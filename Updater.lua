-- SCI Sentinel OS Updater Module
local version = "1.0.2"

-- Load required modules
-- local gui = require("Gui")
-- this comment is a test for version checking
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
        version = "1.0.2",
        path = "Sci_sentinel.lua",
        target = "scios/Sci_sentinel.lua"
    },
    ["gui"] = {
        version = "1.0.1",
        path = "Gui.lua",
        target = "scios/Gui.lua"
    },
    ["commands"] = {
        version = "1.0.1",
        path = "Commands.lua",
        target = "scios/Commands.lua"
    },
    ["updater"] = {
        version = "1.0.2",
        path = "Updater.lua",
        target = "scios/Updater.lua"
    },
    ["startup"] = {
        version = "1.0.1",
        path = "Startup.lua",
        target = "startup.lua"
    }
}

-- Auto-update settings
updater.settings = {
    auto_check = true,
    check_interval = 3600,
    last_check = 0
}

function updater.init(guiInstance)
    if not guiInstance then
        error("GUI instance required")
        return nil
    end
    if type(guiInstance.drawInfo) ~= "function" then
        error("GUI instance missing required functions")
        return nil
    end
    updater.gui = guiInstance
    return updater
end

function updater.getGitHubRawURL(filepath)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s?cb=%d",
        updater.repo.owner,
        updater.repo.name,
        updater.repo.branch,
        filepath,
        os.epoch("utc"))
end

function updater.verifyFile(path, content)
    if not fs.exists(path) then
        return false, "File does not exist after download"
    end
    
    local file = fs.open(path, "r")
    if not file then
        return false, "Cannot open file for verification"
    end
    
    local fileContent = file.readAll()
    file.close()
    
    if fileContent ~= content then
        return false, "File content verification failed"
    end
    
    return true
end

function updater.backupFile(path)
    if fs.exists(path) then
        local backupPath = path .. ".backup"
        fs.delete(backupPath)
        fs.copy(path, backupPath)
        return backupPath
    end
    return nil
end

function updater.restoreBackup(path, backupPath)
    if backupPath and fs.exists(backupPath) then
        fs.delete(path)
        fs.copy(backupPath, path)
        fs.delete(backupPath)
        return true
    end
    return false
end

function updater.downloadFile(url, path)
    if not updater.gui then return false end
    
    updater.gui.drawInfo("Downloading: " .. path)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        -- Create backup of existing file
        local backupPath = updater.backupFile(path)
        
        -- Create directory if needed
        local dir = fs.getDir(path)
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        -- Save file
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
            
            -- Verify file
            local success, error = updater.verifyFile(path, content)
            if success then
                updater.gui.drawSuccess("Successfully downloaded and verified: " .. path)
                if backupPath then
                    fs.delete(backupPath)
                end
                return true
            else
                updater.gui.drawError("File verification failed: " .. (error or "unknown error"))
                if backupPath then
                    updater.gui.drawInfo("Restoring backup...")
                    if updater.restoreBackup(path, backupPath) then
                        updater.gui.drawSuccess("Backup restored")
                    else
                        updater.gui.drawError("Failed to restore backup")
                    end
                end
            end
        end
    end
    updater.gui.drawError("Failed to download: " .. path)
    return false
end

function updater.getRemoteVersion(filepath)
    local url = updater.getGitHubRawURL(filepath)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        local version = string.match(content, "version%s*=%s*[\"']([%d%.]+)[\"']")
        return version
    end
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

function updater.checkForUpdates()
    if not updater.gui then 
        error("Updater not initialized with GUI")
        return false 
    end

    local updates_available = false
    local updates_installed = false
    updater.gui.drawInfo("Checking for updates...")
    
    for name, info in pairs(updater.modules) do
        updater.gui.drawInfo("Checking " .. name .. "...")
        local remote_version = updater.getRemoteVersion(info.path)
        
        if remote_version then
            if updater.compareVersions(remote_version, info.version) > 0 then
                updater.gui.drawSuccess(string.format("Update available for %s: %s -> %s", 
                    name, info.version, remote_version))
                updates_available = true
                
                if updater.gui.confirm("Install update for " .. name .. "?") then
                    local url = updater.getGitHubRawURL(info.path)
                    if updater.downloadFile(url, info.target) then
                        info.version = remote_version
                        updates_installed = true
                        updater.gui.drawSuccess("Successfully updated " .. name)
                    end
                end
            else
                updater.gui.drawSuccess(name .. " is up to date")
            end
        else
            updater.gui.drawError("Failed to check " .. name .. " for updates")
        end
    end
    
    if updates_installed then
        if updater.gui.confirm("Updates installed. Reboot system to apply changes?") then
            os.reboot()
        end
    elseif not updates_available then
        updater.gui.drawSuccess("All modules are up to date")
    end
    
    return updates_available
end

function updater.autoUpdateCheck()
    local current_time = os.epoch("utc")
    if updater.settings.auto_check and 
       (current_time - updater.settings.last_check) >= updater.settings.check_interval then
        updater.settings.last_check = current_time
        return updater.checkForUpdates()
    end
    return false
end

return updater
