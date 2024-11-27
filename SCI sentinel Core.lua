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

local function checkSelfUpdate()
    print("Checking for core updates...")
    local tempFile = "scios/sci_sentinel_temp.lua"
    
    if downloadFromGitHub("sci_sentinel.lua", tempFile) then
        -- Compare files
        local current = fs.open("scios/sci_sentinel.lua", "r")
        local new = fs.open(tempFile, "r")
        
        if current and new then
            local currentContent = current.readAll()
            local newContent = new.readAll()
            current.close()
            new.close()
            
            if currentContent ~= newContent then
                print("Update found! Installing...")
                fs.delete("scios/sci_sentinel.lua")
                fs.move(tempFile, "scios/sci_sentinel.lua")
                print("Core updated. Rebooting...")
                os.sleep(2)
                os.reboot()
            else
                fs.delete(tempFile)
                print("No updates found.")
            end
        end
    else
        print("Failed to check for updates.")
    end
end

local function initialSetup()
    print("Performing initial installation...")
    
    -- Download updater module first
    if not downloadFromGitHub("updater.lua", "scios/updater.lua") then
        print("Failed to download updater module")
        return false
    end
    
    -- Load updater module
    local success, updater = pcall(require, "updater")
    if not success then
        print("Failed to load updater module")
        return false
    end
    
    -- Use updater to install everything else
    return updater.initialInstall()
end

-- Check if modules are already installed, otherwise perform initial update
if not fs.exists("scios/gui.lua") or 
   not fs.exists("scios/commands.lua") or 
   not fs.exists("scios/updater.lua") or 
   not fs.exists("scios/sci_sentinel.lua") then
    initialSetup()
    return
end

-- Check for self-updates first
checkSelfUpdate()

-- Load modules
local function loadModule(name, required)
    local success, module = pcall(require, name)
    if not success or not module then
        if required then
            error("Failed to load " .. name .. " module: " .. tostring(module))
        end
        return nil
    end
    return module
end

-- Load required modules
local gui = loadModule("gui", true)
local commands = loadModule("commands", true)
local updater = loadModule("updater", true)

-- Main Loop
local function startSentinelOS()
    gui.drawScreen()
    while true do
        gui.printPrompt()
        local input = read()
        if input then
            if not commands.executeCommand(input, gui) then
                break
            end
        end
    end
    gui.drawSuccess("Shutting down SCI Sentinel OS...")
end

-- Start the OS
print("Starting SCI Sentinel OS...")
local ok, err = pcall(startSentinelOS)
if not ok then
    if gui then
        gui.drawError("An unexpected error occurred: " .. tostring(err))
    else
        print("An unexpected error occurred: " .. tostring(err))
    end
end
