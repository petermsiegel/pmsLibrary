#include <stdint.h>

// PMS Revised Code: Utf8Buf
//
// Encodes in place <nElem> 4-byte chars at <char4Buf> via UTF-8.
// It's guaranteed that if char4Buf has enough space, then the
// UTF-8 version will be valid.  
// No null byte is appended.
//   Returns the # of total chars (not 4-byte chars) in the output. 
// Based on utf8_encode (Encode a code point using UTF-8)
// by @author Ondřej Hruška <ondra@ondrovo.com>, @license MIT

#define uchar  char 
static inline int Utf8Buf(uint32_t *char4Buf, int nElem){
   uchar *utfView = (uchar *) char4Buf;
   int i= 0;
   int lenOut= 0;
   for (i=0; i< nElem; ++i) {
      uint32_t curCh = char4Buf[i];
      if (curCh <= 0x7F) {
        // Plain ASCII
        utfView[lenOut++] = (uchar) curCh;
        lenOut+= 1;
      }
      else if (curCh <= 0x07FF) {
        // 2-byte unicode
        utfView[lenOut++] = (uchar) ((curCh >> 6)   | 0xC0);
        utfView[lenOut++] = (uchar) ((curCh & 0x3F) | 0x80);
      }
      else if (curCh <= 0xFFFF) {
        // 3-byte unicode
        utfView[lenOut++] = (uchar) (((curCh >> 12)       ) | 0xE0);
        utfView[lenOut++] = (uchar) (((curCh >>  6) & 0x3F) | 0x80);
        utfView[lenOut++] = (uchar) (( curCh        & 0x3F) | 0x80);
      }
      else if (curCh <= 0x10FFFF) {
        // 4-byte unicode
        utfView[lenOut++] = (uchar) (((curCh >> 18) | 0x07)|0xF0);
        utfView[lenOut++] = (uchar) (((curCh >> 12) & 0x3F)|0x80);
        utfView[lenOut++] = (uchar) (((curCh >>  6) & 0x3F)|0x80);
        utfView[lenOut++] = (uchar) (( curCh        & 0x3F)|0x80);
      }
      else { 
        // error - use a replacement character
        utfView[lenOut++] = (uchar) 0xEF;  
        utfView[lenOut++] = (uchar) 0xBF;
        utfView[lenOut++] = (uchar) 0xBD;
      }
   }
   return lenOut;
}

#if 0  /* ignore */
/**
 * Encode a code point using UTF-8
 * 
 * @author Ondřej Hruška <ondra@ondrovo.com>
 * @license MIT
 * 
 * @param out - output buffer (min 5 characters), will be 0-terminated
 * @param utf - code point 0-0x10FFFF
 * @return number of bytes on success, 0 on failure (also produces U+FFFD, which uses 3 bytes)
 */
 
int utf8_encode(char *out, uint32_t utf)
{
  if (utf <= 0x7F) {
    // Plain ASCII
    out[0] = (char) utf;
    out[1] = 0;
    return 1;
  }
  else if (utf <= 0x07FF) {
    // 2-byte unicode
    out[0] = (char) (((utf >> 6) & 0x1F) | 0xC0);
    out[1] = (char) (((utf >> 0) & 0x3F) | 0x80);
    out[2] = 0;
    return 2;
  }
  else if (utf <= 0xFFFF) {
    // 3-byte unicode
    out[0] = (char) (((utf >> 12) & 0x0F) | 0xE0);
    out[1] = (char) (((utf >>  6) & 0x3F) | 0x80);
    out[2] = (char) (((utf >>  0) & 0x3F) | 0x80);
    out[3] = 0;
    return 3;
  }
  else if (utf <= 0x10FFFF) {
    // 4-byte unicode
    out[0] = (char) (((utf >> 18) & 0x07) | 0xF0);
    out[1] = (char) (((utf >> 12) & 0x3F) | 0x80);
    out[2] = (char) (((utf >>  6) & 0x3F) | 0x80);
    out[3] = (char) (((utf >>  0) & 0x3F) | 0x80);
    out[4] = 0;
    return 4;
  }
  else { 
    // error - use replacement character
    out[0] = (char) 0xEF;  
    out[1] = (char) 0xBF;
    out[2] = (char) 0xBD;
    out[3] = 0;
    return 0;
  }
}
#endif 