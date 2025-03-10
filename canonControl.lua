local canonControl = {}

local prevYaw = 0
local prevPitch = 0

function canonControl.moveCanon(yawData, pitchData, triggerSide)
    local common = require "common"
    local modem = peripheral.wrap('bottom')

    triggerSide = triggerSide or "back"
    
    local yawAngle      = yawData['angle'] - prevYaw
    local yawMod        = (yawAngle > 0) and 1 or -1
    yawAngle = math.abs(yawAngle)

    local pitchAngle    = pitchData['angle'] - prevPitch
    local pitchMod      = (pitchAngle > 0) and 1 or -1
    pitchAngle = math.abs(pitchAngle)


    local yawControllName = "Create_SequencedGearshift_" .. yawData['id']
    local pitchControllName = "Create_SequencedGearshift_" .. pitchData['id']

    modem.callRemote(yawControllName, 'rotate', yawAngle * 8, yawMod)
    modem.callRemote(pitchControllName, 'rotate', pitchAngle * 8, pitchMod)

    while modem.callRemote(yawControllName, "isRunning") or modem.callRemote(pitchControllName, "isRunning") do
        sleep(0.01)
    end

    common.redstoneBlink(triggerSide, 5)

    prevYaw = yawData['angle']
    prevPitch = pitchData['angle']


end


return canonControl