/*
  main.c
 */

#include <config.h>

#ifndef HAVE_STDIO_H
#error "HAVE_STDIO_H not defined - cannot continue"
#endif

#include <stdio.h>
#ifdef SQLite3_FOUND
#include <sqlite3.h>
#endif

int main()
{
  puts(GREETING_MSG);
  puts("Compiler: " __VERSION__);

#ifdef USE_SHARED_LIBGCC
  puts("libgcc: shared");
#else
  puts("libgcc: static");
#endif

#ifdef SQLite3_FOUND
  printf("SQLite version: %s [" SQLITE_VERSION "]\n", sqlite3_libversion());
#endif

  return 0;
}
