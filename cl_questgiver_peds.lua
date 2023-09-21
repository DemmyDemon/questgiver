local defaultScenario = GetConvar("questgiverDefaultScenario", SCENARIO.clipboard)
local defaultModel = GetConvarInt("questgiverDefaultModel", GetHashKey('s_m_y_doorman_01')) -- Yes, this could use `backticks`, but for it's a *single* call, and doing it this way simplifies Lua language server diagnostics.

local npcSpawnRange = 75.0
local autoScenarioRange = 2.5
local npcGreetRange = 5.0

local function findConflictingPed(coords, maxDist)
    SetScenarioPedsToBeReturnedByNextCommand(true)
    return GetClosestPed(coords.x, coords.y, coords.z, maxDist, true, true, false, false, -1)
end

function SetScenario(ped, task)
    TaskStartScenarioInPlace(ped, task or  defaultScenario, 0, true)
end

local function loadModel(model, timeout)
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

local function setSkin(ped,skin)
    if not IsEntityAPed(ped) then return false end
    if type(skin) ~= 'table' then return end

    if skin.var and type(skin.var) == 'table' then
        for variation,data in pairs(skin.var) do
            local var = tonumber(variation)
            if var then
                SetPedComponentVariation(ped, var, data[1] or 0, data[2] or 0, data[3] or 0)
            end
        end
    end
    if skin.prop and type(skin.prop) == 'table' then
        for prop,data in pairs(skin.prop) do
            if data[1] == -1 then
                ClearPedProp(ped,prop)
            else
                SetPedPropIndex(ped, prop, data[1] or 0, data[2] or 0, true)
            end
        end
    end

end

function SpawnPed(npcID) -- location, model, weapon, skin
    if not npcID or not NPCs[npcID] then return end
    local npc = NPCs[npcID]
    if not npc.model then npc.model = defaultModel end

    if not loadModel(npc.model) then
        print('Failed to load NPC model ' .. npc.model)
        return
    end

    local conflict, otherPed = findConflictingPed(npc.location, autoScenarioRange)
    if conflict then
        -- FIXME: This only works if you own this ped... Dispatch to server?
        ClearPedTasksImmediately(otherPed)
        TaskWanderStandard(otherPed, 10.0, 10)
    end

    local ped = CreatePed(4, npc.model, npc.location.x, npc.location.y, npc.location.z, npc.location.w, false, false)
    SetEntityAlpha(ped, 0, false)
    SetModelAsNoLongerNeeded(npc.model)
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

    if npc.skin then
        setSkin(ped, npc.skin)
    else
        SetPedRandomProps(ped)
        SetPedRandomComponentVariation(ped, 0)
    end

    FreezeEntityPosition(ped, true)
    -- SetEntityCollision(ped, false, false)
    TaskLookAtEntity(ped, PlayerPedId(), -1, 2048, 3)

    if npc.weapon then
        GiveWeaponToPed(ped, npc.weapon, 1, true, true)
        SetPedDropsWeaponsWhenDead(ped, false)
    end

    Citizen.CreateThread(function()
        for alpha = 0, 255, 51 do
            SetEntityAlpha(ped, alpha, false)
            Citizen.Wait(50)
        end
    end)

    TriggerEvent('questiver:spawn', npcID, ped)

    NPCs[npcID].ped = ped

    return ped
end

function DespawnPed(npcID, instant)
    if not NPCs[npcID] then return end
    if NPCs[npcID].ped and DoesEntityExist(NPCs[npcID].ped) then
        local ped = NPCs[npcID].ped or 0

        TriggerEvent('questiver:despawn', npcID, ped)

        if not instant then
            for alpha = 255, 0, -51 do
                SetEntityAlpha(ped, alpha, false)
                Citizen.Wait(50)
            end
        end

        SetEntityAsMissionEntity(ped, true, true)
        DeleteEntity(ped)
    end
    if not DoesEntityExist(NPCs[npcID].ped or 0) then
        NPCs[npcID].ped = nil
        NPCs[npcID].pedCoords = nil
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local coords = GetFinalRenderedCamCoord()

        local aimed, aimedEntity -- Disabled because it's not very elegant
        -- aimed, aimedEntity = GetEntityPlayerIsFreeAimingAt(PlayerId()) -- Not working right yet
        for npcID, npc in ipairs(NPCs) do
            Citizen.Wait(0)
            local npcDistance = #(coords - npc.location.xyz)
            if not npc.disabled and npcDistance < npcSpawnRange then
                if not npc.ped or not DoesEntityExist(npc.ped) then
                    SpawnPed(npcID)
                    if npc.marker then
                        table.insert(NPCsWithMarkers, npcID)
                    end
                    if npc.interact then
                        table.insert(NPCsWithInteraction, npcID)
                    end
                end
                if IsPedFatallyInjured(npc.ped) then
                    DespawnPed(npcID)
                end
                if aimed and npc.ped == aimedEntity then
                    TaskHandsUp(npc.ped, 10000, -1, 10000, true)
                elseif npc.scenario == SCENARIO.none then
                    -- Literally nothing.
                elseif npc.scenario == SCENARIO.auto then
                    if not IsPedUsingAnyScenario(npc.ped) then
                        if DoesScenarioExistInArea(npc.location.x, npc.location.y, npc.location.z, autoScenarioRange, true) then
                            TaskUseNearestScenarioToCoordWarp(npc.ped, npc.location.x, npc.location.y, npc.location.z, autoScenarioRange, -1)
                        end
                    end
                elseif not IsPedUsingScenario(npc.ped, npc.scenario or defaultScenario) then
                    SetScenario(npc.ped, npc.scenario)
                end

                if not npc.pedCoords then
                    npc.pedCoords = GetEntityCoords(npc.ped)
                end

                if npc.greeting then
                    local bodyDistance = #(GetEntityCoords(PlayerPedId()) - npc.pedCoords)
                    if bodyDistance <= npcGreetRange then
                        if not npc.hasGreeted then
                            npc.hasGreeted = true
                            PlayPedAmbientSpeechNative(npc.ped, npc.greeting[1], "SPEECH_PARAMS_FORCE")
                        end
                    elseif npc.greeting[2] and npc.hasGreeted then
                        PlayPedAmbientSpeechNative(npc.ped, npc.greeting[2], "SPEECH_PARAMS_FORCE")
                        npc.hasGreeted = nil
                    else
                        npc.hasGreeted = nil
                    end
                end
            else
                if npc.ped and DoesEntityExist(npc.ped) then
                    DespawnPed(npcID)
                end
            end
        end
    end
end)
