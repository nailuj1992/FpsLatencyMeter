local addOnName = ...
GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local addOnVersion = GetAddOnMetadata(addOnName, "Version") or "0.0.1"
local addOnTitle = GetAddOnMetadata(addOnName, "Title") or "FpsLatencyMeter"

local clientVersionString = GetBuildInfo()
local clientBuildMajor = string.byte(clientVersionString, 1)

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

_G[addOnName] = {}
local TT = _G[addOnName]

function TT:GetDefaults()
    return {
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
        frameX = -610,
        frameY = -532,
    }
end

local function ResetColors(options)
    options.highColorLabel.colorPicker.SetDisabled(not FpsLatencyMeterConfig.changeColor)
    options.mediumColorLabel.colorPicker.SetDisabled(not FpsLatencyMeterConfig.changeColor)
    options.lowColorLabel.colorPicker.SetDisabled(not FpsLatencyMeterConfig.changeColor)

    if FpsLatencyMeterConfig.changeColor then
        options.highColorLabel.colorPicker:SetColor(unpack(FpsLatencyMeterConfig.highColor))
        options.mediumColorLabel.colorPicker:SetColor(unpack(FpsLatencyMeterConfig.mediumColor))
        options.lowColorLabel.colorPicker:SetColor(unpack(FpsLatencyMeterConfig.lowColor))
    end
end

local function resetCfg(options)
    FpsLatencyMeterConfig = TT:GetDefaults()
    if options then
        ResetColors(options)
    end
end

if not FpsLatencyMeterConfig then
    resetCfg()
end

-- main frame
local frame = CreateFrame("Frame", "Fps Latency Meter Options")
frame.name = addOnTitle
frame:Hide()

-- Add to Blizzard settings
local category = Settings.RegisterCanvasLayoutCategory(frame, frame.name, frame.name);
category.ID = frame.name
Settings.RegisterAddOnCategory(category);

frame:SetScript("OnShow", function(frame)
    local options = {}
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addOnTitle .. " v" .. addOnVersion)

    local function newCheckbox(name, label, description, onClick)
        local check = CreateFrame("CheckButton", "FpsLatencyOptCheckBox" .. name, frame,
            "InterfaceOptionsCheckButtonTemplate")
        check:SetScript("OnClick", function(self)
            local tick = self:GetChecked()
            onClick(self, tick and true or false)
        end)
        check.SetDisabled = function(self, disable)
            if disable then
                self:Disable()
                _G[self:GetName() .. 'Text']:SetFontObject('GameFontDisable')
            else
                self:Enable()
                _G[self:GetName() .. 'Text']:SetFontObject('GameFontHighlight')
            end
        end
        check.label = _G[check:GetName() .. "Text"]
        check.label:SetText(label)
        if (description) then
            check.tooltipText = label
            check.tooltipRequirement = description
        end
        return check
    end

    local function newSlider(name, label, minValue, maxValue, isVertical, onValueChanged)
        local slider = CreateFrame("Slider", "FpsLatencySlider" .. name, frame, "OptionsSliderTemplate")
        slider:SetMinMaxValues(minValue, maxValue)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)

        _G[slider:GetName() .. 'Low']:SetText(string.format("%s", minValue))
        _G[slider:GetName() .. 'High']:SetText(string.format("%s", maxValue))
        _G[slider:GetName() .. 'Text']:SetText(label)

        if isVertical then
            slider:SetOrientation("VERTICAL")

            -- Position high at the top of the slider
            _G[slider:GetName() .. 'Low']:ClearAllPoints()
            _G[slider:GetName() .. 'Low']:SetPoint("TOP", slider, "TOP", 0, 0)

            -- Position low at the bottom of the slider
            _G[slider:GetName() .. 'High']:ClearAllPoints()
            _G[slider:GetName() .. 'High']:SetPoint("BOTTOM", slider, "BOTTOM", 0, 0)

            -- Position label text to the right of the slider, centered vertically
            _G[slider:GetName() .. 'Text']:ClearAllPoints()
            _G[slider:GetName() .. 'Text']:SetPoint("RIGHT", slider, "LEFT", -10, 0)
        end

        slider:SetScript("OnValueChanged", onValueChanged)

        slider.SetDisabled = function(self, disable)
            if disable then
                self:Disable()
                _G[self:GetName() .. 'Text']:SetFontObject('GameFontDisable')
            else
                self:Enable()
                _G[self:GetName() .. 'Text']:SetFontObject('GameFontHighlight')
            end
        end

        return slider
    end

    local displaySettings = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    displaySettings:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    displaySettings:SetText("Display Settings")

    options.showFps = newCheckbox("ShowFps", "Show FPS", "Shows FPS indicator",
        function(self, value)
            FpsLatencyMeterConfig.fps = value
            TT:UpdateFrames()
        end)
    options.showFps:SetPoint("TOPLEFT", displaySettings, "BOTTOMLEFT", 0, -10)

    options.showLatency = newCheckbox("ShowLatency", "Show Latency", "Shows MS indicators",
        function(self, value)
            FpsLatencyMeterConfig.latency = value
            options.showHomeLatency:SetDisabled(not value)
            options.showWorldLatency:SetDisabled(not value)
            TT:UpdateFrames()
        end)
    options.showLatency:SetPoint("TOPLEFT", displaySettings, "BOTTOMLEFT", 140, -10)

    options.showHomeLatency = newCheckbox("ShowHomeLatency", "Show Home MS", "Shows MS (Home) indicator",
        function(self, value)
            FpsLatencyMeterConfig.latencyHome = value
            TT:UpdateFrames()
        end)
    options.showHomeLatency:SetPoint("TOPLEFT", displaySettings, "BOTTOMLEFT", 280, -10)

    options.showWorldLatency = newCheckbox("ShowWorldLatency", "Show World MS", "Shows MS (World) indicator",
        function(self, value)
            FpsLatencyMeterConfig.latencyWorld = value
            TT:UpdateFrames()
        end)
    options.showWorldLatency:SetPoint("TOPLEFT", displaySettings, "BOTTOMLEFT", 420, -10)

    local positionFrame = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    positionFrame:SetPoint("TOPLEFT", displaySettings, "BOTTOMLEFT", 300, -60)
    positionFrame:SetText("Position Settings")

    options.positionX = newSlider("PositionX", "Frame Position in X", -1200, 1200, false,
        function(self, value)
            value = tonumber(string.format("%d", value))
            FpsLatencyMeterConfig.frameX = value
            _G[self:GetName() .. 'Text']:SetText("Frame Position in X: " .. value)
            TT:UpdateFrames()
        end)
    options.positionX:SetWidth(250)
    options.positionX:SetHeight(15)
    options.positionX:SetPoint("TOPLEFT", positionFrame, "BOTTOMLEFT", 0, -30)

    options.positionY = newSlider("PositionY", "Frame Position in Y", -700, 700, false,
        function(self, value)
            value = tonumber(string.format("%d", value))
            FpsLatencyMeterConfig.frameY = value
            _G[self:GetName() .. 'Text']:SetText("Frame Position in Y: " .. value)
            TT:UpdateFrames()
        end)
    options.positionY:SetWidth(250)
    options.positionY:SetHeight(15)
    options.positionY:SetPoint("TOPLEFT", positionFrame, "BOTTOMLEFT", 0, -95)

    local refreshTimer = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    refreshTimer:SetPoint("TOPLEFT", displaySettings, "BOTTOMLEFT", 0, -60)
    refreshTimer:SetText("Refresh Timer")

    options.refreshSlider = newSlider("RefreshInterval", "Refresh Interval", 1, 60, false,
        function(self, value)
            value = tonumber(string.format("%d", value))
            FpsLatencyMeterConfig.refreshInterval = value
            _G[self:GetName() .. 'Text']:SetText("Refresh Interval: " .. value .. "s")
            TT:UpdateFrames()
        end)
    options.refreshSlider:SetWidth(250)
    options.refreshSlider:SetHeight(15)
    options.refreshSlider:SetPoint("TOPLEFT", refreshTimer, "BOTTOMLEFT", 0, -30)

    local textColors = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    textColors:SetPoint("TOPLEFT", displaySettings, "BOTTOMLEFT", 0, -150)
    textColors:SetText("Text Colors")

    options.changeColor = newCheckbox("ChangeColor", "Changing Color", "Changes Color depending on the Value",
        function(self, value)
            FpsLatencyMeterConfig.changeColor = value
            if value then
                options.highColorLabel.colorPicker.SetDisabled(false)
                options.mediumColorLabel.colorPicker.SetDisabled(false)
                options.lowColorLabel.colorPicker.SetDisabled(false)
            else
                options.highColorLabel.colorPicker.SetDisabled(true)
                options.mediumColorLabel.colorPicker.SetDisabled(true)
                options.lowColorLabel.colorPicker.SetDisabled(true)
            end
            TT:UpdateFrames()
        end)
    options.changeColor:SetPoint("TOPLEFT", textColors, "BOTTOMLEFT", 0, -10)

    local function newColorSelector(name, label, description, initialColor, SetColor)
        local colorLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        colorLabel:SetText(label)

        local colorPicker = AceGUI:Create("ColorPicker")
        colorPicker:SetLabel("")
        colorPicker:SetWidth(25)
        colorPicker:SetHeight(25)

        local r, g, b = unpack(initialColor)
        colorPicker:SetColor(r, g, b, 1) -- Alpha defaults to 1

        local currentColor = { r, g, b }

        local aceFrame = colorPicker.frame
        aceFrame:SetParent(frame)
        aceFrame:SetSize(25, 25)
        aceFrame:Show()

        colorPicker:SetCallback("OnValueChanged", function(widget, event, newR, newG, newB, newA)
            currentColor = { newR, newG, newB }
            SetColor(newR, newG, newB)
        end)

        aceFrame.tooltipText = label
        aceFrame.tooltipRequirement = description

        colorLabel.colorPicker = colorPicker

        colorPicker.SetDisabled = function(disable)
            if disable then
                aceFrame:Disable()
                colorLabel:SetFontObject("GameFontDisable")
            else
                aceFrame:Enable()
                colorLabel:SetFontObject("GameFontHighlight")
            end
        end

        return colorLabel, aceFrame
    end

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

    options.highColorLabel, options.highColorSwatch = newColorSelector("HighColorSelector", "High Color",
        "High Value Color (<15fps, >200ms)", highColor, SetHighColor)
    options.highColorSwatch:SetPoint("TOPLEFT", textColors, "BOTTOMLEFT", 20, -40)
    options.highColorLabel:SetPoint("LEFT", options.highColorSwatch, "RIGHT", 10, 0)

    options.mediumColorLabel, options.mediumColorSwatch = newColorSelector("MediumColorSelector", "Medium Color",
        "Medium Value Color (<30fps, >100ms)", mediumColor, SetMediumColor)
    options.mediumColorSwatch:SetPoint("TOPLEFT", textColors, "BOTTOMLEFT", 20, -70)
    options.mediumColorLabel:SetPoint("LEFT", options.mediumColorSwatch, "RIGHT", 10, 0)

    options.lowColorLabel, options.lowColorSwatch = newColorSelector("LowColorSelector", "Low Color",
        "Low Value Color (>30fps, <100ms)", lowColor, SetLowColor)
    options.lowColorSwatch:SetPoint("TOPLEFT", textColors, "BOTTOMLEFT", 20, -100)
    options.lowColorLabel:SetPoint("LEFT", options.lowColorSwatch, "RIGHT", 10, 0)

    local function getConfig()
        options.positionX:SetValue(FpsLatencyMeterConfig.frameX)
        options.positionY:SetValue(FpsLatencyMeterConfig.frameY)

        options.showFps:SetChecked(FpsLatencyMeterConfig.fps)
        options.showLatency:SetChecked(FpsLatencyMeterConfig.latency)

        options.showHomeLatency:SetDisabled(not FpsLatencyMeterConfig.latency)
        options.showWorldLatency:SetDisabled(not FpsLatencyMeterConfig.latency)

        if FpsLatencyMeterConfig.latency then
            options.showHomeLatency:SetChecked(FpsLatencyMeterConfig.latencyHome)
            options.showWorldLatency:SetChecked(FpsLatencyMeterConfig.latencyWorld)
        end

        options.refreshSlider:SetValue(FpsLatencyMeterConfig.refreshInterval or 1)
        options.changeColor:SetChecked(FpsLatencyMeterConfig.changeColor)

        ResetColors(options)
    end

    frame.Refresh = function()
        getConfig()
    end

    local resetcfg = CreateFrame("Button", "FpsLatencyOptButtonResetCfg", frame, "UIPanelButtonTemplate")
    resetcfg:SetText("Reset configuration")
    resetcfg:SetWidth(177)
    resetcfg:SetHeight(24)
    resetcfg:SetPoint("TOPLEFT", positionFrame, "BOTTOMLEFT", 0, -185)
    resetcfg:SetScript("OnClick", function()
        resetCfg(options)
        frame:Refresh()
    end)

    getConfig()

    frame:SetScript("OnShow", function()
        getConfig()
    end)
    frame:SetScript("OnHide", function()
        getConfig()
    end)
end)

-- SLASH_FPSLATENCY1 = "/fps";
-- SLASH_FPSLATENCY2 = "/latency";
-- SLASH_FPSLATENCY3 = "/ms";
-- SlashCmdList["FPSLATENCY"] = function(msg)
--     local cmd = strlower(msg)
--     if (cmd == "reset") then
--         resetCfg()
--         if (frame:IsShown()) then
--             frame:Refresh()
--         end
--         print("|cff59f0dc" .. addOnTitle .. ":|r " .. "Configuration has been reset to default.")
--     else
--         Settings.OpenToCategory(category.ID)
--     end
-- end
