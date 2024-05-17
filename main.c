/*
  main.c
 */

#include <config.h>

#ifndef HAVE_STDIO_H
#error "HAVE_STDIO_H not defined - cannot continue"
#endif

#include <stdio.h>

void main()
{
  puts(GREETING_MSG);
}
