local defaultScenario = SCENARIO.clipboard
local defaultModel = `s_m_y_doorman_01`
local autoScenarioRange = 2.5
local npcSpawnRange = 75.0

local markerRenderDistance = 25.0
local NPCsWithMarkers = {}

local npcGreetRange = 5.0

local npcInteractRange = 2.0
local NPCsWithInteraction = {}
local hudColour = GetConvarInt("questgiverColour", 64)

AddTextEntry('QG_INTERACT', '~INPUT_CONTEXT~ ~a~')

local function findConflictingPed(coords, maxDist)
    SetScenarioPedsToBeReturnedByNextCommand(true)
    return GetClosestPed(coords.x, coords.y, coords.z, maxDist, true, true, false, false, -1)
end

local function displayInteractMessage(ped, message)
    if message == '' then return end
    local coords = GetPedBoneCoords(ped, 0, 0.0, 0.0, 0.0) -- 0x796E for head
    -- SetFloatingHelpTextToEntity(1, ped, 0.025, -0.1)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 3, hudColour, -1, 0, 0)
    BeginTextCommandDisplayHelp('QG_INTERACT')
    AddTextComponentSubstringPlayerName(message or 'Interact')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

local function placeBlip(coords, data)
    local blip = AddBlipForCoord(coords.x, coords.y, 0.0)
    if data.sprite then
        SetBlipSprite(blip, data.sprite)
    else
        SetBlipSprite(blip, 280)
    end
    SetBlipHighDetail(blip, true)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, data.colour or hudColour)
    if data.label then
        if data.label == '' then
            SetBlipHiddenOnLegend(blip, true)
        else
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(tostring(data.label))
            EndTextCommandSetBlipName(blip)
        end
    end
    return blip
end

---Add an NPC
---@param npcDefinition NPCDef An NPC definition to follow when deploying this NPC
---@return integer npcID The ID of the added NPC
function Add(npcDefinition)
    -- TODO: Sanity check the npcDefinition?
    if npcDefinition.blip and not npcDefinition.disabled then
        npcDefinition.blip.ref = placeBlip(npcDefinition.location.xy, npcDefinition.blip)
    end
    table.insert(NPCs, npcDefinition)
    return #NPCs
end
exports('Add', Add)

function Enable(npcID, state)
    if not NPCs[npcID] then
        return nil -- As in "No such NPC"
    end
    NPCs[npcID].disabled = not state -- Because we don't care about the *value* of state here, just it's truthiness

    if NPCs[npcID].disabled then
        if NPCs[npcID].blip and NPCs[npcID].blip.ref then
            RemoveBlip(NPCs[npcID].blip.ref)
            NPCs[npcID].blip.ref = nil
        end
    else
        if NPCs[npcID].blip and not DoesBlipExist(NPCs[npcID].blip.ref) then
            NPCs[npcID].blip.ref = placeBlip(NPCs[npcID].location.xy, NPCs[npcID].blip)
        end
    end
    return not NPCs[npcID].disabled
end
exports('Enable', Enable)

function IsEnabled(npcID)
    if not NPCs[npcID] then
        return nil -- As in "No such NPC"
    end
    return not NPCs[npcID].disabled
end
exports('IsEnabled', IsEnabled)

---Get the Ped associated with the given NPC ID
---@param npcID number NPC ID
---@return number? ped Entity ID associated with this NPC
function GetPed(npcID)
    if not NPCs[npcID] then
        return -- nil, as in "invalid"
    end
    return NPCs[npcID].ped -- Can also be nil, if there is no such ped.
end
exports('GetPed', GetPed)

---Set or unset the hiding of the marker above this NPC, if it has one
---@param npcID number ID of the NPC in question
---@param setting boolean True to hide, false to show, nil to toggle
---@return boolean? isHidden True if now hidden, false if now shown, nil if there is no such NPC, or it has no marker
function HideMarker(npcID, setting)
    if not NPCs[npcID] or not NPCs[npcID].marker then
        return -- nil, as in "no status"
    end

    if setting == nil then -- Checking for nil specifically, not falseness.
        NPCs[npcID].marker.hide = not NPCs[npcID].marker.hide
        return NPCs[npcID].marker.hide
    end

    NPCs[npcID].marker.hide = (setting) -- Store it's truthiness, not it's value
    return NPCs[npcID].marker.hide
end
exports('HideMarker', HideMarker)

---Check if the given NPC has a visible marker or not
---@param npcID number NPC ID to check for
---@return boolean? showingMarker True if the NPC has a marker showing. False if it is hidden. nil if the NPC does not exist or has no marker
function HasMarker(npcID)
    if not NPCs[npcID] or NPCs[npcID].marker == nil then
        return -- No NPC, no response. nil is a false-y value anyway.
    end

    return not NPCs[npcID].marker.hide
end
exports('HasMarker', HasMarker)

---Hide the intraction prompt foor this NPC
---@param npcID number ID of the NPC in question
---@param setting boolean? True to hide the interaction prompt, false to show it, nil to toggle
---@return boolean? isHidden The state of the interaction prompt. True is hidden, False is shown, nil means it is an invalid NPC or it has no interact
function HideInteraction(npcID, setting)
    if not NPCs[npcID] then
        return -- nil, as in "no status"
    end

    if not NPCs[npcID].interact then
        return -- nil again, as it's unsettable
    end

    if setting == nil then -- Checking for nil specifically, not falseness.
        NPCs[npcID].interact.hide = not NPCs[npcID].interact.hide
        return NPCs[npcID].interact.hide
    end

    NPCs[npcID].interact.hide = (setting) -- Store it's truthiness, not it's value
    return NPCs[npcID].interact.hide
end
exports('HideInteraction', HideInteraction)

---Check if an NPC is currently interactable
---@param npcID number The ID of the NPC in question
---@return boolean? isInteractable True if it is interactable, Flase if not, nil if it is an invalid NPC or it has no interact
function IsInteractable(npcID)
    if not NPCs[npcID] or not NPCs[npcID].interact then
        return -- No NPC, no response. nil is a false-y value anyway.
    end
    return not NPCs[npcID].interact.hide
end
exports('IsInteractable', IsInteractable)

Citizen.CreateThread(function()
    for _, npc in ipairs(NPCs) do
        if npc.blip and not npc.disabled then
            npc.blip.ref = placeBlip(npc.location.xy, npc.blip)
        end
    end
end)

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

function SpawnPed(location, model, weapon, skin)
    if not loadModel(model) then
        print('Failed to load NPC model ' .. model)
        return
    end

    local conflict, otherPed = findConflictingPed(location, autoScenarioRange)
    if conflict then
        -- FIXME: This only works if you own this ped... Dispatch to server?
        ClearPedTasksImmediately(otherPed)
        TaskWanderStandard(otherPed, 10.0, 10)
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

    if skin then
        SetSkin(ped, skin)
    else
        SetPedRandomProps(ped)
        SetPedRandomComponentVariation(ped, 0)
    end

    FreezeEntityPosition(ped, true)
    -- SetEntityCollision(ped, false, false)
    TaskLookAtEntity(ped, PlayerPedId(), -1, 2048, 3)

    if weapon then
        GiveWeaponToPed(ped, weapon, 1, true, true)
        SetPedDropsWeaponsWhenDead(ped, false)
    end

    Citizen.CreateThread(function()
        for alpha = 0, 255, 51 do
            SetEntityAlpha(ped, alpha, false)
            Citizen.Wait(50)
        end
    end)

    return ped
end

function DespawnPed(npcID, instant)
    if not NPCs[npcID] then return end
    if NPCs[npcID].ped and DoesEntityExist(NPCs[npcID].ped) then
        local ped = NPCs[npcID].ped or 0

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

local function setScenario(ped, task)
    TaskStartScenarioInPlace(ped, task or  defaultScenario, 0, true)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local coords = GetFinalRenderedCamCoord()

        local aimed, aimedEntity -- Disabled because it's not very elegant
        -- aimed, aimedEntity = GetEntityPlayerIsFreeAimingAt(PlayerId()) -- Not working right yet
        for i, npc in ipairs(NPCs) do
            Citizen.Wait(0)
            local npcDistance = #(coords - npc.location.xyz)
            if not npc.disabled and npcDistance < npcSpawnRange then
                if not npc.ped or not DoesEntityExist(npc.ped) then
                    npc.ped = SpawnPed(npc.location, npc.model or defaultModel, npc.weapon, npc.skin)
                    if npc.marker then
                        table.insert(NPCsWithMarkers, i)
                    end
                    if npc.interact then
                        table.insert(NPCsWithInteraction, i)
                    end
                end
                if IsPedFatallyInjured(npc.ped) then
                    DespawnPed(i)
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
                    setScenario(npc.ped, npc.scenario)
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
                    DespawnPed(i)
                end
            end
        end
    end
end)

local function renderMarker(coords, dist)
    if dist > markerRenderDistance then
        return
    end
    local alpha  = 255

    if dist > markerRenderDistance/2 then
        alpha = alpha - (255/(markerRenderDistance/2)) * (dist - markerRenderDistance/2)
        alpha = math.floor(alpha)
    end

    local r, g, b, _ = GetHudColour(hudColour)

    DrawMarker(43, -- 2 for the chevron
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0, -- "dir"
        0.0, 0.0, 0.0, -- "rot"
        0.1, 0.1, 0.5, -- "scale",
        r, g, b, alpha, -- RGBA
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
            if not ped or not DoesEntityExist(ped) then
                NPCs[qgid].ped = nil
                table.remove(NPCsWithMarkers, i)
            else
                if not NPCs[qgid].marker.hide then
                    local coords = GetPedBoneCoords(ped, 0x796E, 0.3, 0.0, 0.0)
                    local dist = #(camCoords - coords)
                    renderMarker(coords, dist)
                end
            end
        end
    end
end)

local function maybeInteract(npcID)

    if not IsControlEnabled(0, 51) then
        return
    end

    displayInteractMessage(NPCs[npcID].ped, NPCs[npcID].interact.label)

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
            elseif not NPCs[npcID].interact.hide then
                local dist = #( myCoords - NPCs[npcID].pedCoords )
                if dist <= npcInteractRange then
                    maybeInteract(npcID)
                end
            end
        end
    end
end)

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
