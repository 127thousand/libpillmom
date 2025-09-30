use crate::database::get_connection;
use crate::models::{Medication, Reminder};
use anyhow::Result;
use chrono::Utc;
use libsql::params;

pub async fn create_medication(med: &Medication) -> Result<i64> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let mut stmt = conn
        .prepare(
            "INSERT INTO medications (name, dosage, description, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?) RETURNING id",
        )
        .await?;

    let now = Utc::now().to_rfc3339();
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
}

pub async fn get_all_medications() -> Result<Vec<Medication>> {
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
            created_at: row.get::<String>(4)?.parse()?,
            updated_at: row.get::<String>(5)?.parse()?,
            deleted_at: row
                .get::<Option<String>>(6)?
                .and_then(|s| s.parse().ok()),
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
                created_at: row.get::<String>(5)?.parse()?,
                updated_at: row.get::<String>(6)?.parse()?,
                deleted_at: row
                    .get::<Option<String>>(7)?
                    .and_then(|s| s.parse().ok()),
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
}

pub async fn update_medication(med: &Medication) -> Result<bool> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let now = Utc::now().to_rfc3339();
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
}

pub async fn delete_medication(id: i64) -> Result<bool> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let now = Utc::now().to_rfc3339();
    let rows_affected = conn
        .execute(
            "UPDATE medications SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL",
            params![now, id],
        )
        .await?;

    Ok(rows_affected > 0)
}

pub async fn create_reminder(reminder: &Reminder) -> Result<i64> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let mut stmt = conn
        .prepare(
            "INSERT INTO reminders (medication_id, time, days, is_active, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?) RETURNING id",
        )
        .await?;

    let now = Utc::now().to_rfc3339();
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
}

pub async fn get_active_reminders() -> Result<Vec<Reminder>> {
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
            created_at: row.get::<String>(5)?.parse()?,
            updated_at: row.get::<String>(6)?.parse()?,
            deleted_at: row
                .get::<Option<String>>(7)?
                .and_then(|s| s.parse().ok()),
        };
        reminders.push(reminder);
    }

    Ok(reminders)
}

pub async fn get_reminders_for_medication(medication_id: i64) -> Result<Vec<Reminder>> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let mut stmt = conn
        .prepare(
            "SELECT id, medication_id, time, days, is_active, created_at, updated_at, deleted_at
             FROM reminders WHERE medication_id = ? AND deleted_at IS NULL",
        )
        .await?;

    let mut rows = stmt.query(params![medication_id]).await?;
    let mut reminders = Vec::new();

    while let Some(row) = rows.next().await? {
        let reminder = Reminder {
            id: Some(row.get(0)?),
            medication_id: row.get(1)?,
            time: row.get(2)?,
            days: row.get(3)?,
            is_active: row.get::<i64>(4)? != 0,
            created_at: row.get::<String>(5)?.parse()?,
            updated_at: row.get::<String>(6)?.parse()?,
            deleted_at: row
                .get::<Option<String>>(7)?
                .and_then(|s| s.parse().ok()),
        };
        reminders.push(reminder);
    }

    Ok(reminders)
}

pub async fn update_reminder(reminder: &Reminder) -> Result<bool> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let now = Utc::now().to_rfc3339();
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
}

pub async fn delete_reminder(id: i64) -> Result<bool> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let now = Utc::now().to_rfc3339();
    let rows_affected = conn
        .execute(
            "UPDATE reminders SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL",
            params![now, id],
        )
        .await?;

    Ok(rows_affected > 0)
}