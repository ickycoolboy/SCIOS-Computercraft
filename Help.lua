-- SCI Sentinel OS Help Module
local help = {}

-- Command documentation structure
local commands = {
    CD = {
        syntax = "CD [drive:][path]",
        description = "Changes the current directory.",
        details = {
            "Changes the current directory or displays the current directory.",
            "",
            "CD ..         Changes to the parent directory",
            "CD \\         Changes to the root directory",
            "CD            Display current directory path",
            "",
            "Type CD without parameters to display the current path."
        }
    },
    DIR = {
        syntax = "DIR [drive:][path][filename]",
        description = "Displays a list of files and subdirectories in a directory.",
        details = {
            "Lists all files and directories in the specified path.",
            "",
            "DIR          Lists all files in current directory",
            "DIR path     Lists all files in specified path",
            "",
            "The output shows:",
            " - File/directory name",
            " - Size in bytes for files",
            " - <DIR> marker for directories",
            " - Total files listed",
            " - Total bytes used"
        }
    },
    COPY = {
        syntax = "COPY <source> <destination>",
        description = "Copies one or more files to another location.",
        details = {
            "Copies files from one location to another.",
            "",
            "COPY file1.txt file2.txt    Copy file1 to file2",
            "COPY file.txt dir\\          Copy file to directory",
            "",
            "The file will be overwritten if it already exists."
        }
    },
    DEL = {
        syntax = "DEL <filename>",
        description = "Deletes one or more files.",
        details = {
            "Deletes specified files permanently.",
            "",
            "DEL file.txt    Delete a single file",
            "",
            "Warning: Files cannot be recovered once deleted."
        }
    },
    TYPE = {
        syntax = "TYPE <filename>",
        description = "Displays the contents of a text file.",
        details = {
            "Shows the content of specified text file.",
            "",
            "TYPE file.txt    Display file contents",
            "",
            "Use this command to view text files."
        }
    },
    MD = {
        syntax = "MD <directory>",
        description = "Creates a directory.",
        details = {
            "Creates a new directory at specified path.",
            "",
            "MD dirname       Create new directory",
            "MD dir\\subdir   Create nested directory",
            "",
            "Parent directory must exist for nested directories."
        }
    },
    RD = {
        syntax = "RD <directory>",
        description = "Removes a directory.",
        details = {
            "Removes (deletes) a directory.",
            "",
            "RD dirname      Remove empty directory",
            "",
            "Directory must be empty to be removed."
        }
    },
    CLS = {
        syntax = "CLS",
        description = "Clears the screen.",
        details = {
            "Clears the terminal screen and moves cursor to top.",
            "",
            "Use this command to clean up the display."
        }
    },
    VER = {
        syntax = "VER",
        description = "Displays SCI Sentinel version.",
        details = {
            "Shows the version information for SCI Sentinel OS.",
            "",
            "Use this to check your current version."
        }
    },
    UPDATE = {
        syntax = "UPDATE",
        description = "Checks for and installs system updates.",
        details = {
            "Checks GitHub repository for newer versions.",
            "",
            "The update process:",
            " - Checks version numbers",
            " - Downloads new files if available",
            " - Updates system files",
            "",
            "System will restart after updating."
        }
    },
    REINSTALL = {
        syntax = "REINSTALL",
        description = "Reinstalls SCI Sentinel OS.",
        details = {
            "Completely reinstalls the operating system.",
            "",
            "Warning: This will:",
            " - Download fresh copies of all system files",
            " - Replace existing system files",
            " - Require confirmation before proceeding",
            "",
            "Your data files will not be affected."
        }
    },
    UNINSTALL = {
        syntax = "UNINSTALL [-debug]",
        description = "Removes SCI Sentinel OS from the computer.",
        details = {
            "Completely removes the operating system.",
            "",
            "Options:",
            " -debug    Run in debug mode (no files deleted)",
            "",
            "Warning: This will:",
            " - Remove all system files",
            " - Cannot be undone",
            " - Requires confirmation"
        }
    },
    MIRROR = {
        syntax = "MIRROR",
        description = "Toggles display mirroring for secondary monitors.",
        details = {
            "Controls monitor output mirroring.",
            "",
            "Effects:",
            " - Toggles between single and mirrored display",
            " - Affects all connected monitors",
            "",
            "Use this to manage multi-monitor setups."
        }
    },
    MEM = {
        syntax = "MEM",
        description = "Displays storage and memory information.",
        details = {
            "Shows detailed storage and memory statistics.",
            "",
            "Information displayed:",
            " - Total Storage Space in bytes",
            " - Used Storage Space in bytes",
            " - Free Storage Space in bytes",
            " - Memory Limit (if available)",
            "",
            "Use this command to monitor system resources."
        }
    },
    PS = {
        syntax = "PS",
        description = "Displays system status and running tasks.",
        details = {
            "Shows computer information and running parallel tasks.",
            "",
            "Information displayed:",
            " - Computer ID",
            " - Computer Label",
            " - Current Time",
            " - Current Day",
            " - List of running parallel tasks (if any)",
            "",
            "Use this command to monitor system activity."
        }
    },
    FIND = {
        syntax = "FIND <pattern>",
        description = "Searches for files matching the specified pattern.",
        details = {
            "Recursively searches for files matching the given pattern.",
            "",
            "FIND *.lua   Finds all Lua files",
            "FIND test    Finds files containing 'test'",
            "",
            "The search:",
            " - Is case-sensitive",
            " - Starts from current directory",
            " - Includes subdirectories",
            " - Shows full path of matches"
        }
    },
    TAIL = {
        syntax = "TAIL <file> [lines]",
        description = "Displays the last part of a file.",
        details = {
            "Shows the last lines of the specified file.",
            "",
            "TAIL file.txt      Shows last 10 lines",
            "TAIL file.txt 20   Shows last 20 lines",
            "",
            "Parameters:",
            " file   - Required. The file to display",
            " lines  - Optional. Number of lines (default: 10)"
        }
    },
    HISTORY = {
        syntax = "HISTORY",
        description = "Displays the command history.",
        details = {
            "Shows a numbered list of previously executed commands.",
            "",
            "Information shown:",
            " - Command number",
            " - Command text",
            "",
            "Use this to recall previous commands."
        }
    },
    HELP = {
        syntax = "HELP [command]",
        description = "Provides help information for SCI Sentinel commands.",
        details = {
            "Shows help for commands. Without parameters, lists all commands.",
            "",
            "HELP         Lists all available commands",
            "HELP CMD     Shows detailed help for CMD",
            "",
            "For more information on a specific command, type HELP command-name"
        }
    },
    LABEL = {
        syntax = "LABEL [new-name|clear]",
        description = "Displays or changes the computer label.",
        details = {
            "View or modify the computer's network label.",
            "",
            "LABEL         Shows current label",
            "LABEL name    Sets computer label to 'name'",
            "LABEL clear   Removes the computer label",
            "",
            "The label is used for:",
            " - Computer identification on networks",
            " - Rednet communication",
            " - Finding specific computers",
            "",
            "Changes take effect immediately."
        }
    },
    NET = {
        syntax = "NET <command>",
        description = "Manages network connections and displays network status.",
        details = {
            "Available commands:",
            "  NET STATUS    - Show network status and modem information",
            "  NET SCAN      - Scan for nearby computers",
            "  NET OPEN      - Open all modems for networking",
            "  NET CLOSE     - Close all modems",
            "",
            "Examples:",
            "  NET STATUS    Shows current network status and modem information",
            "  NET SCAN      Scans for nearby computers and displays their IDs"
        }
    },
    PING = {
        syntax = "PING <computer-id>",
        description = "Tests network connectivity to another computer.",
        details = {
            "Sends a ping request to the specified computer and measures the response time.",
            "",
            "Examples:",
            "  PING 5        Pings computer with ID 5"
        }
    },
    MSG = {
        syntax = "MSG <computer-id> <message>",
        description = "Sends a message to another computer.",
        details = {
            "Sends a text message to the specified computer over the network.",
            "",
            "Examples:",
            "  MSG 5 Hello   Sends 'Hello' to computer with ID 5",
            "  MSG 3 How are you?    Sends 'How are you?' to computer with ID 3"
        }
    },
}

-- Function to get command help
function help.getCommandHelp(command)
    if command then
        command = command:upper()
        return commands[command]
    end
    return nil
end

-- Function to list all commands
function help.listCommands()
    local cmdList = {}
    for cmd, info in pairs(commands) do
        table.insert(cmdList, {
            name = cmd,
            desc = info.description
        })
    end
    table.sort(cmdList, function(a, b) return a.name < b.name end)
    return cmdList
end

-- Return the module
return help
