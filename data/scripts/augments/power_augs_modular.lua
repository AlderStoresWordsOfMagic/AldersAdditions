-- [Bonus Power Augs - Copied code from from MV.]

local bonusPowerAugs = {
    AA_BOON_INFUSER = 3 -- Weapons
}

-- Make augments provide bonus power to their specified systems
script.on_internal_event(Defines.InternalEvents.SET_BONUS_POWER, function(system, amount)
    local ship = Hyperspace.ships(system._shipObj.iShipId)
    if ship then
        for augName, sysId in pairs(bonusPowerAugs) do
            if system:GetId() == sysId then
                amount = amount + ship:GetAugmentationValue(augName)
            end
        end
    end
    return Defines.Chain.CONTINUE, amount
end)
