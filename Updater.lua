-- SCI Sentinel OS Updater Module
local version = "1.0.1"

-- Load required modules
local gui = require("Gui")

local updater = {}

-- GitHub repository information
updater.repo = {
    owner = "ickycoolboy",
    name = "SCIOS-Computercraft",
    branch = "Github-updating-test"
}

-- Module version information and file hashes
updater.modules = {
    ["core"] = {
        version = "1.0.0",
        path = "Sci_sentinel.lua",
        hash = nil
    },
    ["gui"] = {
        version = "1.0.0",
        path = "Gui.lua",
        hash = nil
    },
    ["commands"] = {
        version = "1.0.1",
        path = "Commands.lua",
        hash = nil
    },
    ["updater"] = {
        version = "1.0.1",
        path = "Updater.lua",
        hash = nil
    },
    ["installer"] = {
        version = "1.0.0",
        path = "Installer.lua",
        hash = nil
    },
    ["startup"] = {
        version = "1.0.0",
        path = "Startup.lua",
        hash = nil
    }
}

-- Auto-update settings
updater.settings = {
    auto_check = true,
    check_interval = 3600, -- Check every hour
    last_check = 0,
    auto_install = false -- Require confirmation by default
}

function updater.calculateHash(content)
    -- Simple hash function for file validation
    local hash = 0
    for i = 1, #content do
        hash = (hash * 31 + string.byte(content, i)) % 2^32
    end
    return string.format("%08x", hash)
end

function updater.validateFile(path, expected_hash)
    if not fs.exists(path) then
        return false, "File does not exist"
    end

    local file = fs.open(path, "r")
    if not file then
        return false, "Cannot open file"
    end

    local content = file.readAll()
    file.close()

    local actual_hash = updater.calculateHash(content)
    return actual_hash == expected_hash, actual_hash
end

function updater.validateAllFiles()
    local all_valid = true
    gui.drawSuccess("Validating system files...")
    
    for name, info in pairs(updater.modules) do
        local path = "scios/" .. info.path
        local valid, result = updater.validateFile(path, info.hash)
        
        if valid then
            gui.drawSuccess(string.format("%s: Valid", name))
        else
            all_valid = false
            gui.drawError(string.format("%s: Invalid (%s)", name, result))
        end
    end
    
    return all_valid
end

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
        
        -- Calculate and store hash before saving
        local hash = updater.calculateHash(content)
        for _, info in pairs(updater.modules) do
            if info.path == fs.getName(path) then
                info.hash = hash
                break
            end
        end
        
        local file = fs.open(path, "w")
        file.write(content)
        file.close()
        return true, hash
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
        return version, updater.calculateHash(content)
    end
    return nil
end

function updater.checkForUpdates(auto_mode)
    local updates_available = false
    
    -- Update last check time
    updater.settings.last_check = os.epoch("utc")
    
    for name, info in pairs(updater.modules) do
        local remote_version, remote_hash = updater.getRemoteVersion(info.path)
        if remote_version and (remote_version ~= info.version or remote_hash ~= info.hash) then
            if not auto_mode then
                gui.drawSuccess(string.format("Update available for %s: %s -> %s", name, info.version, remote_version))
            end
            updates_available = true
            
            if auto_mode and updater.settings.auto_install or
               not auto_mode and gui.confirm("Install update for " .. name .. "?") then
                -- Download the update
                local url = updater.getGitHubRawURL(info.path)
                local success, new_hash = updater.downloadFile(url, "scios/" .. info.path)
                if success then
                    if not auto_mode then
                        gui.drawSuccess(string.format("Successfully updated %s", name))
                    end
                    -- Update local version and hash
                    info.version = remote_version
                    info.hash = new_hash
                else
                    gui.drawError(string.format("Failed to update %s", name))
                end
            end
        elseif not auto_mode then
            gui.drawSuccess(string.format("%s is up to date", name))
        end
    end
    
    return updates_available
end

-- Function to run periodic update checks
function updater.autoUpdateCheck()
    local current_time = os.epoch("utc")
    if updater.settings.auto_check and 
       (current_time - updater.settings.last_check) >= (updater.settings.check_interval * 1000) then
        if updater.checkForUpdates(true) then
            gui.drawSuccess("Updates were found and " .. 
                          (updater.settings.auto_install and "installed" or "are available"))
        end
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
    if not updater.downloadFile(updater.getGitHubRawURL("Startup.lua"), "Startup.lua") then
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