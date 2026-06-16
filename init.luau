local Theme = require(script.Theme)

local WeaveKit = {
    -- Theme API
    setTheme = Theme.setTheme,
    getTheme = Theme.getTheme,
    ThemeProvider = require(script.ThemeProvider),
    GradientPresets = require(script.GradientPresets),

    -- Atoms
    Row = require(script.Atoms.Row),
    Column = require(script.Atoms.Column),
    Text = require(script.Atoms.Text),
    Icon = require(script.Atoms.Icon),
    Container = require(script.Atoms.Container),
    Button = require(script.Atoms.Button),
    Divider = require(script.Atoms.Divider),
    Badge = require(script.Atoms.Badge),
    Spacer = require(script.Atoms.Spacer),
    Circle = require(script.Atoms.Circle),
    Image = require(script.Atoms.Image),

    -- Molecules
    PillButton = require(script.Molecules.PillButton),
    ProgressBar = require(script.Molecules.ProgressBar),
    IconTile = require(script.Molecules.IconTile),
    TextInput = require(script.Molecules.TextInput),
    Toggle = require(script.Molecules.Toggle),
    Checkbox = require(script.Molecules.Checkbox),
    ListItem = require(script.Molecules.ListItem),
    Slider = require(script.Molecules.Slider),
    Avatar = require(script.Molecules.Avatar),
    Toast = require(script.Molecules.Toast),
    Tabs = require(script.Molecules.Tabs),

    -- Organisms
    Window = require(script.Organisms.Window),
    Card = require(script.Organisms.Card),
    Modal = require(script.Organisms.Modal),
    Dropdown = require(script.Organisms.Dropdown),
    Tooltip = require(script.Organisms.Tooltip),
    VirtualGrid = require(script.Organisms.VirtualGrid),
    ColorPicker = require(script.Organisms.ColorPicker),
    ActionMenu = require(script.Organisms.ActionMenu),
    ThreePaneLayout = require(script.Organisms.ThreePaneLayout),
    ListPane = require(script.Organisms.ListPane),
}

return WeaveKit
