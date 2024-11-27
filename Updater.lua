-- SCI Sentinel OS Updater Module

-- Load required modules
local gui = require("GUI")
local test1 = 2
local updater = {}

-- GitHub repository information
updater.repo = {
    owner = "ickycoolboy",
    name = "SCIOS-Computercraft",
    branch = "Github-updating-test"
}

-- Module version information
updater.modules = {
    ["core"] = {
        version = "1.0.0",
        path = "sci_sentinel.lua"
    },
    ["gui"] = {
        version = "1.0.0",
        path = "GUI.lua"
    },
    ["commands"] = {
        version = "1.0.0",
        path = "Commands.lua"
    },
    ["updater"] = {
        version = "1.0.0",
        path = "Updater.lua"
    }
}

function updater.getGitHubRawURL(filepath)
    return string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        updater.repo.owner,
        updater.repo.name,
        updater.repo.branch,
        filepath
    )
end

function updater.downloadFromGitHub(filepath, destination)
    local url = updater.getGitHubRawURL(filepath)
    gui.drawSuccess("Downloading from: " .. url)
    
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

function updater.checkForUpdates()
    gui.drawSuccess("Checking for updates...")
    local updateFound = false
    
    for moduleName, info in pairs(updater.modules) do
        gui.drawSuccess("Checking " .. moduleName .. " module...")
        
        -- Download to temporary file first
        local tempFile = "scios/temp_" .. info.path
        local targetFile = "scios/" .. info.path
        
        if updater.downloadFromGitHub(info.path, tempFile) then
            -- Compare files
            if fs.exists(targetFile) then
                local current = fs.open(targetFile, "r")
                local new = fs.open(tempFile, "r")
                
                if current and new then
                    local currentContent = current.readAll()
                    local newContent = new.readAll()
                    current.close()
                    new.close()
                    
                    if currentContent ~= newContent then
                        gui.drawSuccess("Update found for " .. moduleName)
                        fs.delete(targetFile)
                        fs.move(tempFile, targetFile)
                        updateFound = true
                    else
                        fs.delete(tempFile)
                    end
                end
            else
                -- File doesn't exist, just move the new one
                fs.move(tempFile, targetFile)
                updateFound = true
            end
        else
            gui.drawError("Failed to check for updates for " .. moduleName)
        end
    end
    
    if updateFound then
        gui.drawSuccess("Updates installed. Rebooting in 3 seconds...")
        os.sleep(3)
        os.reboot()
    else
        gui.drawSuccess("No updates found.")
    end
end

-- Initial installation function
function updater.initialInstall()
    gui.drawSuccess("Performing initial installation...")
    local allSuccess = true
    
    -- Create scios directory if it doesn't exist
    if not fs.exists("scios") then
        fs.makeDir("scios")
    end
    
    -- Download startup file first
    if not updater.downloadFromGitHub("startup.lua", "startup.lua") then
        gui.drawError("Failed to install startup file")
        return false
    end
    
    -- Download all modules
    for moduleName, info in pairs(updater.modules) do
        local destination = "scios/" .. info.path
        gui.drawSuccess("Installing " .. moduleName .. " module...")
        
        if not updater.downloadFromGitHub(info.path, destination) then
            gui.drawError("Failed to install " .. moduleName)
            allSuccess = false
        end
    end
    
    return allSuccess
end

return updater