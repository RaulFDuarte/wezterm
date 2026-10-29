local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- rose-pine-moon as the base, with a lavender-tinted foreground and a warm
-- cursor so text picks up the gradient's indigo/pine mood.
local scheme = wezterm.color.get_builtin_schemes()["rose-pine-moon"]
scheme.foreground = "#cbb8ff"
scheme.cursor_bg = "#f6c177"
scheme.cursor_border = "#f6c177"
scheme.cursor_fg = "#232136"
scheme.selection_bg = "#4a4570"
scheme.selection_fg = "#ffffff"
scheme.split = "#c4a7e7"
scheme.tab_bar = {
	background = "#231f3d",
	active_tab = { bg_color = "#c4a7e7", fg_color = "#232136", intensity = "Bold" },
	inactive_tab = { bg_color = "#2b2347", fg_color = "#908caa" },
	inactive_tab_hover = { bg_color = "#393552", fg_color = "#cbb8ff", italic = true },
	new_tab = { bg_color = "#231f3d", fg_color = "#908caa" },
	new_tab_hover = { bg_color = "#393552", fg_color = "#cbb8ff" },
}
config.colors = scheme
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 13.0
config.window_background_opacity = 0.95
-- Diagonal gradient in rose-pine-moon tones: indigo (top-left) to deep pine
-- (bottom-right). Oklab blending + noise avoid visible banding.
config.window_background_gradient = {
	colors = { "#0F0A1C", "#1E1135", "#3B2261" },
	orientation = { Linear = { angle = -45.0 } },
	interpolation = "Linear",
	blend = "Oklab",
	noise = 48,
}
config.hide_tab_bar_if_only_one_tab = true
-- WezTerm's own Wayland frame is square on GNOME. Running through XWayland
-- lets mutter draw the titlebar, which gives the window rounded corners.
config.enable_wayland = false
config.window_decorations = "TITLE|RESIZE"
config.use_fancy_tab_bar = true
config.window_padding = { left = 14, right = 14, top = 10, bottom = 10 }
config.window_frame = {
	font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
	font_size = 11.0,
	active_titlebar_bg = "#231f3d",
	inactive_titlebar_bg = "#1c1a30",
}
config.cursor_blink_rate = 0
config.default_cursor_style = "SteadyBar"
config.scrollback_lines = 10000

-- Dim unfocused windows so the focused one is obvious at a glance.
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.88

-- get_config_overrides() hands back a copy, so the current value is never the
-- same table we last stored; compare the fields instead of the identity.
local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end
	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity
	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- Only write when one of the two values we own actually changes; a redundant
	-- set_config_overrides() call would trigger another config reload.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

-- Cheat sheet: F1 opens a searchable list; picking an entry runs it
-- (section headers and key-only hints are no-ops).
local act = wezterm.action
local NOP = act.Nop
local CHEATSHEET = {
	{ "── ABAS ──", NOP },
	{ "Nova aba                      Ctrl+Shift+T", act.SpawnTab("CurrentPaneDomain") },
	{ "Fechar aba                    Ctrl+Shift+W", act.CloseCurrentTab({ confirm = true }) },
	{ "Próxima aba                   Ctrl+Tab", act.ActivateTabRelative(1) },
	{ "Aba anterior                  Ctrl+Shift+Tab", act.ActivateTabRelative(-1) },
	{ "Mover aba p/ direita          Ctrl+Shift+PgDn", act.MoveTabRelative(1) },
	{ "Mover aba p/ esquerda         Ctrl+Shift+PgUp", act.MoveTabRelative(-1) },
	{ "Ir direto p/ aba N (1-9)      Alt+1 … Alt+9", NOP },

	{ "── PAINÉIS ──", NOP },
	{ "Dividir lado a lado           Ctrl+Shift+Alt+%", act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ "Dividir um embaixo do outro   Ctrl+Shift+Alt+\"", act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ "Fechar painel                 Ctrl+Shift+Q  (ou exit / Ctrl+D)", act.CloseCurrentPane({ confirm = true }) },
	{ "Foco: esquerda                Ctrl+Shift+←", act.ActivatePaneDirection("Left") },
	{ "Foco: direita                 Ctrl+Shift+→", act.ActivatePaneDirection("Right") },
	{ "Foco: cima                    Ctrl+Shift+↑", act.ActivatePaneDirection("Up") },
	{ "Foco: baixo                   Ctrl+Shift+↓", act.ActivatePaneDirection("Down") },
	{ "Escolher painel por letra     (seletor)", act.PaneSelect({ mode = "Activate" }) },
	{ "Redimensionar (modo)          Ctrl+Shift+E → h/j/k/l, Esc sai", act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{ "Zoom no painel (alterna)      Ctrl+Shift+Z", act.TogglePaneZoomState },

	{ "── TEXTO E BUSCA ──", NOP },
	{ "Copiar                        Ctrl+Shift+C", NOP },
	{ "Colar                         Ctrl+Shift+V", act.PasteFrom("Clipboard") },
	{ "Copy mode (seleção vim)       Ctrl+Shift+X", act.ActivateCopyMode },
	{ "   dentro: mover              h j k l · w b e · 0 $ · gg G", act.ActivateCopyMode },
	{ "   dentro: selecionar         v char · V linha · Ctrl+v bloco", act.ActivateCopyMode },
	{ "   dentro: copiar / sair      y copia e sai · Esc sai · / busca", act.ActivateCopyMode },
	{ "Quick select (URLs/hashes)    Ctrl+Shift+Space", act.QuickSelect },
	{ "Buscar no scrollback          Ctrl+Shift+F", act.Search({ CaseInSensitiveString = "" }) },
	{ "Rolar página p/ cima          Shift+PgUp", act.ScrollByPage(-1) },
	{ "Rolar página p/ baixo         Shift+PgDn", act.ScrollByPage(1) },
	{ "Limpar scrollback             Ctrl+Shift+K", act.ClearScrollback("ScrollbackOnly") },
	{ "Seletor Unicode / emoji       Ctrl+Shift+U", act.CharSelect },

	{ "── JANELA E FONTE ──", NOP },
	{ "Aumentar fonte                Ctrl+=", act.IncreaseFontSize },
	{ "Diminuir fonte                Ctrl+-", act.DecreaseFontSize },
	{ "Resetar fonte                 Ctrl+0", act.ResetFontSize },
	{ "Tela cheia                    Alt+Enter", act.ToggleFullScreen },

	{ "── GERAL ──", NOP },
	{ "Paleta de comandos            Ctrl+Shift+P", act.ActivateCommandPalette },
	{ "Recarregar config             Ctrl+Shift+R", act.ReloadConfiguration },
	{ "Debug overlay (Lua)           Ctrl+Shift+L", act.ShowDebugOverlay },
	{ "Esta lista                    F1", NOP },
}

local cheatsheet_choices = {}
for i, entry in ipairs(CHEATSHEET) do
	cheatsheet_choices[i] = { id = tostring(i), label = entry[1] }
end

config.keys = {
	{ key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "e", mods = "CTRL|SHIFT", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{
		key = "F1",
		action = act.InputSelector({
			title = "Atalhos (Enter executa, Esc fecha)",
			choices = cheatsheet_choices,
			fuzzy = true,
			action = wezterm.action_callback(function(window, pane, id)
				if id then
					window:perform_action(CHEATSHEET[tonumber(id)][2], pane)
				end
			end),
		}),
	},
}

-- Ctrl+Alt+arrows is taken by GNOME workspaces, so resizing gets its own mode:
-- Ctrl+Shift+E, then h/j/k/l or arrows (repeat freely), Esc/Enter to leave.
config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 3 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 3 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 3 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 3 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

-- Persist windows/tabs/panes (layout and cwd, not running processes) so the
-- next launch comes back as it was. The plugin only saves while the GUI is
-- alive, so the last state on disk is at most SAVE_INTERVAL_SECONDS old.
local SAVE_INTERVAL_SECONDS = 30
-- Vendored (see vendor/resurrect/README): the upstream plugin loader pulls in
-- another plugin that reloads the config in a loop.
local STATE_DIR = os.getenv("WEZTERM_RESURRECT_DIR") or (wezterm.home_dir .. "/.local/state/wezterm-resurrect/")
package.path = package.path .. ";" .. wezterm.config_dir .. "/vendor/?.lua"
local resurrect = {
	state_manager = require("resurrect.state_manager"),
	workspace_state = require("resurrect.workspace_state"),
}
resurrect.state_manager.change_state_save_dir(STATE_DIR)

-- Programs that are relaunched on restore (claude, opencode). Claude Code records its session id
-- per pid in ~/.claude/sessions, so each pane resumes its own conversation.
local pane_tree = require("resurrect.pane_tree")
pane_tree.resume_command = function(info)
	if not info then
		return nil
	end
	-- opencode keeps no per-pid session record; --continue picks the most recent
	-- session of the pane's directory, which is where the pane is restored.
	if info.name == "opencode" or (info.executable or ""):match("/opencode$") then
		return "opencode --continue"
	end
	if info.name ~= "claude" then
		return nil
	end
	local file = io.open(wezterm.home_dir .. "/.claude/sessions/" .. info.pid .. ".json", "r")
	if not file then
		return nil
	end
	local ok, session = pcall(wezterm.json_parse, file:read("*a"))
	file:close()
	if ok and session and session.sessionId then
		return "claude --resume " .. session.sessionId
	end
end

local function restore_pane(pane_tree_state)
	if pane_tree_state.resume then
		pane_tree_state.pane:send_text(pane_tree_state.resume .. "\r")
	else
		require("resurrect.tab_state").default_on_pane_restore(pane_tree_state)
	end
end
resurrect.state_manager.on_pane_restore = restore_pane

-- Driven by update-status (which only fires while a window exists) instead of
-- a timer: timers started during config evaluation do not survive reloads.
config.status_update_interval = 5000
wezterm.on("update-status", function()
	local now = os.time()
	if now - (wezterm.GLOBAL.last_layout_save or 0) < SAVE_INTERVAL_SECONDS then
		return
	end
	wezterm.GLOBAL.last_layout_save = now
	resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
	resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), "workspace")
end)

-- Centered at ~89% of the screen width and ~82% of its height, leaving a
-- comfortable margin on every side. Falls back to the default size on error.
local function center_window(gui_window, scale)
	pcall(function()
		local screen = wezterm.gui.screens().active
		local width, height
		if scale then
			width = math.floor(screen.width * 0.89)
			height = math.floor(screen.height * 0.82)
			gui_window:set_inner_size(width, height)
		else
			local dims = gui_window:get_dimensions()
			width, height = dims.pixel_width, dims.pixel_height
		end
		gui_window:set_position(screen.x + (screen.width - width) // 2, screen.y + (screen.height - height) // 2)
	end)
end

-- Restore the saved layout; on first run (or unreadable state) open a fresh window.
wezterm.on("gui-startup", function(cmd)
	local restored = not cmd and resurrect.state_manager.resurrect_on_gui_startup()
	if restored and #wezterm.mux.all_windows() > 0 then
		for _, mux_window in ipairs(wezterm.mux.all_windows()) do
			center_window(mux_window:gui_window(), false)
		end
		return
	end
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	center_window(window:gui_window(), true)
end)

return config
