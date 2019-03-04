#include "../hmac_sha1.h"
#include "../../base64/base64.h"
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/mman.h>

#define log_printf(msg...) fprintf(stderr, "hmsh1 : "msg)

int main(int argc, char* argv[])
{
    char *data;
    char *digest;
    int data_len;
    char *key = NULL;
    int lkey_len;
    char arg;

    while ((arg = getopt(argc, argv, "k:d:" )) != EOF) {
        switch (arg) {
            case 'k': {
                // optarg
                key = optarg;
            } break;
            case 'd': {
                data = optarg;
            } break;
            default: break;
        }
    }

    if (key == NULL) {
        log_printf("-k key\n-h (key is hex)\n-f inputfilepath\n");
        char* thebuff = (char*)malloc(SHA_DIGESTSIZE);
        hmac_sha1(NULL, 0,  NULL, 0, thebuff);
        printf("hmac(\"\",\"\")=");
        for(int i=0; i<SHA_DIGESTSIZE; ++i)
        {
        	printf("%02x", (unsigned char)thebuff[i]);
        }
        printf("\n");

        char key[] = {"key"};
        char data[] = {"The quick brown fox jumps over the lazy dog"};
        hmac_sha1(key, strlen(key),  data, strlen(data), thebuff);
        printf("hmac(\"key\",\"The quick brown fox jumps over the lazy dog\")=");
        for(int i=0; i<SHA_DIGESTSIZE; ++i)
        {
        	printf("%02x", (unsigned char)thebuff[i]);
        }
        printf("\n");
        return 1;
    }

    lkey_len = strlen(key);
    data_len = strlen(data);
    
    digest = (char*)malloc(SHA_DIGESTSIZE);
    hmac_sha1(key, lkey_len, data, data_len, digest);
   /* for (i = 0; i < SHA_DIGESTSIZE; i++)
        fprintf(stdout, "%c", digest[i]);*/

	for(int i=0; i<SHA_DIGESTSIZE; ++i)
	{
	   printf("%02x", (unsigned char)digest[i]);
	}
	printf("\n");
	
	char base64buff[32]={0};
	base64_encode((const char *)digest, SHA_DIGESTSIZE, base64buff, sizeof(base64buff));
	printf("%s\n", base64buff);

    return 0;
}
//228bf094169a40a3bd188ba37ebe8723&