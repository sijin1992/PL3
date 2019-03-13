//
//  UVSprite.cpp
//  HelloCpp
//
//  Created by neo on 15-1-10.
//
//

#include "UVSprite.h"

const char* frag_shader = "											\n\
#ifdef GL_ES								\n\
precision mediump float;						\n\
#endif										\n\
\n\
varying vec4 v_fragmentColor;				\n\
varying vec2 v_texCoord;					\n\
uniform vec2 texOffset;                 \n\
//uniform sampler2D CC_Texture0;				\n\
\n\
void main()									\n\
{											\n\
//vec2 texcoord = vec2(v_texCoord.x + texOffsetX,v_texCoord.y + texOffsetY); \n\
vec2 texcoord = mod(texOffset+v_texCoord,1.0);   \n\
gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, texcoord);			\n\
}											\n\
";

using namespace cocos2d;

UVSprite::~UVSprite()
{
	NotificationCenter::getInstance()->removeObserver(this, EVENT_COME_TO_FOREGROUND);
}
void UVSprite::draw(Renderer *renderer, const Mat4 &transform, uint32_t flags)
{

	//重写draw函数 使用customCommand渲染命令
	_customCommand.init(_globalZOrder);
	_customCommand.func = CC_CALLBACK_0(UVSprite::onDraw, this, transform, flags);
	renderer->addCommand(&_customCommand);

}

void UVSprite::onDraw(const Mat4 &transform, uint32_t flags) {

	auto glProgramState = getGLProgramState();

	//转换图片的4个顶点
	//对应quadCommand中的Renderer::fillQuads操作
	//若不进行如下变换,Node使用的pos,scale都表现不出来
	transform.transformPoint(_quad.tl.vertices, &_verticesTransformed[0]);
	transform.transformPoint(_quad.bl.vertices, &_verticesTransformed[1]);
	transform.transformPoint(_quad.tr.vertices, &_verticesTransformed[2]);
	transform.transformPoint(_quad.br.vertices, &_verticesTransformed[3]);

	glProgramState->apply(transform);
	GL::blendFunc(_blendFunc.src, _blendFunc.dst);


	getShaderProgram()->setUniformLocationWith2f(_uniformOffset, _AutoScrollCountU, _AutoScrollCountV);

	//绑定纹理贴图
	GL::bindTexture2D(_texture->getName());
	GL::enableVertexAttribs(GL::VERTEX_ATTRIB_FLAG_POS_COLOR_TEX);

#define kQuadSize sizeof(_quad.bl)
	#ifdef EMSCRIPTEN
	long offset = 0;
	setGLBufferData(&_quad, 4 * kQuadSize, 0);
	#else
	long offset = (long)&_quad;
	#endif // EMSCRIPTEN


	// 设置渲染坐标(x,y)
	int diff = offsetof(V3F_C4B_T2F, vertices);
	glVertexAttribPointer(GLProgram::VERTEX_ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, 0, _verticesTransformed);

	// 设置纹理坐标(u,v)
	diff = offsetof(V3F_C4B_T2F, texCoords);
	glVertexAttribPointer(GLProgram::VERTEX_ATTRIB_TEX_COORD, 2, GL_FLOAT, GL_FALSE, kQuadSize, (void*)(offset + diff));

	// 设置顶点颜色
	diff = offsetof(V3F_C4B_T2F, colors);
	glVertexAttribPointer(GLProgram::VERTEX_ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, kQuadSize, (void*)(offset + diff));

	
	//渲染矩形
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	CHECK_GL_ERROR_DEBUG();

	CC_INCREMENT_GL_DRAWN_BATCHES_AND_VERTICES(1, 4);
}

bool UVSprite::initGLProgramState(const std::string &fragmentFilename)
{
	//auto fileUtiles = FileUtils::getInstance();
	//auto fragmentFullPath = fileUtiles->fullPathForFilename(fragmentFilename);
	//auto fragSource = fileUtiles->getStringFromFile(fragmentFullPath);
	auto glprogram = GLProgram::createWithByteArrays(ccPositionTextureColor_noMVP_vert, fragmentFilename.c_str());

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_WINRT)
	//_fragSource = fragSource;
#endif

	_glprogramstate = (glprogram == nullptr ? nullptr : GLProgramState::getOrCreateWithGLProgram(glprogram));
	//CC_SAFE_RETAIN(_glprogramstate);

	setGLProgramState(_glprogramstate);

	return _glprogramstate != nullptr;
}

void UVSprite::update(float dt)
{
	Sprite::update(dt);

	//更新u
	if (_AutoScrollU)
	{
		_AutoScrollCountU += dt * _AutoScrollSpeedU;
	}

	//更新v
	if (_AutoScrollV) {
		_AutoScrollCountV += dt * _AutoScrollSpeedV;
	}

	//如果超出范围从0开始
	if (_AutoScrollCountU > 1 || _AutoScrollCountU < -1) {
		_AutoScrollCountU = 0;
	}

	if (_AutoScrollCountV > 1 || _AutoScrollCountV < -1) {
		_AutoScrollCountV = 0;
	}
}

void UVSprite::onEnter()
{
	Sprite::onEnter();
	scheduleUpdate();
}

void UVSprite::onExit()
{
	unscheduleUpdate();
	Sprite::onExit();
}

UVSprite::UVSprite() :_uniformOffset(0) {}

UVSprite* UVSprite::create()
{
	UVSprite *pSprite = new UVSprite();
	if (pSprite && pSprite->init())
	{
		pSprite->autorelease();
		return pSprite;
	}
	CC_SAFE_DELETE(pSprite);
	return NULL;
}
UVSprite* UVSprite::create(const char *pszFileName)
{
	UVSprite *pobSprite = new UVSprite();
	if (pobSprite && pobSprite->initWithFile(pszFileName))
	{
		pobSprite->autorelease();
		return pobSprite;
	}
	CC_SAFE_DELETE(pobSprite);
	return NULL;
}
bool UVSprite::initWithTexture(Texture2D *texture, const Rect& rect, bool rotated)
{
	if (Node::init())
	{

		_batchNode = NULL;

		_recursiveDirty = false;
		setDirty(false);

		_opacityModifyRGB = true;

		_blendFunc.src = CC_BLEND_SRC;
		_blendFunc.dst = CC_BLEND_DST;

		_flippedX = _flippedY = false;

		// default transform anchor: center
		setAnchorPoint(Vec2(0.5f, 0.5f));

		// zwoptex default values
		_offsetPosition = Vec2::ZERO;

		_insideBounds = false;

		// clean the Quad
		memset(&_quad, 0, sizeof(_quad));

		// Atlas: Color
		Color4B tmpColor = { 255, 255, 255, 255 };
		_quad.bl.colors = tmpColor;
		_quad.br.colors = tmpColor;
		_quad.tl.colors = tmpColor;
		_quad.tr.colors = tmpColor;

		// shader program
		// shader program
		NotificationCenter::getInstance()->addObserver(this,
			callfuncO_selector(UVSprite::listenBackToForeground),
			EVENT_COME_TO_FOREGROUND,
			NULL);
		loadShaderVertex(ccPositionTextureColor_vert, frag_shader);

		// update texture (calls updateBlendFunc)
		setTexture(texture);
		setTextureRect(rect, rotated, rect.size);

		Texture2D::TexParams texParams = { GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT };
		getTexture()->setTexParameters(texParams);

	 	 initGLProgramState(frag_shader);
		

		// by default use "Self Render".
		// if the sprite is added to a batchnode, then it will automatically switch to "batchnode Render"
		setBatchNode(NULL);

		return true;
	}
	else
	{
		return false;
	}

}

void UVSprite::loadShaderVertex(const char *vert, const char *frag)
{
	GLProgram *shader = new GLProgram();
	shader->initWithVertexShaderByteArray(vert, frag);

	shader->addAttribute(GLProgram::ATTRIBUTE_NAME_POSITION, kCCVertexAttrib_Position);
	shader->addAttribute(GLProgram::ATTRIBUTE_NAME_COLOR, kCCVertexAttrib_Color);
	shader->addAttribute(GLProgram::ATTRIBUTE_NAME_TEX_COORD, kCCVertexAttrib_TexCoords);

	shader->link();

	shader->updateUniforms();

	_uniformOffset = glGetUniformLocation(shader->getProgram(), "texOffset");

	this->setShaderProgram(shader);

	shader->release();
}

void UVSprite::listenBackToForeground(Ref *obj)
{
	this->setShaderProgram(NULL);
	loadShaderVertex(ccPositionTextureColor_vert, frag_shader);
}


UVSprite* UVSprite::createWithSpriteFrameName(const char *pszSpriteFrameName)
{
	SpriteFrame *pSpriteFrame = SpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(pszSpriteFrameName);

#if COCOS2D_DEBUG > 0
	char msg[256] = { 0 };
	sprintf(msg, "Invalid spriteFrameName: %s", pszSpriteFrameName);
	CCAssert(pSpriteFrame != NULL, msg);
#endif

	UVSprite *pobSprite = new UVSprite();
	if (pSpriteFrame && pobSprite && pobSprite->initWithSpriteFrame(pSpriteFrame))
	{
		pobSprite->autorelease();
		return pobSprite;
	}
	CC_SAFE_DELETE(pobSprite);
	return NULL;
}

