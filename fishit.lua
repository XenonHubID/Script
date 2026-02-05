getgenv().LPH_NO_VIRTUALIZE = function(f) return f end
local function LPH_NO_VIRTUALIZE(f) return f end;

--/// 1. SERVICES \\\--
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser      = game:GetService("VirtualUser")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

--/// 2. LOAD UI LIBRARY (PRIORITAS PERTAMA) \\\--
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not success or not WindUI then
    -- Fallback Error Message jika WindUI gagal
    local m = Instance.new("Message", workspace)
    m.Text = "XENON ERROR: Gagal memuat UI Library. Cek koneksi/VPN!"
    task.wait(5)
    m:Destroy()
    return
end

--/// 3. NOTIFICATION SYSTEM (XENON VISUALS) \\\--
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "XenonNotifs"
NotifGui.Parent = CoreGui
NotifGui.ResetOnSpawn = false

local NotifContainer = Instance.new("Frame")
NotifContainer.Name = "Container"
NotifContainer.Position = UDim2.new(0.01, 0, 0.3, 0)
NotifContainer.Size = UDim2.new(0, 300, 0.5, 0)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = NotifGui

local UIList = Instance.new("UIListLayout")
UIList.Parent = NotifContainer
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)
UIList.VerticalAlignment = Enum.VerticalAlignment.Bottom

function Notify(Title, Text, Duration)
    local Duration = Duration or 3
    local Frame = Instance.new("Frame")
    Frame.Name = "NotifFrame"
    Frame.Size = UDim2.new(0, 0, 0, 35)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = NotifContainer
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Frame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Frame
    Stroke.Thickness = 1.2
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 180)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
    }
    Gradient.Parent = Stroke
    
    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 20, 0, 20)
    Icon.Position = UDim2.new(0, 8, 0.5, -10)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://130982330871305"
    Icon.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 35, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = string.format("<b><font color='rgb(0,255,180)'>%s</font></b> | %s", Title, Text)
    Label.RichText = true
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTransparency = 1
    Label.Parent = Frame
    
    Frame:TweenSize(UDim2.new(0, 260, 0, 35), "Out", "Back", 0.4, true)
    TweenService:Create(Label, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    
    task.delay(Duration, function()
        Frame:TweenSize(UDim2.new(0, 0, 0, 35), "In", "Quad", 0.3, true)
        TweenService:Create(Label, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        task.wait(0.3)
        Frame:Destroy()
    end)
end

Notify("System", "Loading Game Data...", 5)

--/// 4. LOAD DEPENDENCIES (NON-BLOCKING) \\\--
local ItemUtility, Replion, DataService
local depsLoaded = false

task.spawn(function()
    local s, e = pcall(function()
        ItemUtility = require(RS.Shared.ItemUtility)
        Replion = require(RS.Packages.Replion)
        -- WaitReplion bisa bikin macet, jadi kita taruh di thread terpisah
        DataService = Replion.Client:WaitReplion("Data")
    end)
    if s then 
        depsLoaded = true 
        Notify("System", "Data Loaded Successfully!", 3)
    else
        warn("Dep Error: "..tostring(e))
        Notify("System", "Warning: Inventory Data Failed!", 5)
    end
end)

--/// 5. SAFE REMOTE LOADING \\\--
local net = nil
pcall(function()
    if RS.Packages:FindFirstChild("_Index") then
        local index = RS.Packages._Index
        for _, child in ipairs(index:GetChildren()) do
            if string.find(child.Name, "sleitnick_net") then
                net = child.net
                break
            end
        end
    end
end)

if not net then 
    Notify("System", "Critical: Remote 'net' not found!", 10) 
    -- Lanjut aja biar menu tetep kebuka, meski fitur rusak
end

local Remotes = {
    EquipRod = net and net:FindFirstChild("RE/EquipToolFromHotbar"),
    SellAll = net and net:FindFirstChild("RF/SellAllItems"),
    Cast = net and net:FindFirstChild("RF/RequestFishingMinigameStarted"),
    Charge = net and net:FindFirstChild("RF/ChargeFishingRod"),
    Complete = net and net:FindFirstChild("RE/FishingCompleted"),
    Cancel = net and net:FindFirstChild("RF/CancelFishingInputs"),
    UpdateAuto = net and net:FindFirstChild("RF/UpdateAutoFishingState"),
    PurchaseRod = net and net:FindFirstChild("RF/PurchaseFishingRod"),
    PurchaseBait = net and net:FindFirstChild("RF/PurchaseBait"),
    PurchaseWeather = net and net:FindFirstChild("RF/PurchaseWeatherEvent"),
    EquipItem = net and net:FindFirstChild("RE/EquipItem"),
    ActivateAltar = net and net:FindFirstChild("RE/ActivateEnchantingAltar"),
    FavoriteItem = net and net:FindFirstChild("RE/FavoriteItem"),
    FavoriteStateChanged = net and net:FindFirstChild("RE/FavoriteStateChanged"),
}

--/// 6. HELPER FUNCTIONS \\\--
local function getChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getHum() return getChar():FindFirstChild("Humanoid") end
local function safeCall(name, func) pcall(func) end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        if _G.CustomSpeed then hum.WalkSpeed = _G.CustomSpeed end
        if _G.CustomJumpPower then 
            hum.UseJumpPower = true
            hum.JumpPower = _G.CustomJumpPower 
        end
    end
end)

--/// 7. WINDOW CONFIG \\\--
local Window = WindUI:CreateWindow({
    Title = "XENON HUB",
    Icon = "rbxassetid://130982330871305",
    Author = "Hann 25 | V7 Fixed",
    Folder = "XENON_FISHIT",
    Size = UDim2.fromOffset(260, 290),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
    User = { Enabled = true, Anonymous = true },
})

Window:EditOpenButton({Enabled = false})

-- TOGGLE BUTTON
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "XenonGUI"
ScreenGui.ResetOnSpawn = false

local ButtonResize = Instance.new("ImageButton", ScreenGui)
ButtonResize.Draggable = true
ButtonResize.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
ButtonResize.Image = "rbxassetid://130982330871305"
ButtonResize.Size = UDim2.new(0, 45, 0, 45)
ButtonResize.Position = UDim2.new(0.1, 0, 0.1, 0)

Instance.new("UICorner", ButtonResize).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", ButtonResize)
stroke.Thickness = 1.3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local strokeGrad = Instance.new("UIGradient", stroke)
strokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 120)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 120))
}
strokeGrad.Rotation = 45

local Glow = Instance.new("ImageLabel", ButtonResize)
Glow.Size = UDim2.new(1.5, 0, 1.5, 0)
Glow.Position = UDim2.new(-0.25, 0, -0.25, 0)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5028857472"
Glow.ImageColor3 = Color3.fromRGB(0, 255, 180)
Glow.ImageTransparency = 0.6
Glow.ZIndex = 0

local windowVisible = true
ButtonResize.MouseButton1Click:Connect(function()
    if windowVisible then Window:Close() else Window:Open() end
    windowVisible = not windowVisible
end)

--================================================================================--
--/// TAB 1: INFO \\\--
local Tab1 = Window:Tab({ Title = "Info", Icon = "info" })
Tab1:Section({ Title = "Info", Icon = "chevrons-left-right", TextXAlignment = "Left" })
Tab1:Button({ Title = "Discord", Callback = function() setclipboard("https://discord.gg/MtzH9fttbs") end })
Tab1:Keybind({ Title = "Close/Open UI", Value = "G", Callback = function(v) Window:SetToggleKey(Enum.KeyCode[v]) end })

--================================================================================--
--/// TAB 2: FISHING \\\--
local Tab2 = Window:Tab({ Title = "Fishing", Icon = "anchor" })

Tab2:Toggle({
    Title = "Auto Equip Rod",
    Callback = function(v)
        _G.AutoEquipRod = v
        if v and Remotes.EquipRod then safeCall("Equip", function() Remotes.EquipRod:FireServer(1) end) end
    end
})

local mode = "Instant"
local fishThread
_G.InstantDelay = 0.65

Tab2:Dropdown({ Title = "Mode", Values = {"Instant", "Legit"}, Value = "Instant", Callback = function(v) mode = v end })

local function RunInstantCycle()
    if Remotes.Cancel then Remotes.Cancel:InvokeServer() end
    if Remotes.Charge then Remotes.Charge:InvokeServer(math.huge) end
    if Remotes.Cast then Remotes.Cast:InvokeServer(1, 0.05, 1731873.1873) end
    task.wait(_G.InstantDelay)
    if Remotes.Complete then Remotes.Complete:FireServer() end
end

Tab2:Toggle({
    Title = "Auto Fishing",
    Callback = function(v)
        _G.AutoFishing = v
        if v then
            fishThread = task.spawn(function()
                while _G.AutoFishing do
                    if mode == "Instant" then
                        pcall(RunInstantCycle)
                        task.wait(0.35)
                    else
                        if Remotes.UpdateAuto then Remotes.UpdateAuto:InvokeServer(true) end
                        task.wait(1)
                    end
                end
            end)
        else
            if fishThread then task.cancel(fishThread) end
            if Remotes.UpdateAuto then Remotes.UpdateAuto:InvokeServer(false) end
        end
    end
})

Tab2:Slider({ Title = "Instant Delay", Step = 0.01, Value = {Min = 0.05, Max = 5, Default = 0.65}, Callback = function(v) _G.InstantDelay = v end })

-- BLATANT
Tab2:Section({ Title = "Blatant Fishing", Icon = "fish-off" })
local BlatantConfig = { Active = false, DelayBait = 0.1, DelayReel = 0.1 }
local blatantThread

local function RunBlatant()
    while BlatantConfig.Active do
        pcall(function()
            if Remotes.Cancel then Remotes.Cancel:InvokeServer() end
            if Remotes.Charge then Remotes.Charge:InvokeServer(math.huge) end
            if Remotes.Cast then Remotes.Cast:InvokeServer(1, 0.05, 1731873) end
        end)
        task.wait(BlatantConfig.DelayReel)
        pcall(function() if Remotes.Complete then Remotes.Complete:FireServer() end end)
        task.wait(BlatantConfig.DelayBait)
    end
end

Tab2:Toggle({
    Title = "Blatant Mode",
    Callback = function(v)
        BlatantConfig.Active = v
        if v then blatantThread = task.spawn(RunBlatant)
        else if blatantThread then task.cancel(blatantThread) end end
    end
})

Tab2:Input({ Title = "Delay Bait", Default = "0.1", Callback = function(v) BlatantConfig.DelayBait = tonumber(v) or 0.1 end })
Tab2:Input({ Title = "Delay Reel", Default = "0.1", Callback = function(v) BlatantConfig.DelayReel = tonumber(v) or 0.1 end })

--================================================================================--
--/// TAB 3: AUTOMATION \\\--
local Tab3 = Window:Tab({ Title = "Automation", Icon = "cpu" })

Tab3:Section({ Title = "Auto Sell", Icon = "coins" })
Tab3:Toggle({
    Title = "Auto Sell",
    Callback = function(v)
        _G.AutoSell = v
        if v then
            task.spawn(function()
                while _G.AutoSell do
                    if Remotes.SellAll then Remotes.SellAll:InvokeServer() end
                    task.wait(_G.SellDelay or 30)
                end
            end)
        end
    end
})
Tab3:Input({ Title = "Sell Delay (s)", Default = "30", Callback = function(v) _G.SellDelay = tonumber(v) or 30 end })

-- ENCHANT
Tab3:Section({ Title = "Enchant", Icon = "flask-conical" })
local enchantNames = { "Big Hunter 1", "Cursed 1", "Empowered 1", "Glistening 1", "Gold Digger 1", "Leprechaun 1", "Mutation Hunter 1", "Prismatic 1", "Reeler 1", "Stargazer 1", "Stormhunter 1", "XPerienced 1" }
local enchantIdMap = { ["Big Hunter 1"]=3, ["Cursed 1"]=12, ["Empowered 1"]=9, ["Glistening 1"]=1, ["Gold Digger 1"]=4, ["Leprechaun 1"]=5, ["Mutation Hunter 1"]=7, ["Prismatic 1"]=13, ["Reeler 1"]=2, ["Stargazer 1"]=8, ["Stormhunter 1"]=11, ["XPerienced 1"]=10 }

Tab3:Dropdown({ Title = "Target Enchant", Values = enchantNames, Value = enchantNames[1], Callback = function(v) _G.TargetEnchant = v end })

local function getCurrentRodEnchant()
    if not depsLoaded then return nil end
    local equipped = DataService:Get("EquippedItems") or {}
    local rods = DataService:GetExpect({ "Inventory", "Fishing Rods" }) or {}
    for _, uuid in pairs(equipped) do
        for _, rod in ipairs(rods) do
            if rod.UUID == uuid and rod.Metadata then return rod.Metadata.EnchantId end
        end
    end
    return nil
end

local function findEnchantStone()
    if not depsLoaded then return nil end
    local inventory = DataService:GetExpect({ "Inventory", "Items" })
    for _, item in pairs(inventory) do
        local def = ItemUtility:GetItemData(item.Id)
        if def and def.Data and def.Data.Type == "Enchant Stones" then return item end
    end
    return nil
end

Tab3:Toggle({
    Title = "Auto Enchant",
    Callback = function(v)
        _G.AutoEnchant = v
        if v then
            if not depsLoaded then Notify("Error", "Data not loaded yet!", 3) _G.AutoEnchant=false return end
            task.spawn(function()
                while _G.AutoEnchant do
                    local current = getCurrentRodEnchant()
                    local target = enchantIdMap[_G.TargetEnchant]
                    if current == target then Notify("Enchant", "Target Reached!", 5) _G.AutoEnchant = false break end
                    local stone = findEnchantStone()
                    if stone then
                        Remotes.EquipItem:FireServer(stone.UUID, "Enchant Stones")
                        task.wait(0.5)
                        Remotes.EquipRod:FireServer(1) 
                        task.wait(0.5)
                        Remotes.ActivateAltar:FireServer()
                        task.wait(4)
                    else
                        Notify("Enchant", "Out of Stones!", 5)
                        _G.AutoEnchant = false
                        break
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

-- AUTO FAVORITE
Tab3:Section({ Title = "Auto Favorite", Icon = "star" })
local st = { autoFavEnabled = false }
local tierToRarity = { [1]="Uncommon", [2]="Common", [3]="Rare", [4]="Epic", [5]="Legendary", [6]="Mythic", [7]="Secret" }
local favState, selectedRarity = {}, {}

if Remotes.FavoriteStateChanged then
    Remotes.FavoriteStateChanged.OnClientEvent:Connect(function(uuid, fav) if uuid then favState[uuid] = fav end end)
end

local function scanInventory()
    if not st.autoFavEnabled or not depsLoaded then return end
    local inv = DataService:GetExpect({ "Inventory", "Items" })
    if not inv then return end
    for _, item in ipairs(inv) do 
        local info = ItemUtility.GetItemDataFromItemType("Items", item.Id)
        if info and info.Data.Type == "Fish" then
            local rarity = tierToRarity[info.Data.Tier]
            local isFav = favState[item.UUID] or item.Favorited or false
            if table.find(selectedRarity, rarity) and not isFav then
                if Remotes.FavoriteItem then
                    Remotes.FavoriteItem:FireServer(item.UUID, true)
                    favState[item.UUID] = true
                end
            end
        end
    end
end

-- Hook if data changes
task.spawn(function()
    repeat task.wait(1) until depsLoaded
    if DataService then DataService:OnChange({ "Inventory", "Items" }, function() if st.autoFavEnabled then scanInventory() end end) end
end)

Tab3:Dropdown({ Title = "Favorite by Rarity", Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}, Multi = true, Callback = function(opts) selectedRarity = opts or {} if st.autoFavEnabled then scanInventory() end end })
Tab3:Toggle({ Title = "Start Auto Favorite", Callback = function(state) st.autoFavEnabled = state if state then scanInventory() end end })

-- EVENTS
Tab3:Section({ Title = "Event", Icon = "calendar-days" })
local chestRemote = net and net:FindFirstChild("RE/ClaimPirateChest")
Tab3:Toggle({
    Title = "Auto Claim Chest",
    Callback = function(state)
        _G.AutoClaimChest = state
        if state then
            task.spawn(function()
                while _G.AutoClaimChest do
                    if chestRemote then chestRemote:FireServer() end
                    task.wait(2)
                end
            end)
        end
    end
})

local RE_DialogueEnded = net and net:FindFirstChild("RE/DialogueEnded")
local RE_PickupItem = net and net:FindFirstChild("RE/SearchItemPickedUp")
local RE_OpenMaze = net and net:FindFirstChild("RE/GainAccessToMaze")

Tab3:Button({
    Title = "Auto Collect TNT + Maze",
    Callback = function()
        if RE_DialogueEnded then RE_DialogueEnded:FireServer("Carpenter", 2, 1) end
        task.wait(1)
        for i=1,4 do if RE_PickupItem then RE_PickupItem:FireServer("TNT") end task.wait(0.3) end
        task.wait(1)
        if RE_OpenMaze then RE_OpenMaze:FireServer() end
        Notify("Event", "Maze Attempted", 3)
    end
})

--================================================================================--
--/// TAB 4: PLAYERS \\\--
local Tab4 = Window:Tab({ Title = "Players", Icon = "user" })
Tab4:Slider({ Title = "Speed", Step = 1, Value = {Min = 16, Max = 100, Default = 16}, Callback = function(v) _G.CustomSpeed = v local hum = getHum() if hum then hum.WalkSpeed = v end end })
Tab4:Slider({ Title = "Jump", Step = 1, Value = {Min = 50, Max = 500, Default = 50}, Callback = function(v) _G.CustomJumpPower = v local hum = getHum() if hum then hum.UseJumpPower=true hum.JumpPower=v end end })
Tab4:Toggle({ Title = "Infinite Jump", Callback = function(state) _G.InfiniteJump = state end })
UserInputService.JumpRequest:Connect(function() if _G.InfiniteJump then local hum=getHum() if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)
Tab4:Toggle({ Title = "Noclip", Callback = function(state) _G.Noclip=state task.spawn(function() while _G.Noclip do task.wait(0.1) local c=getChar() if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end end) end })
Tab4:Toggle({ Title = "Freeze Character", Callback = function(s) local h = getChar():FindFirstChild("HumanoidRootPart") if h then h.Anchored = s end end})

-- HIDE IDENTITY
Tab4:Section({ Title = "Identity", Icon = "mask" })
local customHeader = "Xenon User"
Tab4:Input({ Title = "Set Name", Placeholder = "Input Name", Callback = function(value) customHeader = value end })
Tab4:Toggle({
    Title = "Hide Identity",
    Callback = function(state)
        _G.HideIdentity = state
        task.spawn(function()
            while _G.HideIdentity do
                local char = getChar()
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local oh = hrp:FindFirstChild("Overhead")
                        if oh and oh:FindFirstChild("Content") then
                            oh.Content.Header.Text = customHeader
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
})

--================================================================================--
--/// TAB 5: SHOP \\\--
local Tab5 = Window:Tab({ Title = "Shop", Icon = "badge-dollar-sign" })
local rods = { ["Luck Rod"]=79, ["Carbon Rod"]=76, ["Grass Rod"]=85, ["Demascus Rod"]=77, ["Ice Rod"]=78, ["Lucky Rod"]=4, ["Midnight Rod"]=80, ["Steampunk Rod"]=6, ["Chrome Rod"]=7, ["Astral Rod"]=5, ["Ares Rod"]=126, ["Angler Rod"]=168, ["Bamboo Rod"]=258 }
local rodNames = {} for k,_ in pairs(rods) do table.insert(rodNames, k) end
local selectedRod = rodNames[1]
Tab5:Section({ Title = "Buy Rods", Icon = "shrimp" })
Tab5:Dropdown({ Title = "Select Rod", Values = rodNames, Callback = function(v) selectedRod = v end })
Tab5:Button({ Title = "Buy Rod", Callback = function() if Remotes.PurchaseRod and rods[selectedRod] then Remotes.PurchaseRod:InvokeServer(rods[selectedRod]) Notify("Shop", "Buying "..selectedRod, 2) end end })

local baits = { ["TopWater Bait"]=10, ["Lucky Bait"]=2, ["Midnight Bait"]=3, ["Chroma Bait"]=6, ["Dark Mater Bait"]=8, ["Corrupt Bait"]=15, ["Aether Bait"]=16, ["Floral Bait"]=20 }
local baitNames = {} for k,_ in pairs(baits) do table.insert(baitNames, k) end
local selectedBait = baitNames[1]
Tab5:Section({ Title = "Buy Baits", Icon = "compass" })
Tab5:Dropdown({ Title = "Select Bait", Values = baitNames, Callback = function(v) selectedBait = v end })
Tab5:Button({ Title = "Buy Bait", Callback = function() if Remotes.PurchaseBait and baits[selectedBait] then Remotes.PurchaseBait:InvokeServer(baits[selectedBait]) Notify("Shop", "Buying "..selectedBait, 2) end end })

local weathers = { ["Wind"]="Wind", ["Snow"]="Snow", ["Cloudy"]="Cloudy", ["Storm"]="Storm", ["Radiant"]="Radiant", ["Shark Hunt"]="Shark Hunt" }
local weatherNames = {} for k,_ in pairs(weathers) do table.insert(weatherNames, k) end
_G.SelectedWeathers = {}
_G.AutoBuyWeather = false
_G.WeatherDelay = 600
Tab5:Section({ Title = "Buy Weather", Icon = "cloud" })
Tab5:Dropdown({ Title = "Select Weather (Max 3)", Values = weatherNames, Multi = true, Callback = function(v) _G.SelectedWeathers = v end })
Tab5:Input({ Title = "Re-Buy Delay (s)", Default = "600", Callback = function(v) _G.WeatherDelay = tonumber(v) or 600 end })
Tab5:Toggle({ Title = "Auto Buy Weather", Callback = function(v) _G.AutoBuyWeather = v if v then task.spawn(function() while _G.AutoBuyWeather do for _, name in pairs(_G.SelectedWeathers) do if Remotes.PurchaseWeather and weathers[name] then Remotes.PurchaseWeather:InvokeServer(weathers[name]) Notify("Weather", "Buying "..name, 2) task.wait(1) end end task.wait(_G.WeatherDelay) end end) end end })

--================================================================================--
--/// TAB 6: TELEPORT \\\--
local Tab6 = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local IslandLocations = { ["Ancient Jungle"]=Vector3.new(1518,1,-186), ["Pirate Cove"]=Vector3.new(3172,9,3541), ["Coral Refs"]=Vector3.new(-2855,47,1996), ["Enchant Room"]=Vector3.new(3221,-1303,1406) }
local IslandKeys = {} for k,_ in pairs(IslandLocations) do table.insert(IslandKeys, k) end
Tab6:Dropdown({ Title = "Select Island", Values = IslandKeys, Callback = function(v) local hrp = getChar():FindFirstChild("HumanoidRootPart") if hrp then hrp.CFrame = CFrame.new(IslandLocations[v]) end end })

Tab6:Section({ Title = "Event Auto Teleport", Icon = "calendar" })
local eventData = {
	["Worm Hunt"] = {Locations={Vector3.new(2190,-1,97), Vector3.new(-2450,-1,139)}, Y=107, Priority=1},
	["Megalodon"] = {Locations={Vector3.new(-1076,-1,1676), Vector3.new(-1191,-1,3597)}, Y=107, Priority=2},
    ["Shark Hunt"] = {Locations={Vector3.new(1,-1,2095), Vector3.new(1369,-1,930)}, Y=107, Priority=3}
}
local eventNames = {"Worm Hunt", "Megalodon", "Shark Hunt"}
_G.AutoEventTP = false
_G.SelectedEvents = {}

local function createPlatform(pos, y)
    local p = Instance.new("Part", Workspace)
    p.Size = Vector3.new(10,1,10)
    p.Position = Vector3.new(pos.X, y, pos.Z)
    p.Anchored = true
    p.Name = "XenonPlatform"
    return p
end

Tab6:Dropdown({ Title = "Select Events", Values = eventNames, Multi = true, Callback = function(v) _G.SelectedEvents = v end })
Tab6:Toggle({ 
    Title = "Auto Event TP", 
    Callback = function(v) 
        _G.AutoEventTP = v 
        if v then
            Notify("Event", "Waiting for event...", 3)
            task.spawn(function()
                while _G.AutoEventTP do
                    -- Logic simple event check
                    task.wait(1)
                end
            end)
        end 
    end 
})

--================================================================================--
--/// TAB 7: EXTRA (GIFTS ADDED) \\\--
local Tab7 = Window:Tab({ Title = "Extra", Icon = "star" })

local GiftingController = require(RS.Controllers.GiftingController)
Tab7:Section({ Title = "Free Gifts", Icon = "gift" })
Tab7:Button({ Title = "Gift Holy Trident", Callback = function() if GiftingController then GiftingController:Open("Holy Trident") Notify("Gift", "Attempted", 2) end end })
Tab7:Button({ Title = "Gift Ethereal Sword", Callback = function() if GiftingController then GiftingController:Open("Ethereal Sword") Notify("Gift", "Attempted", 2) end end })
Tab7:Button({ Title = "Gift Crescendo Scythe", Callback = function() if GiftingController then GiftingController:Open("Crescendo Scythe") Notify("Gift", "Attempted", 2) end end })

-- PANEL CHECK
local function CreateXenonPanel()
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "XenonMiniPanelV2"
    gui.Enabled = false
    
    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 200, 0, 60)
    main.Position = UDim2.new(0.5, -100, 0.9, -70)
    main.BackgroundColor3 = Color3.fromRGB(10,10,10)
    main.BorderSizePixel = 0
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
    
    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 1.2
    local grad = Instance.new("UIGradient", stroke)
    grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0,255,180)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,150,255))}
    
    local stats = Instance.new("TextLabel", main)
    stats.Size = UDim2.new(1,0,1,0)
    stats.BackgroundTransparency = 1
    stats.TextColor3 = Color3.new(1,1,1)
    stats.Font = Enum.Font.GothamBold
    stats.TextSize = 14
    stats.Text = "Waiting..."
    
    task.spawn(function()
        while gui.Parent do
            local fps = math.floor(workspace:GetRealPhysicsFPS())
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            stats.Text = string.format("FPS: %d  |  Ping: %dms", fps, ping)
            task.wait(1)
        end
    end)
    return gui
end
local XenonPanel = CreateXenonPanel()
Tab7:Toggle({ 
    Title = "Panel Check", 
    Callback = function(v) 
        XenonPanel.Enabled = v 
    end 
})

-- WEBHOOK SYSTEM
local knownUUIDs = {}
_G.WebhookRarities = {}
Tab7:Section({ Title = "Webhook", Icon = "camera" })

Tab7:Input({ 
    Title = "Webhook URL", 
    Callback = function(v) 
        _G.WebhookURL = v 
    end 
})

Tab7:Dropdown({ 
    Title = "Rarity Filter", 
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}, 
    Multi = true, 
    Callback = function(v) 
        _G.WebhookRarities = v 
    end 
})

Tab7:Toggle({ 
    Title = "Send Webhook (New Fish)", 
    Callback = function(state) 
        _G.DetectNewFishActive = state 
        if state then 
            task.spawn(function() 
                while _G.DetectNewFishActive do 
                    -- Cek Inventory dengan aman
                    local success, inv = pcall(function() return DataService:GetExpect({"Inventory", "Items"}) end)
                    if success and inv then
                        for _, item in pairs(inv) do 
                            local info = ItemUtility.GetItemDataFromItemType("Items", item.Id) 
                            if info and info.Data.Type == "Fish" and not knownUUIDs[item.UUID] then 
                                knownUUIDs[item.UUID] = true 
                                
                                -- Filter Rarity
                                local rarity = tierToRarity[info.Data.Tier]
                                local passFilter = false
                                if _G.WebhookRarities and #_G.WebhookRarities > 0 then
                                    for _, r in pairs(_G.WebhookRarities) do
                                        if r == rarity then passFilter = true break end
                                    end
                                else
                                    passFilter = true -- Kalo gak pilih filter, kirim semua
                                end

                                if passFilter and _G.WebhookURL and string.find(_G.WebhookURL, "http") then 
                                    local data = { 
                                        embeds = {{ 
                                            title = "Xenon Catch: " .. info.Data.Name, 
                                            description = "Rarity: " .. rarity .. "\nWeight: " .. (item.Weight or "N/A"), 
                                            color = 65280,
                                            footer = { text = "Xenon Hub V7" }
                                        }} 
                                    } 
                                    -- Pakai pcall biar gak crash kalo http error
                                    pcall(function()
                                        request({
                                            Url = _G.WebhookURL, 
                                            Method = "POST", 
                                            Headers = {["Content-Type"]="application/json"}, 
                                            Body = HttpService:JSONEncode(data)
                                        })
                                    end)
                                end 
                            end 
                        end 
                    end
                    task.wait(3) 
                end 
            end) 
        end 
    end 
})

--================================================================================--
--/// TAB 8: SETTINGS (FULL OPTIMIZATION) \\\--
local Tab8 = Window:Tab({ Title = "Settings", Icon = "settings" })

-- UTILITY / OPTIMIZATION
Tab8:Section({ Title = "Optimization", Icon = "zap" })

-- BLACK SCREEN (AFK MODE) - FIX GUI
Tab8:Toggle({
    Title = "Black Screen (AFK)",
    Callback = function(state)
        if state then
            if CoreGui:FindFirstChild("XenonBlackScreen") then return end -- Jangan double
            local sg = Instance.new("ScreenGui", CoreGui)
            sg.Name = "XenonBlackScreen"
            sg.IgnoreGuiInset = true
            sg.ResetOnSpawn = false
            
            local fr = Instance.new("Frame", sg)
            fr.Size = UDim2.new(1,0,1,0)
            fr.BackgroundColor3 = Color3.new(0,0,0)
            fr.BorderSizePixel = 0
            
            local txt = Instance.new("TextLabel", fr)
            txt.Text = "XENON HUB AFK MODE\n(Screen Disabled to Save CPU)"
            txt.Size = UDim2.new(1,0,1,0)
            txt.TextColor3 = Color3.fromRGB(0,255,120)
            txt.TextSize = 24
            txt.Font = Enum.Font.GothamBold
            txt.BackgroundTransparency = 1
            
            -- Matikan Rendering 3D (Opsional, extreme mode)
            RunService:Set3dRenderingEnabled(false)
        else
            if CoreGui:FindFirstChild("XenonBlackScreen") then
                CoreGui.XenonBlackScreen:Destroy()
            end
            RunService:Set3dRenderingEnabled(true)
        end
    end
})

-- NO ANIMATION - FIX ERROR HUMANOID
Tab8:Toggle({
    Title = "No Animation",
    Callback = function(state)
        local hum = getHum()
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator and state then
                for _, t in pairs(animator:GetPlayingAnimationTracks()) do 
                    t:Stop() 
                end
            end
        end
    end
})

-- DISABLE NOTIFY - FIX INFINITE YIELD
Tab8:Toggle({
    Title = "Disable Notify",
    Callback = function(state)
        local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
        if pg then
            -- Cek dulu apakah ada, kalau gak ada gak usah error
            if pg:FindFirstChild("Small Notification") then
                pg["Small Notification"].Enabled = not state
            end
        end
    end
})

-- SERVER UTILS
Tab8:Section({ Title = "Server", Icon = "server" })

Tab8:Button({
    Title = "Rejoin Server",
    Callback = function()
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end
})

Tab8:Button({
    Title = "Server Hop (Low Player)",
    Callback = function()
        local function Hop()
            local servers = {}
            local req = request({Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"})
            local body = HttpService:JSONDecode(req.Body)
            
            if body and body.data then
                for _, s in pairs(body.data) do
                    if type(s) == "table" and s.playing < s.maxPlayers and s.id ~= game.JobId then
                        table.insert(servers, s.id)
                    end
                end
            end
            
            if #servers > 0 then
                Notify("Server", "Hopping to server...", 3)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
            else
                Notify("Server", "No better server found!", 3)
            end
        end
        
        pcall(Hop)
    end
})

-- CONFIG SYSTEM
Tab8:Section({ Title = "Config Data", Icon = "folder-open" })

local ConfigFolder = "XENON_FISHIT/Configs"
if not isfolder("XENON_FISHIT") then makefolder("XENON_FISHIT") end
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
local ConfigName = "default.json"

local function GetConfig()
    local hum = getHum()
    return {
        WalkSpeed = hum and hum.WalkSpeed or 16,
        JumpPower = hum and hum.JumpPower or 50,
        AutoSell = _G.AutoSell,
        AutoFishing = _G.AutoFishing,
        InfiniteJump = _G.InfiniteJump,
        AutoEnchant = _G.AutoEnchant,
        TargetEnchant = _G.TargetEnchant
    }
end

local function ApplyConfig(data)
    local hum = getHum()
    if data.WalkSpeed and hum then hum.WalkSpeed = data.WalkSpeed end
    if data.JumpPower and hum then hum.JumpPower = data.JumpPower end
    if data.AutoSell ~= nil then _G.AutoSell = data.AutoSell end
    if data.InfiniteJump ~= nil then _G.InfiniteJump = data.InfiniteJump end
    if data.TargetEnchant then _G.TargetEnchant = data.TargetEnchant end
end

Tab8:Button({
    Title = "Save Config",
    Callback = function()
        writefile(ConfigFolder.."/"..ConfigName, HttpService:JSONEncode(GetConfig()))
        Notify("Config", "Saved!", 2)
    end
})

Tab8:Button({
    Title = "Load Config",
    Callback = function()
        if isfile(ConfigFolder.."/"..ConfigName) then
            local data = HttpService:JSONDecode(readfile(ConfigFolder.."/"..ConfigName))
            ApplyConfig(data)
            Notify("Config", "Loaded!", 2)
        end
    end
})

--================================================================================--
--/// TAB 9: OTHERS (SCRIPTS) \\\--
local Tab9 = Window:Tab({ Title = "Others", Icon = "file-code" })

Tab9:Button({
    Title = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/DarkNetworks/Infinite-Yield/main/latest.lua'))()
    end
})

Tab9:Button({
    Title = "Fly GUI",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
    end
})

Tab9:Button({
    Title = "Simple Shader",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/p0e1/1/refs/heads/main/SimpleShader.lua"))()
    end
})
