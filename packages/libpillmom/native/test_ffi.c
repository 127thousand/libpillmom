#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

typedef char* (*init_local_db_fn)(const char*);
typedef char* (*create_medication_fn)(const char*);
typedef char* (*get_all_medications_fn)(void);
typedef void (*free_string_fn)(char*);

int main() {
    // Load the library
    void* handle = dlopen("../macos/libpillmom.dylib", RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "Cannot open library: %s\n", dlerror());
        return 1;
    }

    // Load functions
    init_local_db_fn init_local_db = (init_local_db_fn)dlsym(handle, "init_local_db");
    create_medication_fn create_medication = (create_medication_fn)dlsym(handle, "create_medication");
    get_all_medications_fn get_all_medications = (get_all_medications_fn)dlsym(handle, "get_all_medications");
    free_string_fn free_string = (free_string_fn)dlsym(handle, "free_string");

    // Initialize database
    printf("Initializing local database...\n");
    char* result = init_local_db("test.db");
    printf("Result: %s\n", result);
    free_string(result);

    // Create a medication
    printf("\nCreating medication...\n");
    const char* med_json = "{\"name\":\"Test Med\",\"dosage\":\"10mg\",\"description\":\"Test medication\"}";
    result = create_medication(med_json);
    printf("Result: %s\n", result);
    free_string(result);

    // Get all medications
    printf("\nGetting all medications...\n");
    result = get_all_medications();
    printf("Result: %s\n", result);
    free_string(result);

    // Close library
    dlclose(handle);
    printf("\nTest completed successfully!\n");
    return 0;
}