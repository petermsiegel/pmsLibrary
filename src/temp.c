  #include <stdio.h> 
  #include <stdlib.h> 
  #include <string.h> 
  #include <iconv.h> 

  int main() { 
  // Sample UCS-32 string (little-endian) 
  unsigned int ucs32_string[] = { 0x00000041, 0x00000042, 0x000020AC, 0x00000000 }; 
  // "AB€" 
  // Determine the size of the UCS-32 string 
  size_t ucs32_size = sizeof(ucs32_string); 
  // Calculate the maximum possible size for the UTF-8 string 
  size_t utf8_size = 4 * ucs32_size; 
  char *utf8_string = (char *)malloc(utf8_size); 
  // Conversion 
  iconv_t cd = iconv_open("UTF-8", "UCS-4LE"); 
  // Assuming little-endian UCS-32 
  if (cd == (iconv_t)-1) { 
      perror("iconv_open"); 
      return 1; 
  } 
  char *inbuf = (char *)ucs32_string; 
  char *outbuf = utf8_string; 
  size_t inbytesleft = ucs32_size; 
  size_t outbytesleft = utf8_size; 
  if (iconv(cd, &inbuf, &inbytesleft, &outbuf, &outbytesleft) == (size_t)-1) { 
    perror("iconv"); 
    return 1; 
  } 
  // Close the conversion descriptor iconv_close(cd); 
  // Print the UTF-8 string printf("UTF-8 string: %s\n", utf8_string); 
  // Free memory 
  free(utf8_string); 
  return 0; 

  }