-- SCI Sentinel OS Commands Module
local version = "1.0.1"

-- Load required modules
local gui = require("Gui")

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

    if cmd == "shell" or cmd == "craftos" then
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
        if gui.confirm("Are you sure you want to uninstall SCI Sentinel? This will remove all system files except the installer.") then
            -- Remove startup file first to prevent auto-start
            if fs.exists("startup.lua") then
                fs.delete("startup.lua")
            end
            
            -- Remove system files
            local system_files = {
                "scios/Sci_sentinel.lua",
                "scios/Gui.lua",
                "scios/Commands.lua",
                "scios/Updater.lua",
                "scios/versions.db"
            }
            local removed = 0
            for _, file in ipairs(system_files) do
                if fs.exists(file) then
                    fs.delete(file)
                    removed = removed + 1
                end
            end
            
            -- Try to remove scios directory if empty
            if fs.exists("scios") and fs.list("scios") ~= nil and #fs.list("scios") == 0 then
                fs.delete("scios")
            end
            
            gui.drawSuccess(string.format("Uninstalled SCI Sentinel (%d files removed)", removed))
            gui.drawSuccess("System will reboot in 3 seconds...")
            os.sleep(3)
            os.reboot()
        else
            gui.drawSuccess("Uninstall cancelled")
        end
    else
        -- Try to run as CraftOS command if not recognized
        if shell.resolveProgram(cmd) then
            shell.run(command)
            return true
        end
        gui.drawError("Unknown command: " .. cmd)
    end
    return true
end

-- Return the Commands module
return commands
