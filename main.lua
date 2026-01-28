local addOnName = ...

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local fonts = LSM:HashTable(LSM.MediaType.FONT)

local TT = _G[addOnName]

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(GetScreenWidth(), GetScreenHeight())
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local textFPS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
textFPS:SetPoint(
    FpsLatencyMeterConfig.frameFpsAlign,
    frame,
    "CENTER",
    FpsLatencyMeterConfig.frameFpsX,
    FpsLatencyMeterConfig.frameFpsY
)
textFPS:SetTextColor(1, 1, 1)
textFPS:SetFont(fonts[FpsLatencyMeterConfig.fontName], FpsLatencyMeterConfig.fontSize, "OUTLINE")

local textHomeMS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
textHomeMS:SetPoint(
    FpsLatencyMeterConfig.frameLatencyHomeAlign,
    frame,
    "CENTER",
    FpsLatencyMeterConfig
    .frameLatencyHomeX,
    FpsLatencyMeterConfig.frameLatencyHomeY
)
textHomeMS:SetTextColor(1, 1, 1)
textHomeMS:SetFont(fonts[FpsLatencyMeterConfig.fontName], FpsLatencyMeterConfig.fontSize, "OUTLINE")

local textWorldMS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
textWorldMS:SetPoint(
    FpsLatencyMeterConfig.frameLatencyWorldAlign,
    frame,
    "CENTER",
    FpsLatencyMeterConfig.frameLatencyWorldX,
    FpsLatencyMeterConfig.frameLatencyWorldY
)
textWorldMS:SetTextColor(1, 1, 1)
textWorldMS:SetFont(fonts[FpsLatencyMeterConfig.fontName], FpsLatencyMeterConfig.fontSize, "OUTLINE")

function TT:ToWoWColorCode(r, g, b, a)
    return string.format("|cFF%02X%02X%02X", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

local function GetColorCodeFps(fps)
    local colorValue
    if fps <= 15 then
        colorValue = FpsLatencyMeterConfig.highColor
    elseif fps <= 30 then
        colorValue = FpsLatencyMeterConfig.mediumColor
    else
        colorValue = FpsLatencyMeterConfig.lowColor
    end
    return TT:ToWoWColorCode(colorValue[1], colorValue[2], colorValue[3], colorValue[4] or 1)
end

local function GetColorCodeMs(ms)
    local colorValue
    if ms >= 200 then
        colorValue = FpsLatencyMeterConfig.highColor
    elseif ms >= 100 then
        colorValue = FpsLatencyMeterConfig.mediumColor
    else
        colorValue = FpsLatencyMeterConfig.lowColor
    end
    return TT:ToWoWColorCode(colorValue[1], colorValue[2], colorValue[3], colorValue[4] or 1), colorValue[4] or 1
end

frame:SetScript("OnUpdate", function(self, elapsed)
    TT:UpdateFrames()

    -- Update every second
    self.timer = (self.timer or 0) + elapsed
    if self.timer >= FpsLatencyMeterConfig.refreshInterval then
        local fps = floor(GetFramerate())
        local bandWidthIn, bandWidthOut, homeMS, worldMS = GetNetStats()
        if FpsLatencyMeterConfig.fps then
            if FpsLatencyMeterConfig.changeColor then
                local colorCode = GetColorCodeFps(fps)
                textFPS:SetText(string.format(string.gsub(FpsLatencyMeterConfig.contentFPS, "#", "%%s%%d|r"), colorCode,
                    fps))
            else
                textFPS:SetText(string.format(string.gsub(FpsLatencyMeterConfig.contentFPS, "#", "%%d"), fps))
            end
        end
        if FpsLatencyMeterConfig.latency then
            if FpsLatencyMeterConfig.latencyHome then
                if FpsLatencyMeterConfig.changeColor then
                    local colorCode = GetColorCodeMs(homeMS)
                    textHomeMS:SetText(string.format(string.gsub(FpsLatencyMeterConfig.contentHomeMS, "#", "%%s%%d|r"),
                        colorCode, homeMS))
                else
                    textHomeMS:SetText(string.format(string.gsub(FpsLatencyMeterConfig.contentHomeMS, "#", "%%d"), homeMS))
                end
            end
            if FpsLatencyMeterConfig.latencyWorld then
                if FpsLatencyMeterConfig.changeColor then
                    local colorCode = GetColorCodeMs(worldMS)
                    textWorldMS:SetText(string.format(string.gsub(FpsLatencyMeterConfig.contentWorldMS, "#", "%%s%%d|r"),
                    colorCode, worldMS))
                else
                    textWorldMS:SetText(string.format(string.gsub(FpsLatencyMeterConfig.contentWorldMS, "#", "%%d"),
                        worldMS))
                end
            end
        end
        self.timer = 0
    end
end)

function TT:UpdateFrames()
    if type(FpsLatencyMeterConfig.frameFpsX) == "number" and type(FpsLatencyMeterConfig.frameFpsY) == "number" then
        textFPS:ClearAllPoints()
        textFPS:SetPoint(
            FpsLatencyMeterConfig.frameFpsAlign,
            frame,
            "CENTER",
            FpsLatencyMeterConfig.frameFpsX,
            FpsLatencyMeterConfig.frameFpsY
        )
    end
    if type(FpsLatencyMeterConfig.frameLatencyHomeX) == "number" and type(FpsLatencyMeterConfig.frameLatencyHomeY) == "number" then
        textHomeMS:ClearAllPoints()
        textHomeMS:SetPoint(
            FpsLatencyMeterConfig.frameLatencyHomeAlign,
            frame,
            "CENTER",
            FpsLatencyMeterConfig.frameLatencyHomeX,
            FpsLatencyMeterConfig.frameLatencyHomeY
        )
    end
    if type(FpsLatencyMeterConfig.frameLatencyWorldX) == "number" and type(FpsLatencyMeterConfig.frameLatencyWorldY) == "number" then
        textWorldMS:ClearAllPoints()
        textWorldMS:SetPoint(
            FpsLatencyMeterConfig.frameLatencyWorldAlign,
            frame,
            "CENTER",
            FpsLatencyMeterConfig.frameLatencyWorldX,
            FpsLatencyMeterConfig.frameLatencyWorldY
        )
    end

    if type(FpsLatencyMeterConfig.fontSize) == "number" and FpsLatencyMeterConfig.fontName then
        textFPS:SetFont(fonts[FpsLatencyMeterConfig.fontName], FpsLatencyMeterConfig.fontSize, "OUTLINE")
        textHomeMS:SetFont(fonts[FpsLatencyMeterConfig.fontName], FpsLatencyMeterConfig.fontSize, "OUTLINE")
        textWorldMS:SetFont(fonts[FpsLatencyMeterConfig.fontName], FpsLatencyMeterConfig.fontSize, "OUTLINE")
    end

    if FpsLatencyMeterConfig.fps then
        textFPS:Show()
    else
        textFPS:Hide()
    end

    if FpsLatencyMeterConfig.latency then
        if FpsLatencyMeterConfig.latencyHome then
            textHomeMS:Show()
        else
            textHomeMS:Hide()
        end

        if FpsLatencyMeterConfig.latencyWorld then
            textWorldMS:Show()
        else
            textWorldMS:Hide()
        end
    else
        textHomeMS:Hide()
        textWorldMS:Hide()
    end
end
