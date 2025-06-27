local canon = {}

function canon.getCurrentPosition()
    local state = AegisOS.utils.readFromJsonFile(AegisOS.paths.canonState)
    if not state or not state.currentYaw or not state.currentPitch then
        state = { currentYaw = 0, currentPitch = 0 }
        AegisOS.canon.savePosition(state.currentYaw, state.currentPitch)
    end
    return state.currentYaw, state.currentPitch
end

function canon.savePosition(yaw, pitch)
    local state = { currentYaw = yaw, currentPitch = pitch }
    return AegisOS.utils.writeToJsonFile(state, AegisOS.paths.canonState)
end

function canon.calculateShortestPath(current, target)
    current = current % 360; if current < 0 then current = current + 360 end
    target = target % 360; if target < 0 then target = target + 360 end
    local clockwiseDist = (target - current) % 360
    local counterclockwiseDist = (current - target) % 360
    if clockwiseDist <= counterclockwiseDist then return clockwiseDist, 1 else return counterclockwiseDist, -1 end
end

function canon.moveCanon(yawData, pitchData, triggerSide)
    local modem = peripheral.wrap('bottom')
    triggerSide = triggerSide or "back"
    local prevYaw, prevPitch = AegisOS.canon.getCurrentPosition()
    local yawAngle, yawMod = AegisOS.canon.calculateShortestPath(prevYaw, yawData.angle)
    local pitchAngle, pitchMod = AegisOS.canon.calculateShortestPath(prevPitch, pitchData.angle)
    local yawControlName = "Create_SequencedGearshift_" .. yawData.id
    local pitchControlName = "Create_SequencedGearshift_" .. pitchData.id
    
    print("Moving from Yaw: " .. prevYaw .. " to " .. yawData.angle)
    print("Rotation: " .. yawAngle .. " degrees " .. (yawMod > 0 and "clockwise" or "counterclockwise"))
    print("Moving from Pitch: " .. prevPitch .. " to " .. pitchData.angle)
    print("Rotation: " .. pitchAngle .. " degrees " .. (pitchMod > 0 and "upward" or "downward"))
    sleep(1)

    modem.callRemote(yawControlName, 'rotate', yawAngle * 8, yawMod)
    modem.callRemote(pitchControlName, 'rotate', pitchAngle * 8, pitchMod)

    while modem.callRemote(yawControlName, "isRunning") or modem.callRemote(pitchControlName, "isRunning") do sleep(0.01) end
    
    AegisOS.utils.redstoneBlink(triggerSide, 5)
    AegisOS.canon.savePosition(yawData.angle, pitchData.angle)
    print("Movement complete.")
    sleep(1)
end

function canon.calibrate()
    AegisOS.ui.drawHeader("Canon Calibration")
    local yaw = tonumber(AegisOS.ui.prompt("Enter current physical yaw angle (0-360):")) or 0
    local pitch = tonumber(AegisOS.ui.prompt("Enter current physical pitch angle:")) or 0
    if AegisOS.canon.savePosition(yaw, pitch) then
        AegisOS.ui.showMessage("Calibration successful!", 2)
    else
        AegisOS.ui.showMessage("Failed to save calibration data.", 2)
    end
    return yaw, pitch
end

return canon