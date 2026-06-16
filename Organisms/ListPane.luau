local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Card = require(script.Parent.Card)
local Column = require(script.Parent.Parent.Atoms.Column)

local function ListPane(scope, props)
    return Card(scope, {
        Padding = props.CardPadding or { Offset = {16, 0} },
        IsScrollable = props.IsScrollable == nil and true or props.IsScrollable,
        Size = props.Size,
        LayoutOrder = props.LayoutOrder,
        BackgroundColor3 = props.BackgroundColor3,
        [Weave.Children] = {
            Column(scope, {
                Padding = props.ColumnPadding or { Offset = {0, 16} },
                Gap = props.Gap or UDim.new(0, 4),
                [Weave.Children] = props[Weave.Children]
            })
        }
    })
end

return ListPane
