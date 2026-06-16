local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weave = require(ReplicatedStorage.Libraries.Weave)
local Theme = require(script.Parent.Theme)

-- ═══════════════════════════════════════════════════════════════════════════════
-- THEME PROVIDER
--
-- Wrapper component that applies a theme preset to the WeaveKit theme engine.
-- Usage:
--   ThemeProvider(scope, {
--       Theme = DarkTheme,             -- static table from a preset file
--       ThemeState = someWeaveValue,    -- OR reactive: re-applies on change
--       [Weave.Children] = { ... },
--   })
-- ═══════════════════════════════════════════════════════════════════════════════

local ThemeProvider = setmetatable({}, {
    __call = function(_, scope, props)
        local children = props[Weave.Children] or props.Children

        -- Static preset: apply once at mount time
        if props.Theme and type(props.Theme) == "table" then
            Theme.setTheme(props.Theme)
        end

        -- Reactive preset: re-apply whenever the state changes
        if props.ThemeState then
            scope.Effect(function(use)
                local preset = use(props.ThemeState)
                if preset then
                    Theme.setTheme(preset)
                end
            end)
        end

        return scope.Fragment(children or {})
    end
})

return ThemeProvider
