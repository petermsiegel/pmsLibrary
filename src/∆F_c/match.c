#include <stdio.h>
#include <ctype.h>

int Match( WIDE *target, WIDE *key ){
   if (!target || !*target || !key || !*key)
       return 0;
   for (WIDE *t = target; *t; ++t) {
        if (tolower(*t) == *key ) {
            WIDE *t1 = t+1, *k1 = key+1; 
            for ( ; *t1 && *k1; ++t1, ++k1 ){
                if (tolower(*t1) != *k1)
                  break;
            }
            if (!*k1 && ((*t1 == ' ' || !*t1)))
                return (t1-target);  // Offset from start of target 
        }
   }
   return 0;

}