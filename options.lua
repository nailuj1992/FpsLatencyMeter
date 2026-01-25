local addOnName = ...
GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local addOnVersion = GetAddOnMetadata(addOnName, "Version") or "0.0.1"
local addOnTitle = GetAddOnMetadata(addOnName, "Title") or "FpsLatencyMeter"

local clientVersionString = GetBuildInfo()
local majorVersion = tonumber(string.match(clientVersionString, "^(%d+)%.?%d*"))

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local SettingsLib = LibStub and LibStub("LibEQOLSettingsMode-1.0", true)

_G[addOnName] = {}
local TT = _G[addOnName]

function TT:IsRetail()
    return majorVersion >= 12 -- Midnight
end

function TT:IsClassic()
    return majorVersion <= 5 -- Up to MoP
end

local FpsLatencyMeterBaseConfig = {
    fps = true,
    latency = true,
    latencyHome = true,
    latencyWorld = true,
    refreshInterval = 1,
    changeColor = true,
    highColor = { 0.90588218115667, 0.29803922772408, 0.23529413312476, 1 },
    mediumColor = { 0.94509810209274, 0.76862752437592, 0.058823533535519, 1 },
    lowColor = { 0.1803921610117, 0.80000007152557, 0.44313728809357, 1 },
    framePoint = "CENTER",
    frameX = 0, --610,
    frameY = 0, --532,
}
FpsLatencyMeterConfig = FpsLatencyMeterConfig or {
    fps = FpsLatencyMeterBaseConfig.fps,
    latency = FpsLatencyMeterBaseConfig.latency,
    latencyHome = FpsLatencyMeterBaseConfig.latencyHome,
    latencyWorld = FpsLatencyMeterBaseConfig.latencyWorld,
    refreshInterval = FpsLatencyMeterBaseConfig.refreshInterval,
    changeColor = FpsLatencyMeterBaseConfig.changeColor,
    highColor = FpsLatencyMeterBaseConfig.highColor,
    mediumColor = FpsLatencyMeterBaseConfig.mediumColor,
    lowColor = FpsLatencyMeterBaseConfig.lowColor,

    framePoint = FpsLatencyMeterBaseConfig.framePoint,
    frameX = FpsLatencyMeterBaseConfig.frameX,
    frameY = FpsLatencyMeterBaseConfig.frameY,
}

function TT:GetDefaults()
    FpsLatencyMeterConfig.fps = FpsLatencyMeterBaseConfig.fps
    FpsLatencyMeterConfig.latency = FpsLatencyMeterBaseConfig.latency
    FpsLatencyMeterConfig.latencyHome = FpsLatencyMeterBaseConfig.latencyHome
    FpsLatencyMeterConfig.latencyWorld = FpsLatencyMeterBaseConfig.latencyWorld
    FpsLatencyMeterConfig.refreshInterval = FpsLatencyMeterBaseConfig.refreshInterval
    FpsLatencyMeterConfig.changeColor = FpsLatencyMeterBaseConfig.changeColor
    FpsLatencyMeterConfig.highColor = FpsLatencyMeterBaseConfig.highColor
    FpsLatencyMeterConfig.mediumColor = FpsLatencyMeterBaseConfig.mediumColor
    FpsLatencyMeterConfig.lowColor = FpsLatencyMeterBaseConfig.lowColor

    FpsLatencyMeterConfig.framePoint = FpsLatencyMeterBaseConfig.framePoint
    FpsLatencyMeterConfig.frameX = FpsLatencyMeterBaseConfig.frameX
    FpsLatencyMeterConfig.frameY = FpsLatencyMeterBaseConfig.frameY
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

local function ResetCfg(options)
    TT:GetDefaults()
    if options and TT:IsClassic() then
        ResetColors(options)
    end
    if TT:IsRetail() then
        local settingsToUpdate = {
            "fps",
            "latency",
            "latencyHome",
            "latencyWorld",
            "refreshInterval",
            "changeColor",
            "highColor",
            "mediumColor",
            "lowColor",
            "frameX",
            "frameY",
        }
        for _, variable in ipairs(settingsToUpdate) do
            Settings.NotifyUpdate(variable)
        end
    end
end

if not FpsLatencyMeterConfig then
    ResetCfg()
end

-- main frame (Classic)
local frame = CreateFrame("Frame", "Fps Latency Meter Options")
frame.name = addOnTitle
frame:Hide()

if TT:IsRetail() then
    local function OnSettingChanged(_, setting, value)
        local variable = setting:GetVariable()
        FpsLatencyMeterConfig[variable] = value
        TT:UpdateFrames()
    end
    local function Register()
        local category, layout = Settings.RegisterVerticalLayoutCategory(addOnTitle .. " v" .. addOnVersion)
        Settings.FPS_LATENCY_CATEGORY_ID = category:GetID()

        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Enable Features"))

        do
            local name = "Show FPS"
            local tooltip = "Shows FPS indicator"
            local defaultValue = FpsLatencyMeterBaseConfig.fps
            local variable = "fps"
            local variableTbl = FpsLatencyMeterConfig

            local setting = Settings.RegisterAddOnSetting(category, variable, variable, variableTbl, type(defaultValue),
                name, defaultValue)
            Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
            Settings.CreateCheckbox(category, setting, tooltip)
        end

        local latencySetting, latencyHomeSetting, latencyWorldSetting
        do
            local name         = "Show Latency"
            local tooltip      = "Shows MS indicators"
            local defaultValue = FpsLatencyMeterBaseConfig.latency
            local variable     = "latency"
            local variableTbl  = FpsLatencyMeterConfig

            latencySetting     = Settings.RegisterAddOnSetting(category, variable, variable, variableTbl,
                type(defaultValue),
                name, defaultValue)
            Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
            Settings.CreateCheckbox(category, latencySetting, tooltip)
        end

        do
            local name = "Show Home MS"
            local tooltip = "Shows MS (Home) indicator"
            local defaultValue = FpsLatencyMeterBaseConfig.latencyHome
            local variable = "latencyHome"
            local variableTbl = FpsLatencyMeterConfig

            latencyHomeSetting = Settings.RegisterAddOnSetting(category, variable, variable, variableTbl,
                type(defaultValue),
                name, defaultValue)
            Settings.SetOnValueChangedCallback(variable, OnSettingChanged)

            local checkbox = Settings.CreateCheckbox(category, latencyHomeSetting, tooltip)
            checkbox:AddShownPredicate(function() return latencySetting:GetValue() end)
        end

        do
            local name = "Show World MS"
            local tooltip = "Shows MS (World) indicator"
            local defaultValue = FpsLatencyMeterBaseConfig.latencyWorld
            local variable = "latencyWorld"
            local variableTbl = FpsLatencyMeterConfig

            latencyWorldSetting = Settings.RegisterAddOnSetting(category, variable, variable, variableTbl,
                type(defaultValue),
                name, defaultValue)
            Settings.SetOnValueChangedCallback(variable, OnSettingChanged)

            local checkbox = Settings.CreateCheckbox(category, latencyWorldSetting, tooltip)
            checkbox:AddShownPredicate(function() return latencySetting:GetValue() end)
        end

        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Refresh Timer"))

        do
            local name = "Refresh Interval"
            local tooltip = "How often the information should be updated"
            local defaultValue = FpsLatencyMeterBaseConfig.refreshInterval
            local variable = "refreshInterval"
            local variableTbl = FpsLatencyMeterConfig
            local minValue = 1
            local maxValue = 60
            local step = 1

            local function GetValue()
                return FpsLatencyMeterBaseConfig.refreshInterval or defaultValue
            end

            local function SetValue(_, setting, value)
                value = tonumber(string.format("%d", value))
                OnSettingChanged(_, setting, value)
            end

            local setting = Settings.RegisterAddOnSetting(category, variable, variable, variableTbl, type(defaultValue),
                name,
                defaultValue, GetValue, SetValue)

            local options = Settings.CreateSliderOptions(minValue, maxValue, step)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
            Settings.CreateSlider(category, setting, options, tooltip)
        end

        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Text Colors"))

        local changeColorSetting, colorPickersSetting
        do
            local name = "Changing Color"
            local tooltip = "Changes the color according to the selected one below"
            local defaultValue = FpsLatencyMeterBaseConfig.changeColor
            local variable = "changeColor"
            local variableTbl = FpsLatencyMeterConfig

            changeColorSetting = Settings.RegisterAddOnSetting(category, variable, variable, variableTbl,
                type(defaultValue),
                name, defaultValue)
            Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
            Settings.CreateCheckbox(category, changeColorSetting, tooltip)
        end

        local colorData = {
            {
                label = "High Color (<15fps, >200ms)",
                key = "highColor",
            },
            {
                label = "Medium Color (<30fps, >100ms)",
                key = "mediumColor",
            },
            {
                label = "Low Color (>30fps, <100ms)",
                key = "lowColor",
            },
        }
        do
            colorPickersSetting = SettingsLib:CreateColorOverrides(category, {
                entries = colorData,
                hasOpacity = false,
                getColor = function(key)
                    local color = FpsLatencyMeterConfig[key] or FpsLatencyMeterBaseConfig[key]
                    return color[1], color[2], color[3], color[4]
                end,
                setColor = function(key, r, g, b, a)
                    local value = { r, g, b, a or 1 }
                    FpsLatencyMeterConfig[key] = value
                    TT:UpdateFrames()
                end,
                getDefaultColor = function(key)
                    local color = FpsLatencyMeterBaseConfig[key]
                    return color[1], color[2], color[3], color[4]
                end,
                colorizeLabel = false
            })
            colorPickersSetting:AddShownPredicate(function() return changeColorSetting:GetValue() end)
        end

        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Position Settings"))

        do
            local name = "Frame Position in X"
            local tooltip = "Position of the frame in X axis"
            local defaultValue = FpsLatencyMeterBaseConfig.frameX
            local variable = "frameX"
            local variableTbl = FpsLatencyMeterConfig
            local minValue = -4000
            local maxValue = 4000
            local step = 1

            local function GetValue()
                return FpsLatencyMeterConfig.frameX or defaultValue
            end

            local function SetValue(_, setting, value)
                value = tonumber(string.format("%d", value))
                OnSettingChanged(_, setting, value)
            end

            local setting = Settings.RegisterAddOnSetting(category, variable, variable, variableTbl, type(defaultValue),
                name,
                defaultValue, GetValue, SetValue)

            local options = Settings.CreateSliderOptions(minValue, maxValue, step)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
            Settings.CreateSlider(category, setting, options, tooltip)
        end

        do
            local name = "Frame Position in Y"
            local tooltip = "Position of the frame in Y axis"
            local defaultValue = FpsLatencyMeterBaseConfig.frameY
            local variable = "frameY"
            local variableTbl = FpsLatencyMeterConfig
            local minValue = -2000
            local maxValue = 2000
            local step = 1

            local function GetValue()
                return FpsLatencyMeterConfig.frameY or defaultValue
            end

            local function SetValue(_, setting, value)
                value = tonumber(string.format("%d", value))
                OnSettingChanged(_, setting, value)
            end

            local setting = Settings.RegisterAddOnSetting(category, variable, variable, variableTbl, type(defaultValue),
                name,
                defaultValue, GetValue, SetValue)

            local options = Settings.CreateSliderOptions(minValue, maxValue, step)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
            Settings.CreateSlider(category, setting, options, tooltip)
        end

        Settings.RegisterAddOnCategory(category)
    end

    SettingsRegistrar:AddRegistrant(Register)
elseif TT:IsClassic() then
    -- -- Methods to create widgets
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

        local r, g, b, a = unpack(initialColor)
        colorPicker:SetColor(r, g, b, a or 1)

        local currentColor = { r, g, b, a }

        local aceFrame = colorPicker.frame
        aceFrame:SetParent(parent)
        aceFrame:SetSize(width, height)
        aceFrame:Show()

        colorPicker:SetCallback("OnValueChanged", function(widget, event, newR, newG, newB, newA)
            currentColor = { newR, newG, newB, newA }
            SetColor(newR, newG, newB, newA or 1)
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

    -- Add to Blizzard settings
    local category = Settings.RegisterCanvasLayoutCategory(frame, frame.name, frame.name)
    Settings.FPS_LATENCY_CATEGORY_ID = category:GetID()
    Settings.RegisterAddOnCategory(category)

    frame:SetScript("OnShow", function(frame)
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

        options.showHomeLatency = newCheckbox(enableFeatures.content, "Show Home MS", "Shows MS (Home) indicator", 205,
            25,
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

        options.changeColor = newCheckbox(textColors.content, "Changing Color", "Changes Color depending on the Value",
            270,
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

        options.highColorSelector = newColorSelector(textColors.content, "High Color", "(<15fps, >200ms)", 250, 25,
            highColor,
            SetHighColor)
        textColors:AddChild(options.highColorSelector)

        options.mediumColorSelector = newColorSelector(textColors.content, "Medium Color", "(<30fps, >100ms)", 250, 25,
            mediumColor,
            SetMediumColor)
        textColors:AddChild(options.mediumColorSelector)

        options.lowColorSelector = newColorSelector(textColors.content, "Low Color", "(>30fps, <100ms)", 250, 25,
            lowColor,
            SetLowColor)
        textColors:AddChild(options.lowColorSelector)

        local refreshTimer = newInlineGroup(frame, "Flow", "Refresh Timer", 270, 90)
        refreshTimer:SetPoint("LEFT", textColors.frame, "RIGHT", 20, 0)

        options.refreshSlider = newSlider(refreshTimer.content, "Refresh Interval", 1, 60, 25, 25,
            function(widget, event, value)
                value = tonumber(string.format("%d", value))
                FpsLatencyMeterConfig.refreshInterval = value
                TT:UpdateFrames()
            end)
        options.refreshSlider:SetWidth(250)
        options.refreshSlider:SetHeight(15)
        refreshTimer:AddChild(options.refreshSlider)

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

        local resetcfg = newButton(frame, "Reset configuration",
            function()
                ResetCfg(options)
                frame:Refresh()
            end)
        resetcfg:SetPoint("LEFT", positionFrame.frame, "RIGHT", 70, 0)

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
end

-- for addon compartment (in .toc)
function OpenFpsLatencySettings()
    Settings.OpenToCategory(Settings.FPS_LATENCY_CATEGORY_ID)
end

SLASH_FPSLATENCY1 = "/fps"
SLASH_FPSLATENCY2 = "/latency"
SLASH_FPSLATENCY3 = "/ms"
function SlashCmdList.FPSLATENCY(msg)
    local cmd = strlower(msg)
    if (cmd == "reset") then
        ResetCfg()
        if TT:IsClassic() and frame:IsShown() then
            frame:Refresh()
        end
        print("|cff59f0dc" .. addOnTitle .. ":|r " .. "Configuration has been reset to default.")
    else
        OpenFpsLatencySettings()
    end
end
