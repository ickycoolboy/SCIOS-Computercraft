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

-- Protected files that cannot be deleted
updater.protected_files = {
    "scios/Sci_sentinel.lua",
    "scios/Gui.lua",
    "scios/Commands.lua",
    "scios/Updater.lua",
    "startup.lua",
    "scios/versions.db"
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

-- Load saved versions from file
function updater.loadVersions()
    if fs.exists("scios/versions.db") then
        local file = fs.open("scios/versions.db", "r")
        if file then
            local content = file.readAll()
            file.close()
            
            for name, version in string.gmatch(content, "(%w+):([%d%.]+)") do
                if updater.modules[name] then
                    updater.modules[name].version = version
                end
            end
        end
    end
end

-- Save current versions to file
function updater.saveVersions()
    local file = fs.open("scios/versions.db", "w")
    if file then
        for name, info in pairs(updater.modules) do
            file.write(string.format("%s:%s\n", name, info.version))
        end
        file.close()
    end
end

-- Protect system files from deletion
function updater.protectFiles()
    -- Override fs.delete for protected files
    local original_delete = fs.delete
    fs.delete = function(path)
        path = fs.combine("", path) -- Normalize path
        for _, protected in ipairs(updater.protected_files) do
            if path == protected then
                return false -- Prevent deletion of protected files
            end
        end
        return original_delete(path)
    end
end

function updater.calculateHash(content)
    local hash = 0
    for i = 1, #content do
        hash = (hash * 31 + string.byte(content, i)) % 2^32
    end
    return string.format("%08x", hash)
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
    local updates_installed = false
    
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
                    updates_installed = true
                else
                    gui.drawError(string.format("Failed to update %s", name))
                end
            end
        elseif not auto_mode then
            gui.drawSuccess(string.format("%s is up to date", name))
        end
    end
    
    -- Save updated versions
    if updates_installed then
        updater.saveVersions()
        if not auto_mode then
            gui.drawSuccess("Updates installed. Rebooting in 3 seconds...")
            os.sleep(3)
            os.reboot()
        end
    end
    
    return updates_available
end

-- Initialize
updater.loadVersions() -- Load saved versions
updater.protectFiles() -- Enable file protection

return updater