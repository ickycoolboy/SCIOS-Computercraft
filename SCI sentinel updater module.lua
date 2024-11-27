-- SCI Sentinel OS Updater Module

-- Load required modules
local gui = require("SCI Sentinel GUI")

local updater = {}

-- Module version information
updater.modules = {
    ["core"] = {
        version = "1.0.0",
        pastebin = "your_core_pastebin_code"
    },
    ["gui"] = {
        version = "1.0.0",
        pastebin = "your_gui_pastebin_code"
    },
    ["commands"] = {
        version = "1.0.0",
        pastebin = "your_commands_pastebin_code"
    }
}

function updater.downloadFromPastebin(pastebinCode, targetFile)
    local response = http.get(
        string.format("https://pastebin.com/raw/%s", pastebinCode)
    )
    
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(targetFile, "w")
        file.write(content)
        file.close()
        return true
    end
    return false
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