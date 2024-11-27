-- SCI Sentinel OS: A Modular Operating System for Advanced Computer with Update Capability
local version = "1.0.2" -- Minor version bump for startup handling improvements

-- Set up the module path
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Add the scios directory to package path
package.path = "./?.lua;/scios/?.lua;" .. package.path

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
    core = "Sci_sentinel.lua",
    help = "Help.lua",
    displayManager = "DisplayManager.lua",
    login = "Login.lua"
}

local function getGitHubRawURL(filepath)
    return string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        GITHUB_REPO.owner,
        GITHUB_REPO.name,
        GITHUB_REPO.branch,
        filepath
    )
end

local function downloadFromGitHub(filepath, destination)
    local url = getGitHubRawURL(filepath)
    print("Downloading from: " .. url)
    
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(destination, "w")
        file.write(content)
        file.close()
        return true
    end
    return false
end

local function createStartup()
    print("Creating startup file...")
    local file = fs.open("startup.lua", "w")
    file.write('-- SCI Sentinel OS Startup File\nshell.run("scios/sci_sentinel.lua")')
    file.close()
end

local function initialSetup()
    print("Performing initial installation...")
    
    -- Create startup file FIRST to ensure it exists for next boot
    createStartup()
    
    -- Save core file first
    print("Saving core module...")
    local currentFile = fs.open(shell.getRunningProgram(), "r")
    if currentFile then
        local content = currentFile.readAll()
        currentFile.close()
        
        local coreFile = fs.open("scios/" .. MODULE_FILES.core, "w")
        coreFile.write(content)
        coreFile.close()
    end
    
    -- Download updater module
    print("Downloading Updater module...")
    if not downloadFromGitHub(MODULE_FILES.updater, "scios/" .. MODULE_FILES.updater) then
        print("Failed to download updater module")
        return false
    end
    
    -- Download GUI module
    print("Downloading GUI module...")
    if not downloadFromGitHub(MODULE_FILES.gui, "scios/" .. MODULE_FILES.gui) then
        print("Failed to download GUI module")
        return false
    end
    
    -- Download Commands module
    print("Downloading Commands module...")
    if not downloadFromGitHub(MODULE_FILES.commands, "scios/" .. MODULE_FILES.commands) then
        print("Failed to download Commands module")
        return false
    end
    
    -- Download Help module
    print("Downloading Help module...")
    if not downloadFromGitHub(MODULE_FILES.help, "scios/" .. MODULE_FILES.help) then
        print("Failed to download Help module")
        return false
    end
    
    -- Download DisplayManager module
    print("Downloading DisplayManager module...")
    if not downloadFromGitHub(MODULE_FILES.displayManager, "scios/" .. MODULE_FILES.displayManager) then
        print("Failed to download DisplayManager module")
        return false
    end
    
    -- Download Login module
    print("Downloading Login module...")
    if not downloadFromGitHub(MODULE_FILES.login, "scios/" .. MODULE_FILES.login) then
        print("Failed to download Login module")
        return false
    end
    
    print("Initial setup complete!")
    return true
end

-- Check if modules exist, otherwise perform initial setup
if not fs.exists("scios/" .. MODULE_FILES.updater) or 
   not fs.exists("scios/" .. MODULE_FILES.gui) or
   not fs.exists("scios/" .. MODULE_FILES.commands) or
   not fs.exists("scios/" .. MODULE_FILES.core) or
   not fs.exists("scios/" .. MODULE_FILES.help) or
   not fs.exists("scios/" .. MODULE_FILES.displayManager) or
   not fs.exists("scios/" .. MODULE_FILES.login) then
    if not initialSetup() then
        print("Initial setup failed!")
        return
    end
    print("Rebooting in 3 seconds...")
    os.sleep(3)
    os.reboot()
end

-- Error handling wrapper
local function protected_call(func, ...)
    local status, result = pcall(func, ...)
    if not status then
        -- Log the error
        local file = fs.open("scios/error.log", "a")
        if file then
            file.write(string.format("[%s] %s\n", os.date(), result))
            file.close()
        end
        return false, result
    end
    return true, result
end

-- Module loader with error recovery
local function loadModule(name, required)
    local status, result = protected_call(require, name)
    if not status then
        print(string.format("Failed to load %s: %s", name, result))
        if required then
            return nil
        else
            -- Return empty table for optional modules
            return {}
        end
    end
    return result
end

-- Initialize the system
local function initSystem()
    -- Add the scios directory to package path
    package.path = "scios/?.lua;" .. package.path

    -- Load required modules with error handling
    local gui = loadModule("Gui", true)
    if not gui then return false end

    local updater = loadModule("Updater", true)
    if not updater then return false end
    
    -- Initialize updater with GUI instance
    updater = updater.init(gui)
    if not updater then 
        gui.drawError("Failed to initialize updater")
        return false 
    end

    local commands = loadModule("Commands", true)
    if not commands then return false end

    local help = loadModule("Help", false)
    if not help then 
        gui.drawError("Failed to load Help module")
    end

    local displayManager = loadModule("DisplayManager", false)
    if not displayManager then 
        gui.drawError("Failed to load DisplayManager module")
    end

    local login = loadModule("Login", false)
    if not login then 
        gui.drawError("Failed to load Login module")
    end

    return gui, updater, commands, help, displayManager, login
end

-- Command execution wrapper
local function executeCommand(command, gui, updater, commands, help, displayManager, login)
    if command == "exit" then
        return false
    else
        protected_call(function()
            commands.handleCommand(command)
        end)
    end
    return true
end

-- Main loop with error recovery
local function mainLoop(gui, updater, commands, help, displayManager, login)
    local running = true
    local lastUpdateCheck = os.epoch("utc")
    
    while running do
        local currentTime = os.epoch("utc")
        
        -- Only check for updates every hour (3600000 milliseconds)
        if currentTime - lastUpdateCheck >= 3600000 then
            protected_call(function()
                updater.autoUpdateCheck()
            end)
            lastUpdateCheck = currentTime
        end

        -- Command processing
        gui.printPrompt()
        local input = read()
        if input then
            running = executeCommand(input, gui, updater, commands, help, displayManager, login)
        end

        -- Error recovery
        if not running then
            if gui.confirm("Do you want to restart SCI Sentinel?") then
                os.reboot()
            end
        end
    end
end

-- Main entry point with error handling
local function main()
    -- Initialize modules
    local gui, updater, commands, help, displayManager, login = initSystem()
    if not gui then
        print("Failed to initialize SCI Sentinel. Check error.log for details.")
        return
    end

    -- Draw initial screen
    gui.drawScreen()

    -- Enter main loop
    protected_call(function()
        mainLoop(gui, updater, commands, help, displayManager, login)
    end)

    -- Clean shutdown
    print("Shutting down SCI Sentinel OS...")
end

-- Start the OS with global error handler
_G.debug.traceback = function(err)
    local file = fs.open("scios/error.log", "a")
    if file then
        file.write(string.format("[%s] Traceback: %s\n", os.date(), err))
        file.close()
    end
    return err
end

protected_call(main)
