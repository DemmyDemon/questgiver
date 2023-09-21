
NPCsWithInteraction = {}
local npcInteractRange = 2.0

local function maybeInteract(npcID)

    if not IsControlEnabled(0, 51) then
        return
    end

    DisplayInteractMessage(NPCs[npcID].ped, NPCs[npcID].interact.label)

    if not IsControlJustPressed(0, 51) then
        return
    end

    if NPCs[npcID].interact.voice then
        PlayPedAmbientSpeechNative(NPCs[npcID].ped, NPCs[npcID].interact.voice, "SPEECH_PARAMS_FORCE")
    end

    if NPCs[npcID].interact.code then
        Citizen.CreateThreadNow(function()
            pcall(NPCs[npcID].interact.code, npcID, table.unpack(NPCs[npcID].interact.args or {}))
        end)
    end

    if NPCs[npcID].interact.event then
        TriggerEvent(NPCs[npcID].interact.event, npcID, table.unpack(NPCs[npcID].interact.args or {}))
        TriggerServerEvent(NPCs[npcID].interact.event, npcID, table.unpack(NPCs[npcID].interact.args or {}))
    end

end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(#NPCsWithInteraction == 0 and 1000 or 0)
        local myCoords = GetEntityCoords(PlayerPedId())
        for i=#NPCsWithInteraction, 1, -1 do
            local npcID = NPCsWithInteraction[i]
            local ped = NPCs[npcID].ped
            if not ped or not DoesEntityExist(ped) then
                NPCs[npcID].ped = nil
                table.remove(NPCsWithInteraction, i)
            elseif not NPCs[npcID].interact.disable then
                local dist = #( myCoords - NPCs[npcID].pedCoords )
                if dist <= npcInteractRange then
                    maybeInteract(npcID)
                end
            end
        end
    end
end)
