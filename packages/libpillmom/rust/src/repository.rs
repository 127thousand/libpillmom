use crate::database::get_connection;
use crate::models::{Medication, Reminder};
use anyhow::Result;
use chrono::Utc;
use libsql::params;

pub async fn create_medication(med: &Medication) -> Result<i64> {
    let now = Utc::now().to_rfc3339();

    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let stmt = conn
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
}

pub async fn get_medication(id: i64) -> Result<Option<Medication>> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let stmt = conn
        .prepare(
            "SELECT id, name, dosage, description, created_at, updated_at, deleted_at
             FROM medications WHERE id = ? AND deleted_at IS NULL",
        )
        .await?;

    let mut rows = stmt.query(params![id]).await?;

    if let Some(row) = rows.next().await? {
        Ok(Some(Medication {
            id: Some(row.get(0)?),
            name: row.get(1)?,
            dosage: row.get(2)?,
            description: row.get(3)?,
            created_at: row.get::<Option<String>>(4)?.unwrap_or_default(),
            updated_at: row.get::<Option<String>>(5)?.unwrap_or_default(),
            deleted_at: row.get::<Option<String>>(6)?,
            reminders: Vec::new(),
        }))
    } else {
        Ok(None)
    }
}

pub async fn get_all_medications() -> Result<Vec<Medication>> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    // Get all medications
    let mut medications = Vec::new();
    let med_stmt = conn
        .prepare(
            "SELECT id, name, dosage, description, created_at, updated_at, deleted_at
             FROM medications WHERE deleted_at IS NULL ORDER BY id",
        )
        .await?;

    let mut med_rows = med_stmt.query(()).await?;

    while let Some(row) = med_rows.next().await? {
        medications.push(Medication {
            id: Some(row.get(0)?),
            name: row.get(1)?,
            dosage: row.get(2)?,
            description: row.get(3)?,
            created_at: row.get::<Option<String>>(4)?.unwrap_or_default(),
            updated_at: row.get::<Option<String>>(5)?.unwrap_or_default(),
            deleted_at: row.get::<Option<String>>(6)?,
            reminders: Vec::new(),
        });
    }

    // Get all reminders and associate with medications
    let rem_stmt = conn
        .prepare(
            "SELECT id, medication_id, time, days, is_active, created_at, updated_at, deleted_at
             FROM reminders WHERE deleted_at IS NULL ORDER BY medication_id",
        )
        .await?;

    let mut rem_rows = rem_stmt.query(()).await?;

    while let Some(row) = rem_rows.next().await? {
        let med_id: i64 = row.get(1)?;
        let reminder = Reminder {
            id: Some(row.get(0)?),
            medication_id: med_id,
            time: row.get(2)?,
            days: row.get(3)?,
            is_active: row.get::<Option<i64>>(4)?.map(|v| v != 0).unwrap_or(true),
            created_at: row.get::<Option<String>>(5)?.unwrap_or_default(),
            updated_at: row.get::<Option<String>>(6)?.unwrap_or_default(),
            deleted_at: row.get::<Option<String>>(7)?,
        };

        // Find the medication and add the reminder
        if let Some(medication) = medications.iter_mut().find(|m| m.id == Some(med_id)) {
            medication.reminders.push(reminder);
        }
    }

    Ok(medications)
}

pub async fn update_medication(med: &Medication) -> Result<bool> {
    let id = med.id.ok_or_else(|| anyhow::anyhow!("Medication ID is required for update"))?;
    let now = Utc::now().to_rfc3339();

    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    conn.execute(
        "UPDATE medications SET name = ?, dosage = ?, description = ?, updated_at = ?
         WHERE id = ? AND deleted_at IS NULL",
        params![
            med.name.clone(),
            med.dosage.clone(),
            med.description.clone(),
            now,
            id
        ],
    )
    .await?;

    Ok(true)
}

pub async fn delete_medication(id: i64) -> Result<bool> {
    let now = Utc::now().to_rfc3339();

    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    // Soft delete the medication
    conn.execute(
        "UPDATE medications SET deleted_at = ? WHERE id = ?",
        params![now.clone(), id],
    )
    .await?;

    // Also soft delete associated reminders
    conn.execute(
        "UPDATE reminders SET deleted_at = ? WHERE medication_id = ?",
        params![now, id],
    )
    .await?;

    Ok(true)
}

pub async fn create_reminder(reminder: &Reminder) -> Result<i64> {
    let now = Utc::now().to_rfc3339();

    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let stmt = conn
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
            reminder.is_active as i64,
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

pub async fn update_reminder(reminder: &Reminder) -> Result<bool> {
    let id = reminder.id.ok_or_else(|| anyhow::anyhow!("Reminder ID is required for update"))?;
    let now = Utc::now().to_rfc3339();

    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    conn.execute(
        "UPDATE reminders SET time = ?, days = ?, is_active = ?, updated_at = ?
         WHERE id = ? AND deleted_at IS NULL",
        params![
            reminder.time.clone(),
            reminder.days.clone(),
            reminder.is_active as i64,
            now,
            id
        ],
    )
    .await?;

    Ok(true)
}

pub async fn delete_reminder(id: i64) -> Result<bool> {
    let now = Utc::now().to_rfc3339();

    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    conn.execute(
        "UPDATE reminders SET deleted_at = ? WHERE id = ?",
        params![now, id],
    )
    .await?;

    Ok(true)
}

pub async fn get_reminders_for_medication(medication_id: i64) -> Result<Vec<Reminder>> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let stmt = conn
        .prepare(
            "SELECT id, medication_id, time, days, is_active, created_at, updated_at, deleted_at
             FROM reminders WHERE medication_id = ? AND deleted_at IS NULL",
        )
        .await?;

    let mut rows = stmt.query(params![medication_id]).await?;
    let mut reminders = Vec::new();

    while let Some(row) = rows.next().await? {
        reminders.push(Reminder {
            id: Some(row.get(0)?),
            medication_id: row.get(1)?,
            time: row.get(2)?,
            days: row.get(3)?,
            is_active: row.get::<Option<i64>>(4)?.map(|v| v != 0).unwrap_or(true),
            created_at: row.get::<Option<String>>(5)?.unwrap_or_default(),
            updated_at: row.get::<Option<String>>(6)?.unwrap_or_default(),
            deleted_at: row.get::<Option<String>>(7)?,
        });
    }

    Ok(reminders)
}

pub async fn get_active_reminders() -> Result<Vec<Reminder>> {
    let conn = get_connection().ok_or_else(|| anyhow::anyhow!("No database connection"))?;
    let conn = conn.lock().await;

    let stmt = conn
        .prepare(
            "SELECT id, medication_id, time, days, is_active, created_at, updated_at, deleted_at
             FROM reminders WHERE is_active = 1 AND deleted_at IS NULL",
        )
        .await?;

    let mut rows = stmt.query(()).await?;
    let mut reminders = Vec::new();

    while let Some(row) = rows.next().await? {
        reminders.push(Reminder {
            id: Some(row.get(0)?),
            medication_id: row.get(1)?,
            time: row.get(2)?,
            days: row.get(3)?,
            is_active: row.get::<Option<i64>>(4)?.map(|v| v != 0).unwrap_or(true),
            created_at: row.get::<Option<String>>(5)?.unwrap_or_default(),
            updated_at: row.get::<Option<String>>(6)?.unwrap_or_default(),
            deleted_at: row.get::<Option<String>>(7)?,
        });
    }

    Ok(reminders)
}