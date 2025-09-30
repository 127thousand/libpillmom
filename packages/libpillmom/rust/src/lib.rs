mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
// Required for Flutter Rust Bridge
pub mod api;
mod database;
mod entities;
pub mod models;
mod repository;

// Re-export for Flutter Rust Bridge
pub use api::*;
pub use models::{Medication, Reminder};

// Initialize flutter_rust_bridge
// The macro was already injected by the code generator