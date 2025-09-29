package main

// #include <stdlib.h>
import "C"
import (
	"encoding/json"
	"unsafe"

	"github.com/127thousand/libpillmom/database"
	"github.com/127thousand/libpillmom/models"
	"github.com/127thousand/libpillmom/repository"
)

//export InitDatabase
func InitDatabase(dbPath *C.char) C.int {
	path := C.GoString(dbPath)
	err := database.InitLocalDB(path)
	if err != nil {
		return -1
	}
	return 0
}

//export InitTursoDatabase
func InitTursoDatabase(databaseURL *C.char, authToken *C.char) C.int {
	url := C.GoString(databaseURL)
	token := C.GoString(authToken)
	err := database.InitDB(url, token)
	if err != nil {
		return -1
	}
	return 0
}

//export InitTursoDatabaseWithSync
func InitTursoDatabaseWithSync(databaseURL *C.char, authToken *C.char, syncInterval C.int) C.int {
	url := C.GoString(databaseURL)
	token := C.GoString(authToken)
	err := database.InitDBWithSync(url, token, int(syncInterval))
	if err != nil {
		return -1
	}
	return 0
}

//export InitTursoDatabaseWithSyncAndPath
func InitTursoDatabaseWithSyncAndPath(databaseURL *C.char, authToken *C.char, syncInterval C.int, dbPath *C.char) C.int {
	url := C.GoString(databaseURL)
	token := C.GoString(authToken)
	path := C.GoString(dbPath)
	err := database.InitDBWithSyncAndPath(url, token, int(syncInterval), path)
	if err != nil {
		return -1
	}
	return 0
}

//export SyncDatabase
func SyncDatabase() C.int {
	err := database.SyncDatabase()
	if err != nil {
		return -1
	}
	return 0
}

//export CloseDatabase
func CloseDatabase() C.int {
	err := database.CloseDB()
	if err != nil {
		return -1
	}
	return 0
}

//export CreateMedication
func CreateMedication(name *C.char, dosage *C.char, description *C.char) C.int {
	medication := &models.Medication{
		Name:        C.GoString(name),
		Dosage:      C.GoString(dosage),
		Description: C.GoString(description),
	}

	err := repository.CreateMedication(medication)
	if err != nil {
		return -1
	}
	return C.int(medication.ID)
}

//export GetMedication
func GetMedication(id C.uint) *C.char {
	medication, err := repository.GetMedication(uint(id))
	if err != nil {
		return nil
	}

	jsonData, err := json.Marshal(medication)
	if err != nil {
		return nil
	}

	return C.CString(string(jsonData))
}

//export GetAllMedications
func GetAllMedications() *C.char {
	medications, err := repository.GetAllMedications()
	if err != nil {
		return nil
	}

	jsonData, err := json.Marshal(medications)
	if err != nil {
		return nil
	}

	return C.CString(string(jsonData))
}

//export UpdateMedication
func UpdateMedication(id C.uint, name *C.char, dosage *C.char, description *C.char) C.int {
	medication, err := repository.GetMedication(uint(id))
	if err != nil {
		return -1
	}

	medication.Name = C.GoString(name)
	medication.Dosage = C.GoString(dosage)
	medication.Description = C.GoString(description)

	err = repository.UpdateMedication(medication)
	if err != nil {
		return -1
	}
	return 0
}

//export DeleteMedication
func DeleteMedication(id C.uint) C.int {
	err := repository.DeleteMedication(uint(id))
	if err != nil {
		return -1
	}
	return 0
}

//export CreateReminder
func CreateReminder(medicationID C.uint, time *C.char, days *C.char) C.int {
	reminder := &models.Reminder{
		MedicationID: uint(medicationID),
		Time:        C.GoString(time),
		Days:        C.GoString(days),
		IsActive:    true,
	}

	err := repository.CreateReminder(reminder)
	if err != nil {
		return -1
	}
	return C.int(reminder.ID)
}

//export GetReminder
func GetReminder(id C.uint) *C.char {
	reminder, err := repository.GetReminder(uint(id))
	if err != nil {
		return nil
	}

	jsonData, err := json.Marshal(reminder)
	if err != nil {
		return nil
	}

	return C.CString(string(jsonData))
}

//export GetRemindersByMedication
func GetRemindersByMedication(medicationID C.uint) *C.char {
	reminders, err := repository.GetRemindersByMedication(uint(medicationID))
	if err != nil {
		return nil
	}

	jsonData, err := json.Marshal(reminders)
	if err != nil {
		return nil
	}

	return C.CString(string(jsonData))
}

//export GetAllReminders
func GetAllReminders() *C.char {
	reminders, err := repository.GetAllReminders()
	if err != nil {
		return nil
	}

	jsonData, err := json.Marshal(reminders)
	if err != nil {
		return nil
	}

	return C.CString(string(jsonData))
}

//export GetActiveReminders
func GetActiveReminders() *C.char {
	reminders, err := repository.GetActiveReminders()
	if err != nil {
		return nil
	}

	jsonData, err := json.Marshal(reminders)
	if err != nil {
		return nil
	}

	return C.CString(string(jsonData))
}

//export UpdateReminder
func UpdateReminder(id C.uint, time *C.char, days *C.char, isActive C.int) C.int {
	reminder, err := repository.GetReminder(uint(id))
	if err != nil {
		return -1
	}

	reminder.Time = C.GoString(time)
	reminder.Days = C.GoString(days)
	reminder.IsActive = isActive != 0

	err = repository.UpdateReminder(reminder)
	if err != nil {
		return -1
	}
	return 0
}

//export DeleteReminder
func DeleteReminder(id C.uint) C.int {
	err := repository.DeleteReminder(uint(id))
	if err != nil {
		return -1
	}
	return 0
}

//export FreeString
func FreeString(str *C.char) {
	C.free(unsafe.Pointer(str))
}

func main() {}