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

function commands.executeCommand(command, gui)
    if not command or command == "" then
        return true
    end

    local args = {}
    for word in string.gmatch(command, "%S+") do
        table.insert(args, word)
    end

    local cmd = args[1]
    table.remove(args, 1)

    if cmd == "update" then
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
    elseif cmd == "shell" or cmd == "craftos" then
        commands.saveState()
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.yellow)
        print("CraftOS Shell Mode - Type 'exit' to return to SCI Sentinel")
        term.setTextColor(colors.white)
        
        while true do
            term.write("> ")
            local input = read()
            if input == "exit" then
                break
            end
            
            -- Execute CraftOS command
            shell.run(input)
        end
        
        commands.restoreState()
        return true
    elseif cmd == "!" then
        -- Direct CraftOS command execution
        local craftosCmd = table.concat(args, " ")
        if craftosCmd ~= "" then
            shell.run(craftosCmd)
        end
        return true
    elseif cmd == "minimize" then
        commands.saveState()
        term.clear()
        term.setCursorPos(1,1)
        print("SCI Sentinel minimized. Type 'sentinel' to restore.")
        shell.run("shell")
        commands.restoreState()
        return true
    elseif cmd == "ls" or cmd == "dir" then
        local path = shell.dir()
        local ok, files = pcall(fs.list, path)
        if ok then
            gui.drawSuccess("Contents of " .. path .. ":")
            for _, file in ipairs(files) do
                local isDir = fs.isDir(fs.combine(path, file))
                gui.drawSuccess((isDir and "[DIR] " or "      ") .. file)
            end
        else
            gui.drawError("Error listing directory: " .. tostring(files))
        end
    elseif cmd == "mkdir" then
        if #args == 1 then
            local dirName = args[1]
            if not fs.exists(dirName) then
                local ok, err = pcall(fs.makeDir, dirName)
                if ok then
                    gui.drawSuccess("Directory created: " .. dirName)
                else
                    gui.drawError("Error creating directory: " .. tostring(err))
                end
            else
                gui.drawError("Directory already exists: " .. dirName)
            end
        else
            gui.drawError("Usage: mkdir <directory>")
        end
    elseif cmd == "rm" then
        if #args == 1 then
            local fileName = args[1]
            if fs.exists(fileName) then
                local ok, err = pcall(fs.delete, fileName)
                if ok then
                    gui.drawSuccess("Deleted: " .. fileName)
                else
                    gui.drawError("Error deleting file or directory: " .. tostring(err))
                end
            else
                gui.drawError("File or directory not found: " .. fileName)
            end
        else
            gui.drawError("Usage: rm <filename or directory>")
        end
    elseif cmd == "exit" then
        return false
    elseif cmd == "clear" then
        term.clear()
        term.setCursorPos(1, 1)
        gui.drawScreen()
    elseif cmd == "reinstall" then
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
    elseif cmd == "help" then
        gui.drawSuccess("Available commands:")
        gui.drawSuccess("  shell, craftos - Enter CraftOS shell mode")
        gui.drawSuccess("  ! <command>   - Execute single CraftOS command")
        gui.drawSuccess("  minimize      - Minimize Sentinel to CraftOS")
        gui.drawSuccess("  ls, dir       - List directory contents")
        gui.drawSuccess("  mkdir         - Create a directory")
        gui.drawSuccess("  rm            - Remove a file or directory")
        gui.drawSuccess("  clear         - Clear the screen")
        gui.drawSuccess("  exit          - Exit SCI Sentinel")
        gui.drawSuccess("  help          - Show this help message")
        gui.drawSuccess("  update        - Check for updates")
        gui.drawSuccess("  reinstall     - Reinstall SCI Sentinel")
        gui.drawSuccess("  uninstall     - Uninstall SCI Sentinel")
    elseif cmd == "uninstall" then
        -- Load file tracker
        local tracker_path = "scios/filetracker.db"
        local filetracker = nil
        
        if fs.exists(tracker_path) then
            local file = fs.open(tracker_path, "r")
            if file then
                local content = file.readAll()
                file.close()
                filetracker = textutils.unserializeJSON(content)
            end
        end
        
        if not filetracker then
            gui.drawWarning("File tracker not found. Using default file list.")
            filetracker = {
                system_files = {
                    "startup.lua",
                    "scios/Sci_sentinel.lua",
                    "scios/Gui.lua",
                    "scios/Commands.lua",
                    "scios/Updater.lua",
                    "scios/versions.db",
                    "scios/filetracker.db"
                },
                temp_files = {
                    "scios/*.tmp",
                    "scios/*.bak",
                    "scios/*.log"
                },
                protected_files = {
                    "startup.lua",
                    "scios/Sci_sentinel.lua",
                    "scios/Gui.lua"
                }
            }
        end

        -- Confirm uninstallation
        gui.drawWarning("WARNING: This will completely remove SCI Sentinel from your computer.")
        if not gui.confirm("Are you sure you want to proceed with uninstallation?") then
            gui.drawSuccess("Uninstall cancelled")
            return true
        end

        -- Ask about force deletion
        local force_delete = gui.confirm("Do you want to force delete protected files?", colors.red)
        
        local function isProtected(file)
            for _, protected in ipairs(filetracker.protected_files) do
                if file == protected then
                    return true
                end
            end
            return false
        end

        local function deleteFile(file)
            if fs.exists(file) then
                local protected = isProtected(file)
                if protected and not force_delete then
                    gui.drawWarning(string.format("Skipping protected file: %s", file))
                    return false
                end
                
                local success = pcall(function()
                    fs.delete(file)
                end)
                
                if success then
                    gui.drawSuccess(string.format("Removed: %s", file))
                    return true
                else
                    gui.drawError(string.format("Failed to remove: %s", file))
                    return false
                end
            end
            return true -- File doesn't exist, consider it "removed"
        end

        -- Delete system files
        local removed = 0
        local failed = 0
        
        -- First delete non-protected files
        for _, file in ipairs(filetracker.system_files) do
            if not isProtected(file) then
                if deleteFile(file) then
                    removed = removed + 1
                else
                    failed = failed + 1
                end
            end
        end
        
        -- Then delete protected files if force delete is enabled
        if force_delete then
            for _, file in ipairs(filetracker.protected_files) do
                if deleteFile(file) then
                    removed = removed + 1
                else
                    failed = failed + 1
                end
            end
        end

        -- Clean up temporary files
        local function cleanTempFiles(pattern)
            local dir = fs.getDir(pattern)
            local ext = string.match(pattern, ".*%*(%..+)$")
            if dir and ext then
                if fs.exists(dir) then
                    for _, file in ipairs(fs.list(dir)) do
                        if string.match(file, ".*" .. ext .. "$") then
                            local full_path = fs.combine(dir, file)
                            if deleteFile(full_path) then
                                removed = removed + 1
                            else
                                failed = failed + 1
                            end
                        end
                    end
                end
            end
        end

        -- Clean up temp files
        for _, pattern in ipairs(filetracker.temp_files) do
            cleanTempFiles(pattern)
        end

        -- Try to remove scios directory if empty
        if fs.exists("scios") then
            local files = fs.list("scios")
            if #files == 0 then
                fs.delete("scios")
                gui.drawSuccess("Removed empty scios directory")
            else
                gui.drawWarning("scios directory not empty, some files remain")
            end
        end

        -- Final status
        gui.drawSuccess(string.format("Uninstallation complete: Removed %d files, %d failed", removed, failed))
        
        if failed > 0 then
            gui.drawWarning("Some files could not be removed. You may need to delete them manually.")
        end
        
        if force_delete then
            gui.drawSuccess("System will reboot in 3 seconds...")
            sleep(3)
            os.reboot()
        end
        
        return true
    else
        -- Only run recognized commands
        gui.drawError("Unknown command: " .. cmd)
        gui.drawError("Type 'help' for a list of available commands")
        return true
    end
    return true
end

-- Return the Commands module
return commands
