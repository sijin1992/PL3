#pragma once
//
//  UVSprite.h
//  StarClient
//
//  Created by hankai on 16/4/28.
//
//

#ifndef UVSprite_h
#define UVSprite_h

#include "cocos2d.h"

USING_NS_CC;

class UVSprite : public Sprite
{

protected:
	virtual bool initWithTexture(Texture2D *texture, const Rect& rect, bool rotated);
	void draw(Renderer *renderer, const Mat4 &transform, uint32_t flags) override;
	void onDraw(const Mat4 &transform, uint32_t flags);
	virtual void update(float dt);
	virtual void onEnter();
	virtual void onExit();

	bool _AutoScrollU = true;
	float _AutoScrollSpeedU = 0;
	bool _AutoScrollV = false;
	float _AutoScrollSpeedV = 0;

	Vec3 _verticesTransformed[4];

	float _AutoScrollCountU = 0;
	float _AutoScrollCountV = 0;

	GLuint _uniformOffset;
	cocos2d::GLProgramState* _glprogramstate;
	CustomCommand _customCommand;

	static UVSprite* create();

	~UVSprite();
	void listenBackToForeground(Ref *obj);
	void loadShaderVertex(const char *vert, const char *frag);
	bool initGLProgramState(const std::string &fragmentFilename);
public:

	UVSprite();

	static UVSprite* createWithSpriteFrameName(const char * pszSpriteFrameName);
	static UVSprite* create(const char *pszFileName);

	void setAutoScrollU(bool scroll)
	{
		_AutoScrollU = scroll;
	}

	void setAutoScrollV(bool scroll)
	{
		_AutoScrollV = scroll;
	}
	void setScrollSpeedU(float speed)
	{
		_AutoScrollSpeedU = speed;
	}


	void setScrollSpeedV(float speed)
	{
		_AutoScrollSpeedV = speed;
	}

	bool isAutoScrollU() { return _AutoScrollU; }
	bool isAutoScrollV() { return _AutoScrollV; }
	float getScrollSpeedV()
	{
		return _AutoScrollSpeedV;
	}
	float getScrollSpeedU()
	{
		return _AutoScrollSpeedU;
	}
};



#endif /* UVSprite_h */
