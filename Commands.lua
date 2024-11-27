-- SCI Sentinel OS Commands Module
local version = "1.0.1"

-- Load required modules
local gui = require("Gui")
local updater = require("Updater")
local help = require("Help")
local network = require("Network")

local commands = {}
local sentinel_state = {}

function commands.saveState()
    -- Save current terminal state
    sentinel_state.term_redirect = term.current()
    sentinel_state.background = gui.getBackground()
    sentinel_state.cursor_x, sentinel_state.cursor_y = term.getCursorPos()
    sentinel_state.text_color = term.getTextColor()
    sentinel_state.background_color = term.getBackgroundColor()
end

function commands.restoreState()
    -- Restore terminal state
    term.redirect(sentinel_state.term_redirect)
    term.setCursorPos(sentinel_state.cursor_x, sentinel_state.cursor_y)
    term.setTextColor(sentinel_state.text_color)
    term.setBackgroundColor(sentinel_state.background_color)
    gui.setBackground(sentinel_state.background)
    gui.drawScreen()
end

-- MS-DOS style command implementations
local function dir(args)
    local path = args[1] or "."
    -- Combine the current directory with the requested path
    local fullPath = fs.combine(shell.dir(), path)
    
    if not fs.exists(fullPath) then
        gui.drawError("Path not found - " .. path)
        return false
    end
    
    local files = fs.list(fullPath)
    local totalFiles = 0
    local totalDirs = 0
    local totalSize = 0
    
    -- Header
    gui.drawInfo(" Directory of " .. fullPath)
    gui.drawInfo("")
    
    -- List files and directories
    for _, file in ipairs(files) do
        local filePath = fs.combine(fullPath, file)
        if fs.isDir(filePath) then
            gui.drawInfo(string.format("%-20s <DIR>", file))
            totalDirs = totalDirs + 1
        else
            local size = fs.getSize(filePath)
            gui.drawInfo(string.format("%-20s %8d bytes", file, size))
            totalFiles = totalFiles + 1
            totalSize = totalSize + size
        end
    end
    
    -- Footer
    gui.drawInfo(string.format("\n     %d File(s)    %d bytes", totalFiles, totalSize))
    gui.drawInfo(string.format("     %d Dir(s)", totalDirs))
    return true
end

local function cd(args)
    local path = args[1] or ""
    local current = shell.dir()
    
    if path == ".." then
        if current ~= "" then
            shell.setDir(fs.getDir(current))
        end
    elseif path == "\\" or path == "/" then
        shell.setDir("")
    else
        -- Combine current directory with requested path
        local newPath = fs.combine(current, path)
        if fs.exists(newPath) and fs.isDir(newPath) then
            shell.setDir(newPath)
        else
            gui.drawError("The system cannot find the path specified.")
            return false
        end
    end
    return true
end

local function cls()
    term.clear()
    term.setCursorPos(1,1)
    gui.drawScreen()
    return true
end

local function type(args)
    if not args[1] then
        gui.drawError("Required parameter missing")
        return false
    end
    
    local file = args[1]
    if not fs.exists(file) then
        gui.drawError("The system cannot find the file specified.")
        return false
    end
    
    if fs.isDir(file) then
        gui.drawError("Access is denied.")
        return false
    end
    
    local f = fs.open(file, "r")
    if f then
        local content = f.readAll()
        f.close()
        print(content)
        return true
    end
    return false
end

local function copy(args)
    if #args < 2 then
        gui.drawError("The syntax of the command is incorrect.")
        return false
    end
    
    local source = args[1]
    local dest = args[2]
    
    if not fs.exists(source) then
        gui.drawError("The system cannot find the file specified.")
        return false
    end
    
    if fs.isDir(source) then
        gui.drawError("The source is a directory.")
        return false
    end
    
    local success = pcall(function()
        local f = fs.open(source, "r")
        local content = f.readAll()
        f.close()
        
        f = fs.open(dest, "w")
        f.write(content)
        f.close()
    end)
    
    if success then
        gui.drawSuccess(string.format("        1 file(s) copied."))
        return true
    else
        gui.drawError("The system cannot copy the file.")
        return false
    end
end

local function del(args)
    if #args < 1 then
        gui.drawError("The syntax of the command is incorrect.")
        return false
    end
    
    local path = args[1]
    if not fs.exists(path) then
        gui.drawError("The system cannot find the file specified.")
        return false
    end
    
    if fs.isDir(path) then
        gui.drawError("The system cannot delete a directory.")
        return false
    end
    
    fs.delete(path)
    return true
end

local function md(args)
    if #args < 1 then
        gui.drawError("The syntax of the command is incorrect.")
        return false
    end
    
    local path = args[1]
    if fs.exists(path) then
        gui.drawError("A subdirectory or file already exists.")
        return false
    end
    
    fs.makeDir(path)
    return true
end

local function rd(args)
    if #args < 1 then
        gui.drawError("The syntax of the command is incorrect.")
        return false
    end
    
    local path = args[1]
    if not fs.exists(path) then
        gui.drawError("The system cannot find the path specified.")
        return false
    end
    
    if not fs.isDir(path) then
        gui.drawError("The directory name is invalid.")
        return false
    end
    
    local files = fs.list(path)
    if #files > 0 then
        gui.drawError("The directory is not empty.")
        return false
    end
    
    fs.delete(path)
    return true
end

local function ver()
    gui.drawInfo("SCI Sentinel [Version 1.0.0]")
    return true
end

-- Network commands
local function net(args)
    if #args == 0 then
        gui.drawError("Usage: NET <command>")
        gui.drawInfo("Available commands:")
        gui.drawInfo("  NET STATUS    - Show network status")
        gui.drawInfo("  NET SCAN      - Scan for nearby computers")
        gui.drawInfo("  NET OPEN      - Open all modems")
        gui.drawInfo("  NET CLOSE     - Close all modems")
        gui.drawInfo("  NET DEBUG     - Toggle debug mode")
        return false
    end
    
    local cmd = args[1]:lower()
    table.remove(args, 1)
    
    if cmd == "debug" then
        _G.DEBUG = not _G.DEBUG
        if _G.DEBUG then
            gui.drawSuccess("Network debugging enabled")
        else
            gui.drawSuccess("Network debugging disabled")
        end
        return true
        
    elseif cmd == "status" then
        -- Initialize network if needed
        network.init()
        
        -- Show network status
        gui.drawInfo(network.getStatus())
        return true
        
    elseif cmd == "scan" then
        gui.drawInfo("Scanning for nearby computers...")
        local computers, err = network.scan()
        if not computers then
            gui.drawError("Scan failed: " .. (err or "Unknown error"))
            return false
        end
        
        if next(computers) == nil then
            gui.drawInfo("No computers found")
            return true
        end
        
        gui.drawInfo("Found computers:")
        for id, info in pairs(computers) do
            gui.drawInfo(string.format("  ID: %d, Label: %s, Distance: %s", 
                info.id, info.label or ("Computer " .. id), info.distance))
        end
        return true
        
    elseif cmd == "open" then
        if network.openRednet() then
            gui.drawSuccess("Network opened successfully")
            return true
        else
            gui.drawError("Failed to open network - No modems available")
            return false
        end
        
    elseif cmd == "close" then
        if network.closeRednet() then
            gui.drawSuccess("Network closed successfully")
            return true
        else
            gui.drawInfo("No modems were open")
            return true
        end
        
    else
        gui.drawError("Unknown network command: " .. cmd)
        return false
    end
end

local function ping(args)
    if #args < 1 then
        gui.drawError("Usage: PING <computer-id>")
        return false
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        gui.drawError("Invalid computer ID")
        return false
    end
    
    gui.drawInfo("Pinging computer " .. targetId .. "...")
    local time, err = network.ping(targetId)
    if not time then
        gui.drawError("Ping failed: " .. (err or "Unknown error"))
        return false
    end
    
    gui.drawSuccess(string.format("Response from %d: time=%dms", targetId, time))
    return true
end

local function msg(args)
    if #args < 2 then
        gui.drawError("Usage: MSG <computer-id> <message>")
        return false
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        gui.drawError("Invalid computer ID")
        return false
    end
    
    -- Combine remaining args into message
    table.remove(args, 1)
    local message = table.concat(args, " ")
    
    local success, err = network.sendMessage(targetId, message)
    if not success then
        gui.drawError("Failed to send message: " .. (err or "Unknown error"))
        return false
    end
    
    gui.drawSuccess("Message sent to computer " .. targetId)
    return true
end

-- Pagination helper function
local function displayPaginatedText(lines, title)
    local w, h = term.getSize()
    local linesPerPage = h - 4  -- Leave room for header and footer
    local totalPages = math.ceil(#lines / linesPerPage)
    local currentPage = 1
    
    while true do
        term.clear()
        term.setCursorPos(1,1)
        
        -- Display title
        if title then
            gui.drawInfo(title)
            gui.drawInfo(string.rep("-", w))
        end
        
        -- Calculate page bounds
        local startLine = (currentPage - 1) * linesPerPage + 1
        local endLine = math.min(startLine + linesPerPage - 1, #lines)
        
        -- Display current page content
        for i = startLine, endLine do
            gui.drawInfo(lines[i])
        end
        
        -- Display footer with page info and navigation help
        local footer = string.format(
            "Page %d of %d - Press: N(ext) P(rev) Q(uit)",
            currentPage, totalPages
        )
        term.setCursorPos(1, h-1)
        gui.drawInfo(string.rep("-", w))
        gui.drawInfo(footer)
        
        -- Handle input
        local event, key = os.pullEvent("key")
        if key == keys.n and currentPage < totalPages then
            currentPage = currentPage + 1
        elseif key == keys.p and currentPage > 1 then
            currentPage = currentPage - 1
        elseif key == keys.q then
            break
        end
    end
    
    -- Clear screen after exiting
    term.clear()
    term.setCursorPos(1,1)
end

local function displayHelp(args)
    if #args == 0 then
        -- Display list of all commands
        local lines = {
            "SCI Sentinel OS Help System",
            "The following commands are available:",
            ""
        }
        
        local cmdList = help.listCommands()
        for _, cmd in ipairs(cmdList) do
            table.insert(lines, string.format("%-12s - %s", cmd.name, cmd.desc))
        end
        
        table.insert(lines, "")
        table.insert(lines, "For more information on a specific command, type HELP command-name")
        
        displayPaginatedText(lines, "SCI Sentinel Help")
    else
        -- Display help for specific command
        local cmdHelp = help.getCommandHelp(args[1])
        if cmdHelp then
            local lines = {
                "Help for " .. args[1]:upper(),
                "",
                "Syntax:",
                "  " .. cmdHelp.syntax,
                "",
                cmdHelp.description,
                ""
            }
            
            -- Add all detail lines
            for _, line in ipairs(cmdHelp.details) do
                table.insert(lines, line)
            end
            
            displayPaginatedText(lines, "Command Help: " .. args[1]:upper())
        else
            gui.drawError("No help available for '" .. args[1] .. "'")
            return false
        end
    end
    return true
end

-- System information commands
local function mem()
    -- Get available memory from fs.getFreeSpace
    local freeSpace = fs.getFreeSpace("/")
    if not freeSpace then
        gui.drawError("Could not get storage information")
        return false
    end
    
    local totalSpace = math.pow(2, 20)  -- ComputerCraft typically has 1MB space
    local usedSpace = totalSpace - freeSpace
    
    gui.drawInfo("Storage Information:")
    gui.drawInfo(string.format("Total Space: %.2f KB", totalSpace/1024))
    gui.drawInfo(string.format("Used Space: %.2f KB", usedSpace/1024))
    gui.drawInfo(string.format("Free Space: %.2f KB", freeSpace/1024))
    
    return true
end

local function label(args)
    if #args == 0 then
        -- Display current label
        local currentLabel = os.getComputerLabel()
        if currentLabel then
            gui.drawInfo("Current computer label: " .. currentLabel)
        else
            gui.drawInfo("Computer has no label")
        end
        gui.drawInfo("")
        gui.drawInfo("To set a new label, use: LABEL <new-name>")
        gui.drawInfo("To remove the label, use: LABEL clear")
    elseif args[1]:lower() == "clear" then
        -- Clear the label
        os.setComputerLabel(nil)
        gui.drawSuccess("Computer label cleared")
    else
        -- Set new label
        local newLabel = args[1]
        os.setComputerLabel(newLabel)
        gui.drawSuccess("Computer label set to: " .. newLabel)
    end
    return true
end

local function ps()
    local running = parallel.getRunningTasks and parallel.getRunningTasks() or {}
    
    if #running == 0 then
        gui.drawInfo("No active parallel tasks found")
        
        -- Show basic computer info instead
        gui.drawInfo("")
        gui.drawInfo("Computer Information:")
        gui.drawInfo(string.format("Computer ID: %d", os.getComputerID()))
        gui.drawInfo(string.format("Computer Label: %s", os.getComputerLabel() or "None"))
        gui.drawInfo(string.format("Time: %d", os.time()))
        gui.drawInfo(string.format("Day: %d", os.day()))
    else
        gui.drawInfo("Running Parallel Tasks:")
        for i, task in ipairs(running) do
            gui.drawInfo(string.format("Task %d: %s", i, tostring(task)))
        end
    end
    
    return true
end

local function find(args)
    if #args < 1 then
        gui.drawError("Usage: find <pattern>")
        return false
    end
    
    local pattern = args[1]
    local results = {}
    
    local function searchDir(path)
        local files = fs.list(path)
        for _, file in ipairs(files) do
            local fullPath = fs.combine(path, file)
            if file:match(pattern) then
                table.insert(results, fullPath)
            end
            if fs.isDir(fullPath) then
                searchDir(fullPath)
            end
        end
    end
    
    searchDir(shell.dir())
    
    if #results > 0 then
        gui.drawInfo(string.format("Found %d matches:", #results))
        for _, path in ipairs(results) do
            gui.drawInfo(path)
        end
    else
        gui.drawInfo("No matches found.")
    end
    return true
end

local function tail(args)
    if #args < 1 then
        gui.drawError("Usage: tail <file> [lines]")
        return false
    end
    
    local filename = args[1]
    local lines = tonumber(args[2]) or 10
    local fullPath = fs.combine(shell.dir(), filename)
    
    if not fs.exists(fullPath) then
        gui.drawError("File not found: " .. filename)
        return false
    end
    
    local file = fs.open(fullPath, "r")
    if not file then
        gui.drawError("Cannot open file: " .. filename)
        return false
    end
    
    local content = {}
    local line = file.readLine()
    while line do
        table.insert(content, line)
        if #content > lines then
            table.remove(content, 1)
        end
        line = file.readLine()
    end
    file.close()
    
    gui.drawInfo(string.format("Last %d lines of %s:", lines, filename))
    for _, line in ipairs(content) do
        gui.drawInfo(line)
    end
    return true
end

local function history()
    if #commandHistory == 0 then
        gui.drawInfo("No commands in history")
        return true
    end
    
    gui.drawInfo("Command History (most recent first):")
    gui.drawInfo("")
    for i, cmd in ipairs(commandHistory) do
        gui.drawInfo(string.format("%2d: %s", i, cmd))
    end
    return true
end

-- Command history tracking
local commandHistory = {}
local MAX_HISTORY = 50  -- Maximum number of commands to remember

local function addToHistory(command)
    -- Don't add empty commands or duplicates of the last command
    if command == "" or (commandHistory[1] and commandHistory[1] == command) then
        return
    end
    
    -- Add new command at the start
    table.insert(commandHistory, 1, command)
    
    -- Remove oldest command if we exceed MAX_HISTORY
    if #commandHistory > MAX_HISTORY then
        table.remove(commandHistory)
    end
    
    -- Save history to file
    local file = fs.open("scios/.history", "w")
    if file then
        for i = #commandHistory, 1, -1 do
            file.writeLine(commandHistory[i])
        end
        file.close()
    end
end

local function loadHistory()
    if fs.exists("scios/.history") then
        local file = fs.open("scios/.history", "r")
        if file then
            local lines = {}
            local line = file.readLine()
            while line do
                table.insert(lines, line)
                line = file.readLine()
            end
            file.close()
            
            -- Reverse the order so newest commands are first
            for i = #lines, 1, -1 do
                table.insert(commandHistory, lines[i])
            end
            
            -- Trim to MAX_HISTORY if needed
            while #commandHistory > MAX_HISTORY do
                table.remove(commandHistory)
            end
        end
    end
end

-- Initialize command history
loadHistory()

-- Display management commands
commands["mirror"] = {
    action = function(args)
        local displayManager = require("DisplayManager")
        local enabled = displayManager.toggleMirroring()
        if enabled then
            gui.drawSuccess("Display mirroring enabled")
        else
            gui.drawSuccess("Display mirroring disabled")
        end
    end,
    help = "Toggle display mirroring for secondary monitors"
}

-- Command handler
function commands.handleCommand(input)
    if input == "" then return true end
    
    -- Split input into command and args
    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local cmd = parts[1]:lower()
    table.remove(parts, 1)  -- Remove command, leaving only args
    
    -- Add command to history before executing
    addToHistory(input)
    
    -- MS-DOS style command mapping
    local commandHandlers = {
        dir = dir,
        cd = cd,
        cls = cls,
        type = type,
        copy = copy,
        del = del,
        md = md,
        rd = rd,
        ver = ver,
        help = displayHelp,
        ["?"] = displayHelp,
        mem = mem,
        ps = ps,
        find = find,
        tail = tail,
        history = history,
        label = label,
        net = net,
        ping = ping,
        msg = msg,
        network = net,
        update = function(args)
            -- Initialize updater with GUI
            updater = updater.init(gui)
            if not updater then
                gui.drawError("Failed to initialize updater")
                return true
            end
            
            local updates = updater.checkForUpdates()
            if updates == false then
                gui.drawSuccess("No updates available")
            end
            return true
        end,
        reinstall = function(args)
            gui.drawError("WARNING: This will reinstall all SCI Sentinel files.")
            gui.drawError("Type 'confirm' to proceed or anything else to cancel.")
            gui.printPrompt()
            local response = read()
            if response == "confirm" then
                gui.drawSuccess("Starting reinstallation...")
                shell.run("wget", "run", "https://raw.githubusercontent.com/ickycoolboy/SCIOS-Computercraft/Github-updating-test/Installer.lua")
            else
                gui.drawSuccess("Reinstallation cancelled.")
            end
            return true
        end,
        uninstall = function(args)
            -- Save current terminal state
            local oldTerm = term.current()
            local oldBg = term.getBackgroundColor()
            local oldFg = term.getTextColor()

            -- Ensure we're using the native terminal
            term.redirect(term.native())
            
            -- Clear any previous state
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1,1)

            -- Check for debug mode
            local debugMode = false
            if args[1] == "-debug" then
                debugMode = true
                print("Running in DEBUG mode - No files will be modified")
                os.sleep(1)
            end
            
            -- Get screen dimensions
            local w, h = term.getSize()
            local isPocketPC = h <= 13
            local minWidth = isPocketPC and 26 or 51
            local minHeight = isPocketPC and 8 or 16

            -- Clear screen and draw main interface
            term.clear()
            term.setCursorPos(1,1)
            
            -- Draw main box with appropriate size
            if isPocketPC then
                gui.drawBox(1, 1, minWidth, minHeight, "[ Uninstaller ]")
                
                -- Draw compact warning
                gui.drawCenteredText(2, "WARNING!", colors.red)
                gui.drawCenteredText(3, "Remove SCIOS?", colors.orange)
                if debugMode then
                    gui.drawCenteredText(4, "(Debug Mode)", colors.lime)
                end
                
                -- Draw buttons
                local buttons = {
                    gui.drawButton(3, 6, "Yes", colors.red),
                    gui.drawButton(minWidth-6, 6, "No", colors.lime)
                }
                
                -- Handle button click
                local choice = gui.handleButtons(buttons)
                if choice ~= "Yes" then
                    term.clear()
                    term.setCursorPos(1,1)
                    gui.drawSuccess("Cancelled")
                    -- Before returning, restore terminal state
                    term.redirect(oldTerm)
                    term.setBackgroundColor(oldBg)
                    term.setTextColor(oldFg)
                    term.clear()
                    term.setCursorPos(1,1)
                    return true
                end
            else
                gui.drawBox(1, 1, minWidth, minHeight, "[ SCI Sentinel Uninstaller ]")
                
                -- Draw warning
                gui.drawCenteredText(4, "WARNING!", colors.red)
                gui.drawCenteredText(6, "This will completely remove", colors.orange)
                gui.drawCenteredText(7, "SCI Sentinel from your computer.", colors.orange)
                if debugMode then
                    gui.drawCenteredText(8, "(Debug Mode - No files will be modified)", colors.lime)
                end
                gui.drawCenteredText(9, "Are you sure you want to proceed?", colors.white)
                
                -- Draw buttons
                local buttons = {
                    gui.drawButton(15, 12, "Uninstall", colors.red),
                    gui.drawButton(30, 12, "Cancel", colors.lime)
                }
                
                -- Handle button click
                local choice = gui.handleButtons(buttons)
                if choice ~= "Uninstall" then
                    term.clear()
                    term.setCursorPos(1,1)
                    gui.drawSuccess("Uninstall cancelled")
                    -- Before returning, restore terminal state
                    term.redirect(oldTerm)
                    term.setBackgroundColor(oldBg)
                    term.setTextColor(oldFg)
                    term.clear()
                    term.setCursorPos(1,1)
                    return true
                end
            end
            
            -- Draw uninstall progress interface
            term.clear()
            term.setCursorPos(1,1)
            
            if isPocketPC then
                gui.drawBox(1, 1, minWidth, minHeight, "[ Uninstalling ]")
            else
                gui.drawBox(1, 1, minWidth, minHeight, "[ Uninstalling SCI Sentinel ]")
            end
            
            -- Initialize progress tracking
            local currentProgress = 0
            local function updateProgress(status, progress)
                currentProgress = progress
                gui.updateProgress(3, 4, 45, "Uninstalling", progress, status)
            end
            
            -- Function to simulate or perform actual file operations
            local function performOperation(operation, debugMode)
                if debugMode then
                    os.sleep(0.5) -- Simulate operation time
                    return true
                else
                    return operation()
                end
            end
            
            -- First, disable startup.lua
            updateProgress("Disabling startup file...", 0.1)
            if fs.exists("startup.lua") or debugMode then
                local success = performOperation(function()
                    local file = fs.open("startup.lua", "w")
                    if file then
                        file.write("-- SCI Sentinel has been uninstalled.\n")
                        file.write("-- This file will be removed on next boot.\n")
                        file.write("shell.run('delete startup.lua')\n")
                        file.close()
                        return true
                    end
                    return false
                end, debugMode)
                
                if success then
                    updateProgress("Startup file disabled successfully", 0.25)
                else
                    updateProgress("Failed to disable startup file", 0.25)
                    os.sleep(1)
                end
            end
            
            -- Remove all other files
            local function deleteFile(path)
                if fs.exists(path) or debugMode then
                    return performOperation(function()
                        fs.delete(path)
                        return true
                    end, debugMode)
                end
                return true
            end
            
            -- List of files to remove
            local files_to_remove = {
                "scios/Sci_sentinel.lua",
                "scios/Gui.lua",
                "scios/Commands.lua",
                "scios/Updater.lua",
                "scios/versions.db",
                "scios/filetracker.db",
                "scios/file_hashes.db"
            }
            
            -- Remove files with progress updates
            updateProgress("Removing SCI files...", 0.3)
            local allFilesRemoved = true
            for i, file in ipairs(files_to_remove) do
                if not deleteFile(file) then
                    allFilesRemoved = false
                end
                local fileProgress = 0.3 + (0.4 * (i / #files_to_remove))
                updateProgress("Removing: " .. file, fileProgress)
                os.sleep(0.2) -- Small delay to show progress
            end
            
            -- Clean up SCIOS directory
            updateProgress("Cleaning up SCIOS directory...", 0.8)
            
            -- Simple cleanup without complex error checking
            if fs.exists("scios") and not debugMode then
                -- Try to delete each file individually
                local files = fs.list("scios")
                for i, file in ipairs(files) do
                    local path = fs.combine("scios", file)
                    updateProgress(string.format("Removing: %s", path), 0.8 + (0.1 * (i/#files)))
                    pcall(function() fs.delete(path) end)  -- Use pcall to prevent errors from stopping the process
                    os.sleep(0.1) -- Small delay to prevent freezing
                end
                
                -- Finally remove the directory itself
                updateProgress("Removing SCIOS directory...", 0.95)
                pcall(function() fs.delete("scios") end)
            elseif debugMode then
                -- In debug mode, just simulate the delay
                os.sleep(0.5)
            end
            
            -- Final completion
            updateProgress("Uninstall Complete!", 1.0)
            os.sleep(1)
            
            -- Show completion screen
            term.clear()
            term.setCursorPos(1,1)
            
            if isPocketPC then
                gui.drawBox(1, 1, minWidth, minHeight, "[ Complete ]")
                
                if debugMode then
                    gui.drawCenteredText(2, "Debug Complete", colors.lime)
                    gui.drawCenteredText(3, "No changes made", colors.white)
                else
                    gui.drawCenteredText(2, "Uninstalled!", colors.lime)
                    gui.drawCenteredText(3, "Reboot needed", colors.white)
                end
                
                gui.drawCenteredText(5, "Reboot now?", colors.yellow)
            else
                gui.drawBox(1, 1, minWidth, minHeight, "[ Uninstall Complete ]")
                
                if debugMode then
                    gui.drawCenteredText(4, "Debug Mode: Uninstall Simulation Complete", colors.lime)
                    gui.drawCenteredText(6, "No files were modified", colors.white)
                    gui.drawCenteredText(7, "Run without -debug to perform actual uninstall", colors.white)
                else
                    gui.drawCenteredText(4, "SCI Sentinel has been uninstalled!", colors.lime)
                    gui.drawCenteredText(6, "The startup file will be removed", colors.white)
                    gui.drawCenteredText(7, "when you reboot the computer.", colors.white)
                end
                
                gui.drawCenteredText(9, "Would you like to reboot now?", colors.yellow)
            end
            
            -- Draw reboot buttons
            local buttons = {
                gui.drawButton(15, 12, "Reboot", colors.lime),
                gui.drawButton(30, 12, "Later", colors.red)
            }
            
            -- Handle reboot choice
            local choice = gui.handleButtons(buttons)
            if choice == "Reboot" and not debugMode then
                term.clear()
                term.setCursorPos(1,1)
                gui.drawCenteredText(8, "Rebooting...", colors.yellow)
                os.sleep(1)
                os.reboot()
            else
                -- Clear screen before exiting
                term.clear()
                term.setCursorPos(1,1)
            end
            
            -- Before returning, restore terminal state
            term.redirect(oldTerm)
            term.setBackgroundColor(oldBg)
            term.setTextColor(oldFg)
            term.clear()
            term.setCursorPos(1,1)
            return true
        end,
        mirror = function(args)
            local displayManager = require("DisplayManager")
            local enabled = displayManager.toggleMirroring()
            if enabled then
                gui.drawSuccess("Display mirroring enabled")
            else
                gui.drawSuccess("Display mirroring disabled")
            end
            return true
        end
    }
    
    -- Run command
    if commandHandlers[cmd] then
        return commandHandlers[cmd](parts)
    else
        -- Only run recognized commands
        gui.drawError("'" .. cmd .. "' is not recognized as an internal or external command.")
        gui.drawError("Type 'HELP' for a list of available commands")
        return false
    end
end

-- Return the Commands module
return {
    handleCommand = commands.handleCommand,
    saveState = commands.saveState,
    restoreState = commands.restoreState
}
