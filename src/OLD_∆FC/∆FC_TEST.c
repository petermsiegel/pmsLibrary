#include "∆FC.c"

// '∆FC' ⎕NA 'I4 ∆FC.dylib|fc  <I4[3] <C4[]    I4           >C4[] =I4' 
//            rc               opts   fString  fStringLen   outBuf   outPLen
int main( int argc, char **argv) {
  CHAR4 fString[512];
  INT4   fStringLen;
  CHAR4 outBuf[512];
  INT4  outPLen[1] = {512};
  INT4  opts[3]= {0, 0, 96};
  INT4 ok; 
  int i;
  if (argc<1) {
      printf("Whoops\n");
      return 0;
  }
  printf("fString: %s", argv[1]);
  fStringLen = strlen(argv[1]);
  exit(0);
  char *arg = argv[1];
  for (i=0; arg[i]; ++i)
        fString[i]= (CHAR4) arg[i];
  printf("fString: ");
  for (i=0; i< fStringLen;++i) {
       printf("%lc", (INT4) fString[i]);
  }
  printf("\n");
  printf("fStringLen=%d\n", fStringLen);
  ok = fc( opts, fString, fStringLen, outBuf, outPLen);
  printf("*outPLen=%d\n rc=%d\n", *outPLen, ok);
  printf("outBuf=<");
  for (i=0; i< *outPLen;++i) {
       printf("%lc", (int) outBuf[i]);
  }
  printf(">\n");
}