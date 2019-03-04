//
//  ResDecoder.h
//  StarClient
//
//  Created by hankai on 16/4/28.
//
//

#ifndef ResDecoder_h
#define ResDecoder_h

#include "cocos2d.h"


class ResDecoder{
	ResDecoder();
public:
	static ResDecoder* getInstance();
	static void destroyInstance();

	virtual ~ResDecoder();

	bool isEncodeData(const std::string & filename,unsigned char * buff);

	unsigned char * decode(unsigned char * buff, size_t buffSize, size_t * decodeLen);
protected:
	virtual bool init();
	
	static ResDecoder* s_sharedResDecoder;

	bool  _xxteaEnabled;
	char* _xxteaKey;
	int   _xxteaKeyLen;
	char* _xxteaSign;
	int   _xxteaSignLen;
};


#endif /* ResDecoder_h */
