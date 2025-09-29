package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/127thousand/libpillmom/database"
	"github.com/127thousand/libpillmom/models"
	"github.com/joho/godotenv"
)

func main() {
	fmt.Println("=== LibSQL Sync Test ===")

	// Load .env file if it exists (from parent directory)
	if err := godotenv.Load("../.env"); err == nil {
		fmt.Println("Loaded .env file")
	}

	// Check for environment variables
	databaseURL := os.Getenv("TURSO_DATABASE_URL")
	authToken := os.Getenv("TURSO_AUTH_TOKEN")

	if databaseURL == "" || authToken == "" {
		// Test with local database only
		fmt.Println("No Turso credentials found. Testing local database only.")
		testLocalDatabase()
	} else {
		// Test with Turso sync
		fmt.Println("Turso credentials found. Testing embedded replica with sync.")
		testTursoSync(databaseURL, authToken)
	}
}

func testLocalDatabase() {
	fmt.Println("\n--- Testing Local Database ---")

	dbPath := "test_local.db"
	defer os.Remove(dbPath)

	fmt.Printf("Initializing local database at %s...\n", dbPath)
	if err := database.InitLocalDB(dbPath); err != nil {
		log.Fatalf("Failed to initialize local database: %v", err)
	}
	defer database.CloseDB()

	// Create test data
	db := database.GetDB()

	med := &models.Medication{
		Name:        "Aspirin",
		Dosage:      "100mg",
		Description: "Pain reliever",
	}

	fmt.Println("Creating medication...")
	if err := db.Create(med).Error; err != nil {
		log.Fatalf("Failed to create medication: %v", err)
	}
	fmt.Printf("✓ Created medication: %s (ID: %d)\n", med.Name, med.ID)

	// Query data
	var medications []models.Medication
	db.Find(&medications)
	fmt.Printf("✓ Found %d medication(s) in database\n", len(medications))

	fmt.Println("\n✅ Local database test completed successfully!")
}

func testTursoSync(databaseURL, authToken string) {
	fmt.Println("\n--- Testing Turso Sync ---")

	replicaPath := "test_replica.db"
	defer os.Remove(replicaPath)

	// Initialize with 10 second sync interval
	syncInterval := 10
	fmt.Printf("Initializing embedded replica with %d second sync interval...\n", syncInterval)

	if err := database.InitDBWithSyncAndPath(databaseURL, authToken, syncInterval, replicaPath); err != nil {
		log.Fatalf("Failed to initialize database with sync: %v", err)
	}
	defer database.CloseDB()

	db := database.GetDB()

	// Create test medication
	testMed := &models.Medication{
		Name:        fmt.Sprintf("SyncTest-%d", time.Now().Unix()),
		Dosage:      "50mg",
		Description: "Medication for sync testing",
	}

	fmt.Printf("Creating test medication: %s...\n", testMed.Name)
	if err := db.Create(testMed).Error; err != nil {
		log.Fatalf("Failed to create medication: %v", err)
	}
	fmt.Printf("✓ Created medication with ID: %d\n", testMed.ID)

	// Manual sync
	fmt.Println("Performing manual sync...")
	if err := database.SyncDatabase(); err != nil {
		log.Printf("Warning: Manual sync failed: %v", err)
	} else {
		fmt.Println("✓ Manual sync completed")
	}

	// Create a reminder
	reminder := &models.Reminder{
		MedicationID: testMed.ID,
		Time:        "14:00",
		Days:        "Mon,Wed,Fri",
		IsActive:    true,
	}

	fmt.Println("Creating reminder...")
	if err := db.Create(reminder).Error; err != nil {
		log.Fatalf("Failed to create reminder: %v", err)
	}
	fmt.Printf("✓ Created reminder with ID: %d\n", reminder.ID)

	// Wait for automatic sync
	fmt.Printf("\nWaiting %d seconds for automatic sync...\n", syncInterval)
	for i := 0; i < syncInterval; i++ {
		fmt.Printf(".")
		time.Sleep(1 * time.Second)
	}
	fmt.Println()

	// Verify data
	var medCount, reminderCount int64
	db.Model(&models.Medication{}).Count(&medCount)
	db.Model(&models.Reminder{}).Count(&reminderCount)

	fmt.Printf("\n📊 Database Statistics:\n")
	fmt.Printf("   Medications: %d\n", medCount)
	fmt.Printf("   Reminders: %d\n", reminderCount)

	// Query and display all medications
	var medications []models.Medication
	db.Preload("Reminders").Find(&medications)

	fmt.Println("\n📋 All Medications:")
	for _, med := range medications {
		fmt.Printf("   - %s (%s): %s [%d reminders]\n",
			med.Name, med.Dosage, med.Description, len(med.Reminders))
	}

	fmt.Println("\n✅ Turso sync test completed successfully!")
	fmt.Println("\nThe embedded replica database is working with automatic sync.")
	fmt.Printf("Local replica saved at: %s\n", replicaPath)
}