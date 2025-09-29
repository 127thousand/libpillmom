package database

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/127thousand/libpillmom/models"
	"github.com/tursodatabase/go-libsql"
	_ "github.com/tursodatabase/go-libsql"
	"gorm.io/gorm"
)

var db *gorm.DB
var sqlDB *sql.DB
var connector *libsql.Connector

func InitDB(databaseURL, authToken string) error {
	return InitDBWithSync(databaseURL, authToken, 60) // Default to 60 seconds sync interval
}

func InitDBWithSync(databaseURL, authToken string, syncIntervalSeconds int) error {
	return InitDBWithSyncAndPath(databaseURL, authToken, syncIntervalSeconds, "local_replica.db")
}

func InitDBWithSyncAndPath(databaseURL, authToken string, syncIntervalSeconds int, dbPath string) error {
	var err error

	// Use embedded replica with automatic syncing
	syncInterval := time.Duration(syncIntervalSeconds) * time.Second

	connector, err = libsql.NewEmbeddedReplicaConnector(
		dbPath,
		databaseURL,
		libsql.WithAuthToken(authToken),
		libsql.WithSyncInterval(syncInterval),
	)
	if err != nil {
		return fmt.Errorf("failed to create embedded replica connector: %w", err)
	}

	// Open a sql.DB connection using the connector
	sqlDB = sql.OpenDB(connector)

	db, err = gorm.Open(Dialector{Conn: sqlDB}, &gorm.Config{})

	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}

	err = db.AutoMigrate(&models.Medication{}, &models.Reminder{})
	if err != nil {
		return fmt.Errorf("failed to migrate database: %w", err)
	}

	return nil
}

func SyncDatabase() error {
	if connector != nil {
		_, err := connector.Sync()
		return err
	}
	return fmt.Errorf("no active database connector")
}

func InitLocalDB(dbPath string) error {
	if dbPath == "" {
		dbPath = "pillmom.db"
	}

	var err error

	// Open local database using go-libsql with file:// URL scheme
	fileURL := "file:" + dbPath
	localDB, err := sql.Open("libsql", fileURL)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}

	sqlDB = localDB
	db, err = gorm.Open(Dialector{Conn: localDB}, &gorm.Config{})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}

	err = db.AutoMigrate(&models.Medication{}, &models.Reminder{})
	if err != nil {
		return fmt.Errorf("failed to migrate database: %w", err)
	}

	return nil
}

func GetDB() *gorm.DB {
	return db
}

func CloseDB() error {
	if connector != nil {
		if err := connector.Close(); err != nil {
			return err
		}
		connector = nil
	}
	if db != nil {
		sqlDB, err := db.DB()
		if err != nil {
			return err
		}
		return sqlDB.Close()
	}
	return nil
}