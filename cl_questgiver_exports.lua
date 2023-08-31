
---Add an NPC
---@param npcDefinition NPCDef An NPC definition to follow when deploying this NPC
---@return integer npcID The ID of the added NPC
function Add(npcDefinition)
    -- TODO: Sanity check the npcDefinition?
    if npcDefinition.blip and not npcDefinition.disabled then
        npcDefinition.blip.ref = PlaceBlip(npcDefinition.location.xy, npcDefinition.blip)
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
            NPCs[npcID].blip.ref = PlaceBlip(NPCs[npcID].location.xy, NPCs[npcID].blip)
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
