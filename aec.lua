local common = require "common"
local controls = require "canonControl"

while true do
    common.redstoneToggle('top', true)
    common.termClear()
    print("=====Aegis Controll=====")
    print("1. Fire Mission")
    print("2. Manual Override")
    print("3. Modifie Parameter")
    print("4. Shutdow")
    print("=====Select Option=====")
    local intOpt = tonumber(read())
    if intOpt == 1 then
        shell.run("fireMissionManager.lua")
    elseif intOpt == 2 then
        common.termClear()
        print("Insert Yaw")
        local yawAngle = tonumber(read())
        print("Insert Pitch")
        local pitchAngle = tonumber(read())

        local yawData = {}
        local pitchData = {}

        yawData['angle'] = yawAngle
        yawData['id'] = 0

        pitchData['angle'] = pitchAngle
        pitchData['id'] = 1

        controls.moveCanon(yawData, pitchData, "back")

    elseif intOpt == 3 then
    elseif intOpt == 4 then
        common.termClear()
        print("Shutting down...")
        common.redstoneToggle('top', false)
        sleep(2)
        common.termClear()
        return
    end
end