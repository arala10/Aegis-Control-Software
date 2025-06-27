local files = {
    "logo.txt",
    "startup.lua",
    "main.lua",
    "apps.lua",
    "modules/balistics.lua",
    "modules/canon.lua",
    "modules/config.lua",
    "modules/missions.lua",
    "modules/ui.lua",
    "modules/utils.lua",
}

local baseURL = "https://raw.githubusercontent.com/arala10/Aegis-Control-Software/refs/heads/main/"

for _, file in ipairs(files) do
    local url = baseURL .. file
    print("Downloading " .. file .. "...")
    shell.run("wget " .. url .. " " .. file)
end

print("All files downloaded successfully!")
