-- SCI Sentinel OS: A Modular Operating System for Advanced Computer with Update Capability
local version = "1.34" -- Minor version bump for startup handling improvements

-- Initialize error handling
local ErrorHandler = require("ErrorHandler")

-- Enhanced logging function
local function verboseLog(context, message)
    ErrorHandler.logError(context, message)
end

-- Global module to track system modules
SystemModules = {}

-- Set up the module path
if not fs.exists("scios") then
    ErrorHandler.logError("System", "Creating SCIOS directory...")
    local success = pcall(function() fs.makeDir("scios") end)
    if not success then
        error("Failed to create SCIOS directory")
    end
end

ErrorHandler.logError("System", "Starting SCIOS initialization...")

-- Add the scios directory to package path
package.path = "./?.lua;/scios/?.lua;" .. package.path

-- Protected require function with module caching and initialization
local function requireModule(name, additionalParams)
    ErrorHandler.logError("Module Loader", "Loading module: " .. tostring(name))
    
    -- Check if module is already loaded and initialized
    if SystemModules[name] then
        ErrorHandler.logError("Module Loader", "Module already loaded: " .. name)
        return SystemModules[name]
    end
    
    local success, loadedModule = pcall(require, name)
    
    if not success then
        ErrorHandler.logError("Module Loader", "ERROR loading module: " .. name .. " - " .. tostring(loadedModule))
        return nil
    end
    
    if loadedModule == nil then
        ErrorHandler.logError("Module Loader", "Module loaded as nil: " .. name)
        return nil
    end
    
    if type(loadedModule) ~= "table" then
        ErrorHandler.logError("Module Loader", "Module did not return a table: " .. name .. ", type: " .. type(loadedModule))
        return nil
    end
    
    ErrorHandler.logError("Module Loader", "Module loaded successfully: " .. name)
    
    -- Store module in SystemModules before initialization to prevent cycles
    SystemModules[name] = loadedModule
    
    -- Initialize the module if it has an init function
    if type(loadedModule.init) == "function" then
        ErrorHandler.logError("Module Loader", "Initializing module: " .. name)
        
        local initSuccess, initErr = pcall(function()
            return loadedModule.init(additionalParams)
        end)
        
        if not initSuccess then
            ErrorHandler.logError("Module Loader", "ERROR initializing module: " .. name .. " - " .. tostring(initErr))
            -- Don't remove from SystemModules, just mark as failed
            SystemModules[name .. "_init_failed"] = true
        end
    end
    
    return loadedModule
end

-- Global function to initialize system modules
function initializeSystemModules()
    ErrorHandler.logError("System", "STARTING system initialization")
    
    -- Create a dependency order for module loading
    local moduleLoadOrder = {
        "ErrorHandler",
        "Theme",
        "Gui",
        "DisplayManager",
        "Login",
        "Commands"
    }
    
    -- Track module loading status
    local loadedModules = {}
    
    -- Load and initialize modules
    for _, moduleName in ipairs(moduleLoadOrder) do
        -- Skip if module is already properly loaded and initialized
        if SystemModules[moduleName] and not SystemModules[moduleName .. "_init_failed"] then
            ErrorHandler.logError("Module Loader", "Skipping already initialized module: " .. moduleName)
            loadedModules[moduleName] = SystemModules[moduleName]
            goto continue
        end
        
        ErrorHandler.logError("Module Loader", "Loading module: " .. moduleName)
        local module = requireModule(moduleName)
        
        if not module then
            ErrorHandler.logError("Module Loader", "CRITICAL: Failed to load module: " .. moduleName)
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.red)
            term.write("SYSTEM INITIALIZATION FAILED: COULD NOT LOAD " .. moduleName:upper())
            return false
        end
        
        loadedModules[moduleName] = module
        ::continue::
    end
    
    -- Update SystemModules global with newly loaded modules
    for name, module in pairs(loadedModules) do
        SystemModules[name] = module
    end
    
    -- Attempt to start system UI
    if type(startSystemUI) ~= "function" then
        ErrorHandler.logError("System", "CRITICAL: startSystemUI is not a valid function")
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        term.write("SYSTEM INITIALIZATION FAILED: INVALID STARTUP FUNCTION")
        return false
    end
    
    local uiSuccess, uiResult = pcall(startSystemUI)
    if not uiSuccess then
        ErrorHandler.logError("System", "Failed to start system UI: " .. tostring(uiResult))
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        term.write("SYSTEM UI INITIALIZATION FAILED: " .. tostring(uiResult))
        return false
    end
    
    -- Check the return value of startSystemUI
    if uiResult ~= true then
        ErrorHandler.logError("System", "System UI initialization returned false")
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        term.write("SYSTEM UI INITIALIZATION FAILED")
        return false
    end
    
    return true
end

-- Start system UI
function startSystemUI()
    ErrorHandler.logError("System", "Starting System UI Components")
    
    -- Verify theme module is loaded
    local themeModule = SystemModules.Theme
    if not themeModule then
        ErrorHandler.logError("System", "CRITICAL: Theme module not loaded")
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        term.write("SYSTEM UI INITIALIZATION FAILED: THEME NOT LOADED")
        return false
    end
    
    -- Start the cursor thread
    local cursorThread
    local cursorSuccess, cursorErr = pcall(function()
        cursorThread = themeModule.startMSDOSCursor()
        if not cursorThread then
            error("Failed to create cursor thread")
        end
    end)
    
    if not cursorSuccess then
        ErrorHandler.logError("System", "Failed to start cursor thread: " .. tostring(cursorErr))
        return false
    end
    
    -- Start parallel execution of cursor thread and login screen
    parallel.waitForAny(
        function()
            while true do
                local success, err = coroutine.resume(cursorThread)
                if not success then
                    ErrorHandler.logError("System", "Cursor thread error: " .. tostring(err))
                    break
                end
                if coroutine.status(cursorThread) == "dead" then
                    break
                end
                os.sleep(0.5)
            end
        end,
        function()
            local login = SystemModules.Login
            if login then
                login.showLoginScreen()
            else
                ErrorHandler.logError("System", "Login module not available")
            end
        end
    )
    
    return true
end

-- Command loop function
local function startCommandLoop()
    ErrorHandler.logError("Main", "Starting command loop")
    
    -- Ensure critical modules are available
    local commands = SystemModules.Commands
    local gui = SystemModules.Gui
    local theme = SystemModules.Theme
    
    if not commands or not gui or not theme then
        ErrorHandler.logError("Main", "CRITICAL: One or more required modules are missing")
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        term.write("SYSTEM INITIALIZATION FAILED")
        return false
    end
    
    -- Attempt to draw initial screen
    local screenDrawSuccess = ErrorHandler.protectedCall("draw_initial_screen", function()
        term.setBackgroundColor(theme.getColor("background"))
        term.setTextColor(theme.getColor("text"))
        term.clear()
        
        -- Draw a welcome message
        local w, h = term.getSize()
        term.setCursorPos(1, h/2)
        local welcomeText = "Welcome to SCIOS"
        term.setCursorPos((w - #welcomeText) / 2, h/2)
        term.write(welcomeText)
        
        -- Draw command prompt
        term.setCursorPos(1, h - 1)
        term.write("SCIOS> ")
        
        return true
    end)
    
    if not screenDrawSuccess then
        ErrorHandler.logError("Main", "Failed to draw initial screen")
        return false
    end
    
    -- Main command processing loop
    while true do
        ErrorHandler.logError("Main", "Waiting for user input")
        
        -- Safely read input
        local inputSuccess, input = pcall(read)
        
        if not inputSuccess then
            ErrorHandler.logError("Main", "Input reading failed: " .. tostring(input))
            gui.drawError("Input error: " .. tostring(input))
            sleep(2)
            goto continue
        end
        
        -- Handle empty input
        if input and input ~= "" then
            ErrorHandler.logError("Main", "Processing command: " .. tostring(input))
            
            -- Attempt to handle command with error handling
            local cmdSuccess, cmdResult = pcall(function()
                return commands.handleCommand(input)
            end)
            
            if not cmdSuccess then
                ErrorHandler.logError("Main", "Command handling failed: " .. tostring(cmdResult))
                gui.drawError("Error processing command: " .. tostring(cmdResult))
                sleep(2)
            end
        end
        
        ::continue::
        
        -- Redraw prompt
        term.setCursorPos(1, term.getSize() - 1)
        term.write("SCIOS> ")
    end
end

-- Main function to initialize and draw interface
local function main()
    ErrorHandler.logError("Main", "STARTING main initialization")
    
    -- Initialize system modules
    if not initializeSystemModules() then
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.white)
        term.write("CRITICAL SYSTEM FAILURE")
        sleep(5)  -- Give time to read
        return false
    end
    
    ErrorHandler.logError("Main", "System modules initialized, proceeding...")
    
    -- Safely get modules from global SystemModules
    local gui = SystemModules.Gui
    local theme = SystemModules.Theme
    local login = SystemModules.Login
    local commands = SystemModules.Commands
    
    -- Validate critical modules
    local criticalModules = {
        {name = "GUI", module = gui},
        {name = "Theme", module = theme},
        {name = "Login", module = login},
        {name = "Commands", module = commands}
    }
    
    for _, mod in ipairs(criticalModules) do
        if not mod.module then
            ErrorHandler.logError("Main", "CRITICAL MODULE MISSING: " .. mod.name)
            term.clear()
            term.setCursorPos(1,1)
            term.setBackgroundColor(colors.red)
            term.setTextColor(colors.white)
            term.write("MISSING CRITICAL MODULE: " .. mod.name)
            sleep(5)
            return false
        end
    end
    
    -- Attempt to draw initial screen
    local screenInitSuccess = ErrorHandler.protectedCall("draw_initial_screen", function()
        if theme then
            theme.drawTitleBar("SCI Sentinel OS v" .. version)
        end
        
        if gui then
            gui.clear()
        end
        
        return true
    end)
    
    if not screenInitSuccess then
        ErrorHandler.logError("Main", "Failed to draw initial screen")
        return false
    end
    
    -- Start command loop
    startCommandLoop()
    
    return true
end

-- Draw initial screen with error handling
local function drawInitialScreen()
    ErrorHandler.logError("Main", "Attempting to draw initial screen...")
    return ErrorHandler.protectedCall("draw_screen", function()
        ErrorHandler.logError("Main", "Inside drawScreen function")
        
        -- Use SystemModules instead of local gui variable
        local gui = SystemModules.Gui
        if not gui then
            ErrorHandler.logError("Main", "GUI module not available, using fallback")
            term.clear()
            term.setCursorPos(1,1)
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.write("System Initialization Failed")
            return false
        end
        
        -- Rest of the existing drawing logic
        gui.clear()
        
        local theme = SystemModules.Theme
        if theme then
            theme.drawTitleBar("SCI Sentinel OS v" .. version)
        end
        
        return true
    end)
end

-- Create the module table
local sci_sentinel = {
    version = version
}

-- Main run function that will be called by Startup.lua
function sci_sentinel.run()
    ErrorHandler.logError("Startup", "SAFE START INITIATED")
    
    -- Attempt to initialize system modules
    local initSuccess, initResult = pcall(initializeSystemModules)
    
    if not initSuccess then
        ErrorHandler.logError("Startup", "CATASTROPHIC FAILURE: " .. tostring(initResult))
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        term.write("SYSTEM STARTUP FAILED: " .. tostring(initResult))
        return false
    end
    
    -- Check the return value of initializeSystemModules
    if initResult ~= true then
        ErrorHandler.logError("Startup", "SYSTEM INITIALIZATION FAILED")
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        term.write("SYSTEM INITIALIZATION FAILED")
        return false
    end
    
    -- If initialization succeeds, start the main command loop
    local loopSuccess, loopResult = pcall(startCommandLoop)
    
    if not loopSuccess then
        ErrorHandler.logError("Startup", "COMMAND LOOP FAILED: " .. tostring(loopResult))
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.red)
        term.write("SYSTEM COMMAND LOOP FAILED: " .. tostring(loopResult))
        return false
    end
    
    return true
end

-- Return the module
return sci_sentinel
