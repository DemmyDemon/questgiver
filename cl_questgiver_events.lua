AddEventHandler('onResourceStop', function(stoppedResource)
    local thisResource = GetCurrentResourceName()
    for i=1, #NPCs do
        if stoppedResource == thisResource or NPCs[i].resource == stoppedResource then
            if NPCs[i].blip and NPCs[i].blip.ref then
                if DoesBlipExist(NPCs[i].blip.ref) then
                    RemoveBlip(NPCs[i].blip.ref)
                end
            end
            DespawnPed(i, true)
            NPCs[i].disabled = true
        end
    end
end)

AddEventHandler('questgiver:hideMarker', function(npcID, hideTime, disableInteractTime)
    HideMarker(npcID, true)
    if disableInteractTime  then
        TriggerEvent('questgiver:disableInteraction', npcID, disableInteractTime)
    end

    if hideTime and hideTime > 0 then
        Citizen.Wait(hideTime)
        HideMarker(npcID, false)
    end
end)

AddEventHandler('questgiver:disableInteraction', function(npcID, length)
    DisableInteraction(npcID, true)
    if length and length > 0 then
        Citizen.Wait(length)
        DisableInteraction(npcID, false)
    end
end)
