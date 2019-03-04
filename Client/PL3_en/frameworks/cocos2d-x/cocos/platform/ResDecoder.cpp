#include "ResDecoder.h"
#include "xxtea/xxtea.h"

ResDecoder* ResDecoder::s_sharedResDecoder = nullptr;

void ResDecoder::destroyInstance()
{
	CC_SAFE_DELETE(s_sharedResDecoder);
}

ResDecoder::ResDecoder():_xxteaEnabled(true)
{
}

ResDecoder::~ResDecoder()
{
}

bool ResDecoder::init()
{
	_xxteaKey = (char *)"utugames";
	_xxteaKeyLen = (int)strlen(_xxteaKey);

	_xxteaSign = (char *)"liuxutao";
	_xxteaSignLen = (int)strlen(_xxteaSign);
	return true;
}

bool ResDecoder::isEncodeData(const std::string & filename, unsigned char * buff) {
	if (!buff) {
		return false;
	}
	size_t filenameLen = filename.length();
	size_t signLen = 5;
	if(filenameLen < signLen){
		return false;
	}
	if (filename.compare(filenameLen - signLen, signLen, ".luac") == 0){
		return false;
	}
	
	if (_xxteaEnabled && strncmp((const char *)buff, _xxteaSign, _xxteaSignLen) == 0) {
		return true;
	}
	return false;
}

unsigned char * ResDecoder::decode(unsigned char * buff, size_t buffSize, size_t * decodeLen) {


	// decrypt XXTEA
	xxtea_long len = 0;
	unsigned char* result = xxtea_decrypt((unsigned char*)buff + _xxteaSignLen,
		(xxtea_long)buffSize - _xxteaSignLen,
		(unsigned char*)_xxteaKey,
		(xxtea_long)_xxteaKeyLen,
		&len);

	(*decodeLen) = len;
	return result;
}

ResDecoder* ResDecoder::getInstance()
{
	if (s_sharedResDecoder == nullptr)
	{
		s_sharedResDecoder = new ResDecoder();
		if (!s_sharedResDecoder->init())
		{
			delete s_sharedResDecoder;
			s_sharedResDecoder = nullptr;
			CCLOG("ERROR: Could not init ResDecoder");
		}
	}
	return s_sharedResDecoder;
}
