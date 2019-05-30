
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")
cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "update_file/".."src/", true)

require "config"
require "cocos.init"
require "VisibleRect"

local function main()

    require("app.MyApp"):getInstance():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
