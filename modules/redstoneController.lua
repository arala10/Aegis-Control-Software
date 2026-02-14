local redstoneController = {}

local function getOutputSource(controllerName)
    if not controllerName or controllerName == "computer" or controllerName == "local" then
        return redstone
    else
        return peripheral.wrap(controllerName)
    end
end

function redstoneController.redstoneBlink(AegisOS, signalData, duration)
    local source = getOutputSource(signalData.controllerSide)
    local side = signalData.linkSide
    
    if not source then 
        print("Error: Redstone Controller '"..tostring(signalData.controllerSide).."' not found.")
        return 
    end

    -- Pulse logic: Set to 14, wait, set to 0
    source.setAnalogOutput(side, 14)
    sleep(duration)
    source.setAnalogOutput(side, 0)
end

function redstoneController.redstoneToggle(AegisOS, signalData, toggle)
    local source = getOutputSource(signalData.controllerSide)
    local side = signalData.linkSide
    
    if not source then return end

    if toggle then
        source.setAnalogOutput(side, 14)
    else
        source.setAnalogOutput(side, 0)
    end
end

return redstoneController