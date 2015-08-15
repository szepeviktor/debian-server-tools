/* Damerau-Levenshtein Distance with Limit for MySQL
 * by Sean Collins (sean at lolyco.com) 27Aug2008
 * updated 16Apr2009 to fix:
 *  Tomas' bug (damlevlim("h","hello",2) i get 4)
 * Adapted from Josh Drew's levenshtein code using pseudo
 * code from
 * http://en.wikipedia.org/wiki/Damerau–Levenshtein_distance
 *  - an optimal string alignment algorithm, as opposed to
 *  'edit distance' as per the notes in the wp article
 *
 * Levenshtein Distance Algorithm implementation as MySQL UDF
	by Joshua Drew for SpinWeb Net Designs, Inc. on 2003-12-28.

   Redistribute as you wish, but leave this information intact.
	The levenshtein function is derived from the C implementation
	by Lorenzo Seidenari. More information about the Levenshtein
	Distance Algorithm can be found at http://www.merriampark.com/ld.htm
*/

#ifdef STANDARD
#include <string.h>
#ifdef __WIN__
typedef unsigned __int64 ulonglong;
typedef __int64 longlong;
#else
typedef unsigned long long ulonglong;
typedef long long longlong;
#endif /*__WIN__*/
#else
#include <my_global.h>
#include <my_sys.h>
#endif
#include <mysql.h>
#include <m_ctype.h>
#include <m_string.h>

#ifdef HAVE_DLOPEN

/******************************************************************************
** function declarations
******************************************************************************/

extern "C" {
	my_bool		damlevlim256_init(UDF_INIT *initid, UDF_ARGS *args,
	                             char *message);
	void			damlevlim256_deinit(UDF_INIT *initid);
	longlong		damlevlim256(UDF_INIT *initid, UDF_ARGS *args,
	                        char *is_null, char *error);
}

/******************************************************************************
** function definitions
******************************************************************************/

/******************************************************************************
** purpose:		called once for each SQL statement which invokes DAMLEVLIM();
**					checks arguments, sets restrictions, allocates memory that
**					will be used during the main DAMLEVLIM() function (the same
**					memory will be reused for each row returned by the query)
** receives:	pointer to UDF_INIT struct which is to be shared with all
**					other functions (damlevlim256() and damlevlim256_deinit()) -
**					the components of this struct are described in the MySQL manual;
**					pointer to UDF_ARGS struct which contains information about
**					the number, size, and type of args the query will be providing
**					to each invocation of damlevlim256(); pointer to a char
**					array of size MYSQL_ERRMSG_SIZE in which an error message
**					can be stored if necessary
** returns:		1 => failure; 0 => successful initialization
******************************************************************************/
my_bool damlevlim256_init(UDF_INIT *initid, UDF_ARGS *args, char *message)
{
	int *workspace;

	/* make sure user has provided three arguments */
	if (args->arg_count != 3)
	{
		strcpy(message, "DAMLEVLIM() requires three arguments");
		return 1;
	}
	/* make sure both arguments are strings - they could be cast to strings,
	** but that doesn't seem useful right now */
	else if (args->arg_type[0] != STRING_RESULT || 
	         args->arg_type[1] != STRING_RESULT ||
					 args->arg_type[2] != INT_RESULT)
	{
		strcpy(message, "DAMLEVLIM() requires arguments (string, string, int)");
		return 1;
	}

	/* set the maximum number of digits MySQL should expect as the return
	** value of the DAMLEVLIM() function */
	initid->max_length = 3;

	/* damlevlim256() will not be returning null */
	initid->maybe_null = 0;

	/* attempt to allocate memory in which to calculate distance */
   // workspace = new int[(args->lengths[0] + 1) * (args->lengths[1] + 1)];
	 workspace = new int[256 * 256];
		
	if (workspace == NULL)
	{
		strcpy(message, "Failed to allocate memory for damlevlim256 function");
		return 1;
	}

		/* initialize first row to 0..n */
		int k;
		for (k = 0; k < 256; k++)
			workspace[k] = k;

		/* initialize first column to 0..m */
		k = 256;
		for (int i = 1; i < 256; i++)
		{
      	workspace[k] = i;
				k += 256;
		}
	/* initid->ptr is a char* which MySQL provides to share allocated memory
	** among the xxx_init(), xxx_deinit(), and xxx() functions */
	initid->ptr = (char*) workspace;

	return 0;
}

/******************************************************************************
** purpose:		deallocate memory allocated by damlevlim256_init(); this func
**					is called once for each query which invokes DAMLEVLIM(),
**					it is called after all of the calls to damlevlim256() are done
** receives:	pointer to UDF_INIT struct (the same which was used by
**					damlevlim256_init() and damlevlim256())
** returns:		nothing
******************************************************************************/
void damlevlim256_deinit(UDF_INIT *initid)
{
	if (initid->ptr != NULL)
	{
		delete [] initid->ptr;
	}
}

/******************************************************************************
** purpose:		compute the Levenshtein distance (edit distance) between two
**					strings
** receives:	pointer to UDF_INIT struct which contains pre-allocated memory
**					in which work can be done; pointer to UDF_ARGS struct which 
**					contains the functions arguments and data about them; pointer
**					to mem which can be set to 1 if the result is NULL; pointer
**					to mem which can be set to 1 if the calculation resulted in an
**					error
** returns:		the Levenshtein distance between the two provided strings
******************************************************************************/
longlong damlevlim256(UDF_INIT *initid, UDF_ARGS *args, char *is_null,
                     char *error)
{
	/* s is the first user-supplied argument; t is the second
	** the levenshtein distance between s and t is to be computed */
  	const char *s = args->args[0];
  	const char *t = args->args[1];
		long long limit_arg = *((long long*)args->args[2]);

	/* get a pointer to the memory allocated in damlevlim256_init() */
	int *d = (int*) initid->ptr;

	longlong n, m;
  	int b,c,f,g,h,i,j,k,min, l1, l2, cost, tr, limit = limit_arg, best = 0;

	/***************************************************************************
	** damlevlim256 step one
	***************************************************************************/

	/* if s or t is a NULL pointer, then the argument to which it points
	** is a MySQL NULL value; when testing a statement like:
	** 	SELECT DAMLEVLIM(NULL, 'test');
	** the first argument has length zero, but if some row in a table contains
	** a NULL value which is sent to DAMLEVLIM() (or some other UDF),
	** that NULL argument has the maximum length of the attribute (as defined
	** in the CREATE TABLE statement); therefore, the argument length is not
	** a reliable indicator of the argument's existence... checking for
	** a NULL pointer is the proper course of action
	*/

  	n = (s == NULL) ? 0 : args->lengths[0];
  	m = (t == NULL) ? 0 : args->lengths[1];

  	if(n != 0 && m != 0)
  	{
		/************************************************************************
    	** damlevlim256 step two
		************************************************************************/

		l1 = n;
		l2 = m;
		n++;
		m++;

		/* initialize first row to 0..n */
		/*
		for (k = 0; k < n; k++)
		{
			d[k] = k;
		}
		*/

		/* initialize first column to 0..m */
		/*
		k = n;
		for (i = 1; i < m; i++)
		{
      	d[k] = i;
				k += n;
		}
		*/

		/************************************************************************
    	** damlevlim256 step three
		************************************************************************/

		/* throughout these loops, g will be equal to i minus one */
		g = 0;
		for (i = 1; i < n; i++)
		{
			/*********************************************************************
    		** damlevlim256 step four
			*********************************************************************/

			k = i;

			/* throughout the for j loop, f will equal j minus one */
			f = 0;
			best = limit;
			for (j = 1; j < m; j++)
			{
				/******************************************************************
				** damlevlim256 step five, six, seven
				******************************************************************/

				/* Seidenari's original was more like:
        		** d[j*n+i] = min(d[(j-1)*n+i]+1,
				**                min(d[j*n+i-1]+1,
				**                    d[(j-1)*n+i-1]+((s[i-1]==t[j-1]) ? 0 : 1)));
				**
				** thanks to algebra, (most or) all of the redundant calculations
				** have been removed; hopefully the variables aren't too confusing
				** :)
				**
				** NOTE: after I did this, I realized I could have just had the
				** compiler optimize the calculations for me... dang
				*/

				/* h = (j * n + i - n)  = ((j - 1) * n + i) */
				h = k;
				/* k = (j * n + i) */
				k += 256;

				/* find the minimum among (the cell immediately above plus one),
				** (the cell immediately to the left plus one), and (the cell
				** diagonally above and to the left plus the cost [cost equals
				** zero if argument one's character at index g equals argument
				** two's character at index f; otherwise, cost is one]) 
        		** d[k] = min(d[h] + 1,
				**           min(d[k-1] + 1,
				**               d[h-1] + ((s[g] == t[f]) ? 0 : 1)));
				*/

				/* computing the minimum inline is much quicker than making
				** two function calls (or even one, as Seidenari used)
				**
				** NOTE: after I did this, I realized I could have just had the
				** compiler inline the functions
				*/

				min = d[h] + 1;
				b = d[k-1] + 1;
				if (s[g] == t[f])
					cost = 0;
				else
				{
					cost = 1;
					/* transposition */
					if (i < l1 && j < l2)
						if (s[i] == t[f] && s[g] == t[j])
						{
							tr = d[(h) - 1];
							if (tr < min)
								min = tr;
						}
				}
				c = d[h - 1] + cost;

				if (b < min) { min = b; }
				if (c < min)
				{
					d[k] = c;
					if (c < best)
						best = c;
				}
				else
				{
					d[k] = min;
					if (min < best)
						best = min;
				}
				/* f will be equal to j minus one on the 
				** next iteration of this loop */
				f = j;
      	}

			if (best >= limit)
				return limit_arg;
			/* g will equal i minus one for the next iteration */
			g = i;
		}

		/* Seidenari's original was:
    	** return (longlong) d[n*m-1]; */

			if (d[k] >= limit)
				return limit_arg;
			else
				return (longlong) d[k];
  	}
	else if (n == 0)
	{
		if (m < limit_arg)
			return m;
		else
			return limit_arg;
	}
	else
	{
		if (n < limit_arg)
			return n;
		else
			return limit_arg;
	}
}

#endif /* HAVE_DLOPEN */
