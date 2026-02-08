local addOnName = ...
GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local addOnVersion = GetAddOnMetadata(addOnName, "Version") or "0.0.1"
local addOnTitle = GetAddOnMetadata(addOnName, "Title") or "FpsLatencyMeter"

local clientVersionString = GetBuildInfo()
local majorVersion = tonumber(string.match(clientVersionString, "^(%d+)%.?%d*"))

local SettingsLib = LibStub and LibStub("LibEQOLSettingsMode-1.0", true)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

_G[addOnName] = {}
local TT = _G[addOnName]

local SupportedExpansions = {
    [1] = "Classic",
    [2] = "The Burning Crusade",
    [5] = "Mists of Pandaria",
    [12] = "Midnight",
}

function TT:IsRetail()
    return majorVersion >= 12 -- Midnight
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
    contentFPS = "# FPS",
    contentHomeMS = "# ms (Home)",
    contentWorldMS = "# ms (World)",
    fontName = "Friz Quadrata TT",
    fontSize = 14,
    frameFpsX = -150,
    frameFpsY = 0,
    frameFpsAlign = "CENTER",
    frameLatencyHomeX = 0,
    frameLatencyHomeY = 0,
    frameLatencyHomeAlign = "CENTER",
    frameLatencyWorldX = 170,
    frameLatencyWorldY = 0,
    frameLatencyWorldAlign = "CENTER",
}

local function InitConfig()
    -- Initialize if it doesn't exist
    FpsLatencyMeterConfig = FpsLatencyMeterConfig or {}

    -- Ensure all default values exist in the config
    for key, defaultValue in pairs(FpsLatencyMeterBaseConfig) do
        if FpsLatencyMeterConfig[key] == nil then
            if type(defaultValue) == "table" then
                -- For tables (like colors), create a copy
                FpsLatencyMeterConfig[key] = {}
                for k, v in pairs(defaultValue) do
                    FpsLatencyMeterConfig[key][k] = v
                end
            else
                -- For simple values
                FpsLatencyMeterConfig[key] = defaultValue
            end
        end
    end

    return FpsLatencyMeterConfig
end

-- Initialize the configuration
FpsLatencyMeterConfig = InitConfig()

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- This function copies values from one table into another:
        local function copyDefaults(src, dst)
            -- If no source (defaults) is specified, return an empty table:
            if type(src) ~= "table" then return {} end
            -- If no target (saved variable) is specified, create a new table:
            if not type(dst) then dst = {} end
            -- Loop through the source (defaults):
            for k, v in pairs(src) do
                -- If the value is a sub-table:
                if type(v) == "table" then
                    -- Recursively call the function:
                    dst[k] = copyDefaults(v, dst[k])
                    -- Or if the default value type doesn't match the existing value type:
                elseif type(v) ~= type(dst[k]) then
                    -- Overwrite the existing value with the default one:
                    dst[k] = v
                end
            end
            -- Return the destination table:
            return dst
        end

        -- Copy the values from the defaults table into the saved variables table
        -- if it exists, and assign the result to the saved variable:
        FpsLatencyMeterConfig = copyDefaults(FpsLatencyMeterBaseConfig, FpsLatencyMeterConfig)
    end
end)

local function ResetPositions()
    FpsLatencyMeterConfig.frameFpsX = FpsLatencyMeterBaseConfig.frameFpsX
    FpsLatencyMeterConfig.frameFpsY = FpsLatencyMeterBaseConfig.frameFpsY
    FpsLatencyMeterConfig.frameFpsAlign = FpsLatencyMeterBaseConfig.frameFpsAlign
    FpsLatencyMeterConfig.frameLatencyHomeX = FpsLatencyMeterBaseConfig.frameLatencyHomeX
    FpsLatencyMeterConfig.frameLatencyHomeY = FpsLatencyMeterBaseConfig.frameLatencyHomeY
    FpsLatencyMeterConfig.frameLatencyHomeAlign = FpsLatencyMeterBaseConfig.frameLatencyHomeAlign
    FpsLatencyMeterConfig.frameLatencyWorldX = FpsLatencyMeterBaseConfig.frameLatencyWorldX
    FpsLatencyMeterConfig.frameLatencyWorldY = FpsLatencyMeterBaseConfig.frameLatencyWorldY
    FpsLatencyMeterConfig.frameLatencyWorldAlign = FpsLatencyMeterBaseConfig.frameLatencyWorldAlign
end

local function ResetSettings()
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
    FpsLatencyMeterConfig.contentFPS = FpsLatencyMeterBaseConfig.contentFPS
    FpsLatencyMeterConfig.contentHomeMS = FpsLatencyMeterBaseConfig.contentHomeMS
    FpsLatencyMeterConfig.contentWorldMS = FpsLatencyMeterBaseConfig.contentWorldMS
end

local function ResetCfg()
    ResetSettings()
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
        "contentFPS",
        "contentHomeMS",
        "contentWorldMS",
    }
    for _, variable in ipairs(settingsToUpdate) do
        Settings.NotifyUpdate(variable)
    end
end

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

    local function CreateParentedScrollDown(tbdb, tbvar, map, parent, prefix, key, name, default, height, set, desc)
        local initializer, setting = SettingsLib:CreateScrollDropdown(category, {
            parentSection = parent,
            prefix = prefix,
            key = key,
            name = name,
            default = default,
            height = height,
            get = function()
                return map[tbdb[tbvar]]
            end,
            set = function(value)
                tbdb[tbvar] = value
                if set then
                    set()
                end
            end,
            desc = "Select the alignment of the text",
            generator = function(dropdown, rootDescription)
                local index = 1
                for key, label in pairs(map) do
                    local button = rootDescription:CreateRadio(label, function()
                        return tbdb[tbvar] == key
                    end, function()
                        tbdb[tbvar] = key
                        if set then
                            set()
                        end
                        dropdown:SetText(label)
                    end)
                    index = index + 1
                end
            end,
        })
        return initializer, setting
    end

    --------------------------------------------------------------------------------
    -- HEADER SECTION
    --------------------------------------------------------------------------------
    local name = "Version " .. addOnVersion
    if SupportedExpansions[majorVersion] then
        name = name .. " for " .. SupportedExpansions[majorVersion]
    end
    SettingsLib:CreateHeader(category, {
        name = name,
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

    local alignmentsMap = {
        ["LEFT"] = "Left",
        ["CENTER"] = "Center",
        ["RIGHT"] = "Right",
    }
    do
        local initializer, setting = CreateParentedScrollDown(FpsLatencyMeterConfig, "frameFpsAlign", alignmentsMap,
            enableFeaturesSection, "FPS_", "fps_text_align", "Alignment", FpsLatencyMeterBaseConfig.frameFpsAlign, 220,
            TT:UpdateFrames(), "Select the alignment of the text")
        initializer:AddShownPredicate(function() return fpsSetting:GetValue() end)

        local function IsSectionEnabled()
            return FpsLatencyMeterBaseConfig.fps
        end

        initializer:SetParentInitializer(fpsInitializer, fpsInitializer.IsSectionEnabled or IsSectionEnabled)
    end

    do
        local initializer, setting = SettingsLib:CreateInput(category, {
            parentSection = enableFeaturesSection,
            prefix = "FPS_",
            key = "fps_text_content",
            name = "Content",
            default = FpsLatencyMeterBaseConfig.contentFPS,
            get = function()
                return FpsLatencyMeterConfig.contentFPS
            end,
            set = function(value)
                FpsLatencyMeterConfig.contentFPS = value
                TT:UpdateFrames()
            end,
            desc = "Set the content of the displayed text",
            readonly = false,
            selectAllOnFocus = false,
            multiline = false,
        })
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

    do
        local initializer, setting = CreateParentedScrollDown(FpsLatencyMeterConfig, "frameLatencyHomeAlign",
            alignmentsMap, enableFeaturesSection, "MS_", "ms_home_text_align", "Alignment",
            FpsLatencyMeterBaseConfig.frameLatencyHomeAlign, 220, TT:UpdateFrames(), "Select the alignment of the text")
        initializer:AddShownPredicate(function() return latencySetting:GetValue() and latencyHomeSetting:GetValue() end)

        local function IsSectionEnabled()
            return FpsLatencyMeterBaseConfig.latency and FpsLatencyMeterBaseConfig.latencyHome
        end

        initializer:SetParentInitializer(latencyHomeInitializer,
            latencyHomeInitializer.IsSectionEnabled or IsSectionEnabled)
    end

    do
        local initializer, setting = SettingsLib:CreateInput(category, {
            parentSection = enableFeaturesSection,
            prefix = "MS_",
            key = "ms_home_text_content",
            name = "Content",
            default = FpsLatencyMeterBaseConfig.contentHomeMS,
            get = function()
                return FpsLatencyMeterConfig.contentHomeMS
            end,
            set = function(value)
                FpsLatencyMeterConfig.contentHomeMS = value
                TT:UpdateFrames()
            end,
            desc = "Set the content of the displayed text",
            readonly = false,
            selectAllOnFocus = false,
            multiline = false,
        })
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

    do
        local initializer, setting = CreateParentedScrollDown(FpsLatencyMeterConfig, "frameLatencyWorldAlign",
            alignmentsMap, enableFeaturesSection, "MS_", "ms_world_text_align", "Alignment",
            FpsLatencyMeterBaseConfig.frameLatencyWorldAlign, 220, TT:UpdateFrames(), "Select the alignment of the text")
        initializer:AddShownPredicate(function() return latencySetting:GetValue() and latencyWorldSetting:GetValue() end)

        local function IsSectionEnabled()
            return FpsLatencyMeterBaseConfig.latency and FpsLatencyMeterBaseConfig.latencyWorld
        end

        initializer:SetParentInitializer(latencyWorldInitializer,
            latencyWorldInitializer.IsSectionEnabled or IsSectionEnabled)
    end

    do
        local initializer, setting = SettingsLib:CreateInput(category, {
            parentSection = enableFeaturesSection,
            prefix = "MS_",
            key = "ms_world_text_content",
            name = "Content",
            default = FpsLatencyMeterBaseConfig.contentWorldMS,
            get = function()
                return FpsLatencyMeterConfig.contentWorldMS
            end,
            set = function(value)
                FpsLatencyMeterConfig.contentWorldMS = value
                TT:UpdateFrames()
            end,
            desc = "Set the content of the displayed text",
            readonly = false,
            selectAllOnFocus = false,
            multiline = false,
        })
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
    if not TT:IsRetail() then
        colorDescription =
            "Changes the color of the text, depending on the FPS and MS.\n\n"
            .. TT:ToWoWColorCode(FpsLatencyMeterConfig.highColor[1], FpsLatencyMeterConfig.highColor[2],
                FpsLatencyMeterConfig.highColor[3]) .. "Red for < 15 fps or > 200 ms|r\n\n"
            .. TT:ToWoWColorCode(FpsLatencyMeterConfig.mediumColor[1], FpsLatencyMeterConfig.mediumColor[2],
                FpsLatencyMeterConfig.mediumColor[3]) .. "Yellow for < 30 fps or > 100 ms|r\n\n"
            .. TT:ToWoWColorCode(FpsLatencyMeterConfig.lowColor[1], FpsLatencyMeterConfig.lowColor[2],
                FpsLatencyMeterConfig.lowColor[3]) .. "Green for > 30 fps or < 100 ms|r"
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

local function ActionResetPositions()
    ResetPositions()
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
        ActionResetSettings(true)
    else
        OpenFpsLatencySettings()
    end
end
