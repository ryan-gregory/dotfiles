# AGENTS.md

Guidance for agents maintaining `~/.config/nvim`.

## Repo overview

- This repo is currently a near-stock `kickstart.nvim` setup.
- The main config lives in `init.lua`.
- `lazy.nvim` is the plugin manager.
- `lua/custom/plugins/` exists, but the `{ import = 'custom.plugins' }` line in `init.lua` is still commented out.
- Prefer preserving the stock Kickstart layout unless the user explicitly asks for a broader refactor.

## Default approach

- Make small, reversible changes.
- Keep existing Kickstart comments and structure unless the change clearly benefits from cleanup.
- Do not rewrite `init.lua` into a new architecture unless requested.
- Prefer adding customizations in new files over growing `init.lua` further.

## Where changes should go

- Core editor options, leader keys, or foundational behavior may live in `init.lua`.
- New plugin specs should usually go in `lua/custom/plugins/*.lua`.
- If adding the first real custom plugin file, also uncomment `{ import = 'custom.plugins' }` in `init.lua`.
- Filetype-specific behavior should prefer `after/ftplugin/<filetype>.lua` or `ftplugin/<filetype>.lua`.
- Always-on startup scripts belong in `plugin/` only when they truly need startup execution. Neovim's docs recommend using `lua/` modules plus `require(...)` for on-demand code.

## Neovim conventions to follow

- Consult Neovim help before changing editor behavior. Start with:
  - `:help lua-guide`
  - `:help init.lua`
  - `:help startup`
  - `:help stdpath()`
  - `:help 'runtimepath'`
  - `:help vim.keymap.set()`
  - `:help nvim_create_autocmd()`
  - `:help diagnostic-defaults`
  - `:help lsp`
  - `:help treesitter`
- Prefer `vim.keymap.set()` over legacy mapping commands in Lua.
- Prefer `vim.api.nvim_create_autocmd()` over stringly `:autocmd` from Lua.
- Prefer `vim.opt` for list-like and map-like options; use `vim.o`, `vim.bo`, and `vim.wo` when direct option access is clearer.
- Prefer `require(...)` modules under `lua/` for reusable logic, per `:help lua-guide`.
- Use `vim.notify`, errors, or visible diagnostics instead of silent failure when configuration code breaks.

## Plugin change guidelines

- Match existing Kickstart and `lazy.nvim` plugin-spec style.
- Reuse existing built-in Kickstart modules when they already cover the requested feature.
- Only add a plugin when built-in Neovim or an already-installed plugin does not solve the problem cleanly.
- When adding a plugin, include only the minimal config needed to make it useful.
- Avoid replacing major subsystems like completion, LSP, picker, or file explorer without explicit user intent.
- Treat `lazy-lock.json` as intentional state; update it only when plugin specs actually change.

## Validation

After config changes, validate with lightweight Neovim-native checks:

- Startup smoke test:
  - `nvim --headless "+qa"`
- Compare against a clean baseline when debugging startup or behavior:
  - `nvim --clean`
- Diagnose environment or provider issues:
  - `:checkhealth`
- Investigate startup regressions:
  - `nvim --startuptime /tmp/nvim-startup.log +qa`

If plugin specs change, also verify Neovim starts cleanly after the lockfile/plugin state is refreshed in the normal project workflow.

## Practical preferences for this repo

- Keep `tokyonight`, Telescope, LSP, completion, formatting, and Treesitter changes localized and easy to revert.
- If the user is still learning Neovim, prefer discoverable keymaps and documented defaults over clever abstractions.
- When suggesting a behavior change, include the exact path and keymaps affected.
- Favor changes that preserve readability for someone using Kickstart as a learning base.

## References consulted

This guide is based on Neovim's own documentation around startup config, Lua modules, and options handling, especially:

- `:help lua-guide`
- `:help starting`
- `:help options`
- `:help usr_05`
