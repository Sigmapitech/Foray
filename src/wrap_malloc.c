#include <stdio.h>
#include <stdlib.h>

#include "wrappers.h"

void *malloc(size_t size)
{
    printf("malloc: %zu\n", size);
    return NULL;
}
