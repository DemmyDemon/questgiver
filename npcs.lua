--[[
    What voice lines are usable with what model can be found in x64\audio\S_FULL_AMB_F.rpf and other archives in it's vicinity.
    Basically, search for the model name, look for a matching .awc
]]

---@type NPCDef[]
NPCs = {
    {
        model = `a_m_y_epsilon_01`,
        location = vec4(42.333,-1350.227,28.292,177.952),
        greeting = {"KIFFLOM_GREET", "GENERIC_BYE"},
        interact = {
            label = 'Join the Epsilon Program',
            voice = "CHAT_RESP",
        },
        blip = {
            sprite =  206,
            label = '',
        },
    },
    {
        model = `a_m_m_tramp_01`,
        location = vec4(13.615,-1349.945,28.325,176.103),
        scenario = SCENARIO.auto,
        marker = {},
        interact = {
            event = "questgiver:hideMarker",
            args = {2500, 2500},
            label = "Poke",
            voice = "BUMP",
        },
        greeting = {"BUM_SPARE_CHANGE"},
    },
    {
        model = `mp_m_shopkeep_01`,
        location = vec4(24.353,-1345.362,28.497,268.375),
        greeting = {"SHOP_GREET", "SHOP_GOODBYE"},
        blip = {
            sprite = 59,
            label = 'Supermarket',
        },
        interact = {
            label = "Shop",
            voice = "SHOP_BANTER",
            code = function(npcID)
                print("Okay, pretend NPC " .. npcID .." opened a shop menu, or whatever")
            end,
        },
    },
    {
        location = vec4(17.921,-1329.56,30.114,182.350),
        scenario = SCENARIO.seatLedge,
        greeting = {"PROVOKE_TRESPASS"},
    },
    {
        model = `s_m_y_marine_01`,
        location = vec4(12.109,-1299.751,28.246,180.115),
        scenario = SCENARIO.none,
        weapon = `WEAPON_CARBINERIFLE`,
        interact = {
            label = "Request access",
            voice = "PROVOKE_TRESPASS",
            code = function(npcID)
                local ped = GetPed(npcID)
                if not ped then return end
                FreezeEntityPosition(ped, false)
                TaskAimGunAtEntity(ped, PlayerPedId(), 3000, true)
                Citizen.Wait(3000)
                FreezeEntityPosition(ped, true)
            end,
        },
        skin = {var={[1]={0,0,0},[2]={0,0,0},[3]={1,1,0},[4]={0,0,0},[5]={0,0,0},[6]={0,0,0},[7]={0,0,0},[8]={0,0,0},[9]={0,0,0},[10]={0,0,0},[11]={0,0,0},[0]={1,0,0},},prop={[1]={-1,-1},[2]={-1,-1},[3]={-1,-1},[0]={0,0},}},
    },
    {
        disabled = true,
        model = `a_m_o_genstreet_01`,
        location = vec4(13.083,-1337.003,28.281,339.995),
        greeting = {"UP_THERE"},
        scenario = SCENARIO.flashlight,
    },
    {
        model = `a_c_westy`,
        location = vec4(21.022,-1350.198,28.325,179.699),
        scenario = "WORLD_DOG_SITTING_SMALL",
        interact = {
            label = '',
            code = function(npcID)
                Enable(6, not IsEnabled(6))
            end,
        }
    },
}
