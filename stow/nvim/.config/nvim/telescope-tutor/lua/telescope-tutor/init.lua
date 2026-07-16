-- telescope-tutor/init.lua
-- Telescope Tutor: an interactive TUI game for learning Telescope keymaps.
-- :TelescopeTutor          — open the main menu
-- :TelescopeTutor reset    — wipe progress

local M = {}

-- ─── Constants ────────────────────────────────────────────────────────────────
local W = 56 -- window inner width
local SAVE = vim.fn.stdpath('data') .. '/telescope-tutor-progress.json'
local MODULES = require('telescope-tutor.lessons')

-- Total XP available
local MAX_XP = 0
for _, mod in ipairs(MODULES) do
  for _, ch in ipairs(mod.challenges) do
    MAX_XP = MAX_XP + (ch.xp or 100)
  end
end

-- ─── State ────────────────────────────────────────────────────────────────────
local S = {
  win = nil, buf = nil,         -- current tutor window
  hint_win = nil, hint_buf = nil, -- corner "press the key" hint
  module_idx = 1,
  challenge_idx = 1,
  xp = 0,
  completed = {},               -- ["m.c"] = { stars=N, xp=N }
  -- keymap challenge live state
  intercepted_key = nil,
  intercepted_orig = nil,
  intercept_au = nil,           -- autocmd id for telescope close watcher
  challenge_start = nil,
  -- pending success data (shown after telescope closes)
  pending = nil,
}

-- ─── Persistence ──────────────────────────────────────────────────────────────
local function save()
  local ok, encoded = pcall(vim.fn.json_encode, {
    xp = S.xp,
    completed = S.completed,
    module_idx = S.module_idx,
    challenge_idx = S.challenge_idx,
  })
  if ok then
    vim.fn.writefile({ encoded }, SAVE)
  end
end

local function load()
  local ok, lines = pcall(vim.fn.readfile, SAVE)
  if not ok or #lines == 0 then return end
  local ok2, data = pcall(vim.fn.json_decode, table.concat(lines, ''))
  if not ok2 or type(data) ~= 'table' then return end
  S.xp = data.xp or 0
  S.completed = data.completed or {}
  S.module_idx = data.module_idx or 1
  S.challenge_idx = data.challenge_idx or 1
end

-- ─── UI helpers ───────────────────────────────────────────────────────────────
local function close(win_field, buf_field)
  win_field = win_field or 'win'
  buf_field = buf_field or 'buf'
  if S[win_field] and vim.api.nvim_win_is_valid(S[win_field]) then
    pcall(vim.api.nvim_win_close, S[win_field], true)
  end
  S[win_field] = nil
  S[buf_field] = nil
end

local function close_all()
  close('win', 'buf')
  close('hint_win', 'hint_buf')
end

-- Open a centered floating window. Returns (buf, win).
local function float(lines, title, opts)
  opts = opts or {}
  local width = opts.width or W
  local height = #lines
  local row = opts.row or math.max(0, math.floor((vim.o.lines - height - 4) / 2))
  local col = opts.col or math.max(0, math.floor((vim.o.columns - width - 2) / 2))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'telescope-tutor'

  local win = vim.api.nvim_open_win(buf, opts.focus ~= false, {
    relative = 'editor',
    row = row, col = col,
    width = width, height = height,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. title .. ' ',
    title_pos = 'center',
    focusable = opts.focus ~= false,
    noautocmd = true,
    zindex = opts.zindex or 50,
  })
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].cursorline = false

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  return buf, win
end

local function map(buf, key, fn)
  vim.keymap.set('n', key, fn, { buffer = buf, nowait = true, silent = true })
end

-- ─── Render helpers ───────────────────────────────────────────────────────────
local function stars_str(n)
  return (n >= 3 and '★★★' or n == 2 and '★★☆' or '★☆☆')
end

local function xp_bar()
  local bar_w = W - 14
  local filled = S.xp >= MAX_XP and bar_w
    or math.floor((S.xp / MAX_XP) * bar_w)
  local empty = bar_w - filled
  return string.format('  XP %s%s  %d/%d',
    string.rep('█', filled), string.rep('░', empty), S.xp, MAX_XP)
end

local function dot_progress(current, total)
  local parts = {}
  for i = 1, total do
    parts[#parts + 1] = (i < current and '●' or i == current and '◉' or '○')
  end
  return table.concat(parts, ' ')
end

local function count_completed_in(mod_idx)
  local n = 0
  for j = 1, #MODULES[mod_idx].challenges do
    if S.completed[mod_idx .. '.' .. j] then n = n + 1 end
  end
  return n
end

-- ─── Menu ─────────────────────────────────────────────────────────────────────
local function show_menu()
  close_all()
  local total_done = 0
  for k in pairs(S.completed) do
    if type(k) == 'string' then total_done = total_done + 1 end
  end
  local total_ch = 0
  for _, m in ipairs(MODULES) do total_ch = total_ch + #m.challenges end

  local lines = {
    '',
    '         🔭  TELESCOPE  TUTOR',
    '',
    xp_bar(),
    string.format('  %d / %d challenges complete', total_done, total_ch),
    '',
    '  ' .. string.rep('─', W - 4),
    '',
  }

  for i, mod in ipairs(MODULES) do
    local done = count_completed_in(i)
    local all_done = done == #mod.challenges
    local status = all_done and '✓' or (done > 0 and '▶' or '○')
    local cursor = (i == S.module_idx) and '▶ ' or '  '
    lines[#lines + 1] = string.format('  %s%s %s  %-20s  %d/%d',
      cursor, status, mod.icon, mod.name, done, #mod.challenges)
    if i == S.module_idx then
      lines[#lines + 1] = '     ' .. mod.desc
      lines[#lines + 1] = ''
    end
  end

  lines[#lines + 1] = '  ' .. string.rep('─', W - 4)
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  j/k  navigate   Enter  start   q  close'
  lines[#lines + 1] = ''

  local buf, win = float(lines, '🔭 Telescope Tutor', { focus = true })
  S.win, S.buf = win, buf

  map(buf, 'q',     close_all)
  map(buf, '<Esc>', close_all)
  map(buf, 'j', function()
    S.module_idx = (S.module_idx % #MODULES) + 1
    -- Jump to first incomplete challenge in selected module
    S.challenge_idx = 1
    for j = 1, #MODULES[S.module_idx].challenges do
      if not S.completed[S.module_idx .. '.' .. j] then
        S.challenge_idx = j; break
      end
    end
    show_menu()
  end)
  map(buf, 'k', function()
    S.module_idx = ((S.module_idx - 2) % #MODULES) + 1
    S.challenge_idx = 1
    for j = 1, #MODULES[S.module_idx].challenges do
      if not S.completed[S.module_idx .. '.' .. j] then
        S.challenge_idx = j; break
      end
    end
    show_menu()
  end)
  map(buf, '<CR>', function()
    close_all()
    M.show_challenge(S.module_idx, S.challenge_idx)
  end)
end

-- ─── Challenge screen ─────────────────────────────────────────────────────────
function M.show_challenge(mi, ci)
  close_all()
  S.module_idx, S.challenge_idx = mi, ci
  local mod = MODULES[mi]
  if not mod then return end
  local ch = mod.challenges[ci]
  if not ch then return end

  local done_key = mi .. '.' .. ci
  local result = S.completed[done_key]

  local lines = {
    '',
    string.format('  %s  Module %d/%d · %s', mod.icon, mi, #MODULES, mod.name),
    '',
    '  ' .. dot_progress(ci, #mod.challenges),
    '',
    '  ' .. string.rep('─', W - 4),
    '',
    '  ' .. ch.title:upper() .. ': ' .. ch.mission,
    '',
  }

  for _, line in ipairs(ch.body) do
    lines[#lines + 1] = '  ' .. line
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = '  ' .. string.rep('─', W - 4)
  lines[#lines + 1] = ''

  if result then
    lines[#lines + 1] = string.format('  ✓  Completed  %s  +%d xp',
      stars_str(result.stars), result.xp)
    lines[#lines + 1] = ''
    lines[#lines + 1] = '  Enter  try again   n  next challenge   q  menu'
  else
    if ch.type == 'keymap' then
      lines[#lines + 1] = '  Enter  start timer + activate intercept'
      lines[#lines + 1] = '  (close this window, then press the key)'
    else
      lines[#lines + 1] = '  Press 1 / 2 / 3 / 4 to answer'
    end
    lines[#lines + 1] = '  q / Esc  back to menu'
  end

  lines[#lines + 1] = ''

  local buf, win = float(lines, 'Challenge ' .. ci .. '/' .. #mod.challenges, { focus = true })
  S.win, S.buf = win, buf

  map(buf, 'q',     show_menu)
  map(buf, '<Esc>', show_menu)

  if result then
    map(buf, '<CR>', function()
      S.completed[done_key] = nil
      S.xp = math.max(0, S.xp - result.xp)
      M.show_challenge(mi, ci)
    end)
    map(buf, 'n', function() close_all(); M.advance() end)
  else
    if ch.type == 'keymap' then
      map(buf, '<CR>', function()
        close_all()
        M.start_keymap_challenge(ch, mi, ci)
      end)
    elseif ch.type == 'quiz' then
      for _, a in ipairs({ '1', '2', '3', '4' }) do
        map(buf, a, function() M.check_quiz(ch, a, mi, ci) end)
      end
    end
  end
end

-- ─── Keymap challenge ─────────────────────────────────────────────────────────
function M.start_keymap_challenge(ch, mi, ci)
  -- Small corner hint window
  local key_display = ch.key:gsub('<leader>', '<Space>')
  local hint_lines = {
    '',
    '  ⌨   Press ' .. key_display,
    '  Esc / :TelescopeTutor  abort',
    '',
  }
  local hbuf, hwin = float(hint_lines, 'Go!', {
    focus = false,
    row = 1,
    col = vim.o.columns - #hint_lines[2] - 6,
    width = math.max(28, #hint_lines[2] + 4),
    zindex = 200,
  })
  S.hint_win, S.hint_buf = hwin, hbuf

  -- Save existing mapping
  local orig = vim.fn.maparg(ch.key, 'n', false, true)
  S.intercepted_key = ch.key
  S.intercepted_orig = orig
  S.challenge_start = vim.uv.hrtime()

  -- Install intercept
  vim.keymap.set('n', ch.key, function()
    M.on_keymap_pressed(ch, mi, ci)
  end, { nowait = true, silent = true, desc = '[tutor] intercept ' .. ch.key })

  -- Safety timeout: restore after 5 minutes
  vim.defer_fn(function()
    if S.intercepted_key == ch.key then
      M.restore_keymap()
      close('hint_win', 'hint_buf')
    end
  end, 300000)
end

function M.on_keymap_pressed(ch, mi, ci)
  local elapsed = (vim.uv.hrtime() - (S.challenge_start or vim.uv.hrtime())) / 1e9
  local stars = 1
  if ch.time_stars then
    if elapsed < ch.time_stars[1] then stars = 3
    elseif elapsed < ch.time_stars[2] then stars = 2
    end
  end

  M.restore_keymap()
  close('hint_win', 'hint_buf')

  -- Stash success data; show it after Telescope closes
  S.pending = { mi = mi, ci = ci, stars = stars, xp = ch.xp, tip = ch.tip }

  -- Watch for Telescope prompt window to close
  local au_id
  au_id = vim.api.nvim_create_autocmd('WinClosed', {
    callback = function(ev)
      local w = tonumber(ev.match)
      if not w then return end
      local ok, b = pcall(vim.api.nvim_win_get_buf, w)
      if ok and vim.bo[b] and vim.bo[b].filetype == 'TelescopePrompt' then
        vim.api.nvim_del_autocmd(au_id)
        S.intercept_au = nil
        vim.defer_fn(function()
          if S.pending then M.show_success(S.pending) end
        end, 80)
      end
    end,
  })
  S.intercept_au = au_id

  -- Execute original mapping
  local orig = S.intercepted_orig
  if orig and type(orig.callback) == 'function' then
    orig.callback()
  elseif orig and orig.rhs and orig.rhs ~= '' then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(orig.rhs, true, false, true), 'm', false)
  end
end

function M.restore_keymap()
  local key = S.intercepted_key
  if not key then return end
  pcall(vim.keymap.del, 'n', key)
  local orig = S.intercepted_orig
  if orig and orig.lhs and orig.lhs ~= '' then
    local opts = {
      noremap = orig.noremap == 1,
      silent = orig.silent == 1,
      expr = orig.expr == 1,
      nowait = orig.nowait == 1,
      desc = orig.desc,
    }
    if type(orig.callback) == 'function' then
      pcall(vim.keymap.set, 'n', orig.lhs, orig.callback, opts)
    elseif orig.rhs and orig.rhs ~= '' then
      pcall(vim.keymap.set, 'n', orig.lhs, orig.rhs, opts)
    end
  end
  S.intercepted_key = nil
  S.intercepted_orig = nil
end

-- ─── Quiz challenge ───────────────────────────────────────────────────────────
function M.check_quiz(ch, answer, mi, ci)
  if answer == ch.answer then
    close_all()
    M.show_success({ mi = mi, ci = ci, stars = 3, xp = ch.xp, explanation = ch.explanation })
  else
    -- Flash wrong-answer feedback by rewriting the bottom of the window
    if S.buf and vim.api.nvim_buf_is_valid(S.buf) then
      local lines = vim.api.nvim_buf_get_lines(S.buf, 0, -1, false)
      -- Find and replace the instruction line
      for i = #lines, 1, -1 do
        if lines[i]:match('Press 1') then
          vim.bo[S.buf].modifiable = true
          lines[i] = '  ✗  Wrong — try again!'
          vim.api.nvim_buf_set_lines(S.buf, 0, -1, false, lines)
          vim.bo[S.buf].modifiable = false
          break
        end
      end
    end
  end
end

-- ─── Success screen ───────────────────────────────────────────────────────────
function M.show_success(data)
  S.pending = nil
  close_all()

  local mi, ci = data.mi, data.ci
  local ch = MODULES[mi].challenges[ci]
  local done_key = mi .. '.' .. ci
  local already = S.completed[done_key]

  if not already then
    S.xp = S.xp + data.xp
    S.completed[done_key] = { stars = data.stars, xp = data.xp }
    save()
  end

  local mod = MODULES[mi]
  local mod_done = count_completed_in(mi) == #mod.challenges

  local lines = {
    '',
    '           ✅  CHALLENGE COMPLETE!',
    '',
    '              ' .. stars_str(data.stars),
    '',
    string.format('  +%d XP        Total: %d / %d', data.xp, S.xp, MAX_XP),
    '',
    '  ' .. string.rep('─', W - 4),
  }

  local tip_src = data.tip or data.explanation
  if tip_src then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '  💡 TIP'
    for line in (tip_src:gsub('^%s+', '') .. '\n'):gmatch('([^\n]*)\n') do
      lines[#lines + 1] = '  ' .. line
    end
  end

  if mod_done then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '  ' .. string.rep('─', W - 4)
    lines[#lines + 1] = ''
    lines[#lines + 1] = string.format('  🎉  MODULE COMPLETE: %s %s!', mod.icon, mod.name)
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = '  ' .. string.rep('─', W - 4)
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  Enter / n  next challenge        q  menu'
  lines[#lines + 1] = ''

  local buf, win = float(lines, '⭐ Result', { focus = true, zindex = 100 })
  S.win, S.buf = win, buf

  map(buf, 'q',     show_menu)
  map(buf, '<Esc>', show_menu)
  map(buf, '<CR>',  function() close_all(); M.advance() end)
  map(buf, 'n',     function() close_all(); M.advance() end)
end

-- ─── Navigation ───────────────────────────────────────────────────────────────
function M.advance()
  local mod = MODULES[S.module_idx]
  if S.challenge_idx < #mod.challenges then
    S.challenge_idx = S.challenge_idx + 1
  elseif S.module_idx < #MODULES then
    S.module_idx = S.module_idx + 1
    S.challenge_idx = 1
  else
    show_menu()
    return
  end
  save()
  M.show_challenge(S.module_idx, S.challenge_idx)
end

-- Called on :TelescopeTutor — also used to abort an active challenge
local function open_tutor()
  -- Clean up any live intercept
  if S.intercepted_key then M.restore_keymap() end
  if S.intercept_au then
    pcall(vim.api.nvim_del_autocmd, S.intercept_au)
    S.intercept_au = nil
  end
  S.pending = nil
  close_all()
  show_menu()
end

-- ─── Setup ────────────────────────────────────────────────────────────────────
function M.setup()
  load()

  -- Fast-forward module/challenge index to first incomplete
  local found = false
  for i, mod in ipairs(MODULES) do
    for j = 1, #mod.challenges do
      if not S.completed[i .. '.' .. j] then
        S.module_idx, S.challenge_idx = i, j
        found = true; break
      end
    end
    if found then break end
  end

  vim.api.nvim_create_user_command('TelescopeTutor', function(args)
    if args.args == 'reset' then
      S.xp = 0
      S.completed = {}
      S.module_idx = 1
      S.challenge_idx = 1
      save()
      vim.notify('Telescope Tutor: progress reset', vim.log.levels.INFO)
    else
      open_tutor()
    end
  end, {
    nargs = '?',
    complete = function() return { 'reset' } end,
    desc = 'Open Telescope Tutor',
  })
end

return M
