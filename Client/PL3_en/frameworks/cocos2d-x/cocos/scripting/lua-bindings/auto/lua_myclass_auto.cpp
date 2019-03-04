#include "scripting/lua-bindings/auto/lua_myclass_auto.hpp"
#include "CCShake.h"
#include "CCContentSizeTo.h"
#include "EffectSprite.h"
#include "UVSprite.h"
#include "MatrixView.h"
#include "ui/CocosGUI.h"
#include "scripting/lua-bindings/manual/tolua_fix.h"
#include "scripting/lua-bindings/manual/LuaBasicConversions.h"

int lua_myclass_Shake_initWithDuration(lua_State* tolua_S)
{
    int argc = 0;
    Shake* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"Shake",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (Shake*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_Shake_initWithDuration'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 3) 
    {
        double arg0;
        double arg1;
        double arg2;

        ok &= luaval_to_number(tolua_S, 2,&arg0, "Shake:initWithDuration");

        ok &= luaval_to_number(tolua_S, 3,&arg1, "Shake:initWithDuration");

        ok &= luaval_to_number(tolua_S, 4,&arg2, "Shake:initWithDuration");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_Shake_initWithDuration'", nullptr);
            return 0;
        }
        bool ret = cobj->initWithDuration(arg0, arg1, arg2);
        tolua_pushboolean(tolua_S,(bool)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "Shake:initWithDuration",argc, 3);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_Shake_initWithDuration'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_Shake_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"Shake",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 2)
    {
        double arg0;
        double arg1;
        ok &= luaval_to_number(tolua_S, 2,&arg0, "Shake:create");
        ok &= luaval_to_number(tolua_S, 3,&arg1, "Shake:create");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_Shake_create'", nullptr);
            return 0;
        }
        Shake* ret = Shake::create(arg0, arg1);
        object_to_luaval<Shake>(tolua_S, "Shake",(Shake*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "Shake:create",argc, 2);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_Shake_create'.",&tolua_err);
#endif
    return 0;
}
int lua_myclass_Shake_createWithStrength(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"Shake",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 3)
    {
        double arg0;
        double arg1;
        double arg2;
        ok &= luaval_to_number(tolua_S, 2,&arg0, "Shake:createWithStrength");
        ok &= luaval_to_number(tolua_S, 3,&arg1, "Shake:createWithStrength");
        ok &= luaval_to_number(tolua_S, 4,&arg2, "Shake:createWithStrength");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_Shake_createWithStrength'", nullptr);
            return 0;
        }
        Shake* ret = Shake::createWithStrength(arg0, arg1, arg2);
        object_to_luaval<Shake>(tolua_S, "Shake",(Shake*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "Shake:createWithStrength",argc, 3);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_Shake_createWithStrength'.",&tolua_err);
#endif
    return 0;
}
int lua_myclass_Shake_constructor(lua_State* tolua_S)
{
    int argc = 0;
    Shake* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif



    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_Shake_constructor'", nullptr);
            return 0;
        }
        cobj = new Shake();
        cobj->autorelease();
        int ID =  (int)cobj->_ID ;
        int* luaID =  &cobj->_luaID ;
        toluafix_pushusertype_ccobject(tolua_S, ID, luaID, (void*)cobj,"Shake");
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "Shake:Shake",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_Shake_constructor'.",&tolua_err);
#endif

    return 0;
}

static int lua_myclass_Shake_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (Shake)");
    return 0;
}

int lua_register_myclass_Shake(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"Shake");
    tolua_cclass(tolua_S,"Shake","Shake","cc.ActionInterval",nullptr);

    tolua_beginmodule(tolua_S,"Shake");
        tolua_function(tolua_S,"new",lua_myclass_Shake_constructor);
        tolua_function(tolua_S,"initWithDuration",lua_myclass_Shake_initWithDuration);
        tolua_function(tolua_S,"create", lua_myclass_Shake_create);
        tolua_function(tolua_S,"createWithStrength", lua_myclass_Shake_createWithStrength);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(Shake).name();
    g_luaType[typeName] = "Shake";
    g_typeCast["Shake"] = "Shake";
    return 1;
}

int lua_myclass_ContentSizeTo_initWithDuration(lua_State* tolua_S)
{
    int argc = 0;
    ContentSizeTo* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"ContentSizeTo",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (ContentSizeTo*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_ContentSizeTo_initWithDuration'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 2) 
    {
        double arg0;
        cocos2d::Size arg1;

        ok &= luaval_to_number(tolua_S, 2,&arg0, "ContentSizeTo:initWithDuration");

        ok &= luaval_to_size(tolua_S, 3, &arg1, "ContentSizeTo:initWithDuration");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_ContentSizeTo_initWithDuration'", nullptr);
            return 0;
        }
        bool ret = cobj->initWithDuration(arg0, arg1);
        tolua_pushboolean(tolua_S,(bool)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "ContentSizeTo:initWithDuration",argc, 2);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_ContentSizeTo_initWithDuration'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_ContentSizeTo_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"ContentSizeTo",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 3)
    {
        double arg0;
        double arg1;
        double arg2;
        ok &= luaval_to_number(tolua_S, 2,&arg0, "ContentSizeTo:create");
        ok &= luaval_to_number(tolua_S, 3,&arg1, "ContentSizeTo:create");
        ok &= luaval_to_number(tolua_S, 4,&arg2, "ContentSizeTo:create");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_ContentSizeTo_create'", nullptr);
            return 0;
        }
        ContentSizeTo* ret = ContentSizeTo::create(arg0, arg1, arg2);
        object_to_luaval<ContentSizeTo>(tolua_S, "ContentSizeTo",(ContentSizeTo*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "ContentSizeTo:create",argc, 3);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_ContentSizeTo_create'.",&tolua_err);
#endif
    return 0;
}
int lua_myclass_ContentSizeTo_constructor(lua_State* tolua_S)
{
    int argc = 0;
    ContentSizeTo* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif



    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_ContentSizeTo_constructor'", nullptr);
            return 0;
        }
        cobj = new ContentSizeTo();
        cobj->autorelease();
        int ID =  (int)cobj->_ID ;
        int* luaID =  &cobj->_luaID ;
        toluafix_pushusertype_ccobject(tolua_S, ID, luaID, (void*)cobj,"ContentSizeTo");
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "ContentSizeTo:ContentSizeTo",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_ContentSizeTo_constructor'.",&tolua_err);
#endif

    return 0;
}

static int lua_myclass_ContentSizeTo_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (ContentSizeTo)");
    return 0;
}

int lua_register_myclass_ContentSizeTo(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"ContentSizeTo");
    tolua_cclass(tolua_S,"ContentSizeTo","ContentSizeTo","cc.ActionInterval",nullptr);

    tolua_beginmodule(tolua_S,"ContentSizeTo");
        tolua_function(tolua_S,"new",lua_myclass_ContentSizeTo_constructor);
        tolua_function(tolua_S,"initWithDuration",lua_myclass_ContentSizeTo_initWithDuration);
        tolua_function(tolua_S,"create", lua_myclass_ContentSizeTo_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(ContentSizeTo).name();
    g_luaType[typeName] = "ContentSizeTo";
    g_typeCast["ContentSizeTo"] = "ContentSizeTo";
    return 1;
}

int lua_myclass_Effect_setTarget(lua_State* tolua_S)
{
    int argc = 0;
    Effect* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"Effect",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (Effect*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_Effect_setTarget'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        EffectSprite* arg0;

        ok &= luaval_to_object<EffectSprite>(tolua_S, 2, "EffectSprite",&arg0, "Effect:setTarget");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_Effect_setTarget'", nullptr);
            return 0;
        }
        cobj->setTarget(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "Effect:setTarget",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_Effect_setTarget'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_Effect_getGLProgramState(lua_State* tolua_S)
{
    int argc = 0;
    Effect* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"Effect",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (Effect*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_Effect_getGLProgramState'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_Effect_getGLProgramState'", nullptr);
            return 0;
        }
        cocos2d::GLProgramState* ret = cobj->getGLProgramState();
        object_to_luaval<cocos2d::GLProgramState>(tolua_S, "cc.GLProgramState",(cocos2d::GLProgramState*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "Effect:getGLProgramState",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_Effect_getGLProgramState'.",&tolua_err);
#endif

    return 0;
}
static int lua_myclass_Effect_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (Effect)");
    return 0;
}

int lua_register_myclass_Effect(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"Effect");
    tolua_cclass(tolua_S,"Effect","Effect","cc.Ref",nullptr);

    tolua_beginmodule(tolua_S,"Effect");
        tolua_function(tolua_S,"setTarget",lua_myclass_Effect_setTarget);
        tolua_function(tolua_S,"getGLProgramState",lua_myclass_Effect_getGLProgramState);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(Effect).name();
    g_luaType[typeName] = "Effect";
    g_typeCast["Effect"] = "Effect";
    return 1;
}

int lua_myclass_EffectSprite_setEffect(lua_State* tolua_S)
{
    int argc = 0;
    EffectSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectSprite_setEffect'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        Effect* arg0;

        ok &= luaval_to_object<Effect>(tolua_S, 2, "Effect",&arg0, "EffectSprite:setEffect");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectSprite_setEffect'", nullptr);
            return 0;
        }
        cobj->setEffect(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectSprite:setEffect",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectSprite_setEffect'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectSprite_addEffect(lua_State* tolua_S)
{
    int argc = 0;
    EffectSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectSprite_addEffect'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 2) 
    {
        Effect* arg0;
        ssize_t arg1;

        ok &= luaval_to_object<Effect>(tolua_S, 2, "Effect",&arg0, "EffectSprite:addEffect");

        ok &= luaval_to_ssize(tolua_S, 3, &arg1, "EffectSprite:addEffect");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectSprite_addEffect'", nullptr);
            return 0;
        }
        cobj->addEffect(arg0, arg1);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectSprite:addEffect",argc, 2);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectSprite_addEffect'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectSprite_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 1)
    {
        std::string arg0;
        ok &= luaval_to_std_string(tolua_S, 2,&arg0, "EffectSprite:create");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectSprite_create'", nullptr);
            return 0;
        }
        EffectSprite* ret = EffectSprite::create(arg0);
        object_to_luaval<EffectSprite>(tolua_S, "EffectSprite",(EffectSprite*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectSprite:create",argc, 1);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectSprite_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectSprite_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectSprite)");
    return 0;
}

int lua_register_myclass_EffectSprite(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectSprite");
    tolua_cclass(tolua_S,"EffectSprite","EffectSprite","cc.Sprite",nullptr);

    tolua_beginmodule(tolua_S,"EffectSprite");
        tolua_function(tolua_S,"setEffect",lua_myclass_EffectSprite_setEffect);
        tolua_function(tolua_S,"addEffect",lua_myclass_EffectSprite_addEffect);
        tolua_function(tolua_S,"create", lua_myclass_EffectSprite_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectSprite).name();
    g_luaType[typeName] = "EffectSprite";
    g_typeCast["EffectSprite"] = "EffectSprite";
    return 1;
}

int lua_myclass_EffectBlur_setBlurRadius(lua_State* tolua_S)
{
    int argc = 0;
    EffectBlur* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectBlur",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectBlur*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectBlur_setBlurRadius'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        double arg0;

        ok &= luaval_to_number(tolua_S, 2,&arg0, "EffectBlur:setBlurRadius");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectBlur_setBlurRadius'", nullptr);
            return 0;
        }
        cobj->setBlurRadius(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectBlur:setBlurRadius",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectBlur_setBlurRadius'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectBlur_setBlurSampleNum(lua_State* tolua_S)
{
    int argc = 0;
    EffectBlur* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectBlur",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectBlur*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectBlur_setBlurSampleNum'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        double arg0;

        ok &= luaval_to_number(tolua_S, 2,&arg0, "EffectBlur:setBlurSampleNum");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectBlur_setBlurSampleNum'", nullptr);
            return 0;
        }
        cobj->setBlurSampleNum(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectBlur:setBlurSampleNum",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectBlur_setBlurSampleNum'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectBlur_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectBlur",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectBlur_create'", nullptr);
            return 0;
        }
        EffectBlur* ret = EffectBlur::create();
        object_to_luaval<EffectBlur>(tolua_S, "EffectBlur",(EffectBlur*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectBlur:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectBlur_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectBlur_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectBlur)");
    return 0;
}

int lua_register_myclass_EffectBlur(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectBlur");
    tolua_cclass(tolua_S,"EffectBlur","EffectBlur","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectBlur");
        tolua_function(tolua_S,"setBlurRadius",lua_myclass_EffectBlur_setBlurRadius);
        tolua_function(tolua_S,"setBlurSampleNum",lua_myclass_EffectBlur_setBlurSampleNum);
        tolua_function(tolua_S,"create", lua_myclass_EffectBlur_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectBlur).name();
    g_luaType[typeName] = "EffectBlur";
    g_typeCast["EffectBlur"] = "EffectBlur";
    return 1;
}

int lua_myclass_EffectOutline_init(lua_State* tolua_S)
{
    int argc = 0;
    EffectOutline* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectOutline",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectOutline*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectOutline_init'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectOutline_init'", nullptr);
            return 0;
        }
        bool ret = cobj->init();
        tolua_pushboolean(tolua_S,(bool)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectOutline:init",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectOutline_init'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectOutline_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectOutline",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectOutline_create'", nullptr);
            return 0;
        }
        EffectOutline* ret = EffectOutline::create();
        object_to_luaval<EffectOutline>(tolua_S, "EffectOutline",(EffectOutline*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectOutline:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectOutline_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectOutline_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectOutline)");
    return 0;
}

int lua_register_myclass_EffectOutline(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectOutline");
    tolua_cclass(tolua_S,"EffectOutline","EffectOutline","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectOutline");
        tolua_function(tolua_S,"init",lua_myclass_EffectOutline_init);
        tolua_function(tolua_S,"create", lua_myclass_EffectOutline_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectOutline).name();
    g_luaType[typeName] = "EffectOutline";
    g_typeCast["EffectOutline"] = "EffectOutline";
    return 1;
}

int lua_myclass_EffectNoise_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectNoise",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectNoise_create'", nullptr);
            return 0;
        }
        EffectNoise* ret = EffectNoise::create();
        object_to_luaval<EffectNoise>(tolua_S, "EffectNoise",(EffectNoise*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectNoise:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectNoise_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectNoise_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectNoise)");
    return 0;
}

int lua_register_myclass_EffectNoise(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectNoise");
    tolua_cclass(tolua_S,"EffectNoise","EffectNoise","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectNoise");
        tolua_function(tolua_S,"create", lua_myclass_EffectNoise_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectNoise).name();
    g_luaType[typeName] = "EffectNoise";
    g_typeCast["EffectNoise"] = "EffectNoise";
    return 1;
}

int lua_myclass_EffectEdgeDetect_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectEdgeDetect",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectEdgeDetect_create'", nullptr);
            return 0;
        }
        EffectEdgeDetect* ret = EffectEdgeDetect::create();
        object_to_luaval<EffectEdgeDetect>(tolua_S, "EffectEdgeDetect",(EffectEdgeDetect*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectEdgeDetect:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectEdgeDetect_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectEdgeDetect_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectEdgeDetect)");
    return 0;
}

int lua_register_myclass_EffectEdgeDetect(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectEdgeDetect");
    tolua_cclass(tolua_S,"EffectEdgeDetect","EffectEdgeDetect","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectEdgeDetect");
        tolua_function(tolua_S,"create", lua_myclass_EffectEdgeDetect_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectEdgeDetect).name();
    g_luaType[typeName] = "EffectEdgeDetect";
    g_typeCast["EffectEdgeDetect"] = "EffectEdgeDetect";
    return 1;
}

int lua_myclass_EffectGreyScale_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectGreyScale",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectGreyScale_create'", nullptr);
            return 0;
        }
        EffectGreyScale* ret = EffectGreyScale::create();
        object_to_luaval<EffectGreyScale>(tolua_S, "EffectGreyScale",(EffectGreyScale*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectGreyScale:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectGreyScale_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectGreyScale_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectGreyScale)");
    return 0;
}

int lua_register_myclass_EffectGreyScale(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectGreyScale");
    tolua_cclass(tolua_S,"EffectGreyScale","EffectGreyScale","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectGreyScale");
        tolua_function(tolua_S,"create", lua_myclass_EffectGreyScale_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectGreyScale).name();
    g_luaType[typeName] = "EffectGreyScale";
    g_typeCast["EffectGreyScale"] = "EffectGreyScale";
    return 1;
}

int lua_myclass_EffectSepia_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectSepia",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectSepia_create'", nullptr);
            return 0;
        }
        EffectSepia* ret = EffectSepia::create();
        object_to_luaval<EffectSepia>(tolua_S, "EffectSepia",(EffectSepia*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectSepia:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectSepia_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectSepia_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectSepia)");
    return 0;
}

int lua_register_myclass_EffectSepia(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectSepia");
    tolua_cclass(tolua_S,"EffectSepia","EffectSepia","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectSepia");
        tolua_function(tolua_S,"create", lua_myclass_EffectSepia_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectSepia).name();
    g_luaType[typeName] = "EffectSepia";
    g_typeCast["EffectSepia"] = "EffectSepia";
    return 1;
}

int lua_myclass_EffectBloom_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectBloom",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectBloom_create'", nullptr);
            return 0;
        }
        EffectBloom* ret = EffectBloom::create();
        object_to_luaval<EffectBloom>(tolua_S, "EffectBloom",(EffectBloom*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectBloom:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectBloom_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectBloom_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectBloom)");
    return 0;
}

int lua_register_myclass_EffectBloom(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectBloom");
    tolua_cclass(tolua_S,"EffectBloom","EffectBloom","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectBloom");
        tolua_function(tolua_S,"create", lua_myclass_EffectBloom_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectBloom).name();
    g_luaType[typeName] = "EffectBloom";
    g_typeCast["EffectBloom"] = "EffectBloom";
    return 1;
}

int lua_myclass_EffectCelShading_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectCelShading",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectCelShading_create'", nullptr);
            return 0;
        }
        EffectCelShading* ret = EffectCelShading::create();
        object_to_luaval<EffectCelShading>(tolua_S, "EffectCelShading",(EffectCelShading*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectCelShading:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectCelShading_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectCelShading_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectCelShading)");
    return 0;
}

int lua_register_myclass_EffectCelShading(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectCelShading");
    tolua_cclass(tolua_S,"EffectCelShading","EffectCelShading","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectCelShading");
        tolua_function(tolua_S,"create", lua_myclass_EffectCelShading_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectCelShading).name();
    g_luaType[typeName] = "EffectCelShading";
    g_typeCast["EffectCelShading"] = "EffectCelShading";
    return 1;
}

int lua_myclass_EffectLensFlare_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectLensFlare",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 0)
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectLensFlare_create'", nullptr);
            return 0;
        }
        EffectLensFlare* ret = EffectLensFlare::create();
        object_to_luaval<EffectLensFlare>(tolua_S, "EffectLensFlare",(EffectLensFlare*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "EffectLensFlare:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectLensFlare_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectLensFlare_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectLensFlare)");
    return 0;
}

int lua_register_myclass_EffectLensFlare(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectLensFlare");
    tolua_cclass(tolua_S,"EffectLensFlare","EffectLensFlare","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectLensFlare");
        tolua_function(tolua_S,"create", lua_myclass_EffectLensFlare_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectLensFlare).name();
    g_luaType[typeName] = "EffectLensFlare";
    g_typeCast["EffectLensFlare"] = "EffectLensFlare";
    return 1;
}

int lua_myclass_EffectNormalMapped_setLightPos(lua_State* tolua_S)
{
    int argc = 0;
    EffectNormalMapped* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectNormalMapped",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectNormalMapped*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectNormalMapped_setLightPos'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        cocos2d::Vec3 arg0;

        ok &= luaval_to_vec3(tolua_S, 2, &arg0, "EffectNormalMapped:setLightPos");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectNormalMapped_setLightPos'", nullptr);
            return 0;
        }
        cobj->setLightPos(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectNormalMapped:setLightPos",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectNormalMapped_setLightPos'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectNormalMapped_setKBump(lua_State* tolua_S)
{
    int argc = 0;
    EffectNormalMapped* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectNormalMapped",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectNormalMapped*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectNormalMapped_setKBump'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        double arg0;

        ok &= luaval_to_number(tolua_S, 2,&arg0, "EffectNormalMapped:setKBump");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectNormalMapped_setKBump'", nullptr);
            return 0;
        }
        cobj->setKBump(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectNormalMapped:setKBump",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectNormalMapped_setKBump'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectNormalMapped_setLightColor(lua_State* tolua_S)
{
    int argc = 0;
    EffectNormalMapped* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectNormalMapped",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectNormalMapped*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectNormalMapped_setLightColor'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        cocos2d::Color4F arg0;

        ok &=luaval_to_color4f(tolua_S, 2, &arg0, "EffectNormalMapped:setLightColor");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectNormalMapped_setLightColor'", nullptr);
            return 0;
        }
        cobj->setLightColor(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectNormalMapped:setLightColor",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectNormalMapped_setLightColor'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectNormalMapped_getKBump(lua_State* tolua_S)
{
    int argc = 0;
    EffectNormalMapped* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"EffectNormalMapped",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (EffectNormalMapped*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_EffectNormalMapped_getKBump'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_EffectNormalMapped_getKBump'", nullptr);
            return 0;
        }
        double ret = cobj->getKBump();
        tolua_pushnumber(tolua_S,(lua_Number)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "EffectNormalMapped:getKBump",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectNormalMapped_getKBump'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_EffectNormalMapped_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"EffectNormalMapped",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S)-1;

    do 
    {
        if (argc == 1)
        {
            std::string arg0;
            ok &= luaval_to_std_string(tolua_S, 2,&arg0, "EffectNormalMapped:create");
            if (!ok) { break; }
            EffectNormalMapped* ret = EffectNormalMapped::create(arg0);
            object_to_luaval<EffectNormalMapped>(tolua_S, "EffectNormalMapped",(EffectNormalMapped*)ret);
            return 1;
        }
    } while (0);
    ok  = true;
    do 
    {
        if (argc == 0)
        {
            EffectNormalMapped* ret = EffectNormalMapped::create();
            object_to_luaval<EffectNormalMapped>(tolua_S, "EffectNormalMapped",(EffectNormalMapped*)ret);
            return 1;
        }
    } while (0);
    ok  = true;
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d", "EffectNormalMapped:create",argc, 0);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_EffectNormalMapped_create'.",&tolua_err);
#endif
    return 0;
}
static int lua_myclass_EffectNormalMapped_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (EffectNormalMapped)");
    return 0;
}

int lua_register_myclass_EffectNormalMapped(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"EffectNormalMapped");
    tolua_cclass(tolua_S,"EffectNormalMapped","EffectNormalMapped","Effect",nullptr);

    tolua_beginmodule(tolua_S,"EffectNormalMapped");
        tolua_function(tolua_S,"setLightPos",lua_myclass_EffectNormalMapped_setLightPos);
        tolua_function(tolua_S,"setKBump",lua_myclass_EffectNormalMapped_setKBump);
        tolua_function(tolua_S,"setLightColor",lua_myclass_EffectNormalMapped_setLightColor);
        tolua_function(tolua_S,"getKBump",lua_myclass_EffectNormalMapped_getKBump);
        tolua_function(tolua_S,"create", lua_myclass_EffectNormalMapped_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(EffectNormalMapped).name();
    g_luaType[typeName] = "EffectNormalMapped";
    g_typeCast["EffectNormalMapped"] = "EffectNormalMapped";
    return 1;
}

int lua_myclass_UVSprite_setScrollSpeedV(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (UVSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_UVSprite_setScrollSpeedV'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        double arg0;

        ok &= luaval_to_number(tolua_S, 2,&arg0, "UVSprite:setScrollSpeedV");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_setScrollSpeedV'", nullptr);
            return 0;
        }
        cobj->setScrollSpeedV(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:setScrollSpeedV",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_setScrollSpeedV'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_UVSprite_setScrollSpeedU(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (UVSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_UVSprite_setScrollSpeedU'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        double arg0;

        ok &= luaval_to_number(tolua_S, 2,&arg0, "UVSprite:setScrollSpeedU");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_setScrollSpeedU'", nullptr);
            return 0;
        }
        cobj->setScrollSpeedU(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:setScrollSpeedU",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_setScrollSpeedU'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_UVSprite_getScrollSpeedV(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (UVSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_UVSprite_getScrollSpeedV'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_getScrollSpeedV'", nullptr);
            return 0;
        }
        double ret = cobj->getScrollSpeedV();
        tolua_pushnumber(tolua_S,(lua_Number)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:getScrollSpeedV",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_getScrollSpeedV'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_UVSprite_getScrollSpeedU(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (UVSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_UVSprite_getScrollSpeedU'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_getScrollSpeedU'", nullptr);
            return 0;
        }
        double ret = cobj->getScrollSpeedU();
        tolua_pushnumber(tolua_S,(lua_Number)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:getScrollSpeedU",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_getScrollSpeedU'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_UVSprite_setAutoScrollU(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (UVSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_UVSprite_setAutoScrollU'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        bool arg0;

        ok &= luaval_to_boolean(tolua_S, 2,&arg0, "UVSprite:setAutoScrollU");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_setAutoScrollU'", nullptr);
            return 0;
        }
        cobj->setAutoScrollU(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:setAutoScrollU",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_setAutoScrollU'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_UVSprite_setAutoScrollV(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (UVSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_UVSprite_setAutoScrollV'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        bool arg0;

        ok &= luaval_to_boolean(tolua_S, 2,&arg0, "UVSprite:setAutoScrollV");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_setAutoScrollV'", nullptr);
            return 0;
        }
        cobj->setAutoScrollV(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:setAutoScrollV",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_setAutoScrollV'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_UVSprite_isAutoScrollV(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (UVSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_UVSprite_isAutoScrollV'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_isAutoScrollV'", nullptr);
            return 0;
        }
        bool ret = cobj->isAutoScrollV();
        tolua_pushboolean(tolua_S,(bool)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:isAutoScrollV",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_isAutoScrollV'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_UVSprite_isAutoScrollU(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (UVSprite*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_UVSprite_isAutoScrollU'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_isAutoScrollU'", nullptr);
            return 0;
        }
        bool ret = cobj->isAutoScrollU();
        tolua_pushboolean(tolua_S,(bool)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:isAutoScrollU",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_isAutoScrollU'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_UVSprite_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 1)
    {
        const char* arg0;
        std::string arg0_tmp; ok &= luaval_to_std_string(tolua_S, 2, &arg0_tmp, "UVSprite:create"); arg0 = arg0_tmp.c_str();
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_create'", nullptr);
            return 0;
        }
        UVSprite* ret = UVSprite::create(arg0);
        object_to_luaval<UVSprite>(tolua_S, "UVSprite",(UVSprite*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "UVSprite:create",argc, 1);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_create'.",&tolua_err);
#endif
    return 0;
}
int lua_myclass_UVSprite_createWithSpriteFrameName(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"UVSprite",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 1)
    {
        const char* arg0;
        std::string arg0_tmp; ok &= luaval_to_std_string(tolua_S, 2, &arg0_tmp, "UVSprite:createWithSpriteFrameName"); arg0 = arg0_tmp.c_str();
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_createWithSpriteFrameName'", nullptr);
            return 0;
        }
        UVSprite* ret = UVSprite::createWithSpriteFrameName(arg0);
        object_to_luaval<UVSprite>(tolua_S, "UVSprite",(UVSprite*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "UVSprite:createWithSpriteFrameName",argc, 1);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_createWithSpriteFrameName'.",&tolua_err);
#endif
    return 0;
}
int lua_myclass_UVSprite_constructor(lua_State* tolua_S)
{
    int argc = 0;
    UVSprite* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif



    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_UVSprite_constructor'", nullptr);
            return 0;
        }
        cobj = new UVSprite();
        cobj->autorelease();
        int ID =  (int)cobj->_ID ;
        int* luaID =  &cobj->_luaID ;
        toluafix_pushusertype_ccobject(tolua_S, ID, luaID, (void*)cobj,"UVSprite");
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "UVSprite:UVSprite",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_UVSprite_constructor'.",&tolua_err);
#endif

    return 0;
}

static int lua_myclass_UVSprite_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (UVSprite)");
    return 0;
}

int lua_register_myclass_UVSprite(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"UVSprite");
    tolua_cclass(tolua_S,"UVSprite","UVSprite","cc.Sprite",nullptr);

    tolua_beginmodule(tolua_S,"UVSprite");
        tolua_function(tolua_S,"new",lua_myclass_UVSprite_constructor);
        tolua_function(tolua_S,"setScrollSpeedV",lua_myclass_UVSprite_setScrollSpeedV);
        tolua_function(tolua_S,"setScrollSpeedU",lua_myclass_UVSprite_setScrollSpeedU);
        tolua_function(tolua_S,"getScrollSpeedV",lua_myclass_UVSprite_getScrollSpeedV);
        tolua_function(tolua_S,"getScrollSpeedU",lua_myclass_UVSprite_getScrollSpeedU);
        tolua_function(tolua_S,"setAutoScrollU",lua_myclass_UVSprite_setAutoScrollU);
        tolua_function(tolua_S,"setAutoScrollV",lua_myclass_UVSprite_setAutoScrollV);
        tolua_function(tolua_S,"isAutoScrollV",lua_myclass_UVSprite_isAutoScrollV);
        tolua_function(tolua_S,"isAutoScrollU",lua_myclass_UVSprite_isAutoScrollU);
        tolua_function(tolua_S,"create", lua_myclass_UVSprite_create);
        tolua_function(tolua_S,"createWithSpriteFrameName", lua_myclass_UVSprite_createWithSpriteFrameName);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(UVSprite).name();
    g_luaType[typeName] = "UVSprite";
    g_typeCast["UVSprite"] = "UVSprite";
    return 1;
}

int lua_myclass_MatrixView_doLayout(lua_State* tolua_S)
{
    int argc = 0;
    MatrixView* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"MatrixView",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (MatrixView*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_MatrixView_doLayout'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 0) 
    {
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_MatrixView_doLayout'", nullptr);
            return 0;
        }
        cobj->doLayout();
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "MatrixView:doLayout",argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_MatrixView_doLayout'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_MatrixView_setRowCol(lua_State* tolua_S)
{
    int argc = 0;
    MatrixView* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"MatrixView",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (MatrixView*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_MatrixView_setRowCol'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 2) 
    {
        int arg0;
        int arg1;

        ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "MatrixView:setRowCol");

        ok &= luaval_to_int32(tolua_S, 3,(int *)&arg1, "MatrixView:setRowCol");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_MatrixView_setRowCol'", nullptr);
            return 0;
        }
        cobj->setRowCol(arg0, arg1);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "MatrixView:setRowCol",argc, 2);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_MatrixView_setRowCol'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_MatrixView_removeCustomItem(lua_State* tolua_S)
{
    int argc = 0;
    MatrixView* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"MatrixView",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (MatrixView*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_MatrixView_removeCustomItem'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        cocos2d::Node* arg0;

        ok &= luaval_to_object<cocos2d::Node>(tolua_S, 2, "cc.Node",&arg0, "MatrixView:removeCustomItem");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_MatrixView_removeCustomItem'", nullptr);
            return 0;
        }
        cobj->removeCustomItem(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "MatrixView:removeCustomItem",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_MatrixView_removeCustomItem'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_MatrixView_pushBackCustomItem(lua_State* tolua_S)
{
    int argc = 0;
    MatrixView* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S,1,"MatrixView",0,&tolua_err)) goto tolua_lerror;
#endif

    cobj = (MatrixView*)tolua_tousertype(tolua_S,1,0);

#if COCOS2D_DEBUG >= 1
    if (!cobj) 
    {
        tolua_error(tolua_S,"invalid 'cobj' in function 'lua_myclass_MatrixView_pushBackCustomItem'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S)-1;
    if (argc == 1) 
    {
        cocos2d::ui::Widget* arg0;

        ok &= luaval_to_object<cocos2d::ui::Widget>(tolua_S, 2, "ccui.Widget",&arg0, "MatrixView:pushBackCustomItem");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_MatrixView_pushBackCustomItem'", nullptr);
            return 0;
        }
        cobj->pushBackCustomItem(arg0);
        lua_settop(tolua_S, 1);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "MatrixView:pushBackCustomItem",argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_MatrixView_pushBackCustomItem'.",&tolua_err);
#endif

    return 0;
}
int lua_myclass_MatrixView_create(lua_State* tolua_S)
{
    int argc = 0;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertable(tolua_S,1,"MatrixView",0,&tolua_err)) goto tolua_lerror;
#endif

    argc = lua_gettop(tolua_S) - 1;

    if (argc == 2)
    {
        int arg0;
        int arg1;
        ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "MatrixView:create");
        ok &= luaval_to_int32(tolua_S, 3,(int *)&arg1, "MatrixView:create");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_MatrixView_create'", nullptr);
            return 0;
        }
        MatrixView* ret = MatrixView::create(arg0, arg1);
        object_to_luaval<MatrixView>(tolua_S, "MatrixView",(MatrixView*)ret);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "MatrixView:create",argc, 2);
    return 0;
#if COCOS2D_DEBUG >= 1
    tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_MatrixView_create'.",&tolua_err);
#endif
    return 0;
}
int lua_myclass_MatrixView_constructor(lua_State* tolua_S)
{
    int argc = 0;
    MatrixView* cobj = nullptr;
    bool ok  = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif



    argc = lua_gettop(tolua_S)-1;
    if (argc == 2) 
    {
        int arg0;
        int arg1;

        ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "MatrixView:MatrixView");

        ok &= luaval_to_int32(tolua_S, 3,(int *)&arg1, "MatrixView:MatrixView");
        if(!ok)
        {
            tolua_error(tolua_S,"invalid arguments in function 'lua_myclass_MatrixView_constructor'", nullptr);
            return 0;
        }
        cobj = new MatrixView(arg0, arg1);
        cobj->autorelease();
        int ID =  (int)cobj->_ID ;
        int* luaID =  &cobj->_luaID ;
        toluafix_pushusertype_ccobject(tolua_S, ID, luaID, (void*)cobj,"MatrixView");
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "MatrixView:MatrixView",argc, 2);
    return 0;

#if COCOS2D_DEBUG >= 1
    tolua_error(tolua_S,"#ferror in function 'lua_myclass_MatrixView_constructor'.",&tolua_err);
#endif

    return 0;
}

static int lua_myclass_MatrixView_finalize(lua_State* tolua_S)
{
    printf("luabindings: finalizing LUA object (MatrixView)");
    return 0;
}

int lua_register_myclass_MatrixView(lua_State* tolua_S)
{
    tolua_usertype(tolua_S,"MatrixView");
    tolua_cclass(tolua_S,"MatrixView","MatrixView","ccui.ScrollView",nullptr);

    tolua_beginmodule(tolua_S,"MatrixView");
        tolua_function(tolua_S,"new",lua_myclass_MatrixView_constructor);
        tolua_function(tolua_S,"doLayout",lua_myclass_MatrixView_doLayout);
        tolua_function(tolua_S,"setRowCol",lua_myclass_MatrixView_setRowCol);
        tolua_function(tolua_S,"removeCustomItem",lua_myclass_MatrixView_removeCustomItem);
        tolua_function(tolua_S,"pushBackCustomItem",lua_myclass_MatrixView_pushBackCustomItem);
        tolua_function(tolua_S,"create", lua_myclass_MatrixView_create);
    tolua_endmodule(tolua_S);
    std::string typeName = typeid(MatrixView).name();
    g_luaType[typeName] = "MatrixView";
    g_typeCast["MatrixView"] = "MatrixView";
    return 1;
}
TOLUA_API int register_all_myclass(lua_State* tolua_S)
{
	tolua_open(tolua_S);
	
	tolua_module(tolua_S,"mc",0);
	tolua_beginmodule(tolua_S,"mc");

	lua_register_myclass_Effect(tolua_S);
	lua_register_myclass_EffectLensFlare(tolua_S);
	lua_register_myclass_EffectNoise(tolua_S);
	lua_register_myclass_MatrixView(tolua_S);
	lua_register_myclass_ContentSizeTo(tolua_S);
	lua_register_myclass_EffectSprite(tolua_S);
	lua_register_myclass_EffectBloom(tolua_S);
	lua_register_myclass_EffectEdgeDetect(tolua_S);
	lua_register_myclass_EffectSepia(tolua_S);
	lua_register_myclass_UVSprite(tolua_S);
	lua_register_myclass_EffectNormalMapped(tolua_S);
	lua_register_myclass_EffectOutline(tolua_S);
	lua_register_myclass_EffectGreyScale(tolua_S);
	lua_register_myclass_EffectCelShading(tolua_S);
	lua_register_myclass_EffectBlur(tolua_S);
	lua_register_myclass_Shake(tolua_S);

	tolua_endmodule(tolua_S);
	return 1;
}

