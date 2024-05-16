/*
  main.c
 */

#include <config.h>
#ifdef HAVE_STDIO_H
#include <stdio.h>

void main()
{
    puts(GREETING_MSG);
}

#else
void main() {}
#endif
