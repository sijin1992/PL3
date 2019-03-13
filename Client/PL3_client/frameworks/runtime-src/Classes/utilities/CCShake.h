//
//  CCShake.h
//  StarClient
//
//  Created by hankai on 16/4/5.
//
//

#ifndef CCShake_h
#define CCShake_h

#include "cocos2d.h"
USING_NS_CC;


class Shake : public ActionInterval
{
    // Code by Francois Guibert
    // Contact: www.frozax.com - http://twitter.com/frozax - www.facebook.com/frozax
public:
    Shake();
    
    // Create the action with a time and a strength (same in x and y)
    static Shake* create(float d, float strength );
    // Create the action with a time and strengths (different in x and y)
    static Shake* createWithStrength(float d, float strength_x, float strength_y );
    bool initWithDuration(float d, float strength_x, float strength_y );
    
protected:
    
    void startWithTarget(Node *pTarget);
    void update(float time);
    void stop(void);
    
    // Initial position of the shaked node
    Vec2 _initial;
    // Strength of the action
    Vec2 _strength;
    

};
#endif /* CCShake_h */
