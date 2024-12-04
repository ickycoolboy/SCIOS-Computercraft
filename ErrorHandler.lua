-- ErrorHandler.lua: Centralized error handling for SCIOS
local ErrorHandler = {}

-- Configure logging
local LOG_FILE = "scios/error.log"
local MAX_LOG_SIZE = 10240 -- 10KB

-- Ensure log directory exists
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Trim log file if it gets too large
local function trimLogFile()
    if fs.exists(LOG_FILE) and fs.getSize(LOG_FILE) > MAX_LOG_SIZE then
        local file = fs.open(LOG_FILE, "r")
        local content = file.readAll()
        file.close()
        
        -- Keep only the last 75% of the file
        content = content:sub(-MAX_LOG_SIZE * 0.75)
        
        file = fs.open(LOG_FILE, "w")
        file.write(content)
        file.close()
    end
end

-- Log an error with timestamp and context
function ErrorHandler.logError(context, err)
    trimLogFile()
    local file = fs.open(LOG_FILE, "a")
    local timeString = os.date("*t")
    local logEntry = string.format(
        "[%d:%02d] %s: %s\n",
        timeString.hour,
        timeString.min,
        context,
        tostring(err)
    )
    file.write(logEntry)
    file.close()
end

-- Protected call with error logging
function ErrorHandler.protectedCall(context, func, ...)
    local result = {pcall(func, ...)}
    if not result[1] then
        ErrorHandler.logError(context, result[2])
        return false, result[2]
    end
    -- Return all results after the success boolean
    return table.unpack(result, 2)
end

-- Wrap a function with error handling
function ErrorHandler.wrap(context, func)
    return function(...)
        return ErrorHandler.protectedCall(context, func, ...)
    end
end

-- Create a protected environment for running code
function ErrorHandler.createSafeEnvironment()
    local env = {}
    for k, v in pairs(_G) do
        if type(v) == "function" then
            env[k] = ErrorHandler.wrap(k, v)
        else
            env[k] = v
        end
    end
    return env
end

-- Get the error log contents
function ErrorHandler.getLog()
    if not fs.exists(LOG_FILE) then
        return "No errors logged"
    end
    local file = fs.open(LOG_FILE, "r")
    local content = file.readAll()
    file.close()
    return content
end

-- Clear the error log
function ErrorHandler.clearLog()
    if fs.exists(LOG_FILE) then
        fs.delete(LOG_FILE)
    end
end

-- Protected require function
function ErrorHandler.safeRequire(module)
    return ErrorHandler.protectedCall("require:" .. module, require, module)
end

return ErrorHandler
