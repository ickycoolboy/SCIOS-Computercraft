-- SCI Sentinel OS: A Modular Operating System for Advanced Pocket Computer with Update Capability

-- This is the core boot module: sci_sentinel.lua

-- Set up the module path
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Add the scios directory to package path
package.path = "/scios/?.lua;" .. package.path

-- Small Updater for Initial Installation
local pastebinURLs = {
    gui = "t1aaU92t",
    commands = "J8wHbkPK",
    updater = "CHU2eqLh",
    sci_sentinel = "FYqUHbiR",
    startup = "Xhc3PP8J"
}

local function ensureDirectoryExists(dir)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

local function downloadFromPastebin(pastebinCode, destination)
    print("Downloading to " .. destination)
    if fs.exists(destination) then
        fs.delete(destination)
    end
    return shell.run("pastebin", "get", pastebinCode, destination)
end

local function checkSelfUpdate()
    print("Checking for core updates...")
    local tempFile = "scios/sci_sentinel_temp.lua"
    
    if downloadFromPastebin(pastebinURLs.sci_sentinel, tempFile) then
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

local function initialUpdate()
    print("Performing initial installation...")
    ensureDirectoryExists("scios")
    local allSuccess = true
    
    for moduleName, pastebinURL in pairs(pastebinURLs) do
        local destination
        if moduleName == "startup" then
            destination = "startup.lua"
        elseif moduleName == "sci_sentinel" then
            destination = "scios/sci_sentinel.lua"
        else
            destination = "scios/" .. moduleName .. ".lua"
        end
        
        print("Downloading " .. moduleName .. " from Pastebin...")
        if not downloadFromPastebin(pastebinURL, destination) then
            print("Failed to install " .. moduleName)
            allSuccess = false
        else
            print("Installed " .. moduleName .. " module successfully.")
        end
    end
    
    if allSuccess then
        print("Initial installation complete. Rebooting in 3 seconds...")
        os.sleep(3)
        os.reboot()
    else
        print("Initial installation failed. Please check errors above and try again.")
    end
end

-- Check if modules are already installed, otherwise perform initial update
if not fs.exists("scios/gui.lua") or 
   not fs.exists("scios/commands.lua") or 
   not fs.exists("scios/updater.lua") or 
   not fs.exists("scios/sci_sentinel.lua") then
    initialUpdate()
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
