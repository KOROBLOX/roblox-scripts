local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "⚔️ Kaiju Alpha Script | Farm Beta V3",
   LoadingTitle = "G-Cells Radius Farm",
   LoadingSubtitle = "Loading...",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("Duo Farm", 4483362458)

local sharedRole = "Игрок 1 (Кому помогают)"
local farmActive = false
local farmPosition = nil

-- === НАДЕЖНЫЙ ПОИСК СВОЕГО ПЕРСОНАЖА ===
local function getMyCharacter()
    local workspace = game:GetService("Workspace")
    local liveFolder = workspace:FindFirstChild("Live")
    
    if liveFolder then
        local char = liveFolder:FindFirstChild(LocalPlayer.Name)
        if char then return char end
    end
    return LocalPlayer.Character
end

-- === СОЗДАНИЕ ЗОНЫ ОСТАНОВКИ ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KaijuStopZone"
screenGui.ResetOnSpawn = false
local success = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local stopZone = Instance.new("Frame")
stopZone.Size = UDim2.fromOffset(100, 100)
stopZone.Position = UDim2.new(0, 20, 0.5, -50) 
stopZone.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
stopZone.BorderSizePixel = 0
stopZone.Visible = false
stopZone.Parent = screenGui

local stopStroke = Instance.new("UIStroke")
stopStroke.Color = Color3.fromRGB(255, 50, 50)
stopStroke.Thickness = 2
stopStroke.Parent = stopZone

local stopText = Instance.new("TextLabel")
stopText.Size = UDim2.new(1, 0, 1, 0)
stopText.BackgroundTransparency = 1
stopText.TextColor3 = Color3.fromRGB(255, 255, 255)
stopText.TextSize = 14
stopText.Text = "НАВЕДИ\nДЛЯ СТОПА"
stopText.Font = Enum.Font.SourceSansBold
stopText.Parent = stopZone

local hoverActive = false
local hoverThread = nil
local FarmToggle

stopZone.MouseEnter:Connect(function()
    hoverActive = true
    stopZone.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    hoverThread = task.spawn(function()
        for i = 3, 1, -1 do
            if not hoverActive then break end
            stopText.Text = "ОСТАНОВКА\nЧЕРЕЗ " .. i
            task.wait(1)
        end
        if hoverActive then
            stopText.Text = "ОСТАНОВЛЕНО!"
            if FarmToggle then FarmToggle:Set(false) end
        end
    end)
end)

stopZone.MouseLeave:Connect(function()
    hoverActive = false
    stopZone.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    stopText.Text = "НАВЕДИ\nДЛЯ СТОПА"
    if hoverThread then task.cancel(hoverThread) hoverThread = nil end
end)
-- ===============================

local function createFarmPlatform()
    if _G.DuoFarmPlatform and _G.DuoFarmPlatform.Parent then return _G.DuoFarmPlatform.Position end
    
    farmPosition = Vector3.new(0, 5000, 0)
    local plat = Instance.new("Part")
    plat.Name = "KaijuAlpha_Platform"
    plat.Size = Vector3.new(45, 2, 45)
    plat.Position = farmPosition
    plat.Anchored = true
    plat.Parent = game.Workspace
    
    _G.DuoFarmPlatform = plat
    return farmPosition
end

local function clickUI(guiObject)
    if not guiObject then return end
    pcall(function()
        if firesignal then
            firesignal(guiObject.MouseButton1Click)
            firesignal(guiObject.Activated)
        end
    end)
    pcall(function()
        local absPos = guiObject.AbsolutePosition
        local absSize = guiObject.AbsoluteSize
        local centerX = absPos.X + absSize.X / 2
        local centerY = absPos.Y + absSize.Y / 2 + 36
        
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
    end)
end

Tab:CreateParagraph({Title = "ℹ️ Инструкция Игрок 1", Content = "Включи тумблер. Ты улетишь на платформу. Скрипт сканирует воздух вокруг платформы и начнет бить любого, кто на неё встанет."})
Tab:CreateParagraph({Title = "ℹ️ Инструкция Игрок 2", Content = "ВНИМАНИЕ: Начинай фарм строго на экране главного меню! Скрипт по очереди прожмет кнопки Play и Spawn, подождет 2 секунды и полетит на платформу."})

Tab:CreateDropdown({
   Name = "Ваша роль",
   Options = {"Игрок 1 (Кому помогают)", "Игрок 2 (Кто помогает)"},
   CurrentOption = {"Игрок 1 (Кому помогают)"},
   MultipleOptions = false,
   Flag = "RoleDropdown",
   Callback = function(Option)
      sharedRole = Option[1]
   end,
})

FarmToggle = Tab:CreateToggle({
   Name = "💥 ЗАПУСК АВТО ФАРМА G-КЛЕТОК",
   CurrentValue = false,
   Flag = "FarmToggle",
   Callback = function(Value)
        farmActive = Value
        stopZone.Visible = farmActive and (sharedRole == "Игрок 1 (Кому помогают)")

        if farmActive then
            local pos = createFarmPlatform()

            if sharedRole == "Игрок 1 (Кому помогают)" then
                task.spawn(function()
                    while farmActive do
                        local myChar = getMyCharacter()
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        
                        if myHrp and myHrp.Parent then
                            -- Жестко удерживаем Игрока 1 на платформе
                            myHrp.Velocity = Vector3.new(0, 0, 0)
                            myHrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
                            
                            -- ПРОСТРАНСТВЕННОЕ СКАННИРОВАНИЕ ПЛАТФОРМЫ
                            local targetDetected = false
                            local liveFolder = game.Workspace:FindFirstChild("Live")
                            
                            if liveFolder then
                                for _, entity in ipairs(liveFolder:GetChildren()) do
                                    -- Проверяем, что сущность — это не сам Игрок 1
                                    if entity ~= myChar and entity:IsA("Model") then
                                        local entHrp = entity:FindFirstChild("HumanoidRootPart")
                                        local entHum = entity:FindFirstChildOfClass("Humanoid")
                                        
                                        if entHrp and entHum and entHum.Health > 0 then
                                            -- Если объект находится в радиусе 35 блоков от центра платформы
                                            if (entHrp.Position - pos).Magnitude < 35 then
                                                targetDetected = true
                                                break -- Цель найдена, выходим из цикла проверки
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- Если радар засёк кого-то на платформе — бьем
                            if targetDetected then
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                task.wait(0.02)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                            end
                        end
                        task.wait(0.05)
                    end
                end)

            elseif sharedRole == "Игрок 2 (Кто помогает)" then
                task.spawn(function()
                    while farmActive do
                        local myChar = getMyCharacter()
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                        
                        -- Проверяем, долетели ли мы уже до платформы
                        local isOnPlatform = false
                        if myHrp and (myHrp.Position - pos).Magnitude < 50 then
                            isOnPlatform = true
                        end
                        
                        if isOnPlatform and hum and hum.Health > 0 then
                            -- МЫ НА ПЛАТФОРМЕ — СТОИМ И ЖДЕМ ПОКА ИГРОК 1 НАС УБЬЕТ
                            myHrp.Velocity = Vector3.new(0, 0, 0)
                            myHrp.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                            task.wait(0.1)
                        else
                            -- МЫ В МЕНЮ ИЛИ ТОЛЬКО ЧТО РЕСТАРТНУЛИСЬ
                            local pg = LocalPlayer:FindFirstChild("PlayerGui")
                            if pg then
                                local menuFrame = pg:FindFirstChild("Menu")
                                
                                -- ШАГ 1: Кликаем кнопку Play
                                local innerMenu = menuFrame and menuFrame:FindFirstChild("Menu")
                                local btnList = innerMenu and innerMenu:FindFirstChild("ButtonList")
                                local btnPlay = btnList and btnList:FindFirstChild("Play")
                                
                                if btnPlay then
                                    clickUI(btnPlay)
                                    task.wait(0.3)
                                end
                                
                                -- ШАГ 2: Кликаем кнопку Spawn
                                local mapFrame = menuFrame and menuFrame:FindFirstChild("Map")
                                local btnSpawn = mapFrame and mapFrame:FindFirstChild("Spawn")
                                
                                if btnSpawn then
                                    clickUI(btnSpawn)
                                    task.wait(2.0) -- Железное ожидание 2 секунды после спавна перед полётом
                                    
                                    -- ШАГ 3: ЗАПУСКАЕМ СКОЛЬЖЕНИЕ ДО ПЛАТФОРМЫ
                                    myChar = getMyCharacter()
                                    myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                                    hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                                    
                                    if myHrp and hum and hum.Health > 0 then
                                        local startPos = myHrp.Position
                                        local endPos = pos + Vector3.new(0, 4, 0)
                                        local duration = 2.0 
                                        local startClock = os.clock()
                                        
                                        while farmActive and (os.clock() - startClock) < duration and hum.Health > 0 do
                                            local t = (os.clock() - startClock) / duration
                                            myChar = getMyCharacter()
                                            myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                                            hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                                            
                                            if myHrp and hum and hum.Health > 0 then
                                                myHrp.Velocity = Vector3.new(0, 0, 0)
                                                myHrp.CFrame = CFrame.new(startPos:Lerp(endPos, t))
                                            end
                                            task.wait(0.01)
                                        end
                                    end
                                else
                                    task.wait(0.5)
                                end
                            else
                                task.wait(0.5)
                            end
                        end
                        task.wait(0.1)
                    end
                end)
            end
        else
            hoverActive = false
            stopZone.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            stopText.Text = "НАВЕДИ\nДЛЯ СТОПА"
            if hoverThread then task.cancel(hoverThread) hoverThread = nil end
        end
   end,
})
