--[[
    This file is not inteded to be run. It is just a bunch of class definitions.
    Useful to the Lua language server only.
--]]

---@class NPCDef
---@field blip NPCBlip? Description of the map blip, if any.
---@field disabled boolean? Is this NPC currently disabled?
---@field location vector4 Where the NPC should spawn, with W denoting heading.
---@field model integer|string? Model to spawn for this NPC, if non-default.
---@field scenario string? Name of the scenario to run, if non-default
---@field marker NPCMarker? Table with description of the marker.
---@field interact NPCInteraction? Description of the intractions with this NPC.
---@field greeting table? Table with the greeting and farewell for this NPC `{"GENERIC_HI", "GENERIC_BYE"}`
---@field hasGreeted boolean? Holds if this NPC has already said it's greeting.
---@field ped number? Entity ID of the NPCs ped, if spawned.
---@field pedCoords vector3? Ped's coordinates, if spawned.
---@field skin table? Skin definition -- TODO: Class for skin definition? I really don't want to.
---@field weapon integer|string? Weapon for this NPC to be holding, if any.
---@field resource string? What resource this NPC belongs to.

---@class NPCBlip
---@field sprite integer? Sprite to use, if non-default
---@field label string? Label to use for legend. Empty string to remove from legend, omit to use blip sprite default.
---@field ref integer? The game's ID for the blip, if currently on the map.
---@field colour integer? HUD colour to use for this blip, if not default

---@class NPCMarker
---@field hide boolean? Should the marker be hidden from drawing?
-- TODO: More fields? Colour, shape, all manner of stuff, I guess?

---@class NPCInteraction
---@field disable boolean? Should the interaction be completely disabled?
---@field label string? Label to show next to the input prompt. Omit for "Interact", set to blank string to not prompt, but still have the intraction available.
---@field voice string? Voice line to say when interaction happens, if any.
---@field code function? Function to run when intraction happens.
---@field event string? Event to emit when interaction happens.
---@field args table? Table of arguments to be passed, along with the NPC ID, to the function and/or event.