local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local Slider = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end

        if props.Value then inst:BindValue(props.Value) end
        if props.Min then inst._props.Min = props.Min end
        if props.Max then inst._props.Max = props.Max end
        if props.Step then inst._props.Step = props.Step end
        if props.ActiveColor then inst._props.ActiveColor = props.ActiveColor end
        if props.OnChanged then inst._props.OnChanged = props.OnChanged end
        
        if props.Name then inst:SetName(props.Name) end
        if props.Size then inst:SetSize(props.Size) end
        if props.Position then inst:SetPosition(props.Position) end
        if props.AnchorPoint then inst:SetAnchor(props.AnchorPoint) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.ZIndex then inst:SetZIndex(props.ZIndex) end

        return inst:Build()
    end
})
Slider.__index = Slider

local function resolveValue(value)
    if type(value) == "function" then
        return value()
    end
    if type(value) == "table" and type(value.Get) == "function" then
        return value:Get()
    end
    return value
end

local function resolveSetter(value)
    if type(value) == "table" and type(value.Set) == "function" then
        return function(newValue)
            value:Set(newValue)
        end
    end
    return nil
end

function Slider.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), Slider)
    self._props.Min = 0
    self._props.Max = 100
    return self
end

function Slider:BindValue(value)
    self._props.Value = value
    return self
end

function Slider:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()

    local getValue, setValue
    if type(self._props.Value) == "function" then
        getValue = self._props.Value
        setValue = nil
    elseif type(self._props.Value) == "table" and type(self._props.Value.Get) == "function" then
        getValue = function()
            return self._props.Value:Get()
        end
        setValue = resolveSetter(self._props.Value)
    else
        getValue, setValue = scope.Value(self._props.Value or 0)
    end
    
    local min = resolveValue(self._props.Min) or 0
    local max = resolveValue(self._props.Max) or 100
    local step = self._props.Step
    local activeColor = self._props.ActiveColor or activeTheme.Colors.Accent

    local getDragging, setDragging = scope.Value(false)
    local sliderRef = scope.Ref()

    local fillScale = scope.Spring(
        scope.Computed(function()
            local currentVal = resolveValue(getValue()) or min
            local fraction = math.clamp((currentVal - min) / (max - min), 0, 1)
            return fraction
        end),
        40, 1
    )

    local function updateValue(input)
        local frame = sliderRef:Get()
        if not frame then return end
        
        local x = math.clamp(input.Position.X - frame.AbsolutePosition.X, 0, frame.AbsoluteSize.X)
        local fraction = x / frame.AbsoluteSize.X
        
        local newValue = min + fraction * (max - min)
        if step then
            newValue = math.floor((newValue / step) + 0.5) * step
        end
        newValue = math.clamp(newValue, min, max)
        
        if setValue then setValue(newValue) end
        if self._props.OnChanged then
            self._props.OnChanged(newValue)
        end
    end

    local trackColor = scope.Computed(function()
        return activeTheme.Colors.PrimaryDark()
    end)

    return scope:TextButton {
        [Weave.Ref] = sliderRef,
        Name = self._props.Name or "Slider",
        Size = self._props.Size or UDim2.fromScale(1, 1),
        Position = self._props.Position,
        AnchorPoint = self._props.AnchorPoint,
        BackgroundColor3 = trackColor,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = self._props.LayoutOrder,
        ZIndex = self._props.ZIndex,
        
        [Weave.OnEvent("InputBegan")] = function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setDragging(true)
                updateValue(input)
            end
        end,
        
        [Weave.OnEvent("InputChanged")] = function(input)
            if getDragging() then
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    updateValue(input)
                end
            end
        end,
        
        [Weave.OnEvent("InputEnded")] = function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setDragging(false)
            end
        end,

        [Weave.Children] = {
            scope:Corner { CornerRadius = UDim.new(1, 0) },
            
            -- Fill
            scope:Frame {
                Name = "Fill",
                Size = scope.Computed(function()
                    return UDim2.fromScale(resolveValue(fillScale) or 0, 1)
                end),
                BackgroundColor3 = activeColor,
                ZIndex = scope.Computed(function() 
                    local z = self._props.ZIndex
                    return (type(z) == "function" and z() or z) or 1 
                end),
                [Weave.Children] = {
                    scope:Corner { CornerRadius = UDim.new(1, 0) }
                }
            },
            
            -- Knob
            scope:Frame {
                Name = "Knob",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = scope.Computed(function()
                    return UDim2.fromScale(resolveValue(fillScale) or 0, 0.5)
                end),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = scope.Computed(function() 
                    local z = self._props.ZIndex
                    return ((type(z) == "function" and z() or z) or 1) + 1 
                end),
                [Weave.Children] = {
                    scope:Corner { CornerRadius = UDim.new(1, 0) }
                }
            }
        }
    }
end

return Slider
