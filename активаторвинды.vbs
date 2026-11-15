' Единый скрипт активации Windows (VBS + PowerShell)
' Home -> HWID (MAS), Остальные -> KMS
Option Explicit

Dim shellApp, wshShell, objFSO, ps1Path, psCode, objFile

Set shellApp = CreateObject("Shell.Application")
Set wshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' 1. Проверка прав администратора
If WScript.Arguments.Count = 0 Then
    shellApp.ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ elevated", "", "runas", 0
    WScript.Quit
End If

' 2. Формируем код PowerShell.
ps1Path = wshShell.ExpandEnvironmentStrings("%TEMP%") & "\win_activate_temp.ps1"

Dim psLines
psLines = Array( _
    "$os = Get-CimInstance Win32_OperatingSystem", _
    "$caption = $os.Caption", _
    "$c = $caption.ToLower()", _
    "$wshell = New-Object -ComObject Wscript.Shell", _
    "$productKey = $null", _
    "if ($c -match 'windows 7') {", _
    "    if ($c -match 'корпоративная|enterprise') {", _
    "        if ($c -match 'e\b| e$') { $productKey = 'C29WB-22CC8-VJ326-GHFJW-H9DH4' } elseif ($c -match 'n\b| n$') { $productKey = 'YDRBP-3D83W-TY26F-D46B2-XCKRJ' } else { $productKey = '33PXH-7Y6KF-2VJC9-XBBR8-HVTHH' }", _
    "    } else {", _
    "        if ($c -match 'e\b| e$') { $productKey = 'W82YF-2Q76Y-63HXB-FGJG9-GF7QX' } elseif ($c -match 'n\b| n$') { $productKey = 'MRPKT-YTG23-K7D7T-X2JMM-QY7MG' } else { $productKey = 'FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4' }", _
    "    }", _
    "} elseif ($c -match 'windows 8\.1') {", _
    "    if ($c -match 'корпоративная|enterprise') {", _
    "        if ($c -match 'n\b| n$') { $productKey = 'TT4HM-HN7YT-62K67-RGRQJ-JFFXW' } else { $productKey = 'MHF9N-XY6XB-WVXMC-BTDCT-MKKG7' }", _
    "    } else {", _
    "        if ($c -match 'n\b| n$') { $productKey = 'HMCNV-VVBFX-7HMBH-CTY9B-B4FXY' } else { $productKey = 'GCRJD-8NW9H-F2CDX-CCM8D-9D6T9' }", _
    "    }", _
    "} elseif ($c -match 'windows 8\b') {", _
    "    if ($c -match 'корпоративная|enterprise') {", _
    "        if ($c -match 'n\b| n$') { $productKey = 'JMNMF-RHW7P-DMY6X-RF3DR-X2BQT' } else { $productKey = '32JNW-9KQ84-P47T8-D8GGY-CWCK7' }", _
    "    } else {", _
    "        if ($c -match 'n\b| n$') { $productKey = 'XCVCF-2NXM9-723PB-MHCB7-2RYQQ' } else { $productKey = 'NG4HW-VH26C-733KW-K6F98-J8CK4' }", _
    "    }", _
    "} else {", _
    "    $edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).EditionID", _
    "    if ($edition) {", _
    "        switch ($edition) {", _
    "            'ProfessionalWorkstationN' { $productKey = '9FNHH-K3HBT-3W4TD-6383H-6XYWF' }", _
    "            'ProfessionalWorkstation'  { $productKey = 'NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J' }", _
    "            'ProfessionalEducationN'   { $productKey = 'YVWGF-BXNMC-HTQYQ-CPQ99-66QFC' }", _
    "            'ProfessionalEducation'    { $productKey = '6TP4R-GNPTD-KYYHQ-7B7DP-J447Y' }", _
    "            'ProfessionalN'            { $productKey = 'MH37W-N47XK-V7XM9-C7227-GCQG9' }", _
    "            'Professional'             { $productKey = 'W269N-WFGWX-YVC9B-4J6C9-T83GX' }", _
    "            'EnterpriseGN'             { $productKey = '44RPN-FTY23-9VTTB-MP9BX-T84FV' }", _
    "            'EnterpriseG'              { $productKey = 'YYVX9-NTFWV-6MDM3-9PT4T-4M68B' }", _
    "            'EnterpriseN'              { $productKey = 'DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4' }", _
    "            'Enterprise'               { $productKey = 'NPPR9-FWDCX-D2C8J-H872K-2YT43' }", _
    "            'EducationN'               { $productKey = '2WH4N-8QGBV-H22JP-CT43Q-MDWWJ' }", _
    "            'Education'                { $productKey = 'NW6C2-QMPVW-D7KKK-3GKT6-VCFB2' }", _
    "            'Core'                     { $productKey = 'HOME_HWID' }", _
    "            'CoreSingleLanguage'       { $productKey = 'HOME_HWID' }", _
    "            'CoreCountrySpecific'      { $productKey = 'HOME_HWID' }", _
    "        }", _
    "    }", _
    "}", _
    "if ($productKey -eq 'HOME_HWID') {", _
    "    try {", _
    "        $block = [ScriptBlock]::Create((irm https://get.activated.win))", _
    "        & $block /HWID | Out-Null", _
    "        $wshell.Popup(""Активация Windows Home (HWID) успешно завершена!`nСистема: $caption"", 10, ""Готово"", 64)", _
    "    } catch {", _
    "        $wshell.Popup(""Ошибка HWID-активации.`nПопробуйте вручную: irm https://get.activated.win | iex"", 10, ""Ошибка"", 16)", _
    "    }", _
    "} elseif (-not $productKey) {", _
    "    $wshell.Popup(""Не удалось определить редакцию Windows.`nСистема: $caption"", 10, ""Ошибка"", 16)", _
    "} else {", _
    "    $kms = 'kms.digiboy.ir'", _
    "    cscript.exe //nologo C:\Windows\System32\slmgr.vbs /ipk $productKey | Out-Null", _
    "    cscript.exe //nologo C:\Windows\System32\slmgr.vbs /skms $kms | Out-Null", _
    "    cscript.exe //nologo C:\Windows\System32\slmgr.vbs /ato | Out-Null", _
    "    if ($LASTEXITCODE -eq 0) {", _
    "        $wshell.Popup(""KMS-Активация успешно завершена!`nСистема: $caption"", 10, ""Готово"", 64)", _
    "    } else {", _
    "        $wshell.Popup(""Произошла ошибка при KMS-активации.`nВозможно, сервер недоступен."", 10, ""Ошибка"", 16)", _
    "    }", _
    "}" _
)

psCode = Join(psLines, vbCrLf)

' 3. Записываем код во временный файл
Set objFile = objFSO.CreateTextFile(ps1Path, True, True)
objFile.Write psCode
objFile.Close

' 4. Запускаем PowerShell скрытно и ждем завершения
wshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1Path & """", 0, True

' 5. Удаляем временный файл
objFSO.DeleteFile ps1Path, True