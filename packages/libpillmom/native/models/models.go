package models

import (
	"time"
	"gorm.io/gorm"
)

type Medication struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	Name        string         `gorm:"not null" json:"name"`
	Dosage      string         `json:"dosage"`
	Description string         `json:"description"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at"`
	Reminders   []Reminder     `gorm:"foreignKey:MedicationID" json:"reminders"`
}

type Reminder struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	MedicationID uint           `gorm:"not null" json:"medication_id"`
	Time         string         `gorm:"not null" json:"time"` // Format: "HH:MM"
	Days         string         `json:"days"`                  // Comma-separated days: "Mon,Wed,Fri" or "Daily"
	IsActive     bool           `gorm:"default:true" json:"is_active"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"deleted_at"`
	Medication   Medication     `gorm:"foreignKey:MedicationID" json:"medication"`
}