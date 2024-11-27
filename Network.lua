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
        if _G.DEBUG then gui.drawInfo("[DEBUG] Found modem") end
        
        -- Start message handler in parallel
        parallel.waitForAny(function()
            network.startMessageHandler()
        end)
        
        return true
    else
        if _G.DEBUG then gui.drawInfo("[DEBUG] No modem found") end
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
    if _G.DEBUG then gui.drawInfo("[DEBUG] Broadcasting discovery message...") end
    
    -- Set up discovery protocol
    local PROTOCOL = "SCI_SENTINEL"
    local DISCOVER_MSG = {
        type = "DISCOVER",
        id = os.getComputerID(),
        label = os.getComputerLabel() or "Unknown"
    }
    
    -- Broadcast discovery
    rednet.broadcast(textutils.serialize(DISCOVER_MSG), PROTOCOL)
    if _G.DEBUG then gui.drawInfo("[DEBUG] Discovery broadcast sent") end
    
    -- Listen for responses
    local timeout = os.startTimer(5) -- Increased timeout to 5 seconds
    
    while true do
        if _G.DEBUG then gui.drawInfo("[DEBUG] Waiting for discovery responses...") end
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" and p1 == timeout then
            if _G.DEBUG then gui.drawInfo("[DEBUG] Scan timeout reached") end
            break
            
        elseif event == "rednet_message" then
            local senderId, message, protocol = p1, p2, p3
            if _G.DEBUG then 
                gui.drawInfo(string.format("[DEBUG] Received message from %d: %s (%s)", 
                    senderId, tostring(message), tostring(protocol)))
            end
            
            if protocol == PROTOCOL then
                -- Try to deserialize the message
                local success, data = pcall(textutils.unserialize, message)
                if success and type(data) == "table" then
                    if _G.DEBUG then gui.drawInfo("[DEBUG] Parsed message: " .. textutils.serialize(data)) end
                    
                    if data.type == "DISCOVER" then
                        -- Send response back
                        local response = {
                            type = "DISCOVER_RESPONSE",
                            id = os.getComputerID(),
                            label = os.getComputerLabel() or "Unknown"
                        }
                        if _G.DEBUG then gui.drawInfo("[DEBUG] Sending response to " .. senderId) end
                        rednet.send(senderId, textutils.serialize(response), PROTOCOL)
                        
                    elseif data.type == "DISCOVER_RESPONSE" then
                        -- Add computer to list
                        computers[senderId] = {
                            id = senderId,
                            label = data.label or ("Computer " .. senderId),
                            distance = "Unknown"
                        }
                        if _G.DEBUG then gui.drawInfo("[DEBUG] Added computer " .. senderId .. " to list") end
                    end
                else
                    if _G.DEBUG then gui.drawInfo("[DEBUG] Failed to parse message: " .. tostring(message)) end
                end
            end
        end
    end
    
    if _G.DEBUG then 
        gui.drawInfo("[DEBUG] Scan complete. Found " .. tostring(next(computers) and #computers or 0) .. " computers")
    end
    
    return computers
end

-- Add message handler for discovery requests
function network.handleMessages()
    if not isOpen then
        if not network.openRednet() then
            return false
        end
    end
    
    local PROTOCOL = "SCI_SENTINEL"
    
    while true do
        local event, senderId, message, protocol = os.pullEvent("rednet_message")
        if protocol == PROTOCOL then
            -- Try to deserialize the message
            local success, data = pcall(textutils.unserialize, message)
            if success and type(data) == "table" then
                if data.type == "DISCOVER" then
                    -- Respond to discovery
                    local response = {
                        type = "DISCOVER_RESPONSE",
                        id = os.getComputerID(),
                        label = os.getComputerLabel() or "Unknown"
                    }
                    if _G.DEBUG then gui.drawInfo("[DEBUG] Responding to discovery from " .. senderId) end
                    rednet.send(senderId, textutils.serialize(response), PROTOCOL)
                end
            end
        end
    end
end

-- Start message handler in parallel
function network.startMessageHandler()
    if _G.DEBUG then gui.drawInfo("[DEBUG] Starting message handler") end
    parallel.waitForAny(network.handleMessages)
end

return network
