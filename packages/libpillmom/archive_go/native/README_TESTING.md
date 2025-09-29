# Testing Guide

## Project Structure

Following Go conventions, the test files are organized as:

```
native/
├── database/
│   ├── connection.go           # Main database code
│   ├── connection_test.go      # Unit tests (Go convention: same directory)
│   └── libsql_dialector.go     # GORM dialector for go-libsql
├── examples/
│   └── sync_demo.go            # Example program demonstrating sync
├── scripts/
│   ├── build.sh                # Build for current platform
│   ├── build_all.sh            # Build for all platforms
│   ├── build_ios.sh            # Build for iOS
│   ├── build_android.sh        # Build for Android
│   ├── test.sh                 # Test runner script
│   └── clean.sh                # Cleanup script
├── .env                        # Local environment variables (gitignored)
└── .env.example               # Template for environment variables
```

### Go Test Conventions

1. **Unit tests** (`*_test.go`) are in the same package as the code they test
2. **Example programs** are in the `examples/` directory
3. **Scripts** are in the `scripts/` directory

## Setting up Turso Database

## Setting up Environment Variables

To run tests with Turso database sync functionality:

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your Turso credentials:
   ```env
   TURSO_DATABASE_URL=libsql://your-database.turso.io
   TURSO_AUTH_TOKEN=your-auth-token-here
   ```

3. Get your credentials from Turso:
   - Database URL: Found in your Turso dashboard
   - Auth Token: Generate from the Turso CLI or dashboard

## Running Tests

### Quick Test (using test script)
```bash
./scripts/test.sh
```

### Manual Testing
```bash
# Set CGO_ENABLED for go-libsql
export CGO_ENABLED=1

# Run all database tests
go test ./database -v

# Run specific test
go test ./database -v -run TestLocalDatabase

# Run sync tests (requires Turso credentials)
go test ./database -v -run TestEmbeddedReplicaWithSync
```

### Example Programs
```bash
# Run the sync demo program
CGO_ENABLED=1 go run ./examples/sync_demo.go
```

### Building the Library

Libraries are built into platform-specific directories:
- `macos/libpillmom.dylib` - macOS
- `linux/libpillmom.so` - Linux
- `windows/libpillmom.dll` - Windows
- `ios/libpillmom.a` - iOS (static library)
- `android/src/main/jniLibs/*/libpillmom.so` - Android (per architecture)

```bash
# Build for current platform only
./scripts/build.sh

# Build for all platforms (requires cross-compilation tools)
./scripts/build_all.sh

# Build for specific platforms
./scripts/build_ios.sh      # iOS
./scripts/build_android.sh   # Android (all architectures)
```

### Cleaning Up
```bash
# Remove test artifacts and databases
./scripts/clean.sh
```

## Test Coverage

- `TestLocalDatabase` - Tests local SQLite database operations
- `TestEmbeddedReplicaWithSync` - Tests Turso sync functionality (requires credentials)
- `TestMultipleSyncIntervals` - Tests different sync interval configurations

## Notes

- The `.env` file is gitignored and won't be committed to the repository
- Tests will automatically skip Turso-specific tests if credentials are not provided
- CGO must be enabled (`CGO_ENABLED=1`) for go-libsql to work
- **Tests use temporary directories** - All test databases are created in system temp directories and automatically cleaned up
- No test files are left in the `database/` directory after tests complete