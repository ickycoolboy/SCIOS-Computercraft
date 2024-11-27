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

-- Debug function
local function debug(msg)
    if _G.DEBUG then
        print("[DEBUG] " .. msg)
    end
end

-- Initialize network
function network.init()
    -- Clear existing modems
    modems = {}
    
    -- Find all modems (wired and wireless)
    local peripheralList = peripheral.getNames()
    debug("Found peripherals: " .. textutils.serialize(peripheralList))
    
    for _, name in ipairs(peripheralList) do
        local pType = peripheral.getType(name)
        debug("Checking " .. name .. " (type: " .. pType .. ")")
        
        if pType == "modem" then
            local modem = peripheral.wrap(name)
            if modem then
                modems[name] = modem
                debug("Added modem: " .. name)
                
                -- Set wireless modem range to maximum
                if modem.isWireless and modem.isWireless() then
                    modem.setStrength(128)  -- Maximum range
                    debug("Set wireless range for " .. name)
                end
                
                -- Close the modem first to ensure clean state
                if rednet.isOpen(name) then
                    rednet.close(name)
                    debug("Closed existing rednet on " .. name)
                end
            else
                debug("Failed to wrap modem: " .. name)
            end
        end
    end
    
    isRednetOpen = false
    local modemCount = 0
    for _ in pairs(modems) do modemCount = modemCount + 1 end
    debug("Found " .. modemCount .. " modems")
    
    return modemCount > 0
end

-- Open rednet on all modems
function network.openRednet()
    if not network.init() then
        print("Error: No modems found")
        return false
    end
    
    local opened = false
    for name, modem in pairs(modems) do
        debug("Attempting to open rednet on " .. name)
        if not rednet.isOpen(name) then
            local success, err = pcall(function()
                rednet.open(name)
            end)
            if success then
                opened = true
                debug("Successfully opened rednet on " .. name)
                print("Opened rednet on " .. name)
            else
                debug("Failed to open rednet on " .. name .. ": " .. tostring(err))
                print("Error opening rednet on " .. name)
            end
        else
            debug(name .. " was already open")
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
            debug("Closed rednet on " .. name)
            print("Closed rednet on " .. name)
            closed = true
        else
            debug(name .. " was already closed")
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
    debug("Getting modem list...")
    
    for name, modem in pairs(modems) do
        local isOpen = rednet.isOpen(name)
        local isWireless = modem.isWireless and modem.isWireless() or false
        
        debug(string.format("Found %s modem on %s (open: %s)", 
            isWireless and "wireless" or "wired",
            name,
            isOpen and "yes" or "no"))
            
        table.insert(modemList, {
            name = name,
            side = name,  -- The name is usually the side
            isWireless = isWireless,
            isOpen = isOpen
        })
    end
    
    return modemList
end

-- Get network status string
function network.getStatus()
    local status = {}
    table.insert(status, "=== Network Status ===")
    table.insert(status, string.format("Computer ID: %d", os.getComputerID()))
    table.insert(status, string.format("Label: %s", os.getComputerLabel() or "None"))
    table.insert(status, "")
    table.insert(status, "Connected Modems:")
    
    local modems = network.getModems()
    if #modems == 0 then
        table.insert(status, "  No modems found")
    else
        for _, modem in ipairs(modems) do
            local statusStr = modem.isOpen and "OPEN" or "CLOSED"
            local typeStr = modem.isWireless and "Wireless" or "Wired"
            table.insert(status, string.format("  %s modem on %s: %s", 
                typeStr, modem.side, statusStr))
        end
    end
    table.insert(status, "===================")
    
    return table.concat(status, "\n")
end

return network
