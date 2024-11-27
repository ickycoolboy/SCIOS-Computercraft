-- SCI Sentinel OS: A Modular Operating System for Advanced Pocket Computer with Update Capability

-- This is the core boot module: sci_sentinel.lua

-- Set up the module path
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Add the scios directory to package path
package.path = "/scios/?.lua;" .. package.path

-- GitHub repository information
local GITHUB_REPO = {
    owner = "ickycoolboy",
    name = "SCIOS-Computercraft",
    branch = "Github-updating-test"
}

-- Module file mappings
local MODULE_FILES = {
    updater = "Updater.lua",
    gui = "GUI.lua",
    commands = "Commands.lua",
    core = "sci_sentinel.lua"
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
    
    print("Initial setup complete!")
    return true
end

-- Check if modules exist, otherwise perform initial setup
if not fs.exists("scios/" .. MODULE_FILES.updater) or 
   not fs.exists("scios/" .. MODULE_FILES.gui) or
   not fs.exists("scios/" .. MODULE_FILES.commands) or
   not fs.exists("scios/" .. MODULE_FILES.core) then
    if not initialSetup() then
        print("Initial setup failed!")
        return
    end
    print("Rebooting in 3 seconds...")
    os.sleep(3)
    os.reboot()
end

-- Load modules
local function loadModule(name)
    local success, module = pcall(require, name)
    if not success then
        print("Failed to load " .. name .. ": " .. tostring(module))
        return nil
    end
    return module
end

-- Load required modules
local gui = loadModule("GUI")
if not gui then return end

local updater = loadModule("Updater")
if not updater then return end

local commands = loadModule("Commands")
if not commands then return end

-- Main Loop
local function startSentinelOS()
    gui.drawScreen()
    while true do
        gui.printPrompt()
        local input = read()
        if input then
            if input == "exit" then
                break
            elseif input == "update" then
                updater.checkForUpdates()
            else
                commands.executeCommand(input, gui)
            end
        end
    end
    print("Shutting down SCI Sentinel OS...")
end

-- Start the OS
print("Starting SCI Sentinel OS...")
local ok, err = pcall(startSentinelOS)
if not ok then
    print("An unexpected error occurred: " .. tostring(err))
end
