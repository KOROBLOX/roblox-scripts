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
    if not playerName or playerName == "" then return nil end
    
    -- Ищем по реальному имени или дисплейнейму через Players
    local targetPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == playerName or p.DisplayName == playerName then
            targetPlayer = p
            break
        end
    end
    
    if targetPlayer and targetPlayer.Character then 
        return targetPlayer.Character 
    end
    
    -- Запасной план: прямой перебор папки Live
    local liveFolder = game.Workspace:FindFirstChild("Live")
    if liveFolder then
        local char = liveFolder:FindFirstChild(playerName)
        if char then return char end
    end
    
    return nil
end

-- === ДИНАМИЧЕСКОЕ ОБНОВЛЕНИЕ СПИСКА ИГРОКОВ ===
local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then table.insert(list, "Нет игроков на сервере") end
    return list
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

Tab:CreateParagraph({Title = "ℹ️ Инструкция Игрок 1", Content = "Включи тумблер. Ты улетишь на платформу. Скрипт начнет бить напарника, как только тот окажется в радиусе платформы."})
Tab:CreateParagraph({Title = "ℹ️ Инструкция Игрок 2", Content = "ВНИМАНИЕ: Активируй тумблер на экране главного меню / выбора карты. Скрипт по очереди нажмет кнопки Play и Spawn, подождет 2 секунды и полетит вверх."})

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

local PlayerDropdown = Tab:CreateDropdown({
   Name = "Выбери НАПАРНИКА",
   Options = getPlayerList(),
   CurrentOption = {""},
   MultipleOptions = false,
   Flag = "PartnerDropdown",
   Callback = function(Option)
      sharedTarget = Option[1]
   end,
})

-- Фоновый поток обновления списка игроков раз в 5 секунд
task.spawn(function()
    while true do
        task.wait(5)
        if PlayerDropdown then
            pcall(function()
                PlayerDropdown:Refresh(getPlayerList(), true)
            end)
        end
    end
end)

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
                        local char1 = getCharacter(LocalPlayer.Name)
                        local pHrp = char1 and char1:FindFirstChild("HumanoidRootPart")
                        
                        if pHrp and pHrp.Parent then
                            -- Удерживаем Игрока 1 на платформе
                            pHrp.Velocity = Vector3.new(0, 0, 0)
                            pHrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
                            
                            -- ПРОВЕРКА НАПАРНИКА НА НАХОЖДЕНИЕ РЯДОМ С ПЛАТФОРМОЙ
                            local partnerChar = getCharacter(sharedTarget)
                            local partnerHrp = partnerChar and partnerChar:FindFirstChild("HumanoidRootPart")
                            local partnerHum = partnerChar and partnerChar:FindFirstChildOfClass("Humanoid")
                            
                            local partnerIsNear = false
                            if partnerHrp and partnerHum and partnerHum.Health > 0 then
                                -- Проверяем дистанцию до центра платформы (сфера радиусом 50 студий)
                                if (partnerHrp.Position - pos).Magnitude < 50 then
                                    partnerIsNear = true
                                end
                            end
                            
                            -- Бьем только когда напарник зашел в радиус зоны фарма
                            if partnerIsNear then
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                task.wait(0.02)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                            end
                        end
                        task.wait(0.05)
                    end
                end)

            elseif sharedRole == "Игрок 2 (Кто помогает)" then
                if sharedTarget == "" or sharedTarget == "Нет игроков на сервере" then
                    FarmToggle:Set(false)
                    Rayfield:Notify({
                       Title = "Внимание",
                       Content = "Сначала выбери напарника из списка!",
                       Duration = 4,
                       Image = 4483362458,
                    })
                    return
                end

                task.spawn(function()
                    while farmActive do
                        local myChar = getCharacter(LocalPlayer.Name)
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                        
                        -- Проверяем, находимся ли мы уже на платформе
                        local isOnPlatform = false
                        if myHrp and (myHrp.Position - pos).Magnitude < 55 then
                            isOnPlatform = true
                        end
                        
                        if isOnPlatform and hum and hum.Health > 0 then
                            -- ШАГ 4: МЫ НА ПЛАТФОРМЕ — УДЕРЖИВАЕМ ПОЗИЦИЮ И ЖДЕМ ОБНУЛЕНИЯ ХП
                            myHrp.Velocity = Vector3.new(0, 0, 0)
                            myHrp.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                            task.wait(0.1)
                        else
                            -- МЫ МЕРТВЫ ИЛИ НА ЗЕМЛЕ -> ПРОЖИМАЕМ МЕНЮ ПО НОВОМУ ЦИКЛУ
                            local pg = LocalPlayer:FindFirstChild("PlayerGui")
                            if pg then
                                local menuGui = pg:FindFirstChild("Menu")
                                
                                -- 1. Ищем и нажимаем кнопку PLAY
                                local innerMenu = menuGui and menuGui:FindFirstChild("Menu")
                                local btnList = innerMenu and innerMenu:FindFirstChild("ButtonList")
                                local btnPlay = btnList and btnList:FindFirstChild("Play")
                                if btnPlay then
                                    clickUI(btnPlay)
                                    task.wait(0.5) -- Небольшая пауза для открытия вкладки карты
                                end
                                
                                -- 2. Ищем и нажимаем кнопку SPAWN
                                local mapFrame = menuGui and menuGui:FindFirstChild("Map")
                                local btnSpawn = mapFrame and mapFrame:FindFirstChild("Spawn")
                                if btnSpawn then
                                    clickUI(btnSpawn)
                                    task.wait(2.0) -- Твое жесткое условие: ждем 2 секунды после нажатия кнопки Спавн
                                end
                            end
                            
                            -- 3. СОБИРАЕМ ТЕЛО И ВКЛЮЧАЕМ ЛИФТ НАВЕРХ
                            myChar = getCharacter(LocalPlayer.Name)
                            myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                            
                            if myHrp and hum and hum.Health > 0 then
                                local startPos = myHrp.Position
                                local endPos = pos + Vector3.new(0, 4, 0)
                                local duration = 2.0 
                                local startClock = os.clock()
                                
                                -- Скользим строго на платформу
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
