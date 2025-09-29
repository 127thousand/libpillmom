use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Medication {
    pub id: Option<i64>,
    pub name: String,
    pub dosage: String,
    pub description: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
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
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}

impl Default for Medication {
    fn default() -> Self {
        Self {
            id: None,
            name: String::new(),
            dosage: String::new(),
            description: String::new(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
            deleted_at: None,
            reminders: Vec::new(),
        }
    }
}

impl Default for Reminder {
    fn default() -> Self {
        Self {
            id: None,
            medication_id: 0,
            time: String::new(),
            days: String::new(),
            is_active: true,
            created_at: Utc::now(),
            updated_at: Utc::now(),
            deleted_at: None,
        }
    }
}