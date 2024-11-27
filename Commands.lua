-- SCI Sentinel OS Commands Module

-- Load required modules
local gui = require("GUI")

-- ComputerCraft APIs are global, no need to require them
-- shell, fs, and term are available globally

local commands = {}

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

    if cmd == "ls" or cmd == "dir" then
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
    elseif cmd == "help" then
        gui.drawSuccess("Available commands:")
        gui.drawSuccess("  ls, dir - List directory contents")
        gui.drawSuccess("  mkdir   - Create a directory")
        gui.drawSuccess("  rm      - Remove a file or directory")
        gui.drawSuccess("  clear   - Clear the screen")
        gui.drawSuccess("  exit    - Exit SCI Sentinel")
        gui.drawSuccess("  help    - Show this help message")
        gui.drawSuccess("  update  - Check for updates")
    else
        gui.drawError("Unknown command: " .. cmd)
    end
    return true
end

-- Return the Commands module
return commands
