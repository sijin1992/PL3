//
//  Singleton.h
//  HelloLua
//
//  Created by hankai on 16/3/11.
//
//

#ifndef Singleton_h
#define Singleton_h

#include "cocos2d.h"

template<class T>
class Singleton : public cocos2d::Ref{
public:
    static T & getInstance(){
        static T s_ins;
        return s_ins;
    };
protected:
    Singleton(){}
    Singleton(const Singleton &){}
};


#endif /* Singleton_h */
