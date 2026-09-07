/* iOS port: crash reporter. A native crash writes <Documents>/te4_crash.txt with the
 * signal, a C backtrace, the last Lua error and the tail of the game log, so a crash
 * the player relaunches after (which overwrites te4_log.txt) is still readable. */
#ifndef TE4_IOS_CRASH_H
#define TE4_IOS_CRASH_H

/* Install the signal handlers. documents_path is where te4_crash.txt is written and
 * where te4_log.txt lives (its tail is copied into the report). Safe to call once. */
void te4_ios_install_crash_handler(const char *documents_path);

/* Remember a short note (a Lua traceback, at most 2 KB) for the next crash report. */
void te4_ios_crash_note(const char *s);

#endif
