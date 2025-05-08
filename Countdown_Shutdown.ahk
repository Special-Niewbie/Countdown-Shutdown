/*
Countdown & Shutdown
Copyright (C) 2025 Special-Niewbie Softwares
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, and distribute copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
Commercial use, sale, or integration of the Software into commercial products
requires explicit written permission from the copyright holder.
Redistributions in any form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#SingleInstance Force
#Include libs\ColorButton.ahk
#Include libs\OD_Colors.ahk
SetWorkingDir A_ScriptDir

; Versione del programma
global programVersion := "1.0.0"

; Variabile globale per tracciare se il controllo aggiornamenti è già stato effettuato
global updateCheckPerformed := false

; Font da utilizzare
fontToUse := "Segoe UI"

; Colori per i temi
global darkModeColors := {
    background: "0x2D2D30",
    text: "0xFFFFFF",
    displayBg: "0x3E3E42",
    displayText: "0xFFFFFF",
    warningColor: "0xF39C12",
    dangerColor: "0xE74C3C",
    dropdownText: "0xFFFFFF",    ; Colore testo per dropdown in Dark mode
    dropdownBg: "0x3E3E42",       ; Colore sfondo per dropdown in Dark mode
    versionText: "0x808080"      ; Colore grigio per la versione
}

global lightModeColors := {
    background: "0xF0F0F0",
    text: "0x000000",
    displayBg: "0xFFFFFF",
    displayText: "0x000000",
    warningColor: "0xF39C12",
    dangerColor: "0xE74C3C",
    dropdownText: "0x000000",    ; Colore testo per dropdown in Light mode
    dropdownBg: "0xFFFFFF",       ; Colore sfondo per dropdown in Light mode
    versionText: "0x808080"      ; Colore grigio per la versione
}

; Impostazioni predefinite
global currentTheme := "Light"

; Carica il tema dal registro di sistema
LoadThemeFromRegistry() {
    try {
        regTheme := RegRead("HKEY_CURRENT_USER\Software\Countdown&Shutdown", "Theme")
        if (regTheme = 1)
            return "Light"
        else
            return "Dark"
    } catch as e {
        ; Se la chiave non esiste, crea con il valore predefinito
        try {
            RegWrite(1, "REG_DWORD", "HKEY_CURRENT_USER\Software\Countdown&Shutdown", "Theme")  ; Cambiato a 1 per Light Mode
        } catch as innerE {
            ; Ignora l'errore se non riesce a scrivere nel registro
        }
        return "Light"  ; Default è Light Mode
    }
}

; Salva il tema nel registro di sistema
SaveThemeToRegistry(theme) {
    try {
        themeValue := (theme = "Light") ? 1 : 0
        RegWrite(themeValue, "REG_DWORD", "HKEY_CURRENT_USER\Software\Countdown&Shutdown", "Theme")
    } catch as e {
        MsgBox("Error saving theme to registry: " . e.Message)
    }
}

; Carica il tema dal registro
currentTheme := LoadThemeFromRegistry()

; Configurazione del System Tray Menu
A_IconTip := "Countdown & Shutdown"

; Crea il menu del System Tray
TrayMenu := A_TrayMenu
TrayMenu.Delete() ; Rimuove tutte le voci standard

; Voci del menu
TrayMenu.Add("👉 >>> Countdown & Shutdown <<<", TitleLabel)
TrayMenu.Disable("👉 >>> Countdown & Shutdown <<<")
TrayMenu.Add()  ; Separatore
TrayMenu.Add("Reload", ReloadScript)
TrayMenu.Add()  ; Separatore
TrayMenu.Add("Donate", OpenDonationSite)
TrayMenu.Add("Project Site", OpenProjectSite)
TrayMenu.Add()  ; Separatore
TrayMenu.Add("Exit", ExitApplication)

; Crea l'interfaccia grafica
MyGui := Gui()
MyGui.SetFont("s9", fontToUse)

; Aggiungi l'etichetta della versione (grigia, a sinistra)
VersionLabel := MyGui.Add("Text", "x20 y10 w100 h20 vVersionLabel", "v" . programVersion)

; Menu per il cambio tema
ThemeMenu := MyGui.Add("DropDownList", "x260 y10 w95 vTheme +0x210 Choose" . (currentTheme = "Dark" ? "1" : "2"), ["Dark Mode", "Light Mode"])
ThemeMenu.OnEvent("Change", ChangeTheme)

MyGui.Add("Text", "x20 y60 w150 h20 vLabelOre", "Hours:")
OreDropDown := MyGui.Add("DropDownList", "x20 y80 w150 vOre +0x210 Choose1 R10", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48"])

MyGui.Add("Text", "x200 y60 w150 h20 vLabelMinuti", "Minutes:")
MinutiDropDown := MyGui.Add("DropDownList", "x200 y80 w150 vMinuti +0x210 Choose1 R12", ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59"])

; Aggiunge un display per il countdown
MyGui.SetFont("s36 bold", fontToUse)
CountdownDisplay := MyGui.Add("Text", "x20 y130 w330 h80 Center vCountdown", "00:00:00")

; Aggiunge i pulsanti con colori personalizzati
MyGui.SetFont("s12 bold", fontToUse)

; Pulsante Cancel (ex Annulla)
CancelButton := MyGui.Add("Button", "x20 y220 w150 h40 vCancelBtn", "Cancel")
CancelButton.OnEvent("Click", CancelShutdown)

; Pulsante Start
StartButton := MyGui.Add("Button", "x200 y220 w150 h40 vStartBtn", "Start")
StartButton.OnEvent("Click", StartCountdown)

; Non aggiungiamo più un pulsante per controllare gli aggiornamenti
MyGui.SetFont("s9", fontToUse)

; Variabili per il timer
global timerRunning := false
global tempoRimanente := 0
global countdownTimerId := 0  ; Variabile per memorizzare l'ID del timer
global shutdownCancelled := false  ; Variabile per tracciare lo stato di cancellazione

; Gestione chiusura della finestra
MyGui.OnEvent("Close", GuiClose)
MyGui.OnEvent("Escape", GuiClose)

; Applica il tema iniziale
ApplyTheme(currentTheme)

; Mostra la finestra
MyGui.Title := "Countdown & Shutdown"
MyGui.Show("w370 h280")

; Controlla automaticamente gli aggiornamenti all'avvio
CheckForUpdates()

; Funzione per cambiare tema
ChangeTheme(ctrl, *) {
    global currentTheme
    
    ; Debug - Mostra il valore corrente selezionato
    selectedValue := ctrl.Text
    newTheme := InStr(selectedValue, "Dark") ? "Dark" : "Light"
    
    if (currentTheme != newTheme) {
        currentTheme := newTheme
        ApplyTheme(currentTheme)
        SaveThemeToRegistry(currentTheme)
    }
}

; Applica il tema selezionato
ApplyTheme(theme) {
    global MyGui, CountdownDisplay, CancelButton, StartButton, darkModeColors, lightModeColors
    global ThemeMenu, OreDropDown, MinutiDropDown
    
    colors := theme = "Dark" ? darkModeColors : lightModeColors
    
    ; Applica colori all'interfaccia
    MyGui.BackColor := colors.background
    
    ; Applica colore al testo
    textControls := ["LabelOre", "LabelMinuti"]
    for _, ctrlName in textControls {
        ctrl := MyGui[ctrlName]
        if (ctrl)
            ctrl.Opt("c" . colors.text)
    }
    
    ; Applica colore al countdown display
    if (timerRunning) {
        ; Se il timer è in esecuzione, mantieni i colori di avviso/pericolo se necessario
        UpdateCountdownDisplayColor(tempoRimanente)
    } else {
        CountdownDisplay.Opt("c" . colors.displayText)
    }
    
    ; Colore grigio per l'etichetta della versione
    VersionLabel.Opt("c" . colors.versionText)
    
    ; Aggiorna i colori dei pulsanti
    CancelButton.SetColor("0xE74C3C", "0xFFFFFF", 1, "0xC0392B", 9)  ; Rosso, testo bianco
    StartButton.SetColor("0x2ECC71", "0xFFFFFF", 1, "0x27AE60", 9)   ; Verde, testo bianco
    
    ; Applica colori ai dropdown usando OD_Colors
    ApplyDropdownColors(ThemeMenu, colors)
    ApplyDropdownColors(OreDropDown, colors)
    ApplyDropdownColors(MinutiDropDown, colors)
}

; Funzione per applicare colori ai dropdown
ApplyDropdownColors(ctrl, colors) {
    ; Collega i colori usando la libreria OD_Colors
    OD_Colors.Attach(ctrl, Map("T", colors.dropdownText, "B", colors.dropdownBg))
    
    ; Imposta l'altezza degli elementi e il font
    OD_Colors.SetItemHeight("s10", fontToUse)
}

StartCountdown(*) {
    global timerRunning, tempoRimanente, OreDropDown, MinutiDropDown, CountdownDisplay, StartButton, countdownTimerId, shutdownCancelled
    
    ; Reset della variabile di controllo per la cancellazione
    shutdownCancelled := false
    
    ; Ottiene i valori selezionati - qui usiamo Text invece di Value per ottenere il valore effettivo
    Ore := Integer(OreDropDown.Text)      ; Utilizziamo il testo visualizzato e lo convertiamo in intero
    Minuti := Integer(MinutiDropDown.Text) ; Utilizziamo il testo visualizzato e lo convertiamo in intero
    
    ; Calcola i secondi totali
    oreSecondi := Ore * 3600
    minutiSecondi := Minuti * 60
    totaleSecondi := oreSecondi + minutiSecondi
    
    if (totaleSecondi <= 0) {
        MsgBox("Please select a valid time!")
        return
    }
    
    ; Imposta il comando di shutdown
    Run("shutdown -s -f -t " . totaleSecondi,, "Hide")
    
    ; Aggiorna il countdown
    tempoRimanente := totaleSecondi
    timerRunning := true
    UpdateCountdownDisplay(tempoRimanente)
    
    ; Ferma eventuali timer precedenti e avvia un nuovo timer
    if (countdownTimerId) {
        SetTimer(countdownTimerId, 0)
        countdownTimerId := 0
    }
    
    ; Avvia il nuovo timer
    countdownTimerId := SetTimer(UpdateCountdown, 1000)
    
    ; Disabilita i controlli
    OreDropDown.Enabled := false
    MinutiDropDown.Enabled := false
    StartButton.Enabled := false
}

UpdateCountdown() {
    global timerRunning, tempoRimanente, countdownTimerId, shutdownCancelled
    
    ; Controlla se lo shutdown è stato cancellato
    if (shutdownCancelled) {
        return
    }
    
    tempoRimanente -= 1
    
    if (tempoRimanente <= 0) {
        timerRunning := false
        if (countdownTimerId) {
            SetTimer(countdownTimerId, 0)
            countdownTimerId := 0
        }
        return
    }
    
    UpdateCountdownDisplay(tempoRimanente)
}

UpdateCountdownDisplay(secondi) {
    global CountdownDisplay, currentTheme, darkModeColors, lightModeColors
    
    ore := Floor(secondi / 3600)
    minuti := Floor(Mod(secondi, 3600) / 60)
    secondiRestanti := Mod(secondi, 60)
    
    displayText := Format("{:02}:{:02}:{:02}", ore, minuti, secondiRestanti)
    CountdownDisplay.Value := displayText
    
    UpdateCountdownDisplayColor(secondi)
}

UpdateCountdownDisplayColor(secondi) {
    global CountdownDisplay, currentTheme, darkModeColors, lightModeColors, fontToUse
    
    colors := currentTheme = "Dark" ? darkModeColors : lightModeColors
    
    ; Cambia colore del countdown quando si avvicina alla fine
    if (secondi <= 300) {  ; Ultimi 5 minuti (300 secondi)
        CountdownDisplay.SetFont("s36 bold c" . colors.dangerColor, fontToUse)  ; Rosso
    } else if (secondi <= 600) {  ; Ultimi 10 minuti (600 secondi)
        CountdownDisplay.SetFont("s36 bold c" . colors.warningColor, fontToUse)  ; Arancione
    } else {
        CountdownDisplay.SetFont("s36 bold c" . colors.displayText, fontToUse)  ; Colore del testo normale
    }
}

CancelShutdown(*) {
    global timerRunning, countdownTimerId, OreDropDown, MinutiDropDown, CountdownDisplay, StartButton, currentTheme, darkModeColors, lightModeColors, shutdownCancelled
    
    ; Annulla lo shutdown
    Run("shutdown -a",, "Hide")
    
    ; Marca lo shutdown come cancellato
    shutdownCancelled := true
    
    ; Ferma il timer
    if (countdownTimerId) {
        SetTimer(countdownTimerId, 0)
        countdownTimerId := 0
    }
    
    timerRunning := false
    
    ; Reset dell'interfaccia
    CountdownDisplay.Value := "00:00:00"
    
    ; Ripristina il colore normale del testo
    colors := currentTheme = "Dark" ? darkModeColors : lightModeColors
    CountdownDisplay.SetFont("s36 bold c" . colors.displayText, fontToUse)
    
    ; Riabilita i controlli
    OreDropDown.Enabled := true
    MinutiDropDown.Enabled := true
    StartButton.Enabled := true
}

GuiClose(*) {
    ; Annulla lo shutdown prima di chiudere
    Run("shutdown -a",, "Hide")
    ExitApp()
}

; Funzione principale per controllare gli aggiornamenti
CheckForUpdates(*) {
    global updateCheckPerformed, programVersion
    
    ; URL per verificare l'ultima versione disponibile
    versionUrl := "https://raw.githubusercontent.com/Special-Niewbie/Countdown-Shutdown/main/version"
    latestVersionFile := A_ScriptDir "\latest_version"
    
    ; Scarica il file dell'ultima versione
    try {
        Download(versionUrl, latestVersionFile)
    } catch as err {
        MsgBox("Unable to check for updates. `nError: " err.Message, "Connection Error", "Icon!")
        return
    }
    
    ; Verifica se il file dell'ultima versione esiste e contiene dati validi
    if (FileExist(latestVersionFile)) {
        try {
            latestVersion := Trim(FileRead(latestVersionFile))
            FileDelete(latestVersionFile)
            
            ; Controlla se il contenuto scaricato non è un errore HTTP (es. 404: Not Found)
            if (!InStr(latestVersion, "404: Not Found") && programVersion != latestVersion) {
                result := MsgBox("A new version is available: " latestVersion 
                      "`n`nYou are currently using version: " programVersion 
                      "`n`nDo you want to download the latest version?", 
                      "Update Available", "Y/N Icon?")
                
                if (result = "Yes") {
                    ; API di GitHub per ottenere informazioni sull'ultima release
                    apiUrl := "https://api.github.com/repos/Special-Niewbie/Countdown-Shutdown/releases/latest"
                    jsonFile := A_Temp "\github_release.json"
                    
                    ; Utilizza il metodo Download di AHK v2
                    try {
                        Download(apiUrl, jsonFile)
                    } catch as err {
                        MsgBox("Unable to get release information. `nError: " err.Message, 
                               "API Error", "Icon!")
                        return
                    }
                    
                    try {
                        jsonContent := FileRead(jsonFile)
                        FileDelete(jsonFile)
                        
                        ; Salva il JSON per il debug
                        ; FileAppend(jsonContent, A_ScriptDir "\debug_json.txt")
                    } catch as err {
                        MsgBox("Unable to read release information. `nError: " err.Message, 
                               "File Error", "Icon!")
                        return
                    }
                    
                    ; Cerca il file di setup utilizzando RegExMatch
                    setupFileUrl := ""
                    
                    ; Log per debug
                    ; FileAppend("Searching for .exe file URL in JSON...", A_ScriptDir "\debug_log.txt")
                    
                    ; Prova diversi pattern per trovare il file .exe
                    fileUrlMatch := {}
                    foundUrl := false
                    
                    ; Pattern 1: Formato standard di GitHub API
                    if (RegExMatch(jsonContent, 'U)"browser_download_url":\s*"(https://[^"]*\.exe)"', &fileUrlMatch)) {
                        ; FileAppend("`nPattern 1 found: " fileUrlMatch[1], A_ScriptDir "\debug_log.txt")
                        foundUrl := true
                        setupFileUrl := fileUrlMatch[1]
                    }
                    ; Pattern 2: Qualsiasi URL che termina con .exe
                    else if (RegExMatch(jsonContent, 'U)"url":\s*"([^"]*\.exe)"', &fileUrlMatch)) {
                        ; FileAppend("`nPattern 2 found: " fileUrlMatch[1], A_ScriptDir "\debug_log.txt")
                        foundUrl := true
                        setupFileUrl := fileUrlMatch[1]
                    }
                    ; Pattern 3: URL dentro html_url
                    else if (RegExMatch(jsonContent, 'U)"html_url":\s*"([^"]*)".*\.exe', &fileUrlMatch)) {
                        ; FileAppend("`nPattern 3 found: " fileUrlMatch[1], A_ScriptDir "\debug_log.txt")
                        foundUrl := true
                        setupFileUrl := fileUrlMatch[1]
                    }
                    ; Pattern 4: Cerca specificamente CountdownShutdown
                    else if (RegExMatch(jsonContent, 'U)"browser_download_url":\s*"([^"]*Countdown_Shutdown[^"]*\.exe)"', &fileUrlMatch)) {
                        ; FileAppend("`nPattern 4 found: " fileUrlMatch[1], A_ScriptDir "\debug_log.txt")
                        foundUrl := true
                        setupFileUrl := fileUrlMatch[1]
                    }
                    
                    ; Se abbiamo trovato un URL
                    if (foundUrl) {
                        setupFileUrl := fileUrlMatch[1]
                        
                        setupFileName := ""  ; Dichiariamo la variabile
                        SplitPath(setupFileUrl, &setupFileName)
                        
                        ; Chiedi all'utente dove salvare il file
                        downloadPath := FileSelect("S", setupFileName, 
                                                 "Save Update File", 
                                                 "Executable Files (*.exe)")
                        
                        if (downloadPath != "") {
                            ; Mostra progresso download
                            dlg := CreateProgressDialog("Downloading...", "Please wait")
                            
                            ; Scarica il file
                            try {
                                Download(setupFileUrl, downloadPath)
                                dlg.Destroy()  ; Chiudi il dialogo di progresso
                                
                                ; Verifica se il download è riuscito
                                if (FileExist(downloadPath)) {
                                    result := MsgBox("The update has been successfully downloaded to:`n" downloadPath 
                                                  "`n`nWould you like to exit Countdown & Shutdown to install the update?", 
                                                  "Download Complete", "Y/N Icon?")
                                    if (result = "Yes") {
                                        ExitApp()
                                    }
                                } else {
                                    MsgBox("Unable to download the update. Please try again or visit the GitHub page manually.", 
                                           "Download Failed", "Icon!")
                                }
                            } catch as err {
                                dlg.Destroy()  ; Chiudere il dialogo in caso di errore
                                MsgBox("Error during download: " err.Message, 
                                       "Download Failed", "Icon!")
                            }
                        }
                    } else {
                        MsgBox("Unable to extract file URL from response.`n`nDetails have been saved to debug_log.txt", 
                               "Error", "Icon!")
                        Run("https://github.com/Special-Niewbie/Countdown-Shutdown/releases")
                    }
                }
            } else {
                MsgBox("You are already using the latest version: " programVersion, "No updates available", "Info")
            }
        } catch as err {
            ; MsgBox("Error processing version: " err.Message, 
                  ; "Error", "Icon!") ; Silent error to don't disturb on opening proces
        }
    }
}

; Funzione per la voce TitleLabel - questa non fa nulla ma è necessaria
TitleLabel(*) {
    ; Non fa nulla, è solo un'etichetta del titolo
    return
}

; Funzione per ricaricare lo script
ReloadScript(*) {
    Reload
}

; Funzione per aprire il sito per le donazioni
OpenDonationSite(*) {
    Run("https://www.paypal.com/ncp/payment/BSQUBPJYRJZMN")
}

; Funzione per aprire il sito del progetto
OpenProjectSite(*) {
    Run("https://github.com/Special-Niewbie/Countdown-Shutdown")
}

; Funzione per uscire dall'applicazione
ExitApplication(*) {
    ; Annulla lo shutdown prima di uscire, per sicurezza
    Run("shutdown -a",, "Hide")
    ExitApp()  ; Questo chiama il comando ExitApp integrato di AutoHotkey
}

; Funzione per creare un dialogo di progresso personalizzato
CreateProgressDialog(title, message) {
    dlg := Gui("+AlwaysOnTop +ToolWindow")
    dlg.Title := title
    dlg.SetFont("s10", "Segoe UI")
    dlg.Add("Text", "w300 Center", message)
    dlg.Add("Progress", "w300 h20 vProgressBar Range0-100", 50)  ; Impostato a 50% fisso
    dlg.Show("w320 h80")
    return dlg
}