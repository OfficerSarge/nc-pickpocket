local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('nc-pickpocket:server:CheckPoliceCount', function()
    local src = source
    local police = 0
    
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
            police = police + 1
        end
    end
    
    local canContinue = police >= Config.RequiredPolice
    TriggerClientEvent('nc-pickpocket:client:ContinuePickpocket', src, canContinue)
end)

RegisterNetEvent('nc-pickpocket:server:AddCollectedItems', function(collectedIndices, originalItems)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    for _, index in ipairs(collectedIndices) do
        if originalItems and originalItems[index+1] then
            local item = originalItems[index+1]
            
            if item.name == 'cash' then
                Player.Functions.AddMoney('cash', item.amount, 'pickpocket')
                TriggerClientEvent('QBCore:Notify', src, "You stole $" .. item.amount, "success")
            else
                Player.Functions.AddItem(item.name, item.amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], 'add')
            end
        end
    end
end)

RegisterNetEvent('nc-pickpocket:server:EmoteMessage', function(coords, message)
    local src = source
    TriggerClientEvent('nc-pickpocket:EmoteDisplay', -1, src, message, coords)
end)

RegisterNetEvent('nc-pickpocket:server:NotifyPolice', function(coords)
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
            TriggerClientEvent('QBCore:Notify', v, "Someone reported a pickpocket", "police", 5000)
            TriggerClientEvent('nc-pickpocket:client:PoliceAlert', v, coords)
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