function SetSkin(ped,skin)
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
