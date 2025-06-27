--[[
AegisOS Startup File
Run this file to start the application.
--]]

-- Initialize the main AegisOS table
AegisOS = {
    version = "1.4.0",
    modules = {},
    apps = {},
    paths = {
        config = "data/config.json",
        missionTable = "data/mission_table.json",
        canonState = "data/canon_state.json",
        logo = "data/logo.txt"
    },
    constants = {
        GRAVITY = 0.05,
        MAX_ITERATIONS = 1000,
        DRAG = 0.01
    }
}

-- Create data directory if it doesn't exist
if not fs.exists("data") then
    fs.makeDir("data")
end

-- Load all modules
-- The '...' argument passes the AegisOS table to the loaded files.
AegisOS.utils = dofile("modules/utils.lua")
AegisOS.ui = dofile("modules/ui.lua")
AegisOS.config = dofile("modules/config.lua")
AegisOS.canon = dofile("modules/canon.lua")
AegisOS.ballistics = dofile("modules/ballistics.lua")
AegisOS.missions = dofile("modules/missions.lua")
AegisOS.apps = dofile("apps.lua")
dofile("main.lua") -- This file contains the AegisOS.run() function

-- Start the OS
AegisOS.run()

-- Reset canon state on shutdown
AegisOS.canon.savePosition(0, 0)