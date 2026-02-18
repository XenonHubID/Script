--[[
    ╔══════════════════════════════════════════╗
    ║           X E N O N  H U B              ║
    ║        Fish It — Ultimate Script         ║
    ║    Developer  : Hann 25                  ║
    ║    Discord    : discord.gg/MtzH9fttbs    ║
    ║    Asset      : rbxassetid://116456203641109 ║
    ╚══════════════════════════════════════════╝
    All features from STREE HUB (Prem.lua) and
    Xenon Hub (fishit.lua) merged & rebranded.
    Instant Fishing logic preserved 100%.
    No sliders re-introduced. Numeric inputs kept.
]]

-- ─────────────────────────────────────────────
-- ENVIRONMENT COMPAT
-- ─────────────────────────────────────────────
getgenv().LPH_NO_VIRTUALIZE = function(f) return f end
local request = (syn and syn.request) or (http and http.request) or http_request
    or (fluxus and fluxus.request) or (typeof(request) == "function" and request) or nil
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or nil

-- ─────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Stats             = game:GetService("Stats")
local LocalPlayer       = Players.LocalPlayer

-- ─────────────────────────────────────────────
-- GLOBAL STATE
-- ─────────────────────────────────────────────
_G.AutoFish         = false
_G.DelaySpeed       = 0.5
_G.AutoSell         = false
_G.SellDelay        = 30
_G.AutoEnchant      = false
_G.TargetEnchant    = "Big Hunter 1"
_G.WebhookURL       = ""
_G.WebhookRarities  = {}
_G.CustomSpeed      = 16
_G.CustomJump       = 50
_G.CustomJumpPower  = 50
_G.InfJump          = false
_G.InfiniteJump     = false
_G.Noclip           = false
_G.AntiAFK          = false
_G.AutoReconnect    = false
_G.FreezeCharacter  = false
_G.HideID           = false
_G.FakeName         = "XenonHUB"
_G.FPSBoost         = false
_G._FPSObjects      = {}
_G.InstantDelay     = 0.35
_G.CallMinDelay     = 0.18
_G.CallBackoff      = 1.5
_G.DetectNewFishActive = false
_G.AutoClaimChest   = false
_G.AutoFishing      = false  -- STREE mode
_G.Instant          = false  -- STREE mode

-- ─────────────────────────────────────────────
-- GLOBAL DATA (REMOTE CACHE)
-- ─────────────────────────────────────────────
local GlobalData = {
    Loaded       = false,
    Remotes      = {},
    Dependencies = {},
    Net          = nil,
}

-- ─────────────────────────────────────────────
-- UI HELPER
-- ─────────────────────────────────────────────
local function getUI()
    return (getgenv().gethui and getgenv().gethui())
        or CoreGui:FindFirstChild("RobloxGui")
        or CoreGui
end

-- ─────────────────────────────────────────────
-- LOAD WIND UI LIBRARY
-- ─────────────────────────────────────────────
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
    ))()
end)

if not success or not WindUI then
    game.StarterGui:SetCore("SendNotification", {
        Title    = "XENON ERROR";
        Text     = "Gagal download UI Library. Cek koneksi!";
        Duration = 10;
    })
    return
end

-- ─────────────────────────────────────────────
-- NOTIFICATION SYSTEM (Custom Toast)
-- ─────────────────────────────────────────────
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name          = "XenonNotifs"
NotifGui.Parent        = getUI()
NotifGui.ResetOnSpawn  = false

local NotifContainer = Instance.new("Frame", NotifGui)
NotifContainer.Name                 = "Container"
NotifContainer.Position             = UDim2.new(0.02, 0, 0.3, 0)
NotifContainer.Size                 = UDim2.new(0, 300, 0.6, 0)
NotifContainer.BackgroundTransparency = 1

local UIList = Instance.new("UIListLayout", NotifContainer)
UIList.SortOrder         = Enum.SortOrder.LayoutOrder
UIList.Padding           = UDim.new(0, 6)
UIList.VerticalAlignment = Enum.VerticalAlignment.Bottom

local function Notify(Title, Text, Duration)
    task.spawn(function()
        local Frame = Instance.new("Frame", NotifContainer)
        Frame.Name             = "Notif"
        Frame.Size             = UDim2.new(0, 0, 0, 38)
        Frame.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
        Frame.BorderSizePixel  = 0
        Frame.ClipsDescendants = true

        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

        local Stroke = Instance.new("UIStroke", Frame)
        Stroke.Thickness       = 1.4
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local Gradient = Instance.new("UIGradient", Stroke)
        Gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0,  240, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0,  120, 255)),
        }

        local Label = Instance.new("TextLabel", Frame)
        Label.Size             = UDim2.new(1, -12, 1, 0)
        Label.Position         = UDim2.new(0, 12, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text             = string.format(
            "<b><font color='rgb(0,240,255)'>%s</font></b>  %s", Title, Text)
        Label.RichText         = true
        Label.TextColor3       = Color3.new(1, 1, 1)
        Label.TextSize         = 13
        Label.Font             = Enum.Font.GothamMedium
        Label.TextXAlignment   = Enum.TextXAlignment.Left
        Label.TextTransparency = 1

        Frame:TweenSize(UDim2.new(0, 270, 0, 38), "Out", "Back", 0.4, true)
        TweenService:Create(Label, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

        task.wait(Duration or 3)

        if Frame and Frame.Parent then
            Frame:TweenSize(UDim2.new(0, 0, 0, 38), "In", "Quad", 0.3, true)
            task.wait(0.3)
            pcall(Frame.Destroy, Frame)
        end
    end)
end

-- ─────────────────────────────────────────────
-- WIND UI WINDOW
-- ─────────────────────────────────────────────
local Window = WindUI:CreateWindow({
    Title        = "XENON HUB",
    Icon         = "rbxassetid://116456203641109",
    Author       = "Hann 25 | Fish It",
    Folder       = "XENON_FISHIT",
    Size         = UDim2.fromOffset(290, 370),
    Transparent  = true,
    Theme        = "Dark",
    SideBarWidth = 175,
    HasOutline   = true,
    User         = { Enabled = true, Anonymous = true },
})

Window:EditOpenButton({ Enabled = false })

Window:Tag({
    Title  = "v2.0.0",
    Color  = Color3.fromRGB(0, 200, 255),
    Radius = 17,
})

Window:Tag({
    Title  = "XenonHUB",
    Color  = Color3.fromRGB(0, 80, 200),
    Radius = 17,
})

-- ─────────────────────────────────────────────
-- FLOATING TOGGLE BUTTON  (fixed: hides on close)
-- ─────────────────────────────────────────────
local FloatGui = Instance.new("ScreenGui")
FloatGui.Name         = "XenonFloat"
FloatGui.Parent       = getUI()
FloatGui.ResetOnSpawn = false

local FloatBtn = Instance.new("ImageButton", FloatGui)
FloatBtn.Size             = UDim2.new(0, 48, 0, 48)
FloatBtn.Position         = UDim2.new(0.05, 0, 0.08, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(8, 12, 22)
FloatBtn.Image            = "rbxassetid://116456203641109"
FloatBtn.Draggable        = false  -- manual drag below (no glitch)
FloatBtn.BorderSizePixel  = 0

Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 12)

local btnStroke = Instance.new("UIStroke", FloatBtn)
btnStroke.Thickness = 1.8
btnStroke.Color     = Color3.fromRGB(0, 200, 255)
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Neon glow gradient on stroke
local btnGrad = Instance.new("UIGradient", btnStroke)
btnGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 240, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,  80, 255)),
}

-- Hover glow effect
FloatBtn.MouseEnter:Connect(function()
    TweenService:Create(btnStroke, TweenInfo.new(0.2), {
        Color     = Color3.fromRGB(0, 255, 255),
        Thickness = 2.5,
    }):Play()
end)
FloatBtn.MouseLeave:Connect(function()
    TweenService:Create(btnStroke, TweenInfo.new(0.2), {
        Color     = Color3.fromRGB(0, 200, 255),
        Thickness = 1.8,
    }):Play()
end)

-- Smooth drag
local dragging, dragInput, dragStart, startPos
FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = FloatBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
FloatBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        FloatBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local windowVisible = true
FloatBtn.MouseButton1Click:Connect(function()
    if dragging then return end
    if windowVisible then
        Window:Close()
    else
        Window:Open()
    end
    windowVisible = not windowVisible
end)

-- ─────────────────────────────────────────────
-- SAFE CLOSE: destroy float icon + all GUIs
-- ─────────────────────────────────────────────
local function FullClose()
    Window:Close()
    FloatGui:Destroy()
    NotifGui:Destroy()
    local stats = getUI():FindFirstChild("XenonStats")
    if stats then stats:Destroy() end
    local miniPanel = getUI():FindFirstChild("XenonMiniPanel")
    if miniPanel then miniPanel:Destroy() end
    local blackScreen = CoreGui:FindFirstChild("Xenon_BlackScreen")
    if blackScreen then blackScreen:Destroy() end
end

-- ─────────────────────────────────────────────
-- DEPENDENCY LOADER + REMOTE BINDER
-- ─────────────────────────────────────────────
task.spawn(function()
    Notify("Loader", "Injecting dependencies...", 2)

    -- Dependencies
    pcall(function()
        GlobalData.Dependencies.ItemUtility  = require(RS.Shared.ItemUtility)
        GlobalData.Dependencies.Replion      = require(RS.Packages.Replion)
        GlobalData.Dependencies.DataService  = GlobalData.Dependencies.Replion.Client:WaitReplion("Data")
    end)

    -- Find net package (supports any version suffix)
    local net = nil
    if RS.Packages:FindFirstChild("_Index") then
        for _, child in ipairs(RS.Packages._Index:GetChildren()) do
            if string.find(child.Name, "sleitnick_net") then
                net = child:FindFirstChild("net")
                if net then break end
            end
        end
    end
    GlobalData.Net = net

    if net then
        GlobalData.Remotes = {
            -- Fishing
            Charge          = net:FindFirstChild("RF/ChargeFishingRod"),
            Start           = net:FindFirstChild("RF/RequestFishingMinigameStarted"),
            FinishFunction  = net:FindFirstChild("RF/CatchFishCompleted"),
            FinishEvent     = net:FindFirstChild("RE/FishingCompleted"),
            CancelInputs    = net:FindFirstChild("RF/CancelFishingInputs"),
            UpdateAutoFish  = net:FindFirstChild("RF/UpdateAutoFishingState"),
            -- Inventory
            EquipRod        = net:FindFirstChild("RE/EquipToolFromHotbar"),
            EquipItem       = net:FindFirstChild("RE/EquipItem"),
            SellAll         = net:FindFirstChild("RF/SellAllItems"),
            FavoriteItem    = net:FindFirstChild("RE/FavoriteItem"),
            FavStateChanged = net:FindFirstChild("RE/FavoriteStateChanged"),
            -- Shop
            PurchaseRod     = net:FindFirstChild("RF/PurchaseFishingRod"),
            PurchaseBait    = net:FindFirstChild("RF/PurchaseBait"),
            PurchaseWeather = net:FindFirstChild("RF/PurchaseWeatherEvent"),
            -- Enchant
            ActivateAltar   = net:FindFirstChild("RE/ActivateEnchantingAltar"),
            -- Events
            ClaimChest      = net:FindFirstChild("RE/ClaimPirateChest"),
            SearchItem      = net:FindFirstChild("RE/SearchItemPickedUp"),
            Dialogue        = net:FindFirstChild("RE/DialogueEnded"),
            Maze            = net:FindFirstChild("RE/GainAccessToMaze"),
            -- Visual
            ReplicateText   = net:FindFirstChild("RE/ReplicateTextEffect"),
            BaitSpawned     = net:FindFirstChild("RE/BaitSpawned"),
            BaitDestroyed   = net:FindFirstChild("RE/BaitDestroyed"),
            -- Oxygen
            EquipOxygen     = net:FindFirstChild("RF/EquipOxygenTank"),
            UnequipOxygen   = net:FindFirstChild("RF/UnequipOxygenTank"),
        }
        GlobalData.Loaded = true
        Notify("System", "Remote Cache Ready!", 3)
    else
        Notify("Error", "Failed to find Game Net!", 10)
    end
end)

-- ─────────────────────────────────────────────
-- SAFE FIRE / INVOKE HELPERS
-- ─────────────────────────────────────────────
local lastCall = {}
local function safeFire(name, ...)
    if not (GlobalData.Loaded and GlobalData.Remotes[name]) then return end
    pcall(GlobalData.Remotes[name].FireServer, GlobalData.Remotes[name], ...)
end

local function safeInvoke(name, ...)
    if not (GlobalData.Loaded and GlobalData.Remotes[name]) then return nil end
    local ok, res = pcall(GlobalData.Remotes[name].InvokeServer, GlobalData.Remotes[name], ...)
    return ok and res or nil
end

-- Rate-limited safe call (from STREE)
local function safeCall(k, f)
    local n = os.clock()
    if lastCall[k] and n - lastCall[k] < _G.CallMinDelay then
        task.wait(_G.CallMinDelay - (n - lastCall[k]))
    end
    local ok, result = pcall(f)
    lastCall[k] = os.clock()
    if not ok then
        local msg = tostring(result):lower()
        task.wait((msg:find("429") or msg:find("too many requests")) and _G.CallBackoff or 0.2)
    end
    return ok, result
end

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 1 — INFO
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabInfo = Window:Tab({ Title = "Info", Icon = "info" })

TabInfo:Section({ Title = "XenonHUB — Fish It", Icon = "activity" })

TabInfo:Paragraph({
    Title = "Version",
    Desc  = "XenonHUB v2.0.0 | Developer: Hann 25",
    RichText = true,
})

TabInfo:Paragraph({
    Title = "Features",
    Desc  = "Instant Fishing • Blantant Mode • Legit Mode • Radar • Auto Enchant • Double Enchant • Auto Favorite • Webhook • FPS Boost • Event TP • Shop • Teleport & More!",
})

TabInfo:Divider()

TabInfo:Button({
    Title = "Copy Discord",
    Desc  = "discord.gg/MtzH9fttbs",
    Callback = function()
        if setclipboard then setclipboard("https://discord.gg/MtzH9fttbs") end
        Notify("Discord", "Copied to clipboard!", 2)
    end,
})

TabInfo:Keybind({
    Title    = "Toggle UI",
    Desc     = "Hotkey to show/hide the hub",
    Value    = "G",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end,
})

TabInfo:Button({
    Title = "Full Close (Remove All)",
    Desc  = "Destroys UI, float icon, and all GUIs",
    Callback = FullClose,
})

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 2 — FISHING
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabFish = Window:Tab({ Title = "Fishing", Icon = "anchor" })

-- ── SECTION: Instant Fishing (Xenon Logic — DO NOT ALTER) ──
TabFish:Section({ Title = "Instant Fishing", Icon = "zap" })

-- ❗ INSTANT FISHING LOGIC — PRESERVED 100% FROM XENON HUB ❗
-- ❗ DO NOT REFORMAT, SIMPLIFY, OR CHANGE THE METHOD       ❗
local function RunInstantFishing()
    task.spawn(function()
        while _G.AutoFish do
            if not GlobalData.Loaded then task.wait(1) continue end
            task.wait(0.1)

            local currentTime = tick()

            pcall(function()
                if GlobalData.Remotes.Charge then
                    GlobalData.Remotes.Charge:InvokeServer(nil, nil, currentTime)
                end
            end)

            task.wait(0.1)

            local constantVal = -1.233184814453125
            local randomPower = math.random(80, 95) / 100

            local successStart, _ = pcall(function()
                if GlobalData.Remotes.Start then
                    GlobalData.Remotes.Start:InvokeServer(constantVal, randomPower, tick())
                end
            end)

            if successStart then
                task.wait(_G.DelaySpeed)

                pcall(function()
                    if GlobalData.Remotes.FinishFunction then
                        GlobalData.Remotes.FinishFunction:InvokeServer()
                    elseif GlobalData.Remotes.FinishEvent then
                        GlobalData.Remotes.FinishEvent:FireServer()
                    end
                end)
            else
                task.wait(0.2)
            end
        end
    end)
end
-- ❗ END OF PROTECTED INSTANT FISHING LOGIC ❗

TabFish:Toggle({
    Title    = "Auto Equip Rod",
    Callback = function(v)
        if v then safeFire("EquipRod", 1) end
    end,
})

TabFish:Toggle({
    Title    = "Auto Fish — Instant Mode",
    Callback = function(v)
        _G.AutoFish = v
        if v then
            if not GlobalData.Loaded then Notify("Wait", "Game still loading...", 2) end
            RunInstantFishing()
        end
    end,
})

TabFish:Input({
    Title       = "Delay Speed (seconds)",
    Placeholder = "Min: 0.1 (Risky)  |  Safe: 0.5",
    Default     = "0.5",
    Callback    = function(text)
        local num = tonumber(text)
        if num then
            _G.DelaySpeed = math.clamp(num, 0.05, 60)
            Notify("Config", "Delay set: " .. _G.DelaySpeed .. "s", 2)
        else
            Notify("Error", "Enter a valid number!", 2)
        end
    end,
})

-- ── SECTION: STREE Blantant Fishing ──
TabFish:Section({ Title = "Blantant Fishing", Icon = "fish" })

local BlantantConfig = {
    blantant = false,
    cancel   = 100,
    complete = 100,
}

local baitActive         = 0
local exclaimDetected    = false
local blantantMain       = nil
local blantantEquip      = nil

-- Connect bait + exclaim events after remotes load
task.spawn(function()
    repeat task.wait(0.5) until GlobalData.Loaded

    if GlobalData.Remotes.ReplicateText then
        GlobalData.Remotes.ReplicateText.OnClientEvent:Connect(function(data)
            local char = LocalPlayer.Character
            if not char or not data or not data.TextData then return end
            if data.TextData.AttachTo and data.TextData.AttachTo:IsDescendantOf(char)
            and data.TextData.Text == "!" then
                exclaimDetected = true
            end
        end)
    end

    if GlobalData.Remotes.BaitSpawned then
        GlobalData.Remotes.BaitSpawned.OnClientEvent:Connect(function(_, _, owner)
            if owner and owner == LocalPlayer then baitActive = 1 end
        end)
    end

    if GlobalData.Remotes.BaitDestroyed then
        GlobalData.Remotes.BaitDestroyed.OnClientEvent:Connect(function()
            baitActive = 0
        end)
    end
end)

local function BlantantCast()
    task.spawn(function()
        pcall(function()
            local rem = GlobalData.Remotes
            if rem.CancelInputs then
                local ok = rem.CancelInputs:InvokeServer()
                if not ok then repeat ok = rem.CancelInputs:InvokeServer() until ok end
            end
            if rem.Charge then
                local ch = rem.Charge:InvokeServer(math.huge)
                if not ch then repeat ch = rem.Charge:InvokeServer(math.huge) until ch end
            end
            if rem.Start then
                rem.Start:InvokeServer(1, 0.05, 1731873.1873)
            end
        end)
    end)

    task.spawn(function()
        exclaimDetected = false
        local timeout, timer = 20, 0
        while BlantantConfig.blantant and timer < timeout do
            if exclaimDetected and baitActive == 0 then break end
            task.wait(0.01)
            timer += 0.1
        end
        if not BlantantConfig.blantant then return end
        if not (exclaimDetected and baitActive == 0) then return end
        task.wait(BlantantConfig.complete)
        if BlantantConfig.blantant and GlobalData.Remotes.FinishEvent then
            pcall(GlobalData.Remotes.FinishEvent.FireServer, GlobalData.Remotes.FinishEvent)
        end
    end)
end

local function BlantantMainLoop()
    blantantEquip = task.spawn(function()
        while BlantantConfig.blantant do
            pcall(function() GlobalData.Remotes.EquipRod:FireServer(1) end)
            task.wait(1.5)
        end
    end)
    while BlantantConfig.blantant do
        BlantantCast()
        task.wait(BlantantConfig.cancel)
        if not BlantantConfig.blantant then break end
        task.wait(0.1)
    end
end

local function ToggleBlantant(state)
    BlantantConfig.blantant = state
    if state then
        if blantantMain  then task.cancel(blantantMain)  end
        if blantantEquip then task.cancel(blantantEquip) end
        blantantMain = task.spawn(BlantantMainLoop)
    else
        if blantantMain  then task.cancel(blantantMain)  blantantMain  = nil end
        if blantantEquip then task.cancel(blantantEquip) blantantEquip = nil end
        baitActive = 0
        if GlobalData.Remotes.CancelInputs then
            pcall(GlobalData.Remotes.CancelInputs.InvokeServer, GlobalData.Remotes.CancelInputs)
        end
    end
end

TabFish:Toggle({
    Title    = "Blantant (Smart Cast)",
    Callback = ToggleBlantant,
})

TabFish:Input({
    Title       = "Delay Bait (s)",
    Default     = tostring(BlantantConfig.cancel),
    Placeholder = "seconds to wait before re-cast",
    Callback    = function(v)
        local n = tonumber(v)
        if n and n > 0 then BlantantConfig.cancel = n end
    end,
})

TabFish:Input({
    Title       = "Delay Reel (s)",
    Default     = tostring(BlantantConfig.complete),
    Placeholder = "seconds after ! before reel",
    Callback    = function(v)
        local n = tonumber(v)
        if n and n > 0 then BlantantConfig.complete = n end
    end,
})

-- ── SECTION: Legit Auto Fishing (STREE) ──
TabFish:Section({ Title = "Legit Mode", Icon = "waves" })

-- STREE Legit helpers (rate-limited, uses UpdateAutoFishingState)
local legitThread = nil

local function StreeCharge()
    safeCall("charge", function()
        GlobalData.Remotes.Charge:InvokeServer()
    end)
end
local function StreeThrow()
    safeCall("lempar", function()
        GlobalData.Remotes.Start:InvokeServer(-139.63, 0.996, -1761532005.497)
    end)
    safeCall("charge2", function()
        GlobalData.Remotes.Charge:InvokeServer()
    end)
end
local function StreeCatch()
    safeCall("catch", function()
        GlobalData.Remotes.FinishEvent:FireServer()
    end)
end

TabFish:Input({
    Title       = "Legit Cycle Delay (s)",
    Placeholder = "0.35 default",
    Default     = "0.35",
    Callback    = function(v)
        local n = tonumber(v)
        if n then _G.InstantDelay = math.clamp(n, 0.05, 60) end
    end,
})

TabFish:Toggle({
    Title    = "Auto Fish — Legit Mode",
    Callback = function(v)
        _G.AutoFishing = v
        if v then
            if legitThread then task.cancel(legitThread) end
            legitThread = task.spawn(function()
                while _G.AutoFishing do
                    if GlobalData.Loaded then
                        StreeCharge()
                        StreeThrow()
                        task.wait(_G.InstantDelay)
                        StreeCatch()
                        task.wait(0.35)
                    else
                        task.wait(1)
                    end
                end
            end)
        else
            if GlobalData.Remotes.UpdateAutoFish then
                pcall(GlobalData.Remotes.UpdateAutoFish.InvokeServer,
                    GlobalData.Remotes.UpdateAutoFish, false)
            end
            if legitThread then task.cancel(legitThread) legitThread = nil end
        end
    end,
})

-- ── SECTION: Radar ──
TabFish:Section({ Title = "Radar", Icon = "radar" })

TabFish:Toggle({
    Title = "Fishing Radar",
    Callback = function(state)
        pcall(function()
            local NetPkg  = require(RS.Packages.Net)
            local Replion = require(RS.Packages.Replion)
            local rep     = Replion.Client:GetReplion("Data")
            local NetFn   = NetPkg:RemoteFunction("UpdateFishingRadar")
            if rep and NetFn then
                NetFn:InvokeServer(state)
                local snd = require(RS.Shared.Soundbook)
                if snd and snd.Sounds and snd.Sounds.RadarToggle then
                    local s = snd.Sounds.RadarToggle:Play()
                    if s then s.PlaybackSpeed = 1 + math.random() * 0.3 end
                end
                local c = Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect")
                if c then
                    local sprPkg = RS.Packages:FindFirstChild("spr")
                    if sprPkg then
                        local spr = require(sprPkg)
                        spr.stop(c)
                        if state then
                            c.TintColor = Color3.fromRGB(42, 226, 118)
                            c.Brightness = 0.4
                        else
                            c.TintColor = Color3.fromRGB(255, 0, 0)
                            c.Brightness = 0.2
                        end
                    end
                end
            end
        end)
    end,
})

-- ── SECTION: Diving Gear ──
TabFish:Section({ Title = "Diving Gear", Icon = "droplets" })

TabFish:Toggle({
    Title = "Diving Gear (Basic)",
    Desc  = "Oxygen Tank ID 105",
    Callback = function(state)
        if state then safeInvoke("EquipOxygen", 105)
        else safeInvoke("UnequipOxygen") end
    end,
})

TabFish:Toggle({
    Title = "Advanced Diving Gear",
    Desc  = "Oxygen Tank ID 575",
    Callback = function(state)
        if state then safeInvoke("EquipOxygen", 575)
        else safeInvoke("UnequipOxygen") end
    end,
})

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 3 — AUTO FARM
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabFarm = Window:Tab({ Title = "Auto Farm", Icon = "cpu" })

-- ── SECTION: Auto Sell ──
TabFarm:Section({ Title = "Selling", Icon = "coins" })

local sellThread = nil

TabFarm:Toggle({
    Title    = "Auto Sell All",
    Callback = function(v)
        _G.AutoSell = v
        if v then
            if sellThread then task.cancel(sellThread) end
            sellThread = task.spawn(function()
                while _G.AutoSell do
                    safeInvoke("SellAll")
                    local d = _G.SellDelay
                    local elapsed = 0
                    while elapsed < d and _G.AutoSell do
                        task.wait(0.25)
                        elapsed += 0.25
                    end
                end
            end)
        else
            if sellThread then task.cancel(sellThread) sellThread = nil end
        end
    end,
})

TabFarm:Input({
    Title       = "Sell Delay (s)",
    Default     = "30",
    Placeholder = "Seconds between sells",
    Callback    = function(v)
        local n = tonumber(v)
        if n and n > 0 then
            _G.SellDelay = n
            Notify("Sell", "Sell delay: " .. n .. "s", 2)
        end
    end,
})

-- ── SECTION: Auto Favorite ──
TabFarm:Section({ Title = "Auto Favorite", Icon = "star" })

local favRarities    = {}
local favNames       = {}
local autoFavEnabled = false
local favState       = {}

-- Hook FavoriteStateChanged after load
task.spawn(function()
    repeat task.wait(0.5) until GlobalData.Loaded
    if GlobalData.Remotes.FavStateChanged then
        GlobalData.Remotes.FavStateChanged.OnClientEvent:Connect(function(uuid, fav)
            if uuid then favState[uuid] = fav end
        end)
    end
    -- Also watch Data changes for reactive auto-fav
    if GlobalData.Dependencies.DataService then
        GlobalData.Dependencies.DataService:OnChange({"Inventory","Items"}, function()
            if not autoFavEnabled then return end
            pcall(function()
                local inv = GlobalData.Dependencies.DataService:GetExpect({"Inventory","Items"})
                if not inv then return end
                for _, item in ipairs(inv) do
                    if not (item.Favorited or favState[item.UUID]) then
                        local info = GlobalData.Dependencies.ItemUtility
                            .GetItemDataFromItemType("Items", item.Id)
                        if info and info.Data.Type == "Fish" then
                            local tierMap = {[1]="Uncommon",[2]="Common",[3]="Rare",
                                [4]="Epic",[5]="Legendary",[6]="Mythic",[7]="Secret"}
                            local rarity = tierMap[info.Data.Tier]
                            if table.find(favRarities, rarity) or table.find(favNames, info.Data.Name) then
                                safeFire("FavoriteItem", item.UUID, true)
                                favState[item.UUID] = true
                            end
                        end
                    end
                end
            end)
        end)
    end
end)

TabFarm:Dropdown({
    Title     = "Favorite by Rarity",
    Values    = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret"},
    Multi     = true,
    AllowNone = true,
    Callback  = function(opts) favRarities = opts or {} end,
})

TabFarm:Toggle({
    Title    = "Start Auto Favorite",
    Callback = function(v)
        autoFavEnabled = v
        if v and GlobalData.Dependencies.DataService then
            task.spawn(function()
                while autoFavEnabled do
                    pcall(function()
                        local inv = GlobalData.Dependencies.DataService
                            :GetExpect({"Inventory","Items"})
                        if not inv then return end
                        for _, item in ipairs(inv) do
                            if not (item.Favorited or favState[item.UUID]) then
                                local info = GlobalData.Dependencies.ItemUtility
                                    .GetItemDataFromItemType("Items", item.Id)
                                if info and info.Data.Type == "Fish" then
                                    local tierMap = {[1]="Uncommon",[2]="Common",[3]="Rare",
                                        [4]="Epic",[5]="Legendary",[6]="Mythic",[7]="Secret"}
                                    local rarity = tierMap[info.Data.Tier]
                                    if table.find(favRarities, rarity)
                                    or table.find(favNames, info.Data.Name) then
                                        safeFire("FavoriteItem", item.UUID, true)
                                        favState[item.UUID] = true
                                        task.wait(0.05)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(2)
                end
            end)
        end
    end,
})

TabFarm:Button({
    Title    = "Unfavorite All",
    Callback = function()
        if not GlobalData.Dependencies.DataService then return end
        local inv = GlobalData.Dependencies.DataService:GetExpect({"Inventory","Items"})
        if not inv then return end
        for _, item in ipairs(inv) do
            if item.Favorited or favState[item.UUID] then
                safeFire("FavoriteItem", item.UUID, false)
                favState[item.UUID] = false
                task.wait(0.05)
            end
        end
        Notify("Favorite", "All unfavorited!", 2)
    end,
})

-- ── SECTION: Enchanting ──
TabFarm:Section({ Title = "Enchanting", Icon = "flask-conical" })

local enchantNames = {
    "Big Hunter 1", "Cursed 1", "Empowered 1", "Glistening 1",
    "Gold Digger 1", "Leprechaun 1", "Leprechaun 2",
    "Mutation Hunter 1", "Mutation Hunter 2", "Prismatic 1",
    "Reeler 1", "Stargazer 1", "Stormhunter 1", "XPerienced 1",
}

local enchantIdMap = {
    ["Big Hunter 1"]     = 3,  ["Cursed 1"]         = 12,
    ["Empowered 1"]      = 9,  ["Glistening 1"]     = 1,
    ["Gold Digger 1"]    = 4,  ["Leprechaun 1"]     = 5,
    ["Leprechaun 2"]     = 6,  ["Mutation Hunter 1"]= 7,
    ["Mutation Hunter 2"]= 14, ["Prismatic 1"]      = 13,
    ["Reeler 1"]         = 2,  ["Stargazer 1"]      = 8,
    ["Stormhunter 1"]    = 11, ["XPerienced 1"]     = 10,
}

-- Live Enchant Status paragraph
local EnchantPara = TabFarm:Paragraph({
    Title    = "Enchant Status",
    Desc     = "Loading...",
    RichText = true,
})

local function getCurrentEnchantId()
    if not GlobalData.Dependencies.DataService then return nil end
    local equipped = GlobalData.Dependencies.DataService:Get("EquippedItems") or {}
    local rods     = GlobalData.Dependencies.DataService:GetExpect({"Inventory","Fishing Rods"}) or {}
    for _, uuid in pairs(equipped) do
        for _, rod in ipairs(rods) do
            if rod.UUID == uuid and rod.Metadata and rod.Metadata.EnchantId then
                return rod.Metadata.EnchantId
            end
        end
    end
    return nil
end

local function getEquippedRodName()
    if not GlobalData.Dependencies.DataService then return "None" end
    local equipped = GlobalData.Dependencies.DataService:Get("EquippedItems") or {}
    local rods     = GlobalData.Dependencies.DataService:GetExpect({"Inventory","Fishing Rods"}) or {}
    for _, uuid in pairs(equipped) do
        for _, rod in ipairs(rods) do
            if rod.UUID == uuid then
                local d = GlobalData.Dependencies.ItemUtility:GetItemData(rod.Id)
                if d and d.Data and d.Data.Name then return d.Data.Name end
                if rod.ItemName then return rod.ItemName end
            end
        end
    end
    return "None"
end

local function getStoneCount()
    if not GlobalData.Dependencies.DataService then return 0 end
    local inv   = GlobalData.Dependencies.DataService:GetExpect({"Inventory","Items"}) or {}
    local total = 0
    for _, item in ipairs(inv) do
        local d = GlobalData.Dependencies.ItemUtility.GetItemDataFromItemType("Items", item.Id)
        if d and d.Data and d.Data.Type == "Enchant Stones" then
            total += (item.Quantity or 1)
        end
    end
    return total
end

local function findEnchantStones()
    if not GlobalData.Dependencies.DataService then return {} end
    local inv    = GlobalData.Dependencies.DataService:GetExpect({"Inventory","Items"}) or {}
    local stones = {}
    for _, item in pairs(inv) do
        local d = GlobalData.Dependencies.ItemUtility:GetItemData(item.Id)
        if d and d.Data and d.Data.Type == "Enchant Stones" then
            table.insert(stones, {UUID = item.UUID, Quantity = item.Quantity or 1})
        end
    end
    return stones
end

-- Live update enchant status
task.spawn(LPH_NO_VIRTUALIZE(function()
    while task.wait(1) do
        pcall(function()
            if not GlobalData.Loaded then return end
            local rodName   = getEquippedRodName()
            local eid       = getCurrentEnchantId()
            local enchName  = "None"
            if eid then
                for n, id in pairs(enchantIdMap) do
                    if id == eid then enchName = n break end
                end
            end
            local stones = getStoneCount()
            EnchantPara:SetDesc(
                "Rod: <font color='rgb(0,200,255)'>" .. rodName .. "</font>\n"
                .. "Enchant: <font color='rgb(200,100,255)'>" .. enchName .. "</font>\n"
                .. "Stones: <font color='rgb(255,215,0)'>" .. stones .. "</font>"
            )
        end)
    end
end))

TabFarm:Dropdown({
    Title    = "Target Enchant",
    Values   = enchantNames,
    Value    = enchantNames[1],
    Callback = function(v) _G.TargetEnchant = v end,
})

TabFarm:Toggle({
    Title    = "Auto Enchant",
    Callback = function(v)
        _G.AutoEnchant = v
        if v then
            task.spawn(LPH_NO_VIRTUALIZE(function()
                while _G.AutoEnchant do
                    pcall(function()
                        if not GlobalData.Dependencies.DataService then return end
                        local targetId  = enchantIdMap[_G.TargetEnchant]
                        local currentId = getCurrentEnchantId()

                        if currentId == targetId then
                            Notify("Enchant", "Target reached! Stopping.", 5)
                            _G.AutoEnchant = false
                            return
                        end

                        local stones = findEnchantStones()
                        if #stones == 0 then
                            Notify("Enchant", "No stones left!", 5)
                            _G.AutoEnchant = false
                            return
                        end

                        local stone = stones[1]
                        safeFire("EquipItem", stone.UUID, "Enchant Stones")
                        task.wait(1)

                        -- Count hotbar slots via BackpackGui
                        local slotNumber = 1
                        pcall(function()
                            local bg = LocalPlayer.PlayerGui:FindFirstChild("Backpack")
                            if bg then
                                local display = bg:FindFirstChild("Display")
                                if display then
                                    local cnt = 0
                                    for _, c in ipairs(display:GetChildren()) do
                                        if c:IsA("ImageButton") then cnt += 1 end
                                    end
                                    slotNumber = math.max(1, cnt - 2)
                                end
                            end
                        end)

                        safeFire("EquipRod", slotNumber)
                        task.wait(1)
                        safeFire("ActivateAltar")
                    end)
                    task.wait(5)
                end
            end))
        end
    end,
})

TabFarm:Button({
    Title    = "Start Double Enchant",
    Callback = function()
        task.spawn(function()
            pcall(function()
                if not GlobalData.Dependencies.DataService then return end
                local inv = GlobalData.Dependencies.DataService:GetExpect({"Inventory","Items"}) or {}
                local stoneUUID = nil
                for _, item in pairs(inv) do
                    -- ID 246 = Double Enchant Stone
                    if item.Id == 246 then stoneUUID = item.UUID break end
                end
                if not stoneUUID then Notify("Enchant", "No Double Enchant Stone!", 3) return end

                local slot, start = nil, tick()
                while tick() - start < 5 do
                    local equipped = GlobalData.Dependencies.DataService:Get("EquippedItems") or {}
                    for sl, id in pairs(equipped) do
                        if id == stoneUUID then slot = sl break end
                    end
                    if slot then break end
                    safeFire("EquipItem", stoneUUID, "EnchantStones")
                    task.wait(0.3)
                end
                if not slot then Notify("Enchant", "Failed to equip stone!", 3) return end

                safeFire("EquipRod", slot)
                task.wait(0.2)
                safeFire("ActivateAltar")
                Notify("Enchant", "Double Enchant sent!", 3)
            end)
        end)
    end,
})

-- ── SECTION: Events ──
TabFarm:Section({ Title = "Events", Icon = "calendar" })

local chestThread = nil
TabFarm:Toggle({
    Title    = "Auto Claim Pirate Chest",
    Callback = function(v)
        _G.AutoClaimChest = v
        if v then
            if chestThread then task.cancel(chestThread) end
            chestThread = task.spawn(function()
                while _G.AutoClaimChest do
                    safeFire("ClaimChest")
                    task.wait(0.5)
                end
            end)
        else
            if chestThread then task.cancel(chestThread) chestThread = nil end
        end
    end,
})

TabFarm:Button({
    Title    = "Auto Collect TNT + Open Maze",
    Callback = function()
        task.spawn(function()
            -- Trigger Carpenter quest
            if GlobalData.Remotes.Dialogue then
                GlobalData.Remotes.Dialogue:FireServer("Carpenter", 2, 1)
            end
            task.wait(1)
            for i = 1, 4 do
                safeFire("SearchItem", "TNT")
                task.wait(0.5)
            end
            task.wait(1)
            safeFire("Maze")
            Notify("Event", "TNT Collected + Maze Unlock Sent!", 3)
        end)
    end,
})

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 4 — PLAYER
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabPlayer = Window:Tab({ Title = "Player", Icon = "user" })

-- ── SECTION: Movement ──
TabPlayer:Section({ Title = "Movement", Icon = "footprints" })

-- Walk Speed (numeric input, NO slider per requirement)
TabPlayer:Input({
    Title       = "Walk Speed",
    Default     = "16",
    Placeholder = "16 = default, max 100",
    Callback    = function(v)
        local n = tonumber(v)
        if n then
            _G.CustomSpeed = math.clamp(n, 1, 1000)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = _G.CustomSpeed
            end
        end
    end,
})

TabPlayer:Button({
    Title    = "Reset Speed",
    Desc     = "Return to default (16)",
    Callback = function()
        _G.CustomSpeed = 16
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
        end
        Notify("Player", "Speed reset to 16", 2)
    end,
})

-- Jump Power (numeric input, NO slider per requirement)
TabPlayer:Input({
    Title       = "Jump Power",
    Default     = "50",
    Placeholder = "50 = default",
    Callback    = function(v)
        local n = tonumber(v)
        if n then
            _G.CustomJumpPower = math.clamp(n, 1, 2000)
            local char = LocalPlayer.Character
            if char then
                local h = char:FindFirstChildOfClass("Humanoid")
                if h then h.UseJumpPower = true h.JumpPower = _G.CustomJumpPower end
            end
        end
    end,
})

TabPlayer:Button({
    Title    = "Reset Jump Power",
    Desc     = "Return to default (50)",
    Callback = function()
        _G.CustomJumpPower = 50
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower = true h.JumpPower = 50 end
        end
        Notify("Player", "Jump power reset to 50", 2)
    end,
})

-- Persist stats on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid")
    h.WalkSpeed   = _G.CustomSpeed or 16
    h.UseJumpPower = true
    h.JumpPower   = _G.CustomJumpPower or 50
end)

TabPlayer:Divider()

TabPlayer:Toggle({
    Title    = "Infinite Jump",
    Callback = function(v)
        _G.InfJump      = v
        _G.InfiniteJump = v
    end,
})

UserInputService.JumpRequest:Connect(function()
    if (_G.InfJump or _G.InfiniteJump) and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

TabPlayer:Toggle({
    Title    = "Noclip",
    Callback = function(v)
        _G.Noclip = v
        if v then
            task.spawn(function()
                while _G.Noclip do
                    task.wait(0.1)
                    if LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    end,
})

-- ── Freeze Character (STREE) ──
local freezeConn = nil
local frozenCFrame = nil

TabPlayer:Toggle({
    Title    = "Freeze Character",
    Callback = function(state)
        _G.FreezeCharacter = state
        if state then
            local char = LocalPlayer.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    frozenCFrame = root.CFrame
                    freezeConn = RunService.Heartbeat:Connect(function()
                        if _G.FreezeCharacter and root and root.Parent then
                            root.CFrame = frozenCFrame
                        end
                    end)
                end
            end
        else
            if freezeConn then freezeConn:Disconnect() freezeConn = nil end
        end
    end,
})

LocalPlayer.CharacterAdded:Connect(function(char)
    if _G.FreezeCharacter then
        task.wait(0.5)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and frozenCFrame then root.CFrame = frozenCFrame end
    end
end)

-- ── SECTION: Privacy ──
TabPlayer:Section({ Title = "Privacy", Icon = "eye-off" })

TabPlayer:Input({
    Title       = "Fake Display Name",
    Placeholder = "Enter fake name",
    Default     = "XenonHUB",
    Callback    = function(v) _G.FakeName = v end,
})

local function getOverheadHeader()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local oh = hrp:FindFirstChild("Overhead")
    if not oh then return nil end
    return oh.Content and oh.Content.Header
end

TabPlayer:Toggle({
    Title    = "Hide Identity",
    Callback = function(v)
        _G.HideID = v
        if v then
            task.spawn(function()
                while _G.HideID do
                    pcall(function()
                        local h = getOverheadHeader()
                        if h then h.Text = _G.FakeName end
                    end)
                    task.wait(0.5)
                end
            end)
        else
            pcall(function()
                local h = getOverheadHeader()
                if h then h.Text = LocalPlayer.DisplayName end
            end)
        end
    end,
})

-- ── SECTION: VFX ──
TabPlayer:Section({ Title = "Visual Effects", Icon = "sparkles" })

local VFX_ORI = {}
TabPlayer:Toggle({
    Title    = "Remove Skin VFX",
    Desc     = "Hides cosmetic particle effects",
    Callback = function(state)
        pcall(function()
            local VFX = require(RS.Controllers.VFXController)
            if state then
                VFX_ORI.H = VFX.Handle
                VFX_ORI.P = VFX.RenderAtPoint
                VFX_ORI.I = VFX.RenderInstance
                VFX.Handle        = function() end
                VFX.RenderAtPoint = function() end
                VFX.RenderInstance= function() end
                local f = Workspace:FindFirstChild("CosmeticFolder")
                if f then pcall(f.ClearAllChildren, f) end
                Notify("VFX", "Skin effects removed!", 3)
            else
                if VFX_ORI.H then VFX.Handle        = VFX_ORI.H end
                if VFX_ORI.P then VFX.RenderAtPoint = VFX_ORI.P end
                if VFX_ORI.I then VFX.RenderInstance= VFX_ORI.I end
                Notify("VFX", "Skin effects restored!", 3)
            end
        end)
    end,
})

-- ── SECTION: Animations ──
TabPlayer:Section({ Title = "Animations", Icon = "activity" })

local stopAnimConns = {}
local function setAnimEnabled(state)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, c in pairs(stopAnimConns) do c:Disconnect() end
    stopAnimConns = {}
    if state then
        local anim = hum:FindFirstChildOfClass("Animator")
        if anim then
            for _, t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end
            local conn = anim.AnimationPlayed:Connect(function(t)
                task.defer(function() t:Stop(0) end)
            end)
            table.insert(stopAnimConns, conn)
        end
        Notify("Anim", "Animations disabled!", 3)
    else
        Notify("Anim", "Animations re-enabled!", 3)
    end
end

TabPlayer:Toggle({
    Title    = "No Animation",
    Callback = setAnimEnabled,
})

-- ── SECTION: Notifications ──
TabPlayer:Section({ Title = "Game Notifications", Icon = "bell-off" })

local disableNotifConn = nil
TabPlayer:Toggle({
    Title    = "Disable Game Pop-ups",
    Callback = function(state)
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local sn = pg:FindFirstChild("Small Notification")
            or pg:WaitForChild("Small Notification", 5)
        if not sn then Notify("Error", "Notification GUI not found!", 3) return end

        if state then
            disableNotifConn = RunService.RenderStepped:Connect(function()
                sn.Enabled = false
            end)
            Notify("UI", "Game pop-ups blocked!", 2)
        else
            if disableNotifConn then
                disableNotifConn:Disconnect()
                disableNotifConn = nil
            end
            sn.Enabled = true
            Notify("UI", "Game pop-ups restored!", 2)
        end
    end,
})

-- ── SECTION: Black Screen (XenonHUB themed) ──
TabPlayer:Section({ Title = "Display", Icon = "monitor" })

TabPlayer:Toggle({
    Title    = "Black Screen Overlay",
    Callback = function(state)
        if state then
            local sg = Instance.new("ScreenGui")
            sg.Name          = "Xenon_BlackScreen"
            sg.IgnoreGuiInset = true
            sg.ResetOnSpawn  = false
            sg.Parent        = CoreGui

            local fr = Instance.new("Frame", sg)
            fr.Size            = UDim2.new(1,0,1,0)
            fr.BackgroundColor3= Color3.fromRGB(0,0,0)
            fr.BorderSizePixel = 0

            local img = Instance.new("ImageLabel", fr)
            img.AnchorPoint       = Vector2.new(0.5,0.5)
            img.Position          = UDim2.new(0.5,0,0.42,0)
            img.Size              = UDim2.new(0,160,0,160)
            img.BackgroundTransparency = 1
            img.Image             = "rbxassetid://116456203641109"

            local t1 = Instance.new("TextLabel", fr)
            t1.AnchorPoint        = Vector2.new(0.5,0)
            t1.Position           = UDim2.new(0.5,0,0.68,0)
            t1.Size               = UDim2.new(0,400,0,45)
            t1.BackgroundTransparency = 1
            t1.Text               = "XENON HUB | Fish It"
            t1.TextColor3         = Color3.fromRGB(0,220,255)
            t1.Font               = Enum.Font.GothamBold
            t1.TextSize           = 26

            local t2 = Instance.new("TextLabel", fr)
            t2.AnchorPoint        = Vector2.new(0.5,0)
            t2.Position           = UDim2.new(0.5,0,0.76,0)
            t2.Size               = UDim2.new(0,400,0,28)
            t2.BackgroundTransparency = 1
            t2.Text               = "discord.gg/MtzH9fttbs"
            t2.TextColor3         = Color3.fromRGB(180,180,255)
            t2.Font               = Enum.Font.Gotham
            t2.TextSize           = 18
        else
            local g = CoreGui:FindFirstChild("Xenon_BlackScreen")
            if g then g:Destroy() end
        end
    end,
})

-- ── SECTION: FPS Boost ──
TabPlayer:Section({ Title = "Performance", Icon = "gauge" })

TabPlayer:Toggle({
    Title    = "FPS Boost",
    Desc     = "Removes shadows, particles, water details",
    Callback = function(state)
        _G.FPSBoost = state
        local Terrain = Workspace:FindFirstChildOfClass("Terrain")
        _G._FPSObjects = _G._FPSObjects or {}

        if state then
            if not _G.OldSettings then
                _G.OldSettings = {
                    GlobalShadows      = Lighting.GlobalShadows,
                    FogEnd             = Lighting.FogEnd,
                    Brightness         = Lighting.Brightness,
                    Ambient            = Lighting.Ambient,
                    OutdoorAmbient     = Lighting.OutdoorAmbient,
                    ColorShift_Top     = Lighting.ColorShift_Top,
                    ColorShift_Bottom  = Lighting.ColorShift_Bottom,
                    WaterTransparency  = Terrain and Terrain.WaterTransparency,
                    WaterReflectance   = Terrain and Terrain.WaterReflectance,
                    WaterWaveSize      = Terrain and Terrain.WaterWaveSize,
                    WaterWaveSpeed     = Terrain and Terrain.WaterWaveSpeed,
                }
            end
            Lighting.GlobalShadows    = false
            Lighting.FogEnd           = 1e10
            Lighting.Brightness       = 0
            Lighting.Ambient          = Color3.new(1,1,1)
            Lighting.OutdoorAmbient   = Color3.new(1,1,1)
            Lighting.ColorShift_Top   = Color3.new(0,0,0)
            Lighting.ColorShift_Bottom= Color3.new(0,0,0)
            if Terrain then
                Terrain.WaterTransparency = 1
                Terrain.WaterReflectance  = 0
                Terrain.WaterWaveSize     = 0
                Terrain.WaterWaveSpeed    = 0
            end
            for _, v in ipairs(Workspace:GetDescendants()) do
                if not _G._FPSObjects[v] then
                    if v:IsA("BasePart") then
                        _G._FPSObjects[v] = {
                            Material    = v.Material,
                            Color       = v.Color,
                            CastShadow  = v.CastShadow,
                            Reflectance = v.Reflectance,
                        }
                        v.Material    = Enum.Material.SmoothPlastic
                        v.Color       = Color3.new(1,1,1)
                        v.CastShadow  = false
                        v.Reflectance = 0
                    elseif v:IsA("Light") or v:IsA("ParticleEmitter") or v:IsA("Trail") then
                        _G._FPSObjects[v] = {Enabled = v.Enabled}
                        v.Enabled = false
                    end
                end
            end
            Notify("FPS", "FPS Boost enabled!", 3)
        else
            if _G.OldSettings then
                Lighting.GlobalShadows    = _G.OldSettings.GlobalShadows
                Lighting.FogEnd           = _G.OldSettings.FogEnd
                Lighting.Brightness       = _G.OldSettings.Brightness
                Lighting.Ambient          = _G.OldSettings.Ambient
                Lighting.OutdoorAmbient   = _G.OldSettings.OutdoorAmbient
                Lighting.ColorShift_Top   = _G.OldSettings.ColorShift_Top
                Lighting.ColorShift_Bottom= _G.OldSettings.ColorShift_Bottom
                if Terrain then
                    Terrain.WaterTransparency = _G.OldSettings.WaterTransparency
                    Terrain.WaterReflectance  = _G.OldSettings.WaterReflectance
                    Terrain.WaterWaveSize     = _G.OldSettings.WaterWaveSize
                    Terrain.WaterWaveSpeed    = _G.OldSettings.WaterWaveSpeed
                end
            end
            for obj, data in pairs(_G._FPSObjects) do
                if obj and obj.Parent then
                    if obj:IsA("BasePart") then
                        obj.Material    = data.Material
                        obj.Color       = data.Color
                        obj.CastShadow  = data.CastShadow
                        obj.Reflectance = data.Reflectance
                    elseif obj:IsA("Light") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                        obj.Enabled = data.Enabled
                    end
                end
            end
            table.clear(_G._FPSObjects)
            Notify("FPS", "FPS Boost disabled!", 3)
        end
    end,
})

-- ── FPS + Ping Panel ──
TabPlayer:Toggle({
    Title    = "FPS & Ping Panel",
    Callback = function(v)
        if v then
            local p = Instance.new("ScreenGui", getUI())
            p.Name         = "XenonStats"
            p.ResetOnSpawn = false

            local main = Instance.new("Frame", p)
            main.Size             = UDim2.new(0,220,0,65)
            main.Position         = UDim2.new(0.5,-110,0.92,0)
            main.BackgroundColor3 = Color3.fromRGB(6,10,18)
            main.BackgroundTransparency = 0.2
            main.BorderSizePixel  = 0
            main.Active           = true
            Instance.new("UICorner", main).CornerRadius = UDim.new(0,14)

            local stroke = Instance.new("UIStroke", main)
            stroke.Color     = Color3.fromRGB(0,180,255)
            stroke.Thickness  = 1.6

            local header = Instance.new("Frame", main)
            header.Size            = UDim2.new(1,0,0,22)
            header.BackgroundTransparency = 1

            local title = Instance.new("TextLabel", header)
            title.Size             = UDim2.new(1,0,1,0)
            title.BackgroundTransparency = 1
            title.Font             = Enum.Font.GothamBold
            title.TextSize         = 11
            title.Text             = "XENON HUB | STATS"
            title.TextColor3       = Color3.fromRGB(0,200,255)

            local statsF = Instance.new("Frame", main)
            statsF.Position        = UDim2.new(0,6,0,24)
            statsF.Size            = UDim2.new(1,-12,1,-28)
            statsF.BackgroundTransparency = 1

            local layout = Instance.new("UIListLayout", statsF)
            layout.FillDirection      = Enum.FillDirection.Horizontal
            layout.HorizontalAlignment= Enum.HorizontalAlignment.Center
            layout.VerticalAlignment  = Enum.VerticalAlignment.Center
            layout.Padding            = UDim.new(0,6)

            local function makeStat()
                local box = Instance.new("Frame")
                box.Size             = UDim2.new(0,60,1,0)
                box.BackgroundColor3 = Color3.fromRGB(14,22,36)
                box.BackgroundTransparency = 0.1
                box.BorderSizePixel  = 0
                Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)
                local s = Instance.new("UIStroke", box)
                s.Color = Color3.fromRGB(0,80,120) s.Thickness = 1
                local lbl = Instance.new("TextLabel", box)
                lbl.Size             = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Font             = Enum.Font.GothamBold
                lbl.TextSize         = 12
                lbl.TextWrapped      = true
                lbl.TextColor3       = Color3.fromRGB(0,220,255)
                box.Parent = statsF
                return lbl
            end

            local fpsLbl  = makeStat()
            local pingLbl = makeStat()
            local cpuLbl  = makeStat()

            -- Drag panel
            local dragging2, ds2, sp2 = false, nil, nil
            header.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging2 = true ds2 = inp.Position sp2 = main.Position
                    inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End then dragging2 = false end
                    end)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging2 and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local d = inp.Position - ds2
                    main.Position = UDim2.new(sp2.X.Scale, sp2.X.Offset+d.X, sp2.Y.Scale, sp2.Y.Offset+d.Y)
                end
            end)

            local frames, fps2, last2 = 0, 0, tick()
            RunService.RenderStepped:Connect(function()
                frames += 1
                if tick() - last2 >= 1 then fps2 = frames frames = 0 last2 = tick() end
            end)

            local function getPing()
                local n = Stats:FindFirstChild("Network")
                if n then
                    local si = n:FindFirstChild("ServerStatsItem")
                    if si then
                        local dp = si:FindFirstChild("Data Ping")
                        if dp then return math.floor(dp:GetValue()) end
                    end
                end
                return 0
            end

            local function getCPU()
                local perf = Stats:FindFirstChild("PerformanceStats")
                if perf then
                    local cpu = perf:FindFirstChild("CPU")
                    if cpu then return math.floor(cpu:GetValue()) end
                end
                return 0
            end

            local function colorLabel(lbl, val, yellow, red)
                if val >= red then lbl.TextColor3 = Color3.fromRGB(255,80,80)
                elseif val >= yellow then lbl.TextColor3 = Color3.fromRGB(255,220,0)
                else lbl.TextColor3 = Color3.fromRGB(0,220,255) end
            end

            task.spawn(function()
                while p.Parent do
                    local fp = fps2
                    local pi = getPing()
                    local cp = getCPU()
                    fpsLbl.Text  = "FPS\n" .. fp
                    pingLbl.Text = "PING\n" .. pi .. "ms"
                    cpuLbl.Text  = "CPU\n" .. cp .. "%"
                    colorLabel(fpsLbl,  60 - fp, 30, 60)
                    colorLabel(pingLbl, pi, 80, 150)
                    colorLabel(cpuLbl,  cp, 50, 80)
                    task.wait(1)
                end
            end)
        else
            local g = getUI():FindFirstChild("XenonStats")
            if g then g:Destroy() end
        end
    end,
})

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 5 — SHOP
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabShop = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })

-- ── Buy Rods ──
TabShop:Section({ Title = "Fishing Rods", Icon = "shrimp" })

local rodData = {
    ["Luck Rod (350)"]          = 79,
    ["Carbon Rod (900)"]        = 76,
    ["Grass Rod (1.5k)"]        = 85,
    ["Demascus Rod (3k)"]       = 77,
    ["Ice Rod (5k)"]            = 78,
    ["Lucky Rod (15k)"]         = 4,
    ["Midnight Rod (50k)"]      = 80,
    ["Steampunk Rod (215k)"]    = 6,
    ["Chrome Rod (437k)"]       = 7,
    ["Astral Rod (1M)"]         = 5,
    ["Ares Rod (3M)"]           = 126,
    ["Angler Rod (8M)"]         = 168,
    ["Bamboo Rod (12M)"]        = 258,
}
local rodNames = {}
for k in pairs(rodData) do table.insert(rodNames, k) end
table.sort(rodNames)

local selRod = rodNames[1]
TabShop:Dropdown({ Title = "Select Rod", Values = rodNames, Callback = function(v) selRod = v end })
TabShop:Button({ Title = "Buy Rod", Callback = function()
    local id = rodData[selRod]
    if id then
        local ok, err = pcall(safeInvoke, "PurchaseRod", id)
        if ok then Notify("Shop", "Purchased: " .. selRod, 2)
        else Notify("Shop Error", tostring(err), 4) end
    end
end })

-- ── Buy Baits ──
TabShop:Section({ Title = "Baits", Icon = "compass" })

local baitData = {
    ["TopWater Bait"]  = 10,
    ["Lucky Bait"]     = 2,
    ["Midnight Bait"]  = 3,
    ["Chroma Bait"]    = 6,
    ["Dark Matter Bait"]= 8,
    ["Corrupt Bait"]   = 15,
    ["Aether Bait"]    = 16,
    ["Floral Bait"]    = 20,
}
local baitNames = {}
for k in pairs(baitData) do table.insert(baitNames, k) end
table.sort(baitNames)

local selBait = baitNames[1]
TabShop:Dropdown({ Title = "Select Bait", Values = baitNames, Callback = function(v) selBait = v end })
TabShop:Button({ Title = "Buy Bait", Callback = function()
    local id = baitData[selBait]
    if id then
        local ok, err = pcall(safeInvoke, "PurchaseBait", id)
        if ok then Notify("Shop", "Purchased: " .. selBait, 2)
        else Notify("Shop Error", tostring(err), 4) end
    end
end })

-- ── Buy Weather ──
TabShop:Section({ Title = "Weather Events", Icon = "cloud-lightning" })

local weatherData = {
    ["Wind (10k)"]         = "Wind",
    ["Snow (15k)"]         = "Snow",
    ["Cloudy (20k)"]       = "Cloudy",
    ["Storm (35k)"]        = "Storm",
    ["Radiant (50k)"]      = "Radiant",
    ["Shark Hunt (300k)"]  = "Shark Hunt",
}
local weatherNames = {}
for k in pairs(weatherData) do table.insert(weatherNames, k) end
table.sort(weatherNames)

local selWeathers  = {}
local autoBuyWeather = false
local weatherBuyDelay = 540  -- 9 minutes default

TabShop:Dropdown({
    Title     = "Select Weather",
    Values    = weatherNames,
    Multi     = true,
    AllowNone = true,
    Callback  = function(v) selWeathers = v or {} end,
})

TabShop:Input({
    Title       = "Auto Buy Interval (minutes)",
    Placeholder = "9",
    Default     = "9",
    Callback    = function(v)
        local n = tonumber(v)
        if n and n > 0 then weatherBuyDelay = n * 60 end
    end,
})

TabShop:Toggle({
    Title    = "Auto Buy Weather",
    Callback = function(v)
        autoBuyWeather = v
        if v then
            task.spawn(function()
                while autoBuyWeather do
                    for _, displayName in ipairs(selWeathers) do
                        local key = weatherData[displayName]
                        if key then
                            local ok = pcall(safeInvoke, "PurchaseWeather", key)
                            if ok then Notify("Shop", "Weather: " .. displayName, 2) end
                        end
                    end
                    task.wait(weatherBuyDelay)
                end
            end)
        end
    end,
})

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 6 — TELEPORT
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabTP = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

-- ── Islands ──
TabTP:Section({ Title = "Islands", Icon = "tree-palm" })

local IslandLocations = {
    ["Ancient Jungle"]  = Vector3.new(1518, 1, -186),
    ["Coral Refs"]      = Vector3.new(-2855, 47, 1996),
    ["Crater Island"]   = Vector3.new(997, 1, 5012),
    ["Crystal Cavern"]  = Vector3.new(-1841, -456, 7186),
    ["Enchant Room"]    = Vector3.new(3221, -1303, 1406),
    ["Enchant Room 2"]  = Vector3.new(1480, 126, -585),
    ["Esoteric Island"] = Vector3.new(1990, 5, 1398),
    ["Fisherman Island"]= Vector3.new(-175, 3, 2772),
    ["Kohana"]          = Vector3.new(-603, 3, 719),
    ["Lost Isle"]       = Vector3.new(-3643, 1, -1061),
    ["Pirate Cove"]     = Vector3.new(3172, 9, 3541),
    ["Sysyphus Statue"] = Vector3.new(-3783, -135, -950),
    ["Tropical Grove"]  = Vector3.new(-2091, 6, 3703),
    ["Volcano"]         = Vector3.new(-588, 48, 212),
    ["Weather Machine"] = Vector3.new(-1508, 6, 1895),
}

local islandKeys = {}
for k in pairs(IslandLocations) do table.insert(islandKeys, k) end
table.sort(islandKeys)

local selIsland = nil
TabTP:Dropdown({ Title = "Select Island", Values = islandKeys, Callback = function(v) selIsland = v end })
TabTP:Button({ Title = "Teleport to Island", Callback = function()
    if selIsland and IslandLocations[selIsland] and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(IslandLocations[selIsland]) end
    end
end })

-- ── Fishing Spots ──
TabTP:Section({ Title = "Fishing Spots", Icon = "map-pin" })

local FishingSpots = {
    ["Actient Ruin"]        = Vector3.new(6046, -588, 4608),
    ["Coral Refs"]          = Vector3.new(-2855, 47, 1996),
    ["Crystal Depths"]      = Vector3.new(5747, -904, 15385),
    ["Deep Ocean"]          = Vector3.new(2135, -92, -695),
    ["Kohana"]              = Vector3.new(-603, 3, 719),
    ["Leviathan"]           = Vector3.new(3474, -287, 3470),
    ["Levers 1"]            = Vector3.new(1475, 4, -847),
    ["Levers 2"]            = Vector3.new(882, 5, -321),
    ["Levers 3"]            = Vector3.new(1425, 6, 126),
    ["Levers 4"]            = Vector3.new(1837, 4, -309),
    ["Sacred Temple"]       = Vector3.new(1475, -22, -632),
    ["Sysyphus Statue"]     = Vector3.new(-3693, -136, -1045),
    ["Treasure Room"]       = Vector3.new(-3600, -267, -1575),
    ["Treasure Room Pirate"]= Vector3.new(3331, -297, 3099),
}

local fishKeys = {}
for k in pairs(FishingSpots) do table.insert(fishKeys, k) end
table.sort(fishKeys)

local selSpot = nil
TabTP:Dropdown({ Title = "Select Spot", Values = fishKeys, Callback = function(v) selSpot = v end })
TabTP:Button({ Title = "Teleport to Spot", Callback = function()
    if selSpot and FishingSpots[selSpot] and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(FishingSpots[selSpot]) end
    end
end })

-- ── Altar Shortcuts ──
TabTP:Section({ Title = "Altar Shortcuts", Icon = "diamond" })

TabTP:Button({ Title = "Teleport to Altar 1", Callback = function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(
            3234.83667, -1302.85486, 1398.39087,
            0.464485794, -1.12043161e-07, -0.885580599,
            6.74793981e-08, 1, -9.11265872e-08,
            0.885580599, -1.74314394e-08, 0.464485794
        )
    end
end })

TabTP:Button({ Title = "Teleport to Altar 2", Callback = function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(1481, 128, -592)
    end
end })

-- ── Player TP ──
TabTP:Section({ Title = "Player Teleport", Icon = "user" })

local selPlayer = nil
local function GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

local plrDrop = TabTP:Dropdown({ Title = "Select Player", Values = GetPlayerList(), Callback = function(v) selPlayer = v end })

TabTP:Button({ Title = "Teleport to Player", Callback = function()
    local t = selPlayer and Players:FindFirstChild(selPlayer)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
        LocalPlayer.Character.HumanoidRootPart.CFrame =
            t.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
    end
end })

TabTP:Button({ Title = "Refresh Player List", Callback = function()
    local list = GetPlayerList()
    pcall(function() plrDrop:Refresh(list) end)
    pcall(function() plrDrop:SetValues(list) end)
end })

-- ── Event Teleporter (STREE exclusive) ──
TabTP:Section({ Title = "Event Teleporter", Icon = "calendar" })

local evChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local evHRP  = evChar:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(c)
    evChar = c
    evHRP  = c:WaitForChild("HumanoidRootPart")
end)

local eventData = {
    ["Worm Hunt"] = {
        TargetName = "Model",
        Locations  = {
            Vector3.new(2190.85,-1.4,97.575), Vector3.new(-2450.679,-1.4,139.731),
            Vector3.new(-267.479,-1.4,5188.531), Vector3.new(-327,-1.4,2422)
        },
        PlatformY = 107, Priority = 1,
    },
    ["Megalodon Hunt"] = {
        TargetName = "Megalodon Hunt",
        Locations  = {
            Vector3.new(-1076.3,-1.4,1676.2), Vector3.new(-1191.8,-1.4,3597.3),
            Vector3.new(412.7,-1.4,4134.4)
        },
        PlatformY = 107, Priority = 2,
    },
    ["Ghost Shark Hunt"] = {
        TargetName = "Ghost Shark Hunt",
        Locations  = {
            Vector3.new(489.559,-1.35,25.406), Vector3.new(-1358.216,-1.35,4100.556),
            Vector3.new(627.859,-1.35,3798.081)
        },
        PlatformY = 107, Priority = 3,
    },
    ["Shark Hunt"] = {
        TargetName = "Shark Hunt",
        Locations  = {
            Vector3.new(1.65,-1.35,2095.725), Vector3.new(1369.95,-1.35,930.125),
            Vector3.new(-1585.5,-1.35,1242.875), Vector3.new(-1896.8,-1.35,2634.375)
        },
        PlatformY = 107, Priority = 4,
    },
}

local eventNames    = {}
for k in pairs(eventData) do table.insert(eventNames, k) end

local autoEventTP    = false
local selectedEvents = {}
local evPlatform     = nil
local MEG_RADIUS     = 150

local function destroyEvPlatform()
    if evPlatform and evPlatform.Parent then
        evPlatform:Destroy()
        evPlatform = nil
    end
end

local function tpToPlatform(pos, y)
    destroyEvPlatform()
    local plat = Instance.new("Part")
    plat.Size        = Vector3.new(5,1,5)
    plat.Position    = Vector3.new(pos.X, y, pos.Z)
    plat.Anchored    = true
    plat.Transparency= 1
    plat.CanCollide  = true
    plat.Name        = "XenonEventPlatform"
    plat.Parent      = Workspace
    evPlatform       = plat
    evHRP.CFrame     = CFrame.new(plat.Position + Vector3.new(0,3,0))
end

local function runEventTP()
    while autoEventTP do
        local sorted = {}
        for _, name in ipairs(selectedEvents) do
            if eventData[name] then table.insert(sorted, eventData[name]) end
        end
        table.sort(sorted, function(a,b) return a.Priority < b.Priority end)

        for _, cfg in ipairs(sorted) do
            local found, foundPos = nil, nil

            if cfg.TargetName == "Model" then
                local mr = Workspace:FindFirstChild("!!! MENU RINGS")
                if mr then
                    for _, props in ipairs(mr:GetChildren()) do
                        if props.Name == "Props" then
                            local model = props:FindFirstChild("Model")
                            if model and model.PrimaryPart then
                                for _, loc in ipairs(cfg.Locations) do
                                    if (model.PrimaryPart.Position - loc).Magnitude <= MEG_RADIUS then
                                        found = model
                                        foundPos = model.PrimaryPart.Position
                                        break
                                    end
                                end
                            end
                        end
                        if found then break end
                    end
                end
            else
                for _, loc in ipairs(cfg.Locations) do
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d.Name == cfg.TargetName then
                            local pos = d:IsA("BasePart") and d.Position
                                or (d.PrimaryPart and d.PrimaryPart.Position)
                            if pos and (pos - loc).Magnitude <= MEG_RADIUS then
                                found    = d
                                foundPos = pos
                                break
                            end
                        end
                    end
                    if found then break end
                end
            end

            if found and foundPos then
                tpToPlatform(foundPos, cfg.PlatformY)
            end
        end
        task.wait(0.05)
    end
    destroyEvPlatform()
end

TabTP:Dropdown({
    Title     = "Select Events",
    Values    = eventNames,
    Multi     = true,
    AllowNone = true,
    Callback  = function(v) selectedEvents = v or {} end,
})

TabTP:Toggle({
    Title    = "Auto Event Teleport",
    Callback = function(v)
        autoEventTP = v
        if v then task.spawn(runEventTP) end
    end,
})

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 7 — WEBHOOK (STREE advanced)
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabWebhook = Window:Tab({ Title = "Webhook", Icon = "webhook" })

TabWebhook:Section({ Title = "Fish Caught Webhook", Icon = "fish" })

-- Fish database (built from Items in RS)
local fishDB = {}
local knownFishUUIDs = {}

local tierRarityMap = {
    [1]="Common", [2]="Uncommon", [3]="Rare",
    [4]="Epic", [5]="Legendary", [6]="Mythic", [7]="SECRET"
}

local function buildFishDB()
    local itemsC = RS:FindFirstChild("Items")
    if not itemsC then return end
    for _, mod in ipairs(itemsC:GetChildren()) do
        local ok, d = pcall(require, mod)
        if ok and type(d) == "table" and d.Data and d.Data.Type == "Fish" then
            if d.Data.Id and d.Data.Name then
                fishDB[d.Data.Id] = {
                    Name      = d.Data.Name,
                    Tier      = d.Data.Tier,
                    Icon      = d.Data.Icon,
                    SellPrice = d.SellPrice,
                }
            end
        end
    end
end

local function getInventoryFish()
    if not GlobalData.Dependencies.DataService then return {} end
    local inv = GlobalData.Dependencies.DataService:GetExpect({"Inventory","Items"}) or {}
    local out = {}
    for _, v in pairs(inv) do
        local d = GlobalData.Dependencies.ItemUtility.GetItemDataFromItemType("Items", v.Id)
        if d and d.Data.Type == "Fish" then
            table.insert(out, {Id = v.Id, UUID = v.UUID, Metadata = v.Metadata})
        end
    end
    return out
end

local function getCoins()
    if not GlobalData.Dependencies.DataService then return "N/A" end
    local ok, c = pcall(function() return GlobalData.Dependencies.DataService:Get("Coins") end)
    if ok and c then
        return tostring(c):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
    end
    return "N/A"
end

local function sendFishWebhook(fish)
    if not request or not _G.WebhookURL or not _G.WebhookURL:match("discord.com/api/webhooks") then return end
    local info = fishDB[fish.Id]
    if not info then return end
    local rarity = tierRarityMap[info.Tier] or "Unknown"
    if #_G.WebhookRarities > 0 and not table.find(_G.WebhookRarities, rarity) then return end

    local weight   = fish.Metadata and fish.Metadata.Weight and string.format("%.2f Kg", fish.Metadata.Weight) or "N/A"
    local mutation = fish.Metadata and fish.Metadata.VariantId and tostring(fish.Metadata.VariantId) or "None"
    local sell     = info.SellPrice and ("$"..tostring(info.SellPrice).." Coins") or "N/A"

    local payload = {
        username = "XenonHUB Webhook",
        embeds = {{
            title       = "XenonHUB | Fish Caught!",
            description = string.format("**%s** caught a **%s** fish!", LocalPlayer.Name, rarity),
            color       = 0x00F0FF,
            fields = {
                {name = "Name",     value = "```" .. info.Name .. "```"},
                {name = "Rarity",   value = "```" .. rarity    .. "```"},
                {name = "Weight",   value = "```" .. weight    .. "```"},
                {name = "Mutation", value = "```" .. mutation  .. "```"},
                {name = "Sell",     value = "```" .. sell      .. "```"},
                {name = "Coins",    value = "```" .. getCoins() .. "```"},
            },
            footer = { text = "XenonHUB | discord.gg/MtzH9fttbs" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        }},
    }

    pcall(function()
        request({
            Url     = _G.WebhookURL,
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = HttpService:JSONEncode(payload),
        })
    end)
end

local function sendTestWebhook()
    if not request or not _G.WebhookURL or not _G.WebhookURL:match("discord.com/api/webhooks") then
        Notify("Webhook", "Invalid URL!", 3) return
    end
    local payload = {
        username = "XenonHUB Webhook",
        embeds = {{
            title       = "Test — XenonHUB Connected!",
            description = "Webhook connection successful.",
            color       = 0x00F0FF,
        }},
    }
    pcall(function()
        request({
            Url     = _G.WebhookURL,
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = HttpService:JSONEncode(payload),
        })
    end)
    Notify("Webhook", "Test sent!", 2)
end

task.spawn(buildFishDB)

-- Init known UUIDs
task.spawn(function()
    repeat task.wait(1) until GlobalData.Loaded
    local fish = getInventoryFish()
    for _, f in ipairs(fish) do
        if f.UUID then knownFishUUIDs[f.UUID] = true end
    end
end)

-- Watch loop
task.spawn(LPH_NO_VIRTUALIZE(function()
    while task.wait(3) do
        if _G.DetectNewFishActive then
            pcall(function()
                local current = getInventoryFish()
                for _, f in ipairs(current) do
                    if f.UUID and not knownFishUUIDs[f.UUID] then
                        knownFishUUIDs[f.UUID] = true
                        sendFishWebhook(f)
                    end
                end
            end)
        end
    end
end))

TabWebhook:Input({
    Title       = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default     = "",
    Callback    = function(v) _G.WebhookURL = v end,
})

TabWebhook:Dropdown({
    Title     = "Rarity Filter (empty = all)",
    Values    = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","SECRET"},
    Multi     = true,
    AllowNone = true,
    Callback  = function(v) _G.WebhookRarities = v or {} end,
})

TabWebhook:Toggle({
    Title    = "Send Webhook on Fish",
    Callback = function(v) _G.DetectNewFishActive = v end,
})

TabWebhook:Button({ Title = "Test Webhook", Callback = sendTestWebhook })

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 8 — GIFT / EXCLUSIVE
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabGift = Window:Tab({ Title = "Exclusive", Icon = "gift" })

TabGift:Section({ Title = "Gift Skins", Icon = "gift" })

local GiftingController = nil
pcall(function()
    GiftingController = require(RS:WaitForChild("Controllers"):WaitForChild("GiftingController"))
end)

local function openGift(name)
    if GiftingController and GiftingController.Open then
        pcall(function() GiftingController:Open(name) end)
        Notify("Gift", name .. " opened!", 3)
    else
        Notify("Gift", "Patched / not available!", 3)
    end
end

TabGift:Button({ Title = "Gift — Holy Trindent",     Callback = function() openGift("Holy Trindent") end })
TabGift:Button({ Title = "Gift — Ethereal Sword",    Callback = function() openGift("Ethereal Sword") end })
TabGift:Button({ Title = "Gift — Crescendo Scythe",  Callback = function() openGift("Crescendo Scythe") end })

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 9 — SETTINGS
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ── Anti AFK ──
TabSettings:Section({ Title = "Session", Icon = "clock" })

TabSettings:Toggle({
    Title = "Anti-AFK",
    Desc  = "Prevents idle kick (24h sessions)",
    Callback = function(state)
        _G.AntiAFK = state
        if state then
            task.spawn(function()
                while _G.AntiAFK do
                    task.wait(50)
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new(0,0))
                    end)
                end
            end)
            task.spawn(function()
                while _G.AntiAFK do
                    task.wait(300)
                    pcall(function() LocalPlayer.Idled:Fire() end)
                end
            end)
        end
    end,
})

TabSettings:Toggle({
    Title    = "Auto Reconnect",
    Desc     = "Auto-clicks reconnect button on disconnect",
    Callback = function(state)
        _G.AutoReconnect = state
        if state then
            task.spawn(function()
                while _G.AutoReconnect do
                    task.wait(2)
                    pcall(function()
                        local ui = CoreGui:FindFirstChild("RobloxPromptGui")
                        if ui then
                            local overlay = ui:FindFirstChild("promptOverlay")
                            if overlay then
                                local btn = overlay:FindFirstChild("ButtonPrimary")
                                if btn and btn.Visible then
                                    firesignal(btn.MouseButton1Click)
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

-- ── Server ──
TabSettings:Section({ Title = "Server", Icon = "server" })

TabSettings:Button({
    Title = "Rejoin Server",
    Desc  = "Reconnect to same server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

TabSettings:Button({
    Title    = "Server Hop",
    Desc     = "Switch to another available server",
    Callback = function()
        local ok, data = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId ..
                    "/servers/Public?sortOrder=Asc&limit=100")
            )
        end)
        if not ok or not data or not data.data then
            Notify("Error", "Failed to fetch server list!", 3) return
        end
        for _, s in ipairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                return
            end
        end
        Notify("Server Hop", "No available servers!", 3)
    end,
})

-- ── Config Save/Load ──
TabSettings:Section({ Title = "Config", Icon = "folder-open" })

local CONFIG_FOLDER = "XENON_FISHIT/Configs"
local CONFIG_FILE   = CONFIG_FOLDER .. "/default.json"

pcall(function()
    if not isfolder("XENON_FISHIT") then makefolder("XENON_FISHIT") end
    if not isfolder(CONFIG_FOLDER)  then makefolder(CONFIG_FOLDER) end
end)

local function buildConfig()
    return {
        DelaySpeed     = _G.DelaySpeed,
        SellDelay      = _G.SellDelay,
        AutoSell       = _G.AutoSell,
        TargetEnchant  = _G.TargetEnchant,
        CustomSpeed    = _G.CustomSpeed,
        CustomJumpPower= _G.CustomJumpPower,
        InfiniteJump   = _G.InfiniteJump,
        AntiAFK        = _G.AntiAFK,
        AutoReconnect  = _G.AutoReconnect,
        WebhookURL     = _G.WebhookURL,
        InstantDelay   = _G.InstantDelay,
    }
end

local function applyConfig(data)
    if data.DelaySpeed      then _G.DelaySpeed      = data.DelaySpeed end
    if data.SellDelay       then _G.SellDelay       = data.SellDelay end
    if data.AutoSell ~= nil then _G.AutoSell        = data.AutoSell end
    if data.TargetEnchant   then _G.TargetEnchant   = data.TargetEnchant end
    if data.CustomSpeed     then
        _G.CustomSpeed = data.CustomSpeed
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = _G.CustomSpeed
        end
    end
    if data.CustomJumpPower then
        _G.CustomJumpPower = data.CustomJumpPower
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower = true h.JumpPower = _G.CustomJumpPower end
        end
    end
    if data.InfiniteJump ~= nil then _G.InfiniteJump = data.InfiniteJump end
    if data.AntiAFK      ~= nil then _G.AntiAFK      = data.AntiAFK end
    if data.AutoReconnect~= nil then _G.AutoReconnect = data.AutoReconnect end
    if data.WebhookURL      then _G.WebhookURL      = data.WebhookURL end
    if data.InstantDelay    then _G.InstantDelay    = data.InstantDelay end
end

TabSettings:Button({
    Title    = "Save Config",
    Desc     = "Save all current settings",
    Callback = function()
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(buildConfig()))
            Notify("Config", "Saved!", 2)
        end)
    end,
})

TabSettings:Button({
    Title    = "Load Config",
    Desc     = "Load saved settings",
    Callback = function()
        pcall(function()
            if isfile(CONFIG_FILE) then
                local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
                applyConfig(data)
                Notify("Config", "Loaded!", 2)
            else
                Notify("Config", "No config file found!", 3)
            end
        end)
    end,
})

TabSettings:Button({
    Title    = "Delete Config",
    Desc     = "Remove saved config",
    Callback = function()
        pcall(function()
            if isfile(CONFIG_FILE) then
                delfile(CONFIG_FILE)
                Notify("Config", "Deleted!", 2)
            end
        end)
    end,
})

-- ─────────────────────────────────────────────
-- ══════════════════════════════════════════════
-- TAB 10 — MISC / EXTRAS
-- ══════════════════════════════════════════════
-- ─────────────────────────────────────────────
local TabMisc = Window:Tab({ Title = "Misc", Icon = "code" })

TabMisc:Section({ Title = "External Scripts", Icon = "file-code" })

TabMisc:Button({ Title = "Infinite Yield",  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkNetworks/Infinite-Yield/main/latest.lua"))()
end })

TabMisc:Button({ Title = "Fly GUI V3",  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
end })

TabMisc:Button({ Title = "Simple Shader",  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/p0e1/1/refs/heads/main/SimpleShader.lua"))()
end })

TabMisc:Section({ Title = "Utility", Icon = "wrench" })

TabMisc:Button({
    Title    = "Full Destroy + Remove",
    Desc     = "Removes all XenonHUB GUIs from CoreGui",
    Callback = FullClose,
})

-- ─────────────────────────────────────────────
-- STARTUP NOTIFICATION
-- ─────────────────────────────────────────────
Notify("XenonHUB", "All systems loaded! discord.gg/MtzH9fttbs", 6)

WindUI:Notify({
    Title   = "XenonHUB Loaded",
    Content = "Fish It | Developer: Hann 25",
    Duration= 4,
    Icon    = "anchor",
})
