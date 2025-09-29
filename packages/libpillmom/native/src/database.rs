use anyhow::Result;
use libsql::{Builder, Connection, Database};
use once_cell::sync::OnceCell;
use std::sync::Arc;
use tokio::sync::Mutex;

static DATABASE: OnceCell<Arc<Mutex<Connection>>> = OnceCell::new();
static DB_HANDLE: OnceCell<Database> = OnceCell::new();

pub async fn init_turso_db(url: &str, auth_token: &str) -> Result<()> {
    let db = Builder::new_remote(url.to_string(), auth_token.to_string()).build().await?;
    let conn = db.connect()?;

    // Create tables
    conn.execute(
        r#"
        CREATE TABLE IF NOT EXISTS medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            dosage TEXT,
            description TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            deleted_at DATETIME
        )
        "#,
        (),
    )
    .await?;

    conn.execute(
        r#"
        CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            time TEXT NOT NULL,
            days TEXT,
            is_active BOOLEAN DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            deleted_at DATETIME,
            FOREIGN KEY (medication_id) REFERENCES medications(id)
        )
        "#,
        (),
    )
    .await?;

    // Store the connection
    DATABASE.set(Arc::new(Mutex::new(conn))).map_err(|_| {
        anyhow::anyhow!("Failed to set database connection")
    })?;

    DB_HANDLE.set(db).map_err(|_| {
        anyhow::anyhow!("Failed to set database handle")
    })?;

    Ok(())
}

pub async fn init_local_db(path: &str) -> Result<()> {
    let db = Builder::new_local(path).build().await?;
    let conn = db.connect()?;

    // Create tables (same as above)
    conn.execute(
        r#"
        CREATE TABLE IF NOT EXISTS medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            dosage TEXT,
            description TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            deleted_at DATETIME
        )
        "#,
        (),
    )
    .await?;

    conn.execute(
        r#"
        CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            time TEXT NOT NULL,
            days TEXT,
            is_active BOOLEAN DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            deleted_at DATETIME,
            FOREIGN KEY (medication_id) REFERENCES medications(id)
        )
        "#,
        (),
    )
    .await?;

    DATABASE.set(Arc::new(Mutex::new(conn))).map_err(|_| {
        anyhow::anyhow!("Failed to set database connection")
    })?;

    DB_HANDLE.set(db).map_err(|_| {
        anyhow::anyhow!("Failed to set database handle")
    })?;

    Ok(())
}

pub async fn sync_database() -> Result<i64> {
    if let Some(db) = DB_HANDLE.get() {
        let _result = db.sync().await?;
        // Return a placeholder value since libsql's sync returns Replicated type
        // which doesn't directly convert to i64
        Ok(0)
    } else {
        Err(anyhow::anyhow!("No active database connection"))
    }
}

pub fn get_connection() -> Option<Arc<Mutex<Connection>>> {
    DATABASE.get().cloned()
}

pub async fn close_database() -> Result<()> {
    // OnceCell doesn't have a take method, so we just let it drop naturally
    // when the program exits
    Ok(())
}