local AegisOS = {
    version = "1.4.0",
    modules = {},
    paths = {
        config = "data/config.json",
        missionTable = "data/mission_table.json",
        canonState = "data/canon_state.json",
        logo = "data/logo.txt"
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

AegisOS.utils = {}

function AegisOS.utils.clearScreen()
    term.clear()
    term.setCursorPos(1,1)
end

function AegisOS.utils.redstoneBlink(side, duration)
    sleep(duration / 2)
    redstone.setOutput(side, not redstone.getOutput(side))
    sleep(duration / 2)
    redstone.setOutput(side, not redstone.getOutput(side))
end

function AegisOS.utils.redstoneToggle(side, toggle)
    if redstone.getOutput(side) == toggle then
        return
    end
    redstone.setOutput(side, toggle)
end

function AegisOS.utils.readFromJsonFile(filePath)
    if not fs.exists(filePath) then
        return {}
    end
    
    local file = fs.open(filePath, "r")
    if not file then
        return {}
    end
    
    local content = file.readAll()
    file.close()
    
    local success, data = pcall(textutils.unserializeJSON, content)
    if not success or type(data) ~= "table" then
        return {}
    end
    
    return data
end

function AegisOS.utils.writeToJsonFile(data, filePath)
    if not data or type(data) ~= "table" then
        return false
    end
    
    
    local parentDir = string.match(filePath, "(.-)/[^/]+$")
    if parentDir and not fs.exists(parentDir) then
        fs.makeDir(parentDir)
    end
    
    local success, serialized = pcall(textutils.serializeJSON, data)
    if not success then
        return false
    end
    
    local file = fs.open(filePath, "w")
    if not file then
        return false
    end
    
    file.write(serialized)
    file.close()
    
    return true
end

function AegisOS.utils.renderAsciiArt(filePath)
    if not fs.exists(filePath) then
        return false
    end
    
    local file = fs.open(filePath, "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    print(content)
    return true
end

function AegisOS.utils.renderCenteredAsciiArt(filePath)
    if not fs.exists(filePath) then
        return false
    end
    
    local file = fs.open(filePath, "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    local termWidth, termHeight = term.getSize()
    local lines = {}
    
    
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    
    local maxWidth = 0
    for _, line in ipairs(lines) do
        maxWidth = math.max(maxWidth, #line)
    end
    
    
    local startY = math.max(1, math.floor((termHeight - #lines) / 3))
    
    
    term.clear()
    for i, line in ipairs(lines) do
        local startX = math.floor((termWidth - #line) / 2)
        term.setCursorPos(startX, startY + i - 1)
        term.write(line)
    end
    
    return true, startY + #lines  
end

function AegisOS.utils.renderLoadingBar(startY, width, steps, message)
    local termWidth, _ = term.getSize()
    local barWidth = width or 40
    local startX = math.floor((termWidth - barWidth) / 2)
    local steps = steps or 20
    local message = message or "Loading AegisOS"
    
    
    local msgX = math.floor((termWidth - #message) / 2)
    term.setCursorPos(msgX, startY + 1)
    term.write(message)
    
    
    term.setCursorPos(startX, startY + 3)
    term.write("[" .. string.rep(" ", barWidth - 2) .. "]")
    
    
    for i = 1, barWidth - 2 do
        term.setCursorPos(startX + i, startY + 3)
        term.write("=")
        
        
        local percentage = math.floor((i / (barWidth - 2)) * 100)
        local versionText = "v" .. AegisOS.version .. " - " .. percentage .. "%"
        local versionX = math.floor((termWidth - #versionText) / 2)
        
        term.setCursorPos(versionX, startY + 5)
        term.write(versionText)
        
        
        local sleepTime = 0.1 - (0.08 * (i / (barWidth - 2)))
        sleep(sleepTime)
    end
    
    
    local completionMessage = "System Initialization Complete"
    local completionX = math.floor((termWidth - #completionMessage) / 2)
    
    term.setCursorPos(msgX, startY + 1)
    term.write(string.rep(" ", #message))  
    term.setCursorPos(completionX, startY + 1)
    term.write(completionMessage)
    
    sleep(1)
    return startY + 6  
end

AegisOS.ui = {}

function AegisOS.ui.drawHeader(title)
    local w, h = term.getSize()
    local titleX = math.floor((w - #title) / 2)
    
    AegisOS.utils.clearScreen()
    term.setCursorPos(1, 1)
    term.write(string.rep("=", w))
    term.setCursorPos(titleX, 1)
    term.write(title)
    term.setCursorPos(1, 2)
    term.write(string.rep("=", w))
    term.setCursorPos(1, 4)
end

function AegisOS.ui.showMenu(title, options)
    AegisOS.ui.drawHeader(title)
    
    local selectedOption = 1
    local running = true
    local w, h = term.getSize()
    
    
    local function drawMenu()
        
        for i = 4, h do
            term.setCursorPos(1, i)
            term.write(string.rep(" ", w))
        end
        
        term.setCursorPos(1, 4)
        for i, option in ipairs(options) do
            if i == selectedOption then
                print("[ " .. option .. " ]")
            else
                print("  " .. option .. "  ")
            end
        end
        
        term.setCursorPos(1, h)
        term.write("Use Up/Down arrows or W/S keys to navigate, Enter to select")
    end
    
    
    drawMenu()
    
    
    while running do
        local event, key = os.pullEvent("key")
        
        
        if key == keys.up or key == keys.w then
            selectedOption = selectedOption > 1 and selectedOption - 1 or #options
            drawMenu()
        elseif key == keys.down or key == keys.s then
            selectedOption = selectedOption < #options and selectedOption + 1 or 1
            drawMenu()
        elseif key == keys.enter then
            running = false
        end
    end
    
    return selectedOption
end

function AegisOS.ui.prompt(message, defaultValue)
    print(message)
    local input = read()
    
    if input == "" and defaultValue ~= nil then
        return defaultValue
    end
    
    return input
end

function AegisOS.ui.showMessage(message, pause)
    print(message)
    if pause then
        sleep(pause)
    else
        print("\nPress Enter to continue...")
        read()
    end
end


function AegisOS.ui.selectFromList(title, items, displayFunc)
    AegisOS.ui.drawHeader(title)
    
    if #items == 0 then
        AegisOS.ui.showMessage("No items found.", 2)
        return nil
    end
    
    local selectedItem = 1
    local startIndex = 1
    local maxDisplay = 10  
    local running = true
    local w, h = term.getSize()
    
    
    local function displayItem(item, index, isSelected)
        local prefix = isSelected and "[ " or "  "
        local suffix = isSelected and " ]" or "  "
        
        if displayFunc then
            return prefix .. displayFunc(item, index) .. suffix
        else
            return prefix .. tostring(item) .. suffix
        end
    end
    
    
    local function drawList()
        
        for i = 4, h-2 do
            term.setCursorPos(1, i)
            term.write(string.rep(" ", w))
        end
        
        
        local endIndex = math.min(startIndex + maxDisplay - 1, #items)
        for i = startIndex, endIndex do
            term.setCursorPos(1, 4 + (i - startIndex))
            print(displayItem(items[i], i, i == selectedItem))
        end
        
        
        term.setCursorPos(1, h-1)
        term.write(string.rep("-", w))
        term.setCursorPos(1, h)
        term.write("Use Up/Down arrows to navigate, Enter to select, Esc to cancel")
        
        
        if #items > maxDisplay then
            local pageInfo = "Page " .. math.ceil(startIndex/maxDisplay) .. "/" .. math.ceil(#items/maxDisplay)
            term.setCursorPos(w - #pageInfo, h-1)
            term.write(pageInfo)
        end
    end
    
    
    drawList()
    
    
    while running do
        local event, key = os.pullEvent("key")
        
        
        if key == keys.up or key == keys.w then
            selectedItem = selectedItem > 1 and selectedItem - 1 or #items
            
            
            if selectedItem < startIndex then
                startIndex = selectedItem
            end
            
            drawList()
        elseif key == keys.down or key == keys.s then
            selectedItem = selectedItem < #items and selectedItem + 1 or 1
            
            
            if selectedItem >= startIndex + maxDisplay then
                startIndex = selectedItem - maxDisplay + 1
            end
            
            drawList()
        elseif key == keys.pageUp then
            startIndex = math.max(1, startIndex - maxDisplay)
            selectedItem = startIndex
            drawList()
        elseif key == keys.pageDown then
            startIndex = math.min(#items - maxDisplay + 1, startIndex + maxDisplay)
            if startIndex < 1 then startIndex = 1 end
            selectedItem = startIndex
            drawList()
        elseif key == keys.enter then
            running = false
            return selectedItem, items[selectedItem]
        elseif key == keys.escape then
            running = false
            return nil
        end
    end
    
    return nil
end


AegisOS.config = {}

function AegisOS.config.getConfig()
    local config = AegisOS.utils.readFromJsonFile(AegisOS.paths.config)
    
    
    local defaultConfig = {
        centerPoint = { x = 0, y = 0, z = 0 },
        muzzlePoint = { x = 0, y = 0, z = 0 },
        physics = {
            initialSpeed = 160.0,
            barrelLength = 9, 
            environmentDensity = 1.0,
            gravityMultiplier = 1.0
        },
        gearShiftIDs = {yaw = 0, pitch = 1},
        redstoneDirections = {trigger = "back", power = "top"}

    }
    
    
    if not config then
        config = defaultConfig
        AegisOS.config.saveConfig(config)
    else
        
        if not config.centerPoint then config.centerPoint = defaultConfig.centerPoint end
        if not config.muzzlePoint then config.muzzlePoint = defaultConfig.muzzlePoint end
        
        
        if not config.physics then
            config.physics = defaultConfig.physics
        else
            
            if not config.physics.initialSpeed then config.physics.initialSpeed = defaultConfig.physics.initialSpeed end
            if not config.physics.barrelLength then config.physics.barrelLength = defaultConfig.physics.barrelLength end
            if not config.physics.environmentDensity then config.physics.environmentDensity = defaultConfig.physics.environmentDensity end
            if not config.physics.gravityMultiplier then config.physics.gravityMultiplier = defaultConfig.physics.gravityMultiplier end
        end
        
        if not config.gearShiftIDs then
            config.gearShiftIDs = defaultConfig.gearShiftIDs
        else
            if not config.gearShiftIDs.yaw then config.gearShiftIDs.yaw = defaultConfig.gearShiftIDs.yaw end
            if not config.gearShiftIDs.pitch then config.gearShiftIDs.pitch = defaultConfig.gearShiftIDs.pitch end
        end
        
        if not config.redstoneDirections then
            config.redstoneDirections = defaultConfig.redstoneDirections
        else
            if not config.redstoneDirections.trigger then config.redstoneDirections.trigger = defaultConfig.redstoneDirections.trigger end
            if not config.redstoneDirections.power then config.redstoneDirections.power = defaultConfig.redstoneDirections.power end
        end

        
        AegisOS.config.saveConfig(config)
    end
    
    return config
end

function AegisOS.config.saveConfig(config)
    return AegisOS.utils.writeToJsonFile(config, AegisOS.paths.config)
end

function AegisOS.config.modifyPoint(pointName, currentPoint)
    AegisOS.utils.clearScreen()
    print("Current " .. pointName .. ":")
    print("X: " .. (currentPoint.x or 0))
    print("Y: " .. (currentPoint.y or 0))
    print("Z: " .. (currentPoint.z or 0))
    print("\nEnter new values (leave blank to keep current):")
    
    print("Enter X coordinate:")
    local x = read()
    if x ~= "" then currentPoint.x = tonumber(x) end
    
    print("Enter Y coordinate:")
    local y = read()
    if y ~= "" then currentPoint.y = tonumber(y) end
    
    print("Enter Z coordinate:")
    local z = read()
    if z ~= "" then currentPoint.z = tonumber(z) end
    
    return currentPoint
end


function AegisOS.config.modifyPhysics(currentPhysics)
    AegisOS.utils.clearScreen()
    print("Current Physics Parameters:")
    print("Initial Speed: " .. (currentPhysics.initialSpeed or 160.0))
    print("Barrel Length: " .. (currentPhysics.barrelLength or 9))
    print("Environment Density: " .. (currentPhysics.environmentDensity or 1.0))
    print("Gravity Multiplier: " .. (currentPhysics.gravityMultiplier or 1.0))
    print("\nEnter new values (leave blank to keep current):")
    
    print("Enter Initial Speed (default 160.0):")
    local speed = read()
    if speed ~= "" then currentPhysics.initialSpeed = tonumber(speed) end
    
    print("Enter Barrel Length (default 9):")
    local length = read()
    if length ~= "" then currentPhysics.barrelLength = tonumber(length) end
    
    print("Enter Environment Density (default 1.0):")
    local density = read()
    if density ~= "" then currentPhysics.environmentDensity = tonumber(density) end
    
    print("Enter Gravity Multiplier (default 1.0):")
    local gravity = read()
    if gravity ~= "" then currentPhysics.gravityMultiplier = tonumber(gravity) end
    
    return currentPhysics
end

function AegisOS.config.modifyGearshiftIDs(currentIDs)
    AegisOS.utils.clearScreen()
    print("Current Gearshift ID Parameters:")
    print("Yaw Sequenced GearShift Id: " .. (currentIDs.yaw or 0))
    print("Pitch Sequenced GearShift Id: " .. (currentIDs.pitch or 0))
    print("\nEnter new values (leave blank to keep current):")
    
    print("Enter Yaw Sequenced Gearshift Id:")
    local yawId = read()
    if yawId ~= "" then currentIDs.yaw = tonumber(yawId) end
    
    print("Enter Pitch Sequenced Gearshift Id:")
    local pitchId = read()
    if pitchId ~= "" then currentIDs.pitch = tonumber(pitchId) end

    return currentIDs
end

function AegisOS.config.modifyRedstoneDirection(currentDirections)
    AegisOS.utils.clearScreen()
    print("Current Redstone Directions Parameters:")
    print("Trigger Redstone Direction: " .. (currentDirections.trigger or "back"))
    print("Power Redstone Direction: " .. (currentDirections.power or "top"))
    print("\nEnter new values (leave blank to keep current):")
    local directionMatrix = {}
    directionMatrix[1] = "top"
    directionMatrix[2] = "right"
    directionMatrix[3] = "bottom"
    directionMatrix[4] = "left"
    directionMatrix[5] = "back"

    print("Enter Redstone Directions for Trigger:")
    local triggerDir = read()
    if triggerDir ~= "" then currentDirections.trigger = directionMatrix[tonumber(triggerDir)] end
    
    print("Enter Redstone Directions for Power:")
    local powerDir = read()
    if powerDir ~= "" then currentDirections.power = directionMatrix[tonumber(powerDir)] end

    return currentDirections
    
end


AegisOS.canon = {}

function AegisOS.canon.getCurrentPosition()
    local state = AegisOS.utils.readFromJsonFile(AegisOS.paths.canonState)
    
    if not state or not state.currentYaw or not state.currentPitch then
        state = {
            currentYaw = 0,
            currentPitch = 0
        }
        AegisOS.canon.savePosition(state.currentYaw, state.currentPitch)
    end
    
    return state.currentYaw, state.currentPitch
end

function AegisOS.canon.savePosition(yaw, pitch)
    local state = {
        currentYaw = yaw,
        currentPitch = pitch
    }
    return AegisOS.utils.writeToJsonFile(state, AegisOS.paths.canonState)
end

function AegisOS.canon.calculateShortestPath(current, target)
    
    current = current % 360
    if current < 0 then current = current + 360 end
    
    target = target % 360
    if target < 0 then target = target + 360 end
    
    
    local clockwiseDist = (target - current) % 360
    local counterclockwiseDist = (current - target) % 360
    
    
    if clockwiseDist <= counterclockwiseDist then
        return clockwiseDist, 1  
    else
        return counterclockwiseDist, -1  
    end
end

function AegisOS.canon.moveCanon(yawData, pitchData, triggerSide)
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

    while modem.callRemote(yawControlName, "isRunning") or modem.callRemote(pitchControlName, "isRunning") do
        sleep(0.01)
    end

    AegisOS.utils.redstoneBlink(triggerSide, 5)

    
    AegisOS.canon.savePosition(yawData.angle, pitchData.angle)
    print("Movement complete.")
    sleep(1)
end

function AegisOS.canon.calibrate()
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


AegisOS.ballistics = {}

function AegisOS.ballistics.simulateProjectile(start_pos, initial_velocity, env_density, gravity_multiplier, targetY, verbose)
    local pos = vector.new(start_pos[1], start_pos[2], start_pos[3])
    local vel = vector.new(initial_velocity[1], initial_velocity[2], initial_velocity[3])
    local gravity = vector.new(0, -gravity_multiplier * AegisOS.constants.GRAVITY, 0)
  
    local trajectory = {vector.new(pos.x, pos.y, pos.z), vector.new(vel.x, vel.y, vel.z)}
  
    if verbose == nil then verbose = false end
  
    for tick = 1, AegisOS.constants.MAX_ITERATIONS do
        local vel_sq = vel.x^2 + vel.y^2 + vel.z^2
        if vel_sq < 1e-6 then
            if verbose then print(string.format("Stopped at tick %d: velocity below threshold", tick)) end
            break
        end

        local normalized_vel = vel:normalize()
        local drag_force = normalized_vel:mul(-env_density * AegisOS.constants.DRAG * vel:length())
        local accel = drag_force + gravity

        local next_pos = pos + vel + accel:mul(0.5)
        local next_vel = vel + accel

        if next_pos.y < targetY then
            local dy = next_pos - pos
            local impact_pos = pos
            if dy.y ~= 0 then
                local alpha = (targetY - pos.y) / dy.y
                impact_pos = pos + dy:mul(alpha)
                if verbose then print(string.format("Hit 'ground' (targetY) at tick %d @ %.3f, %.3f, %.3f", tick + 1, impact_pos.x, impact_pos.y, impact_pos.z)) end
            else
                impact_pos = next_pos
                if verbose then print(string.format("Hit 'ground' (targetY) at tick %d @ %.3f, %.3f, %.3f", tick + 1, next_pos.x, next_pos.y, next_pos.z)) end
            end
            table.insert(trajectory, vector.new(impact_pos.x, impact_pos.y, impact_pos.z))
            break
        end

        pos = next_pos
        vel = next_vel
        table.insert(trajectory, vector.new(pos.x, pos.y, pos.z))
        table.insert(trajectory, vector.new(vel.x, vel.y, vel.z))
    end
  
    if verbose then
      print(string.format("Final Position: %.3f, %.3f, %.3f", pos.x, pos.y, pos.z))
    end
  
    return trajectory
end

function AegisOS.ballistics.calculatePitchForTarget(startX, startY, startZ, targetX, targetY, targetZ, yawAngle)
    local config = AegisOS.config.getConfig()
    local env_density = config.physics.environmentDensity
    local gravity_multiplier = config.physics.gravityMultiplier
    local initial_speed = config.physics.initialSpeed
    local barrelLength = config.physics.barrelLength

    local dx = targetX - startX
    local dz = targetZ - startZ
    local horizontalDistance = math.sqrt(dx^2 + dz^2)
    local dirX, dirZ = dx / horizontalDistance, dz / horizontalDistance
    
    local yawRad = math.rad(yawAngle)
    local forwardVec = vector.new(math.sin(yawRad), 0, math.cos(yawRad))
    local tipOffset = forwardVec * 0.5
    local centerX = config.centerPoint.x
    local centerZ = config.centerPoint.z
    
    local bestAngle = nil
    local minError = math.huge
    
    local steps = {
        {min = -30, max = 60, step = 5},
        {min = 0, max = 0, step = 0.45}
    }
    
    for pass = 1, 2 do
        local searchParams = steps[pass]
        
        if pass == 2 and bestAngle then
            searchParams.min = math.max(0, bestAngle - 5)
            searchParams.max = math.min(60, bestAngle + 5)
        elseif pass == 2 and not bestAngle then
            break
        end
        
        for angle = searchParams.min, searchParams.max, searchParams.step do
            local angleRad = math.rad(angle)
            
            local cosAngle = math.cos(angleRad)
            local sinAngle = math.sin(angleRad)
            local vx = initial_speed * cosAngle * dirX
            local vy = initial_speed * sinAngle
            local vz = initial_speed * cosAngle * dirZ
            
            local pitchVecY = barrelLength * sinAngle
            local forwardOffset = forwardVec * (barrelLength * cosAngle)
            
            local simStartX = centerX + forwardOffset.x + tipOffset.x
            local simStartZ = centerZ + forwardOffset.z + tipOffset.z
            local simStartY = startY + pitchVecY

            local trajectory = AegisOS.ballistics.simulateProjectile(
                {simStartX, simStartY, simStartZ},
                {vx, vy, vz},
                env_density,
                gravity_multiplier,
                targetY
            )

            if #trajectory > 0 then
                local finalPos = trajectory[#trajectory]
                if finalPos and finalPos.x and finalPos.z then
                    local distError = math.sqrt((finalPos.x - targetX)^2 + (finalPos.y - targetY)^2 + (finalPos.z - targetZ)^2)
                    
                    if distError < minError then
                        minError = distError
                        bestAngle = angle
                    end
                end
            end
        end
    end
    
    return bestAngle or 15, minError
end


function AegisOS.ballistics.findYaw(targetPoint)
    local config = AegisOS.config.getConfig()

    local basePoint = vector.new(config.centerPoint.x, 0, config.centerPoint.z)
    local muzzleEndPoint = vector.new(config.muzzlePoint.x, 0, config.muzzlePoint.z)

    local forwardVector = muzzleEndPoint - basePoint
    forwardVector = forwardVector:normalize()
    
    local targetVector = targetPoint - basePoint
    targetVector = targetVector:normalize()

    
    local dotProduct = forwardVector:dot(targetVector)
    local radian_angle = math.acos(math.min(1, math.max(-1, dotProduct)))
    
    
    local crossProduct = forwardVector.x * targetVector.z - forwardVector.z * targetVector.x
    
    
    if crossProduct < 0 then
        radian_angle = -radian_angle
    end
    
    return math.deg(radian_angle)
end


AegisOS.missions = {}

function AegisOS.missions.getMissions()
    return AegisOS.utils.readFromJsonFile(AegisOS.paths.missionTable) or {}
end

function AegisOS.missions.saveMissions(missions)
    return AegisOS.utils.writeToJsonFile(missions, AegisOS.paths.missionTable)
end

function AegisOS.missions.addMission()
    AegisOS.ui.drawHeader("Add Fire Mission")
    
    local targetX = tonumber(AegisOS.ui.prompt("Enter Target X Coordinate:"))
    local targetY = tonumber(AegisOS.ui.prompt("Enter Target Y Coordinate:"))
    local targetZ = tonumber(AegisOS.ui.prompt("Enter Target Z Coordinate:"))
    
    local munitionType = AegisOS.ui.prompt("Enter Munition Type (solid, explosive, incendiary):", "solid")
    
    local mission = {
        point = {
            x = targetX,
            y = targetY,
            z = targetZ
        },
        munition = munitionType
    }
    
    local missions = AegisOS.missions.getMissions()
    table.insert(missions, mission)
    
    if AegisOS.missions.saveMissions(missions) then
        AegisOS.ui.showMessage("Fire mission added successfully!", 2)
    else
        AegisOS.ui.showMessage("Failed to add fire mission.", 2)
    end
end

function AegisOS.missions.listMissions()
    AegisOS.ui.drawHeader("Fire Mission List")
    
    local missions = AegisOS.missions.getMissions()
    
    if #missions == 0 then
        AegisOS.ui.showMessage("No fire missions found.", 2)
        return
    end
    
    
    local function displayMission(mission, index)
        return "Mission #" .. index .. ": X=" .. mission.point.x .. 
               ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. 
               " (" .. mission.munition .. ")"
    end
    
    
    local selection = AegisOS.ui.selectFromList("Fire Mission List", missions, displayMission)
    
    if selection then
        local mission = missions[selection]
        AegisOS.ui.drawHeader("Mission Details")
        print("Mission #" .. selection)
        print("  Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
        print("  Munition: " .. mission.munition)
        AegisOS.ui.showMessage("")
    end
end

function AegisOS.missions.editMission()
    AegisOS.ui.drawHeader("Edit Fire Mission")
    
    local missions = AegisOS.missions.getMissions()
    
    if #missions == 0 then
        AegisOS.ui.showMessage("No fire missions found.", 2)
        return
    end
    
    
    local function displayMission(mission, index)
        return "Mission #" .. index .. ": X=" .. mission.point.x .. 
               ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. 
               " (" .. mission.munition .. ")"
    end
    
    
    local selection = AegisOS.ui.selectFromList("Select Mission to Edit", missions, displayMission)
    
    if not selection then
        return
    end
    
    local mission = missions[selection]
    AegisOS.utils.clearScreen()
    print("Editing Mission #" .. selection)
    print("Current Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
    print("Current Munition: " .. mission.munition)
    print("\nEnter new values (leave blank to keep current):")
    
    local x = AegisOS.ui.prompt("Enter X coordinate:")
    if x ~= "" then mission.point.x = tonumber(x) end
    
    local y = AegisOS.ui.prompt("Enter Y coordinate:")
    if y ~= "" then mission.point.y = tonumber(y) end
    
    local z = AegisOS.ui.prompt("Enter Z coordinate:")
    if z ~= "" then mission.point.z = tonumber(z) end
    
    local munitionType = AegisOS.ui.prompt("Enter Munition Type (solid, explosive, incendiary):")
    if munitionType ~= "" then mission.munition = munitionType end
    
    if AegisOS.missions.saveMissions(missions) then
        AegisOS.ui.showMessage("Fire mission updated successfully!", 2)
    else
        AegisOS.ui.showMessage("Failed to update fire mission.", 2)
    end
end

function AegisOS.missions.deleteMission()
    AegisOS.ui.drawHeader("Delete Fire Mission")
    
    local missions = AegisOS.missions.getMissions()
    
    if #missions == 0 then
        AegisOS.ui.showMessage("No fire missions found.", 2)
        return
    end
    
    
    local function displayMission(mission, index)
        return "Mission #" .. index .. ": X=" .. mission.point.x .. 
               ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. 
               " (" .. mission.munition .. ")"
    end
    
    
    local displayOptions = {}
    for i, mission in ipairs(missions) do
        table.insert(displayOptions, mission)
    end
    table.insert(displayOptions, {special = "delete_all"})
    
    
    local function displayOption(item, index)
        if item.special and item.special == "delete_all" then
            return "DELETE ALL MISSIONS"
        else
            return displayMission(item, index)
        end
    end
    
    
    local selection, selectedItem = AegisOS.ui.selectFromList("Select Mission to Delete", displayOptions, displayOption)
    
    if not selection then
        return
    end
    
    
    if selectedItem.special and selectedItem.special == "delete_all" then
        AegisOS.ui.drawHeader("Confirm Delete All")
        print("Are you sure you want to delete ALL missions?")
        print("This action cannot be undone.")
        
        local options = {"Yes, delete all missions", "No, cancel deletion"}
        local confirm = AegisOS.ui.showMenu("Confirm Delete All", options)
        
        if confirm == 1 then
            if AegisOS.missions.saveMissions({}) then
                AegisOS.ui.showMessage("All fire missions deleted successfully!", 2)
            else
                AegisOS.ui.showMessage("Failed to delete fire missions.", 2)
            end
        else
            AegisOS.ui.showMessage("Deletion cancelled.", 2)
        end
    else
        
        local actualIndex = selection
        if selection > #missions then
            return
        end
        
        AegisOS.ui.drawHeader("Confirm Delete")
        print("Are you sure you want to delete mission #" .. actualIndex .. "?")
        local mission = missions[actualIndex]
        print("Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
        print("Munition: " .. mission.munition)
        
        local options = {"Yes, delete this mission", "No, cancel deletion"}
        local confirm = AegisOS.ui.showMenu("Confirm Delete", options)
        
        if confirm == 1 then
            table.remove(missions, actualIndex)
            if AegisOS.missions.saveMissions(missions) then
                AegisOS.ui.showMessage("Fire mission deleted successfully!", 2)
            else
                AegisOS.ui.showMessage("Failed to delete fire mission.", 2)
            end
        else
            AegisOS.ui.showMessage("Deletion cancelled.", 2)
        end
    end
end

function AegisOS.missions.executeMissions()
    AegisOS.ui.drawHeader("Execute Fire Missions")
    
    local missions = AegisOS.missions.getMissions()
    local config = AegisOS.config.getConfig()
    
    if #missions == 0 then
        AegisOS.ui.showMessage("No fire missions found.", 2)
        return
    end
    
    
    local function displayMission(mission, index)
        return "Mission #" .. index .. ": X=" .. mission.point.x .. 
               ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. 
               " (" .. mission.munition .. ")"
    end
    
    
    local options = {
        "Execute All Missions",
        "Select Single Mission to Execute",
        "Cancel Execution"
    }
    
    local choice = AegisOS.ui.showMenu("Execute Fire Missions", options)
    
    if choice == 3 then
        return
    elseif choice == 2 then
        
        local selection = AegisOS.ui.selectFromList("Select Mission to Execute", missions, displayMission)
        if not selection then
            return
        end
        
        local singleMission = {missions[selection]}
        missions = singleMission
    end
    
    
    print("Total Missions to Execute: " .. #missions)
    print("Starting execution in 3 seconds...")
    sleep(3)
    
    for index, mission in ipairs(missions) do
        AegisOS.utils.clearScreen()
        print("Executing Mission #" .. index)
        print("Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
        print("Munition: " .. mission.munition)
        print("Using physics parameters:")
        print("- Initial Speed: " .. config.physics.initialSpeed)
        print("- Barrel Length: " .. config.physics.barrelLength)
        print("- Environment Density: " .. config.physics.environmentDensity)
        print("- Gravity Multiplier: " .. config.physics.gravityMultiplier)
        


        
        local targetPoint = vector.new(mission.point.x, 0, mission.point.z)
        local yawAngle = AegisOS.ballistics.findYaw(targetPoint)
        
        
        local targetX = mission.point.x
        local targetY = mission.point.y or 0
        local targetZ = mission.point.z
        local startX = config.centerPoint.x + config.physics.barrelLength * math.sin(math.rad(yawAngle))
        local startY = config.centerPoint.y - 0.5
        local startZ = config.centerPoint.z + config.physics.barrelLength * math.cos(math.rad(yawAngle))
        
        
        print("Calculating optimal pitch angle...")
        local pitchAngle, expectedError = AegisOS.ballistics.calculatePitchForTarget(
            startX, startY, startZ,
            targetX, targetY, targetZ, yawAngle
        )
        
        print("Calculated Yaw: " .. string.format("%.2f", yawAngle) .. "°")
        print("Calculated Pitch: " .. string.format("%.2f", pitchAngle) .. "°")
        print("Expected accuracy: " .. string.format("%.2f", expectedError) .. " blocks")
        sleep(1)
        
        local yawGearShiftId = config.gearShiftIDs.yaw
        local pitchGearShiftId = config.gearShiftIDs.pitch

        local yawData = {
            angle = yawAngle,
            id = yawGearShiftId
        }
        
        local pitchData = {
            angle = pitchAngle,
            id = pitchGearShiftId
        }
        
        local triggerSide = config.redstoneDirections.trigger

        print("Moving cannon...")
        AegisOS.canon.moveCanon(yawData, pitchData, triggerSide)
        print("Fire mission completed!")
        
        
        if index < #missions then
            print("\nPress Enter to continue to next mission...")
            read()
        else
            sleep(2)
        end
    end
    
    AegisOS.ui.showMessage("All fire missions executed successfully!", 2)
end


AegisOS.apps = {}

function AegisOS.apps.fireMissionManager()
    while true do
        local choice = AegisOS.ui.showMenu("Fire Mission Manager", {
            "Add Fire Mission",
            "List Fire Missions",
            "Edit Fire Mission",
            "Delete Fire Mission",
            "Execute Fire Missions",
            "Return To Main Menu"
        })
        
        if choice == 1 then
            AegisOS.missions.addMission()
        elseif choice == 2 then
            AegisOS.missions.listMissions()
        elseif choice == 3 then
            AegisOS.missions.editMission()
        elseif choice == 4 then
            AegisOS.missions.deleteMission()
        elseif choice == 5 then
            AegisOS.missions.executeMissions()
        elseif choice == 6 then
            break
        end
    end
end

function AegisOS.apps.parameterSettings()
    while true do
        local choice = AegisOS.ui.showMenu("Modify Parameters", {
            "Modify Center Point",
            "Modify Muzzle Point",
            "Modify Physics Parameters",
            "Modify GearShift IDs",
            "Modify Redstone Signal Directions",
            "Calibrate Canon Position",
            "Return to Main Menu"
        })
        
        local config = AegisOS.config.getConfig()
        
        if choice == 1 then
            config.centerPoint = AegisOS.config.modifyPoint("Center Point", config.centerPoint)
            if AegisOS.config.saveConfig(config) then
                AegisOS.ui.showMessage("Center Point updated successfully!", 2)
            else
                AegisOS.ui.showMessage("Failed to update Center Point.", 2)
            end
        elseif choice == 2 then
            config.muzzlePoint = AegisOS.config.modifyPoint("Muzzle Point", config.muzzlePoint)
            if AegisOS.config.saveConfig(config) then
                AegisOS.ui.showMessage("Muzzle Point updated successfully!", 2)
            else
                AegisOS.ui.showMessage("Failed to update Muzzle Point.", 2)
            end
        elseif choice == 3 then
            config.physics = AegisOS.config.modifyPhysics(config.physics or {})
            if AegisOS.config.saveConfig(config) then
                AegisOS.ui.showMessage("Physics Parameters updated successfully!", 2)
            else
                AegisOS.ui.showMessage("Failed to update Physics Parameters.", 2)
            end
        elseif choice == 4 then
            config.gearShiftIDs = AegisOS.config.modifyGearshiftIDs(config.gearShiftIDs or {})
            if AegisOS.config.saveConfig(config) then
                AegisOS.ui.showMessage("GearShift IDs updated successfully!", 2)
            else
                AegisOS.ui.showMessage("Failed to update GearShift IDs.", 2)
            end
        elseif choice == 5 then
            config.redstoneDirections = AegisOS.config.modifyRedstoneDirection(config.redstoneDirections or {})
            if AegisOS.config.saveConfig(config) then
                AegisOS.ui.showMessage("Redstone Directions updated successfully!", 2)
            else
                AegisOS.ui.showMessage("Failed to update Redstone Directions.", 2)
            end
        elseif choice == 6 then
            AegisOS.canon.calibrate()
        elseif choice == 7 then
            break
        end
    end
end

function AegisOS.apps.manualOverride()
    AegisOS.ui.drawHeader("Manual Override")
    
    local yawAngle = tonumber(AegisOS.ui.prompt("Insert Yaw:"))
    local pitchAngle = tonumber(AegisOS.ui.prompt("Insert Pitch:"))

    local config = AegisOS.config.getConfig()

    local yawGearShiftId = config.gearShiftIDs.yaw
    local pitchGearShiftId = config.gearShiftIDs.pitch

    local yawData = {
        angle = yawAngle,
        id = yawGearShiftId
    }

    local pitchData = {
        angle = pitchAngle,
        id = pitchGearShiftId
    }

    local triggerSide = config.redstoneDirections.trigger

    AegisOS.canon.moveCanon(yawData, pitchData, triggerSide)
    AegisOS.ui.showMessage("Manual movement completed.", 2)
end


function AegisOS.run()
    
    AegisOS.utils.clearScreen()
    
    
    if not fs.exists(AegisOS.paths.logo) and fs.exists("logo.txt") then
        
        local logoFile = fs.open("logo.txt", "r")
        local logoContent = logoFile.readAll()
        logoFile.close()
        
        
        if not fs.exists("data") then
            fs.makeDir("data")
        end
        
        
        local destFile = fs.open(AegisOS.paths.logo, "w")
        destFile.write(logoContent)
        destFile.close()
    end
    
    local success, lineAfterLogo = AegisOS.utils.renderCenteredAsciiArt(AegisOS.paths.logo)
    
    if success then
        
        AegisOS.utils.renderLoadingBar(lineAfterLogo, 30, 1, "Initializing AegisOS")
    else
        
        AegisOS.utils.clearScreen()
        print("AegisOS v" .. AegisOS.version)
        print("Initializing system...")
        sleep(2)
    end

    local config = AegisOS.config.getConfig()

    AegisOS.utils.redstoneToggle(config.redstoneDirections.power, true)
    
    while true do
        local choice = AegisOS.ui.showMenu("Aegis Control System v" .. AegisOS.version, {
            "Fire Mission",
            "Manual Override",
            "System Settings",
            "Shutdown"
        })
        
        if choice == 1 then
            AegisOS.apps.fireMissionManager()
        elseif choice == 2 then
            AegisOS.apps.manualOverride()
        elseif choice == 3 then
            AegisOS.apps.parameterSettings()
        elseif choice == 4 then
            AegisOS.utils.clearScreen()
            print("Shutting down...")
            AegisOS.utils.redstoneToggle(config.redstoneDirections.power, false)
            sleep(2)
            AegisOS.utils.clearScreen()
            return
        end
    end
end


AegisOS.run()
AegisOS.canon.savePosition(0, 0)
