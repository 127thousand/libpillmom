package database

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/127thousand/libpillmom/models"
	"github.com/joho/godotenv"
)

func init() {
	// Try to load .env file from the native directory
	envPath := filepath.Join("..", ".env")
	if _, err := os.Stat(envPath); err == nil {
		godotenv.Load(envPath)
	}
	// Also try current directory
	godotenv.Load(".env")
}

func TestLocalDatabase(t *testing.T) {
	// Create temp directory for test databases
	tempDir, err := os.MkdirTemp("", "libpillmom_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir) // Clean up entire temp directory

	// Test with local database in temp directory
	dbPath := filepath.Join(tempDir, "test_local.db")
	t.Logf("Using temp database: %s", dbPath)

	err = InitLocalDB(dbPath)
	if err != nil {
		t.Fatalf("Failed to initialize local database: %v", err)
	}
	defer CloseDB()

	// Test creating a medication
	med := &models.Medication{
		Name:        "Test Medicine",
		Dosage:      "50mg",
		Description: "Test medication for unit testing",
	}

	db := GetDB()
	if err := db.Create(med).Error; err != nil {
		t.Fatalf("Failed to create medication: %v", err)
	}

	// Verify medication was created
	var count int64
	db.Model(&models.Medication{}).Count(&count)
	if count != 1 {
		t.Errorf("Expected 1 medication, got %d", count)
	}

	// Test creating a reminder
	reminder := &models.Reminder{
		MedicationID: med.ID,
		Time:         "09:00",
		Days:         "Mon,Wed,Fri",
		IsActive:     true,
	}

	if err := db.Create(reminder).Error; err != nil {
		t.Fatalf("Failed to create reminder: %v", err)
	}

	// Verify reminder was created
	db.Model(&models.Reminder{}).Count(&count)
	if count != 1 {
		t.Errorf("Expected 1 reminder, got %d", count)
	}

	t.Log("Local database test passed")
}

func TestEmbeddedReplicaWithSync(t *testing.T) {
	// This test requires Turso credentials
	databaseURL := os.Getenv("TURSO_DATABASE_URL")
	authToken := os.Getenv("TURSO_AUTH_TOKEN")

	if databaseURL == "" || authToken == "" {
		t.Skip("Skipping Turso sync test - TURSO_DATABASE_URL and TURSO_AUTH_TOKEN not set")
	}

	// Create temp directory for test databases
	tempDir, err := os.MkdirTemp("", "libpillmom_sync_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir) // Clean up entire temp directory

	// Use temp directory for replica
	replicaPath := filepath.Join(tempDir, "test_replica.db")
	t.Logf("Using temp replica: %s", replicaPath)

	// Initialize with a short sync interval for testing
	err = InitDBWithSyncAndPath(databaseURL, authToken, 5, replicaPath) // 5 second sync interval
	if err != nil {
		t.Fatalf("Failed to initialize database with sync: %v", err)
	}
	defer CloseDB()

	// Create a test medication
	med := &models.Medication{
		Name:        fmt.Sprintf("Sync Test Medicine %d", time.Now().Unix()),
		Dosage:      "100mg",
		Description: "Testing sync functionality",
	}

	db := GetDB()
	if err := db.Create(med).Error; err != nil {
		t.Fatalf("Failed to create medication: %v", err)
	}

	t.Logf("Created medication with ID %d", med.ID)

	// Manual sync
	if err := SyncDatabase(); err != nil {
		t.Fatalf("Failed to sync database: %v", err)
	}

	t.Log("Manual sync completed successfully")

	// Wait for automatic sync (should happen within 5 seconds)
	time.Sleep(6 * time.Second)

	// Verify data still exists after sync
	var retrievedMed models.Medication
	if err := db.First(&retrievedMed, med.ID).Error; err != nil {
		t.Fatalf("Failed to retrieve medication after sync: %v", err)
	}

	if retrievedMed.Name != med.Name {
		t.Errorf("Medication name mismatch: expected %s, got %s", med.Name, retrievedMed.Name)
	}

	t.Log("Embedded replica with sync test passed")
}

func TestMultipleSyncIntervals(t *testing.T) {
	// Test that we can initialize with different sync intervals
	databaseURL := os.Getenv("TURSO_DATABASE_URL")
	authToken := os.Getenv("TURSO_AUTH_TOKEN")

	if databaseURL == "" || authToken == "" {
		t.Skip("Skipping sync interval test - TURSO_DATABASE_URL and TURSO_AUTH_TOKEN not set")
	}

	// Create temp directory for all test databases
	tempDir, err := os.MkdirTemp("", "libpillmom_multi_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir) // Clean up entire temp directory

	testCases := []struct {
		name         string
		syncInterval int
		dbName       string
	}{
		{"Fast sync", 1, "fast_sync.db"},
		{"Default sync", 60, "default_sync.db"},
		{"Slow sync", 300, "slow_sync.db"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Use temp directory for each database
			dbPath := filepath.Join(tempDir, tc.dbName)
			t.Logf("Testing %s with database: %s", tc.name, dbPath)

			// Initialize with specific sync interval
			err := InitDBWithSyncAndPath(databaseURL, authToken, tc.syncInterval, dbPath)
			if err != nil {
				t.Fatalf("Failed to initialize with %d second interval: %v", tc.syncInterval, err)
			}

			// Verify connection works
			db := GetDB()
			if db == nil {
				t.Fatal("Database connection is nil")
			}

			// Clean up connection
			CloseDB()

			t.Logf("%s initialization successful with %d second interval", tc.name, tc.syncInterval)
		})
	}
}
