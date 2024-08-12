  /* TakeDrop.so library */
  #include <stdint.h>
  #include <stdio.h>
  #define I4 int32_t 
 
     I4 TakeDrop32(
             I4 offset, int32_t *outRaw, int32_t *inRaw,
             I4 inRows, I4 inCols, I4 tRows, I4 tCols, I4 dRows, I4 dCols
     ){
     int     skip, r, c;
     int32_t *inPtr, *outPtr;  /* int32_t, etc. */ 

 /*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
     if (offset == -1) 
        offset= 10;

   /* We don't allow negative take and drop offsets. Sorry. */
     if (tRows<0 || tCols<0 || dRows<0 || dCols<0)  
       return 911;

     inPtr = inRaw + offset;
     outPtr= outRaw + offset; 

     inPtr+= dCols + dRows * inCols;

     if (tRows>(inRows-dRows) || tCols>(inCols-dCols))
       return 912;

   skip= inCols-tCols;       
   for (r=0; r<tRows; ++r, inPtr+= skip ){
       for (c=0; c<tCols; ++c){
         *outPtr++ = *inPtr++ ;
       }
   }

    return 0;
   }
 
     I4 TakeDrop16(
             I4 offset, int16_t *outRaw, int16_t *inRaw,
             I4 inRows, I4 inCols, I4 tRows, I4 tCols, I4 dRows, I4 dCols
     ){
     int     skip, r, c;
     int16_t *inPtr, *outPtr;  /* int32_t, etc. */ 

 /*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
     if (offset == -1) 
        offset= 20;

   /* We don't allow negative take and drop offsets. Sorry. */
     if (tRows<0 || tCols<0 || dRows<0 || dCols<0)  
       return 911;

     inPtr = inRaw + offset;
     outPtr= outRaw + offset; 

     inPtr+= dCols + dRows * inCols;

     if (tRows>(inRows-dRows) || tCols>(inCols-dCols))
       return 912;

   skip= inCols-tCols;       
   for (r=0; r<tRows; ++r, inPtr+= skip ){
       for (c=0; c<tCols; ++c){
         *outPtr++ = *inPtr++ ;
       }
   }

    return 0;
   }
 
     I4 TakeDrop8(
             I4 offset, int8_t *outRaw, int8_t *inRaw,
             I4 inRows, I4 inCols, I4 tRows, I4 tCols, I4 dRows, I4 dCols
     ){
     int     skip, r, c;
     int8_t *inPtr, *outPtr;  /* int32_t, etc. */ 

 /*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
     if (offset == -1) 
        offset= 40;

   /* We don't allow negative take and drop offsets. Sorry. */
     if (tRows<0 || tCols<0 || dRows<0 || dCols<0)  
       return 911;

     inPtr = inRaw + offset;
     outPtr= outRaw + offset; 

     inPtr+= dCols + dRows * inCols;

     if (tRows>(inRows-dRows) || tCols>(inCols-dCols))
       return 912;

   skip= inCols-tCols;       
   for (r=0; r<tRows; ++r, inPtr+= skip ){
       for (c=0; c<tCols; ++c){
         *outPtr++ = *inPtr++ ;
       }
   }

    return 0;
   }
