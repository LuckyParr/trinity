#include <stdio.h>

extern "C"
{
    int dpic_test(int a)
    {
        return a + 2;
    }
}