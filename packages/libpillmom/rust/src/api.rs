use crate::database;
use crate::models::{Medication, Reminder};
use crate::repository;
use anyhow::Result;
use flutter_rust_bridge::frb;

#[frb(opaque)]
pub struct PillMomApi {}

impl PillMomApi {
    #[frb(sync)]
    pub fn new() -> Self {
        PillMomApi {}
    }

    // ===== Database Connection Methods =====

    /// Connect to an in-memory database (no persistence)
    pub async fn open_in_memory(&self) -> Result<()> {
        database::init_in_memory().await
    }

    /// Connect to a local SQLite database file
    pub async fn open_local(&self, path: String) -> Result<()> {
        database::init_local_db(&path).await
    }

    /// Connect to a remote Turso database
    pub async fn open_remote(&self, url: String, auth_token: String) -> Result<()> {
        database::init_remote_db(&url, &auth_token).await
    }

    /// Connect to an embedded replica (local SQLite that syncs with remote)
    /// Note: Currently using remote connection due to FFI issues with embedded replicas
    pub async fn open_embedded_replica(
        &self,
        _path: String,
        url: String,
        auth_token: String,
        _sync_period: Option<f64>, // Sync period in seconds
    ) -> Result<()> {
        // TODO: Fix embedded replica crash and use sync_period
        // For now, fall back to remote connection
        database::init_remote_db(&url, &auth_token).await
    }

    // Legacy methods for backward compatibility
    pub async fn init_turso_database(&self, url: String, auth_token: String) -> Result<()> {
        self.open_remote(url, auth_token).await
    }

    pub async fn init_local_database(&self, path: String) -> Result<()> {
        self.open_local(path).await
    }

    // ===== Database Operations =====

    pub async fn sync_database(&self) -> Result<i64> {
        database::sync_database().await
    }

    pub async fn close_database(&self) -> Result<()> {
        database::close_database().await
    }

    // ===== Medication CRUD =====

    pub async fn create_medication(
        &self,
        name: String,
        dosage: String,
        description: String,
    ) -> Result<i64> {
        let med = Medication {
            id: None,
            name,
            dosage,
            description,
            created_at: Default::default(),
            updated_at: Default::default(),
            deleted_at: None,
            reminders: Vec::new(),
        };
        repository::create_medication(&med).await
    }

    pub async fn get_all_medications(&self) -> Result<Vec<Medication>> {
        repository::get_all_medications().await
    }

    pub async fn update_medication(&self, medication: Medication) -> Result<bool> {
        repository::update_medication(&medication).await
    }

    pub async fn delete_medication(&self, id: i64) -> Result<bool> {
        repository::delete_medication(id).await
    }

    // ===== Reminder CRUD =====

    pub async fn create_reminder(
        &self,
        medication_id: i64,
        time: String,
        days: String,
        is_active: bool,
    ) -> Result<i64> {
        let reminder = Reminder {
            id: None,
            medication_id,
            time,
            days,
            is_active,
            created_at: Default::default(),
            updated_at: Default::default(),
            deleted_at: None,
        };
        repository::create_reminder(&reminder).await
    }

    pub async fn get_active_reminders(&self) -> Result<Vec<Reminder>> {
        repository::get_active_reminders().await
    }

    pub async fn update_reminder(&self, reminder: Reminder) -> Result<bool> {
        repository::update_reminder(&reminder).await
    }

    pub async fn delete_reminder(&self, id: i64) -> Result<bool> {
        repository::delete_reminder(id).await
    }
}

// Convenience function to create the API instance
#[frb(sync)]
pub fn create_api() -> PillMomApi {
    PillMomApi::new()
}