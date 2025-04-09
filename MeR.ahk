#NoEnv
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

; Set your password here
Password := "ABB"  ; Change this to your desired password

; Password Prompt
InputBox, UserPassword, MeR's mod menu, Please enter the password to proceed:
if (UserPassword != Password) {
    MsgBox, Incorrect password!
    ExitApp
}

; GUI Setup
Gui, +ToolWindow -Caption +E0x08000000 +LastFound +AlwaysOnTop
WinSetTitle, A, , MeR's mod menu
Gui, Color, 20232A
Gui, Font, s10 cFFFFFF, Segoe UI Semibold
Gui, Margin, 10, 10

Gui, Add, Text, x10 y5 w180 h30 Center BackgroundTrans cFFA500 gGuiMove, MeR's mod menu

Gui, Add, Text, y+10 w180 Center c00CED1, Presets
Gui, Add, Button, w180 h28 gFullHack, Full Hack
Gui, Add, Button, w180 h28 gProPlayer, Pro Player
Gui, Add, Button, w180 h28 gLegit, Legit

Gui, Add, Text, y+10 w180 Center c00CED1, Modes
Gui, Add, CheckBox, vRifleCheckbox gRifleToggle, Rifle
Gui, Add, CheckBox, vSniperCheckbox gSniperToggle, Sniper
Gui, Add, CheckBox, vEnablePredictionCheckbox, Enable Prediction

Gui, Add, Text, y+10 w180 Center c00CED1, Target Location
Gui, Add, Button, x10 w125 h26 gHeadshotsButton, Head
Gui, Add, Button, x+10 w125 h26 gChestButton, Chest

Gui, Add, Text, y+10 w180 Center c00CED1, Aim Strength
Gui, Add, Radio, vStrengthOption1 gUpdateStrength, Aim Assist
Gui, Add, Radio, vStrengthOption2 gUpdateStrength, Strong Aim
Gui, Add, Radio, vStrengthOption3 gUpdateStrength, Aimbot

Gui, Add, Text, y+10 w180 Center c00CED1, Other
Gui, Add, CheckBox, vRedBoxToggle, Show Red Square Overlay
Gui, Add, CheckBox, vRapidFireToggle, Rapid Fire
Gui, Add, CheckBox, vAutoMarkToggle, Auto Mark (MB1+MB2 → P)
Gui, Add, CheckBox, vYYToggle, YY (Hold 1)

Gui, Add, Button, x10 y+20 w50 h28 gClose, Close

Gui, Show, AutoSize, MeR's mod menu
AnimateGuiIn()

; Vars
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
targetOverlayID := 0
lastAutoMarkTime := 0

Loop {
    GuiControlGet, EnablePrediction,, EnablePredictionCheckbox
    GuiControlGet, RifleEnabled,, RifleCheckbox
    GuiControlGet, SniperEnabled,, SniperCheckbox
    GuiControlGet, RedBoxEnabled,, RedBoxToggle
    GuiControlGet, RapidFireEnabled,, RapidFireToggle
    GuiControlGet, AutoMarkActive,, AutoMarkToggle
    GuiControlGet, YYActive,, YYToggle

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

    if (RifleEnabled && GetKeyState("LButton", "P") && GetKeyState("RButton", "P"))
        ModeActive := true
    else if (SniperEnabled && GetKeyState("RButton", "P"))
        ModeActive := true
    else
        ModeActive := false

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

            if (RedBoxEnabled)
                ShowRedBox(PredictedX, PredictedY)
            else
                HideRedBox()

            AimX := PredictedX - ZeroX
            AimY := PredictedY - ZeroY
            DllCall("mouse_event", uint, 1, int, Round(AimX * strength), int, Round(AimY * strength), uint, 0, int, 0)
        } else {
            HideRedBox()
        }
    } else {
        HideRedBox()
    }

    Sleep, 10
}

ShowRedBox(x, y) {
    global targetOverlayID
    if (targetOverlayID)
        WinSet, Region,, ahk_id %targetOverlayID%
    else {
        Gui, RedBox: +ToolWindow -Caption +AlwaysOnTop +LastFound +E0x80000
        Gui, RedBox: Color, FF0000
        Gui, RedBox: Show, x%x% y%y% w20 h20 NoActivate, TargetBox
        WinGet, targetOverlayID, ID, TargetBox
    }
    WinMove, ahk_id %targetOverlayID%, , x - 10, y - 10, 20, 20
    WinSet, Transparent, 180, ahk_id %targetOverlayID%
}

HideRedBox() {
    global targetOverlayID
    if (targetOverlayID) {
        Gui, RedBox:Hide
    }
}

; GUI Move
GuiMove:
~LButton::
    MouseGetPos,,, WinID
    WinGetTitle, title, ahk_id %WinID%
    if (InStr(title, "MeR's mod menu"))
        PostMessage, 0xA1, 2,,, A
Return

; Right Ctrl to toggle the menu
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

; Buttons
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
    if (s1) {
        strength := 0.11
        SoundBeep, 1000
    } else if (s2) {
        strength := 0.20
        SoundBeep, 1200
    } else if (s3) {
        strength := 0.35
        SoundBeep, 1400
    }
Return

FullHack:
    GuiControl,, EnablePredictionCheckbox, 1
    GuiControl,, RifleCheckbox, 0
    GuiControl,, SniperCheckbox, 1
    GuiControl,, StrengthOption3, 1
    Gosub, UpdateStrength
    ZeroY := A_ScreenHeight / 2.18
    SoundBeep, 1300
Return

ProPlayer:
    GuiControl,, EnablePredictionCheckbox, 1
    GuiControl,, RifleCheckbox, 1
    GuiControl,, SniperCheckbox, 0
    GuiControl,, StrengthOption2, 1
    Gosub, UpdateStrength
    ZeroY := A_ScreenHeight / 2.18
    SoundBeep, 1100
Return

Legit:
    GuiControl,, EnablePredictionCheckbox, 1
    GuiControl,, RifleCheckbox, 1
    GuiControl,, SniperCheckbox, 0
    GuiControl,, StrengthOption1, 1
    Gosub, UpdateStrength
    ZeroY := A_ScreenHeight / 2.22
    SoundBeep, 900
Return

; Animations
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
