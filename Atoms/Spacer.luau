local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)

local Spacer = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        
        if props.Size then inst:SetSize(props.Size) end
        if props.FlexMode then inst:SetFlex(props.FlexMode, props.GrowRatio) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.Name then inst:SetName(props.Name) end
        
        return inst:Build()
    end
})
Spacer.__index = Spacer

function Spacer.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Spacer)
    return self
end

function Spacer:SetFlex(mode: Enum.UIFlexMode, ratio: number?)
    self._props.FlexMode = mode
    self._props.GrowRatio = ratio
    return self
end

function Spacer:Build()
    local scope = self._scope
    
    local layoutChildren = {}
    
    if self._props.FlexMode then
        table.insert(layoutChildren, scope:FlexItem {
            FlexMode = self._props.FlexMode or Enum.UIFlexMode.Grow,
            GrowRatio = self._props.GrowRatio or 1
        })
    end

    return scope:Frame {
        Name = self._props.Name or "Spacer",
        Size = self._props.Size or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        LayoutOrder = self._props.LayoutOrder,
        [Weave.Children] = layoutChildren
    }
end

return Spacer
