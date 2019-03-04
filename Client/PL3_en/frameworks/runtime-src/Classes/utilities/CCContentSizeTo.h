//
//  ContentSizeTo.h
//  StarClient
//
//  Created by hankai on 16/4/5.
//
//

#ifndef ContentSizeTo_h
#define ContentSizeTo_h

#include "cocos2d.h"
USING_NS_CC;


class ContentSizeTo : public ActionInterval
{
public:
	ContentSizeTo();
    
    static ContentSizeTo* create(float d, float width, float height);

    bool initWithDuration(float d, const Size & size);
 
protected:
    
    void startWithTarget(Node *pTarget);
    void update(float time);
    void stop(void);
    
	Size _deltaSize;
	Size _startSize;
	Size _endSize;
};
#endif /* ContentSizeTo_h */
