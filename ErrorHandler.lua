-- ErrorHandler.lua: Centralized error handling for SCIOS
local ErrorHandler = {}

-- Configure logging
local LOG_FILE = "error.log"
local MAX_LOG_SIZE = 10240 -- 10KB

-- Initialize or clear log file on startup
local function initLogFile()
    -- Create or clear the log file
    local file = fs.open(LOG_FILE, "w")
    if file then
        file.write("=== SCIOS Log Started ===\n")
        file.close()
    end
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

-- Format timestamp consistently
local function getTimestamp()
    local time = os.date("*t")
    return string.format(
        "%02d:%02d:%02d",
        time.hour,
        time.min,
        time.sec
    )
end

-- Log an error with timestamp and context
function ErrorHandler.logError(context, err)
    trimLogFile()
    local file = fs.open(LOG_FILE, "a")
    if file then
        local timestamp = getTimestamp()
        local logEntry = string.format(
            "[%s] %s: %s\n",
            timestamp,
            context,
            tostring(err)
        )
        file.write(logEntry)
        file.close()
        
        -- Also print to terminal for immediate visibility
        if term and term.isColor and term.isColor() then
            local oldColor = term.getTextColor()
            term.setTextColor(colors.yellow)
            print(logEntry)
            term.setTextColor(oldColor)
        end
    end
end

-- Protected call with error logging
function ErrorHandler.protectedCall(context, func, ...)
    local results = {pcall(func, ...)}
    if not results[1] then
        ErrorHandler.logError(context, results[2])
        return false, results[2]
    end
    -- Return success flag and all actual results
    return true, table.unpack(results, 2)
end

-- Initialize log file when module is loaded
initLogFile()

return ErrorHandler
