-- SCI Sentinel OS Updater Module
local version = "1.0.2" -- Minor version bump for improved file handling

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
        version = "1.0.2",  -- Updated for startup handling improvements
        path = "Sci_sentinel.lua",
        target = "scios/Sci_sentinel.lua",
        hash = nil
    },
    ["gui"] = {
        version = "1.0.1",  -- No changes
        path = "Gui.lua",
        target = "scios/Gui.lua",
        hash = nil
    },
    ["commands"] = {
        version = "1.0.1",  -- No changes
        path = "Commands.lua",
        target = "scios/Commands.lua",
        hash = nil
    },
    ["updater"] = {
        version = "1.0.2",  -- This file's version
        path = "Updater.lua",
        target = "scios/Updater.lua",
        hash = nil
    },
    ["installer"] = {
        version = "1.1.0",  -- Major version bump for installer
        path = "Installer.lua",
        target = "Installer.lua",
        hash = nil
    },
    ["startup"] = {
        version = "1.0.1",  -- Properly cased version
        path = "Startup.lua",
        target = "startup.lua",
        hash = nil,
        root = true
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
            
            for name, version, hash in string.gmatch(content, "(%w+):([%d%.]+):(%x+)") do
                if updater.modules[name] then
                    updater.modules[name].version = version
                    updater.modules[name].hash = hash
                end
            end
        end
    else
        -- Calculate initial hashes for existing files
        for name, info in pairs(updater.modules) do
            local path = info.target
            if fs.exists(path) then
                local file = fs.open(path, "r")
                if file then
                    local content = file.readAll()
                    file.close()
                    info.hash = updater.calculateHash(content)
                end
            end
        end
        -- Save initial versions
        updater.saveVersions()
    end
end

-- Save current versions to file
function updater.saveVersions()
    local file = fs.open("scios/versions.db", "w")
    if file then
        for name, info in pairs(updater.modules) do
            file.write(string.format("%s:%s:%s\n", name, info.version, info.hash or ""))
        end
        file.close()
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
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s?cb=%d",
        updater.repo.owner,
        updater.repo.name,
        updater.repo.branch,
        filepath,
        os.epoch("utc")) -- Restore cache-busting timestamp
end

function updater.downloadFile(url, path)
    gui.drawInfo("Downloading: " .. path)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        -- Create parent directory if it doesn't exist
        local dir = fs.getDir(path)
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        -- Check if file is protected
        local isProtected = false
        for _, pfile in ipairs(updater.protected_files) do
            if pfile == path then
                isProtected = true
                break
            end
        end
        
        -- Handle protected files
        if isProtected and fs.exists(path) then
            if not gui.confirm("Warning: " .. path .. " is a protected system file.\nAre you sure you want to modify it?", colors.red) then
                gui.drawError("Update cancelled for " .. path)
                return false
            end
        end
        
        -- Delete existing file if it exists
        if fs.exists(path) then
            fs.delete(path)
        end
        
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
            gui.drawSuccess("Downloaded: " .. path)
            return true, updater.calculateHash(content)
        end
    end
    gui.drawError("Failed to download: " .. path)
    return false
end

function updater.getRemoteVersion(filepath)
    gui.drawInfo("Checking version for: " .. filepath)
    local url = updater.getGitHubRawURL(filepath)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        -- Look for version string in the file
        local version = string.match(content, "version%s*=%s*[\"']([%d%.]+)[\"']")
        if version then
            return version, updater.calculateHash(content)
        end
    end
    gui.drawError("Failed to get version for: " .. filepath)
    return nil
end

function updater.compareVersions(v1, v2)
    local function parseVersion(v)
        local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
        return tonumber(major), tonumber(minor), tonumber(patch)
    end
    
    local m1, n1, p1 = parseVersion(v1)
    local m2, n2, p2 = parseVersion(v2)
    
    if m1 > m2 then return 1
    elseif m1 < m2 then return -1
    elseif n1 > n2 then return 1
    elseif n1 < n2 then return -1
    elseif p1 > p2 then return 1
    elseif p1 < p2 then return -1
    else return 0 end
end

function updater.checkForUpdates(auto_mode)
    local updates_available = false
    local updates_installed = false
    
    if not auto_mode then
        gui.drawInfo("Checking for updates...")
    end
    
    -- Update last check time
    updater.settings.last_check = os.epoch("utc")
    
    -- Load current versions and hashes
    updater.loadVersions()
    
    for name, info in pairs(updater.modules) do
        if not auto_mode then
            gui.drawInfo(string.format("Checking %s...", name))
        end
        
        -- Get remote version and hash
        local remote_version, remote_hash = updater.getRemoteVersion(info.path)
        if remote_version then
            local version_diff = updater.compareVersions(remote_version, info.version)
            local hash_diff = (info.hash ~= remote_hash)
            
            if version_diff > 0 or (version_diff == 0 and hash_diff) then
                if not auto_mode then
                    if version_diff > 0 then
                        gui.drawSuccess(string.format("Update available for %s: %s -> %s", 
                            name, info.version, remote_version))
                    elseif hash_diff then
                        gui.drawSuccess(string.format("File changes detected for %s", name))
                    end
                end
                updates_available = true
                
                if auto_mode and updater.settings.auto_install or
                   not auto_mode and gui.confirm("Install update for " .. name .. "?") then
                    -- Download the update
                    local url = updater.getGitHubRawURL(info.path)
                    local success, new_hash = updater.downloadFile(url, info.target)
                    if success then
                        -- Update local version and hash
                        info.version = remote_version
                        info.hash = new_hash
                        updates_installed = true
                    end
                end
            elseif not auto_mode then
                gui.drawSuccess(string.format("%s is up to date", name))
            end
        end
    end
    
    -- Save updated versions and reboot if needed
    if updates_installed then
        updater.saveVersions()
        if not auto_mode then
            gui.drawSuccess("Updates installed. Rebooting in 3 seconds...")
            os.sleep(3)
            shell.run("reboot")
        end
    elseif not auto_mode then
        gui.drawSuccess("No updates available.")
    end
    
    return updates_available
end

-- Initialize
updater.loadVersions() -- Load saved versions

return updater
