use anyhow::Result;
use libsql::{Builder, Connection, Database};
use once_cell::sync::OnceCell;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;

static DATABASE: OnceCell<Arc<Mutex<Connection>>> = OnceCell::new();
static DB_HANDLE: OnceCell<Database> = OnceCell::new();

#[derive(Debug, Clone, Copy)]
#[allow(dead_code)]
enum DbType {
    InMemory,
    Local,
    Remote,
    EmbeddedReplica,
}

static DB_TYPE: OnceCell<DbType> = OnceCell::new();

// ===== Connection Methods =====

/// Initialize an in-memory database (no persistence)
pub async fn init_in_memory() -> Result<()> {
    DB_TYPE.set(DbType::InMemory).map_err(|_| {
        anyhow::anyhow!("Failed to set database type")
    })?;

    // Use libsql for in-memory SQLite
    let db = Builder::new_local(":memory:").build().await?;
    let conn = db.connect()?;

    create_tables(&conn).await?;

    DATABASE.set(Arc::new(Mutex::new(conn))).map_err(|_| {
        anyhow::anyhow!("Failed to set database connection")
    })?;

    DB_HANDLE.set(db).map_err(|_| {
        anyhow::anyhow!("Failed to set database handle")
    })?;

    Ok(())
}

/// Initialize a local SQLite database
pub async fn init_local_db(path: &str) -> Result<()> {
    DB_TYPE.set(DbType::Local).map_err(|_| {
        anyhow::anyhow!("Failed to set database type")
    })?;

    // Use libsql for local SQLite
    let db = Builder::new_local(path).build().await?;
    let conn = db.connect()?;

    create_tables(&conn).await?;

    DATABASE.set(Arc::new(Mutex::new(conn))).map_err(|_| {
        anyhow::anyhow!("Failed to set database connection")
    })?;

    DB_HANDLE.set(db).map_err(|_| {
        anyhow::anyhow!("Failed to set database handle")
    })?;

    Ok(())
}

/// Initialize a remote Turso database connection
pub async fn init_remote_db(url: &str, auth_token: &str) -> Result<()> {
    DB_TYPE.set(DbType::Remote).map_err(|_| {
        anyhow::anyhow!("Failed to set database type")
    })?;

    // Use libsql for remote Turso connection
    let db = Builder::new_remote(url.to_string(), auth_token.to_string())
        .build()
        .await?;
    let conn = db.connect()?;

    create_tables(&conn).await?;

    DATABASE.set(Arc::new(Mutex::new(conn))).map_err(|_| {
        anyhow::anyhow!("Failed to set database connection")
    })?;

    DB_HANDLE.set(db).map_err(|_| {
        anyhow::anyhow!("Failed to set database handle")
    })?;

    Ok(())
}

/// Initialize an embedded replica (local SQLite that syncs with remote)
#[allow(dead_code)]
pub async fn init_embedded_replica(
    path: &str,
    url: &str,
    auth_token: &str,
    sync_period: Option<Duration>,
) -> Result<()> {
    DB_TYPE.set(DbType::EmbeddedReplica).map_err(|_| {
        anyhow::anyhow!("Failed to set database type")
    })?;

    // Use libsql embedded replica
    let mut builder = Builder::new_remote_replica(path, url.to_string(), auth_token.to_string());

    if let Some(period) = sync_period {
        builder = builder.sync_interval(period);
    }

    let db = builder.build().await?;
    let conn = db.connect()?;

    create_tables(&conn).await?;

    DATABASE.set(Arc::new(Mutex::new(conn))).map_err(|_| {
        anyhow::anyhow!("Failed to set database connection")
    })?;

    DB_HANDLE.set(db).map_err(|_| {
        anyhow::anyhow!("Failed to set database handle")
    })?;

    Ok(())
}

// Legacy support for old API
#[allow(dead_code)]
pub async fn init_turso_db(url: &str, auth_token: &str) -> Result<()> {
    init_remote_db(url, auth_token).await
}

// ===== Helper Functions =====

async fn create_tables(conn: &Connection) -> Result<()> {
    conn.execute(
        r#"
        CREATE TABLE IF NOT EXISTS medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            dosage TEXT,
            description TEXT,
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now')),
            deleted_at TEXT
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
            is_active INTEGER DEFAULT 1,
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now')),
            deleted_at TEXT,
            FOREIGN KEY (medication_id) REFERENCES medications(id)
        )
        "#,
        (),
    )
    .await?;

    Ok(())
}

// ===== Database Operations =====

pub async fn sync_database() -> Result<i64> {
    // Sync is only supported for embedded replicas
    // For other connection types, data is already synced or local-only
    match DB_TYPE.get() {
        Some(DbType::Remote) | Some(DbType::InMemory) | Some(DbType::Local) => {
            // No sync needed for these types
            Ok(0)
        }
        Some(DbType::EmbeddedReplica) => {
            if let Some(db) = DB_HANDLE.get() {
                // Attempt sync for embedded replica
                let _result = db.sync().await?;
                Ok(0)
            } else {
                Err(anyhow::anyhow!("No active database connection"))
            }
        }
        None => Err(anyhow::anyhow!("Database not initialized")),
    }
}

pub async fn close_database() -> Result<()> {
    // libsql connections are automatically closed when dropped
    Ok(())
}

// ===== Getters for repository layer =====

pub fn get_connection() -> Option<Arc<Mutex<Connection>>> {
    DATABASE.get().cloned()
}

pub fn is_remote() -> bool {
    matches!(
        DB_TYPE.get(),
        Some(DbType::Remote) | Some(DbType::EmbeddedReplica)
    )
}