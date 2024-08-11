 /*  Source Code for _TakeDrop.c => TakeDrop.so'  */
     #include <stdint.h>
     #include <stdio.h>
     /*  MAGIC_OFFSET: Don't use this unless you know what you are doing! */
     #define MAGIC_OFFSET 10            /* I32 (10*4) bytes */

     int32_t TakeDrop(int32_t offset, int32_t *outRaw, int32_t *inRaw,
                      int inRows, int inCols, int tRows, int tCols, int dRows, int dCols){
       int     skip, r, c;
       int32_t *inPtr, *outPtr;


       if (offset == -1)
         offset= MAGIC_OFFSET;

     /* We don't allow negative take and drop offsets. Sorry. */
       if ((tRows<0) || (tCols<0) || (dRows<0) || (dCols<0)) {
         return 911;
       }

       inPtr = inRaw + offset;
       outPtr= outRaw + offset;

       inPtr+= dCols + dRows * inCols;

       if ((tRows>(inRows-dRows) || (tCols>(inCols-dCols)))){
         return 11;
       }

     skip= inCols-tCols;
     for (r=0; r<tRows; ++r, inPtr+= skip ){
         for (c=0; c<tCols; ++c){
           *outPtr++ = *inPtr++ ;
         }
     }

      return 0;


     }
