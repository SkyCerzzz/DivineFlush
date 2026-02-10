DF.energy = {}

DF.energy.increase_limit = function(amount)
    G.GAME.energy_plus = G.GAME.energy_plus
        and G.GAME.energy_plus + amount
        or amount
end

DF.energy.decrease_limit = function(amount)
    G.GAME.energy_plus = G.GAME.energy_plus and G.GAME.energy_plus > 0
        and G.GAME.energy_plus - amount
        or 0
end

DF.energy.increase_all = function(etype, amount)
    for _, card in pairs(G.jokers.cards) do
        if not etype or is_type(card, etype) then
            increment_energy(card, etype, amount)
        end
    end
end

DF.energy.decrease_all = function(etype, amount)
    for _, card in pairs(G.jokers.cards) do
        if not etype or is_type(card, etype) then
            increment_energy(card, etype, -amount)
        end
    end
end
