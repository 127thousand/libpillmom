package database

import (
	"database/sql"

	"gorm.io/gorm"
	"gorm.io/gorm/callbacks"
	"gorm.io/gorm/clause"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/migrator"
	"gorm.io/gorm/schema"
)

type Dialector struct {
	Conn *sql.DB
}

func (d Dialector) Name() string {
	return "sqlite"
}

func (d Dialector) Initialize(db *gorm.DB) error {
	callbacks.RegisterDefaultCallbacks(db, &callbacks.Config{})
	db.ConnPool = d.Conn
	return nil
}

func (d Dialector) Migrator(db *gorm.DB) gorm.Migrator {
	return Migrator{migrator.Migrator{Config: migrator.Config{
		DB:                          db,
		Dialector:                   d,
		CreateIndexAfterCreateTable: true,
	}}}
}

func (d Dialector) DataTypeOf(field *schema.Field) string {
	switch field.DataType {
	case schema.Bool:
		return "numeric"
	case schema.Int, schema.Uint:
		return "integer"
	case schema.Float:
		return "real"
	case schema.String:
		return "text"
	case schema.Time:
		return "datetime"
	case schema.Bytes:
		return "blob"
	default:
		return string(field.DataType)
	}
}

func (d Dialector) DefaultValueOf(field *schema.Field) clause.Expression {
	return clause.Expr{SQL: "NULL"}
}

func (d Dialector) BindVarTo(writer clause.Writer, stmt *gorm.Statement, v interface{}) {
	writer.WriteByte('?')
}

func (d Dialector) QuoteTo(writer clause.Writer, str string) {
	writer.WriteByte('`')
	writer.WriteString(str)
	writer.WriteByte('`')
}

func (d Dialector) Explain(sql string, vars ...interface{}) string {
	return logger.ExplainSQL(sql, nil, `"`, vars...)
}

type Migrator struct {
	migrator.Migrator
}

func (m Migrator) HasTable(value interface{}) bool {
	var count int
	m.Migrator.RunWithValue(value, func(stmt *gorm.Statement) error {
		return m.DB.Raw("SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?", stmt.Table).Row().Scan(&count)
	})
	return count > 0
}

func (m Migrator) HasColumn(value interface{}, field string) bool {
	var count int
	m.Migrator.RunWithValue(value, func(stmt *gorm.Statement) error {
		if stmt.Schema != nil {
			if f := stmt.Schema.LookUpField(field); f != nil {
				field = f.DBName
			}
		}
		if field != "" {
			// Using pragma_table_info for column checking
			m.DB.Raw("SELECT count(*) FROM pragma_table_info(?) WHERE name = ?", stmt.Table, field).Row().Scan(&count)
		}
		return nil
	})
	return count > 0
}

func (m Migrator) HasIndex(value interface{}, index string) bool {
	var count int
	m.Migrator.RunWithValue(value, func(stmt *gorm.Statement) error {
		return m.DB.Raw("SELECT count(*) FROM sqlite_master WHERE type='index' AND tbl_name=? AND name=?",
			stmt.Table, index).Row().Scan(&count)
	})
	return count > 0
}

func (m Migrator) HasConstraint(value interface{}, constraint string) bool {
	var count int
	m.Migrator.RunWithValue(value, func(stmt *gorm.Statement) error {
		return m.DB.Raw("SELECT count(*) FROM sqlite_master WHERE type='index' AND tbl_name=? AND name=?",
			stmt.Table, constraint).Row().Scan(&count)
	})
	return count > 0
}

func (m Migrator) AlterColumn(value interface{}, field string) error {
	// SQLite doesn't support ALTER COLUMN operations
	// Return nil to skip the operation silently
	return nil
}

func (m Migrator) CreateConstraint(value interface{}, name string) error {
	// SQLite doesn't support adding constraints after table creation
	// Return nil to skip the operation silently
	return nil
}

func (m Migrator) CurrentDatabase() (name string) {
	return "main"
}