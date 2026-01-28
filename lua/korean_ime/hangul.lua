local M = {}

M.mode = "en"

-- When finished with `finish(true)` it means we left the insert mode.
-- However, I think we still want to set the mode to "en" to further prevent any issues.
-- We thus save prevmode, and recover it when `begin(true)` is called (InsertEnter).
-- local prevmode = "en"

-- stylua: ignore start
-- TABLE{I,M,F} -- tables for initial, medial, final jamos
--                     0     1     2     3     4     5     6     7     8     9
local TABLEI = { [0]='ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
                     'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'}
local TABLEM = { [0]='ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ',
                     'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ',
                     'ㅣ'}
local TABLEF = { [0]='ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ',
                     'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ',
                     'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'}

-- TABLEC{M,F} -- mappings from keystrokes to medial/final compounds
--                Key consists of two elements (A * 100 + B).
local TABLECM = { [800]=9, [801]=10, [820]=11, [1304]=14, [1305]=15, [1320]=16,
                  [1820]=19}
local TABLECF = { [0]=1, [18]=2, [321]=4, [326]=5, [700]=8, [715]=9, [716]=10,
                  [718]=11, [724]=12, [725]=13, [726]=14, [1618]=17, [1818]=19}

-- TABLEFC -- reverse mapping from final jamo to compound elements & initial jamo
-- Legend: (A * 100 + B) * 100 + C
--         A and B are compound elements; if not compound, A should be 99.
--         C is equivalent initial jamo # or 99 (no equivalent jamo).
local TABLEFC = { [0]=990000,      1,    999, 990202,  31299,  31899, 990303, 990505,
                       70099,  70699,  70799,  70999,  71699,  71799,  71899, 990606,
                      990707, 160999, 990909, 180910, 991111, 991212, 991414, 991515,
                      991616, 991717, 991818}
-- stylua: ignore end

---Get a Hangeul syllable from serial (-1 to 11171)
local function get_syllable(serial)
  if vim.o.enc == "utf-8" then
    return vim.fn.nr2char(44033 + serial)
  else
    local code = 44033 + serial
    local s = vim.fn.nr2char(224 + math.floor(code / 4096))
      .. vim.fn.nr2char(128 + math.floor(code / 64) % 64)
      .. vim.fn.nr2char(128 + code % 64)
    return vim.fn.iconv(s, "utf-8", vim.o.enc)
  end
end

local syllable = {
  init = -1,
  med = -1,
  fin = -1,
  state = 0,
}

---Get current syllable's representation
M.keystrokes = function()
  local keys = ""
  if syllable.init < 0 then
    keys = (syllable.med < 0 and "" or TABLEM[syllable.med])
    keys = keys .. (syllable.fin < 0 and "" or TABLEF[syllable.fin])
  elseif syllable.med < 0 then
    keys = TABLEI[syllable.init]
    keys = keys .. (syllable.fin < 0 and "" or TABLEF[syllable.fin])
  else
    keys = get_syllable(syllable.init * 588 + syllable.med * 28 + syllable.fin)
  end
  return keys
end

---Update current syllable and return appropriate key sequences
---존재하는 글자에 따라 한번 혹은 두번 지운 후 글자 입력하는 방식임.
local function update_syllable(init, med, fin)
  local keys = ""
  if not (syllable.init < 0 and syllable.med < 0 and syllable.fin < 0) then
    keys = [[<C-H>]]
    if (syllable.init < 0 or syllable.med < 0) and syllable.fin >= 0 then
      keys = keys .. [[<C-H>]]
    end
  end
  syllable.init = init
  syllable.med = med
  syllable.fin = fin
  return keys .. M.keystrokes()
end

-------------------------------------------------------------------------------
-- KS X 5002 two-layered scheme (Dubeolsik standard)

-- Legend: A * 100 + B or -1 (not applicable)
--         Vowel if A is 99, where B is medial jamo #
--         Consonant otherwise, where A is initial # and B is final # (or 99)

-- stylua: ignore start
local MAP2s = { [0]=615, 9917, 1422, 1120,  499,  507, 1826, 9908, 9902, 9904,
                   9900, 9920, 9918, 9913, 9903, 9907,  899,  101,  203, 1019,
                   9906, 1725, 1399, 1624, 9912, 1523,   -1,   -1,   -1,   -1,
                     -1,   -1,  615, 9917, 1422, 1120,  306,  507, 1826, 9908,
                   9902, 9904, 9900, 9920, 9918, 9913, 9901, 9905,  716,    0,
                    203,  918, 9906, 1725, 1221, 1624, 9912, 1523,   -1,   -1,
                     -1,   -1}
-- stylua: ignore end

local function begin_2s()
  syllable.init = -1
  syllable.med = -1
  syllable.fin = -1
  syllable.state = 0
end

local function finish_2s()
  syllable.init = -1
  syllable.med = -1
  syllable.fin = -1
  syllable.state = 0
end

---@param key integer
local function compose_2s(key)
  if key < 65 or MAP2s[key - 65] < 0 then
    finish_2s()
    return vim.fn.nr2char(key)
  end
  local value1 = math.floor(MAP2s[key - 65] / 100)
  local value2 = MAP2s[key - 65] % 100
  local isvowel = (value1 == 99)

  if syllable.state == 1 then -- initial jamo is present
    if isvowel then
      syllable.state = 2
      return update_syllable(syllable.init, value2, -1)
    elseif 697015 % (value1 * 2 + 5) == 0 and value1 == syllable.init then
      return update_syllable(syllable.init + 1, -1, -1)
    end
  elseif syllable.state == 2 or syllable.state == 5 then -- medial jamo is present
    if isvowel then
      if TABLECM[syllable.med * 100 + value2] ~= nil then
        local newmedial = TABLECM[syllable.med * 100 + value2]
        return update_syllable(syllable.init, newmedial, -1)
      end
    elseif syllable.state == 2 and value2 ~= 99 then
      syllable.state = 3
      return update_syllable(syllable.init, syllable.med, value2)
    end
  elseif syllable.state == 3 or syllable.state == 4 then -- all jamo are present
    if isvowel then
      local prevfinal, nextinitial
      if syllable.state == 3 then
        prevfinal = -1
        nextinitial = TABLEFC[syllable.fin] % 100
      else
        prevfinal = math.floor(TABLEFC[syllable.fin] / 10000)
        nextinitial = math.floor(TABLEFC[syllable.fin] / 100 % 100)
      end
      local iresult = update_syllable(syllable.init, syllable.med, prevfinal)
      finish_2s()
      syllable.state = 2
      return iresult .. update_syllable(nextinitial, value2, -1)
    else
      if TABLECF[syllable.fin * 100 + value2] ~= nil then
        syllable.state = 4
        local newfinal = TABLECF[syllable.fin * 100 + value2]
        return update_syllable(syllable.init, syllable.med, newfinal)
      end
    end
  end

  finish_2s()
  if value1 == 99 then
    syllable.state = 5
    return update_syllable(-1, value2, -1)
  else
    syllable.state = 1
    return update_syllable(value1, -1, -1)
  end
end

local function revert_2s()
  if syllable.fin >= 0 then
    syllable.state = 2
    return update_syllable(syllable.init, syllable.med, -1)
  end
  if syllable.med >= 0 then
    syllable.state = (syllable.init < 0 and 0 or 1)
    return update_syllable(syllable.init, -1, -1)
  end
  syllable.state = 0
  if syllable.init >= 0 then
    return update_syllable(-1, -1, -1)
  else
    return [[<C-H>]]
  end
end

-------------------------------------------------------------------------

local internal = 0

local function begin(reset)
  if reset then
    internal = 0
  end
  if M.mode == "ko" then
    begin_2s()
  end
end

---Update current syllable from key input
local function compose(key)
  internal = internal + 1
  if M.mode == "ko" then
    return compose_2s(key)
  else
    return vim.fn.nr2char(key)
  end
end

---Undo one key input
local function revert()
  internal = internal + 1
  if M.mode == "ko" then
    return revert_2s()
  else
    return [[<C-H>]]
  end
end

---Finish, adjust automaton state and reset internal flag (if needed)
local function finish(reset)
  if M.mode == "ko" then
    finish_2s()
  end
  if reset then
    internal = 0
  end
end

---Clean up composition of current syllable
local function refresh()
  if internal > 0 then
    internal = internal - 1
    return
  end
  finish(false)
  begin(false)
end

------------------------------------------------------
---Alternate current input mode
M.change_mode = function()
  finish(false)
  M.mode = M.mode == "en" and "ko" or "en"
  begin(false)
  -- vim.bo.ro = vim.bo.ro -- force updating of status line
end

M.essential_mappings = function()
  local key = 33
  while key < 127 do
    vim.keymap.set(
      "i",
      "<Char-" .. key .. ">",
      (function(k)
        return function()
          return compose(k) -- Uses the value of k at the time of function creation
        end
      end)(key),
      { silent = true, expr = true, noremap = true, desc = "Korean-IME.nvim compose" }
    )
    key = key + 1
  end

  -- Fix: https://github.com/kiyoon/Korean-IME.nvim/issues/2
  vim.keymap.set("i", "<space>", function()
    finish_2s()
    return "<space>"
  end, { noremap = true, silent = true, expr = true, desc = "Korean-IME.nvim space" })

  vim.keymap.set("i", "<BS>", function()
    return revert()
  end, { noremap = true, silent = true, expr = true, desc = "Korean-IME.nvim backspace" })
  -- This is an unusal key (same as <BS>), thus the fact that a mapping exists probabily means we should not remap it.
  if vim.fn.maparg("<C-H>") == "" then
    vim.keymap.set("i", "<C-H>", function()
      return revert()
    end, { noremap = true, silent = true, expr = true, desc = "Korean-IME.nvim backspace" })
  end

  local augroup = vim.api.nvim_create_augroup("Hangul", { clear = true })
  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = augroup,
    callback = refresh,
  })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = augroup,
    callback = function()
      begin(true)
    end,
  })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    callback = function()
      finish(true)
    end,
  })
end

return M
