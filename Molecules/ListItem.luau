local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Builder = require(script.Parent.Parent.Builder)
local Theme = require(script.Parent.Parent.Theme)

local ListItem = setmetatable({}, {
    __index = Builder,
    __call = function(t, scope, props)
        local inst = t.new(scope)
        if not props then return inst:Build() end
        
        if props.Text then inst._props.Text = props.Text end
        if props.IsSelected then inst._props.IsSelected = props.IsSelected end
        if props.OnActivated then inst._props.OnActivated = props.OnActivated end
        
        if props.Size then inst:SetSize(props.Size) end
        if props.LayoutOrder then inst:SetLayoutOrder(props.LayoutOrder) end
        if props.Padding then inst._props.Padding = props.Padding end
        
        return inst:Build()
    end
})
ListItem.__index = ListItem

function ListItem.new(scope: Weave.Scope)
    local self = setmetatable(Builder.new(scope), ListItem)
    self._props.IsSelected = false
    self._props.Text = ""
    return self
end

function ListItem:Build()
    local scope = self._scope
    local activeTheme = Theme.getTheme()
    
    local Text = require(script.Parent.Parent.Atoms.Text)
    local Button = require(script.Parent.Parent.Atoms.Button)

    local isSelected = self._props.IsSelected
    local getHovered, setHovered = scope.Value(false)
    
    local bgColor = scope.Computed(function()
        local sel = type(isSelected) == "function" and isSelected() or isSelected
        if sel then
            return activeTheme.Colors.Accent()
        end
        return getHovered() and activeTheme.Colors.Highlight() or activeTheme.Colors.Surface()
    end)
    
    local textColor = scope.Computed(function()
        local sel = type(isSelected) == "function" and isSelected() or isSelected
        if sel then
            return activeTheme.Colors.TextPrimary()
        end
        return activeTheme.Colors.TextLight()
    end)
    
    return Button(scope, {
        Size = self._props.Size or UDim2.new(1, 0, 0, 44),
        CornerRadius = UDim.new(0, 8),
        BackgroundColor3 = bgColor,
        Padding = self._props.Padding or UDim.new(0, 10),
        LayoutOrder = self._props.LayoutOrder,
        OnActivated = self._props.OnActivated,
        OnMouseEnter = function() setHovered(true) end,
        OnMouseLeave = function() setHovered(false) end,
        [Weave.Children] = {
            Text(scope, {
                Text = self._props.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.fromScale(1, 1),
                TextColor3 = textColor,
                Font = activeTheme.Fonts.Body,
                MaxSize = 16,
                MinSize = 10,
            })
        }
    })
end

return ListItem
