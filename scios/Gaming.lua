-- SCI Sentinel Gaming Module
local version = "1.0.0"

local gaming = {}

-- Performance optimization settings
gaming.settings = {
    priorityMode = false,  -- When true, system will prioritize gaming performance
    reducedAnimations = false,  -- Reduce UI animations for better performance
    memoryOptimization = false  -- Optimize memory usage for gaming
}

-- Enable gaming optimizations
function gaming.enableGamingMode()
    gaming.settings.priorityMode = true
    gaming.settings.reducedAnimations = true
    gaming.settings.memoryOptimization = true
    
    -- Adjust system settings for gaming
    os.setComputerLabel("SCIOS-Gaming")
    term.setTextScale(1) -- Set optimal text scale for gaming
    
    return true
end

-- Disable gaming optimizations
function gaming.disableGamingMode()
    gaming.settings.priorityMode = false
    gaming.settings.reducedAnimations = false
    gaming.settings.memoryOptimization = false
    
    -- Restore default system settings
    os.setComputerLabel("SCIOS")
    
    return true
end

-- Get current gaming mode status
function gaming.getStatus()
    return {
        priorityMode = gaming.settings.priorityMode,
        reducedAnimations = gaming.settings.reducedAnimations,
        memoryOptimization = gaming.settings.memoryOptimization
    }
end

-- API for game performance monitoring
function gaming.getPerformanceMetrics()
    return {
        memory = os.getComputerSpace(),
        uptime = os.clock(),
        label = os.getComputerLabel()
    }
end

return gaming
