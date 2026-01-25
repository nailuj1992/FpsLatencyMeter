local addOnName = ...
local TT = _G[addOnName]

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(200, 100)
frame:SetPoint(FpsLatencyMeterConfig.framePoint,
    UIParent,
    FpsLatencyMeterConfig.framePoint,
    FpsLatencyMeterConfig.frameX,
    FpsLatencyMeterConfig.frameY
)

local textFPS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
textFPS:SetPoint("CENTER", frame, "CENTER", 0, 0)
textFPS:SetTextColor(1, 1, 1)

local textHomeMS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
textHomeMS:SetPoint("CENTER", frame, "CENTER", 0, -20)
textHomeMS:SetTextColor(1, 1, 1)

local textWorldMS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
textWorldMS:SetPoint("CENTER", frame, "CENTER", 0, -35)
textWorldMS:SetTextColor(1, 1, 1)

local function ToWoWColorCode(r, g, b, a)
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
    return ToWoWColorCode(colorValue[1], colorValue[2], colorValue[3], colorValue[4] or 1)
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
    return ToWoWColorCode(colorValue[1], colorValue[2], colorValue[3], colorValue[4] or 1), colorValue[4] or 1
end

frame:SetScript("OnUpdate", function(self, elapsed)
    TT:UpdateFrames()

    -- Update every second
    self.timer = (self.timer or 0) + elapsed
    if self.timer >= FpsLatencyMeterConfig.refreshInterval then
        local fps = floor(GetFramerate())
        local _, _, homeMS, worldMS = GetNetStats()
        if FpsLatencyMeterConfig.fps then
            if FpsLatencyMeterConfig.changeColor then
                local colorCode = GetColorCodeFps(fps)
                textFPS:SetText(string.format("%s%d|r FPS", colorCode, fps))
            else
                textFPS:SetText(string.format("%d FPS", fps))
            end
        end
        if FpsLatencyMeterConfig.latency then
            if FpsLatencyMeterConfig.latencyHome then
                if FpsLatencyMeterConfig.changeColor then
                    local colorCode = GetColorCodeMs(homeMS)
                    textHomeMS:SetText(string.format("%s%d|r ms (Home)", colorCode, homeMS))
                else
                    textHomeMS:SetText(string.format("%d ms (Home)", homeMS))
                end
            end
            if FpsLatencyMeterConfig.latencyWorld then
                if FpsLatencyMeterConfig.changeColor then
                    local colorCode = GetColorCodeMs(worldMS)
                    textWorldMS:SetText(string.format("%s%d|r ms (World)", colorCode, worldMS))
                else
                    textWorldMS:SetText(string.format("%d ms (World)", worldMS))
                end
            end
        end
        self.timer = 0
    end
end)

function TT:UpdateFrames()
    if FpsLatencyMeterConfig.framePoint and type(FpsLatencyMeterConfig.frameX) == "number" and type(FpsLatencyMeterConfig.frameY) == "number" then
        frame:ClearAllPoints()
        frame:SetPoint(
            FpsLatencyMeterConfig.framePoint,
            UIParent,
            FpsLatencyMeterConfig.framePoint,
            FpsLatencyMeterConfig.frameX,
            FpsLatencyMeterConfig.frameY
        )
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
