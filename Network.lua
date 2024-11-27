-- SCI Sentinel OS Network Module
local network = {}

-- GUI module for output
local gui = require("Gui")

-- Network state
local modem = nil
local isOpen = false

-- Debug function
local function debug(msg)
    if _G.DEBUG then
        gui.drawInfo("[DEBUG] " .. msg)
    end
end

-- Initialize network
function network.init()
    -- Try to find a wireless modem
    local side = peripheral.find("modem")
    if side then
        modem = side
        debug("Found modem")
        return true
    else
        debug("No modem found")
        return false
    end
end

-- Open rednet on modem
function network.openRednet()
    if not modem then
        if not network.init() then
            return false
        end
    end

    debug("Opening rednet...")
    rednet.open(peripheral.getName(modem))
    isOpen = true
    debug("Rednet opened successfully")
    return true
end

-- Close rednet on modem
function network.closeRednet()
    if modem then
        debug("Closing rednet...")
        rednet.close(peripheral.getName(modem))
        isOpen = false
        debug("Rednet closed")
        return true
    end
    return false
end

-- Get network status string
function network.getStatus()
    local status = {}
    
    -- Check modem
    if modem then
        table.insert(status, "Modem: Connected")
        table.insert(status, "Side: " .. peripheral.getName(modem))
    else
        table.insert(status, "Modem: Not Found")
    end
    
    -- Check rednet state
    table.insert(status, "Rednet: " .. (isOpen and "Open" or "Closed"))
    
    return table.concat(status, "\n")
end

-- Scan for nearby computers
function network.scan()
    if not isOpen then
        if not network.openRednet() then
            return nil, "No modems available"
        end
    end
    
    local computers = {}
    rednet.broadcast("DISCOVER", "SCI_SENTINEL")
    
    local timeout = os.startTimer(2)
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "timer" and p1 == timeout then
            break
        elseif event == "rednet_message" then
            local senderId, message, protocol = p1, p2, p3
            if protocol == "SCI_SENTINEL" and message == "DISCOVER_RESPONSE" then
                computers[senderId] = {
                    id = senderId,
                    label = os.getComputerLabel(),
                    distance = "Unknown"
                }
            end
        end
    end
    
    return computers
end

return network
