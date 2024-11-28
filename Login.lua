local login = {}

-- Default user credentials
local users = {
    ["Ickycoolboy"] = "",
    ["The Dertopian"] = ""
}

function login.showLoginScreen()
    term.clear()
    term.setCursorPos(1,1)
    
    -- Draw login box
    local w, h = term.getSize()
    local boxWidth = 30
    local boxHeight = 7
    local startX = math.floor((w - boxWidth) / 2)
    local startY = math.floor((h - boxHeight) / 2)
    
    -- Draw box
    for y = startY, startY + boxHeight do
        term.setCursorPos(startX, y)
        if y == startY or y == startY + boxHeight then
            term.write("+" .. string.rep("-", boxWidth-2) .. "+")
        else
            term.write("|" .. string.rep(" ", boxWidth-2) .. "|")
        end
    end
    
    -- Draw title
    term.setCursorPos(startX + 2, startY + 1)
    term.setTextColor(colors.yellow)
    term.write("SCI Sentinel OS Login")
    term.setTextColor(colors.white)
    
    -- Username input
    term.setCursorPos(startX + 2, startY + 3)
    term.write("Username: ")
    term.setCursorPos(startX + 11, startY + 3)
    
    local username = read()
    
    -- Validate credentials
    if users[username] ~= nil then
        if users[username] == "" then
            return true  -- Login successful
        else
            term.setCursorPos(startX + 2, startY + 4)
            term.write("Password: ")
            term.setCursorPos(startX + 11, startY + 4)
            
            local password = read("*")
            
            return password == users[username]
        end
    end
    
    return false
end

return login
