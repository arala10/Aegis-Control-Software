local redstoneController = {}

function redstoneController.redstoneBlink(AegisOS, side, duration)
    local relay = peripheral.wrap(side.controllerSide)
    sleep(duration / 2)
    relay.setOutput(side.linkSide, not relay.getOutput(side.linkSide))
    sleep(duration / 2)
    relay.setOutput(side.linkSide, not relay.getOutput(side.linkSide))
end

function redstoneController.redstoneToggle(AegisOS, side, toggle)
    local relay = peripheral.wrap(side.controllerSide)
    if relay.getOutput(side.linkSide) == toggle then return end
    redstone.setOutput(side.linkSide, toggle)
end

return redstoneController