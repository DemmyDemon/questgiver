AddTextEntry('QG_INTERACT', GetConvar("questgiverPrompt", '~INPUT_CONTEXT~ ~a~'))
local hudColour = GetConvarInt("questgiverColour", 64)
local markerRenderDistance = 25.0

NPCsWithMarkers = {}

Citizen.CreateThread(function()
    for _, npc in ipairs(NPCs) do
        if npc.blip and not npc.disabled then
            npc.blip.ref = PlaceBlip(npc.location.xy, npc.blip)
        end
    end
end)

function PlaceBlip(coords, data)
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

function DisplayInteractMessage(ped, message)
    if message == '' then return end
    local coords = GetPedBoneCoords(ped, 0x9995, 0.0, 0.0, 0.0) -- 0x796E for head
    -- SetFloatingHelpTextToEntity(1, ped, 0.025, -0.1)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 3, hudColour, -1, 0, 0)
    BeginTextCommandDisplayHelp('QG_INTERACT')
    AddTextComponentSubstringPlayerName(message or 'Interact')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

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
