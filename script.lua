local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "⚔️ Kaiju Alpha Script | Farm Beta",
   LoadingTitle = "G-Cells Farm Edition",
   LoadingSubtitle = "Loading...",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("Duo Farm", 4483362458)

local sharedRole = "Игрок 1 (Кому помогают)"
local sharedTarget = ""
local farmActive = false
local farmPosition = nil

-- === НАДЕЖНЫЙ ПОИСК ПЕРСОНАЖА ===
local function getCharacter(playerName)
    local workspace = game:GetService("Workspace")
    local liveFolder = workspace:FindFirstChild("Live")
    
    if liveFolder then
        local char = liveFolder:FindFirstChild(playerName)
        if char then return char end
    end
    
    local p = Players:FindFirstChild(playerName)
    return p and p.Character
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
    if not guiObject or not guiObject:IsA("GuiButton") then return end
    
    if firesignal then
        firesignal(guiObject.MouseButton1Click)
    else
        local absPos = guiObject.AbsolutePosition
        local absSize = guiObject.AbsoluteSize
        local centerX = absPos.X + absSize.X / 2
        local centerY = absPos.Y + absSize.Y / 2 + 36
        
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
    end
end

Tab:CreateParagraph({Title = "ℹ️ Инструкция Игрок 1", Content = "Включи тумблер. Ты улетишь на платформу. Авто-удары начнутся автоматически, как только Игрок 2 долетит до тебя."})
Tab:CreateParagraph({Title = "ℹ️ Инструкция Игрок 2", Content = "Введи ник Игрока 1. ВНИМАНИЕ: Начинай фарм строго находясь в меню выбора карты! Скрипт сам нажмет кнопку Спавна, подождет 2 секунды и полетит."})

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

Tab:CreateInput({
   Name = "Ник Игрока 1",
   PlaceholderText = "Введи точный ник...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      sharedTarget = Text
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
                    local char1 = nil
                    while farmActive and not char1 do
                        char1 = getCharacter(LocalPlayer.Name)
                        task.wait(0.1)
                    end
                    
                    local pHrp = char1:WaitForChild("HumanoidRootPart", 5)
                    if not pHrp then return end
                    
                    -- Лифт для Игрока 1 при старте
                    local startPos = pHrp.Position
                    local endPos = pos + Vector3.new(0, 4, 0)
                    local duration = 1.5 
                    local startClock = os.clock()
                    
                    while farmActive and (os.clock() - startClock) < duration do
                        local t = (os.clock() - startClock) / duration
                        char1 = getCharacter(LocalPlayer.Name)
                        pHrp = char1 and char1:FindFirstChild("HumanoidRootPart")
                        
                        if pHrp then
                            pHrp.Velocity = Vector3.new(0, 0, 0)
                            pHrp.CFrame = CFrame.new(startPos:Lerp(endPos, t))
                        end
                        task.wait(0.01)
                    end
                    
                    -- Основной цикл Игрока 1
                    while farmActive do
                        char1 = getCharacter(LocalPlayer.Name)
                        pHrp = char1 and char1:FindFirstChild("HumanoidRootPart")
                        
                        if pHrp and pHrp.Parent then
                            pHrp.Velocity = Vector3.new(0, 0, 0)
                            pHrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
                            
                            -- ПРОВЕРКА: Находится ли Игрок 2 на платформе?
                            local targetChar = getCharacter(sharedTarget)
                            local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                            local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
                            
                            local targetIsReady = false
                            if targetHrp and targetHum and targetHum.Health > 0 then
                                -- Проверяем высоту (Y > 4950) и дистанцию до центра нашей платформы
                                if targetHrp.Position.Y > 4950 and (targetHrp.Position - pos).Magnitude < 40 then
                                    targetIsReady = true
                                end
                            end
                            
                            -- Бьем только тогда, когда цель доехала и жива
                            if targetIsReady then
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                task.wait(0.02)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                            end
                        end
                        task.wait(0.05)
                    end
                end)

            elseif sharedRole == "Игрок 2 (Кто помогает)" then
                if sharedTarget == "" then
                    FarmToggle:Set(false)
                    Rayfield:Notify({
                       Title = "Ошибка логики",
                       Content = "Ты не указал ник Игрока 1!",
                       Duration = 4,
                       Image = 4483362458,
                    })
                    return
                end

                task.spawn(function()
                    while farmActive do
                        local myChar = getCharacter(LocalPlayer.Name)
                        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        
                        -- Если мы заспавнились в мире и живы
                        if myChar and hum and hum.Health > 0 and myHrp then
                            
                            local startPos = myHrp.Position
                            local endPos = pos + Vector3.new(0, 4, 0)
                            local duration = 2.0 
                            local startClock = os.clock()
                            
                            -- ЕДЕМ НА ПЛАТФОРМУ
                            while farmActive and (os.clock() - startClock) < duration and hum.Health > 0 do
                                local t = (os.clock() - startClock) / duration
                                myChar = getCharacter(LocalPlayer.Name)
                                myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                                hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                                
                                if myHrp and hum and hum.Health > 0 then
                                    myHrp.Velocity = Vector3.new(0, 0, 0)
                                    myHrp.CFrame = CFrame.new(startPos:Lerp(endPos, t))
                                end
                                task.wait(0.01)
                            end
                            
                            -- СТОИМ НА ПЛАТФОРМЕ И ЖДЕМ СМЕРТИ И ОТДАЕМ КЛЕТКИ
                            while farmActive and hum and hum.Health > 0 do
                                myChar = getCharacter(LocalPlayer.Name)
                                myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                                hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                                
                                if myHrp and hum and hum.Health > 0 then
                                    myHrp.Velocity = Vector3.new(0, 0, 0)
                                    myHrp.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                                end
                                task.wait(0.1)
                            end
                        else
                            -- МЫ В МЕНЮ ИЛИ МЕРТВЫ -> ТАРГЕТИРУЕМ КНОПКУ СПАВНА В PLAYERGUI
                            local pg = LocalPlayer:FindFirstChild("PlayerGui")
                            local menu = pg and pg:FindFirstChild("Menu")
                            local mapMenu = menu and menu:FindFirstChild("Map")
                            local btnSpawn = mapMenu and mapMenu:FindFirstChild("Spawn")
                            
                            if btnSpawn then
                                clickUI(btnSpawn)
                                task.wait(2.0) -- Жесткая задержка в 2 секунды после клика по ТЗ
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
