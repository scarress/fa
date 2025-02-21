--****************************************************************************
--**
--**  File     :  /units/XSL0307/XSL0307_script.lua
--**
--**  Summary  :  Seraphim Mobile Shield Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SShieldHoverLandUnit = import("/lua/seraphimunits.lua").SShieldHoverLandUnit
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon --import a default weapon so our pointer doesnt explode
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class XSL0307 : SShieldHoverLandUnit, ShieldEffectsComponent
XSL0307 = ClassUnit(SShieldHoverLandUnit, ShieldEffectsComponent) {
    
    Weapons = {        
        TargetPointer = ClassWeapon(DefaultProjectileWeapon) {},
    },
    
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_mobile_01_emit.bp',
    },
    
    ---@param self XSL0307
    OnCreate = function(self) -- Are these missng on purpose?
        SShieldHoverLandUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    ---@param self XSL0307
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self,builder,layer)
        SShieldHoverLandUnit.OnStopBeingBuilt(self,builder,layer)
        
        self.TargetPointer = self:GetWeapon(1) --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
        self.TargetLayerCaps = self:GetBlueprint().Weapon[1].FireTargetLayerCapsTable --we save this to the unit table so dont have to call every time.
        self.PointerEnabled = true --a flag to let our thread know whether we should turn on our pointer.
    end,
    
    ---@param self XSL0307
    OnShieldEnabled = function(self)
        SShieldHoverLandUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)
    end,

    ---@param self XSL0307
    OnShieldDisabled = function(self)
        SShieldHoverLandUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
    end,

    ---@param self XSL0307
    DisablePointer = function(self)
        self.TargetPointer:SetFireTargetLayerCaps('None') --this disables the stop feature - note that its reset on layer change!
        self.PointerRestartThread = self:ForkThread( self.PointerRestart )
    end,
    
    ---@param self XSL0307
    PointerRestart = function(self)
    --sadly i couldnt find some way of doing this without a thread. dont know where to check if its still assisting other than this.
        while self.PointerEnabled == false do
            WaitSeconds(1)

            -- break if we're a gooner
            if IsDestroyed(self) or IsDestroyed(self.TargetPointer) then 
                break 
            end

            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self.Layer]) --this resets the stop feature - note that its reset on layer change!
            end
        end
    end,
    
    ---@param self XSL0307
    OnLayerChange = function(self, new, old)
        SShieldHoverLandUnit.OnLayerChange(self, new, old)
        
        if not IsDestroyed(self.TargetPointer) then
            if self.PointerEnabled == false then
                self.TargetPointer:SetFireTargetLayerCaps('None') --since its reset on layer change we need to do this. unfortunate.
            end
        end
    end,
}

TypeClass = XSL0307
