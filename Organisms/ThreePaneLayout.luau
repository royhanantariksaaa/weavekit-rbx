local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)

local ThreePaneLayout = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        
        if props.LeftPane then inst._props.LeftPane = props.LeftPane end
        if props.MiddlePane then inst._props.MiddlePane = props.MiddlePane end
        if props.RightPane then inst._props.RightPane = props.RightPane end
        if props.Ratios then inst._props.Ratios = props.Ratios end
        
        return inst:Build()
    end
})
ThreePaneLayout.__index = ThreePaneLayout

function ThreePaneLayout.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), ThreePaneLayout)
    self._props.Ratios = { 0.25, 0.35, 0.4 }
    return self
end

function ThreePaneLayout:Build()
    local scope = self._scope
    
    local Container = require(script.Parent.Parent.Atoms.Container)
    local Row = require(script.Parent.Parent.Atoms.Row)


    return Container(scope, {
        Padding = UDim.new(0, 16),
        [Weave.Children] = {
            Row(scope, {
                Ratios = self._props.Ratios,
                Gap = UDim.new(0, 12),
                Size = UDim2.fromScale(1, 1),
                [Weave.Children] = {
                    scope:Frame {
                        Name = "LeftPaneSlot",
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        [Weave.Children] = self._props.LeftPane
                    },
                    scope:Frame {
                        Name = "MiddlePaneSlot",
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        [Weave.Children] = self._props.MiddlePane
                    },
                    scope:Frame {
                        Name = "RightPaneSlot",
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        [Weave.Children] = self._props.RightPane
                    },
                }
            })
        }
    })
end

return ThreePaneLayout
