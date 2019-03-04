#pragma once

//tmd 绝对不能改值
#define SHA_DIGESTSIZE 20
#define SHA_BLOCKSIZE 64

/*
 * return 0, image is integral, otherwise image is corrupted
 */

//digest length should be SHA_DIGESTSIZE 
void hmac_sha1(void *key, /* secret key */
		int key_len,
              void *data, /* data */
              int  data_len, /* length of data in bytes */
              void *digest); /* the right digest data */

