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
    -- Clear existing modems
    modems = {}
    
    -- Find all modems (wired and wireless)
    local peripheralList = peripheral.getNames()
    for _, name in ipairs(peripheralList) do
        if peripheral.getType(name) == "modem" then
            local modem = peripheral.wrap(name)
            if modem then
                modems[name] = modem
                -- Set wireless modem range to maximum
                if modem.isWireless and modem.isWireless() then
                    modem.setStrength(128)  -- Maximum range
                end
                -- Close the modem first to ensure clean state
                if rednet.isOpen(name) then
                    rednet.close(name)
                end
            end
        end
    end
    
    isRednetOpen = false
    return #modems > 0
end

-- Open rednet on all modems
function network.openRednet()
    network.init()  -- Reinitialize to ensure clean state
    
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
    local closed = false
    for name, _ in pairs(modems) do
        if rednet.isOpen(name) then
            rednet.close(name)
            closed = true
        end
    end
    
    isRednetOpen = false
    return closed
end

-- Scan for nearby computers
function network.scan()
    if not network.openRednet() then
        return nil, "No modems available"
    end
    
    local computers = {}
    
    -- Broadcast discovery request
    rednet.broadcast({
        id = os.getComputerID(),
        label = os.getComputerLabel() or "Unknown"
    }, protocols.DISCOVER)
    
    -- Wait for responses (with timeout)
    local timeout = os.startTimer(2)
    while true do
        local event, id, message, protocol = os.pullEvent()
        if event == "timer" and id == timeout then
            break
        elseif event == "rednet_message" and protocol == protocols.DISCOVER then
            if type(message) == "table" then
                computers[id] = {
                    id = id,
                    label = message.label or ("Computer " .. id),
                    distance = message.distance or "unknown"
                }
            end
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
            rednet.send(senderId, {
                id = os.getComputerID(),
                label = os.getComputerLabel() or "Unknown",
                distance = "unknown"  -- Could be calculated with wireless modems
            }, protocols.DISCOVER)
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
            side = name,  -- The name is usually the side
            isWireless = modem.isWireless and modem.isWireless() or false,
            isOpen = rednet.isOpen(name)
        })
    end
    return modemList
end

return network
