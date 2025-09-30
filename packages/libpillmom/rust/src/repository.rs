use crate::database::{get_connection, get_sea_db, is_turso};
use crate::entities::{medications, reminders, Medications, Reminders};
use crate::models::{Medication, Reminder};
use anyhow::Result;
use chrono::Utc;
use libsql::params;
use sea_orm::{
    ActiveModelTrait, ColumnTrait, EntityTrait, QueryFilter, Set, ActiveValue,
    QueryOrder, LoaderTrait
};

pub async fn create_medication(med: &Medication) -> Result<i64> {
    let now = Utc::now().to_rfc3339();

    if is_turso() {
        // Use libsql for Turso
        let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No Turso database connection"))?;
        let conn = conn.lock().await;

        let mut stmt = conn
            .prepare(
                "INSERT INTO medications (name, dosage, description, created_at, updated_at)
                 VALUES (?, ?, ?, ?, ?) RETURNING id",
            )
            .await?;

        let mut rows = stmt
            .query(params![
                med.name.clone(),
                med.dosage.clone(),
                med.description.clone(),
                now.clone(),
                now
            ])
            .await?;

        if let Some(row) = rows.next().await? {
            let id: i64 = row.get(0)?;
            Ok(id)
        } else {
            Err(anyhow::anyhow!("Failed to create medication"))
        }
    } else {
        // Use SeaORM for local SQLite
        let db = get_sea_db().ok_or_else(|| anyhow::anyhow!("No SeaORM connection"))?;

        let new_med = medications::ActiveModel {
            name: Set(med.name.clone()),
            dosage: Set(med.dosage.clone()),
            description: Set(med.description.clone()),
            created_at: Set(now.clone()),
            updated_at: Set(now),
            ..Default::default()
        };

        let result = new_med.insert(db).await?;
        Ok(result.id)
    }
}

pub async fn get_all_medications() -> Result<Vec<Medication>> {
    if is_turso() {
        // Use libsql for Turso
        let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
        let conn = conn.lock().await;

        // First get all medications
        let mut stmt = conn
            .prepare(
                "SELECT id, name, dosage, description, created_at, updated_at, deleted_at
                 FROM medications WHERE deleted_at IS NULL",
            )
            .await?;

        let mut rows = stmt.query(()).await?;
        let mut medications = Vec::new();

        while let Some(row) = rows.next().await? {
            let med = Medication {
                id: Some(row.get(0)?),
                name: row.get(1)?,
                dosage: row.get(2)?,
                description: row.get(3)?,
                created_at: row.get(4)?,
                updated_at: row.get(5)?,
                deleted_at: row.get(6)?,
                reminders: Vec::new(),
            };
            medications.push(med);
        }

        // Then get all reminders in a single query
        if !medications.is_empty() {
            let mut reminder_stmt = conn
                .prepare(
                    "SELECT id, medication_id, time, days, is_active, created_at, updated_at, deleted_at
                     FROM reminders WHERE deleted_at IS NULL",
                )
                .await?;

            let mut reminder_rows = reminder_stmt.query(()).await?;

            while let Some(row) = reminder_rows.next().await? {
                let reminder = Reminder {
                    id: Some(row.get(0)?),
                    medication_id: row.get(1)?,
                    time: row.get(2)?,
                    days: row.get(3)?,
                    is_active: row.get::<i64>(4)? != 0,
                    created_at: row.get(5)?,
                    updated_at: row.get(6)?,
                    deleted_at: row.get(7)?,
                };

                // Find the medication this reminder belongs to and add it
                for med in &mut medications {
                    if let Some(med_id) = med.id {
                        if med_id == reminder.medication_id {
                            med.reminders.push(reminder);
                            break;
                        }
                    }
                }
            }
        }

        Ok(medications)
    } else {
        // Use SeaORM for local SQLite
        let db = get_sea_db().ok_or_else(|| anyhow::anyhow!("No SeaORM connection"))?;

        // Fetch medications with their reminders using SeaORM
        let meds = Medications::find()
            .filter(medications::Column::DeletedAt.is_null())
            .order_by_asc(medications::Column::Id)
            .all(db)
            .await?;

        // Load reminders for all medications
        let reminders = meds.load_many(Reminders, db).await?;

        // Convert to our model
        let mut result = Vec::new();
        for (med, med_reminders) in meds.into_iter().zip(reminders) {
            let mut medication = Medication {
                id: Some(med.id),
                name: med.name,
                dosage: med.dosage,
                description: med.description,
                created_at: med.created_at,
                updated_at: med.updated_at,
                deleted_at: med.deleted_at,
                reminders: Vec::new(),
            };

            // Convert reminders
            for rem in med_reminders {
                if rem.deleted_at.is_none() {
                    medication.reminders.push(Reminder {
                        id: Some(rem.id),
                        medication_id: rem.medication_id,
                        time: rem.time,
                        days: rem.days,
                        is_active: rem.is_active != 0,
                        created_at: rem.created_at,
                        updated_at: rem.updated_at,
                        deleted_at: rem.deleted_at,
                    });
                }
            }

            result.push(medication);
        }

        Ok(result)
    }
}

pub async fn update_medication(med: &Medication) -> Result<bool> {
    let now = Utc::now().to_rfc3339();

    if is_turso() {
        // Use libsql for Turso
        let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
        let conn = conn.lock().await;

        let rows_affected = conn
            .execute(
                "UPDATE medications SET name = ?, dosage = ?, description = ?, updated_at = ?
                 WHERE id = ? AND deleted_at IS NULL",
                params![
                    med.name.clone(),
                    med.dosage.clone(),
                    med.description.clone(),
                    now,
                    med.id.unwrap_or(0)
                ],
            )
            .await?;

        Ok(rows_affected > 0)
    } else {
        // Use SeaORM for local SQLite
        let db = get_sea_db().ok_or_else(|| anyhow::anyhow!("No SeaORM connection"))?;

        let med_id = med.id.ok_or_else(|| anyhow::anyhow!("Medication ID is required"))?;

        // Find the medication
        let existing = Medications::find_by_id(med_id)
            .filter(medications::Column::DeletedAt.is_null())
            .one(db)
            .await?;

        if let Some(_) = existing {
            let active_med = medications::ActiveModel {
                id: Set(med_id),
                name: Set(med.name.clone()),
                dosage: Set(med.dosage.clone()),
                description: Set(med.description.clone()),
                updated_at: Set(now),
                created_at: ActiveValue::NotSet,
                deleted_at: ActiveValue::NotSet,
            };

            active_med.update(db).await?;
            Ok(true)
        } else {
            Ok(false)
        }
    }
}

pub async fn delete_medication(id: i64) -> Result<bool> {
    let now = Utc::now().to_rfc3339();

    if is_turso() {
        // Use libsql for Turso
        let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
        let conn = conn.lock().await;

        let rows_affected = conn
            .execute(
                "UPDATE medications SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL",
                params![now, id],
            )
            .await?;

        Ok(rows_affected > 0)
    } else {
        // Use SeaORM for local SQLite
        let db = get_sea_db().ok_or_else(|| anyhow::anyhow!("No SeaORM connection"))?;

        // Find the medication
        let existing = Medications::find_by_id(id)
            .filter(medications::Column::DeletedAt.is_null())
            .one(db)
            .await?;

        if let Some(_) = existing {
            let active_med = medications::ActiveModel {
                id: Set(id),
                deleted_at: Set(Some(now.clone())),
                updated_at: Set(now),
                name: ActiveValue::NotSet,
                dosage: ActiveValue::NotSet,
                description: ActiveValue::NotSet,
                created_at: ActiveValue::NotSet,
            };

            active_med.update(db).await?;
            Ok(true)
        } else {
            Ok(false)
        }
    }
}

pub async fn create_reminder(reminder: &Reminder) -> Result<i64> {
    let now = Utc::now().to_rfc3339();

    if is_turso() {
        // Use libsql for Turso
        let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
        let conn = conn.lock().await;

        let mut stmt = conn
            .prepare(
                "INSERT INTO reminders (medication_id, time, days, is_active, created_at, updated_at)
                 VALUES (?, ?, ?, ?, ?, ?) RETURNING id",
            )
            .await?;

        let mut rows = stmt
            .query(params![
                reminder.medication_id,
                reminder.time.clone(),
                reminder.days.clone(),
                reminder.is_active,
                now.clone(),
                now
            ])
            .await?;

        if let Some(row) = rows.next().await? {
            let id: i64 = row.get(0)?;
            Ok(id)
        } else {
            Err(anyhow::anyhow!("Failed to create reminder"))
        }
    } else {
        // Use SeaORM for local SQLite
        let db = get_sea_db().ok_or_else(|| anyhow::anyhow!("No SeaORM connection"))?;

        let new_reminder = reminders::ActiveModel {
            medication_id: Set(reminder.medication_id),
            time: Set(reminder.time.clone()),
            days: Set(reminder.days.clone()),
            is_active: Set(if reminder.is_active { 1 } else { 0 }),
            created_at: Set(now.clone()),
            updated_at: Set(now),
            ..Default::default()
        };

        let result = new_reminder.insert(db).await?;
        Ok(result.id)
    }
}

pub async fn get_active_reminders() -> Result<Vec<Reminder>> {
    if is_turso() {
        // Use libsql for Turso
        let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
        let conn = conn.lock().await;

        let mut stmt = conn
            .prepare(
                "SELECT id, medication_id, time, days, is_active, created_at, updated_at, deleted_at
                 FROM reminders WHERE is_active = 1 AND deleted_at IS NULL",
            )
            .await?;

        let mut rows = stmt.query(()).await?;
        let mut reminders = Vec::new();

        while let Some(row) = rows.next().await? {
            let reminder = Reminder {
                id: Some(row.get(0)?),
                medication_id: row.get(1)?,
                time: row.get(2)?,
                days: row.get(3)?,
                is_active: row.get::<i64>(4)? != 0,
                created_at: row.get(5)?,
                updated_at: row.get(6)?,
                deleted_at: row.get(7)?,
            };
            reminders.push(reminder);
        }

        Ok(reminders)
    } else {
        // Use SeaORM for local SQLite
        let db = get_sea_db().ok_or_else(|| anyhow::anyhow!("No SeaORM connection"))?;

        let rems = Reminders::find()
            .filter(reminders::Column::IsActive.eq(1))
            .filter(reminders::Column::DeletedAt.is_null())
            .all(db)
            .await?;

        let mut result = Vec::new();
        for rem in rems {
            result.push(Reminder {
                id: Some(rem.id),
                medication_id: rem.medication_id,
                time: rem.time,
                days: rem.days,
                is_active: rem.is_active != 0,
                created_at: rem.created_at,
                updated_at: rem.updated_at,
                deleted_at: rem.deleted_at,
            });
        }

        Ok(result)
    }
}

pub async fn update_reminder(reminder: &Reminder) -> Result<bool> {
    let now = Utc::now().to_rfc3339();

    if is_turso() {
        // Use libsql for Turso
        let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
        let conn = conn.lock().await;

        let rows_affected = conn
            .execute(
                "UPDATE reminders SET time = ?, days = ?, is_active = ?, updated_at = ?
                 WHERE id = ? AND deleted_at IS NULL",
                params![
                    reminder.time.clone(),
                    reminder.days.clone(),
                    reminder.is_active,
                    now,
                    reminder.id.unwrap_or(0)
                ],
            )
            .await?;

        Ok(rows_affected > 0)
    } else {
        // Use SeaORM for local SQLite
        let db = get_sea_db().ok_or_else(|| anyhow::anyhow!("No SeaORM connection"))?;

        let rem_id = reminder.id.ok_or_else(|| anyhow::anyhow!("Reminder ID is required"))?;

        // Find the reminder
        let existing = Reminders::find_by_id(rem_id)
            .filter(reminders::Column::DeletedAt.is_null())
            .one(db)
            .await?;

        if let Some(_) = existing {
            let active_rem = reminders::ActiveModel {
                id: Set(rem_id),
                time: Set(reminder.time.clone()),
                days: Set(reminder.days.clone()),
                is_active: Set(if reminder.is_active { 1 } else { 0 }),
                updated_at: Set(now),
                medication_id: ActiveValue::NotSet,
                created_at: ActiveValue::NotSet,
                deleted_at: ActiveValue::NotSet,
            };

            active_rem.update(db).await?;
            Ok(true)
        } else {
            Ok(false)
        }
    }
}

pub async fn delete_reminder(id: i64) -> Result<bool> {
    let now = Utc::now().to_rfc3339();

    if is_turso() {
        // Use libsql for Turso
        let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
        let conn = conn.lock().await;

        let rows_affected = conn
            .execute(
                "UPDATE reminders SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL",
                params![now, id],
            )
            .await?;

        Ok(rows_affected > 0)
    } else {
        // Use SeaORM for local SQLite
        let db = get_sea_db().ok_or_else(|| anyhow::anyhow!("No SeaORM connection"))?;

        // Find the reminder
        let existing = Reminders::find_by_id(id)
            .filter(reminders::Column::DeletedAt.is_null())
            .one(db)
            .await?;

        if let Some(_) = existing {
            let active_rem = reminders::ActiveModel {
                id: Set(id),
                deleted_at: Set(Some(now.clone())),
                updated_at: Set(now),
                medication_id: ActiveValue::NotSet,
                time: ActiveValue::NotSet,
                days: ActiveValue::NotSet,
                is_active: ActiveValue::NotSet,
                created_at: ActiveValue::NotSet,
            };

            active_rem.update(db).await?;
            Ok(true)
        } else {
            Ok(false)
        }
    }
}