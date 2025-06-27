local utils = {}

function utils.clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

function utils.redstoneBlink(side, duration)
    sleep(duration / 2)
    redstone.setOutput(side, not redstone.getOutput(side))
    sleep(duration / 2)
    redstone.setOutput(side, not redstone.getOutput(side))
end

function utils.redstoneToggle(side, toggle)
    if redstone.getOutput(side) == toggle then return end
    redstone.setOutput(side, toggle)
end

function utils.readFromJsonFile(filePath)
    if not fs.exists(filePath) then return {} end
    local file = fs.open(filePath, "r")
    if not file then return {} end
    local content = file.readAll()
    file.close()
    local success, data = pcall(textutils.unserializeJSON, content)
    if not success or type(data) ~= "table" then return {} end
    return data
end

function utils.writeToJsonFile(data, filePath)
    if not data or type(data) ~= "table" then return false end
    local parentDir = string.match(filePath, "(.-)/[^/]+$")
    if parentDir and not fs.exists(parentDir) then fs.makeDir(parentDir) end
    local success, serialized = pcall(textutils.serializeJSON, data)
    if not success then return false end
    local file = fs.open(filePath, "w")
    if not file then return false end
    file.write(serialized)
    file.close()
    return true
end

function utils.renderAsciiArt(filePath)
    if not fs.exists(filePath) then return false end
    local file = fs.open(filePath, "r")
    if not file then return false end
    local content = file.readAll()
    file.close()
    print(content)
    return true
end

function utils.renderCenteredAsciiArt(filePath)
    if not fs.exists(filePath) then return false end
    local file = fs.open(filePath, "r")
    if not file then return false end
    local content = file.readAll()
    file.close()
    local termWidth, termHeight = term.getSize()
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do table.insert(lines, line) end
    local maxWidth = 0
    for _, line in ipairs(lines) do maxWidth = math.max(maxWidth, #line) end
    local startY = math.max(1, math.floor((termHeight - #lines) / 3))
    term.clear()
    for i, line in ipairs(lines) do
        local startX = math.floor((termWidth - #line) / 2)
        term.setCursorPos(startX, startY + i - 1)
        term.write(line)
    end
    return true, startY + #lines
end

function utils.renderLoadingBar(startY, width, steps, message)
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

return utils