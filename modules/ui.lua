local ui = {}

function ui.drawHeader(title)
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

function ui.showMenu(title, options)
    AegisOS.ui.drawHeader(title)
    local selectedOption = 1
    local running = true
    local w, h = term.getSize()
    local function drawMenu()
        for i = 4, h do term.setCursorPos(1, i); term.write(string.rep(" ", w)) end
        term.setCursorPos(1, 4)
        for i, option in ipairs(options) do
            if i == selectedOption then print("[ " .. option .. " ]") else print("  " .. option .. "  ") end
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

function ui.prompt(message, defaultValue)
    print(message)
    local input = read()
    if input == "" and defaultValue ~= nil then return defaultValue end
    return input
end

function ui.showMessage(message, pause)
    print(message)
    if pause then
        sleep(pause)
    else
        print("\nPress Enter to continue...")
        read()
    end
end

function ui.selectFromList(title, items, displayFunc)
    AegisOS.ui.drawHeader(title)
    if #items == 0 then AegisOS.ui.showMessage("No items found.", 2); return nil end
    local selectedItem, startIndex, maxDisplay, running = 1, 1, 10, true
    local w, h = term.getSize()
    local function displayItem(item, index, isSelected)
        local prefix = isSelected and "[ " or "  "; local suffix = isSelected and " ]" or "  "
        if displayFunc then return prefix .. displayFunc(item, index) .. suffix else return prefix .. tostring(item) .. suffix end
    end
    local function drawList()
        for i = 4, h - 2 do term.setCursorPos(1, i); term.write(string.rep(" ", w)) end
        local endIndex = math.min(startIndex + maxDisplay - 1, #items)
        for i = startIndex, endIndex do
            term.setCursorPos(1, 4 + (i - startIndex))
            print(displayItem(items[i], i, i == selectedItem))
        end
        term.setCursorPos(1, h - 1); term.write(string.rep("-", w))
        term.setCursorPos(1, h); term.write("Use Up/Down arrows to navigate, Enter to select, Esc to cancel")
        if #items > maxDisplay then
            local pageInfo = "Page " .. math.ceil(startIndex / maxDisplay) .. "/" .. math.ceil(#items / maxDisplay)
            term.setCursorPos(w - #pageInfo, h - 1); term.write(pageInfo)
        end
    end
    drawList()
    while running do
        local event, key = os.pullEvent("key")
        if key == keys.up or key == keys.w then
            selectedItem = selectedItem > 1 and selectedItem - 1 or #items
            if selectedItem < startIndex then startIndex = selectedItem end
            drawList()
        elseif key == keys.down or key == keys.s then
            selectedItem = selectedItem < #items and selectedItem + 1 or 1
            if selectedItem >= startIndex + maxDisplay then startIndex = selectedItem - maxDisplay + 1 end
            drawList()
        elseif key == keys.pageUp then
            startIndex = math.max(1, startIndex - maxDisplay); selectedItem = startIndex; drawList()
        elseif key == keys.pageDown then
            startIndex = math.min(#items - maxDisplay + 1, startIndex + maxDisplay); if startIndex < 1 then startIndex = 1 end; selectedItem = startIndex; drawList()
        elseif key == keys.enter then
            running = false; return selectedItem, items[selectedItem]
        elseif key == keys.escape then
            running = false; return nil
        end
    end
    return nil
end

return ui