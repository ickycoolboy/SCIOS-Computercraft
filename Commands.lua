-- SCI Sentinel OS Commands Module
local version = "1.0.1"

-- Load required modules
local gui = require("Gui")
local updater = require("Updater")

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

local function help()
    gui.drawSuccess("SCI Sentinel Command Line Help")
    gui.drawSuccess("The following commands are available:")
    gui.drawSuccess("")
    gui.drawSuccess("  CD [path]      - Change directory")
    gui.drawSuccess("  CLS            - Clear screen")
    gui.drawSuccess("  COPY           - Copy files")
    gui.drawSuccess("  DEL            - Delete files")
    gui.drawSuccess("  DIR            - List directory contents")
    gui.drawSuccess("  HELP           - Show this help message")
    gui.drawSuccess("  MD             - Create directory")
    gui.drawSuccess("  RD             - Remove directory")
    gui.drawSuccess("  TYPE           - Display file contents")
    gui.drawSuccess("  VER            - Show version information")
    gui.drawSuccess("")
    gui.drawSuccess("SCI Sentinel Commands:")
    gui.drawSuccess("  UPDATE         - Check for updates")
    gui.drawSuccess("  REINSTALL      - Reinstall SCI Sentinel")
    gui.drawSuccess("  UNINSTALL      - Uninstall SCI Sentinel")
    gui.drawSuccess("  MIRROR         - Toggle display mirroring")
    return true
end

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
        help = help,
        ["?"] = help,  -- Allow ? as alias for help
        
        -- SCI Sentinel specific commands
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
            -- Check for debug mode
            local debugMode = false
            if args[1] == "-debug" then
                debugMode = true
                gui.drawInfo("Running in DEBUG mode - No files will be modified")
            end
            
            -- Clear screen and draw main interface
            term.clear()
            term.setCursorPos(1,1)
            
            -- Draw main box
            gui.drawBox(1, 1, 51, 16, "[ SCI Sentinel Uninstaller ]")
            
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
                return true
            end
            
            -- Draw uninstall progress interface
            term.clear()
            term.setCursorPos(1,1)
            gui.drawBox(1, 1, 51, 16, "[ Uninstalling SCI Sentinel ]")
            
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
            gui.drawBox(1, 1, 51, 16, "[ Uninstall Complete ]")
            
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
return commands
