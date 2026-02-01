local canon = {}

-- NATO Mils constants
local MILS_PER_CIRCLE = 6400
local DEGREES_TO_MILS = MILS_PER_CIRCLE / 360
local MOTOR_DEGREES_PER_MIL = 45 -- degrees needed for 1 mils

local modem = peripheral.wrap('bottom')

local function toMils(degrees)
    return degrees * DEGREES_TO_MILS
end

function canon.getCurrentPosition(AegisOS)
    local success, data = pcall(function() 
        return modem.callRemote("blockReader_0", "getBlockData") 
    end)

    local currentYawMils = 0
    local currentPitchMils = 0

    if success then
        local rawYawAngle = data.CannonYaw
        local rawPitchAngle = data.CannonPitch
        currentYawMils = toMils(rawYawAngle)
        currentPitchMils = toMils(rawPitchAngle)
    else
        print("Error: Could not read blockReader_0 or 'angle' key missing.")
    end
    return currentYawMils, currentPitchMils
end

function canon.savePosition(AegisOS, yawMils, pitchMils)
    local state = { currentYaw = yawMils, currentPitch = pitchMils }
    return AegisOS.utils.writeToJsonFile(AegisOS, state, AegisOS.paths.canonState)
end

function canon.calculateShortestPath(AegisOS, current, target)
    current = current % MILS_PER_CIRCLE; if current < 0 then current = current + MILS_PER_CIRCLE end
    target = target % MILS_PER_CIRCLE; if target < 0 then target = target + MILS_PER_CIRCLE end
    
    local clockwiseDist = (target - current) % MILS_PER_CIRCLE
    local counterclockwiseDist = (current - target) % MILS_PER_CIRCLE
    
    if clockwiseDist <= counterclockwiseDist then 
        return clockwiseDist, 1 
    else 
        return counterclockwiseDist, -1 
    end
end

function canon.moveCanon(AegisOS, yawData, pitchData, triggerSide)
    triggerSide = triggerSide or "back"
    
    local prevYaw, prevPitch = AegisOS.canon.getCurrentPosition(AegisOS)
    
    local targetYawMils = toMils(yawData.angle)
    local targetPitchMils = toMils(pitchData.angle)

    local yawDiffMils, yawMod = AegisOS.canon.calculateShortestPath(AegisOS, prevYaw, targetYawMils)
    local pitchDiffMils, pitchMod = AegisOS.canon.calculateShortestPath(AegisOS, prevPitch, targetPitchMils)
    
    local yawControlName = "Create_SequencedGearshift_" .. yawData.id
    local pitchControlName = "Create_SequencedGearshift_" .. pitchData.id
    
    print("Moving Yaw from (Mils): " .. string.format("%.2f", prevYaw) .. " to " .. string.format("%.2f", targetYawMils))
    print("Rotation: " .. string.format("%.2f", yawDiffMils) .. " mils " .. (yawMod > 0 and "clockwise" or "counterclockwise"))
    
    print("Moving Pitch from (Mils): " .. string.format("%.2f", prevPitch) .. " to " .. string.format("%.2f", targetPitchMils))
    sleep(1)

    modem.callRemote(yawControlName, 'rotate', yawDiffMils * MOTOR_DEGREES_PER_MIL, yawMod)
    modem.callRemote(pitchControlName, 'rotate', pitchDiffMils * MOTOR_DEGREES_PER_MIL, pitchMod)

    while modem.callRemote(yawControlName, "isRunning") or modem.callRemote(pitchControlName, "isRunning") do sleep(0.01) end
    
    AegisOS.redstoneController.redstoneBlink(AegisOS, triggerSide, 5)
    
    AegisOS.canon.savePosition(AegisOS, targetYawMils, targetPitchMils)
    print("Movement complete.")
    sleep(1)
end

function canon.calibrate(AegisOS)
    AegisOS.ui.drawHeader(AegisOS, "Canon Calibration (NATO Mils)")
    -- Prompt user in Degrees for convenience
    local yawDeg = tonumber(AegisOS.ui.prompt(AegisOS, "Enter current physical yaw degrees (0-360):")) or 0
    local pitchDeg = tonumber(AegisOS.ui.prompt(AegisOS, "Enter current physical pitch degrees:")) or 0
    
    local yawMils = toMils(yawDeg)
    local pitchMils = toMils(pitchDeg)
    
    if AegisOS.canon.savePosition(AegisOS, yawMils, pitchMils) then
        AegisOS.ui.showMessage(AegisOS, "Calibration successful! Saved as " .. string.format("%.1f", yawMils) .. " mils.", 2)
    else
        AegisOS.ui.showMessage(AegisOS, "Failed to save calibration data.", 2)
    end
    return yawMils, pitchMils
end

return canon