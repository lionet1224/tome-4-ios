/* iOS port: crash reporter. See ios_crash.h.
 *
 * Everything inside the signal handler is async-signal-safe: open/write/read/lseek/
 * close, backtrace_symbols_fd, sigaction, raise. No malloc, no stdio. The "recent log"
 * section is the tail of te4_log.txt read back from disk (main.c line-buffers it),
 * which avoids hooking stdout. */
#include "ios_crash.h"

#include <execinfo.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define CRASH_NOTE_MAX 2048
#define CRASH_LOG_TAIL (8 * 1024)
#define CRASH_STACK_SIZE (64 * 1024)
#define CRASH_FRAMES 64

static char crash_path[1200];
static char log_path[1200];
static char crash_note[CRASH_NOTE_MAX];
static volatile sig_atomic_t crash_in_progress = 0;
static int installed = 0;

/* signal-safe helpers */
static void wr(int fd, const char *s) { size_t n = strlen(s); while (n) { ssize_t k = write(fd, s, n); if (k <= 0) break; s += k; n -= (size_t)k; } }

static void wr_num(int fd, long v)
{
	char buf[24]; int i = sizeof(buf); int neg = v < 0;
	unsigned long u = neg ? (unsigned long)(-v) : (unsigned long)v;
	buf[--i] = 0;
	do { buf[--i] = (char)('0' + u % 10); u /= 10; } while (u && i > 1);
	if (neg && i > 0) buf[--i] = '-';
	wr(fd, buf + i);
}

static const char *sig_name(int sig)
{
	switch (sig) {
	case SIGSEGV: return "SIGSEGV";
	case SIGBUS: return "SIGBUS";
	case SIGILL: return "SIGILL";
	case SIGFPE: return "SIGFPE";
	case SIGABRT: return "SIGABRT";
	case SIGTRAP: return "SIGTRAP";
	default: return "signal";
	}
}

static void copy_log_tail(int fd)
{
	if (!log_path[0]) { wr(fd, "(no log path)\n"); return; }
	int lf = open(log_path, O_RDONLY);
	if (lf < 0) { wr(fd, "(log not readable)\n"); return; }
	off_t end = lseek(lf, 0, SEEK_END);
	if (end < 0) { close(lf); wr(fd, "(log not seekable)\n"); return; }
	off_t start = end > CRASH_LOG_TAIL ? end - CRASH_LOG_TAIL : 0;
	lseek(lf, start, SEEK_SET);
	static char buf[4096];
	for (;;) {
		ssize_t k = read(lf, buf, sizeof(buf));
		if (k <= 0) break;
		const char *p = buf; size_t n = (size_t)k;
		while (n) { ssize_t w = write(fd, p, n); if (w <= 0) break; p += w; n -= (size_t)w; }
	}
	close(lf);
	wr(fd, "\n");
}

static void crash_handler(int sig, siginfo_t *info, void *ctx)
{
	(void)ctx;
	if (crash_in_progress) { /* a crash inside the handler: give up */
		signal(sig, SIG_DFL);
		raise(sig);
		return;
	}
	crash_in_progress = 1;

	int fd = open(crash_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd >= 0) {
		wr(fd, "=== ToME iOS crash report ===\n");
		wr(fd, "signal: "); wr_num(fd, sig); wr(fd, " ("); wr(fd, sig_name(sig)); wr(fd, ")\n");
		if (info) { wr(fd, "code: "); wr_num(fd, info->si_code); wr(fd, "  addr: "); wr_num(fd, (long)(intptr_t)info->si_addr); wr(fd, "\n"); }
		wr(fd, "time (unix): "); wr_num(fd, (long)time(NULL)); wr(fd, "\n\n");

		wr(fd, "--- C backtrace ---\n");
		void *frames[CRASH_FRAMES];
		int n = backtrace(frames, CRASH_FRAMES);
		backtrace_symbols_fd(frames, n, fd);
		wr(fd, "\n");

		wr(fd, "--- last Lua error (if any) ---\n");
		if (crash_note[0]) { wr(fd, crash_note); wr(fd, "\n\n"); } else wr(fd, "(none)\n\n");

		wr(fd, "--- tail of te4_log.txt ---\n");
		copy_log_tail(fd);
		wr(fd, "=== end ===\n");
		close(fd);
	}

	/* let the default action happen (the system's own crash log still gets written) */
	signal(sig, SIG_DFL);
	raise(sig);
}

void te4_ios_crash_note(const char *s)
{
	if (!s) { crash_note[0] = 0; return; }
	size_t n = strlen(s);
	if (n >= CRASH_NOTE_MAX) n = CRASH_NOTE_MAX - 1;
	memcpy(crash_note, s, n);
	crash_note[n] = 0;
}

void te4_ios_install_crash_handler(const char *documents_path)
{
	if (installed) return;
	installed = 1;
	crash_note[0] = 0;
	if (documents_path && documents_path[0]) {
		size_t n = strlen(documents_path);
		if (n > sizeof(crash_path) - 32) n = sizeof(crash_path) - 32;
		memcpy(crash_path, documents_path, n);
		crash_path[n] = 0;
		strcat(crash_path, "/te4_crash.txt");
		memcpy(log_path, documents_path, n);
		log_path[n] = 0;
		strcat(log_path, "/te4_log.txt");
	} else {
		strcpy(crash_path, "/tmp/te4_crash.txt");
		strcpy(log_path, "/tmp/te4_log.txt");
	}

	/* an alternate stack so a stack overflow still gets reported */
	static char *altstack = NULL;
	if (!altstack) altstack = malloc(CRASH_STACK_SIZE);
	if (altstack) {
		stack_t ss;
		ss.ss_sp = altstack;
		ss.ss_size = CRASH_STACK_SIZE;
		ss.ss_flags = 0;
		sigaltstack(&ss, NULL);
	}

	struct sigaction sa;
	memset(&sa, 0, sizeof(sa));
	sa.sa_sigaction = crash_handler;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = SA_SIGINFO | SA_ONSTACK;
	const int sigs[] = { SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGABRT, SIGTRAP };
	size_t i;
	for (i = 0; i < sizeof(sigs) / sizeof(sigs[0]); i++) sigaction(sigs[i], &sa, NULL);
}
