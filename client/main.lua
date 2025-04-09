local QBCore = exports['qb-core']:GetCoreObject()
local pickpocketingInProgress = false
local cooldownNPCs = {}
local currentPickpocketItems = {}
local isMinigameReset = true
local callingPoliceNPC = nil
local npcOriginalHeadings = {}

local function ResetPickpocketState()
    pickpocketingInProgress = false
    currentPickpocketItems = {}
    SetNuiFocus(false, false)
    ClearPedTasks(PlayerPedId())
    isMinigameReset = true
end

local function IsNearValidNPC()
    local player = PlayerPedId()
    local playerCoords = GetEntityCoords(player)
    
    local closestPed = nil
    local closestDistance = 2.0
    
    local peds = GetGamePool('CPed')
    for _, ped in ipairs(peds) do
        if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, 1) and not IsPedInAnyVehicle(ped, false) then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - pedCoords)
            
            if distance < closestDistance then
                closestPed = ped
                closestDistance = distance
            end
        end
    end
    
    return closestPed
end

local function MakeNPCLookNatural(npcPed, enable)
    if not DoesEntityExist(npcPed) then return end
    
    if enable then
        ClearPedTasksImmediately(npcPed)
        
        npcOriginalHeadings[npcPed] = GetEntityHeading(npcPed)
        
        local gender = IsPedMale(npcPed) and "male" or "female"
        
        local maleScenarios = {
            "WORLD_HUMAN_STAND_MOBILE",
            "WORLD_HUMAN_SMOKING",
            "WORLD_HUMAN_HANG_OUT_STREET",
            "WORLD_HUMAN_STAND_IMPATIENT",
            "WORLD_HUMAN_TOURIST_MAP"
        }
        
        local femaleScenarios = {
            "WORLD_HUMAN_STAND_MOBILE",
            "WORLD_HUMAN_HANG_OUT_STREET",
            "WORLD_HUMAN_STAND_IMPATIENT",
            "WORLD_HUMAN_TOURIST_MAP",
            "WORLD_HUMAN_WINDOW_SHOP"
        }
        
        local scenarios = gender == "male" and maleScenarios or femaleScenarios
        
        local selectedScenario = scenarios[math.random(#scenarios)]
        
        TaskStartScenarioInPlace(npcPed, selectedScenario, 0, true)
        
        SetEntityInvincible(npcPed, true)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
    else
        local originalHeading = npcOriginalHeadings[npcPed]
        if originalHeading then
            SetEntityHeading(npcPed, originalHeading)
            npcOriginalHeadings[npcPed] = nil
        end
        
        SetEntityInvincible(npcPed, false)
        SetBlockingOfNonTemporaryEvents(npcPed, false)
        
        SetTimeout(math.random(500, 1200), function()
            if DoesEntityExist(npcPed) then
                if math.random() > 0.7 then
                    local walkStyles = {"move_m@casual@a", "move_m@casual@b", "move_m@casual@c", "move_m@casual@d"}
                    local randomStyle = walkStyles[math.random(#walkStyles)]
                    
                    RequestAnimSet(randomStyle)
                    while not HasAnimSetLoaded(randomStyle) do
                        Wait(10)
                    end
                    
                    SetPedMovementClipset(npcPed, randomStyle, 0.25)
                    
                    local playerPed = PlayerPedId()
                    local playerCoords = GetEntityCoords(playerPed)
                    local npcCoords = GetEntityCoords(npcPed)
                    local directionVector = vector3(
                        npcCoords.x - playerCoords.x,
                        npcCoords.y - playerCoords.y,
                        0
                    )
                    
                    local length = #directionVector
                    if length > 0 then
                        directionVector = directionVector / length
                    end
                    
                    local distance = math.random(5, 10)
                    local targetCoords = vector3(
                        npcCoords.x + directionVector.x * distance,
                        npcCoords.y + directionVector.y * distance,
                        npcCoords.z
                    )
                    
                    TaskGoStraightToCoord(npcPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, 5000, GetEntityHeading(npcPed), 0.1)
                    
                    SetTimeout(5000, function()
                        if DoesEntityExist(npcPed) then
                            ResetPedMovementClipset(npcPed, 0.25)
                        end
                    end)
                else
                    ClearPedTasks(npcPed)
                end
            end
        end)
    end
end

local function IsNPCOnCooldown(npcNetId)
    return cooldownNPCs[npcNetId] ~= nil
end

local function AddNPCToCooldown(npcNetId)
    cooldownNPCs[npcNetId] = true
    SetTimeout(Config.CooldownTime, function()
        cooldownNPCs[npcNetId] = nil
    end)
end

local function GetRandomPickpocketItems()
    if math.random(1, 100) <= Config.EmptyPocketChance then
        return {}
    end
    
    local items = {}
    local maxItems = math.random(1, 3)
    
    local attempts = 0
    while #items < maxItems and attempts < 10 do
        attempts = attempts + 1
        
        for _, item in ipairs(Config.StealableItems) do
            if math.random(1, 100) <= item.chance then
                local amount = math.random(item.min, item.max)
                local displayValue = item.item == 'cash' 
                    and (item.value .. amount) 
                    or (item.value .. item.label)
                
                table.insert(items, {
                    name = item.item,
                    label = item.label,
                    amount = amount,
                    value = displayValue,
                    chance = item.chance
                })
                
                break
            end
        end
    end
    
    return items
end

function HandleNPCCallingPolice(npcPed)
    if not DoesEntityExist(npcPed) then return end
    
    local npcCoords = GetEntityCoords(npcPed)
    
    ClearPedTasksImmediately(npcPed)
    TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    
    callingPoliceNPC = npcPed
    
    TriggerServerEvent('nc-pickpocket:server:EmoteMessage', npcCoords, 'Someone is calling the police')
    
    QBCore.Functions.Notify(Config.Notifications.NPCCalling, "error")
    
    local callThreadActive = true
    local callTime = Config.NPCCallPoliceTimeout
    
    CreateThread(function()
        local startTime = GetGameTimer()
        
        while callThreadActive and DoesEntityExist(npcPed) and GetGameTimer() - startTime < callTime do
            if not IsPedUsingScenario(npcPed, "WORLD_HUMAN_STAND_MOBILE") then
                TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
            end
            
            local pos = GetEntityCoords(npcPed)
            DrawMarker(
                1,
                pos.x, pos.y, pos.z - 0.95,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.8, 0.8, 0.1,
                255, 0, 0, 80,
                false,
                false,
                2,
                false,
                nil,
                nil,
                false
            )
            
            Wait(0)
        end
        
        if callingPoliceNPC == npcPed then
            callingPoliceNPC = nil
        end
    end)
    
    Wait(callTime)
    callThreadActive = false
    
    if Config.UseQBDispatch then
        if exports['qb-dispatch'] then
            TriggerServerEvent('qb-dispatch:server:SendAlert', {
                name = 'Pickpocket',
                coords = npcCoords,
                description = 'Pickpocket attempt reported',
                dispatchCode = '10-31',
                priority = 2,
                blip = {
                    sprite = 225,
                    scale = 1.0,
                    colour = 1,
                    flashes = true,
                    text = 'Pickpocket',
                    time = 60,
                    radius = 100.0
                }
            })
        else
            TriggerServerEvent('nc-pickpocket:server:NotifyPolice', npcCoords)
        end
    end
    
    if DoesEntityExist(npcPed) then
        if math.random() > 0.5 then
            local playerPed = PlayerPedId()
            TaskReactAndFleePed(npcPed, playerPed)
        else
            ClearPedTasks(npcPed)
        end
    end
end

local function MakeNPCAggressive(npcPed, playerPed)
    if not DoesEntityExist(npcPed) or not DoesEntityExist(playerPed) then return end
    
    ClearPedTasksImmediately(playerPed)
    
    ClearPedTasksImmediately(npcPed)
    
    local weapons = {
        GetHashKey("WEAPON_BAT"),
        GetHashKey("WEAPON_KNUCKLE"),
        GetHashKey("WEAPON_BOTTLE")
    }
    
    local selectedWeapon = weapons[math.random(#weapons)]
    
    if not HasPedGotWeapon(npcPed, selectedWeapon, false) then
        GiveWeaponToPed(npcPed, selectedWeapon, 0, false, true)
    end
    
    SetCurrentPedWeapon(npcPed, selectedWeapon, true)
    
    SetPedCombatAttributes(npcPed, 46, true)
    SetPedCombatAttributes(npcPed, 5, true)
    SetPedCombatAttributes(npcPed, 2, true)
    SetPedCombatAttributes(npcPed, 0, true)
    SetPedCombatAttributes(npcPed, 1, true)
    SetPedCombatAttributes(npcPed, 52, true)
    
    SetPedCombatMovement(npcPed, 3)
    SetPedCombatRange(npcPed, 0)
    
    SetPedMoveRateOverride(npcPed, 2.0)
    
    SetPedRelationshipGroupHash(npcPed, GetHashKey("HATES_PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("HATES_PLAYER"), GetHashKey("PLAYER"))
    
    TaskSetBlockingOfNonTemporaryEvents(npcPed, false)
    SetPedKeepTask(npcPed, true)
    
    RegisterEntityForCutscene(playerPed, 'player', 0, 0, 64)
    
    SetPedRagdollBlockingFlags(npcPed, 1)
    
    TaskAimGunAtEntity(npcPed, playerPed, 1000, false)
    
    TaskGoToEntityWhileAimingAtEntity(npcPed, playerPed, playerPed, 4.0, true, 0.0, 4.0, true, false, 0)
    
    SetTimeout(50, function()
        if DoesEntityExist(npcPed) and DoesEntityExist(playerPed) then
            TaskCombatPed(npcPed, playerPed, 0, 16)
            
            SetPedCombatAbility(npcPed, 100)
            SetPedCombatMovement(npcPed, 3)
            SetPedCombatRange(npcPed, 0)
            
            SetPedKeepTask(npcPed, true)
        end
    end)
    
    QBCore.Functions.Notify(Config.Notifications.NPCNoticed, "error")
end

local continuePickpocketing = false

local function StartPickpocketing(npcPed)
    if pickpocketingInProgress then
        QBCore.Functions.Notify(Config.Notifications.AlreadyPickpocketing, "error")
        return
    end
    
    if not isMinigameReset then
        ResetPickpocketState()
        
        SendNUIMessage({
            action = "forceReset"
        })
        
        Wait(100)
    end
    
    local npcNetId = NetworkGetNetworkIdFromEntity(npcPed)
    
    if IsNPCOnCooldown(npcNetId) then
        QBCore.Functions.Notify(Config.Notifications.CooldownActive, "error")
        return
    end
    
    continuePickpocketing = false
    TriggerServerEvent('nc-pickpocket:server:CheckPoliceCount')
    
    local timeout = 0
    while not continuePickpocketing and timeout < 50 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if timeout >= 50 or not continuePickpocketing then
        QBCore.Functions.Notify(Config.Notifications.NotEnoughPolice, "error")
        return
    end
    
    MakeNPCLookNatural(npcPed, true)
    
    local potentialItems = GetRandomPickpocketItems()
    currentPickpocketItems = potentialItems
    
    pickpocketingInProgress = true
    isMinigameReset = false
    
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
    
    local minigameItems = {}
    for _, item in ipairs(potentialItems) do
        table.insert(minigameItems, {
            name = item.name,
            label = item.label,
            amount = item.amount,
            value = item.value,
            chance = item.chance
        })
    end
    
    local inventoryImageConfig = {
        useInventoryPath = Config.UseInventoryImagePath,
        type = Config.InventoryType,
        path = Config.InventoryImagePath[Config.InventoryType] or ""
    }
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "startMinigame",
        items = minigameItems,
        speed = Config.MinigameSpeed,
        inventoryConfig = inventoryImageConfig
    })
    
    AddNPCToCooldown(npcNetId)
end

RegisterNetEvent('nc-pickpocket:client:ContinuePickpocket')
AddEventHandler('nc-pickpocket:client:ContinuePickpocket', function(canContinue)
    continuePickpocketing = canContinue
end)

RegisterNUICallback('npcCallingPolice', function(data, cb)
    local npcPed = IsNearValidNPC()
    if npcPed then
        HandleNPCCallingPolice(npcPed)
    end
    cb({})
end)

RegisterNUICallback('minigameComplete', function(data, cb)
    local success = data.success
    local successRate = data.totalAttempts > 0 and (data.successfulAttempts / data.totalAttempts) * 100 or 0
    local collectedItems = data.collectedItems or {} 
    
    local playerPed = PlayerPedId()
    ClearPedTasksImmediately(playerPed)
    
    pickpocketingInProgress = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = "stopMinigame"
    })
    
    local npcPed = IsNearValidNPC()
    
    if npcPed then
        SetTimeout(300, function()
            if DoesEntityExist(npcPed) then
                MakeNPCLookNatural(npcPed, false)
            end
        end)
        
        if success and successRate >= Config.SuccessPercentage and #collectedItems > 0 then
            QBCore.Functions.Notify(Config.Notifications.SuccessfulPickpocket, "success")
            
            TriggerServerEvent('nc-pickpocket:server:AddCollectedItems', collectedItems, currentPickpocketItems)
            
            if math.random(1, 100) <= Config.DiscoveryChance then
                Wait(math.random(100, 300))
                
                if math.random(1, 100) <= Config.NPCAggressiveChance then
                    MakeNPCAggressive(npcPed, playerPed)
                else
                    HandleNPCCallingPolice(npcPed)
                end
            end
        elseif data.totalAttempts > 0 then
            QBCore.Functions.Notify(Config.Notifications.FailedPickpocket, "error")
            
            Wait(math.random(50, 150))
            
            local reaction = math.random(1, 100)
            if reaction <= Config.NPCCallPoliceChance then
                HandleNPCCallingPolice(npcPed)
            elseif reaction <= (Config.NPCCallPoliceChance + Config.NPCAggressiveChance) then
                MakeNPCAggressive(npcPed, playerPed)
            end
        end
    end
    
    currentPickpocketItems = {}
    isMinigameReset = true
    
    cb({})
end)

RegisterNUICallback('closeMinigame', function(data, cb)
    ClearPedTasksImmediately(PlayerPedId())
    
    ResetPickpocketState()
    
    SendNUIMessage({
        action = "stopMinigame"
    })
    
    local npcPed = IsNearValidNPC()
    if npcPed then
        MakeNPCLookNatural(npcPed, false)
    end
    
    if data.emptyPockets then
        QBCore.Functions.Notify(Config.Notifications.NoItems, "error")
    end
    
    cb({})
end)

RegisterNUICallback('confirmReset', function(data, cb)
    isMinigameReset = true
    cb({})
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for npcPed, _ in pairs(npcOriginalHeadings) do
        if DoesEntityExist(npcPed) then
            SetEntityInvincible(npcPed, false)
            SetBlockingOfNonTemporaryEvents(npcPed, false)
            ClearPedTasks(npcPed)
        end
    end
    
    npcOriginalHeadings = {}
    callingPoliceNPC = nil
end)

local function InitializeTarget()
    exports['qb-target']:AddGlobalPed({
        options = {
            {
                icon = 'fas fa-hand-paper',
                label = 'Pickpocket',
                action = function(entity)
                    if not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, 1) then
                        StartPickpocketing(entity)
                    end
                end,
                canInteract = function(entity)
                    return not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, 1) and not IsPedInAnyVehicle(entity, false)
                end,
            },
        },
        distance = 1.5,
    })
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        InitializeTarget()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    InitializeTarget()
end)

RegisterNetEvent('nc-pickpocket:EmoteDisplay')
AddEventHandler('nc-pickpocket:EmoteDisplay', function(playerId, message, coords)
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    if #(playerCoords - coords) < 10.0 then
        TriggerEvent('chat:addMessage', {
            template = '<div style="padding: 0.5vh; margin: 0.5vh; background-color: rgba(99, 99, 99, 0.75); border-radius: 3px;"><i class="fas fa-user"></i> {0}: {1}</div>',
            args = {"NPC", message}
        })
    end
end)

RegisterNetEvent('nc-pickpocket:client:PoliceAlert', function(coords)
    local alpha = 250
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, 50.0)

    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, alpha)
    SetBlipAsShortRange(blip, true)

    while alpha ~= 0 do
        Wait(Config.BlipTimeout)
        alpha = alpha - 1
        SetBlipAlpha(blip, alpha)

        if alpha == 0 then
            RemoveBlip(blip)
            return
        end
    end
end)