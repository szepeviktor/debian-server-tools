/*
# Seeker with threads
#
# VERSION       :3.0
# DATE          :2009-06-17
# AUTHOR        :https://github.com/baryluk
# LOCATION      :/root/hdd-bench/seeker_baryluk.c
*/

#define _LARGEFILE64_SOURCE

#ifndef _REENTRANT
#define _REENTRANT
#endif
#include <pthread.h>

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <signal.h>
#include <sys/fcntl.h>
#include <sys/ioctl.h>
#include <linux/fs.h>

#define BLOCKSIZE 512
#define TIMEOUT 30

pthread_mutex_t muteks = PTHREAD_MUTEX_INITIALIZER;

int count;
time_t start;
off64_t maxoffset = 0;
off64_t minoffset = 249994674176000uLL;


int threads;

typedef struct {
	int id;
	int fd;
	int run;
	char* filename;
	unsigned int seed;
	unsigned long long numbytes;
	char* buffer;
	int count;
	off64_t maxoffset;
	off64_t minoffset;
} parm;

parm *p;

void done() {
	int i;
	time_t end;

	time(&end);

	if (end < start + TIMEOUT) {
		printf(".");
		alarm(1);
		return;
	}

	for (i = 0; i < threads; i++) {
		p[i].run = 0;
	}
}

void report() {
	if (count) {
		printf(".\nResults: %d seeks/second, %.3f ms random access time (%llu < offsets < %llu)\n",
			count / TIMEOUT, 1000.0 * TIMEOUT / count, (unsigned long long)minoffset, (unsigned long long)maxoffset);
	}
	exit(EXIT_SUCCESS);
}

void handle(const char *string, int error) {
	if (error) {
		perror(string);
		exit(EXIT_FAILURE);
	}
}

void* f(void *arg) {
	int retval;
	off64_t offset;

	parm *p = (parm*)arg;

	srand(p->seed);

	/* wait for all processes */
	pthread_mutex_lock(&muteks);
	pthread_mutex_unlock(&muteks);

	while (p->run) {
		offset = (off64_t) ( (unsigned long long) (p->numbytes * (rand_r(&(p->seed)) / (RAND_MAX + 1.0) )));
		//printf("%d %llu\n", p->id, (unsigned long long )offset);
		retval = lseek64(p->fd, offset, SEEK_SET);
		handle("lseek64", retval == (off64_t) -1);
		retval = read(p->fd, p->buffer, BLOCKSIZE);
		handle("read", retval < 0);

		p->count++;
		if (offset > p->maxoffset) {
			p->maxoffset = offset;
		} else if (offset < p->minoffset) {
			p->minoffset = offset;
		}
	}

	//pthread_exit(NULL);
	return NULL;
}

int main(int argc, char **argv) {
	int fd, retval;
	int physical_sector_size = 0;
	size_t logical_sector_size = 0ULL;
	unsigned long long numblocks, numbytes;
	unsigned long long ull;
	unsigned long ul;
	pthread_t *t_id;
	pthread_attr_t pthread_custom_attr;
	int i;

	setvbuf(stdout, NULL, _IONBF, 0);

	printf("Seeker v3.0, 2009-06-17, "
	       "http://www.linuxinsight.com/how_fast_is_your_disk.html\n");

	if (!(argc == 2 || argc == 3)) {
		printf("Usage: %s device [threads]\n", argv[0]);
		exit(1);
	}

	threads = 1;
	if (argc == 3) {
		threads = atoi(argv[2]);
	}

	//pthread_mutex_init(&muteks, NULL); 

	fd = open(argv[1], O_RDONLY | O_LARGEFILE);
	handle("open", fd < 0);

#ifdef BLKGETSIZE64
	retval = ioctl(fd, BLKGETSIZE64, &ull);
	numbytes = (unsigned long long)ull;
#else
	retval = ioctl(fd, BLKGETSIZE, &ul);
	numbytes = (unsigned long long)ul;
#endif
	handle("ioctl", retval == -1);
	retval = ioctl(fd, BLKBSZGET, &logical_sector_size);
	handle("ioctl", retval == -1 && logical_sector_size > 0);
	retval = ioctl(fd, BLKSSZGET, &physical_sector_size);
	handle("ioctl", retval == -1 && physical_sector_size > 0);
	numblocks = ((unsigned long long)numbytes)/(unsigned long long)BLOCKSIZE;
	printf("Benchmarking %s [%llu blocks, %llu bytes, %llu GB, %llu MB, %llu GiB, %llu MiB]\n",
		argv[1], numblocks, numbytes, numbytes/(1024uLL*1024uLL*1024uLL), numbytes / (1024uLL*1024uLL), numbytes/(1000uLL*1000uLL*1000uLL), numbytes / (1000uLL*1000uLL));
	printf("[%d logical sector size, %d physical sector size]\n", physical_sector_size, physical_sector_size);
	printf("[%d threads]\n", threads);
	printf("Wait %d seconds", TIMEOUT);

	t_id = (pthread_t *)malloc(threads*sizeof(pthread_t));
	handle("malloc", t_id == NULL);
	pthread_attr_init(&pthread_custom_attr);
	p = (parm *)malloc(sizeof(parm)*threads);
	handle("malloc", p == NULL);

	time(&start);

	pthread_mutex_lock(&muteks);


	srand((unsigned int)start*(unsigned int)getpid());

	for (i = 0; i < threads; i++) {
		p[i].id = i;
		p[i].filename = argv[1];
		p[i].seed = rand()+i;
		p[i].fd = dup(fd);
		handle("dup", p[i].fd < 0);
		p[i].buffer = malloc(sizeof(char)*BLOCKSIZE);
		p[i].numbytes = numbytes;
		handle("malloc", p[i].buffer == NULL);
		p[i].run = 1;
		p[i].count = 0;
		p[i].minoffset = minoffset;
		p[i].maxoffset = maxoffset;

		retval = pthread_create(&(t_id[i]), NULL, f, (void*)(p+i));
		handle("pthread_create", retval != 0);
	}

	sleep(1);

	time(&start);
	signal(SIGALRM, &done);
	alarm(1);

	pthread_mutex_unlock(&muteks);

	for (i = 0; i < threads; i++) {
		pthread_join(t_id[i], NULL);
	}

	for (i = 0; i < threads; i++) {
		count += p[i].count;
		if (p[i].maxoffset > maxoffset) {
			maxoffset = p[i].maxoffset;
		}
		if (p[i].minoffset < minoffset) {
			minoffset = p[i].minoffset;
		}
	}

	report();

	/* notreached */
	return 0;
}
