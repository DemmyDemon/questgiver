AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for i=1, #NPCs do
        if NPCs[i].blip and NPCs[i].blip.ref then
            RemoveBlip(NPCs[i].blip.ref)
        end
        DespawnPed(i, true)
    end
end)

AddEventHandler('questgiver:hideMarker', function(npcID, hideTime, hideInteractTime)
    HideMarker(npcID, true)
    if hideInteractTime  then
        TriggerEvent('questgiver:hideInteraction', npcID, hideInteractTime)
    end

    if hideTime and hideTime > 0 then
        Citizen.Wait(hideTime)
        HideMarker(npcID, false)
    end
end)

AddEventHandler('questgiver:hideInteraction', function(npcID, length)
    HideInteraction(npcID, true)
    if length and length > 0 then
        Citizen.Wait(length)
        HideInteraction(npcID, false)
    end
end)
