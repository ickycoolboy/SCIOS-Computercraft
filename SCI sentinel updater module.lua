-- SCI Sentinel OS Updater Module

-- Load required modules
local gui = require("SCI Sentinel GUI")

local updater = {}

local function ensureDirectoryExists(dir)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

function updater.checkForUpdates()
    gui.drawSuccess("Checking for updates...")
    
    for moduleName, info in pairs(updater.modules) do
        gui.drawSuccess("Checking " .. moduleName .. " module...")
        
        -- Try to download and update the module
        local targetFile = string.format("SCI Sentinel %s module.lua", moduleName)
        if moduleName == "core" then
            targetFile = "SCI Sentinel Core.lua"
        end
        
        if updater.downloadFromPastebin(info.pastebin, targetFile) then
            gui.drawSuccess(moduleName .. " module updated successfully!")
        else
            gui.drawError("Failed to update " .. moduleName .. " module")
        end
    end
    
    gui.drawSuccess("Update check complete!")
end

-- Return the Updater module
return updater