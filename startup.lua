local scriptPath = debug.getinfo(1, "S").source:sub(2)
local scriptDir = scriptPath:match("(.*/)") or ""

-- Initialize the main application object as a local variable.
local AegisOS = {
    version = "1.6.0",
    modules = {},
    apps = {},
    paths = {
        config = scriptDir.."data/config.json",
        missionTable = scriptDir.."data/mission_table.json",
        canonState = scriptDir.."data/canon_state.json",
        logo = scriptDir.."logo.txt"
    },
    constants = {
        GRAVITY = 0.05,
        MAX_ITERATIONS = 1000,
        DRAG = 0.01
    }
}

if not fs.exists(scriptDir.."data") then
    fs.makeDir(scriptDir.."data")
end

-- Load all modules and attach them to the AegisOS object.
-- These dofile calls return tables of functions.
AegisOS.utils = dofile(scriptDir.."modules/utils.lua")
AegisOS.ui = dofile(scriptDir.."modules/ui.lua")
AegisOS.config = dofile(scriptDir.."modules/config.lua")
AegisOS.canon = dofile(scriptDir.."modules/canon.lua")
AegisOS.ballistics = dofile(scriptDir.."modules/ballistics.lua")
AegisOS.missions = dofile(scriptDir.."modules/missions.lua")
AegisOS.redstoneController = dofile(scriptDir.."modules/redstoneController.lua")
AegisOS.apps = dofile(scriptDir.."apps.lua")

-- Load the main application function from main.lua
local run = dofile(scriptDir.."main.lua")

-- Start the application by calling the run function with the AegisOS object.
run(AegisOS)