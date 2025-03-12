local canonControl = {}
local stateFilePath = "canon_state.json"

-- Load saved state or initialize with defaults
local function loadState()
    local common = require "common"
    local state = common.readFromJsonFile(stateFilePath)
    
    if not state then
        -- Initialize with defaults if no state file exists
        state = {
            currentYaw = 0,
            currentPitch = 0
        }
        common.writeToJsonFile(state, stateFilePath)
    end
    
    return state
end

-- Save current state to file
local function saveState(yaw, pitch)
    local common = require "common"
    local state = {
        currentYaw = yaw,
        currentPitch = pitch
    }
    return common.writeToJsonFile(state, stateFilePath)
end

-- Get current state
function canonControl.getCurrentPosition()
    local state = loadState()
    return state.currentYaw, state.currentPitch
end

-- Set current state directly (useful for calibration)
function canonControl.setCurrentPosition(yaw, pitch)
    return saveState(yaw, pitch)
end

-- Calculate shortest rotation path
local function calculateShortestPath(current, target)
    -- Normalize angles to 0-360 range
    current = current % 360
    if current < 0 then current = current + 360 end
    
    target = target % 360
    if target < 0 then target = target + 360 end
    
    -- Calculate clockwise and counterclockwise distances
    local clockwiseDist = (target - current) % 360
    local counterclockwiseDist = (current - target) % 360
    
    -- Choose the shorter path
    if clockwiseDist <= counterclockwiseDist then
        return clockwiseDist, 1  -- Clockwise, positive mod
    else
        return counterclockwiseDist, -1  -- Counterclockwise, negative mod
    end
end

function canonControl.moveCanon(yawData, pitchData, triggerSide)
    local common = require "common"
    local modem = peripheral.wrap('bottom')

    triggerSide = triggerSide or "back"
    
    -- Load current state
    local state = loadState()
    local prevYaw = state.currentYaw
    local prevPitch = state.currentPitch
    
    -- Calculate optimal rotation paths
    local yawAngle, yawMod = calculateShortestPath(prevYaw, yawData['angle'])
    local pitchAngle, pitchMod = calculateShortestPath(prevPitch, pitchData['angle'])

    local yawControllName = "Create_SequencedGearshift_" .. yawData['id']
    local pitchControllName = "Create_SequencedGearshift_" .. pitchData['id']

    -- Debug output
    print("Moving from Yaw: " .. prevYaw .. " to " .. yawData['angle'])
    print("Rotation: " .. yawAngle .. " degrees " .. (yawMod > 0 and "clockwise" or "counterclockwise"))
    print("Moving from Pitch: " .. prevPitch .. " to " .. pitchData['angle'])
    print("Rotation: " .. pitchAngle .. " degrees " .. (pitchMod > 0 and "upward" or "downward"))
    sleep(1)

    modem.callRemote(yawControllName, 'rotate', yawAngle * 8, yawMod)
    modem.callRemote(pitchControllName, 'rotate', pitchAngle * 8, pitchMod)

    while modem.callRemote(yawControllName, "isRunning") or modem.callRemote(pitchControllName, "isRunning") do
        sleep(0.01)
    end

    common.redstoneBlink(triggerSide, 5)

    -- Save new state
    saveState(yawData['angle'], pitchData['angle'])
    print("Movement complete.")
    sleep(1)
end

-- Add a new calibration function
function canonControl.calibrate()
    local common = require "common"
    
    common.termClear()
    print("=====Canon Calibration=====")
    print("Enter current physical yaw angle (0-360):")
    local yaw = tonumber(read()) or 0
    
    print("Enter current physical pitch angle:")
    local pitch = tonumber(read()) or 0
    
    if saveState(yaw, pitch) then
        print("Calibration successful!")
    else
        print("Failed to save calibration data.")
    end
    
    sleep(2)
    return yaw, pitch
end

return canonControl
