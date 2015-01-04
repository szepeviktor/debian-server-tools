/* imaildate.c -- generate an Internet mail date string
 *
 * (C) Copyright 1991-1997 Christopher J. Newman
 * All Rights Reserved.
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of Christopher J. Newman not be used in
 * advertising or publicity pertaining to distribution of the software without
 * specific, written prior permission.  Christopher J. Newman makes no
 * representations about the suitability of this software for any purpose.
 * It is provided "as is" without express or implied warranty.
 *
 * CHRISTOPHER J. NEWMAN DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT
 * SHALL CHRISTOPHER J. NEWMAN BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 * DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
 * OF THIS SOFTWARE.
 *
 * Author:	  Christopher J. Newman
 * Message:	  This is a nifty program.
 */

#include <time.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include "imaildate.h"

static char *dayofweek[] = {
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
};
static char *month[] = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};
#define ZONESIZE 7

/* generate an Internet mail date string
 */
void n_maildate(char *buf)
{
    time_t now;
    struct tm local, gmt;
    char tzbuf[ZONESIZE];
    long zminutes;
    char zsign, zdst;

    /* get time */
    now = time(NULL);
#ifdef __APPLE__
    local = *localtime(&now);
    gmt = *gmtime(&now);
#else
    localtime_r(&now, &local);
    gmtime_r(&now, &gmt);
#endif
    
    /* get GMT offset */
    zminutes = local.tm_yday - gmt.tm_yday;
    if (zminutes > 1) {
	zminutes = -24;
    } else if (zminutes < -1) {
	zminutes = 24;
    } else {
	zminutes *= 24;
    }
    zminutes = (zminutes + local.tm_hour - gmt.tm_hour) * 60
	+ local.tm_min - gmt.tm_min;

    /* create timezone */
    *tzbuf = '\0';
    zsign = '+';
    zdst = 'S';
    if (local.tm_isdst) {
	zdst = 'D';
    }
    if (zminutes < 0) {
	zsign = '-';
	zminutes = -zminutes;
	if (zminutes >= 240 && zminutes <= 660 && zminutes % 60 == 0) {
	    sprintf(tzbuf, " (%c%cT)", "AECMPYHB"
		    [(zminutes / 60) - (zdst == 'D' ? 3 : 4)], zdst);
	}
    }

    /* create Internet date */
    sprintf(buf, "%s, %d %s %d %02d:%02d:%02d %c%02ld%02ld%s",
	    dayofweek[local.tm_wday],
	    local.tm_mday,
	    month[local.tm_mon],
	    local.tm_year + 1900,
	    local.tm_hour, local.tm_min, local.tm_sec,
	    zsign, (unsigned long) (zminutes / 60),
	    (unsigned long) (zminutes % 60), tzbuf);
}
