local canon = {}

-- RATIOS
-- Coarse Mode: 1:8 (1 Canon Deg = 8 Motor Deg)
local MOUNT_RATIO = 8
-- Precision Mode: 1:8 * 1:100 (1 Canon Deg = 800 Motor Deg)
local PRECISION_RATIO = 800

local modem = peripheral.wrap('bottom')

function canon.getCurrentPosition(AegisOS)
    local config = AegisOS.config.getConfig(AegisOS)
    local readerName = config.blockReaderID or "blockReader_0"
    
    local success, data = pcall(function() 
        return modem.callRemote(readerName, "getBlockData") 
    end)

    local currentYaw = 0
    local currentPitch = 0

    if success and data then
        -- Read Raw Degrees directly from NBT (Yaw/Pitch are standard for CBC Mount)
        currentYaw = data.Yaw or data.CannonYaw or 0
        currentPitch = data.Pitch or data.CannonPitch or 0
    else
        -- Fallback to state file if Block Reader is missing or fails
        local state = AegisOS.utils.readFromJsonFile(AegisOS, AegisOS.paths.canonState)
        currentYaw = state.currentYaw or 0
        currentPitch = state.currentPitch or 0
        
        term.setCursorPos(1,1)
        term.write("WARN: Sensor Offline - Using Cached State")
    end
    return currentYaw, currentPitch
end

function canon.savePosition(AegisOS, yaw, pitch)
    local state = { currentYaw = yaw, currentPitch = pitch }
    return AegisOS.utils.writeToJsonFile(AegisOS, state, AegisOS.paths.canonState)
end

function canon.calculateShortestPath(current, target)
    -- Normalize to 0-360 range
    current = current % 360
    if current < 0 then current = current + 360 end
    target = target % 360
    if target < 0 then target = target + 360 end
    
    local clockwiseDist = (target - current) % 360
    local counterclockwiseDist = (current - target) % 360
    
    if clockwiseDist <= counterclockwiseDist then
        return clockwiseDist, 1 -- 1 for clockwise
    else
        return counterclockwiseDist, -1 -- -1 for counter-clockwise
    end
end

function canon.moveCanon(AegisOS, yawData, pitchData, redstoneSides)
    local triggerSide = redstoneSides.trigger
    local precisionSide = redstoneSides.precision
    
    -- 1. Get Physical Position
    local startYaw, startPitch = AegisOS.canon.getCurrentPosition(AegisOS)
    
    -- 2. Calculate Total Movement Needed
    local yawDiff, yawMod = AegisOS.canon.calculateShortestPath(startYaw, yawData.angle)
    local pitchDiff = math.abs(pitchData.angle - startPitch)
    local pitchMod = (pitchData.angle > startPitch) and 1 or -1

    local yawName = "Create_SequencedGearshift_" .. yawData.id
    local pitchName = "Create_SequencedGearshift_" .. pitchData.id

    print("--- FIRE MISSION ---")
    print(string.format("Target: Y %.3f, P %.3f", yawData.angle, pitchData.angle))

    -- Extract Coarse (Integer) and Fine (Fractional) parts correctly
    local yawCoarse = math.floor(yawDiff)
    local yawFine = yawDiff - yawCoarse

    local pitchCoarse = math.floor(pitchDiff)
    local pitchFine = pitchDiff - pitchCoarse

    -- === STAGE 1: COARSE MOVE (High Speed) ===
    -- Ensure Precision Clutch is DISENGAGED
    if precisionSide then
        AegisOS.redstoneController.redstoneToggle(AegisOS, precisionSide, false) 
        sleep(0.2) 
    end

    if yawCoarse > 0 or pitchCoarse > 0 then
        print(string.format(">> Coarse: Yaw %d, Pitch %d", yawCoarse, pitchCoarse))
        
        local yRot = math.floor(yawCoarse * MOUNT_RATIO + 0.5)
        local pRot = math.floor(pitchCoarse * MOUNT_RATIO + 0.5)
        
        if yRot > 0 then modem.callRemote(yawName, 'rotate', yRot, yawMod) end
        if pRot > 0 then modem.callRemote(pitchName, 'rotate', pRot, pitchMod) end
        
        -- Wait for mechanical completion
        while modem.callRemote(yawName, "isRunning") or modem.callRemote(pitchName, "isRunning") do 
            sleep(0.05) 
        end
    end

    sleep(5.0)

    -- === STAGE 2: FINE MOVE (Precision 1:100 Gear) ===
    -- Only attempt if decimal adjustment is required and precision gear is configured
    if (yawFine > 0.0001 or pitchFine > 0.0001) and precisionSide then
        -- ENGAGE Precision Clutch
        AegisOS.redstoneController.redstoneToggle(AegisOS, precisionSide, true)
        sleep(1.0) 

        print(string.format(">> Fine: Yaw %.3f, Pitch %.3f", yawFine, pitchFine))
        
        -- Use 800 Ratio (8 * 100)
        local yRotFine = math.floor(yawFine * PRECISION_RATIO + 0.5)
        local pRotFine = math.floor(pitchFine * PRECISION_RATIO + 0.5)
        
        if yRotFine > 0 then modem.callRemote(yawName, 'rotate', yRotFine, yawMod) end
        if pRotFine > 0 then modem.callRemote(pitchName, 'rotate', pRotFine, pitchMod) end

        while modem.callRemote(yawName, "isRunning") or modem.callRemote(pitchName, "isRunning") do 
            sleep(0.05) 
        end

        -- DISENGAGE Precision Clutch
        AegisOS.redstoneController.redstoneToggle(AegisOS, precisionSide, false)
        sleep(1.0)
    end

    -- 3. Trigger Firing Sequence
    if triggerSide then
        print(">> Firing!")
        AegisOS.redstoneController.redstoneBlink(AegisOS, triggerSide, 5)
    end
    
    -- 4. Finalize
    AegisOS.canon.savePosition(AegisOS, yawData.angle, pitchData.angle)
    print("Mission complete.")
    sleep(1)
end

function canon.calibrate(AegisOS)
    AegisOS.ui.drawHeader(AegisOS, "Canon Calibration")
    local yaw = tonumber(AegisOS.ui.prompt(AegisOS, "Current physical Yaw (Deg):")) or 0
    local pitch = tonumber(AegisOS.ui.prompt(AegisOS, "Current physical Pitch (Deg):")) or 0
    AegisOS.canon.savePosition(AegisOS, yaw, pitch)
    AegisOS.ui.showMessage(AegisOS, "Calibration Saved.", 2)
end

return canon