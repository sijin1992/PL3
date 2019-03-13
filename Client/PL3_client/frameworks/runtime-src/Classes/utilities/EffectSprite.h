//
//  EffectSprite.h
//  StarClient
//
//  Created by hankai on 16/4/28.
//
//

#ifndef EffectSprite_h
#define EffectSprite_h

#include "cocos2d.h"

USING_NS_CC;

class EffectSprite;

class Effect : public cocos2d::Ref
{
public:
    cocos2d::GLProgramState* getGLProgramState() const { return _glprogramstate; }
    virtual void setTarget(EffectSprite *sprite){}
    
protected:
    bool initGLProgramState(const std::string &fragmentFilename);
    Effect();
    virtual ~Effect();
    cocos2d::GLProgramState* _glprogramstate;
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_WINRT)
    std::string _fragSource;
    cocos2d::EventListenerCustom* _backgroundListener;
#endif
};

class EffectSprite : public Sprite
{
public:
    static EffectSprite *create(const std::string& filename);
    
    void setEffect(Effect* effect);
    void addEffect(Effect *effect, ssize_t order);
    
    void draw(Renderer *renderer, const Mat4 &transform, uint32_t flags) override;
protected:
    EffectSprite();
    ~EffectSprite();
    
    std::vector<std::tuple<ssize_t,Effect*,QuadCommand>> _effects;
    Effect* _defaultEffect;
};

// Blur
class EffectBlur : public Effect
{
public:
    CREATE_FUNC(EffectBlur);
    virtual void setTarget(EffectSprite *sprite) override;
    void setBlurRadius(float radius);
    void setBlurSampleNum(float num);
    
protected:
    bool init(float blurRadius = 10.0f, float sampleNum = 5.0f);
    
    float _blurRadius;
    float _blurSampleNum;
};

// Outline
class EffectOutline : public Effect
{
public:
    CREATE_FUNC(EffectOutline);
    
    bool init()
    {
        initGLProgramState("Shaders/example_Outline.fsh");
        
        Vec3 color(1.0f, 0.2f, 0.3f);
        GLfloat radius = 0.01f;
        GLfloat threshold = 1.75;
        
        _glprogramstate->setUniformVec3("u_outlineColor", color);
        _glprogramstate->setUniformFloat("u_radius", radius);
        _glprogramstate->setUniformFloat("u_threshold", threshold);
        return true;
    }
};

// Noise
class EffectNoise : public Effect
{
public:
    CREATE_FUNC(EffectNoise);
    
protected:
    bool init() {
        initGLProgramState("Shaders/example_Noisy.fsh");
        return true;
    }
    
    virtual void setTarget(EffectSprite* sprite) override
    {
        auto s = sprite->getTexture()->getContentSizeInPixels();
        getGLProgramState()->setUniformVec2("resolution", Vec2(s.width, s.height));
    }
};

// Edge Detect
class EffectEdgeDetect : public Effect
{
public:
    CREATE_FUNC(EffectEdgeDetect);
    
protected:
    bool init() {
        initGLProgramState("Shaders/example_EdgeDetection.fsh");
        return true;
    }
    
    virtual void setTarget(EffectSprite* sprite) override
    {
        auto s = sprite->getTexture()->getContentSizeInPixels();
        getGLProgramState()->setUniformVec2("resolution", Vec2(s.width, s.height));
    }
};

// Grey
class EffectGreyScale : public Effect
{
public:
    CREATE_FUNC(EffectGreyScale);
    
protected:
    bool init() {
        initGLProgramState("Shaders/example_GreyScale.fsh");
        return true;
    }
};

// Sepia
class EffectSepia : public Effect
{
public:
    CREATE_FUNC(EffectSepia);
    
protected:
    bool init() {
        initGLProgramState("Shaders/example_Sepia.fsh");
        return true;
    }
};

// bloom
class EffectBloom : public Effect
{
public:
    CREATE_FUNC(EffectBloom);
    
protected:
    bool init() {
        initGLProgramState("Shaders/example_Bloom.fsh");
        return true;
    }
    
    virtual void setTarget(EffectSprite* sprite) override
    {
        auto s = sprite->getTexture()->getContentSizeInPixels();
        getGLProgramState()->setUniformVec2("resolution", Vec2(s.width, s.height));
    }
};

// cel shading
class EffectCelShading : public Effect
{
public:
    CREATE_FUNC(EffectCelShading);
    
protected:
    bool init() {
        initGLProgramState("Shaders/example_CelShading.fsh");
        return true;
    }
    
    virtual void setTarget(EffectSprite* sprite) override
    {
        auto s = sprite->getTexture()->getContentSizeInPixels();
        getGLProgramState()->setUniformVec2("resolution", Vec2(s.width, s.height));
    }
};

// Lens Flare
class EffectLensFlare : public Effect
{
public:
    CREATE_FUNC(EffectLensFlare);
    
protected:
    bool init() {
        initGLProgramState("Shaders/example_LensFlare.fsh");
        return true;
    }
    
    virtual void setTarget(EffectSprite* sprite) override
    {
        auto s = sprite->getTexture()->getContentSizeInPixels();
        getGLProgramState()->setUniformVec2("textureResolution", Vec2(s.width, s.height));
        
        s = Director::getInstance()->getWinSize();
        getGLProgramState()->setUniformVec2("resolution", Vec2(s.width, s.height));
        
    }
};


class EffectNormalMapped : public Effect
{
public:
    CREATE_FUNC(EffectNormalMapped);
    static EffectNormalMapped* create(const std::string&normalMapFileName)
    {
        EffectNormalMapped *normalMappedSprite = new (std::nothrow) EffectNormalMapped();
        if (normalMappedSprite && normalMappedSprite->init() && normalMappedSprite->initNormalMap(normalMapFileName))
        {
            
            normalMappedSprite->autorelease();
            return normalMappedSprite;
        }
        CC_SAFE_DELETE(normalMappedSprite);
        return nullptr;
    }
    void setKBump(float value);
    void setLightPos(const Vec3& pos);
    void setLightColor(const Color4F& color);
    float getKBump()const{return _kBump;}
protected:
    bool init();
    bool initNormalMap(const std::string&normalMapFileName);
    virtual void setTarget(EffectSprite* sprite) override;
    EffectSprite* _sprite;
    Vec3 _lightPos;
    Color4F _lightColor;
    float  _kBump;
};

#endif /* EffectSprite_h */
