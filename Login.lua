local login = {}
local displayManager = require("DisplayManager")

-- Default user credentials
local users = {
    ["Ickycoolboy"] = ""  -- Empty string means no password required
}

function login.showLoginScreen()
    local dualTerm = displayManager.getDualTerm() or term.current()
    dualTerm.clear()
    dualTerm.setCursorPos(1,1)
    
    -- Draw login box
    local w, h = dualTerm.getSize()
    local boxWidth = 30
    local boxHeight = 7
    local startX = math.floor((w - boxWidth) / 2)
    local startY = math.floor((h - boxHeight) / 2)
    
    -- Draw box
    for y = startY, startY + boxHeight do
        dualTerm.setCursorPos(startX, y)
        if y == startY or y == startY + boxHeight then
            displayManager.write("+" .. string.rep("-", boxWidth-2) .. "+")
        else
            displayManager.write("|" .. string.rep(" ", boxWidth-2) .. "|")
        end
    end
    
    -- Draw title
    dualTerm.setCursorPos(startX + 2, startY + 1)
    dualTerm.setTextColor(colors.yellow)
    displayManager.write("SCI Sentinel OS Login")
    dualTerm.setTextColor(colors.white)
    
    -- Username input
    dualTerm.setCursorPos(startX + 2, startY + 3)
    displayManager.write("Username: ")
    dualTerm.setCursorPos(startX + 11, startY + 3)
    
    -- Temporarily disable mirroring for input
    local mirroringWasEnabled = displayManager.isMirroringEnabled()
    if mirroringWasEnabled then
        displayManager.disableMirroring()
    end
    
    local username = read()
    
    -- Re-enable mirroring if it was enabled
    if mirroringWasEnabled then
        displayManager.enableMirroring()
    end
    
    -- Validate credentials
    if users[username] ~= nil then
        if users[username] == "" then
            return true  -- Login successful
        else
            dualTerm.setCursorPos(startX + 2, startY + 4)
            displayManager.write("Password: ")
            dualTerm.setCursorPos(startX + 11, startY + 4)
            
            -- Temporarily disable mirroring for password input
            if mirroringWasEnabled then
                displayManager.disableMirroring()
            end
            
            local password = read("*")
            
            -- Re-enable mirroring if it was enabled
            if mirroringWasEnabled then
                displayManager.enableMirroring()
            end
            
            return password == users[username]
        end
    end
    
    return false
end

return login
