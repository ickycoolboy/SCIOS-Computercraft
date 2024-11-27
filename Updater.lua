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

-- Module information
updater.modules = {
    ["core"] = {
        path = "Sci_sentinel.lua",
        target = "scios/Sci_sentinel.lua",
        hash = nil  -- Will be populated during runtime
    },
    ["gui"] = {
        path = "Gui.lua",
        target = "scios/Gui.lua",
        hash = nil
    },
    ["commands"] = {
        path = "Commands.lua",
        target = "scios/Commands.lua",
        hash = nil
    },
    ["updater"] = {
        path = "Updater.lua",
        target = "scios/Updater.lua",
        hash = nil
    },
    ["startup"] = {
        path = "Startup.lua",
        target = "startup.lua",
        hash = nil
    },
    ["displaymanager"] = {
        path = "DisplayManager.lua",
        target = "scios/DisplayManager.lua",
        hash = nil
    }
}

-- Hash tracking
updater.hash_file = "scios/file_hashes.db"

function updater.calculateHash(content)
    -- Simple hash function since ComputerCraft doesn't have SHA-256
    local hash = 0
    for i = 1, #content do
        hash = (hash * 31 + string.byte(content, i)) % 2^32
    end
    return string.format("%08x", hash)
end

function updater.loadStoredHashes()
    -- Create scios directory if it doesn't exist
    if not fs.exists("scios") then
        fs.makeDir("scios")
    end
    
    local hashes = {}
    if fs.exists(updater.hash_file) then
        local file = fs.open(updater.hash_file, "r")
        if file then
            local content = file.readAll()
            file.close()
            hashes = textutils.unserializeJSON(content) or {}
        end
    end
    
    -- Calculate hashes for existing files
    for name, info in pairs(updater.modules) do
        if fs.exists(info.target) then
            local file = fs.open(info.target, "r")
            if file then
                local content = file.readAll()
                file.close()
                info.hash = updater.calculateHash(content)
            end
        end
        -- Store calculated hash
        hashes[info.target] = info.hash
    end
    
    -- Save updated hashes
    local file = fs.open(updater.hash_file, "w")
    if file then
        file.write(textutils.serializeJSON(hashes))
        file.close()
    end
end

function updater.saveHashes()
    local hashes = {}
    for name, info in pairs(updater.modules) do
        if info.hash then
            hashes[info.target] = info.hash
        end
    end
    
    local file = fs.open(updater.hash_file, "w")
    if file then
        file.write(textutils.serializeJSON(hashes))
        file.close()
    end
end

function updater.getGitHubRawURL(filepath)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s?cb=%d",
        updater.repo.owner,
        updater.repo.name,
        updater.repo.branch,
        filepath,
        os.epoch("utc"))
end

function updater.downloadFile(path, target)
    local url = updater.getGitHubRawURL(path)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(target, "w")
        if file then
            file.write(content)
            file.close()
            return true, content
        end
    end
    return false
end

function updater.getRemoteContent(filepath)
    local url = updater.getGitHubRawURL(filepath)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        return content
    end
    return nil
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

function updater.checkForUpdates()
    if not updater.gui then 
        error("Updater not initialized with GUI")
        return false 
    end

    -- Load current file hashes
    updater.loadStoredHashes()

    local updates_available = false
    local updates_installed = false
    updater.gui.drawInfo("Checking for updates...")
    
    -- First check all files for changes or missing files
    local to_update = {}
    for name, info in pairs(updater.modules) do
        updater.gui.drawInfo("Checking " .. name .. "...")
        local remote_content = updater.getRemoteContent(info.path)
        
        if remote_content then
            local needs_update = false
            local reason = ""
            
            -- Check if file exists
            if not fs.exists(info.target) then
                needs_update = true
                reason = "File is missing"
            else
                -- Check hash if file exists
                local remote_hash = updater.calculateHash(remote_content)
                if remote_hash ~= info.hash then
                    needs_update = true
                    reason = "File content differs"
                end
            end
            
            if needs_update then
                updater.gui.drawSuccess(string.format("Update needed for %s (%s)", name, reason))
                updates_available = true
                table.insert(to_update, {
                    name = name, 
                    info = info, 
                    content = remote_content,
                    new_hash = updater.calculateHash(remote_content)
                })
            else
                updater.gui.drawSuccess(name .. " is up to date")
            end
        else
            updater.gui.drawError("Failed to check " .. name)
        end
    end
    
    -- If updates are available, ask to install all at once
    if #to_update > 0 and updater.gui.confirm("Install all available updates?") then
        for _, update in ipairs(to_update) do
            -- Create backup of existing file if it exists
            local backupPath = nil
            if fs.exists(update.info.target) then
                backupPath = updater.backupFile(update.info.target)
            end
            
            -- Create directory if it doesn't exist
            local dir = fs.getDir(update.info.target)
            if not fs.exists(dir) then
                fs.makeDir(dir)
            end
            
            -- Save new content
            local file = fs.open(update.info.target, "w")
            if file then
                file.write(update.content)
                file.close()
                
                -- Verify the write was successful
                local success, error = updater.verifyFile(update.info.target, update.content)
                if success then
                    update.info.hash = update.new_hash
                    updates_installed = true
                    updater.gui.drawSuccess("Successfully updated " .. update.name)
                    if backupPath then
                        fs.delete(backupPath)
                    end
                else
                    updater.gui.drawError("Failed to verify " .. update.name .. ": " .. (error or "unknown error"))
                    if backupPath then
                        updater.restoreBackup(update.info.target, backupPath)
                    end
                end
            end
        end
        
        -- Save new hashes after successful updates
        if updates_installed then
            updater.saveHashes()
        end
    end
    
    if updates_installed then
        if updater.gui.confirm("Updates installed. Reboot system to apply changes?") then
            os.reboot()
        end
    elseif not updates_available then
        updater.gui.drawSuccess("All files are up to date")
    end
    
    return updates_available
end

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
    
    -- Initialize hashes on startup
    updater.loadStoredHashes()
    
    return updater
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

-- Auto-update settings
updater.settings = {
    auto_check = true,
    check_interval = 3600,
    last_check = 0
}

return updater
