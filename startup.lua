local scriptPath = debug.getinfo(1, "S").source:sub(2)
local scriptDir = scriptPath:match("(.*/)")
print(scriptDir)


AegisOS = {
    version = "1.4.0",
    modules = {},
    apps = {},
    paths = {
        config = scriptDir.."data/config.json",
        missionTable = scriptDir.."data/mission_table.json",
        canonState = scriptDir.."data/canon_state.json",
        logo = scriptDir.."data/logo.txt"
    },
    constants = {
        GRAVITY = 0.05,
        MAX_ITERATIONS = 1000,
        DRAG = 0.01
    }
}

if not fs.exists("data") then
    fs.makeDir("data")
end

AegisOS.utils = dofile(scriptDir.."modules/utils.lua")
AegisOS.ui = dofile(scriptDir.."modules/ui.lua")
AegisOS.config = dofile(scriptDir.."modules/config.lua")
AegisOS.canon = dofile(scriptDir.."modules/canon.lua")
AegisOS.ballistics = dofile(scriptDir.."modules/ballistics.lua")
AegisOS.missions = dofile(scriptDir.."modules/missions.lua")
AegisOS.apps = dofile(scriptDir.."apps.lua")
dofile(scriptDir.."main.lua")

AegisOS.run()

AegisOS.canon.savePosition(0, 0)