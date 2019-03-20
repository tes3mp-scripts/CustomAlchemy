local Formulas = {
    MORTAR = 1,
    ALEMBIC = 2,
    CALCINATOR = 3,
    RETORT = 4,
    
    fPotionStrengthMult = 0.5,
    fPotionT1DurMult = 0.5,
    fPotionT1MagMult = 1.5,
    iAlchemyMod = 2,
    
    maxPotency = 100
}


function Formulas.getRandom()
    math.randomseed(os.time())
    
    math.random()
    math.random()
    math.random()
    
    return math.random()
end

function Formulas.getAlchemy(pid)
    return Players[pid].data.skills.Alchemy
end

function Formulas.getIntelligence(pid)
    return Players[pid].data.attributes.Intelligence
end

function Formulas.getLuck(pid)
    return Players[pid].data.attributes.Luck
end


function Formulas.makeAlchemyStatus(pid, apparatuses, ingredients)
    local status = {
        pid = pid,
        ingredients = ingredients
    }
    
    status.mortar = apparatuses[Formulas.MORTAR]
    status.alembic = apparatuses[Formulas.ALEMBIC]
    status.calcinator = apparatuses[Formulas.CALCINATOR]
    status.retort = apparatuses[Formulas.RETORT]

    status.alchemy = Formulas.getAlchemy(pid)
    status.intelligence = Formulas.getIntelligence(pid)
    status.luck = Formulas.getLuck(pid)

    status.potency = Formulas.getPotionPotency(status)

    status.weight = Formulas.getPotionWeight(status)
    
    status.icon = Formulas.getPotionIcon(status)
    
    status.model = Formulas.getPotionModel(status)
    
    status.value = Formulas.getPotionValue(status)
    
    return status
end

function Formulas.getPotionPotency(status)
    local potency = status.alchemy + 0.1 * ( status.intelligence + status.luck )
    potency = potency * status.mortar * Formulas.fPotionStrengthMult
    
    return potency
end

function Formulas.getPotionValue(status)
    return Formulas.iAlchemyMod * status.potency
end


function Formulas.getPotionWeight(status)
    local total_weight = 0
    for _,ingredient in pairs(status.ingredients) do
        total_weight = total_weight + ingredient.weight
    end
    return (0.75 * total_weight + 0.35) / (0.5 + status.alembic)
end

function Formulas.getPotionIcon(status)
    local tier = math.floor(status.potency/18)
    if tier >= 4 then
        return "m\\tx_potion_exclusive_01.tga"
    elseif tier == 3 then
        return "m\\tx_potion_quality_01.tga"
    elseif tier == 2 then
        return "m\\tx_potion_standard_01.tga"
    elseif tier == 1 then
        return "m\\tx_potion_cheap_01.tga"
    end
    return "m\\tx_potion_bargain_01.tga"
end

function Formulas.getPotionModel(status)
    local tier = math.floor(status.potency/18)
    if tier >= 4 then
        return "m\\misc_potion_exclusive_01.nif"
    elseif tier == 3 then
        return "m\\misc_potion_quality_01.nif"
    elseif tier == 2 then
        return "m\\misc_potion_standard_01.nif"
    elseif tier == 1 then
        return "m\\misc_potion_cheap_01.nif"
    end
    return "m\\misc_potion_bargain_01.nif"
end


function Formulas.getPotionCount(status, ingredientCount)
    local n = ingredientCount
    local roll = Formulas.getRandom()
    local p = status.potency / Formulas.maxPotency
    
    local pn = (1-p)^n
    local probability = pn
    local n_choose_i = 1
    local dp = p/(1-p)
    
    for k = 1,n do
        n_choose_i = n_choose_i * (n - k + 1) / k
        pn = pn * dp
        probability = probability + n_choose_i * pn
        if probability >= roll then
            
            return k-1
        end
    end
    
    return n
end

function Formulas.getEffectMagnitude(status, effect)
    if not effect.hasMagnitude then
        return 0
    end
    
    local magnitude = status.potency / Formulas.fPotionT1MagMult / effect.cost
    
    if effect.negative then
        if status.alembic ~= 0 then
            if status.calcinator ~= 0 then
                magnitude = magnitude / ( status.alembic * 2 + status.calcinator * 3 )
            else
                magnitude = magnitude / ( status.alembic + 1 )
            end
        else
            magnitude = magnitude + status.calcinator
            if not effect.hasDuration then
                magnitude = magnitude*( status.calcinator + 0.5 ) - status.calcinator
            end
        end
    else
        local mod = status.calcinator + status.retort
        
        if status.calcinator ~= 0 and  status.retort ~= 0 then
            magnitude = magnitude  + mod + status.retort
            if not effect.hasDuration then
                magnitude = magnitude - ( mod / 3 ) - status.retort + 0.5
            end
        else
            magnitude = magnitude + mod
            if not effect.hasDuration then
                magnitude = magnitude * ( mod + 0.5 ) - mod
            end
        end
    end
    
    return magnitude
end

function Formulas.getEffectDuration(status, effect)
    if not effect.hasDuration then
        return 0
    end
    
    local duration = status.potency / Formulas.fPotionT1DurMult / effect.cost
    
    if effect.negative then
        if status.alembic ~= 0 then
            if status.calcinator ~= 0 then
                duration = duration / ( status.alembic * 2 + status.calcinator * 3 )
            else
                duration = duration / ( status.alembic + 1 )
            end
        else
            duration = duration + status.calcinator
            if not effect.hasMagnitude then
                duration = duration*(status.calcinator + 0.5) - status.calcinator
            end
        end
    else
        local mod = status.calcinator + status.retort
        
        if status.calcinator ~= 0 and  status.retort ~= 0 then
            duration = duration + mod + status.retort
            if not effect.hasMagnitude then
                duration = duration - ( mod / 3 ) - status.retort + 0.5
            end
        else
            duration = duration + mod
            if not effect.hasMagnitude then
                duration = duration * ( mod + 0.5 ) - mod
            end
        end
    end
    
    return duration
end


return Formulas