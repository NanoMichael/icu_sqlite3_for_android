#include <stdlib.h>
#include "sqlite3ext.h"
SQLITE_EXTENSION_INIT1

/**
 * Take match size from value returned by function offsets()
 */
static char *next_match_size(char *value, int *size) {
    int i = 0;
    int token_count = 0;
    char x[32];
    while (*value != '\0') {
        if (*value == ' ') {
            x[i] = '\0';
            i = 0;
            token_count++;
            if (token_count == 4) {
                *size = atoi(x);
                return value + 1;
            }
        } else {
            x[i++] = *value;
        }
        value++;
    }
    x[i] = '\0';
    token_count++;
    if (token_count == 4) {
        *size = atoi(x);
    } else {
        *size = -1;
    }
    return NULL;
}

/**
 * SQLite user defined function to use with offsets() to calculate the simple relevancy of
 * an FTS match. The value returned is the relevancy score (a real value greater than or
 * equal to zero). A larger value indicates a more relevant document.
 *
 * According to the value returned by the function offsets(), it contains 4 integer values on each
 * term, the last value is the size of the matching term in bytes, typically the size will
 * keep the same with the given term, but in some cases, for example, when create an fts table with
 * option tokenize=porter, and contains the following records:
 *
 * docid   content
 * ------  -------
 * 1       sleep
 * 2       sleeping
 *
 * when we execute query:
 * 
 * 		select docid, content, offsets(fts) from fts where fts match 'sleeping'
 * 
 * we will get 2 records like:
 * 
 * docid   content   offsets
 * ------  -------   -------
 * 1       sleep     0 0 0 5
 * 2       sleeping  0 0 0 8
 * 
 * It is not that resonable, we want 'sleeping' ahead of 'sleep', in another word, we want a
 * larger matching size represents a more relevant document.
 *
 * The following query returns the docids of documents that match the full-text query <query>
 * sorted from most to least relevant.
 *
 * 		select docid from fts where fts match <query>
 * 		order by offsets_rank(offsets(fts)) desc
 * 
 */
static void offsets_rank(sqlite3_context *pCtx, int nVal, sqlite3_value **apVal) {
    // Obtain the offsets value
    char *offsets_value = (char *)sqlite3_value_text(apVal[0]);
    if (offsets_value == NULL) {
        sqlite3_result_int(pCtx, 1);
        return;
    }

    // Obtain the term length
    int termLen = 0;
    if (nVal > 1) {
        termLen = sqlite3_value_int(apVal[1]);
    }

    // Calculate rank
    int rank = 0;
    int len = 0;
    char *next_start = offsets_value;
    while (next_start != NULL) {
        next_start = next_match_size(next_start, &len);
        if (len > 0) {
            rank += len;
        }
    }

    // Adjust rank
    if (termLen > 0 && rank > termLen) {
        rank = termLen - 1;
    }

    sqlite3_result_int(pCtx, rank);
}

int sqlite3_extension_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi) {
    SQLITE_EXTENSION_INIT2(pApi)

    sqlite3_create_function(db, "offsets_rank", -1, SQLITE_ANY, 0, offsets_rank, 0, 0);
    return 0;
}