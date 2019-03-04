local log = require "log.c"

function LOG_DEBUG(something)
    if type(something) ~= "string" then
        log.LOG_ERROR("##lua debug err##")
    end
    log.LOG_DEBUG(something)
end

function LOG_INFO(something)
    if type(something) ~= "string" then
        log.LOG_ERROR("##lua info err##")
    end
    log.LOG_INFO(something)
end

function LOG_ERROR(something)
    if type(something) ~= "string" then
        log.LOG_ERROR("##lua error err##")
    end
    log.LOG_ERROR(something)
end

function LOG_EXT(something)
    if type(something) ~= "string" then
        log.LOG_ERROR("##lua error err##")
    end
    log.LOG_EXT_INFO(something)
end

function LOG_STAT(something)
    if type(something) ~= "string" then
        log.LOG_ERROR("##lua error err##")
    end
    log.LOG_STAT(something)
end