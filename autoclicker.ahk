#Requires AutoHotkey v2.0
#SingleInstance Force

; --- ОПТИМИЗАЦИЯ СКОРОСТИ ---
SetMouseDelay -1 ; Убирает задержку после каждого движения или клика мыши
SendMode "Input" ; Самый быстрый режим отправки команд в Windows

; Экстренное закрытие скрипта
Esc::ExitApp()

global IsClicking := false
global ClickCount := 0
global CurrentHotkey := ""
global iniFile := A_ScriptDir "\clicker_settings.ini"

MainGui := Gui("+AlwaysOnTop", "Advanced Autoclicker")
MainGui.OnEvent("Close", (*) => ExitApp())

; --- БАЗОВЫЕ НАСТРОЙКИ ---
MainGui.Add("GroupBox", "x10 y10 w280 h100", "Настройки клика")
MainGui.Add("Text", "x20 y30", "Кнопка:")
global DropButton := MainGui.Add("DropDownList", "x70 y25 w80 Choose1", ["Left", "Right", "Middle"])

MainGui.Add("Text", "x160 y30", "Тип:")
global DropType := MainGui.Add("DropDownList", "x195 y25 w80 Choose1", ["Single", "Double"])

MainGui.Add("Text", "x20 y65", "Задержка (мс):")
; Для 500 кликов/сек ставь здесь 1 или 2 (но 0 — это "без задержек")
global EditDelay := MainGui.Add("Edit", "x110 y60 w60", "1") 

; --- МЕХАНИКИ И ФИЧИ ---
MainGui.Add("GroupBox", "x10 y120 w280 h80", "Дополнительные механики")
global ChkRandom := MainGui.Add("CheckBox", "x20 y140", "Рандом задержки (±20% анти-детект)")
global ChkLimit := MainGui.Add("CheckBox", "x20 y170", "Лимит кликов:")
global EditLimit := MainGui.Add("Edit", "x120 y165 w60 Disabled", "1000")
ChkLimit.OnEvent("Click", (ctrl, *) => EditLimit.Enabled := ctrl.Value)

; --- ПРИВЯЗКА К ОКНУ ---
MainGui.Add("GroupBox", "x10 y210 w280 h85", "Привязка к окну (работает везде, если выкл)")
global ChkWindow := MainGui.Add("CheckBox", "x20 y230", "Только в окне:")
global EditWindow := MainGui.Add("Edit", "x120 y225 w150 Disabled", "ahk_exe notepad.exe")
ChkWindow.OnEvent("Click", (ctrl, *) => EditWindow.Enabled := ctrl.Value)
global BtnGrabWin := MainGui.Add("Button", "x20 y255 w100", "Захватить окно")
BtnGrabWin.OnEvent("Click", GrabWindow)

; --- УПРАВЛЕНИЕ И ПРОФИЛЬ ---
MainGui.Add("GroupBox", "x10 y305 w280 h100", "Управление и сохранение")
MainGui.Add("Text", "x20 y325", "Старт/Стоп бинд:")
global HkToggle := MainGui.Add("Hotkey", "x120 y320 w100", "")
HkToggle.OnEvent("Change", ApplyHotkey)

global BtnSave := MainGui.Add("Button", "x20 y365 w80", "Сохранить")
global BtnLoad := MainGui.Add("Button", "x110 y365 w80", "Загрузить")
BtnSave.OnEvent("Click", SaveSettings)
BtnLoad.OnEvent("Click", LoadSettings)

LoadSettings()
MainGui.Show("w300 h420")

; --- ЛОГИКА И ФУНКЦИИ ---

ApplyHotkey(*) {
    global CurrentHotkey
    if (CurrentHotkey != "") {
        try Hotkey(CurrentHotkey, StartClicking, "Off")
        try Hotkey(CurrentHotkey " Up", StopClicking, "Off")
    }
    CurrentHotkey := HkToggle.Value
    if (CurrentHotkey != "") {
        try {
            Hotkey(CurrentHotkey, StartClicking, "On")
            Hotkey(CurrentHotkey " Up", StopClicking, "On")
        } catch {
            MsgBox("Не удалось назначить клавишу.", "Ошибка", "Icon!")
        }
    }
}

StartClicking(ThisHotkey) {
    global IsClicking, ClickCount
    if (!IsClicking) {
        IsClicking := true
        ClickCount := 0
        PerformClick()
    }
}

StopClicking(ThisHotkey) {
    global IsClicking
    IsClicking := false
    SetTimer(PerformClick, 0)
}
ToggleClicker(ThisHotkey) {
    global IsClicking, ClickCount
    IsClicking := !IsClicking
    if (IsClicking) {
        ClickCount := 0
        PerformClick()
    } else {
        SetTimer(PerformClick, 0)
        ToolTip()
    }
}

PerformClick() {
    global IsClicking, ClickCount

    if (ChkWindow.Value && !WinActive(EditWindow.Value)) {
        SetTimer(PerformClick, -100)
        return
    }

    baseDelay := Integer(EditDelay.Value)
    btn := DropButton.Text
    isDouble := (DropType.Text = "Double")

    ; --- ТУРБО-РЕЖИМ ---
    ; Если задержка стоит 1мс или меньше, делаем пачку кликов за раз
    if (baseDelay <= 1) {
        Loop 15 { ; Количество кликов за один проход таймера
            Click(btn)
            ClickCount += (isDouble ? 2 : 1)
            if (isDouble) 
                Click(btn)
        }
        nextDelay := -1 ; Максимальная частота перезапуска таймера
    } else {
        ; Обычный режим
        Click(btn)
        if (isDouble) 
            Click(btn)
        ClickCount += (isDouble ? 2 : 1)
        nextDelay := baseDelay
    }

    ; Проверка лимита
    if (ChkLimit.Value && ClickCount >= Integer(EditLimit.Value)) {
        IsClicking := false
        SetTimer(PerformClick, 0)
        ToolTip("Лимит достигнут: " ClickCount)
        SetTimer(() => ToolTip(), -2000)
        return
    }

    if (IsClicking)
        SetTimer(PerformClick, nextDelay)
}
GrabWindow(*) {
    MsgBox("У тебя есть 3 секунды...", "Захват окна", "T3 Iconi")
    Sleep(3000)
    try {
        exe := WinGetProcessName("A")
        EditWindow.Value := "ahk_exe " exe
    } catch {
        MsgBox("Ошибка захвата.")
    }
}

SaveSettings(*) {
    IniWrite(DropButton.Value, iniFile, "Main", "ButtonIndex")
    IniWrite(DropType.Value, iniFile, "Main", "TypeIndex")
    IniWrite(EditDelay.Value, iniFile, "Main", "Delay")
    IniWrite(ChkRandom.Value, iniFile, "Mechanics", "Random")
    IniWrite(ChkLimit.Value, iniFile, "Mechanics", "LimitEnable")
    IniWrite(EditLimit.Value, iniFile, "Mechanics", "LimitValue")
    IniWrite(ChkWindow.Value, iniFile, "Window", "WindowEnable")
    IniWrite(EditWindow.Value, iniFile, "Window", "WindowTitle")
    IniWrite(HkToggle.Value, iniFile, "Main", "Hotkey")
    MsgBox("Конфиг сохранен!", "Сохранено", "T1 Iconi")
}

LoadSettings(*) {
    if !FileExist(iniFile)
        return

    DropButton.Choose(Integer(IniRead(iniFile, "Main", "ButtonIndex", 1)))
    DropType.Choose(Integer(IniRead(iniFile, "Main", "TypeIndex", 1)))
    EditDelay.Value := IniRead(iniFile, "Main", "Delay", "1")
    ChkRandom.Value := Integer(IniRead(iniFile, "Mechanics", "Random", 0))
    ChkLimit.Value := Integer(IniRead(iniFile, "Mechanics", "LimitEnable", 0))
    EditLimit.Value := IniRead(iniFile, "Mechanics", "LimitValue", "1000")
    EditLimit.Enabled := ChkLimit.Value
    ChkWindow.Value := Integer(IniRead(iniFile, "Window", "WindowEnable", 0))
    EditWindow.Value := IniRead(iniFile, "Window", "WindowTitle", "ahk_exe notepad.exe")
    EditWindow.Enabled := ChkWindow.Value

    savedHk := IniRead(iniFile, "Main", "Hotkey", "")
    if (savedHk != "") {
        HkToggle.Value := savedHk
        ApplyHotkey()
    }
}
