use anyhow::Result;
use libsql::{Builder, Connection, Database};
use once_cell::sync::OnceCell;
use sea_orm::{Database as SeaDatabase, DatabaseConnection, ConnectOptions};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;

static DATABASE: OnceCell<Arc<Mutex<Connection>>> = OnceCell::new();
static DB_HANDLE: OnceCell<Database> = OnceCell::new();
static SEA_DB: OnceCell<DatabaseConnection> = OnceCell::new();

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

    // Use SeaORM for in-memory SQLite
    let database_url = "sqlite::memory:";
    let mut opt = ConnectOptions::new(database_url);
    opt.max_connections(100)
        .min_connections(5)
        .connect_timeout(Duration::from_secs(8))
        .idle_timeout(Duration::from_secs(8))
        .max_lifetime(Duration::from_secs(8))
        .sqlx_logging(false);

    let sea_db = SeaDatabase::connect(opt).await?;
    create_tables_seaorm(&sea_db).await?;

    SEA_DB.set(sea_db).map_err(|_| {
        anyhow::anyhow!("Failed to set SeaORM connection")
    })?;

    Ok(())
}

/// Initialize a local SQLite database
pub async fn init_local_db(path: &str) -> Result<()> {
    DB_TYPE.set(DbType::Local).map_err(|_| {
        anyhow::anyhow!("Failed to set database type")
    })?;

    // Use SeaORM for local SQLite
    let database_url = format!("sqlite://{}?mode=rwc", path);

    let mut opt = ConnectOptions::new(database_url);
    opt.max_connections(100)
        .min_connections(5)
        .connect_timeout(Duration::from_secs(8))
        .idle_timeout(Duration::from_secs(8))
        .max_lifetime(Duration::from_secs(8))
        .sqlx_logging(false);

    let sea_db = SeaDatabase::connect(opt).await?;
    create_tables_seaorm(&sea_db).await?;

    SEA_DB.set(sea_db).map_err(|_| {
        anyhow::anyhow!("Failed to set SeaORM connection")
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

    create_tables_libsql(&conn).await?;

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
    _path: &str,
    url: &str,
    auth_token: &str,
    _sync_period: Option<Duration>,
) -> Result<()> {
    DB_TYPE.set(DbType::EmbeddedReplica).map_err(|_| {
        anyhow::anyhow!("Failed to set database type")
    })?;

    // TODO: Fix embedded replica crash
    // For now, use remote connection
    let db = Builder::new_remote(url.to_string(), auth_token.to_string())
        .build()
        .await?;
    let conn = db.connect()?;

    create_tables_libsql(&conn).await?;

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

async fn create_tables_seaorm(db: &DatabaseConnection) -> Result<()> {
    let create_medications = r#"
        CREATE TABLE IF NOT EXISTS medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            dosage TEXT,
            description TEXT,
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now')),
            deleted_at TEXT
        )
    "#;

    let create_reminders = r#"
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
    "#;

    use sea_orm::ConnectionTrait;
    ConnectionTrait::execute_unprepared(db, create_medications).await?;
    ConnectionTrait::execute_unprepared(db, create_reminders).await?;

    Ok(())
}

async fn create_tables_libsql(conn: &Connection) -> Result<()> {
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
    // SeaORM and libsql connections are automatically closed when dropped
    Ok(())
}

// ===== Getters for repository layer =====

pub fn get_connection() -> Option<Arc<Mutex<Connection>>> {
    DATABASE.get().cloned()
}

pub fn get_sea_db() -> Option<&'static DatabaseConnection> {
    SEA_DB.get()
}

pub fn is_remote() -> bool {
    matches!(
        DB_TYPE.get(),
        Some(DbType::Remote) | Some(DbType::EmbeddedReplica)
    )
}

// Legacy support
pub fn is_turso() -> bool {
    is_remote()
}