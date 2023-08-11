local defaultScenario = SCENARIO.clipboard
local defaultModel = `s_m_y_doorman_01`
local autoScenarioRange = 2.5
local markerRenderDistance = 25.0
local NPCsWithMarkers = {}
local npcSpawnRange = 75.0

function AddNPC(npcDefinition)
    table.insert(NPCs, npcDefinition)
    return #NPCs
end
exports('AddNPC', AddNPC)

function SetMarker(npcRef, setting)
    if not NPCs[npcRef] then
        return -- nil, as in "no status"
    end

    if setting == nil then -- Checking for nil specifically, not falseness.
        NPCs[npcRef].marker = not NPCs[npcRef].marker
        return NPCs[npcRef].marker
    end

    NPCs[npcRef].marker = (setting) -- Store it's truthiness, not it's value
    return NPCs[npcRef].marker
end
exports('SetMarker', SetMarker)

function LoadModel(model, timeout)
    timeout = timeout or 5000

    if HasModelLoaded(model) then
        return true
    end

    RequestModel(model)
    local started = GetGameTimer()
    while not HasModelLoaded(model) and GetGameTimer() < started + timeout do
        Citizen.Wait(0)
    end
    return HasModelLoaded(model)
end


function SpawnPed(location, model)
    if not LoadModel(model) then
        print('Failed to load NPC model ' .. model)
        return
    end
    local ped = CreatePed(4, model, location.x, location.y, location.z, location.w, false, false)
    SetEntityAlpha(ped, 0, false)
    SetModelAsNoLongerNeeded(model)
    -- SetEntityCoordsNoOffset(ped, location.x, location.y, location.z, true, false, false)
    SetPedConfigFlag(ped, 17, true) -- CPED_CONFIG_FLAG_BlockNonTemporaryEvents
    SetPedConfigFlag(ped, 43, true) -- CPED_CONFIG_FLAG_DisablePlayerLockon
    SetPedConfigFlag(ped, 128, false) -- CPED_CONFIG_FLAG_CanBeAgitated
    SetEntityProofs(
        ped,
        true, -- Bullet
        true, -- Fire
        true, -- Explosion
        true, -- Collision
        true, -- Melee
        true, -- Steam
        true, -- [Unknown]
        true -- Drowning
    )
    SetPedRandomProps(ped)
    SetPedRandomComponentVariation(ped, 0)
    FreezeEntityPosition(ped, true)
    -- SetEntityCollision(ped, false, false)
    TaskLookAtEntity(ped, PlayerPedId(), -1, 2048, 3)
    local alpha = 0
    Citizen.CreateThread(function()
        while alpha <= 255 do
            -- Yes, I realize this bit is convoluted as fsck.
            local delta = GetFrameTime()
            local newAlpha = alpha + math.ceil(500 * delta)
            if newAlpha == alpha then
                newAlpha = alpha + 1
            end
            alpha = newAlpha
            if alpha > 255 then alpha = 255 end
            SetEntityAlpha(ped, alpha, false)
            Citizen.Wait(0)
        end
    end)
    return ped
end

function DespawnPedAtIndex(index)
    if NPCs[index] and NPCs[index].ped and DoesEntityExist(NPCs[index].ped) then
        SetEntityAsMissionEntity(NPCs[index].ped, true, true)
        DeleteEntity(NPCs[index].ped)
        NPCs[index].ped = nil
    end
end

function SetScenario(ped, task)
    TaskStartScenarioInPlace(ped, task or  defaultScenario, 0, true)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local coords = GetFinalRenderedCamCoord()

        -- local aimed, aimedEntity = GetEntityPlayerIsFreeAimingAt(PlayerId()) -- Not working right yet
        for i, npc in ipairs(NPCs) do
            Citizen.Wait(0)
            if #(coords - npc.location.xyz) < npcSpawnRange then
                if not npc.ped or not DoesEntityExist(npc.ped) then
                    npc.ped = SpawnPed(npc.location, npc.model or defaultModel)
                    if npc.marker then
                        table.insert(NPCsWithMarkers, i)
                    end
                end
                if IsPedFatallyInjured(npc.ped) then
                    DespawnPedAtIndex(i)
                end
                --[[ This bit has some issues still
                if aimed and npc.ped == aimedEntity then
                    TaskHandsUp(npc.ped, 10000, -1, 10000, true)
                else
                --]]
                if npc.scenario == SCENARIO.auto then
                    if not IsPedUsingAnyScenario(npc.ped) then
                        if DoesScenarioExistInArea(npc.location.x, npc.location.y, npc.location.z, autoScenarioRange, true) then
                            TaskUseNearestScenarioToCoordWarp(npc.ped, npc.location.x, npc.location.y, npc.location.z, autoScenarioRange, -1)
                        end
                    end
                elseif not IsPedUsingScenario(npc.ped, npc.scenario or defaultScenario) then
                    SetScenario(npc.ped, npc.scenario)
                end
            else
                if npc.ped and DoesEntityExist(npc.ped) then
                    DespawnPedAtIndex(i)
                end
            end
        end
    end
end)

function RenderMarker(coords, dist)
    if dist > markerRenderDistance then
        return
    end
    local alpha  = 255

    if dist > markerRenderDistance/2 then
        alpha = alpha - (255/(markerRenderDistance/2)) * (dist - markerRenderDistance/2)
        alpha = math.floor(alpha)
    end

    DrawMarker(43, -- 2 for the chevron
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0, -- "dir"
        0.0, 0.0, 0.0, -- "rot"
        0.1, 0.1, 0.5, -- "scale",
        175, 175, 0, alpha, -- RGBA
        false, -- bob
        false, -- face
        0, -- UNK
        true, -- rotate
        ---@diagnostic disable-next-line -- Trust me, bro, this means "no texture"
        0, 0, -- Texture
        false -- DrawOnEnts
    )
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(#NPCsWithMarkers == 0 and 1000 or 0)

        local camCoords = GetFinalRenderedCamCoord()

        for i=#NPCsWithMarkers, 1, -1 do
            local qgid = NPCsWithMarkers[i]
            local ped = NPCs[qgid].ped
            if not DoesEntityExist(ped) then
                NPCs[qgid].ped = nil
                table.remove(NPCsWithMarkers, i)
            else
                local coords = GetPedBoneCoords(ped, 0x796E, 0.4, 0.0, 0.0)
                local dist = #(camCoords - coords)
                RenderMarker(coords, dist)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for i=1, #NPCs do
        DespawnPedAtIndex(i)
    end
end)
