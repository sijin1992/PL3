// Code by Francois Guibert
// Contact: www.frozax.com - http://twitter.com/frozax - www.facebook.com/frozax
#include "CCShake.h"

// not really useful, but I like clean default constructors
Shake::Shake(){
}

Shake* Shake::create( float d, float strength )
{
    // call other construction method with twice the same strength
    return createWithStrength( d, strength, strength );
}

Shake* Shake::createWithStrength(float duration, float strength_x, float strength_y)
{
    Shake *pRet = new Shake();
    
    if (pRet && pRet->initWithDuration(duration, strength_x, strength_y))
    {
        pRet->autorelease();
    }
    else
    {
        CC_SAFE_DELETE(pRet);
    }
    
    
    return pRet;
}

bool Shake::initWithDuration(float duration, float strength_x, float strength_y)
{
    if (ActionInterval::initWithDuration(duration))
    {
        _strength.x = strength_x;
        _strength.y = strength_y;
        return true;
    }
    
    return false;
}

// Helper function. I included it here so that you can compile the whole file
// it returns a random value between min and max included
static float fgRangeRand( float min, float max )
{
    float rnd = ((float)rand()/(float)RAND_MAX);
    return rnd*(max-min)+min;
}

void Shake::update(float dt)
{
    float randx = fgRangeRand( -_strength.x, _strength.x )*dt;
    float randy = fgRangeRand( -_strength.y, _strength.y )*dt;
    
    // move the target to a shaked position
    _target->setPosition( _initial + Vec2(randx, randy));
}

void Shake::startWithTarget(Node *pTarget)
{
    ActionInterval::startWithTarget( pTarget );
    
    // save the initial position
    _initial = _target->getPosition();
}

void Shake::stop(void)
{
    // Action is done, reset clip position
    _target->setPosition( _initial );
    
    ActionInterval::stop();
}