-- AegisOS - Main System File Structure

-- Core modules
local AegisOS = {
    version = "1.0.5",
    modules = {},
    paths = {
        config = "data/config.json",
        missionTable = "data/mission_table.json",
        canonState = "data/canon_state.json",
        logo = "data/logo.txt"
    },
    constants = {
        GRAVITY = 0.05,     -- Minecraft gravity in blocks/tick²
        MAX_ITERATIONS = 1000,  -- Maximum simulation steps
        TIME_STEP = 0.025,   -- Simulation time step in ticks
        DRAG = 0.01   -- Simulation time step in ticks
    }
}

-- Ensure data directory exists
if not fs.exists("data") then
    fs.makeDir("data")
end

-- Utils Module
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
    
    -- Ensure parent directories exist
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
    
    -- Split the content by newlines
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    -- Find the longest line to calculate centering
    local maxWidth = 0
    for _, line in ipairs(lines) do
        maxWidth = math.max(maxWidth, #line)
    end
    
    -- Calculate the starting Y position to center vertically
    local startY = math.max(1, math.floor((termHeight - #lines) / 3))
    
    -- Clear screen and render each line centered
    term.clear()
    for i, line in ipairs(lines) do
        local startX = math.floor((termWidth - #line) / 2)
        term.setCursorPos(startX, startY + i - 1)
        term.write(line)
    end
    
    return true, startY + #lines  -- Return success and the line after the logo
end

function AegisOS.utils.renderLoadingBar(startY, width, steps, message)
    local termWidth, _ = term.getSize()
    local barWidth = width or 40
    local startX = math.floor((termWidth - barWidth) / 2)
    local steps = steps or 20
    local message = message or "Loading AegisOS"
    
    -- Position and render message
    local msgX = math.floor((termWidth - #message) / 2)
    term.setCursorPos(msgX, startY + 1)
    term.write(message)
    
    -- Draw the empty loading bar
    term.setCursorPos(startX, startY + 3)
    term.write("[" .. string.rep(" ", barWidth - 2) .. "]")
    
    -- Animate the loading bar
    for i = 1, barWidth - 2 do
        term.setCursorPos(startX + i, startY + 3)
        term.write("=")
        
        -- Update the version text with progress percentage
        local percentage = math.floor((i / (barWidth - 2)) * 100)
        local versionText = "v" .. AegisOS.version .. " - " .. percentage .. "%"
        local versionX = math.floor((termWidth - #versionText) / 2)
        
        term.setCursorPos(versionX, startY + 5)
        term.write(versionText)
        
        -- Sleep less as the bar progresses for a more dynamic feel
        local sleepTime = 0.1 - (0.08 * (i / (barWidth - 2)))
        sleep(sleepTime)
    end
    
    -- Complete loading message
    local completionMessage = "System Initialization Complete"
    local completionX = math.floor((termWidth - #completionMessage) / 2)
    
    term.setCursorPos(msgX, startY + 1)
    term.write(string.rep(" ", #message))  -- Clear previous message
    term.setCursorPos(completionX, startY + 1)
    term.write(completionMessage)
    
    sleep(1)
    return startY + 6  -- Return the line after the loading bar
end

-- UI Module
AegisOS.ui = {}-- UI Module with keyboard navigation
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
    
    -- Function to draw the menu
    local function drawMenu()
        -- Clear the menu area (below header)
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
    
    -- Initial draw
    drawMenu()
    
    -- Handle user input
    while running do
        local event, key = os.pullEvent("key")
        
        -- Handle navigation
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

-- Enhanced UI for list selection with keyboard navigation
function AegisOS.ui.selectFromList(title, items, displayFunc)
    AegisOS.ui.drawHeader(title)
    
    if #items == 0 then
        AegisOS.ui.showMessage("No items found.", 2)
        return nil
    end
    
    local selectedItem = 1
    local startIndex = 1
    local maxDisplay = 10  -- Maximum number of items to display at once
    local running = true
    local w, h = term.getSize()
    
    -- Function to display a single item
    local function displayItem(item, index, isSelected)
        local prefix = isSelected and "[ " or "  "
        local suffix = isSelected and " ]" or "  "
        
        if displayFunc then
            return prefix .. displayFunc(item, index) .. suffix
        else
            return prefix .. tostring(item) .. suffix
        end
    end
    
    -- Function to draw the list
    local function drawList()
        -- Clear the display area
        for i = 4, h-2 do
            term.setCursorPos(1, i)
            term.write(string.rep(" ", w))
        end
        
        -- Display items
        local endIndex = math.min(startIndex + maxDisplay - 1, #items)
        for i = startIndex, endIndex do
            term.setCursorPos(1, 4 + (i - startIndex))
            print(displayItem(items[i], i, i == selectedItem))
        end
        
        -- Display navigation help
        term.setCursorPos(1, h-1)
        term.write(string.rep("-", w))
        term.setCursorPos(1, h)
        term.write("Use Up/Down arrows to navigate, Enter to select, Esc to cancel")
        
        -- Display pagination info if needed
        if #items > maxDisplay then
            local pageInfo = "Page " .. math.ceil(startIndex/maxDisplay) .. "/" .. math.ceil(#items/maxDisplay)
            term.setCursorPos(w - #pageInfo, h-1)
            term.write(pageInfo)
        end
    end
    
    -- Initial draw
    drawList()
    
    -- Handle user input
    while running do
        local event, key = os.pullEvent("key")
        
        -- Handle navigation
        if key == keys.up or key == keys.w then
            selectedItem = selectedItem > 1 and selectedItem - 1 or #items
            
            -- Adjust view if selection is out of view
            if selectedItem < startIndex then
                startIndex = selectedItem
            end
            
            drawList()
        elseif key == keys.down or key == keys.s then
            selectedItem = selectedItem < #items and selectedItem + 1 or 1
            
            -- Adjust view if selection is out of view
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

-- Config Module
AegisOS.config = {}

function AegisOS.config.getConfig()
    local config = AegisOS.utils.readFromJsonFile(AegisOS.paths.config)
    
    if not config or not config.centerPoint or not config.muzzlePoint then
        config = {
            centerPoint = { x = 0, y = 0, z = 0 },
            muzzlePoint = { x = 0, y = 0, z = 0 }
        }
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

-- Canon Control Module
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

function AegisOS.canon.moveCanon(yawData, pitchData, triggerSide)
    local modem = peripheral.wrap('bottom')
    triggerSide = triggerSide or "back"
    
    -- Load current state
    local prevYaw, prevPitch = AegisOS.canon.getCurrentPosition()
    
    -- Calculate optimal rotation paths
    local yawAngle, yawMod = AegisOS.canon.calculateShortestPath(prevYaw, yawData.angle)
    local pitchAngle, pitchMod = AegisOS.canon.calculateShortestPath(prevPitch, pitchData.angle)

    local yawControlName = "Create_SequencedGearshift_" .. yawData.id
    local pitchControlName = "Create_SequencedGearshift_" .. pitchData.id

    -- Debug output
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

    -- Save new state
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

-- Ballistics Module
AegisOS.ballistics = {}

function AegisOS.ballistics.simulateProjectile(initial_position, initial_velocity, env_density, gravity_multiplier)
    -- Set default values if parameters are nil
    local time_steps = AegisOS.constants.MAX_ITERATIONS
    local dt = AegisOS.constants.TIME_STEP
    local form_drag = AegisOS.constants.DRAG
    env_density = env_density or 1.0
    local base_gravity = AegisOS.constants.GRAVITY
    gravity_multiplier = gravity_multiplier or 1.0
    
    -- Calculate gravity for the simulation
    local GRAVITY = (base_gravity * gravity_multiplier) * 400
    
    -- Initialize position and velocity
    local position = {initial_position[1], initial_position[2], initial_position[3] or 0}
    local velocity = {initial_velocity[1], initial_velocity[2], initial_velocity[3] or 0}
    
    -- Table to store trajectory
    local positions = {{position[1], position[2], position[3]}}
    
    -- Simulation loop
    for i = 1, time_steps do
        -- Calculate current speed
        local speed = math.sqrt(velocity[1]^2 + velocity[2]^2 + velocity[3]^2)
        
        if speed > 0 then
            -- Compute linear drag
            local drag = form_drag * env_density * speed
            drag = math.min(drag, speed)  -- Limit drag force
            
            -- Apply drag to velocity (scaled per tick)
            local drag_factor = (drag / speed) * dt * 20
            
            -- Apply drag uniformly to all velocity components
            velocity[1] = velocity[1] * (1 - drag_factor)
            velocity[2] = velocity[2] * (1 - drag_factor)
            velocity[3] = velocity[3] * (1 - drag_factor)
        end
        
        -- Apply gravity to vertical component (Y in Lua)
        velocity[2] = velocity[2] - GRAVITY * dt
        
        -- Update position using velocity
        position[1] = position[1] + velocity[1] * dt
        position[2] = position[2] + velocity[2] * dt
        position[3] = position[3] + velocity[3] * dt
        
        -- Store new position
        table.insert(positions, {position[1], position[2], position[3]})
        
        -- Stop simulation if projectile hits the ground
        if position[2] <= 0 then
            position[2] = 0  -- Ensure exact ground level
            positions[#positions] = {position[1], position[2], position[3]}
            break
        end
    end
    
    return positions
end

function AegisOS.ballistics.calculatePitchForTarget(startX, startY, startZ, targetX, targetY, targetZ)
    -- Default values for physics parameters
    local env_density = 1.0
    local gravity_multiplier = 1.0
    local initial_speed = 160.0  -- Based on the Python code
    
    -- Calculate horizontal distance
    local dx = targetX - startX
    local dz = targetZ - startZ
    local horizontalDistance = math.sqrt(dx^2 + dz^2)
    local verticalDistance = targetY - startY
    
    -- Create normalized direction vector for horizontal movement
    local dirX, dirZ
    if horizontalDistance > 0 then
        dirX = dx / horizontalDistance
        dirZ = dz / horizontalDistance
    else
        -- If target is directly above/below, use default direction
        dirX, dirZ = 1, 0
    end
    
    -- Test a range of angles to find the best one
    local bestAngle = nil
    local minDistance = math.huge
    
    -- Try angles from 0 to 60 degrees in 1-degree increments
    for angle = 0, 30, 5 do
        local angleRad = math.rad(angle)
        local vx = initial_speed * math.cos(angleRad) * dirX
        local vy = initial_speed * math.sin(angleRad)
        local vz = initial_speed * math.cos(angleRad) * dirZ
        
        local trajectory = AegisOS.ballistics.simulateProjectile(
            {startX, startY, startZ},
            {vx, vy, vz},
            env_density,
            gravity_multiplier
        )
        
        -- Get the final position
        local finalPos = trajectory[#trajectory]
        local finalDistance = math.sqrt((finalPos[1] - targetX)^2 + (finalPos[3] - targetZ)^2)
        print(angle, finalDistance)
        read()
        -- Check if this is the closest to the target so far
        if finalDistance < minDistance then
            minDistance = finalDistance
            bestAngle = angle
        end
        
    end
    
    -- Return just the best pitch angle and the expected error
    return bestAngle, minDistance
end

function AegisOS.ballistics.findYaw(targetPoint)
    local config = AegisOS.config.getConfig()

    local basePoint = vector.new(config.centerPoint.x, 0, config.centerPoint.z)
    local muzzleEndPoint = vector.new(config.muzzlePoint.x, 0, config.muzzlePoint.z)

    local forwardVector = muzzleEndPoint - basePoint
    forwardVector = forwardVector:normalize()
    
    local targetVector = targetPoint - basePoint
    targetVector = targetVector:normalize()

    -- Calculate the angle between vectors
    local dotProduct = forwardVector:dot(targetVector)
    local radian_angle = math.acos(math.min(1, math.max(-1, dotProduct)))
    
    -- Determine the direction (clockwise or counter-clockwise)
    local crossProduct = forwardVector.x * targetVector.z - forwardVector.z * targetVector.x
    
    -- If cross product is negative, angle is clockwise (negative)
    if crossProduct < 0 then
        radian_angle = -radian_angle
    end
    
    return math.deg(radian_angle)
end

-- Fire Mission Module
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
-- Fire Mission Module with enhanced UI
function AegisOS.missions.listMissions()
    AegisOS.ui.drawHeader("Fire Mission List")
    
    local missions = AegisOS.missions.getMissions()
    
    if #missions == 0 then
        AegisOS.ui.showMessage("No fire missions found.", 2)
        return
    end
    
    -- Define how to display a mission
    local function displayMission(mission, index)
        return "Mission #" .. index .. ": X=" .. mission.point.x .. 
               ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. 
               " (" .. mission.munition .. ")"
    end
    
    -- Show the missions with the new UI
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
    
    -- Define how to display a mission
    local function displayMission(mission, index)
        return "Mission #" .. index .. ": X=" .. mission.point.x .. 
               ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. 
               " (" .. mission.munition .. ")"
    end
    
    -- Show the missions with the new UI
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
    
    -- Define how to display a mission
    local function displayMission(mission, index)
        return "Mission #" .. index .. ": X=" .. mission.point.x .. 
               ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. 
               " (" .. mission.munition .. ")"
    end
    
    -- Add a special "Delete All" option at the end
    local displayOptions = {}
    for i, mission in ipairs(missions) do
        table.insert(displayOptions, mission)
    end
    table.insert(displayOptions, {special = "delete_all"})
    
    -- Custom display function that handles the special case
    local function displayOption(item, index)
        if item.special and item.special == "delete_all" then
            return "DELETE ALL MISSIONS"
        else
            return displayMission(item, index)
        end
    end
    
    -- Show the missions with the new UI
    local selection, selectedItem = AegisOS.ui.selectFromList("Select Mission to Delete", displayOptions, displayOption)
    
    if not selection then
        return
    end
    
    -- Handle the special "Delete All" option
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
        -- Get the actual mission index (accounting for the "Delete All" option)
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
    
    -- Define how to display a mission for selection
    local function displayMission(mission, index)
        return "Mission #" .. index .. ": X=" .. mission.point.x .. 
               ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z .. 
               " (" .. mission.munition .. ")"
    end
    
    -- Add options for execution
    local options = {
        "Execute All Missions",
        "Select Single Mission to Execute",
        "Cancel Execution"
    }
    
    local choice = AegisOS.ui.showMenu("Execute Fire Missions", options)
    
    if choice == 3 then
        return
    elseif choice == 2 then
        -- Select a single mission
        local selection = AegisOS.ui.selectFromList("Select Mission to Execute", missions, displayMission)
        if not selection then
            return
        end
        
        local singleMission = {missions[selection]}
        missions = singleMission
    end
    
    -- Now execute the mission(s)
    print("Total Missions to Execute: " .. #missions)
    print("Starting execution in 3 seconds...")
    sleep(3)
    
    for index, mission in ipairs(missions) do
        AegisOS.utils.clearScreen()
        print("Executing Mission #" .. index)
        print("Target: X=" .. mission.point.x .. ", Y=" .. mission.point.y .. ", Z=" .. mission.point.z)
        print("Munition: " .. mission.munition)
        
        -- Calculate yaw
        local targetPoint = vector.new(mission.point.x, 0, mission.point.z)
        local yawAngle = AegisOS.ballistics.findYaw(targetPoint)
        
        -- Calculate distance to target (2D)
        local targetX = mission.point.x
        local targetY = mission.point.y or 0
        local targetZ = mission.point.z
        local startX = config.centerPoint.x + 9 * math.sin(math.rad(yawAngle))
        local startY = math.abs(config.centerPoint.y - targetY) or 0
        local startZ = config.centerPoint.z + 9 * math.cos(math.rad(yawAngle))
        
        -- Calculate pitch using physics simulation
        print("Calculating optimal pitch angle...")
        local pitchAngle, expectedError = AegisOS.ballistics.calculatePitchForTarget(
            startX, startY, startZ,
            targetX, targetY,targetZ
        )
        
        print("Calculated Yaw: " .. string.format("%.2f", yawAngle) .. "°")
        print("Calculated Pitch: " .. string.format("%.2f", pitchAngle) .. "°")
        print("Expected accuracy: " .. string.format("%.2f", expectedError) .. " blocks")
        sleep(1)
        
        local yawData = {
            angle = yawAngle,
            id = 0
        }
        
        local pitchData = {
            angle = pitchAngle,
            id = 1
        }
        
        print("Moving cannon...")
        AegisOS.canon.moveCanon(yawData, pitchData)
        print("Fire mission completed!")
        
        -- If there are more missions, pause briefly
        if index < #missions then
            print("\nPress Enter to continue to next mission...")
            read()
        else
            sleep(2)
        end
    end
    
    AegisOS.ui.showMessage("All fire missions executed successfully!", 2)
end

-- Application Modules
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
            AegisOS.canon.calibrate()
        elseif choice == 4 then
            break
        end
    end
end

function AegisOS.apps.manualOverride()
    AegisOS.ui.drawHeader("Manual Override")
    
    local yawAngle = tonumber(AegisOS.ui.prompt("Insert Yaw:"))
    local pitchAngle = tonumber(AegisOS.ui.prompt("Insert Pitch:"))

    local yawData = {
        angle = yawAngle,
        id = 0
    }

    local pitchData = {
        angle = pitchAngle,
        id = 1
    }

    AegisOS.canon.moveCanon(yawData, pitchData, "back")
    AegisOS.ui.showMessage("Manual movement completed.", 2)
end

-- Main Application
function AegisOS.run()
    -- Initialize system
    AegisOS.utils.clearScreen()
    
    -- Try to render the logo
    if not fs.exists(AegisOS.paths.logo) and fs.exists("logo.txt") then
        -- If logo doesn't exist in the data directory but exists in root, copy it
        local logoFile = fs.open("logo.txt", "r")
        local logoContent = logoFile.readAll()
        logoFile.close()
        
        -- Make sure data directory exists
        if not fs.exists("data") then
            fs.makeDir("data")
        end
        
        -- Save to data directory
        local destFile = fs.open(AegisOS.paths.logo, "w")
        destFile.write(logoContent)
        destFile.close()
    end
    
    local success, lineAfterLogo = AegisOS.utils.renderCenteredAsciiArt(AegisOS.paths.logo)
    -- Display the logo
    if success then
        -- Render loading bar animation below the logo
        AegisOS.utils.renderLoadingBar(lineAfterLogo, 30, 1, "Initializing AegisOS")
    else
        -- Fallback if logo can't be rendered
        AegisOS.utils.clearScreen()
        print("AegisOS v" .. AegisOS.version)
        print("Initializing system...")
        sleep(2)
    end
    AegisOS.utils.redstoneToggle('top', true)
    
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
            AegisOS.utils.redstoneToggle('top', false)
            sleep(2)
            AegisOS.utils.clearScreen()
            return
        end
    end
end

-- Start the OS
AegisOS.run()
AegisOS.canon.savePosition(0, 0)
