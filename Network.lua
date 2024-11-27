-- SCI Sentinel OS Network Module
local network = {}

-- GUI module for output
local gui = require("Gui")

-- Network state
local modems = {}
local isRednetOpen = false
local protocols = {
    PING = "SCINET_PING",
    DISCOVER = "SCINET_DISCOVER",
    MESSAGE = "SCINET_MSG"
}

-- Initialize network
function network.init()
    -- Find all modems (wired and wireless)
    local peripheralList = peripheral.getNames()
    for _, name in ipairs(peripheralList) do
        if peripheral.getType(name) == "modem" then
            modems[name] = peripheral.wrap(name)
        end
    end
    
    return #modems > 0
end

-- Open rednet on all modems
function network.openRednet()
    if isRednetOpen then return true end
    
    local opened = false
    for name, modem in pairs(modems) do
        if not rednet.isOpen(name) then
            rednet.open(name)
            opened = true
        end
    end
    
    isRednetOpen = opened
    return opened
end

-- Close rednet on all modems
function network.closeRednet()
    if not isRednetOpen then return true end
    
    for name, _ in pairs(modems) do
        if rednet.isOpen(name) then
            rednet.close(name)
        end
    end
    
    isRednetOpen = false
    return true
end

-- Scan for nearby computers
function network.scan()
    if not network.openRednet() then
        return nil, "No modems available"
    end
    
    local computers = {}
    rednet.broadcast("", protocols.DISCOVER)
    
    -- Wait for responses (with timeout)
    local timeout = os.startTimer(2)
    while true do
        local event, id, message, protocol = os.pullEvent()
        if event == "timer" and id == timeout then
            break
        elseif event == "rednet_message" and protocol == protocols.DISCOVER then
            local label = os.getComputerLabel() or tostring(id)
            computers[id] = {
                id = id,
                label = label,
                distance = message.distance or "unknown"
            }
        end
    end
    
    return computers
end

-- Ping a specific computer
function network.ping(targetId)
    if not network.openRednet() then
        return nil, "No modems available"
    end
    
    local startTime = os.epoch("local")
    rednet.send(targetId, "", protocols.PING)
    
    -- Wait for response with timeout
    local timeout = os.startTimer(2)
    while true do
        local event, id, message, protocol = os.pullEvent()
        if event == "timer" and id == timeout then
            return nil, "Timeout"
        elseif event == "rednet_message" and id == targetId and protocol == protocols.PING then
            local endTime = os.epoch("local")
            return endTime - startTime
        end
    end
end

-- Send a message to a specific computer
function network.sendMessage(targetId, message)
    if not network.openRednet() then
        return false, "No modems available"
    end
    
    rednet.send(targetId, message, protocols.MESSAGE)
    return true
end

-- Listen for incoming messages
function network.listen(callback)
    if not network.openRednet() then
        return false, "No modems available"
    end
    
    while true do
        local event, senderId, message, protocol = os.pullEvent("rednet_message")
        
        if protocol == protocols.PING then
            -- Auto-respond to pings
            rednet.send(senderId, "", protocols.PING)
        elseif protocol == protocols.DISCOVER then
            -- Auto-respond to discovery
            local response = {
                id = os.getComputerID(),
                label = os.getComputerLabel(),
                distance = "unknown" -- Could be calculated with wireless modems
            }
            rednet.send(senderId, response, protocols.DISCOVER)
        elseif protocol == protocols.MESSAGE then
            -- Handle regular messages
            if callback then
                callback(senderId, message, protocol)
            end
        end
    end
end

-- Get list of connected modems
function network.getModems()
    local modemList = {}
    for name, modem in pairs(modems) do
        table.insert(modemList, {
            name = name,
            isWireless = modem.isWireless and modem.isWireless() or false,
            isOpen = rednet.isOpen(name)
        })
    end
    return modemList
end

return network
