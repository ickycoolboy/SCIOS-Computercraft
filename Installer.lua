-- SCI Sentinel OS Installer
local version = "1.0.1"

-- GitHub repository information
local repo = {
    owner = "ickycoolboy",
    name = "SCIOS-Computercraft",
    branch = "Github-updating-test"
}

-- Required files
local required_files = {
    {name = "core", path = "Sci_sentinel.lua"},
    {name = "gui", path = "GUI.lua"},
    {name = "commands", path = "Commands.lua"},
    {name = "updater", path = "Updater.lua"},
    {name = "startup", path = "Startup.lua"}
}

local function getGitHubRawURL(filepath)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s",
        repo.owner,
        repo.name,
        repo.branch,
        filepath)
end

local function downloadFile(url, path)
    print("Downloading from: " .. url)
    print("Saving to: " .. path)
    
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        -- Ensure parent directory exists
        local dir = fs.getDir(path)
        if dir and dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
            return true
        else
            print("Failed to open file for writing: " .. path)
            return false
        end
    else
        print("Failed to download from: " .. url)
        return false
    end
end

-- Create startup file
local function createStartup()
    local startup_content = [[
-- SCI Sentinel OS Startup
local version = "1.0.0"

-- Load the main OS file
if fs.exists("scios/Sci_sentinel.lua") then
    shell.run("scios/Sci_sentinel.lua")
else
    print("SCI Sentinel OS not found. Please run the installer.")
end
]]
    
    local file = fs.open("startup.lua", "w")
    if file then
        file.write(startup_content)
        file.close()
        return true
    end
    return false
end

-- Main installation
print("Installing SCI Sentinel OS...")

-- Create main directory
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Download all required files
local all_success = true
for _, file in ipairs(required_files) do
    print("Installing " .. file.name .. " module...")
    local url = getGitHubRawURL(file.path)
    local path = "scios/" .. file.path
    
    if not downloadFile(url, path) then
        print("Failed to download " .. file.name .. " module")
        all_success = false
        break
    end
end

-- Create startup file
if all_success then
    print("Creating startup file...")
    if not createStartup() then
        print("Failed to create startup file")
        all_success = false
    end
end

if all_success then
    print("Installation complete! Rebooting in 3 seconds...")
    os.sleep(3)
    os.reboot()
else
    print("Installation failed. Please check the error messages above.")
    print("Press any key to exit...")
    os.pullEvent("key")
end
