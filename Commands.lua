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
        -- Clear screen and draw main interface
        term.clear()
        term.setCursorPos(1,1)
        
        -- Draw main box
        gui.drawBox(1, 1, 51, 16, "[ SCI Sentinel Uninstaller ]")
        
        -- Draw warning
        gui.drawCenteredText(4, "WARNING!", colors.red)
        gui.drawCenteredText(6, "This will completely remove", colors.orange)
        gui.drawCenteredText(7, "SCI Sentinel from your computer.", colors.orange)
        gui.drawCenteredText(9, "Are you sure you want to proceed?", colors.white)
        
        -- Draw buttons
        local buttons = {
            gui.drawButton(15, 12, "Uninstall", colors.red),
            gui.drawButton(30, 12, "Cancel", colors.lime)
        }
        
        -- Handle button click
        local choice = gui.handleButtons(buttons)
        if choice ~= "Uninstall" then
            gui.drawSuccess("Uninstall cancelled")
            return true
        end
        
        -- Draw uninstall progress interface
        term.clear()
        term.setCursorPos(1,1)
        gui.drawBox(1, 1, 51, 16, "[ Uninstalling SCI Sentinel ]")
        
        -- First, disable startup.lua
        if fs.exists("startup.lua") then
            gui.drawFancyProgressBar(3, 4, 47, "Disabling startup file", 0.25)
            local success = pcall(function()
                local file = fs.open("startup.lua", "w")
                if file then
                    file.write("-- SCI Sentinel has been uninstalled.\n")
                    file.write("-- This file will be removed on next boot.\n")
                    file.write("shell.run('delete startup.lua')\n")
                    file.close()
                end
            end)
            
            if success then
                gui.drawCenteredText(6, "Startup file disabled successfully", colors.lime)
            else
                gui.drawCenteredText(6, "Failed to disable startup file", colors.red)
                os.sleep(2)
            end
        end
        
        -- Remove all other files
        local function deleteFile(path)
            if fs.exists(path) then
                local success = pcall(function()
                    if fs.isDir(path) then
                        fs.delete(path)
                    else
                        fs.delete(path)
                    end
                end)
                return success and not fs.exists(path)
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
        
        -- Remove files with progress
        gui.drawFancyProgressBar(3, 8, 47, "Removing SCI files", 0.50)
        for _, file in ipairs(files_to_remove) do
            deleteFile(file)
        end
        
        -- Clean up SCIOS directory
        gui.drawFancyProgressBar(3, 10, 47, "Cleaning up", 0.75)
        if fs.exists("scios") then
            pcall(function()
                for _, file in ipairs(fs.list("scios")) do
                    local path = fs.combine("scios", file)
                    deleteFile(path)
                end
                fs.delete("scios")
            end)
        end
        
        gui.drawFancyProgressBar(3, 10, 47, "Uninstall Complete!", 1.0)
        os.sleep(1)
        
        -- Show completion screen
        term.clear()
        term.setCursorPos(1,1)
        gui.drawBox(1, 1, 51, 16, "[ Uninstall Complete ]")
        
        gui.drawCenteredText(4, "SCI Sentinel has been uninstalled!", colors.lime)
        gui.drawCenteredText(6, "The startup file will be removed", colors.white)
        gui.drawCenteredText(7, "when you reboot the computer.", colors.white)
        gui.drawCenteredText(9, "Would you like to reboot now?", colors.yellow)
        
        -- Draw reboot buttons
        buttons = {
            gui.drawButton(15, 12, "Reboot", colors.lime),
            gui.drawButton(30, 12, "Later", colors.red)
        }
        
        -- Handle reboot choice
        choice = gui.handleButtons(buttons)
        if choice == "Reboot" then
            term.clear()
            term.setCursorPos(1,1)
            gui.drawCenteredText(8, "Rebooting...", colors.yellow)
            os.sleep(1)
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
