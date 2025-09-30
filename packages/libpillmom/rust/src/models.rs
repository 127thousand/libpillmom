use chrono::Utc;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Medication {
    pub id: Option<i64>,
    pub name: String,
    pub dosage: String,
    pub description: String,
    pub created_at: String,  // Use String for simpler FFI
    pub updated_at: String,  // Use String for simpler FFI
    pub deleted_at: Option<String>,  // Use String for simpler FFI
    #[serde(default)]
    pub reminders: Vec<Reminder>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Reminder {
    pub id: Option<i64>,
    pub medication_id: i64,
    pub time: String, // Format: "HH:MM"
    pub days: String, // Comma-separated days: "Mon,Wed,Fri" or "Daily"
    pub is_active: bool,
    pub created_at: String,  // Use String for simpler FFI
    pub updated_at: String,  // Use String for simpler FFI
    pub deleted_at: Option<String>,  // Use String for simpler FFI
}

impl Default for Medication {
    fn default() -> Self {
        let now = Utc::now().to_rfc3339();
        Self {
            id: None,
            name: String::new(),
            dosage: String::new(),
            description: String::new(),
            created_at: now.clone(),
            updated_at: now,
            deleted_at: None,
            reminders: Vec::new(),
        }
    }
}

impl Default for Reminder {
    fn default() -> Self {
        let now = Utc::now().to_rfc3339();
        Self {
            id: None,
            medication_id: 0,
            time: String::new(),
            days: String::new(),
            is_active: true,
            created_at: now.clone(),
            updated_at: now,
            deleted_at: None,
        }
    }
}