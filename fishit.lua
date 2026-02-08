getgenv().LPH_NO_VIRTUALIZE = function(f) return f end
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local queue_on_teleport = queue_on_teleport or syn.queue_on_teleport

--/// 1. SERVICES \\\--
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")
local LocalPlayer      = Players.LocalPlayer

-- Global State & Config Defaults
_G.AutoFish = false
_G.DelaySpeed = 0.5 -- Default Delay
_G.AutoSell = false
_G.SellDelay = 30
_G.AutoEnchant = false
_G.TargetEnchant = "Big Hunter 1"
_G.WebhookURL = ""
_G.CustomSpeed = 16
_G.CustomJump = 50
_G.InfJump = false
_G.Noclip = false

local GlobalData = { 
    Loaded = false, 
    Remotes = {}, 
    Dependencies = {} 
}

-- Safe GUI Parent
local function getUI()
    return (getgenv().gethui and getgenv().gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
end

--/// 2. LOAD UI LIBRARY \\\--
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not success or not WindUI then
    game.StarterGui:SetCore("SendNotification", {
        Title = "XENON ERROR";
        Text = "Gagal download UI Library. Cek koneksi!";
        Duration = 10;
    })
    return
end

--/// 3. NOTIFICATION SYSTEM \\\--
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "XenonNotifs"
NotifGui.Parent = getUI()
NotifGui.ResetOnSpawn = false

local NotifContainer = Instance.new("Frame", NotifGui)
NotifContainer.Name = "Container"
NotifContainer.Position = UDim2.new(0.02, 0, 0.3, 0)
NotifContainer.Size = UDim2.new(0, 300, 0.6, 0)
NotifContainer.BackgroundTransparency = 1

local UIList = Instance.new("UIListLayout", NotifContainer)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)
UIList.VerticalAlignment = Enum.VerticalAlignment.Bottom

function Notify(Title, Text, Duration)
    task.spawn(function()
        local Frame = Instance.new("Frame", NotifContainer)
        Frame.Name = "Notif"
        Frame.Size = UDim2.new(0, 0, 0, 35)
        Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        Frame.BorderSizePixel = 0
        Frame.ClipsDescendants = true
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)
        local Stroke = Instance.new("UIStroke", Frame)
        Stroke.Thickness = 1.2
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        local Gradient = Instance.new("UIGradient", Stroke)
        Gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 180)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))}
        local Label = Instance.new("TextLabel", Frame)
        Label.Size = UDim2.new(1, -10, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = string.format("<b><font color='rgb(0,255,180)'>%s</font></b> | %s", Title, Text)
        Label.RichText = true
        Label.TextColor3 = Color3.new(1,1,1)
        Label.TextSize = 13
        Label.Font = Enum.Font.GothamMedium
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextTransparency = 1
        Frame:TweenSize(UDim2.new(0, 260, 0, 35), "Out", "Back", 0.4, true)
        TweenService:Create(Label, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
        task.wait(Duration or 3)
        if Frame then
            Frame:TweenSize(UDim2.new(0, 0, 0, 35), "In", "Quad", 0.3, true)
            task.wait(0.3)
            Frame:Destroy()
        end
    end)
end

--/// 4. WINDOW & DATA LOADER \\\--
local Window = WindUI:CreateWindow({
    Title = "XENON HUB",
    Icon = "rbxassetid://130982330871305",
    Author = "Hann 25 | Fish It",
    Folder = "XENON_FISHIT",
    Size = UDim2.fromOffset(280, 350),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
    User = { Enabled = true, Anonymous = true },
})

Window:EditOpenButton({Enabled = false})

local ScreenGui = Instance.new("ScreenGui", getUI())
ScreenGui.Name = "XenonGUI"
ScreenGui.ResetOnSpawn = false
local ButtonResize = Instance.new("ImageButton", ScreenGui)
ButtonResize.Size = UDim2.new(0, 45, 0, 45)
ButtonResize.Position = UDim2.new(0.1, 0, 0.1, 0)
ButtonResize.BackgroundColor3 = Color3.fromRGB(10,10,10)
ButtonResize.Image = "rbxassetid://130982330871305"
ButtonResize.Draggable = true
Instance.new("UICorner", ButtonResize).CornerRadius = UDim.new(0,10)
local btnStroke = Instance.new("UIStroke", ButtonResize)
btnStroke.Thickness = 1.3
btnStroke.Color = Color3.fromRGB(0, 255, 120)
local windowVisible = true
ButtonResize.MouseButton1Click:Connect(function()
    if windowVisible then Window:Close() else Window:Open() end
    windowVisible = not windowVisible
end)

-- Loader Script
task.spawn(function()
    Notify("Loader", "Injecting dependencies...", 2)
    local s, e = pcall(function()
        GlobalData.Dependencies.ItemUtility = require(RS.Shared.ItemUtility)
        GlobalData.Dependencies.Replion = require(RS.Packages.Replion)
        GlobalData.Dependencies.DataService = GlobalData.Dependencies.Replion.Client:WaitReplion("Data")
    end)
    
    local net = nil
    if RS.Packages:FindFirstChild("_Index") then
        for _, child in ipairs(RS.Packages._Index:GetChildren()) do
            if string.find(child.Name, "sleitnick_net") then net = child.net break end
        end
    end
    
    if net then
        GlobalData.Remotes = {
            Charge = net:FindFirstChild("RF/ChargeFishingRod"),
            Start = net:FindFirstChild("RF/RequestFishingMinigameStarted"),
            FinishFunction = net:FindFirstChild("RF/CatchFishCompleted"),
            FinishEvent = net:FindFirstChild("RE/FishingCompleted"),
            EquipRod = net:FindFirstChild("RE/EquipToolFromHotbar"),
            SellAll = net:FindFirstChild("RF/SellAllItems"),
            PurchaseRod = net:FindFirstChild("RF/PurchaseFishingRod"),
            PurchaseBait = net:FindFirstChild("RF/PurchaseBait"),
            PurchaseWeather = net:FindFirstChild("RF/PurchaseWeatherEvent"),
            EquipItem = net:FindFirstChild("RE/EquipItem"),
            ActivateAltar = net:FindFirstChild("RE/ActivateEnchantingAltar"),
            FavoriteItem = net:FindFirstChild("RE/FavoriteItem"),
            ClaimChest = net:FindFirstChild("RE/ClaimPirateChest"),
            SearchItem = net:FindFirstChild("RE/SearchItemPickedUp"),
            Dialogue = net:FindFirstChild("RE/DialogueEnded"),
            Maze = net:FindFirstChild("RE/GainAccessToMaze")
        }
        GlobalData.Loaded = true
        Notify("System", "Ready! Logic Loaded.", 4)
    else
        Notify("Error", "Failed to find Game Remotes!", 10)
    end
end)

local function safeFire(name, ...) if GlobalData.Loaded and GlobalData.Remotes[name] then GlobalData.Remotes[name]:FireServer(...) end end
local function safeInvoke(name, ...) if GlobalData.Loaded and GlobalData.Remotes[name] then return GlobalData.Remotes[name]:InvokeServer(...) end end

--/// 5. CORE LOGIC: NEW INSTANT FISHING V9 \\\--
local function RunInstantFishing()
    task.spawn(function()
        while _G.AutoFish do
            if not GlobalData.Loaded then task.wait(1) continue end
            task.wait(0.1)
            
            local currentTime = tick()
            
            -- 1. Charge Rod (With time argument bypass)
            pcall(function()
                if GlobalData.Remotes.Charge then
                    GlobalData.Remotes.Charge:InvokeServer(nil, nil, currentTime)
                end
            end)
            
            task.wait(0.1) 
            
            -- 2. Start Minigame (Constant Bypass)
            local constantVal = -1.233184814453125
            local randomPower = math.random(80, 95) / 100 
            
            local successStart, _ = pcall(function()
                if GlobalData.Remotes.Start then
                    GlobalData.Remotes.Start:InvokeServer(constantVal, randomPower, tick())
                end
            end)
            
            if successStart then
                -- 3. Humanized Delay (Prevent Kick)
                task.wait(_G.DelaySpeed)
                
                -- 4. Finish / Catch
                pcall(function()
                    if GlobalData.Remotes.FinishFunction then
                        GlobalData.Remotes.FinishFunction:InvokeServer()
                    elseif GlobalData.Remotes.FinishEvent then
                        GlobalData.Remotes.FinishEvent:FireServer()
                    end
                end)
            else
                -- Retry logic if start failed
                task.wait(0.2)
            end
        end
    end)
end

--/// 6. TAB 1: INFORMATION \\\--
local Tab1 = Window:Tab({ Title = "Info", Icon = "info" })
Tab1:Section({ Title = "Status", Icon = "activity" })
Tab1:Paragraph({ Title = "Version", Desc = "XenonHUB (Instant Ready)" })
Tab1:Button({ Title = "Copy Discord", Callback = function() setclipboard("https://discord.gg/MtzH9fttbs") Notify("Discord", "Copied!", 2) end })

--/// 7. TAB 2: FISHING (REMAKED V9 - STRICT UI) \\\--
local Tab2 = Window:Tab({ Title = "Fishing", Icon = "anchor" })

Tab2:Section({ Title = "Instant Fishing", Icon = "zap" })

Tab2:Toggle({
    Title = "Auto Equip Rod",
    Callback = function(v) if v then safeFire("EquipRod", 1) end end
})

-- UI BARU: Checkbox + Input Only (SESUAI REQUEST)
Tab2:Toggle({
    Title = "Auto Fish (Instant)",
    Callback = function(v)
        _G.AutoFish = v
        if v then
            if not GlobalData.Loaded then Notify("Wait", "Game Loading...", 2) end
            RunInstantFishing()
        end
    end
})

Tab2:Input({
    Title = "Delay Speed (Seconds)",
    Placeholder = "Min: 0.1 (Risky) - Safe: 0.5",
    Default = "0.5",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            _G.DelaySpeed = num
            Notify("Config", "Delay set to: " .. num, 1)
        else
            Notify("Error", "Please input valid number!", 2)
        end
    end
})

--/// 8. TAB 3: AUTOMATION \\\--
local Tab3 = Window:Tab({ Title = "Automation", Icon = "cpu" })

-- SELLING
Tab3:Section({ Title = "Selling", Icon = "coins" })
Tab3:Toggle({
    Title = "Auto Sell All",
    Callback = function(v)
        _G.AutoSell = v
        if v then
            task.spawn(function()
                while _G.AutoSell do
                    safeInvoke("SellAll")
                    task.wait(_G.SellDelay)
                end
            end)
        end
    end
})
Tab3:Input({ Title = "Sell Delay (s)", Default = "30", Callback = function(v) _G.SellDelay = tonumber(v) or 30 end })

-- AUTO FAVORITE (RESTORED FROM YOUR CODE)
Tab3:Section({ Title = "Auto Favorite", Icon = "star" })
local favRarities = {}
local autoFav = false
local tierToRarity = {[1]="Uncommon",[2]="Common",[3]="Rare",[4]="Epic",[5]="Legendary",[6]="Mythic",[7]="Secret"}

Tab3:Dropdown({
    Title = "Favorite by Rarity",
    Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
    Multi = true,
    Callback = function(opts) favRarities = opts or {} end
})

Tab3:Toggle({
    Title = "Start Auto Favorite",
    Callback = function(v)
        autoFav = v
        if v then
            task.spawn(function()
                while autoFav do
                    if GlobalData.Dependencies.DataService then
                        local inv = GlobalData.Dependencies.DataService:GetExpect({"Inventory", "Items"})
                        if inv then
                            for _, item in ipairs(inv) do
                                local info = GlobalData.Dependencies.ItemUtility.GetItemDataFromItemType("Items", item.Id)
                                if info and info.Data.Type == "Fish" then
                                    local rarity = tierToRarity[info.Data.Tier]
                                    local isFav = item.Favorited
                                    if not isFav then
                                        for _, r in ipairs(favRarities) do
                                            if r == rarity then
                                                safeFire("FavoriteItem", item.UUID, true)
                                                task.wait(0.1)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    end
})

Tab3:Button({
    Title = "Unfavorite All",
    Callback = function()
        if GlobalData.Dependencies.DataService then
            local inv = GlobalData.Dependencies.DataService:GetExpect({"Inventory", "Items"})
            for _, item in ipairs(inv) do
                if item.Favorited then safeFire("FavoriteItem", item.UUID, false) task.wait(0.05) end
            end
        end
    end
})

-- AUTO ENCHANT
Tab3:Section({ Title = "Enchanting", Icon = "flask-conical" })
local enchantNames = { "Big Hunter 1", "Cursed 1", "Empowered 1", "Glistening 1", "Gold Digger 1", "Leprechaun 1", "Mutation Hunter 1", "Prismatic 1", "Reeler 1", "Stargazer 1", "Stormhunter 1", "XPerienced 1" }
local enchantIdMap = { ["Big Hunter 1"]=3, ["Cursed 1"]=12, ["Empowered 1"]=9, ["Glistening 1"]=1, ["Gold Digger 1"]=4, ["Leprechaun 1"]=5, ["Mutation Hunter 1"]=7, ["Prismatic 1"]=13, ["Reeler 1"]=2, ["Stargazer 1"]=8, ["Stormhunter 1"]=11, ["XPerienced 1"]=10 }
Tab3:Dropdown({ Title = "Target Enchant", Values = enchantNames, Value = enchantNames[1], Callback = function(v) _G.TargetEnchant = v end })

Tab3:Toggle({
    Title = "Auto Enchant",
    Callback = function(v)
        _G.AutoEnchant = v
        if v then
            task.spawn(function()
                while _G.AutoEnchant do
                    if not GlobalData.Dependencies.DataService then task.wait(1) continue end
                    local Data = GlobalData.Dependencies.DataService
                    local ItemUtil = GlobalData.Dependencies.ItemUtility
                    
                    local equipped = Data:Get("EquippedItems") or {}
                    local rods = Data:GetExpect({ "Inventory", "Fishing Rods" }) or {}
                    local currentEnchantID = nil
                    for _, uuid in pairs(equipped) do
                        for _, rod in ipairs(rods) do
                            if rod.UUID == uuid and rod.Metadata then currentEnchantID = rod.Metadata.EnchantId end
                        end
                    end
                    
                    if currentEnchantID == enchantIdMap[_G.TargetEnchant] then
                        Notify("Enchant", "Target Reached!", 5)
                        _G.AutoEnchant = false
                        break
                    end
                    
                    local stoneItem = nil
                    local inv = Data:GetExpect({ "Inventory", "Items" })
                    for _, item in pairs(inv) do
                        local def = ItemUtil:GetItemData(item.Id)
                        if def and def.Data and def.Data.Type == "Enchant Stones" then stoneItem = item break end
                    end
                    
                    if stoneItem then
                        safeFire("EquipItem", stoneItem.UUID, "Enchant Stones")
                        task.wait(0.5)
                        safeFire("EquipRod", 1)
                        task.wait(0.5)
                        safeFire("ActivateAltar")
                        task.wait(4)
                    else
                        Notify("Enchant", "No Stones!", 5)
                        _G.AutoEnchant = false
                        break
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

-- EVENT & MAZE
Tab3:Section({ Title = "Events", Icon = "calendar" })
Tab3:Toggle({
    Title = "Auto Claim Chest",
    Callback = function(v)
        _G.ClaimChest = v
        if v then task.spawn(function() while _G.ClaimChest do safeFire("ClaimChest") task.wait(3) end end) end
    end
})

Tab3:Button({
    Title = "Auto Collect TNT & Maze",
    Callback = function()
        safeFire("Dialogue", "Carpenter", 2, 1)
        task.wait(1)
        for i=1,4 do safeFire("SearchItem", "TNT") task.wait(0.3) end
        task.wait(1)
        safeFire("Maze")
        Notify("Event", "Maze Unlock Attempted", 3)
    end
})

--/// 9. TAB 4: PLAYERS \\\--
local Tab4 = Window:Tab({ Title = "Players", Icon = "user" })
Tab4:Slider({ Title = "Walk Speed", Value = {Min=16, Max=100, Default=16}, Callback = function(v) 
    _G.CustomSpeed = v 
    if LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = v end 
end })
Tab4:Slider({ Title = "Jump Power", Value = {Min=50, Max=500, Default=50}, Callback = function(v) 
    _G.CustomJump = v 
    if LocalPlayer.Character then LocalPlayer.Character.Humanoid.UseJumpPower=true LocalPlayer.Character.Humanoid.JumpPower=v end 
end })
Tab4:Toggle({ Title = "Infinite Jump", Callback = function(v) _G.InfJump = v end })
UserInputService.JumpRequest:Connect(function() 
    if _G.InfJump and LocalPlayer.Character then 
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
    end 
end)

-- HIDE IDENTITY
Tab4:Section({ Title = "Privacy", Icon = "eye-off" })
_G.FakeName = "XenonHUB"
Tab4:Input({ Title = "Fake Name", Placeholder = "Name", Callback = function(v) _G.FakeName = v end })
Tab4:Toggle({ Title = "Hide Identity", Callback = function(v)
    _G.HideID = v
    if v then
        task.spawn(function()
            while _G.HideID do
                pcall(function() LocalPlayer.Character.HumanoidRootPart.Overhead.Content.Header.Text = _G.FakeName end)
                task.wait(1)
            end
        end)
    end
end})

--/// 10. TAB 5: SHOP (AUTO BUY) \\\--
local Tab5 = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
-- RODS
local rods = { ["Luck Rod"]=79, ["Carbon Rod"]=76, ["Grass Rod"]=85, ["Demascus Rod"]=77, ["Ice Rod"]=78, ["Lucky Rod"]=4, ["Midnight Rod"]=80, ["Steampunk Rod"]=6, ["Chrome Rod"]=7, ["Astral Rod"]=5, ["Ares Rod"]=126, ["Angler Rod"]=168, ["Bamboo Rod"]=258 }
local rodNames = {} for k,_ in pairs(rods) do table.insert(rodNames, k) end
local selRod = rodNames[1]
Tab5:Dropdown({ Title = "Select Rod", Values = rodNames, Callback = function(v) selRod = v end })
Tab5:Button({ Title = "Buy Rod", Callback = function() if rods[selRod] then safeInvoke("PurchaseRod", rods[selRod]) Notify("Shop", "Purchased!", 2) end end })

-- BAITS
local baits = { ["TopWater Bait"]=10, ["Lucky Bait"]=2, ["Midnight Bait"]=3, ["Chroma Bait"]=6, ["Dark Mater Bait"]=8, ["Corrupt Bait"]=15, ["Aether Bait"]=16, ["Floral Bait"]=20 }
local baitNames = {} for k,_ in pairs(baits) do table.insert(baitNames, k) end
local selBait = baitNames[1]
Tab5:Dropdown({ Title = "Select Bait", Values = baitNames, Callback = function(v) selBait = v end })
Tab5:Button({ Title = "Buy Bait", Callback = function() if baits[selBait] then safeInvoke("PurchaseBait", baits[selBait]) Notify("Shop", "Purchased!", 2) end end })

-- WEATHER
local weatherKeyMap = {["Wind"] = "Wind", ["Snow"] = "Snow", ["Cloudy"] = "Cloudy", ["Storm"] = "Storm", ["Radiant"] = "Radiant", ["Shark Hunt"] = "Shark Hunt"}
local weatherNames = {"Wind", "Snow", "Cloudy", "Storm", "Radiant", "Shark Hunt"}
local selWeathers = {}
local autoBuyWeather = false
Tab5:Dropdown({ Title = "Select Weather", Values = weatherNames, Multi = true, Callback = function(v) selWeathers = v end })
Tab5:Toggle({ Title = "Auto Buy Weather", Callback = function(v)
    autoBuyWeather = v
    if v then
        task.spawn(function()
            while autoBuyWeather do
                for _, name in ipairs(selWeathers) do
                    safeInvoke("PurchaseWeather", name)
                end
                task.wait(600)
            end
        end)
    end
end })

--/// 11. TAB 6: TELEPORT \\\--
local Tab6 = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local IslandLocations = {
    ["Ancient Jungle"] = Vector3.new(1518, 1, -186), ["Coral Refs"] = Vector3.new(-2855, 47, 1996),
    ["Crater Island"] = Vector3.new(997, 1, 5012), ["Crystal Cavern"] = Vector3.new(-1841, -456, 7186),
    ["Enchant Room"] = Vector3.new(3221, -1303, 1406), ["Pirate Cove"] = Vector3.new(3172, 9, 3541),
    ["Volcano"] = Vector3.new(-588, 48, 212), ["Tropical Grove"] = Vector3.new(-2091, 6, 3703)
}
local IslandKeys = {} for k,_ in pairs(IslandLocations) do table.insert(IslandKeys, k) end
Tab6:Dropdown({ Title = "Island", Values = IslandKeys, Callback = function(v) if LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(IslandLocations[v]) end end })

local FishingLocations = {
    ["Actient Ruin"] = Vector3.new(6046, -588, 4608), ["Leviathan"] = Vector3.new(3474, -287, 3470),
    ["Treasure Room"] = Vector3.new(-3600, -267, -1575), ["Deep Ocean"] = Vector3.new(2135, -92, -695)
}
local FishKeys = {} for k,_ in pairs(FishingLocations) do table.insert(FishKeys, k) end
Tab6:Dropdown({ Title = "Spots", Values = FishKeys, Callback = function(v) if LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(FishingLocations[v]) end end })

-- PLAYER TELEPORT
local function GetPlayerList()
    local list = {} for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer then table.insert(list, plr.Name) end end return list
end
local selPlayer = nil
local plrDrop = Tab6:Dropdown({ Title = "Select Player", Values = GetPlayerList(), Callback = function(v) selPlayer = v end })
Tab6:Button({ Title = "Teleport", Callback = function() 
    local t = Players:FindFirstChild(selPlayer)
    if t and t.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame end 
end })
Tab6:Button({ Title = "Refresh List", Callback = function() plrDrop:Refresh(GetPlayerList()) end })

--/// 12. TAB 7: EXTRA \\\--
local Tab7 = Window:Tab({ Title = "Extra", Icon = "star" })
Tab7:Button({ Title = "Unlock Holy Trident", Callback = function()
    local GC = GlobalData.Dependencies.Replion and require(RS.Controllers.GiftingController)
    if GC then GC:Open("Holy Trindent") Notify("Gift", "Sent!", 2) end
end })
Tab7:Input({ Title = "Webhook URL", Callback = function(v) _G.WebhookURL = v end })
Tab7:Toggle({ Title = "Webhook Catch", Callback = function(v)
    _G.WebhookActive = v
    if v then
        local processed = {}
        task.spawn(function()
            while _G.WebhookActive do
                if GlobalData.Dependencies.DataService then
                    local inv = GlobalData.Dependencies.DataService:GetExpect({"Inventory", "Items"})
                    for _, item in pairs(inv) do
                        if not processed[item.UUID] then
                            local info = GlobalData.Dependencies.ItemUtility.GetItemDataFromItemType("Items", item.Id)
                            if info and info.Data.Type == "Fish" then
                                processed[item.UUID] = true
                                if _G.WebhookURL ~= "" then
                                    local data = { embeds = {{ title = "XenonHUB: " .. info.Data.Name, color = 65280 }} }
                                    request({ Url = _G.WebhookURL, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = HttpService:JSONEncode(data) })
                                end
                            end
                        end
                    end
                end
                task.wait(3)
            end
        end)
    end
end })

Tab7:Toggle({
    Title = "FPS & Ping Panel",
    Callback = function(v)
        if v then
            local p = Instance.new("ScreenGui", getUI())
            p.Name = "XenonStats"
            local f = Instance.new("TextLabel", p)
            f.Size = UDim2.new(0, 200, 0, 50)
            f.Position = UDim2.new(0.5, -100, 0.9, 0)
            f.BackgroundTransparency = 0.5
            f.BackgroundColor3 = Color3.new(0,0,0)
            f.TextColor3 = Color3.new(1,1,1)
            task.spawn(function()
                while p.Parent do
                    f.Text = "FPS: "..math.floor(Workspace:GetRealPhysicsFPS()).." | Ping: "..math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()).."ms"
                    task.wait(1)
                end
            end)
        else
            if getUI():FindFirstChild("XenonStats") then getUI().XenonStats:Destroy() end
        end
    end
})

--/// 13. TAB 8: SETTINGS \\\--
local Tab8 = Window:Tab({ Title = "Settings", Icon = "settings" })
Tab8:Button({ Title = "Server Hop", Callback = function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
    for _, s in ipairs(servers) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            break
        end
    end
end })

local ConfigFile = "Xenon_Config.json"
Tab8:Button({ Title = "Save Config", Callback = function()
    local data = { DelaySpeed = _G.DelaySpeed, AutoSell = _G.AutoSell, TargetEnchant = _G.TargetEnchant }
    writefile(ConfigFile, HttpService:JSONEncode(data))
    Notify("Config", "Saved!", 2)
end })

Tab8:Button({ Title = "Load Config", Callback = function()
    if isfile(ConfigFile) then
        local data = HttpService:JSONDecode(readfile(ConfigFile))
        _G.DelaySpeed = data.DelaySpeed or 0.5
        _G.TargetEnchant = data.TargetEnchant
        Notify("Config", "Loaded!", 2)
    end
end })

--/// 14. TAB 9: OTHERS \\\--
local Tab9 = Window:Tab({ Title = "Others", Icon = "code" })
Tab9:Button({ Title = "Infinite Yield", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/DarkNetworks/Infinite-Yield/main/latest.lua'))() end })
Tab9:Button({ Title = "Fly GUI V3", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))() end })

Notify("System", "XenonHUB FULL LOADED!", 5)
