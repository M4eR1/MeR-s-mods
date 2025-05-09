; AutoHotkey Script - Fixed Version with Draggable Square and V2.0 Label
#NoEnv
#NoTrayIcon
#SingleInstance, Force
#Persistent
#InstallKeybdHook
#UseHook
#KeyHistory, 0
#HotKeyInterval 1
#MaxHotkeysPerInterval 127

CoordMode, Pixel, Screen, RGB
CoordMode, Mouse, Screen
SetBatchLines, -1
PID := DllCall("GetCurrentProcessId")
Process, Priority, %PID%, High

GuiVisible := true
Password := "AAA"
InputBox, UserPassword, Enter Password, Please enter the password to proceed:
if (UserPassword != Password) {
    MsgBox, Incorrect password!
    ExitApp
}

Gui, +ToolWindow -Caption +E0x08000000 +LastFound +AlwaysOnTop
Gui, Color, 20232A
Gui, Font, s10 cFFFFFF, Segoe UI Semibold
Gui, Margin, 10, 10

; Drag Handle
Gui, Add, Text, x160 y0 w20 h20 BackgroundTrans vDragHandle gGuiMove, ■

; Title
Gui, Add, Text, x10 y5 w180 h30 Center BackgroundTrans cFFA500, MeR's Mod menu

; Modes
Gui, Add, Text, y+10 w180 Center c00CED1, Modes
Gui, Add, CheckBox, vRifleCheckbox gRifleToggle, Rifle
Gui, Add, CheckBox, vSniperCheckbox gSniperToggle, Sniper
Gui, Add, CheckBox, vEnablePredictionCheckbox, Enable Prediction

; Target Location
Gui, Add, Text, y+10 w180 Center c00CED1, Target Location
Gui, Add, Button, x10 w125 h26 gHeadshotsButton, Head
Gui, Add, Button, x+10 w125 h26 gChestButton, Chest

; Aim Strength
Gui, Add, Text, y+10 w180 Center c00CED1, Aim Strength
Gui, Add, Radio, vStrengthOption1 gUpdateStrength, Aim Assist
Gui, Add, Radio, vStrengthOption2 gUpdateStrength, Strong Aim
Gui, Add, Radio, vStrengthOption3 gUpdateStrength, Aimbot
Gui, Add, Radio, vStrengthOption4 gUpdateStrength, Smooth Aimbot

; Other
Gui, Add, Text, y+10 w180 Center c00CED1, Other
Gui, Add, CheckBox, vRapidFireToggle, Rapid Fire (⚠️ Might Lag Device)
Gui, Add, CheckBox, vAutoMarkToggle, Auto Mark (MB1+MB2 → P)
Gui, Add, CheckBox, vYYToggle, YY (Hold 1)

; Sniper
Gui, Add, Text, y+10 w180 Center c00CED1, Sniper
Gui, Add, CheckBox, vSniperFocusToggle, Sniper Focus
Gui, Add, CheckBox, vSilenceToggle, Silence

; Silence Key
Gui, Add, Text, y+5 w180 Center c00CED1, Silence Key
Gui, Add, DropDownList, vSilenceKeyChoice gSilenceKeyChanged, E||G

; Version Label
Gui, Add, Text, x140 y+20 w120 h30 Right BackgroundTrans c808080, V2.0

; Close Button
Gui, Add, Button, x10 y+20 w50 h28 gClose, Close

Gui, Show, AutoSize, MeR's Mod menu

AnimateGuiIn()

EMCol := 0xEEFF00
ColVn := 30
ZeroX := A_ScreenWidth / 2
ZeroY := A_ScreenHeight / 2.18
CFovX := 70
CFovY := 70
SearchArea := 30
prevX := 0
prevY := 0
lastTime := 0
strength := 0.11
predictionMultiplier := 2.5
lastAutoMarkTime := 0
silenceActive := false
SilenceFired := false
silenceKey := "e" ; default

Loop {
    GuiControlGet, EnablePrediction,, EnablePredictionCheckbox
    GuiControlGet, RifleEnabled,, RifleCheckbox
    GuiControlGet, SniperEnabled,, SniperCheckbox
    GuiControlGet, RapidFireEnabled,, RapidFireToggle
    GuiControlGet, AutoMarkActive,, AutoMarkToggle
    GuiControlGet, YYActive,, YYToggle
    GuiControlGet, SniperFocusActive,, SniperFocusToggle
    GuiControlGet, SilenceEnabled,, SilenceToggle
    GuiControlGet, silenceKey,, SilenceKeyChoice

    if (RapidFireEnabled && GetKeyState("LButton", "P"))
        Click

    if (AutoMarkActive && GetKeyState("LButton", "P") && GetKeyState("RButton", "P")) {
        now := A_TickCount
        if (now - lastAutoMarkTime >= 2000 || lastAutoMarkTime = 0) {
            Send, p
            lastAutoMarkTime := now
        }
    } else {
        lastAutoMarkTime := 0
    }

    if (YYActive && GetKeyState("1", "P")) {
        Send, 1
        Sleep, 50
    }

    if (SniperFocusActive && GetKeyState("RButton", "P"))
        Send, {Shift Down}
    else
        Send, {Shift Up}

    if (SilenceEnabled) {
        if (GetKeyState("LButton", "P") && !SilenceFired) {
            SilenceFired := true
            Send, {%silenceKey% down}
            Sleep, 10
            Send, 1
            Sleep, 10
            Send, {%silenceKey% up}
        } else if (!GetKeyState("LButton", "P")) {
            SilenceFired := false
        }
    }

    if ((RifleEnabled && GetKeyState("LButton", "P") && GetKeyState("RButton", "P")) || (SniperEnabled && GetKeyState("RButton", "P"))) {
        ModeActive := true
    } else {
        ModeActive := false
    }

    if (ModeActive) {
        targetFound := False
        PixelSearch, AimPixelX, AimPixelY, targetX - SearchArea, targetY - SearchArea, targetX + SearchArea, targetY + SearchArea, EMCol, ColVn, Fast RGB
        if (!ErrorLevel) {
            targetX := AimPixelX
            targetY := AimPixelY
            targetFound := True
        } else {
            ScanL := ZeroX - CFovX
            ScanT := ZeroY - CFovY
            ScanR := ZeroX + CFovX
            ScanB := ZeroY + CFovY
            PixelSearch, AimPixelX, AimPixelY, ScanL, ScanT, ScanR, ScanB, EMCol, ColVn, Fast RGB
            if (!ErrorLevel) {
                targetX := AimPixelX
                targetY := AimPixelY
                targetFound := True
            }
        }

        if (targetFound) {
            currentTime := A_TickCount
            if (lastTime != 0) {
                deltaTime := (currentTime - lastTime) / 1000.0
                velocityX := (targetX - prevX) / deltaTime
                velocityY := (targetY - prevY) / deltaTime
            }
            prevX := targetX
            prevY := targetY
            lastTime := currentTime

            if (EnablePrediction && deltaTime != 0) {
                PredictedX := targetX + Round(velocityX * predictionMultiplier * deltaTime)
                PredictedY := targetY + Round(velocityY * predictionMultiplier * deltaTime)
            } else {
                PredictedX := targetX
                PredictedY := targetY
            }

            AimX := PredictedX - ZeroX
            AimY := PredictedY - ZeroY
            DllCall("mouse_event", uint, 1, int, Round(AimX * strength), int, Round(AimY * strength), uint, 0, int, 0)
        }
    }

    Sleep, 10
}

GuiMove:
~LButton::
    MouseGetPos, mx, my, WinID, Control
    if (Control = "Static1" || Control = "DragHandle") {
        PostMessage, 0xA1, 2,,, A
    }
Return

~RControl::
    if (GuiVisible) {
        AnimateGuiOut()
        GuiVisible := false
    } else {
        Gui, Show, NoActivate
        AnimateGuiIn()
        GuiVisible := true
    }
Return

Close:
GuiClose:
    ExitApp
Return

HeadshotsButton:
    ZeroY := A_ScreenHeight / 2.18
    SoundBeep, 1000
Return

ChestButton:
    ZeroY := A_ScreenHeight / 2.22
    SoundBeep, 800
Return

RifleToggle:
    GuiControlGet, RifleState,, RifleCheckbox
    if (RifleState)
        GuiControl,, SniperCheckbox, 0
    SoundBeep, 600
Return

SniperToggle:
    GuiControlGet, SniperState,, SniperCheckbox
    if (SniperState)
        GuiControl,, RifleCheckbox, 0
    SoundBeep, 700
Return

UpdateStrength:
    GuiControlGet, s1,, StrengthOption1
    GuiControlGet, s2,, StrengthOption2
    GuiControlGet, s3,, StrengthOption3
    GuiControlGet, s4,, StrengthOption4
    if (s1) {
        strength := 0.11
        SoundBeep, 1000
    } else if (s2) {
        strength := 0.20
        SoundBeep, 1200
    } else if (s3) {
        strength := 0.35
        SoundBeep, 1400
    } else if (s4) {
        strength := 0.50
        SoundBeep, 1600
    }
Return

SilenceKeyChanged:
    GuiControlGet, silenceKey,, SilenceKeyChoice
Return

AnimateGuiIn() {
    Loop, 10 {
        alpha := A_Index * 22
        WinSet, Transparent, %alpha%
        Sleep, 15
    }
}

AnimateGuiOut() {
    Loop, 10 {
        alpha := 220 - (A_Index * 22)
        WinSet, Transparent, %alpha%
        Sleep, 15
    }
    Gui, Hide
}
