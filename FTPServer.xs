/* -*- text -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdlib.h>
#include <string.h>
#include <signal.h>

/*#include <Net::FTPServer>*/

/* We kind of assume Unix-like signals here ... */
static volatile unsigned signals = 0;

static void
signal_handler (int s)
{
	signals |= 1 << s;
}

MODULE = Net::FTPServer		PACKAGE = Net::FTPServer
PROTOTYPES: ENABLE

void
_install_signals ()
CODE:
	struct sigaction sa;

	memset (&sa, 0, sizeof sa);
	sa.sa_handler = signal_handler;
	sa.sa_flags = SA_NOCLDSTOP | SA_RESTART;
	if (sigaction (SIGCHLD, &sa, NULL) == -1)
		croak ("sigaction: errno = %d", errno);
	sa.sa_flags = SA_RESTART;
	if (sigaction (SIGURG,  &sa, NULL) == -1)
		croak ("sigaction: errno = %d", errno);
	if (sigaction (SIGHUP,  &sa, NULL) == -1)
		croak ("sigaction: errno = %d", errno);
	if (sigaction (SIGTERM, &sa, NULL) == -1)
		croak ("sigaction: errno = %d", errno);

unsigned
_test_and_clear_signals ()
CODE:
	sigset_t ss;

	/* Avoid the system call overhead in the common case where there
	 * are no signals waiting.
	 */
	if (signals == 0) RETVAL = 0;
	else {
		sigfillset (&ss);
		sigprocmask (SIG_BLOCK, &ss, 0);
		RETVAL = signals;
		signals = 0;
		sigprocmask (SIG_UNBLOCK, &ss, 0);
	}
OUTPUT:
	RETVAL

int
SIGURG ()
CODE:
	RETVAL = SIGURG;
OUTPUT:
	RETVAL

int
SIGCHLD ()
CODE:
	RETVAL = SIGCHLD;
OUTPUT:
	RETVAL

int
SIGHUP ()
CODE:
	RETVAL = SIGHUP;
OUTPUT:
	RETVAL

int
SIGTERM ()
CODE:
	RETVAL = SIGTERM;
OUTPUT:
	RETVAL
