local QBCore, ESX = nil, nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

local function GetJobPlayerCount(jobName)
    local count = 0
    
    if Config.Framework == 'qb' then
        for _, v in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(v)
            if Player.PlayerData.job.name == jobName and Player.PlayerData.job.onduty then
                count = count + 1
            end
        end
    elseif Config.Framework == 'esx' then
        for _, v in pairs(ESX.GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(v)
            if xPlayer.job.name == jobName and (xPlayer.job.onduty == nil or xPlayer.job.onduty) then
                count = count + 1
            end
        end
    end
    
    return count
end

local function GetPlayer(source)
    if Config.Framework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif Config.Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
end

local function AddPlayerMoney(player, amount)
    if Config.Framework == 'qb' then
        player.Functions.AddMoney('cash', amount, 'pickpocket')
    elseif Config.Framework == 'esx' then
        player.addMoney(amount)
    end
end

local function AddPlayerItem(player, item, amount)
    if Config.Framework == 'qb' then
        player.Functions.AddItem(item, amount)
    elseif Config.Framework == 'esx' then
        player.addInventoryItem(item, amount)
    end
end

local function SendItemBoxNotification(source, item, type, amount)
    if Config.Framework == 'qb' then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], type, amount)
    end
end

local function SendNotification(source, message, notifyType)
    if Config.Framework == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, message, notifyType)
    elseif Config.Framework == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    end
end

RegisterNetEvent('nc-pickpocket:server:CheckPoliceCount', function()
    local src = source
    local policeCount = GetJobPlayerCount("police")
    local canContinue = policeCount >= Config.RequiredPolice
    TriggerClientEvent('nc-pickpocket:client:ContinuePickpocket', src, canContinue)
end)

RegisterNetEvent('nc-pickpocket:server:AddCollectedItems', function(collectedIndices, originalItems)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    for _, index in ipairs(collectedIndices) do
        if originalItems and originalItems[index+1] then
            local item = originalItems[index+1]
            
            if item.name == 'cash' then
                AddPlayerMoney(Player, item.amount)
                SendNotification(src, "You stole $" .. item.amount, "success")
            else
                AddPlayerItem(Player, item.name, item.amount)
                if Config.Framework == 'qb' then
                    SendItemBoxNotification(src, item.name, 'add', item.amount)
                end
            end
        end
    end
end)

RegisterNetEvent('nc-pickpocket:server:EmoteMessage', function(coords, message)
    local src = source
    TriggerClientEvent('nc-pickpocket:EmoteDisplay', -1, src, message, coords)
end)

RegisterNetEvent('nc-pickpocket:server:NotifyPolice', function(coords)
    if Config.Framework == 'qb' then
        for _, v in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(v)
            if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
                TriggerClientEvent('QBCore:Notify', v, "Someone reported a pickpocket", "police", 5000)
                TriggerClientEvent('nc-pickpocket:client:PoliceAlert', v, coords)
            end
        end
    elseif Config.Framework == 'esx' then
        for _, v in pairs(ESX.GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(v)
            if xPlayer.job.name == "police" and (xPlayer.job.onduty == nil or xPlayer.job.onduty) then
                TriggerClientEvent('esx:showNotification', v, "Someone reported a pickpocket")
                TriggerClientEvent('nc-pickpocket:client:PoliceAlert', v, coords)
            end
        end
    end
end)

RegisterNetEvent('nc-pickpocket:EmoteDisplay', function(playerId, message, coords)
    local src = source
    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    
    if #(srcCoords - coords) < 10.0 then
        TriggerClientEvent('chat:addMessage', src, {
            template = '<div style="padding: 0.5vh; margin: 0.5vh; background-color: rgba(99, 99, 99, 0.75); border-radius: 3px;"><i class="fas fa-user"></i> {0}: {1}</div>',
            args = {"NPC", message}
        })
    end
end)
