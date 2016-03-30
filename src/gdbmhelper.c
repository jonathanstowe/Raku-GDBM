#include <gdbm.h>
#include <stdlib.h>
#include <string.h>


/*
 * Wrapper for libgdbm, largely because NC wants to pass pointers to structs
 * and that's not what gdbm wants.  We'll just use this rather than lgdbm.
 *
*/


GDBM_FILE p_gdbm_open (const char *fname, int bs, int flags, int mode, void (*fatal)(const char *)) {
	return gdbm_open(fname, bs, flags, mode, fatal);
}

void p_gdbm_close (GDBM_FILE file) {
	gdbm_close(file);
}

int p_gdbm_store (GDBM_FILE file, datum *key, datum *value, int flags) {
	return gdbm_store(file,*key, *value, flags);
}

datum *p_gdbm_fetch (GDBM_FILE file, datum *key) {
	datum val;
	datum *ret;
	char *dptr;
   val = gdbm_fetch(file, *key);
	ret = (datum *)malloc(sizeof(datum));
   dptr = malloc(val.dsize);
	ret->dsize = val.dsize;
	ret->dptr = memcpy(dptr, val.dptr, val.dsize);
   return ret;
}

int p_gdbm_delete (GDBM_FILE file, datum *key) {
	return gdbm_delete(file, *key);
}

datum *p_gdbm_firstkey (GDBM_FILE file) {
	static datum key;
	key = gdbm_firstkey(file);
	return &key;
}

datum *p_gdbm_nextkey (GDBM_FILE file, datum *lastkey) {
	static datum key;
	key = gdbm_nextkey(file, *lastkey);
	return &key;
}

int p_gdbm_reorganize (GDBM_FILE file) {
	return gdbm_reorganize(file);
}

void p_gdbm_sync (GDBM_FILE file) {
	gdbm_sync(file);
}

int p_gdbm_exists (GDBM_FILE file, datum *key) {
	return gdbm_exists(file, *key);
}

int p_gdbm_count (GDBM_FILE dbf, gdbm_count_t *pcount) {
	return gdbm_count(dbf, pcount);
}
