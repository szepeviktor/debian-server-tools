/* MD5.H - header file for MD5C.C
 */

/* Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
rights reserved.

License to copy and use this software is granted provided that it
is identified as the "RSA Data Security, Inc. MD5 Message-Digest
Algorithm" in all material mentioning or referencing this software
or this function.

License is also granted to make and use derivative works provided
that such works are identified as "derived from the RSA Data
Security, Inc. MD5 Message-Digest Algorithm" in all material
mentioning or referencing the derived work.

RSA Data Security, Inc. makes no representations concerning either
the merchantability of this software or the suitability of this
software for any particular purpose. It is provided "as is"
without express or implied warranty of any kind.
These notices must be retained in any copies of any part of this
documentation and/or software.
 */

#ifndef MD5_H
#define MD5_H 1

/* UINT4 defines a four byte word */
#ifndef UINT4
#ifdef __alpha
#define UINT4 unsigned int
#else
#define UINT4 unsigned long int
#endif
#endif

/* MD5 context. */
typedef struct {
  UINT4 state[4];		/* state (ABCD) */
  UINT4 count[2];		/* number of bits, modulo 2^64 (lsb first) */
  unsigned char in[64];		/* input buffer */
} MD5_CTX;

#if defined(sun) && !defined(IN_MD5C)
#define MD5Init md5init
#define MD5Update md5update
#define MD5Final md5final
#endif

#ifdef _WIN32
#  ifndef STDCALL
#    define STDCALL __stdcall
#  endif
#else
#  ifndef STDCALL
#    define STDCALL
#  endif
#endif
void STDCALL MD5Init(MD5_CTX *);
void STDCALL MD5Update(MD5_CTX *, const unsigned char *, unsigned int);
void STDCALL MD5Final(unsigned char [16], MD5_CTX *);

#endif /* MD5_H */
