 /* TakeDrop.so library */
 #include <stdint.h>
 #include <stdio.h>

    int TakeDrop32(
            int offset, int32_t *outRaw, int32_t *inRaw,
            int inRows, int inCols, int tRows, int tCols, int dRows, int dCols
    ){
    int     skip, r, c;
    int32_t *inPtr, *outPtr;  /* int32_t, etc. */ 

/*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
    if (offset < 0) {
      if (offset == -1) 
          offset= 10;
      else if (offset == -2)   /* This is for testing w/o doing any copying */
          return 0;   
      else 
          return 999;          /* invalid offset */
    }

  /* We don't allow negative take and drop offsets. Sorry. */
    if (tRows<0 || tCols<0 || dRows<0 || dCols<0)  
      return 911;

    inPtr = inRaw + offset;
    outPtr= outRaw + offset; 

    inPtr+= dCols + dRows * inCols;

  /* Overtaking is NOT allowed here. Sorry. */
    if (tRows>(inRows-dRows) || tCols>(inCols-dCols))
      return 912;

  skip= inCols-tCols;      
/* This is where all the work is done! */ 
  for (r=0; r<tRows; ++r, inPtr+= skip ){
      for (c=0; c<tCols; ++c)
        *outPtr++ = *inPtr++ ;
  }

   return 0;
  }

    int TakeDrop16(
            int offset, int16_t *outRaw, int16_t *inRaw,
            int inRows, int inCols, int tRows, int tCols, int dRows, int dCols
    ){
    int     skip, r, c;
    int16_t *inPtr, *outPtr;  /* int32_t, etc. */ 

/*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
    if (offset < 0) {
      if (offset == -1) 
          offset= 20;
      else if (offset == -2)   /* This is for testing w/o doing any copying */
          return 0;   
      else 
          return 999;          /* invalid offset */
    }

  /* We don't allow negative take and drop offsets. Sorry. */
    if (tRows<0 || tCols<0 || dRows<0 || dCols<0)  
      return 911;

    inPtr = inRaw + offset;
    outPtr= outRaw + offset; 

    inPtr+= dCols + dRows * inCols;

  /* Overtaking is NOT allowed here. Sorry. */
    if (tRows>(inRows-dRows) || tCols>(inCols-dCols))
      return 912;

  skip= inCols-tCols;      
/* This is where all the work is done! */ 
  for (r=0; r<tRows; ++r, inPtr+= skip ){
      for (c=0; c<tCols; ++c)
        *outPtr++ = *inPtr++ ;
  }

   return 0;
  }

    int TakeDrop8(
            int offset, int8_t *outRaw, int8_t *inRaw,
            int inRows, int inCols, int tRows, int tCols, int dRows, int dCols
    ){
    int     skip, r, c;
    int8_t *inPtr, *outPtr;  /* int32_t, etc. */ 

/*  MAGIC OFFSET: Don't use this unless you know what you are doing! */
    if (offset < 0) {
      if (offset == -1) 
          offset= 40;
      else if (offset == -2)   /* This is for testing w/o doing any copying */
          return 0;   
      else 
          return 999;          /* invalid offset */
    }

  /* We don't allow negative take and drop offsets. Sorry. */
    if (tRows<0 || tCols<0 || dRows<0 || dCols<0)  
      return 911;

    inPtr = inRaw + offset;
    outPtr= outRaw + offset; 

    inPtr+= dCols + dRows * inCols;

  /* Overtaking is NOT allowed here. Sorry. */
    if (tRows>(inRows-dRows) || tCols>(inCols-dCols))
      return 912;

  skip= inCols-tCols;      
/* This is where all the work is done! */ 
  for (r=0; r<tRows; ++r, inPtr+= skip ){
      for (c=0; c<tCols; ++c)
        *outPtr++ = *inPtr++ ;
  }

   return 0;
  }
