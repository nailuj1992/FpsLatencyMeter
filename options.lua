local addOnName = ...
GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local addOnVersion = GetAddOnMetadata(addOnName, "Version") or "0.0.1"
local addOnTitle = GetAddOnMetadata(addOnName, "Title") or "FpsLatencyMeter"

local clientVersionString = GetBuildInfo()
local clientBuildMajor = string.byte(clientVersionString, 1)
local majorVersion = tonumber(string.match(clientVersionString, "^(%d+)%.?%d*"))

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

_G[addOnName] = {}
local TT = _G[addOnName]

FpsLatencyMeterBaseConfig = {
    fps = true,
    latency = true,
    latencyHome = true,
    latencyWorld = true,
    refreshInterval = 1,
    changeColor = true,
    highColor = { 0.90588218115667, 0.29803922772408, 0.23529413312476 },
    mediumColor = { 0.94509810209274, 0.76862752437592, 0.058823533535519 },
    lowColor = { 0.1803921610117, 0.80000007152557, 0.44313728809357 },
    framePoint = "CENTER",
    frameX = 0, --610,
    frameY = 0, --532,
}

function TT:GetDefaultPositions()
    FpsLatencyMeterConfig.frameX = FpsLatencyMeterBaseConfig.frameX
    FpsLatencyMeterConfig.frameY = FpsLatencyMeterBaseConfig.frameY
end

function TT:GetDefaults()
    if not FpsLatencyMeterConfig then
        FpsLatencyMeterConfig = {
            frameX = FpsLatencyMeterBaseConfig.frameX,
            frameY = FpsLatencyMeterBaseConfig.frameY,
        }
    end
    FpsLatencyMeterConfig.fps = true
    FpsLatencyMeterConfig.latency = true
    FpsLatencyMeterConfig.latencyHome = true
    FpsLatencyMeterConfig.latencyWorld = true
    FpsLatencyMeterConfig.refreshInterval = 1
    FpsLatencyMeterConfig.changeColor = true
    FpsLatencyMeterConfig.highColor = { 0.90588218115667, 0.29803922772408, 0.23529413312476 }
    FpsLatencyMeterConfig.mediumColor = { 0.94509810209274, 0.76862752437592, 0.058823533535519 }
    FpsLatencyMeterConfig.lowColor = { 0.1803921610117, 0.80000007152557, 0.44313728809357 }
    FpsLatencyMeterConfig.framePoint = "CENTER"
end

local function ResetColors(options)
    options.highColorSelector.SetDisabled(options.highColorSelector, not FpsLatencyMeterConfig.changeColor)
    options.mediumColorSelector.SetDisabled(options.mediumColorSelector, not FpsLatencyMeterConfig.changeColor)
    options.lowColorSelector.SetDisabled(options.lowColorSelector, not FpsLatencyMeterConfig.changeColor)

    if FpsLatencyMeterConfig.changeColor then
        options.highColorSelector:SetColor(unpack(FpsLatencyMeterConfig.highColor))
        options.mediumColorSelector:SetColor(unpack(FpsLatencyMeterConfig.mediumColor))
        options.lowColorSelector:SetColor(unpack(FpsLatencyMeterConfig.lowColor))
    end
end

local function resetCfg(options)
    TT:GetDefaults()
    if options then
        ResetColors(options)
    end
end

if not FpsLatencyMeterConfig then
    resetCfg()
end

-- Methods to create widgets
local function newCheckbox(parent, label, description, width, height, onClick)
    local check = AceGUI:Create("CheckBox")
    check:SetLabel(label)
    check:SetDescription(description)
    check:SetCallback("OnValueChanged", onClick)

    local aceFrame = check.frame
    aceFrame:SetParent(parent)
    aceFrame:SetSize(width, height)
    aceFrame:Show()
    return check
end
local function newSlider(parent, label, minValue, maxValue, width, height, onValueChanged)
    local slider = AceGUI:Create("Slider")
    slider:SetLabel(label)
    slider:SetSliderValues(minValue, maxValue, 1)
    slider:SetCallback("OnValueChanged", onValueChanged)

    local aceFrame = slider.frame
    aceFrame:SetParent(parent)
    aceFrame:SetSize(width, height)
    aceFrame:Show()

    return slider
end
local function newColorSelector(parent, label, description, width, height, initialColor, SetColor)
    local colorPicker = AceGUI:Create("ColorPicker")
    colorPicker:SetLabel(label .. " " .. description)
    colorPicker:SetHasAlpha(false)

    local r, g, b = unpack(initialColor)
    colorPicker:SetColor(r, g, b, 1) -- Alpha defaults to 1

    local currentColor = { r, g, b }

    local aceFrame = colorPicker.frame
    aceFrame:SetParent(parent)
    aceFrame:SetSize(width, height)
    aceFrame:Show()

    colorPicker:SetCallback("OnValueChanged", function(widget, event, newR, newG, newB, newA)
        currentColor = { newR, newG, newB }
        SetColor(newR, newG, newB)
    end)

    return colorPicker
end
local function newButton(parent, label, onClick)
    local button = AceGUI:Create("Button")
    button:SetText(label)

    local aceFrame = button.frame
    aceFrame:SetParent(parent)
    aceFrame:SetSize(177, 24)
    aceFrame:Show()

    button:SetCallback("OnClick", onClick)

    return button
end
local function newInlineGroup(parent, layout, text, width, height)
    local inlineGroup = AceGUI:Create("InlineGroup")
    inlineGroup:SetTitle(text)
    inlineGroup.noAutoHeight = true
    inlineGroup:SetLayout(layout)

    local aceFrame = inlineGroup.frame
    aceFrame:SetParent(parent)
    aceFrame:SetSize(width, height)
    aceFrame:Show()

    return inlineGroup
end

-- main frame
local frame = CreateFrame("Frame", "Fps Latency Meter Options")
frame.name = addOnTitle
frame:Hide()

-- Add to Blizzard settings
local category = Settings.RegisterCanvasLayoutCategory(frame, frame.name, frame.name)
Settings.RegisterAddOnCategory(category)
-- local category = Settings.RegisterVerticalLayoutCategory(frame, frame.name, frame.name);
-- Settings.RegisterAddOnCategory(category);

frame:SetScript("OnShow", function(frame)
    -- local function Register()
    -- local category, layout = Settings.RegisterVerticalLayoutCategory(frame, frame.name, frame.name)
    -- Settings.FPS_LATENCY_CATEGORY_ID = category:GetID()

    -- layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("General"))

    -- Methods for color
    local highColor = FpsLatencyMeterConfig.highColor
    local mediumColor = FpsLatencyMeterConfig.mediumColor
    local lowColor = FpsLatencyMeterConfig.lowColor
    local function SetHighColor(r, g, b)
        FpsLatencyMeterConfig.highColor = { r, g, b }
        highColor = { r, g, b }
        TT:UpdateFrames()
    end
    local function SetMediumColor(r, g, b)
        FpsLatencyMeterConfig.mediumColor = { r, g, b }
        mediumColor = { r, g, b }
        TT:UpdateFrames()
    end
    local function SetLowColor(r, g, b)
        FpsLatencyMeterConfig.lowColor = { r, g, b }
        lowColor = { r, g, b }
        TT:UpdateFrames()
    end

    -- Place options in frame
    local options = {}
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addOnTitle .. " v" .. addOnVersion)

    local enableFeatures = newInlineGroup(frame, "Flow", "Enable Features", 425, 120)
    enableFeatures:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

    options.showFps = newCheckbox(enableFeatures.content, "Show FPS", "Shows FPS indicator", 170, 25,
        function(widget, event, value)
            FpsLatencyMeterConfig.fps = value
            TT:UpdateFrames()
        end)
    enableFeatures:AddChild(options.showFps)

    options.showHomeLatency = newCheckbox(enableFeatures.content, "Show Home MS", "Shows MS (Home) indicator", 205, 25,
        function(widget, event, value)
            FpsLatencyMeterConfig.latencyHome = value
            TT:UpdateFrames()
        end)
    enableFeatures:AddChild(options.showHomeLatency)

    options.showLatency = newCheckbox(enableFeatures.content, "Show Latency", "Shows MS indicators", 170, 25,
        function(widget, event, value)
            FpsLatencyMeterConfig.latency = value
            options.showHomeLatency:SetDisabled(not value)
            options.showWorldLatency:SetDisabled(not value)
            TT:UpdateFrames()
        end)
    enableFeatures:AddChild(options.showLatency)

    options.showWorldLatency = newCheckbox(enableFeatures.content, "Show World MS", "Shows MS (World) indicator", 205,
        25,
        function(widget, event, value)
            FpsLatencyMeterConfig.latencyWorld = value
            TT:UpdateFrames()
        end)
    enableFeatures:AddChild(options.showWorldLatency)

    local textColors = newInlineGroup(frame, "Flow", "Text Colors", 300, 180)
    textColors:SetPoint("TOPLEFT", enableFeatures.frame, "BOTTOMLEFT", 0, 0)

    options.changeColor = newCheckbox(textColors.content, "Changing Color", "Changes Color depending on the Value", 270,
        25,
        function(widget, event, value)
            FpsLatencyMeterConfig.changeColor = value
            if value then
                options.highColorSelector.SetDisabled(options.highColorSelector, false)
                options.mediumColorSelector.SetDisabled(options.mediumColorSelector, false)
                options.lowColorSelector.SetDisabled(options.lowColorSelector, false)
            else
                options.highColorSelector.SetDisabled(options.highColorSelector, true)
                options.mediumColorSelector.SetDisabled(options.mediumColorSelector, true)
                options.lowColorSelector.SetDisabled(options.lowColorSelector, true)
            end
            TT:UpdateFrames()
        end)
    textColors:AddChild(options.changeColor)

    options.highColorSelector = newColorSelector(textColors.content, "High Color", "(<15fps, >200ms)", 250, 25, highColor,
        SetHighColor)
    textColors:AddChild(options.highColorSelector)

    options.mediumColorSelector = newColorSelector(textColors.content, "Medium Color", "(<30fps, >100ms)", 250, 25,
        mediumColor,
        SetMediumColor)
    textColors:AddChild(options.mediumColorSelector)

    options.lowColorSelector = newColorSelector(textColors.content, "Low Color", "(>30fps, <100ms)", 250, 25, lowColor,
        SetLowColor)
    textColors:AddChild(options.lowColorSelector)

    local refreshTimer = newInlineGroup(frame, "Flow", "Refresh Timer", 270, 90)
    refreshTimer:SetPoint("LEFT", textColors.frame, "RIGHT", 0, 0)

    options.refreshSlider = newSlider(refreshTimer.content, "Refresh Interval", 1, 60, 25, 25,
        function(widget, event, value)
            value = tonumber(string.format("%d", value))
            FpsLatencyMeterConfig.refreshInterval = value
            TT:UpdateFrames()
        end)
    options.refreshSlider:SetWidth(250)
    options.refreshSlider:SetHeight(15)
    refreshTimer:AddChild(options.refreshSlider)

    local resetcfg = newButton(frame, "Reset configuration",
        function()
            resetCfg(options)
            frame:Refresh()
        end)
    resetcfg:SetPoint("TOP", refreshTimer.frame, "BOTTOM", 0, 0)

    local positionFrame = newInlineGroup(frame, "Flow", "Position Settings", 300, 140)
    positionFrame:SetPoint("LEFT", textColors.frame, "BOTTOMLEFT", 0, -75)

    options.positionX = newSlider(positionFrame.content, "Frame Position in X", -1200, 1200, 250, 60,
        function(widget, event, value)
            value = tonumber(string.format("%d", value))
            FpsLatencyMeterConfig.frameX = value
            TT:UpdateFrames()
        end)
    positionFrame:AddChild(options.positionX)

    options.positionY = newSlider(positionFrame.content, "Frame Position in Y", -700, 700, 250, 60,
        function(widget, event, value)
            value = tonumber(string.format("%d", value))
            FpsLatencyMeterConfig.frameY = value
            TT:UpdateFrames()
        end)
    positionFrame:AddChild(options.positionY)

    local function getConfig()
        options.positionX:SetValue(FpsLatencyMeterConfig.frameX)
        options.positionY:SetValue(FpsLatencyMeterConfig.frameY)

        options.showFps:SetValue(FpsLatencyMeterConfig.fps)
        options.showLatency:SetValue(FpsLatencyMeterConfig.latency)

        options.showHomeLatency:SetDisabled(not FpsLatencyMeterConfig.latency)
        options.showWorldLatency:SetDisabled(not FpsLatencyMeterConfig.latency)

        if FpsLatencyMeterConfig.latency then
            options.showHomeLatency:SetValue(FpsLatencyMeterConfig.latencyHome)
            options.showWorldLatency:SetValue(FpsLatencyMeterConfig.latencyWorld)
        end

        options.refreshSlider:SetValue(FpsLatencyMeterConfig.refreshInterval or 1)
        options.changeColor:SetValue(FpsLatencyMeterConfig.changeColor)

        ResetColors(options)
    end

    frame.Refresh = function()
        getConfig()
    end

    getConfig()

    frame:SetScript("OnShow", function()
        getConfig()
    end)
    frame:SetScript("OnHide", function()
        getConfig()
    end)
end)
-- end

-- SettingsRegistrar:AddRegistrant(Register)

-- -- for addon compartment (in .toc)
-- function OpenUUISettings()
--     Settings.OpenToCategory(Settings.FPS_LATENCY_CATEGORY_ID);
-- end

SLASH_FPSLATENCY1 = "/fps";
SLASH_FPSLATENCY2 = "/latency";
SLASH_FPSLATENCY3 = "/ms";
function SlashCmdList.FPSLATENCY(msg)
    local cmd = strlower(msg)
    if (cmd == "reset") then
        resetCfg()
        if (frame:IsShown()) then
            frame:Refresh()
        end
        print("|cff59f0dc" .. addOnTitle .. ":|r " .. "Configuration has been reset to default.")
    else
        Settings.OpenToCategory(category.ID)
        -- Settings.OpenToCategory(category.FPS_LATENCY_CATEGORY_ID)
    end
end
