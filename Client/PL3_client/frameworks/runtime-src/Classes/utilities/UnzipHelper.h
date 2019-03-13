//
//  UnzipHelper.h
//  StarClient
//
//  Created by hankai on 16/4/5.
//
//

#ifndef UnzipHelper_h
#define UnzipHelper_h

#include "cocos2d.h"
USING_NS_CC;
#include "Singleton.h"
class UnzipHelper : public Singleton<UnzipHelper> {
public:
	bool loadZIP(const std::string &zipFilename, const std::string & outFilePath, const std::string &password/*""*/);
	bool unCompress(const char * pZipFileName, const char * pOutFileName, const std::string &password);
};
#endif /* UnzipHelper_h */
