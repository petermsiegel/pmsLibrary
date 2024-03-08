#include <stdio.h>
void Fmt; 
int main(int argc, char *argv[]) {
    wchar_t *fred;
    int      len;
    Fmt(L"abc {iota \"fred\"}", &fred, &len);
} 
wchar_t *Fmt( wchar_t *test, int len){
     wchar_t tp = test;
     for (; len; --len)
        switch(tp){
           case L'{':
              break;
        }
     }
}