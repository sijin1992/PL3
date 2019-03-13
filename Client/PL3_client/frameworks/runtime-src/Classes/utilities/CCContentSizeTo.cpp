
#include "CCContentSizeTo.h"

ContentSizeTo::ContentSizeTo(){
}

ContentSizeTo* ContentSizeTo::create(float duration, float width, float height)
{
	ContentSizeTo *pRet = new ContentSizeTo();
    
    if (pRet && pRet->initWithDuration(duration, Size(width, height)))
    {
        pRet->autorelease();
    }
    else
    {
        CC_SAFE_DELETE(pRet);
    }
    
    return pRet;
}

bool ContentSizeTo::initWithDuration(float duration, const Size & size)
{
    if (ActionInterval::initWithDuration(duration))
    {
		_endSize = size;
		
        return true;
    }
    
    return false;
}

void ContentSizeTo::update(float time)
{
	if (_target)
	{
		_target->setContentSize(_startSize + Size(_deltaSize.width * time, _deltaSize.height * time));
	}
}

void ContentSizeTo::startWithTarget(Node *pTarget)
{
    ActionInterval::startWithTarget( pTarget );
	_startSize = _target->getContentSize();
	_deltaSize.width = _endSize.width - _startSize.width;
	_deltaSize.height = _endSize.height - _startSize.height;
}

void ContentSizeTo::stop(void)
{
    _target->setContentSize(_endSize);
    ActionInterval::stop();
}
