/*
# VERSION       :0.9.1
# SOURCE        :https://github.com/mlsorensen/seekmark
# LOCATION      :/root/hdd-bench/seekmark-0.9.1.c
# COMPILE       :gcc -o seekmark -lpthread -O3 seekmark-*.c

Written by Marcus Sorensen
Copyright (C) 2010-2011
learnitwithme.com

SeekMark - a threaded random I/O tester, designed to test the number of seeks
and hence get a rough idea of the access time of a disk and the number of iops
it can perform .  It was loosely inspired by the 'seeker' program
(http://www.linuxinsight.com/how_fast_is_your_disk.html), when it was noticed
that the results from seeker were very much the same for a RAID array as for a
single disk, and a look at the code showed that it was doing one random read at
a time, basically only triggering access to one drive and waiting for that to
complete before continuing. What we want to see is not only the performance of
a single spindle, but how much benefit we get on random reads as we add
spindles.

This code has been successfully compiled and run on Linux. The source for this
program (SeekMark) is distributed under the Clarified Artistic License. This is
unsupported software, but please make an effort to report any bugs to me at
<mlsorensen@mlsorensen.com>

compile example: gcc -o seekmark seekmark.c -lpthread -O3

Versions:
0.1 - Release Candidate 1

0.3 - Changed various reporting items

0.7 - Added write benchmark (USE AT YOUR OWN RISK), optional specification of
      I/O size, quiet flag.

0.8 - Added ability to disable random data writing, uses char '234' for all
      bytes written.

0.8.1 - Changed block != bytes in seekthenreadwrite to warn

0.8.2 - Threads each open their own fd now

0.9 - Add option to insert a delay between random read or write, to provide
      a load generating functionality. With this, you can for example load your
      disks to 50% of their capability or some such live load simulation.
      Include endless mode.

0.9.1 - Add 'aligned' option (submitted by Stefan Seidel http://stefanseidel.info/)
*/

#define _FILE_OFFSET_BITS 64

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/timeb.h>
#include <pthread.h>

char version[] = "SeekMark 0.9.2 (8/27/2013) by Marcus Sorensen";

char *file[255] = {""};//output file name
int fd;
off_t size;

/* defaults */
int seeks = 5000;
int numthreads = 1;
off_t sizelimit = 0;
int writetest = 0;
int block = 512;
int quiet = 0;
int writerandomdata = 1;
int delay = 0;
int endless = 0;
int align = 0;

/* prototypes */
void seekthenreadwrite(int fd, off_t offset);
void * threadseek(void * ptr);
void usage();
void datafill(char * buffer, int makerandom);
void getargs(int argc, char *argv[]);

int main(int argc, char *argv[]) {

        //don't buffer what we print
        setvbuf(stdout, NULL, _IONBF, 0);
        setvbuf(stderr, NULL, _IONBF, 0);

        //get arguments, set things up
        getargs(argc,argv);
        if(writetest == 1 && writerandomdata == 0) {
                fprintf(stderr,"warning: -R flag (write non-random data) has no effect on read test\n");
        }

        //convert our delay to microseconds for the usleep function
        delay = delay * 1000;

        //warn if endless mode is enabled
        if(endless == 1){
                printf("***WARNING: Endless mode enabled, we will simply run until killed!***\n");
        }

        pthread_t threads[numthreads];//create an array of threads
        errno=0;
        int i;
        struct timeb starttm,endtm; //keep track of timing on things
        long long int startsec,endsec,position,printsize;
        double startms,endms,totaltime,totalseekspersec;
        char unit[3] = "B";
        char mode[6] = "READ";

        //test file
        if(writetest == 1) {
                fd=open(*file,O_RDWR|O_SYNC);
                strcpy(mode,"WRITE");
        }
        else {
                fd=open(*file, O_RDONLY);
        }

        if(fd == -1) {
                usage();
                fprintf(stderr,"\nfile %s is not readable: %s\n\n", *file,strerror(errno));
                exit(1);
        }

        size = lseek(fd,0,SEEK_END);
        if (sizelimit > 0) {
        fprintf(stderr,"\nsetting size limit to %lld\n",sizelimit);
                size = sizelimit;
        }

        close(fd);

        if(size == -1) {
                fprintf(stderr,"\nfile %s is not readable: %s\n\n", *file,strerror(errno));
                exit(1);
        }

        //format display of file size
        printsize = size;
        if(size > 1048576) {
                printsize = printsize>>20;
                strcpy(unit,"MB");
        }
        else if (size > 1024) {
                printsize = printsize>>10;
                strcpy(unit,"KB");
        }

        printf("\n%s benchmarking against %s %lld %s\n\n", mode, *file, printsize, unit);
        if(quiet == 0) {
                printf("threads to spawn: %d\n",numthreads);
                printf("seeks per thread: %d\n",seeks);
                printf("io size in bytes: %d\n",block);
                printf("io aligned bytes: %d\n",1 << align);
                if(sizelimit > 0) {
                        printf("size limit in bytes: %lld\n",sizelimit);
                }
                if(writetest == 1) {
                        if(writerandomdata == 1) {
                                printf("write data is randomly generated\n");
                        }
                        else {
                                printf("write data is single character repeated\n");
                        }
                }
                printf("\n");
        }

        //seed random
        srand((long int)time(NULL));

        //get start time
        ftime(&starttm);
        startsec = starttm.time;
        startms = starttm.millitm;

        //go to work
        for(i = 0; i < numthreads; i++) {
                if(quiet == 0) {
                        if(endless == 1){
                                printf("Spawning worker %d to do endless seeks\n",i);
                        }
                        else{
                                printf("Spawning worker %d to do %d seeks\n",i,seeks);
                        }
                }
                pthread_create(&threads[i], NULL, threadseek, (void*)(long)i);
        }

        //wait for the threads to complete
        for(i = 0; i < numthreads; i++) {
                pthread_join( threads[i], NULL);
        }

        //get end time
        ftime(&endtm);
        endsec = endtm.time;
        endms = endtm.millitm;
        totaltime = (double)(endsec-startsec)+((endms-startms)/1000);
        totalseekspersec = ((double)seeks*numthreads)/totaltime;

        printf("\ntotal time: %.2lf, time per %s request(ms): %.3f\n%.2f total seeks per sec, %.2f %s seeks per sec per thread\n\n", totaltime, mode, (1/totalseekspersec)*1000, totalseekspersec, totalseekspersec/numthreads, mode);

}

void * threadseek(void * ptr) {
        int i;
        int threadnum = (long)ptr;
        int tfd;

        //open fd just for me
        if(writetest == 1) {
                tfd=open(*file,O_RDWR|O_SYNC);
        }
        else {
                tfd=open(*file, O_RDONLY);
        }

        //keep track of timing on things
        struct timeb starttm,endtm;
        long long int startsec,endsec;
        double startms,endms,totaltime,seekspersec;

        //get start time
        ftime(&starttm);
        startsec = starttm.time;
        startms = starttm.millitm;

        //do work
        off_t position;
        for(i=0;i<(seeks);i+=endless^1) {
                position = size * ((float)rand()/RAND_MAX);
                if(position > (size - block)) {
                        position = (size - block);
                }
                seekthenreadwrite(tfd,position&~0<<align);
        }

        //get end time
        ftime(&endtm);
        endsec = endtm.time;
        endms = endtm.millitm;
        totaltime = (double)(endsec-startsec)+((endms-startms)/1000);
        seekspersec = ((double)seeks)/totaltime;

        close(tfd);

        if(quiet == 0) {
                printf("thread %d completed, time: %.2lf, %.2f seeks/sec, %.1fms per request\n",threadnum,totaltime,seekspersec,(1/seekspersec)*1000);
        }


}

void seekthenreadwrite(int tfd, off_t offset) {
        off_t seekpos = lseek(tfd,offset,SEEK_SET);
        char buf[block];

        if(delay > 0 ) {
                usleep(delay);
        }

        if( seekpos == -1) {
                printf("failed to seek to %lld/%lld: %s\n",(long long int)seekpos,(long long int)offset,strerror(errno));
        }

        if(writetest == 1) {
                datafill(buf,writerandomdata);
                int bytes = write(tfd, buf, block);
                if(bytes <= 0) {
                        fprintf(stderr, "Error: unable to write at current position of %lld: %s\n",(long long int)seekpos,strerror(errno));
                }
                else if(bytes != block) {
                        fprintf(stderr, "Error: unable to write full io of %d to position %lld in file of size %lld\n",block,(long long int)offset,(long long int)size);
                }
        }
        else {
                int bytes = read(tfd, buf, block);
                if(bytes <= 0) {
                        fprintf(stderr, "Error: unable to read at current position of %lld: %s\n",(long long int)seekpos,strerror(errno));
                }
                else if(bytes != block) {
                        fprintf(stderr, "Warning: unable to read full io of %d bytes (got %d bytes) from position %lld in file of size %lld\n",block,bytes,(long long int)offset,(long long int)size);
                }
        }


}

void datafill(char * buffer,int makerandom) {
        int i;
        unsigned int rand_state;

        /*tested this several different ways, there didn't seem to be any performance difference between filling a block one
        random character at a time, vs filling with identical characters one at a time, vs memsetting the entire block at once.
        There was no noticeable difference. Will leave in the option of using semi-random vs non-random data for compressible
        data vs non-compressible data tests*/

        if(makerandom = 1) {
                for(i = 0; i < block; i++) {
                        int randchar;
                        randchar = 255 * ((float)rand_r(&rand_state)/RAND_MAX);
                        buffer[i] = randchar;
                }
        }
        else {
                memset(buffer,234,block);
        }
}

void getargs(int argc, char *argv[]) {
        int c;
        int gotrequired = 0;

        while ((c = getopt (argc, argv, "S:f:t:a:s:hw:Ri:qd:e")) != -1){
                switch(c) {
                        case 'f':
                                if(strlen(optarg) > (sizeof(file)/sizeof(*file))){
                                        fprintf(stderr,"\nfile name too long, size should be <= %lu chars\n\n",(long)sizeof(file)/sizeof(*file));
                                        exit(1);
                                }
                                *file = optarg;
                                gotrequired = 1;
                                break;
                        case 'S':
                                if(atoll(optarg) < 0) {
                                        fprintf(stderr, "\nsize limit should be a positive integer\n\n");
                                        exit(1);
                                }
                                sizelimit = atoll(optarg);
                                fprintf(stderr,"size limit is %lld\n",sizelimit);
                                break;
                        case 't':
                                if(atoi(optarg) < 1) {
                                        fprintf(stderr,"\nthreads should be a positive integer\n\n");
                                        exit(1);
                                }
                                numthreads = atoi(optarg);
                                break;
                        case 'a':
                                if(atoi(optarg) < 1) {
                                        fprintf(stderr,"\nalignment should be a positive integer\n\n");
                                        exit(1);
                                }
                                align = atoi(optarg);
                                break;
                        case 's':
                                if(atoi(optarg) < 1) {
                                        fprintf(stderr,"\nseeks should be a positive integer\n\n");
                                        exit(1);
                                }
                                seeks = atoi(optarg);
                                break;
                        case 'h':
                                usage();
                                exit(1);
                        case 'w':
                                if(strcmp(optarg,"destroy-data") != 0) {
                                        fprintf(stderr,"\n'w' flag was used without argument 'destroy-data', please add this if you really want to do a write test\n\n");
                                        exit(1);
                                }
                                writetest = 1;
                                break;
                        case 'R':
                                writerandomdata = 0;
                                break;
                        case 'i':
                                block = atoi(optarg);
                                if(block < 1 || block > 1048577) {
                                        fprintf(stderr,"\nio size should be greater than zero, less than 1048577\n\n");
                                        exit(1);
                                }
                                break;
                        case 'q':
                                quiet = 1;
                                break;
                        case 'd' :
                                delay = atoi(optarg);
                                if(delay < 1 || delay > 10000) {
                                        fprintf(stderr,"\ndelay should be a positive integer between 1 and 10000\n\n");
                                        exit(1);
                                }
                                break;
                        case 'e':
                                endless = 1;
                                break;
                }
        }

        if(gotrequired == 0) {
                usage();
                fprintf(stderr,"\nPlease provide a filename with the -f flag\n\n");
                exit(1);
        }
}

void usage(){
        fprintf(stderr,"\n%s\n\n",version);
        fprintf(stderr,"Usage: seekmark -f FILENAME [OPTIONS]...\n\n");

        fprintf(stderr,"Defaults used are:\n");
        fprintf(stderr,"  read-only test\n");
        fprintf(stderr,"  verbose reporting\n");
        fprintf(stderr,"  threads:      1\n");
        fprintf(stderr,"  seeks/thread: 5000\n");
        fprintf(stderr,"  io size:      512");
        fprintf(stderr,"\n\n");
        fprintf(stderr,"OPTIONS:\n");
        fprintf(stderr,"  -f FILENAME      File to random read, device or filesystem file\n");
        fprintf(stderr,"  -t INTEGER       Number of worker threads to spawn\n");
        fprintf(stderr,"  -s INTEGER       Number of seeks to execute per thread\n");
        fprintf(stderr,"  -a INTEGER       Align seeks to 2^INTEGER byte boundaries, ex.: 9=>512, 12=>4096\n");
        fprintf(stderr,"  -w destroy-data  Do a write iops test (destructive to file specified)\n");
        fprintf(stderr,"  -R               Disable use of random data for write test\n");
        fprintf(stderr,"  -i INTEGER       io size (in bytes) to use for iops\n");
        fprintf(stderr,"  -q               turn off per-thread reporting\n");
        fprintf(stderr,"  -d INTEGER       add milliseconds of delay between IOs (to generate partial loads)\n");
        fprintf(stderr,"  -e               run in endless mode (good for load generator); run until killed\n");
        fprintf(stderr,"  -S               limit disk/file seek size (for example if size of disk is not detected)\n");
        fprintf(stderr,"  -h               Print this help dialog and exit\n");
}

/*
                    The Clarified Artistic License

                                Preamble

The intent of this document is to state the conditions under which a
Package may be copied, such that the Copyright Holder maintains some
semblance of artistic control over the development of the package,
while giving the users of the package the right to use and distribute
the Package in a more-or-less customary fashion, plus the right to make
reasonable modifications.

Definitions:

        "Package" refers to the collection of files distributed by the
        Copyright Holder, and derivatives of that collection of files
        created through textual modification.

        "Standard Version" refers to such a Package if it has not been
        modified, or has been modified in accordance with the wishes
        of the Copyright Holder as specified below.

        "Copyright Holder" is whoever is named in the copyright or
        copyrights for the package.

        "You" is you, if you're thinking about copying or distributing
        this Package.

        "Distribution fee" is a fee you charge for providing a copy
        of this Package to another party.

        "Freely Available" means that no fee is charged for the right to
        use the item, though there may be fees involved in handling the
        item.  It also means that recipients of the item may redistribute
        it under the same conditions they received it.

1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you
duplicate all of the original copyright notices and associated disclaimers.

2. You may apply bug fixes, portability fixes and other modifications
derived from the Public Domain, or those made Freely Available, or from
the Copyright Holder.  A Package modified in such a way shall still be
considered the Standard Version.

3. You may otherwise modify your copy of this Package in any way, provided
that you insert a prominent notice in each changed file stating how and
when you changed that file, and provided that you do at least ONE of the
following:

    a) place your modifications in the Public Domain or otherwise make them
    Freely Available, such as by posting said modifications to Usenet or an
    equivalent medium, or placing the modifications on a major network
    archive site allowing unrestricted access to them, or by allowing the
    Copyright Holder to include your modifications in the Standard Version
    of the Package.

    b) use the modified Package only within your corporation or organization.

    c) rename any non-standard executables so the names do not conflict
    with standard executables, which must also be provided, and provide
    a separate manual page for each non-standard executable that clearly
    documents how it differs from the Standard Version.

    d) make other distribution arrangements with the Copyright Holder.

    e) permit and encourge anyone who receives a copy of the modified Package
       permission to make your modifications Freely Available
       in some specific way.


4. You may distribute the programs of this Package in object code or
executable form, provided that you do at least ONE of the following:

    a) distribute a Standard Version of the executables and library files,
    together with instructions (in the manual page or equivalent) on where
    to get the Standard Version.

    b) accompany the distribution with the machine-readable source of
    the Package with your modifications.

    c) give non-standard executables non-standard names, and clearly
    document the differences in manual pages (or equivalent), together
    with instructions on where to get the Standard Version.

    d) make other distribution arrangements with the Copyright Holder.

    e) offer the machine-readable source of the Package, with your
       modifications, by mail order.

5. You may charge a distribution fee for any distribution of this Package.
If you offer support for this Package, you may charge any fee you choose
for that support.  You may not charge a license fee for the right to use
this Package itself.  You may distribute this Package in aggregate with
other (possibly commercial and possibly nonfree) programs as part of a
larger (possibly commercial and possibly nonfree) software distribution,
and charge license fees for other parts of that software distribution,
provided that you do not advertise this Package as a product of your own.
If the Package includes an interpreter, You may embed this Package's
interpreter within an executable of yours (by linking); this shall be
construed as a mere form of aggregation, provided that the complete
Standard Version of the interpreter is so embedded.

6. The scripts and library files supplied as input to or produced as
output from the programs of this Package do not automatically fall
under the copyright of this Package, but belong to whoever generated
them, and may be sold commercially, and may be aggregated with this
Package.  If such scripts or library files are aggregated with this
Package via the so-called "undump" or "unexec" methods of producing a
binary executable image, then distribution of such an image shall
neither be construed as a distribution of this Package nor shall it
fall under the restrictions of Paragraphs 3 and 4, provided that you do
not represent such an executable image as a Standard Version of this
Package.

7. C subroutines (or comparably compiled subroutines in other
languages) supplied by you and linked into this Package in order to
emulate subroutines and variables of the language defined by this
Package shall not be considered part of this Package, but are the
equivalent of input as in Paragraph 6, provided these subroutines do
not change the language in any way that would cause it to fail the
regression tests for the language.

8. Aggregation of the Standard Version of the Package with a commercial
distribution is always permitted provided that the use of this Package
is embedded; that is, when no overt attempt is made to make this Package's
interfaces visible to the end user of the commercial distribution.
Such use shall not be construed as a distribution of this Package.

9. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.

10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

                                The End
*/
