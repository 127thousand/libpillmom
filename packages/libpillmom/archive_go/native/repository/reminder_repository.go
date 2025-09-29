package repository

import (
	"github.com/127thousand/libpillmom/database"
	"github.com/127thousand/libpillmom/models"
)

func CreateReminder(reminder *models.Reminder) error {
	return database.GetDB().Create(reminder).Error
}

func GetReminder(id uint) (*models.Reminder, error) {
	var reminder models.Reminder
	err := database.GetDB().Preload("Medication").First(&reminder, id).Error
	if err != nil {
		return nil, err
	}
	return &reminder, nil
}

func GetRemindersByMedication(medicationID uint) ([]models.Reminder, error) {
	var reminders []models.Reminder
	err := database.GetDB().Where("medication_id = ?", medicationID).Find(&reminders).Error
	return reminders, err
}

func GetAllReminders() ([]models.Reminder, error) {
	var reminders []models.Reminder
	err := database.GetDB().Preload("Medication").Find(&reminders).Error
	return reminders, err
}

func GetActiveReminders() ([]models.Reminder, error) {
	var reminders []models.Reminder
	err := database.GetDB().Preload("Medication").Where("is_active = ?", true).Find(&reminders).Error
	return reminders, err
}

func UpdateReminder(reminder *models.Reminder) error {
	return database.GetDB().Save(reminder).Error
}

func DeleteReminder(id uint) error {
	return database.GetDB().Delete(&models.Reminder{}, id).Error
}