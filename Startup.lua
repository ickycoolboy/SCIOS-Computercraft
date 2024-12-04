-- SCI Sentinel OS Startup
term.setCursorPos(1, 2)  -- Move cursor below title bar
print("Startup.lua script execution started.")
sleep(2)  -- Add delay to ensure message is visible
local version = "1.34"

-- Improve module loading path and diagnostics
local function setupModulePath()
    local currentDir = shell.dir()
    local modulePaths = {
        fs.combine(currentDir, "?.lua"),
        fs.combine(currentDir, "scios/?.lua"),
        fs.combine(currentDir, "/?.lua"),
        fs.combine(currentDir, "/scios/?.lua"),
        "/?",
        "/scios/?"
    }
    
    package.path = table.concat(modulePaths, ";") .. ";" .. package.path
    
    ErrorHandler.logError("Module Path", "Updated package.path: " .. package.path)
end

-- Enhanced safe require with detailed logging and validation
local function safeRequire(module, required)
    ErrorHandler.logError("Require", "Attempting to load module: " .. tostring(module))
    
    -- Validate module name
    if type(module) ~= "string" then
        ErrorHandler.logError("Require", "Invalid module name: " .. tostring(module))
        return false, "Invalid module name"
    end
    
    -- Check if module file exists
    local moduleExists = false
    for path in package.path:gmatch("[^;]+") do
        local fullPath = path:gsub("?", module)
        if fs.exists(fullPath) then
            moduleExists = true
            ErrorHandler.logError("Require", "Module file found: " .. fullPath)
            break
        end
    end
    
    if not moduleExists then
        ErrorHandler.logError("Require", "No module file found for: " .. module)
        return false, "Module file not found"
    end
    
    local status, result = ErrorHandler.protectedCall("require:" .. module, function()
        local loaded = require(module)
        
        -- Additional validation of loaded module
        if loaded == nil then
            error("Module loaded as nil: " .. module)
        end
        
        if type(loaded) ~= "table" then
            error("Module did not return a table: " .. module .. ", type: " .. type(loaded))
        end
        
        ErrorHandler.logError("Require", "Module loaded successfully: " .. tostring(module))
        return loaded
    end)
    
    if not status then
        ErrorHandler.logError("Require", "Failed to load module: " .. tostring(module) .. ", Error: " .. tostring(result))
        return false, result
    end
    
    return true, result
end

-- Modify theme loading to be more explicit
local function loadThemeModule()
    ErrorHandler.logError("Theme", "Explicit theme module loading initiated")
    
    local status, theme = safeRequire("Theme")
    
    if not status then
        ErrorHandler.logError("Theme", "Theme module load failed: " .. tostring(theme))
        
        -- Fallback mechanism
        theme = {
            version = "fallback",
            getColor = function(name) return colors.black end,
            drawTitleBar = function() end
        }
    end
    
    return theme
end

-- Call this before requiring modules
setupModulePath()

-- Set up the module path
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Initialize error handling
local ErrorHandler = safeRequire("ErrorHandler", true)
if not ErrorHandler then
    error("Failed to load ErrorHandler module")
end

-- Initialize theme system
local theme = loadThemeModule()

-- Track key states
local altHeld = false

-- Handle resolution controls
local function handleResolution()
    while true do
        local status, event, key = ErrorHandler.protectedCall("resolution_handler", function()
            return os.pullEvent()
        end)
        
        if not status then
            ErrorHandler.logError("Resolution Handler", event)
            sleep(1)
            return -- Exit the handler on error
        end
        
        if event == "key" then
            if key == 56 then -- left alt key
                altHeld = true
            elseif altHeld then
                if key == keys.EQUALS then -- plus key
                    ErrorHandler.protectedCall("resolution_scale", function()
                        local currentScale = term.current().getTextScale()
                        if currentScale > 0.5 then
                            term.current().setTextScale(currentScale - 0.5)
                        end
                        local initSuccess = theme.init() -- Refresh theme after resize
                        if not initSuccess then
                            ErrorHandler.logError("Resolution Handler", "Failed to reinitialize theme after resize")
                        end
                    end)
                elseif key == keys.MINUS then -- minus key
                    ErrorHandler.protectedCall("resolution_scale", function()
                        local currentScale = term.current().getTextScale()
                        if currentScale < 5 then
                            term.current().setTextScale(currentScale + 0.5)
                        end
                        local initSuccess = theme.init() -- Refresh theme after resize
                        if not initSuccess then
                            ErrorHandler.logError("Resolution Handler", "Failed to reinitialize theme after resize")
                        end
                    end)
                end
            end
        elseif event == "key_up" and key == 56 then
            altHeld = false
        end
    end
end

-- Display startup message with protected calls
ErrorHandler.protectedCall("draw_startup", function()
    sleep(1)  -- Add delay before drawing title bar
    theme.drawTitleBar("SCI Sentinel OS v" .. version)
    
    -- Show resize hint
    local w, h = term.getSize()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1, math.floor(h/2))
    term.write(string.rep(" ", w))
    local msg = "Press Alt + +/- to adjust screen size"
    term.setCursorPos(math.floor((w - #msg) / 2), math.floor(h/2))
    term.write(msg)
end)

-- Show resize hint
os.sleep(3) -- Show the message longer

-- Clear the hint
ErrorHandler.protectedCall("clear_hint", function()
    term.setBackgroundColor(colors.black)
    term.clear()
    theme.drawTitleBar("SCI Sentinel OS v" .. version)
end)

-- System file protection
local protected_files = {
    "scios/Sci_sentinel.lua",
    "scios/Gui.lua",
    "scios/Commands.lua",
    "scios/Updater.lua",
    "scios/Theme.lua",
    "startup.lua",
    "scios/versions.db"
}

-- Override fs.delete for protected files
local original_delete = fs.delete
fs.delete = function(path)
    path = fs.combine("", path) -- Normalize path
    for _, protected in ipairs(protected_files) do
        if path == protected then
            return false -- Prevent deletion of protected files
        end
    end
    return original_delete(path)
end

-- Start SCIOS
ErrorHandler.logError("Startup", "Starting SCIOS")
local sci_sentinel = safeRequire("Sci_sentinel")

if not sci_sentinel then
    ErrorHandler.logError("Startup", "SCIOS failed to start")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.clear()
    term.setCursorPos(1,1)
    print("Failed to start SCIOS. Check error.log for details.")
    return
end

-- Run SCIOS
sci_sentinel.run()
