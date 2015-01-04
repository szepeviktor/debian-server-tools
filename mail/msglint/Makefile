#
# makefile for msglint
#
OBJS=msglint.o imaildate.o md5c.o
CFLAGS=-g

msglint: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

clean:
	rm -f $(OBJS) msglint

dist:
	gtar zcvf msglint-src.tar.gz LICENSE Makefile msglint.c imaildate.c imaildate.h md5.h md5c.c
