package repository

import (
	"github.com/ostrearium/libpillmom/database"
	"github.com/ostrearium/libpillmom/models"
)

func CreateMedication(medication *models.Medication) error {
	return database.GetDB().Create(medication).Error
}

func GetMedication(id uint) (*models.Medication, error) {
	var medication models.Medication
	err := database.GetDB().Preload("Reminders").First(&medication, id).Error
	if err != nil {
		return nil, err
	}
	return &medication, nil
}

func GetAllMedications() ([]models.Medication, error) {
	var medications []models.Medication
	err := database.GetDB().Preload("Reminders").Find(&medications).Error
	return medications, err
}

func UpdateMedication(medication *models.Medication) error {
	return database.GetDB().Save(medication).Error
}

func DeleteMedication(id uint) error {
	return database.GetDB().Delete(&models.Medication{}, id).Error
}