use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "reminders")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i64,
    pub medication_id: i64,
    pub time: String,
    pub days: String,
    pub is_active: i64,  // SQLite uses i64 for boolean
    pub created_at: String,
    pub updated_at: String,
    pub deleted_at: Option<String>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::medications::Entity",
        from = "Column::MedicationId",
        to = "super::medications::Column::Id"
    )]
    Medication,
}

impl Related<super::medications::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Medication.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}