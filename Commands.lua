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
        -- Confirm uninstallation
        gui.drawWarning("WARNING: This will completely remove SCI Sentinel from your computer.")
        if not gui.confirm("Are you sure you want to proceed with uninstallation?") then
            gui.drawSuccess("Uninstall cancelled")
            return true
        end

        -- Debug: Check current directory and startup.lua location
        local current_dir = shell.dir()
        gui.drawInfo("Current directory: " .. current_dir)

        -- Get absolute paths
        local function getAbsolutePath(path)
            if path:sub(1,1) == "/" then
                return path
            else
                return fs.combine(current_dir, path)
            end
        end

        -- Aggressive startup file removal
        local function removeStartup()
            -- Try multiple possible locations with absolute paths
            local startup_locations = {
                "", -- root
                "scios",
                current_dir
            }

            for _, dir in ipairs(startup_locations) do
                local path = fs.combine(dir, "startup.lua")
                gui.drawInfo("Checking for startup.lua in: " .. path)
                
                if fs.exists(path) then
                    gui.drawInfo("Found startup.lua at: " .. path)
                    
                    -- Method 1: Close all file handles and delete
                    local success = pcall(function()
                        -- Force close any open handles
                        if fs.open(path, "r") then
                            fs.close(path)
                        end
                        fs.delete(path)
                    end)
                    
                    -- Verify deletion
                    if success and not fs.exists(path) then
                        gui.drawSuccess("Successfully removed startup.lua from: " .. path)
                        return true
                    end
                    
                    -- Method 2: Try to overwrite then delete
                    if fs.exists(path) then
                        success = pcall(function()
                            local file = fs.open(path, "w")
                            if file then
                                file.write("-- Disabled by uninstaller\n")
                                file.close()
                                fs.delete(path)
                            end
                        end)
                        
                        if success and not fs.exists(path) then
                            gui.drawSuccess("Successfully removed startup.lua after overwrite from: " .. path)
                            return true
                        end
                    end
                    
                    -- Method 3: Use shell commands
                    if fs.exists(path) then
                        success = pcall(function()
                            shell.run("delete", path)
                            if fs.exists(path) then
                                shell.run("rm", path)
                            end
                        end)
                        
                        if success and not fs.exists(path) then
                            gui.drawSuccess("Successfully removed startup.lua using shell commands from: " .. path)
                            return true
                        end
                    end
                    
                    if fs.exists(path) then
                        gui.drawError("Failed to remove startup.lua from: " .. path)
                    end
                end
            end
            return false
        end

        -- Try to remove startup file first
        if not removeStartup() then
            gui.drawError("WARNING: Could not remove startup file. System may still boot into SCI Sentinel.")
            if not gui.confirm("Continue with uninstallation anyway?") then
                gui.drawSuccess("Uninstall cancelled")
                return true
            end
        end

        -- Remove all other files
        local function deleteFile(path)
            if fs.exists(path) then
                local success = pcall(function()
                    if fs.isDir(path) then
                        fs.delete(path)
                    else
                        local file = fs.open(path, "w")
                        if file then
                            file.close()
                        end
                        fs.delete(path)
                    end
                end)
                if success and not fs.exists(path) then
                    gui.drawSuccess("Removed: " .. path)
                    return true
                else
                    gui.drawError("Failed to remove: " .. path)
                    return false
                end
            end
            return true -- File doesn't exist, consider it removed
        end

        -- List of files to remove with proper paths
        local files_to_remove = {
            "startup.lua",
            "/startup.lua",
            "scios/startup.lua",
            "scios/Sci_sentinel.lua",
            "scios/Gui.lua",
            "scios/Commands.lua",
            "scios/Updater.lua",
            "scios/versions.db",
            "scios/filetracker.db",
            "scios/file_hashes.db"
        }

        -- Remove all files
        for _, file in ipairs(files_to_remove) do
            deleteFile(getAbsolutePath(file))
        end

        -- Try to remove the scios directory itself
        if fs.exists("scios") then
            local success = pcall(function() 
                -- Try to remove any remaining files
                for _, file in ipairs(fs.list("scios")) do
                    local path = fs.combine("scios", file)
                    deleteFile(path)
                end
                -- Then remove directory
                fs.delete("scios") 
            end)
            
            if success and not fs.exists("scios") then
                gui.drawSuccess("Removed SCIOS directory")
            else
                gui.drawWarning("Could not remove SCIOS directory completely")
                if fs.exists("scios") and fs.list("scios") then
                    gui.drawWarning("Remaining files in SCIOS directory:")
                    for _, file in ipairs(fs.list("scios")) do
                        gui.drawWarning("  - " .. file)
                    end
                end
            end
        end

        -- Final verification
        local function checkFile(path)
            if fs.exists(path) then
                gui.drawError("File still exists: " .. path)
                return true
            end
            return false
        end

        local files_exist = false
        for _, path in ipairs({
            "startup.lua",
            "/startup.lua",
            "scios/startup.lua",
            "scios"
        }) do
            if checkFile(getAbsolutePath(path)) then
                files_exist = true
            end
        end

        if files_exist then
            gui.drawError("Some SCI Sentinel files could not be removed.")
            gui.drawError("Please try to remove them manually using 'delete' or 'rm' commands.")
        else
            gui.drawSuccess("SCI Sentinel has been successfully uninstalled.")
        end

        gui.drawSuccess("The computer will reboot in 3 seconds...")
        os.sleep(3)
        os.reboot()
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
