-- SCI Sentinel OS Installer

-- GitHub repository information
local GITHUB_REPO = {
    owner = "ickycoolboy",
    name = "SCIOS-Computercraft",
    branch = "Github-updating-test"
}

-- Module file mappings
local MODULE_FILES = {
    updater = "Updater.lua",
    gui = "GUI.lua",
    commands = "Commands.lua",
    core = "sci_sentinel.lua"
}

local function getGitHubRawURL(filepath)
    return string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        GITHUB_REPO.owner,
        GITHUB_REPO.name,
        GITHUB_REPO.branch,
        filepath
    )
end

local function downloadFromGitHub(filepath, destination)
    local url = getGitHubRawURL(filepath)
    print("Downloading from: " .. url)
    
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(destination, "w")
        file.write(content)
        file.close()
        return true
    end
    return false
end

local function createStartup()
    print("Creating startup file...")
    local file = fs.open("startup", "w")
    file.write('shell.run("scios/sci_sentinel.lua")')
    file.close()
end

print("Starting SCI Sentinel OS installation...")

-- Create scios directory
if not fs.exists("scios") then
    fs.makeDir("scios")
end

-- Create startup file FIRST
createStartup()

-- Download all modules
for name, filename in pairs(MODULE_FILES) do
    print("Downloading " .. name .. " module...")
    if not downloadFromGitHub(filename, "scios/" .. filename) then
        print("Failed to download " .. name .. " module!")
        return
    end
end

print("Installation complete! Rebooting in 3 seconds...")
os.sleep(3)
os.reboot()
