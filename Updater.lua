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
        path = "Sci_sentinel.lua"
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
    },
    ["installer"] = {
        version = "1.0.0",
        path = "Installer.lua"
    },
    ["startup"] = {
        version = "1.0.0",
        path = "Startup.lua"
    }
}

function updater.getGitHubRawURL(filepath)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s",
        updater.repo.owner,
        updater.repo.name,
        updater.repo.branch,
        filepath)
end

function updater.downloadFile(url, path)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(path, "w")
        file.write(content)
        file.close()
        return true
    end
    return false
end

function updater.getRemoteVersion(filepath)
    local url = updater.getGitHubRawURL(filepath)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        -- Look for version string in the file
        local version = string.match(content, "version%s*=%s*[\"']([%d%.]+)[\"']")
        return version
    end
    return nil
end

function updater.checkForUpdates()
    local updates_available = false
    
    for name, info in pairs(updater.modules) do
        local remote_version = updater.getRemoteVersion(info.path)
        if remote_version and remote_version ~= info.version then
            gui.drawSuccess(string.format("Update available for %s: %s -> %s", name, info.version, remote_version))
            updates_available = true
            
            -- Download the update
            local url = updater.getGitHubRawURL(info.path)
            if updater.downloadFile(url, info.path) then
                gui.drawSuccess(string.format("Successfully updated %s", name))
                -- Update local version
                info.version = remote_version
            else
                gui.drawError(string.format("Failed to update %s", name))
            end
        else
            gui.drawSuccess(string.format("%s is up to date", name))
        end
    end
    
    return updates_available
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
    if not updater.downloadFile(updater.getGitHubRawURL("startup.lua"), "startup.lua") then
        gui.drawError("Failed to install startup file")
        return false
    end
    
    -- Download all modules
    for moduleName, info in pairs(updater.modules) do
        local destination = "scios/" .. info.path
        gui.drawSuccess("Installing " .. moduleName .. " module...")
        
        if not updater.downloadFile(updater.getGitHubRawURL(info.path), destination) then
            gui.drawError("Failed to install " .. moduleName)
            allSuccess = false
        end
    end
    
    return allSuccess
end

return updater