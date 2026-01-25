local addOnName = ...
GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local addOnVersion = GetAddOnMetadata(addOnName, "Version") or "0.0.1"
local addOnTitle = GetAddOnMetadata(addOnName, "Title") or "FpsLatencyMeter"

local clientVersionString = GetBuildInfo()
local majorVersion = tonumber(string.match(clientVersionString, "^(%d+)%.?%d*"))

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local SettingsLib = LibStub and LibStub("LibEQOLSettingsMode-1.0", true)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

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
    fontName = "Friz Quadrata TT",
    fontSize = 14,
    frameFpsX = -150,
    frameFpsY = 0,
    frameLatencyHomeX = 0,
    frameLatencyHomeY = 0,
    frameLatencyWorldX = 170,
    frameLatencyWorldY = 0,
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
    fontName = FpsLatencyMeterBaseConfig.fontName,
    fontSize = FpsLatencyMeterBaseConfig.fontSize,
    frameFpsX = FpsLatencyMeterBaseConfig.frameFpsX,
    frameFpsY = FpsLatencyMeterBaseConfig.frameFpsY,
    frameLatencyHomeX = FpsLatencyMeterBaseConfig.frameLatencyHomeX,
    frameLatencyHomeY = FpsLatencyMeterBaseConfig.frameLatencyHomeY,
    frameLatencyWorldX = FpsLatencyMeterBaseConfig.frameLatencyWorldX,
    frameLatencyWorldY = FpsLatencyMeterBaseConfig.frameLatencyWorldY,
}

function TT:ResetPositions()
    FpsLatencyMeterConfig.frameFpsX = FpsLatencyMeterBaseConfig.frameFpsX
    FpsLatencyMeterConfig.frameFpsY = FpsLatencyMeterBaseConfig.frameFpsY
    FpsLatencyMeterConfig.frameLatencyHomeX = FpsLatencyMeterBaseConfig.frameLatencyHomeX
    FpsLatencyMeterConfig.frameLatencyHomeY = FpsLatencyMeterBaseConfig.frameLatencyHomeY
    FpsLatencyMeterConfig.frameLatencyWorldX = FpsLatencyMeterBaseConfig.frameLatencyWorldX
    FpsLatencyMeterConfig.frameLatencyWorldY = FpsLatencyMeterBaseConfig.frameLatencyWorldY
end

function TT:ResetSettings()
    FpsLatencyMeterConfig.fps = FpsLatencyMeterBaseConfig.fps
    FpsLatencyMeterConfig.latency = FpsLatencyMeterBaseConfig.latency
    FpsLatencyMeterConfig.latencyHome = FpsLatencyMeterBaseConfig.latencyHome
    FpsLatencyMeterConfig.latencyWorld = FpsLatencyMeterBaseConfig.latencyWorld
    FpsLatencyMeterConfig.refreshInterval = FpsLatencyMeterBaseConfig.refreshInterval
    FpsLatencyMeterConfig.changeColor = FpsLatencyMeterBaseConfig.changeColor
    FpsLatencyMeterConfig.highColor = FpsLatencyMeterBaseConfig.highColor
    FpsLatencyMeterConfig.mediumColor = FpsLatencyMeterBaseConfig.mediumColor
    FpsLatencyMeterConfig.lowColor = FpsLatencyMeterBaseConfig.lowColor
    FpsLatencyMeterConfig.fontName = FpsLatencyMeterBaseConfig.fontName
    FpsLatencyMeterConfig.fontSize = FpsLatencyMeterBaseConfig.fontSize
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
    TT:ResetSettings()
    if options and false then -- TT:IsClassic()
        ResetColors(options)
    end
    if TT:IsRetail() or TT:IsClassic() then
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
            "fontName",
            "fontSize",
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
local frame = CreateFrame("Frame", addOnTitle)
frame.name = addOnTitle
frame:Hide()

local function GetPositionLimits()
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()

    local xMultiplier = 2 -- How many screen widths to allow
    local yMultiplier = 2 -- How many screen heights to allow

    return {
        minX = -screenWidth * xMultiplier,
        maxX = screenWidth * xMultiplier,
        minY = -screenHeight * yMultiplier,
        maxY = screenHeight * yMultiplier
    }
end

local limits = GetPositionLimits()
local minValueX = limits.minX
local maxValueX = limits.maxX
local minValueY = limits.minY
local maxValueY = limits.maxY

if TT:IsRetail() or TT:IsClassic() then
    local function Register()
        local category, layout = Settings.RegisterVerticalLayoutCategory(addOnTitle)
        Settings.FPS_LATENCY_CATEGORY_ID = category:GetID()

        -- Function to create a slider with a parent section
        local function CreateParentedSlider(tbdb, tbvar, parentSection, prefix, key, name, default, min, max, step,
                                            set, desc)
            local initializer, setting = SettingsLib:CreateSlider(category, {
                parentSection = parentSection,
                prefix = prefix,
                key = key,
                name = name,
                default = default,
                min = min,
                max = max,
                step = step,
                formatter = function(value)
                    return string.format("%d", value)
                end,
                get = function()
                    return tbdb[tbvar]
                end,
                set = function(value)
                    value = tonumber(string.format("%d", value))
                    tbdb[tbvar] = value
                    if set then
                        set()
                    end
                end,
                desc = desc,
            })
            return initializer, setting
        end

        --------------------------------------------------------------------------------
        -- HEADER SECTION
        --------------------------------------------------------------------------------
        SettingsLib:CreateHeader(category, {
            name = "Version " .. addOnVersion,
        })
        SettingsLib:CreateText(category, {
            name =
            "Here, you can configure the settings of the |cff87bbcaFpsLatencyMeter|r addon.",
        })
        SettingsLib:CreateText(category, {
            name =
            "The |cff87bbcaFpsLatencyMeter|r addon is a simple addon that displays the FPS and the Latency of the player in the screen.",
        })
        SettingsLib:CreateText(category, {
            name =
            "The |cff87bbcaFpsLatencyMeter|r addon is free and open source, you can find the source code on |cff00ff00Github|r.",
        })
        SettingsLib:CreateText(category, {
            name =
            "If you have any questions or suggestions, please visit the |cff87bbcaFpsLatencyMeter|r addon page on |cff00ff00CurseForge|r.",
        })

        --------------------------------------------------------------------------------
        -- REFRESH TIMER SECTION
        --------------------------------------------------------------------------------
        local refreshTimerSection = SettingsLib:CreateExpandableSection(category, {
            name = "Refresh Timer",
            expanded = true,
            colorizeTitle = false,
        })

        do
            local initializer, setting = CreateParentedSlider(FpsLatencyMeterConfig, "refreshInterval",
                refreshTimerSection, "FPS_MS_", "fps_ms_refresh_timer", "Refresh Interval",
                FpsLatencyMeterBaseConfig.refreshInterval, 1, 60, 1, TT:UpdateFrames(),
                "How often the information should be updated")
        end

        --------------------------------------------------------------------------------
        -- ENABLE FEATURES SECTION
        --------------------------------------------------------------------------------
        local enableFeaturesSection = SettingsLib:CreateExpandableSection(category, {
            name = "Enable Features",
            expanded = false,
            colorizeTitle = false,
        })

        -- FPS
        local fpsSetting, fpsInitializer
        do
            fpsInitializer, fpsSetting = SettingsLib:CreateCheckbox(category, {
                parentSection = enableFeaturesSection,
                prefix = "FPS_",
                key = "fps_show_text",
                name = "Show FPS",
                default = FpsLatencyMeterBaseConfig.fps,
                get = function()
                    return FpsLatencyMeterConfig.fps
                end,
                set = function(value)
                    FpsLatencyMeterConfig.fps = value
                    TT:UpdateFrames()
                end,
                desc = "Shows FPS indicator",
            })
        end

        do
            local initializer, setting = CreateParentedSlider(FpsLatencyMeterConfig, "frameFpsX", enableFeaturesSection,
                "FPS_", "fps_x_offset", "X Offset", FpsLatencyMeterBaseConfig.frameFpsX, minValueX, maxValueX, 1,
                TT:UpdateFrames(), "Position of the text in X axis")
            initializer:AddShownPredicate(function() return fpsSetting:GetValue() end)

            local function IsSectionEnabled()
                return FpsLatencyMeterBaseConfig.fps
            end

            initializer:SetParentInitializer(fpsInitializer, fpsInitializer.IsSectionEnabled or IsSectionEnabled)
        end

        do
            local initializer, setting = CreateParentedSlider(FpsLatencyMeterConfig, "frameFpsY", enableFeaturesSection,
                "FPS_", "fps_y_offset", "Y Offset", FpsLatencyMeterBaseConfig.frameFpsY, minValueY, maxValueY, 1,
                TT:UpdateFrames(), "Position of the text in Y axis")
            initializer:AddShownPredicate(function() return fpsSetting:GetValue() end)

            local function IsSectionEnabled()
                return FpsLatencyMeterBaseConfig.fps
            end

            initializer:SetParentInitializer(fpsInitializer, fpsInitializer.IsSectionEnabled or IsSectionEnabled)
        end

        -- Latency
        local latencySetting, latencyInitializer
        do
            latencyInitializer, latencySetting = SettingsLib:CreateCheckbox(category, {
                parentSection = enableFeaturesSection,
                prefix = "MS_",
                key = "ms_show_text",
                name = "Show MS",
                default = FpsLatencyMeterBaseConfig.latency,
                get = function()
                    return FpsLatencyMeterConfig.latency
                end,
                set = function(value)
                    FpsLatencyMeterConfig.latency = value
                    TT:UpdateFrames()
                end,
                desc = "Shows MS indicators",
            })
        end

        -- Latency Home
        local latencyHomeSetting, latencyHomeInitializer
        do
            latencyHomeInitializer, latencyHomeSetting = SettingsLib:CreateCheckbox(category, {
                parentSection = enableFeaturesSection,
                prefix = "MS_",
                key = "ms_home_show_text",
                name = "Show Home MS",
                default = FpsLatencyMeterBaseConfig.latencyHome,
                get = function()
                    return FpsLatencyMeterConfig.latencyHome
                end,
                set = function(value)
                    FpsLatencyMeterConfig.latencyHome = value
                    TT:UpdateFrames()
                end,
                desc = "Shows MS (Home) indicator",
            })
            latencyHomeInitializer:AddShownPredicate(function() return latencySetting:GetValue() end)

            local function IsSectionEnabled()
                return FpsLatencyMeterBaseConfig.latency
            end

            latencyHomeInitializer:SetParentInitializer(latencyInitializer,
                latencyInitializer.IsSectionEnabled or IsSectionEnabled)
        end

        do
            local initializer, setting = CreateParentedSlider(FpsLatencyMeterConfig, "frameLatencyHomeX",
                enableFeaturesSection, "MS_", "ms_home_x_offset", "Home MS: X Offset",
                FpsLatencyMeterBaseConfig.frameLatencyHomeX, minValueX, maxValueX, 1,
                TT:UpdateFrames(), "Position of the text in X axis")
            initializer:AddShownPredicate(function() return latencySetting:GetValue() and latencyHomeSetting:GetValue() end)

            local function IsSectionEnabled()
                return FpsLatencyMeterBaseConfig.latency and FpsLatencyMeterBaseConfig.latencyHome
            end

            initializer:SetParentInitializer(latencyHomeInitializer,
                latencyHomeInitializer.IsSectionEnabled or IsSectionEnabled)
        end

        do
            local initializer, setting = CreateParentedSlider(FpsLatencyMeterConfig, "frameLatencyHomeY",
                enableFeaturesSection, "MS_", "ms_home_y_offset", "Home MS: Y Offset",
                FpsLatencyMeterBaseConfig.frameLatencyHomeY, minValueY, maxValueY, 1,
                TT:UpdateFrames(), "Position of the text in Y axis")

            initializer:AddShownPredicate(function() return latencySetting:GetValue() and latencyHomeSetting:GetValue() end)

            local function IsSectionEnabled()
                return FpsLatencyMeterBaseConfig.latency and FpsLatencyMeterBaseConfig.latencyHome
            end

            initializer:SetParentInitializer(latencyHomeInitializer,
                latencyHomeInitializer.IsSectionEnabled or IsSectionEnabled)
        end

        -- Latency World
        local latencyWorldSetting, latencyWorldInitializer
        do
            latencyWorldInitializer, latencyWorldSetting = SettingsLib:CreateCheckbox(category, {
                parentSection = enableFeaturesSection,
                prefix = "MS_",
                key = "ms_world_show_text",
                name = "Show World MS",
                default = FpsLatencyMeterBaseConfig.latencyWorld,
                get = function()
                    return FpsLatencyMeterConfig.latencyWorld
                end,
                set = function(value)
                    FpsLatencyMeterConfig.latencyWorld = value
                    TT:UpdateFrames()
                end,
                desc = "Shows MS (World) indicator",
            })
            latencyWorldInitializer:AddShownPredicate(function() return latencySetting:GetValue() end)

            local function IsSectionEnabled()
                return FpsLatencyMeterBaseConfig.latency
            end

            latencyWorldInitializer:SetParentInitializer(latencyInitializer,
                latencyInitializer.IsSectionEnabled or IsSectionEnabled)
        end

        do
            local initializer, setting = CreateParentedSlider(FpsLatencyMeterConfig, "frameLatencyWorldX",
                enableFeaturesSection, "MS_", "ms_world_x_offset", "World MS: X Offset",
                FpsLatencyMeterBaseConfig.frameLatencyWorldX, minValueX, maxValueX, 1,
                TT:UpdateFrames(), "Position of the text in X axis")
            initializer:AddShownPredicate(function() return latencySetting:GetValue() and latencyWorldSetting:GetValue() end)

            local function IsSectionEnabled()
                return FpsLatencyMeterBaseConfig.latency and FpsLatencyMeterBaseConfig.latencyWorld
            end

            initializer:SetParentInitializer(latencyWorldInitializer,
                latencyWorldInitializer.IsSectionEnabled or IsSectionEnabled)
        end

        do
            local initializer, setting = CreateParentedSlider(FpsLatencyMeterConfig, "frameLatencyWorldY",
                enableFeaturesSection, "MS_", "ms_world_y_offset", "World MS: Y Offset",
                FpsLatencyMeterBaseConfig.frameLatencyWorldY, minValueY, maxValueY, 1,
                TT:UpdateFrames(), "Position of the text in Y axis")
            initializer:AddShownPredicate(function() return latencySetting:GetValue() and latencyWorldSetting:GetValue() end)

            local function IsSectionEnabled()
                return FpsLatencyMeterBaseConfig.latency and FpsLatencyMeterBaseConfig.latencyWorld
            end

            initializer:SetParentInitializer(latencyWorldInitializer,
                latencyWorldInitializer.IsSectionEnabled or IsSectionEnabled)
        end

        --------------------------------------------------------------------------------
        -- OTHER OPTIONS SECTION
        --------------------------------------------------------------------------------
        local otherSection = SettingsLib:CreateExpandableSection(category, {
            name = "Other options",
            expanded = false,
            colorizeTitle = false,
        })

        -- Font dropdown
        do
            SettingsLib:CreateScrollDropdown(category, {
                parentSection = otherSection,
                prefix = "FPS_MS_",
                key = "fps_ms_font_name",
                name = "Font",
                default = FpsLatencyMeterBaseConfig.fontName,
                height = 220,
                get = function()
                    return FpsLatencyMeterConfig.fontName
                end,
                set = function(value)
                    FpsLatencyMeterConfig.fontName = value
                    TT:UpdateFrames()
                end,
                desc = "Select the font for the text to be displayed",
                generator = function(dropdown, rootDescription)
                    dropdown.fontPool = {}
                    if not dropdown._FPS_MS_FontFace_Dropdown_OnMenuClosed_hooked then
                        hooksecurefunc(dropdown, "OnMenuClosed", function()
                            for _, fontDisplay in pairs(dropdown.fontPool) do
                                fontDisplay:Hide()
                            end
                        end)
                        dropdown._FPS_MS_FontFace_Dropdown_OnMenuClosed_hooked = true
                    end
                    local fonts = LSM:HashTable(LSM.MediaType.FONT)
                    local sortedFonts = {}
                    for fontName in pairs(fonts) do
                        if fontName ~= "" then
                            table.insert(sortedFonts, fontName)
                        end
                    end
                    table.sort(sortedFonts)

                    for index, fontName in ipairs(sortedFonts) do
                        local fontPath = fonts[fontName]

                        local button = rootDescription:CreateRadio(fontName, function()
                            return FpsLatencyMeterConfig.fontName == fontName
                        end, function()
                            FpsLatencyMeterConfig.fontName = fontName
                            TT:UpdateFrames()
                            dropdown:SetText(fontName)
                        end)

                        button:AddInitializer(function(self)
                            local fontDisplay = dropdown.fontPool[index]
                            if not fontDisplay then
                                fontDisplay = dropdown:CreateFontString(nil, "BACKGROUND")
                                dropdown.fontPool[index] = fontDisplay
                            end

                            self.fontString:Hide()

                            fontDisplay:SetParent(self)
                            fontDisplay:SetPoint("LEFT", self.fontString, "LEFT", 0, 0)
                            fontDisplay:SetFont(fontPath, 12)
                            fontDisplay:SetText(fontName)
                            fontDisplay:Show()
                        end)
                    end
                end,
            })
        end

        -- Font size
        do
            local initializer, setting = CreateParentedSlider(FpsLatencyMeterConfig, "fontSize",
                otherSection, "FPS_MS_", "fps_ms_font_size", "Font Size",
                FpsLatencyMeterBaseConfig.fontSize, 8, 50, 1, TT:UpdateFrames(),
                "The font size of the text to be displayed")
        end

        -- Changing Color checkbox
        local changeColorSetting, colorPickersSetting
        local colorDescription = "Changes the color of the text according to the selected one below"
        if TT:IsClassic() then
            colorDescription =
                "Changes the color of the text, depending on the FPS and MS.\n\n"
                .. TT:ToWoWColorCode(FpsLatencyMeterConfig.highColor[1], FpsLatencyMeterConfig.highColor[2],
                    FpsLatencyMeterConfig.highColor[3]) .. "Red for < 15 fps or > 200 ms|r\n\n"
                .. TT:ToWoWColorCode(FpsLatencyMeterConfig.mediumColor[1], FpsLatencyMeterConfig.mediumColor[2],
                    FpsLatencyMeterConfig.mediumColor[3]) .. "Green for < 30 fps or > 100 ms|r\n\n"
                .. TT:ToWoWColorCode(FpsLatencyMeterConfig.lowColor[1], FpsLatencyMeterConfig.lowColor[2],
                    FpsLatencyMeterConfig.lowColor[3]) .. "Blue for > 30 fps or < 100 ms|r"
        end
        do
            colorPickersSetting, changeColorSetting = SettingsLib:CreateCheckbox(category, {
                parentSection = otherSection,
                prefix = "FPS_MS_",
                key = "fps_ms_show_colors",
                name = "Changing Color",
                default = FpsLatencyMeterBaseConfig.changeColor,
                get = function()
                    return FpsLatencyMeterConfig.changeColor
                end,
                set = function(value)
                    FpsLatencyMeterConfig.changeColor = value
                    TT:UpdateFrames()
                end,
                desc = colorDescription,
            })
        end

        -- Color pickers
        if TT:IsRetail() then
            local colorData = {
                {
                    label = "High Color (< 15 fps, > 200 ms)",
                    key = "highColor",
                },
                {
                    label = "Medium Color (< 30 fps, > 100 ms)",
                    key = "mediumColor",
                },
                {
                    label = "Low Color (> 30 fps, < 100 ms)",
                    key = "lowColor",
                },
            }
            do
                colorPickersSetting = SettingsLib:CreateColorOverrides(category, {
                    parentSection = otherSection,
                    prefix = "FPS_MS_",
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
                    colorizeLabel = true
                })
                colorPickersSetting:AddShownPredicate(function() return changeColorSetting:GetValue() end)
            end
        end

        Settings.RegisterAddOnCategory(category)
    end

    SettingsRegistrar:AddRegistrant(Register)
elseif false then -- TT:IsClassic()
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
    local function newSimpleGroup(parent, layout)
        local group = AceGUI:Create("SimpleGroup")
        group:SetFullWidth(true)
        group:SetLayout(layout)

        local aceFrame = group.frame
        aceFrame:SetParent(parent)
        -- aceFrame:SetSize(width, height)
        aceFrame:Show()

        return group
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

        local enableFeatures = newInlineGroup(frame, "Flow", "Enable Features", 635, 250)
        enableFeatures:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

        local sectionFps = newSimpleGroup(enableFeatures.content, "Flow")
        enableFeatures:AddChild(sectionFps)

        options.showFps = newCheckbox(sectionFps.content, "Show FPS", "Shows FPS indicator", 170, 25,
            function(widget, event, value)
                FpsLatencyMeterConfig.fps = value
                TT:UpdateFrames()
            end)
        sectionFps:AddChild(options.showFps)

        options.fpsPositionX = newSlider(sectionFps.content, "Frame Position in X", minValueX, maxValueX, 180, 60,
            function(widget, event, value)
                value = tonumber(string.format("%d", value))
                FpsLatencyMeterConfig.frameFpsX = value
                TT:UpdateFrames()
            end)
        sectionFps:AddChild(options.fpsPositionX)

        options.fpsPositionY = newSlider(sectionFps.content, "Frame Position in Y", minValueY, maxValueY, 180, 60,
            function(widget, event, value)
                value = tonumber(string.format("%d", value))
                FpsLatencyMeterConfig.frameFpsY = value
                TT:UpdateFrames()
            end)
        sectionFps:AddChild(options.fpsPositionY)

        local sectionLatency = newSimpleGroup(enableFeatures.content, "Flow")
        enableFeatures:AddChild(sectionLatency)

        options.showLatency = newCheckbox(sectionLatency.content, "Show Latency", "Shows MS indicators", 170, 25,
            function(widget, event, value)
                FpsLatencyMeterConfig.latency = value
                options.showHomeLatency:SetDisabled(not value)
                options.showWorldLatency:SetDisabled(not value)
                TT:UpdateFrames()
            end)
        sectionLatency:AddChild(options.showLatency)

        local sectionLatencyHome = newSimpleGroup(enableFeatures.content, "Flow")
        enableFeatures:AddChild(sectionLatencyHome)

        options.showHomeLatency = newCheckbox(sectionLatencyHome.content, "Show Home MS", "Shows MS (Home) indicator",
            205, 25, function(widget, event, value)
                FpsLatencyMeterConfig.latencyHome = value
                TT:UpdateFrames()
            end)
        sectionLatencyHome:AddChild(options.showHomeLatency)

        options.latencyHomePositionX = newSlider(sectionLatencyHome.content, "Frame Position in X", minValueX, maxValueX,
            180, 60, function(widget, event, value)
                value = tonumber(string.format("%d", value))
                FpsLatencyMeterConfig.frameLatencyHomeX = value
                TT:UpdateFrames()
            end)
        sectionLatencyHome:AddChild(options.latencyHomePositionX)

        options.latencyHomePositionY = newSlider(sectionLatencyHome.content, "Frame Position in Y", minValueY, maxValueY,
            180, 60, function(widget, event, value)
                value = tonumber(string.format("%d", value))
                FpsLatencyMeterConfig.frameLatencyHomeY = value
                TT:UpdateFrames()
            end)
        sectionLatencyHome:AddChild(options.latencyHomePositionY)

        local sectionLatencyWorld = newSimpleGroup(enableFeatures.content, "Flow")
        enableFeatures:AddChild(sectionLatencyWorld)

        options.showWorldLatency = newCheckbox(sectionLatencyWorld.content, "Show World MS", "Shows MS (World) indicator",
            205, 25, function(widget, event, value)
                FpsLatencyMeterConfig.latencyWorld = value
                TT:UpdateFrames()
            end)
        sectionLatencyWorld:AddChild(options.showWorldLatency)

        options.latencyWorldPositionX = newSlider(sectionLatencyWorld.content, "Frame Position in X", minValueX,
            maxValueX, 180, 60, function(widget, event, value)
                value = tonumber(string.format("%d", value))
                FpsLatencyMeterConfig.frameLatencyWorldX = value
                TT:UpdateFrames()
            end)
        sectionLatencyWorld:AddChild(options.latencyWorldPositionX)

        options.latencyWorldPositionY = newSlider(sectionLatencyWorld.content, "Frame Position in Y", minValueY,
            maxValueY, 180, 60, function(widget, event, value)
                value = tonumber(string.format("%d", value))
                FpsLatencyMeterConfig.frameLatencyWorldY = value
                TT:UpdateFrames()
            end)
        sectionLatencyWorld:AddChild(options.latencyWorldPositionY)

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

        local resetcfg = newButton(frame, "Reset configuration",
            function()
                ResetCfg(options)
                frame:Refresh()
            end)
        resetcfg:SetPoint("TOP", refreshTimer.frame, "BOTTOM", 0, 0)

        local function getConfig()
            options.fpsPositionX:SetValue(FpsLatencyMeterConfig.frameFpsX)
            options.fpsPositionY:SetValue(FpsLatencyMeterConfig.frameFpsY)
            options.latencyHomePositionX:SetValue(FpsLatencyMeterConfig.frameLatencyHomeX)
            options.latencyHomePositionY:SetValue(FpsLatencyMeterConfig.frameLatencyHomeY)
            options.latencyWorldPositionX:SetValue(FpsLatencyMeterConfig.frameLatencyWorldX)
            options.latencyWorldPositionY:SetValue(FpsLatencyMeterConfig.frameLatencyWorldY)

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

local function ActionResetPositions()
    TT:ResetPositions()
    print("|cff59f0dc" .. addOnTitle .. ":|r " .. "Positions have been reset to default.")
end

local function ActionResetSettings(reloadUI)
    ResetCfg()
    if reloadUI then
        ReloadUI()
    else
        print("|cff59f0dc" .. addOnTitle .. ":|r " .. "Configuration has been reset to default.")
    end
end

hooksecurefunc(SettingsPanel, "DisplayCategory", function(self, category)
    if TT:IsRetail() or TT:IsClassic() then
        local header = SettingsPanel.Container.SettingsList.Header
        if category:GetID() == Settings.FPS_LATENCY_CATEGORY_ID then
            if not header.FpsLatencyMeter_ResetPositions then
                header.FpsLatencyMeter_ResetPositions = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
                header.FpsLatencyMeter_ResetPositions:SetPoint("RIGHT", header.DefaultsButton, "LEFT", -10, 0)
                header.FpsLatencyMeter_ResetPositions:SetSize(header.DefaultsButton:GetSize())
                header.FpsLatencyMeter_ResetPositions:SetText("Reset Positions")
                header.FpsLatencyMeter_ResetPositions:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    GameTooltip:ClearLines()
                    GameTooltip:SetText("Resets all positions to default")
                    GameTooltip:Show()
                end)
                header.FpsLatencyMeter_ResetPositions:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
                header.FpsLatencyMeter_ResetPositions:SetScript("OnClick", function()
                    SettingsPanel:Hide()
                    ActionResetPositions()
                end)
            end
            if not header.FpsLatencyMeter_ResetSettings then
                header.FpsLatencyMeter_ResetSettings = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
                header.FpsLatencyMeter_ResetSettings:SetPoint("LEFT", header.DefaultsButton, "LEFT", 0, 0)
                header.FpsLatencyMeter_ResetSettings:SetSize(header.DefaultsButton:GetSize())
                header.FpsLatencyMeter_ResetSettings:SetText("Reset Settings")
                header.FpsLatencyMeter_ResetSettings:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    GameTooltip:ClearLines()
                    GameTooltip:SetText("Resets all settings to default (except positions)")
                    GameTooltip:Show()
                end)
                header.FpsLatencyMeter_ResetSettings:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
                header.FpsLatencyMeter_ResetSettings:SetScript("OnClick", function()
                    SettingsPanel:Hide()
                    ActionResetSettings(false)
                end)
            end

            header.FpsLatencyMeter_ResetPositions:Show()
            header.FpsLatencyMeter_ResetSettings:Show()

            if header.DefaultsButton:IsShown() then
                header.DefaultsButton:Hide()
            end
        else
            if header.FpsLatencyMeter_ResetPositions then
                header.FpsLatencyMeter_ResetPositions:Hide()
            end
            if header.FpsLatencyMeter_ResetSettings then
                header.FpsLatencyMeter_ResetSettings:Hide()
            end
            if not header.DefaultsButton:IsShown() then
                header.DefaultsButton:Show()
            end
        end
    end
end)

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
        if false and frame:IsShown() then -- TT:IsClassic()
            frame:Refresh()
        end
        ActionResetSettings(true)
    else
        OpenFpsLatencySettings()
    end
end
