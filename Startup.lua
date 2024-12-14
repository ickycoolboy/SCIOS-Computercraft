-- SCI Sentinel OS Startup
term.setCursorPos(1, 2)  -- Move cursor below title bar
print("Startup.lua script execution started.")
sleep(2)  -- Add delay to ensure message is visible
local version = "1.34"

-- Basic logging function before ErrorHandler is available
local function earlyLog(context, message)
    print("[" .. context .. "] " .. message)
end

-- Set up basic paths first
if not fs.exists("scios") then
    fs.makeDir("scios")
    earlyLog("Startup", "Created scios directory")
end

-- Improve module loading path
local function setupModulePath()
    -- Use absolute paths with shell.dir()
    local basePath = shell.dir()
    package.path = fs.combine(basePath, "scios/?") .. ";" ..
                  fs.combine(basePath, "scios/?.lua") .. ";" ..
                  fs.combine(basePath, "?") .. ";" ..
                  fs.combine(basePath, "?.lua")
    
    earlyLog("Module Path", "Updated package.path: " .. package.path)
end

-- Initialize paths before loading any modules
setupModulePath()

-- Load ErrorHandler first with detailed error checking
earlyLog("Startup", "Loading ErrorHandler module...")
local ErrorHandler
local success, result = pcall(function()
    local module = require("ErrorHandler")
    if type(module) ~= "table" then
        error("ErrorHandler module did not return a table, got: " .. type(module))
    end
    return module
end)

if not success then
    error("Failed to load ErrorHandler: " .. tostring(result))
end

ErrorHandler = result
if not ErrorHandler then
    error("ErrorHandler loaded as nil")
end

if type(ErrorHandler.logError) ~= "function" then
    error("ErrorHandler.logError is not a function")
end

earlyLog("Startup", "ErrorHandler module loaded successfully")
ErrorHandler.logError("Startup", "ErrorHandler module loaded successfully")

-- Enhanced safe require with error handling
local function safeRequire(module)
    local success, loaded = ErrorHandler.protectedCall("require:" .. module, function()
        local mod = require(module)
        if not mod then
            error("Module loaded as nil: " .. module)
        end
        return mod
    end)
    return success, loaded
end

-- Ensure theme is loaded and accessible
local function initializeTheme()
    ErrorHandler.logError("Theme", "Initializing theme module")
    
    local success, themeModule = safeRequire("Theme")
    
    if not success or type(themeModule) ~= "table" then
        ErrorHandler.logError("Theme", "Failed to load theme module: " .. tostring(themeModule))
        -- Fallback mechanism
        themeModule = {
            version = "fallback",
            getColor = function(name) return colors.black end,
            drawTitleBar = function() end,
            init = function() return true end,
            isInitialized = function() return true end
        }
    else
        ErrorHandler.logError("Theme", "Theme module loaded successfully")
        -- Initialize the theme immediately after loading
        if type(themeModule.init) ~= "function" then
            ErrorHandler.logError("Theme", "Theme module missing init function")
            return false
        end
        
        local initSuccess, initResult = ErrorHandler.protectedCall("Theme:init", function()
            return themeModule.init()
        end)
        
        if not initSuccess then
            ErrorHandler.logError("Theme", "Theme initialization failed: " .. tostring(initResult))
            return false
        end
        
        if not initResult then
            ErrorHandler.logError("Theme", "Theme initialization returned false")
            return false
        end
        
        ErrorHandler.logError("Theme", "Theme initialized successfully")
    end
    
    -- Assign to global variable
    _G.theme = themeModule
    ErrorHandler.logError("Theme", "Theme module assigned globally")
    
    -- Verify initialization
    if type(_G.theme.isInitialized) == "function" and _G.theme.isInitialized() then
        ErrorHandler.logError("Theme", "Theme verified as initialized")
        return true
    else
        ErrorHandler.logError("Theme", "Theme verification failed")
        return false
    end
end

-- Initialize theme module
initializeTheme()

-- Verify theme is accessible
if not _G.theme then
    ErrorHandler.logError("Theme", "Theme is nil after initialization")
else
    ErrorHandler.logError("Theme", "Theme is accessible globally")
end

-- Safe theme access function
function _G.safeTheme()
    if not _G.theme then
        ErrorHandler.logError("Theme", "Theme module not found, attempting reinitialization")
        initializeTheme()
        if not _G.theme then
            ErrorHandler.logError("Theme", "Theme reinitialization failed, using fallback")
            return {
                version = "fallback",
                getColor = function(name) 
                    ErrorHandler.logError("Theme", "Using fallback color for: " .. tostring(name))
                    return colors.black 
                end,
                drawTitleBar = function() end,
                init = function() return true end,
                isInitialized = function() return true end
            }
        end
    end
    
    -- If theme exists but not initialized, try to initialize it
    if type(_G.theme.isInitialized) == "function" and not _G.theme.isInitialized() then
        ErrorHandler.logError("Theme", "Theme not initialized, attempting initialization")
        if type(_G.theme.init) == "function" then
            local success = _G.theme.init()
            if not success then
                ErrorHandler.logError("Theme", "Theme initialization failed")
            else
                ErrorHandler.logError("Theme", "Theme initialized successfully")
            end
        else
            ErrorHandler.logError("Theme", "Theme missing init function")
        end
    end
    
    return _G.theme
end

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
                        local initSuccess = _G.safeTheme().init() -- Refresh theme after resize
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
                        local initSuccess = _G.safeTheme().init() -- Refresh theme after resize
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
    _G.safeTheme().drawTitleBar("SCI Sentinel OS v" .. version)
    
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
    _G.safeTheme().drawTitleBar("SCI Sentinel OS v" .. version)
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
local success, sci_sentinel = safeRequire("Sci_sentinel")

if not success or type(sci_sentinel) ~= "table" then
    ErrorHandler.logError("Startup", "SCIOS failed to start: " .. tostring(sci_sentinel))
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.clear()
    term.setCursorPos(1,1)
    print("Failed to start SCIOS. Check error.log for details.")
    return
end

-- Run SCIOS
if type(sci_sentinel.run) ~= "function" then
    ErrorHandler.logError("Startup", "SCIOS missing run function")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.clear()
    term.setCursorPos(1,1)
    print("SCIOS initialization error. Check error.log for details.")
    return
end

sci_sentinel.run()
