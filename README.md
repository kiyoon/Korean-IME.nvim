# Korean-IME.nvim

한글 입력기 플러그인입니다.

**특징:**

- 🔠 영어 입력을 한글로 변환하는 방식입니다.
    - 한글 키보드가 없거나 터미널 입력기 버그 등 극한의 상황에서도 한글 입력이 가능합니다.
- 漢字 한자 입력을 지원합니다.
- ♻️ 명령 모드 -> 입력 모드 전환 시 한글 입력 상태를 유지합니다.
- 💤 lazy load를 지원합니다.
    - 한영 전환 시에만 플러그인 로드.
    - 한자 입력 시에만 한자 DB 로드.

## ⚒️ 설치

lazy.nvim:

```lua
  {
    "kiyoon/Korean-IME.nvim",
    keys = {
      -- lazy load on 한영전환
      {
        "<f12>",
        function()
          require("korean_ime").change_mode()
        end,
        mode = { "i", "n", "x", "s" },
        desc = "한/영",
      },
    },
    config = function()
      require("korean_ime").setup()

      vim.keymap.set("i", "<f9>", function()
        require("korean_ime").convert_hanja()
      end, { noremap = true, silent = true, desc = "한자" })
    end,
  },
```


### lualine.nvim

한/A 표시는 다음과 같이 설정할 수 있습니다.

<img width="155" alt="image" src="https://github.com/user-attachments/assets/d5d28d8f-981b-43ea-8419-ccb27b5fa0da" />

```lua
{
  sections = {
    -- ...
    lualine_z = {
      {
        function()
          if not package.loaded["korean_ime"] then
            return ""
          end
          local mode = require("korean_ime").get_mode()
          if mode == "en" then
            return "A "
          elseif mode == "ko" then
            return "한"
          end
        end,
      },
    },
  }
}
```

## 💡 Tips

### (Windows) Windows Terminal 내부에서 한/영 키를 F12 키로 맵핑
Windows Terminal **설정** 또는 `Ctrl + ,` → 왼쪽 하단 **JSON 파일 열기** → `"actions"` 배열에 추가:
```json
{
    "command": { "action": "sendInput", "input": "\u007B" },
    "keys": "vk15"
}
```
저장 후 바로 적용됩니다.
- `vk15` — 한/영 키의 가상 키 코드
- `\u007B` — F12 입력
- Korean-IME.nvim 플러그인 효과로 nvim 안에서 F12가 한영 전환으로 쓰이는 환경에서 유효합니다.

### (macOS) Hammerspoon으로 nvim 감지해 한영 전환하기

Right Command 키를 nvim일 때 `<f12>`로 매핑하고 그 외에는 시스템 입력기를 전환하려면 다음과 같이 설정할 수 있습니다.

1. wezterm인지 확인
    - window title이 vi인지 확인
    - vi이면 command 모드가 아닌지 UI로 확인 (`wezterm cli get-text --escapes` 사용)
    - vi이고 command 모드가 아닌 경우 `<f12>` 누르기.
2. 그 외에는 시스템 입력기 전환

예를 들어, command 모드 여부는 lualine 양쪽 끝 내용과 색상으로 유추할 수 있습니다.

<img width="701" alt="image" src="https://github.com/user-attachments/assets/e4e209c4-1962-440e-813b-96cf73b7095e" />

tmux active pane에 돌아가는 프로그램도 pane-border-format, pane-active-border-style로 유추할 수 있습니다.:

<img width="254" alt="image" src="https://github.com/user-attachments/assets/60718148-7d0a-463b-97e5-468c97ce9bce" />

아래 템플릿을 이용해 수정해 사용하시길 바랍니다.

```lua
-- Karabiner 이용해 Right Command를 F18로 매핑함.
-- 주의: 단순 예시입니다. string.match 부분을 본인 UI에 맞게 수정해야합니다.
-- tmux 안에서는 동작하지 않으니 마찬가지로 사용자 tmux UI에 맞게 수정해야합니다.
hs.hotkey.bind({}, "f18", function()
  local input_source = hs.keycodes.currentSourceID()
  local current_app = hs.application.frontmostApplication()
  print(current_app:name())

  if current_app:name() == "WezTerm" then
    -- get current window title
    local window_title = current_app:focusedWindow():title()
    -- ends with vi/vim/nvim
    -- e.g. [1/2] vi
    print(window_title)
    if
      string.match(window_title, " vi$")
      or string.match(window_title, " vim$")
      or string.match(window_title, " nvim$")
      or string.match(window_title, "^vi$")
      or string.match(window_title, "^vim$")
      or string.match(window_title, "^nvim$")
    then
      print("vim")
      local output, status, type, rc = hs.execute("/opt/homebrew/bin/wezterm cli get-text --escapes")
      if
        status == true
        and type == "exit"
        and rc == 0
        and output ~= nil
        and string.match(output, [[nvim .%[38:2::98:114:164m.%[49m─]])
      then
        print("not in command mode")
        if input_source ~= "com.apple.keylayout.ABC" then
          hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
        end
        hs.eventtap.keyStroke({}, "f12")
        return
      end
    end
  end

  if input_source == "com.apple.keylayout.ABC" then
    hs.keycodes.currentSourceID("com.apple.inputmethod.Korean.2SetKorean")
  elseif input_source == "com.apple.inputmethod.Korean.2SetKorean" then
    hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
  else
    hs.keycodes.currentSourceID("com.apple.inputmethod.Korean.2SetKorean")
  end
end)
```

## 📝 Note

- Lua rewrite of [hangeul.vim](https://github.com/lifthrasiir/hangeul.vim)
- 조합 모음이나 자음의 경우 한번 지우면 같이 지워지는 등의 문제가 있습니다.
