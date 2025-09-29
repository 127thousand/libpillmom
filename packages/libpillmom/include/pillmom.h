#include <cstdarg>
#include <cstdint>
#include <cstdlib>
#include <ostream>
#include <new>

extern "C" {

char *init_turso_db(const char *url, const char *auth_token);

char *init_local_db(const char *path);

char *sync_database();

char *close_database();

char *create_medication(const char *json_data);

char *get_all_medications();

char *update_medication(const char *json_data);

char *delete_medication(int64_t id);

char *create_reminder(const char *json_data);

char *get_active_reminders();

char *update_reminder(const char *json_data);

char *delete_reminder(int64_t id);

void free_string(char *s);

} // extern "C"
