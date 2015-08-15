/* Damerau-Levenshtein Distance for MySQL
 * by Sean Collins (sean at lolyco.com) 27Aug2008
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
	my_bool		damlev_init(UDF_INIT *initid, UDF_ARGS *args,
	                             char *message);
	void			damlev_deinit(UDF_INIT *initid);
	longlong		damlev(UDF_INIT *initid, UDF_ARGS *args,
	                        char *is_null, char *error);
}

/******************************************************************************
** function definitions
******************************************************************************/

/******************************************************************************
** purpose:		called once for each SQL statement which invokes DAMLEV();
**					checks arguments, sets restrictions, allocates memory that
**					will be used during the main DAMLEV() function (the same
**					memory will be reused for each row returned by the query)
** receives:	pointer to UDF_INIT struct which is to be shared with all
**					other functions (damlev() and damlev_deinit()) -
**					the components of this struct are described in the MySQL manual;
**					pointer to UDF_ARGS struct which contains information about
**					the number, size, and type of args the query will be providing
**					to each invocation of damlev(); pointer to a char
**					array of size MYSQL_ERRMSG_SIZE in which an error message
**					can be stored if necessary
** returns:		1 => failure; 0 => successful initialization
******************************************************************************/
my_bool damlev_init(UDF_INIT *initid, UDF_ARGS *args, char *message)
{
	int *workspace;

	/* make sure user has provided two arguments */
	if (args->arg_count != 2)
	{
		strcpy(message, "DAMLEV() requires two arguments");
		return 1;
	}
	/* make sure both arguments are strings - they could be cast to strings,
	** but that doesn't seem useful right now */
	else if (args->arg_type[0] != STRING_RESULT || 
	         args->arg_type[1] != STRING_RESULT)
	{
		strcpy(message, "DAMLEV() requires two string arguments");
		return 1;
	}

	/* set the maximum number of digits MySQL should expect as the return
	** value of the DAMLEV() function */
	initid->max_length = 3;

	/* damlev() will not be returning null */
	initid->maybe_null = 0;

	/* attempt to allocate memory in which to calculate distance */
   workspace = new int[(args->lengths[0] + 1) * (args->lengths[1] + 1)];
		
	if (workspace == NULL)
	{
		strcpy(message, "Failed to allocate memory for damlev function");
		return 1;
	}

	/* initid->ptr is a char* which MySQL provides to share allocated memory
	** among the xxx_init(), xxx_deinit(), and xxx() functions */
	initid->ptr = (char*) workspace;

	return 0;
}

/******************************************************************************
** purpose:		deallocate memory allocated by damlev_init(); this func
**					is called once for each query which invokes DAMLEV(),
**					it is called after all of the calls to damlev() are done
** receives:	pointer to UDF_INIT struct (the same which was used by
**					damlev_init() and damlev())
** returns:		nothing
******************************************************************************/
void damlev_deinit(UDF_INIT *initid)
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
longlong damlev(UDF_INIT *initid, UDF_ARGS *args, char *is_null,
                     char *error)
{
	/* s is the first user-supplied argument; t is the second
	** the levenshtein distance between s and t is to be computed */
  	const char *s = args->args[0];
  	const char *t = args->args[1];

	/* get a pointer to the memory allocated in damlev_init() */
	int *d = (int*) initid->ptr;

	longlong n, m;
  	int b,c,f,g,h,i,j,k,min, l1, l2, cost, tr;

	/***************************************************************************
	** damlev step one
	***************************************************************************/

	/* if s or t is a NULL pointer, then the argument to which it points
	** is a MySQL NULL value; when testing a statement like:
	** 	SELECT DAMLEV(NULL, 'test');
	** the first argument has length zero, but if some row in a table contains
	** a NULL value which is sent to DAMLEV() (or some other UDF),
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
    	** damlev step two
		************************************************************************/

		l1 = n;
		l2 = m;
		n++;
		m++;

		/* initialize first row to 0..n */
		for (k = 0; k < n; k++)
		{
			d[k] = k;
		}

		/* initialize first column to 0..m */
		k = n;
		for (i = 1; i < m; i++)
		{
      	d[k] = i;
				k += n;
		}

		/************************************************************************
    	** damlev step three
		************************************************************************/

		/* throughout these loops, g will be equal to i minus one */
		g = 0;
		for (i = 1; i < n; i++)
		{
			/*********************************************************************
    		** damlev step four
			*********************************************************************/

			k = i;

			/* throughout the for j loop, f will equal j minus one */
			f = 0;
			for (j = 1; j < m; j++)
			{
				/******************************************************************
				** damlev step five, six, seven
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
				k += n;

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
					d[k] = c;
				else
					d[k] = min;

				/* f will be equal to j minus one on the 
				** next iteration of this loop */
				f = j;
      	}

			/* g will equal i minus one for the next iteration */
			g = i;
		}

		/* Seidenari's original was:
    	** return (longlong) d[n*m-1]; */

    	return (longlong) d[k];
  	}
	else if (n == 0)
	{
		return m;
	}
	else
	{
		return n;
	}
}

#endif /* HAVE_DLOPEN */
