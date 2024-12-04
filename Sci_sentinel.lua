-- SCI Sentinel OS: A Modular Operating System for Advanced Computer with Update Capability
local version = "1.34" -- Minor version bump for startup handling improvements

-- Set up the module path
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Add the scios directory to package path
package.path = "./?.lua;/scios/?.lua;" .. package.path

-- Initialize error handling
local ErrorHandler = require("ErrorHandler")

-- Module cache to prevent circular dependencies
local loadedModules = {}

-- Forward declarations
local gui = nil
local theme
local login
local commands
local displayManager
local help
local updater

-- GitHub repository information
local GITHUB_REPO = {
    owner = "ickycoolboy",
    name = "SCIOS-Computercraft",
    branch = "Github-updating-test"
}

-- Module file mappings
local MODULE_FILES = {
    updater = "Updater.lua",
    gui = "Gui.lua",
    commands = "Commands.lua",
    sci_sentinel = "Sci_sentinel.lua",
    help = "Help.lua",
    displayManager = "DisplayManager.lua",
    login = "Login.lua",
    errorHandler = "ErrorHandler.lua"
}

-- Enhanced logging function
local function verboseLog(context, message)
    ErrorHandler.logError(context, message)
    print("[VERBOSE] " .. context .. ": " .. message)  -- Also print to screen for immediate visibility
end

-- Protected require function with module caching and initialization
local function requireModule(name, additionalParams)
    verboseLog("Module Loader", "ATTEMPTING to load module: " .. tostring(name))
    
    if loadedModules[name] then
        verboseLog("Module Loader", "Returning CACHED module: " .. name)
        return loadedModules[name]
    end
    
    local loadedModule  -- Declare outside of the protected call
    local success, result = ErrorHandler.protectedCall("require_" .. name, function()
        verboseLog("Module Loader", "Calling require() for: " .. name)
        loadedModule = require(name)
        
        verboseLog("Module Loader", "Module loaded type: " .. type(loadedModule))
        
        if loadedModule == nil then
            error("Module loaded as nil: " .. name)
        end
        
        if type(loadedModule) ~= "table" then
            error("Module did not return a table: " .. name .. ", type: " .. type(loadedModule))
        end
        
        return loadedModule
    end)
    
    if not success then
        verboseLog("Module Loader", "FAILED to load module: " .. name .. ", Error: " .. tostring(result))
        return nil
    end
    
    verboseLog("Module Loader", "Module loaded successfully: " .. name)
    
    -- Store module before initialization to prevent circular dependencies
    loadedModules[name] = loadedModule
    
    -- Initialize the module if it has an init function
    if type(loadedModule.init) == "function" then
        verboseLog("Module Loader", "Attempting to initialize module: " .. name)
        
        -- Prepare initialization parameters
        local initParams = {}
        if additionalParams then
            for k, v in pairs(additionalParams) do
                initParams[k] = v
            end
        end
        
        local initSuccess = ErrorHandler.protectedCall("init_" .. name, function()
            -- Special handling for modules with specific initialization requirements
            if name == "Updater" and _G.SystemModules and _G.SystemModules.Gui then
                initParams.guiInstance = _G.SystemModules.Gui
            end
            
            return loadedModule.init(unpack(initParams))
        end)
        
        if not initSuccess then
            verboseLog("Module Loader", "Failed to initialize module: " .. name)
            loadedModules[name] = nil
            return nil
        end
        
        verboseLog("Module Loader", "Module initialized successfully: " .. name)
    end
    
    return loadedModule
end

-- Initialize all system modules
local function initializeSystemModules()
    verboseLog("System", "STARTING system initialization")
    
    -- Create a dependency order for module loading
    local moduleLoadOrder = {
        "Theme",      -- Load first as it's a core dependency
        "Gui",        -- Load GUI next as it manages display
        "DisplayManager",
        "Commands",
        "Help",
        "Login",
        "Updater"
    }
    
    local modules = {}
    
    -- Load modules in order
    for _, moduleName in ipairs(moduleLoadOrder) do
        verboseLog("System", "Attempting to load module: " .. moduleName)
        
        -- Prepare any additional parameters for specific modules
        local additionalParams = {}
        
        local module = requireModule(moduleName, additionalParams)
        
        if not module then
            verboseLog("System", "CRITICAL FAILURE loading module: " .. moduleName)
            
            -- Provide a fallback for critical modules
            if moduleName == "Theme" then
                module = {
                    version = "fallback",
                    getColor = function(name) return colors.black end,
                    drawTitleBar = function() end,
                    init = function() return true end
                }
            elseif moduleName == "Gui" then
                module = {
                    version = "fallback",
                    clear = function() term.clear() end,
                    init = function() return true end
                }
            elseif moduleName == "Updater" then
                module = {
                    version = "fallback",
                    checkUpdates = function() return false end,
                    init = function() return true end
                }
            end
            
            -- If still no module, return false to indicate system initialization failure
            if not module then
                verboseLog("System", "ABSOLUTE FAILURE: No fallback for " .. moduleName)
                return false
            end
        end
        
        modules[moduleName] = module
        verboseLog("System", "Module stored: " .. moduleName)
    end
    
    -- Store modules globally
    _G.SystemModules = modules
    
    verboseLog("System", "SYSTEM MODULES INITIALIZED SUCCESSFULLY")
    return true
end

-- Command loop function
local function startCommandLoop()
    verboseLog("Main", "Starting command loop")
    
    -- Ensure critical modules are available
    local commands = _G.SystemModules and _G.SystemModules.Commands
    local gui = _G.SystemModules and _G.SystemModules.Gui
    local theme = _G.SystemModules and _G.SystemModules.Theme
    
    if not commands or not gui or not theme then
        verboseLog("Main", "CRITICAL: One or more required modules are missing")
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
        verboseLog("Main", "Failed to draw initial screen")
        return false
    end
    
    -- Main command processing loop
    while true do
        verboseLog("Main", "Waiting for user input")
        
        -- Safely read input
        local inputSuccess, input = pcall(read)
        
        if not inputSuccess then
            verboseLog("Main", "Input reading failed: " .. tostring(input))
            gui.drawError("Input error: " .. tostring(input))
            sleep(2)
            goto continue
        end
        
        -- Handle empty input
        if input and input ~= "" then
            verboseLog("Main", "Processing command: " .. tostring(input))
            
            -- Attempt to handle command with error handling
            local cmdSuccess, cmdResult = pcall(function()
                return commands.handleCommand(input)
            end)
            
            if not cmdSuccess then
                verboseLog("Main", "Command handling failed: " .. tostring(cmdResult))
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
    verboseLog("Main", "STARTING main initialization")
    
    -- Initialize system modules
    if not initializeSystemModules() then
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.white)
        term.write("CRITICAL SYSTEM FAILURE")
        sleep(5)  -- Give time to read
        return false
    end
    
    verboseLog("Main", "System modules initialized, proceeding...")
    
    -- Safely get modules from global SystemModules
    local gui = _G.SystemModules and _G.SystemModules.Gui
    local theme = _G.SystemModules and _G.SystemModules.Theme
    local login = _G.SystemModules and _G.SystemModules.Login
    local commands = _G.SystemModules and _G.SystemModules.Commands
    
    -- Validate critical modules
    local criticalModules = {
        {name = "GUI", module = gui},
        {name = "Theme", module = theme},
        {name = "Login", module = login},
        {name = "Commands", module = commands}
    }
    
    for _, mod in ipairs(criticalModules) do
        if not mod.module then
            verboseLog("Main", "CRITICAL MODULE MISSING: " .. mod.name)
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
        verboseLog("Main", "Failed to draw initial screen")
        return false
    end
    
    -- Start command loop
    startCommandLoop()
    
    return true
end

-- Draw initial screen with error handling
local function drawInitialScreen()
    verboseLog("Main", "Attempting to draw initial screen...")
    return ErrorHandler.protectedCall("draw_screen", function()
        verboseLog("Main", "Inside drawScreen function")
        
        -- Use SystemModules instead of local gui variable
        local gui = _G.SystemModules and _G.SystemModules.Gui
        if not gui then
            verboseLog("Main", "GUI module not available, using fallback")
            term.clear()
            term.setCursorPos(1,1)
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.write("System Initialization Failed")
            return false
        end
        
        -- Rest of the existing drawing logic
        gui.clear()
        
        local theme = _G.SystemModules and _G.SystemModules.Theme
        if theme then
            theme.drawTitleBar("SCI Sentinel OS v" .. version)
        end
        
        return true
    end)
end

-- Wrap the entire script execution in a protected call
local function safeStart()
    verboseLog("Startup", "SAFE START INITIATED")
    local status, result = pcall(main)
    
    if not status then
        verboseLog("Startup", "CATASTROPHIC FAILURE: " .. tostring(result))
        term.clear()
        term.setCursorPos(1,1)
        term.setBackgroundColor(colors.red)
        term.setTextColor(colors.white)
        term.write("SYSTEM STARTUP FAILED")
        term.setCursorPos(1,2)
        term.write(tostring(result))
        sleep(10)  -- Give time to read error
    end
    
    return status
end

-- Call the safe start function
safeStart()
