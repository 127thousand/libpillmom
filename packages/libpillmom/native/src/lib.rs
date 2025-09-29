mod database;
mod models;
mod repository;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

use once_cell::sync::OnceCell;
use tokio::runtime::Runtime;

static RUNTIME: OnceCell<Runtime> = OnceCell::new();

fn get_runtime() -> &'static Runtime {
    RUNTIME.get_or_init(|| {
        Runtime::new().expect("Failed to create Tokio runtime")
    })
}

#[no_mangle]
pub extern "C" fn init_turso_db(url: *const c_char, auth_token: *const c_char) -> *mut c_char {
    let url = unsafe {
        if url.is_null() {
            return error_response("URL is null");
        }
        CStr::from_ptr(url).to_string_lossy().into_owned()
    };

    let auth_token = unsafe {
        if auth_token.is_null() {
            return error_response("Auth token is null");
        }
        CStr::from_ptr(auth_token).to_string_lossy().into_owned()
    };

    let rt = get_runtime();
    match rt.block_on(database::init_turso_db(&url, &auth_token)) {
        Ok(_) => success_response("Database initialized successfully"),
        Err(e) => error_response(&format!("Failed to initialize database: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn init_local_db(path: *const c_char) -> *mut c_char {
    let path = unsafe {
        if path.is_null() {
            "pillmom.db".to_string()
        } else {
            CStr::from_ptr(path).to_string_lossy().into_owned()
        }
    };

    let rt = get_runtime();
    match rt.block_on(database::init_local_db(&path)) {
        Ok(_) => success_response("Local database initialized successfully"),
        Err(e) => error_response(&format!("Failed to initialize local database: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn sync_database() -> *mut c_char {
    let rt = get_runtime();
    match rt.block_on(database::sync_database()) {
        Ok(frame_no) => {
            let response = serde_json::json!({
                "success": true,
                "frameNo": frame_no
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to sync database: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn close_database() -> *mut c_char {
    let rt = get_runtime();
    match rt.block_on(database::close_database()) {
        Ok(_) => success_response("Database closed successfully"),
        Err(e) => error_response(&format!("Failed to close database: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn create_medication(json_data: *const c_char) -> *mut c_char {
    let json_str = unsafe {
        if json_data.is_null() {
            return error_response("JSON data is null");
        }
        CStr::from_ptr(json_data).to_string_lossy().into_owned()
    };

    let med: models::Medication = match serde_json::from_str(&json_str) {
        Ok(m) => m,
        Err(e) => return error_response(&format!("Invalid JSON: {}", e)),
    };

    let rt = get_runtime();
    match rt.block_on(repository::create_medication(&med)) {
        Ok(id) => {
            let response = serde_json::json!({
                "success": true,
                "id": id
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to create medication: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn get_all_medications() -> *mut c_char {
    let rt = get_runtime();
    match rt.block_on(repository::get_all_medications()) {
        Ok(medications) => {
            let response = serde_json::json!({
                "success": true,
                "medications": medications
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to get medications: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn update_medication(json_data: *const c_char) -> *mut c_char {
    let json_str = unsafe {
        if json_data.is_null() {
            return error_response("JSON data is null");
        }
        CStr::from_ptr(json_data).to_string_lossy().into_owned()
    };

    let med: models::Medication = match serde_json::from_str(&json_str) {
        Ok(m) => m,
        Err(e) => return error_response(&format!("Invalid JSON: {}", e)),
    };

    let rt = get_runtime();
    match rt.block_on(repository::update_medication(&med)) {
        Ok(updated) => {
            let response = serde_json::json!({
                "success": true,
                "updated": updated
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to update medication: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn delete_medication(id: i64) -> *mut c_char {
    let rt = get_runtime();
    match rt.block_on(repository::delete_medication(id)) {
        Ok(deleted) => {
            let response = serde_json::json!({
                "success": true,
                "deleted": deleted
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to delete medication: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn create_reminder(json_data: *const c_char) -> *mut c_char {
    let json_str = unsafe {
        if json_data.is_null() {
            return error_response("JSON data is null");
        }
        CStr::from_ptr(json_data).to_string_lossy().into_owned()
    };

    let reminder: models::Reminder = match serde_json::from_str(&json_str) {
        Ok(r) => r,
        Err(e) => return error_response(&format!("Invalid JSON: {}", e)),
    };

    let rt = get_runtime();
    match rt.block_on(repository::create_reminder(&reminder)) {
        Ok(id) => {
            let response = serde_json::json!({
                "success": true,
                "id": id
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to create reminder: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn get_active_reminders() -> *mut c_char {
    let rt = get_runtime();
    match rt.block_on(repository::get_active_reminders()) {
        Ok(reminders) => {
            let response = serde_json::json!({
                "success": true,
                "reminders": reminders
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to get reminders: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn update_reminder(json_data: *const c_char) -> *mut c_char {
    let json_str = unsafe {
        if json_data.is_null() {
            return error_response("JSON data is null");
        }
        CStr::from_ptr(json_data).to_string_lossy().into_owned()
    };

    let reminder: models::Reminder = match serde_json::from_str(&json_str) {
        Ok(r) => r,
        Err(e) => return error_response(&format!("Invalid JSON: {}", e)),
    };

    let rt = get_runtime();
    match rt.block_on(repository::update_reminder(&reminder)) {
        Ok(updated) => {
            let response = serde_json::json!({
                "success": true,
                "updated": updated
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to update reminder: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn delete_reminder(id: i64) -> *mut c_char {
    let rt = get_runtime();
    match rt.block_on(repository::delete_reminder(id)) {
        Ok(deleted) => {
            let response = serde_json::json!({
                "success": true,
                "deleted": deleted
            });
            string_to_c_char(&response.to_string())
        }
        Err(e) => error_response(&format!("Failed to delete reminder: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

// Helper functions
fn string_to_c_char(s: &str) -> *mut c_char {
    match CString::new(s) {
        Ok(c_str) => c_str.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

fn error_response(msg: &str) -> *mut c_char {
    let response = serde_json::json!({
        "success": false,
        "error": msg
    });
    string_to_c_char(&response.to_string())
}

fn success_response(msg: &str) -> *mut c_char {
    let response = serde_json::json!({
        "success": true,
        "message": msg
    });
    string_to_c_char(&response.to_string())
}