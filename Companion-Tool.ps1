# -------------------- I N I T I A L I S A T I O N --------------------

# --- External Modules ---
function Initialise-Modules {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    if (-not (Get-Module -ListAvailable CimCmdlets)) {
        Install-Module CimCmdlets -Scope CurrentUser -Force
    }
    Import-Module CimCmdlets -ErrorAction Stop

    if (-not (Get-Module -ListAvailable Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $global:MgAuthReady = $true

    if (-not (Get-Module -ListAvailable Microsoft.Graph.Users)) {
        Install-Module Microsoft.Graph.Users -Scope CurrentUser -Force
    }
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
    $global:MgUsersReady = $true

    if (-not (Get-Module -ListAvailable ImagePlayground)) {
        Install-Module ImagePlayground -Scope CurrentUser -Force
    }
    Import-Module ImagePlayground -ErrorAction Stop
    $global:ImagePlaygroundReady = $true

    if (-not (Get-Module -ListAvailable ps2exe)) {
        Install-Module ps2exe -Scope CurrentUser -Force
    }
    Import-Module ps2exe -ErrorAction Stop
    $global:Ps2ExeReady = $true
}
Initialise-Modules


# --- Grab Root ---
if ($PSScriptRoot) {
    $script:AppRoot = $PSScriptRoot
} else {
    $script:AppRoot = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

# --- Grab full script content ---
try {
    $script:FullScript = Get-Content -Path $MyInvocation.MyCommand.Path -Raw -ErrorAction Stop
} catch {
    # ___INJECT_FULLSCRIPT___
}














# -------------------- T H E M E --------------------

# --- Colour Palette ---
$Theme = @{
    Background  = [System.Drawing.Color]::FromArgb(45,  45,  55)   # Main window background
    Surface     = [System.Drawing.Color]::FromArgb(58,  58,  70)   # Header / nav background
    Panel       = [System.Drawing.Color]::FromArgb(50,  50,  62)   # Content area background
    Button      = [System.Drawing.Color]::FromArgb(68,  68,  82)   # Default button
    ButtonHover = [System.Drawing.Color]::FromArgb(85,  85, 100)   # Button hover
    ButtonDown  = [System.Drawing.Color]::FromArgb(52,  52,  64)   # Button pressed
    Border      = [System.Drawing.Color]::FromArgb(85,  85, 102)   # Borders and separators
    Accent      = [System.Drawing.Color]::FromArgb(99,  140, 255)  # Blue accent (header line)
    Text        = [System.Drawing.Color]::FromArgb(230, 230, 240)  # Primary text
    Font        = New-Object System.Drawing.Font("Segoe UI", 9)
    FontBold    = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
}

# --- Button ---
function New-Button {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$W = 180,
        [int]$H = 45,
        [int]$Size = 9,
        [scriptblock]$OnClick
    )
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = $Text
    $btn.Location  = New-Object System.Drawing.Point($X, $Y)
    $btn.Size      = New-Object System.Drawing.Size($W, $H)
    $btn.BackColor = $script:Theme.Button
    $btn.ForeColor = $script:Theme.Text
    $btn.Font      = New-Object System.Drawing.Font($script:Theme.FontBold.FontFamily, $Size, $script:Theme.FontBold.Style)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize         = 1
    $btn.FlatAppearance.BorderColor        = $script:Theme.Border
    $btn.FlatAppearance.MouseOverBackColor = $script:Theme.ButtonHover
    $btn.FlatAppearance.MouseDownBackColor = $script:Theme.ButtonDown
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn.Add_Click($OnClick)
    return $btn
}

# --- Panel ---
function New-Panel {
    param(
        [int]$X,
        [int]$Y,
        [int]$W = 200,
        [int]$H = 100,
        [System.Drawing.Color]$Color = $script:Theme.Panel
    )
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location  = New-Object System.Drawing.Point($X, $Y)
    $panel.Size      = New-Object System.Drawing.Size($W, $H)
    $panel.BackColor = $Color
    return $panel
}

# --- Label ---
function New-Label {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$W = 0,
        [int]$H = 0,
        [int]$Size = 10,
        [bool]$Bold = $false
    )
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Text
    $lbl.Location  = New-Object System.Drawing.Point($X, $Y)
    $lbl.ForeColor = $script:Theme.Text
    $style = if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $lbl.Font = New-Object System.Drawing.Font($script:Theme.Font.FontFamily, $Size, $style)
    if ($BoxWidth -gt 0) {
        $lbl.AutoSize  = $false
        $lbl.Size      = New-Object System.Drawing.Size($BoxWidth, $BoxHeight)
        $lbl.TextAlign = 'MiddleCenter'
    } else {
        $lbl.AutoSize = $true
    }
    return $lbl
}

# --- TextArea ---
function New-TextArea {
    param(
        [string]$Text = "",
        [int]$X,
        [int]$Y,
        [int]$W = 300,
        [int]$H = 150,
        [bool]$ReadOnly = $false,
        [string]$ScrollBars = "Vertical",   # None, Horizontal, Vertical, Both
        [bool]$WordWrap = $true
    )
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Multiline   = $true
    $txt.Text        = $Text
    $txt.Location    = New-Object System.Drawing.Point($X, $Y)
    $txt.Size        = New-Object System.Drawing.Size($W, $H)
    $txt.ScrollBars  = $ScrollBars
    $txt.WordWrap    = $WordWrap
    $txt.AcceptsReturn = $true
    $txt.AcceptsTab    = $true
    $txt.ReadOnly      = $ReadOnly
    $txt.BackColor   = $script:Theme.Panel
    $txt.ForeColor   = $script:Theme.Text
    $txt.Font        = $script:Theme.Font
    $txt.BorderStyle = "FixedSingle"
    return $txt
}

function New-Checkbox {
    param(
        [string]$Text = "",
        [int]$X,
        [int]$Y,
        [bool]$Checked = $false,
        [int]$Size = 9,
        [scriptblock]$OnCheckedChanged
    )
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = $Text
    $chk.Location = New-Object System.Drawing.Point($X, $Y)
    $chk.ForeColor = $script:Theme.Text
    $chk.BackColor = [System.Drawing.Color]::Transparent
    $chk.Checked = $Checked
    $chk.AutoSize = $true
    $chk.Font = New-Object System.Drawing.Font($script:Theme.Font.FontFamily, $Size)
    $chk.Cursor = [System.Windows.Forms.Cursors]::Hand
    if ($OnCheckedChanged) { $chk.Add_CheckedChanged($OnCheckedChanged) }
    return $chk
}


















# -------------------- L O C A L   D A T A   S T O R A G E --------------------

# --- Create File ---
$script:DataFile = Join-Path $script:AppRoot "Companion Data.json"
if (-not (Test-Path $script:DataFile)) {
    "{}" | Set-Content -Path $script:DataFile -Encoding UTF8
}
function Get-Data {
    Get-Content -Path $script:DataFile -Raw | ConvertFrom-Json
}

# --- Save Data ---
function Save-Data {
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)]$Value
    )
    $data = Get-Data
    $data | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
    $data | ConvertTo-Json -Depth 10 | Set-Content -Path $script:DataFile -Encoding UTF8
}

# --- Load Data ---
function Load-Data {
    param(
        [Parameter(Mandatory)][string]$Key,
        $Default = $null
    )
    $data = Get-Data
    if ($data.PSObject.Properties.Name -contains $Key) { return $data.$Key }
    return $Default
}



















# -------------------- W I N D O W --------------------

# --- Settings ---
$FullWidth  = 800
$FullHeight = 600
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Companion Tool"
$form.ClientSize      = New-Object System.Drawing.Size($FullWidth, $FullHeight)
$form.BackColor       = $Theme.Background
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false

# --- Icon ---
$form.Add_Shown({
    if (Test-Path "$script:AppRoot\logo.ico") {
        $form.Icon = New-Object System.Drawing.Icon("$script:AppRoot\logo.ico")
    } else {
        $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon(
            [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        )
    }
})

# --- Modules and their tools ---
$Modules = [ordered]@{
    "Microsoft" = [ordered]@{
        "Sign in" = { Sign-In-Microsoft }
    }
    "Crosstek" = [ordered]@{
        "Asset Label Generator" = { Asset-Label-Generator }
        "System Setup" = { System-Setup }
        "Password Generator" = { Password-Generator }
    }
    "Tools" = [ordered]@{
        "Notepad" = { Show-Notepad }
        "RSS Viewer" = { RSS-Viewer }
        "QR Code Generator" = { QR-Code-Generator }
        "Network Scanner" = { Network-Scanner }
        "Port Scanner" = { Port-Scanner }
        "AI Chat" = { AI-Chat }
        "Custom PowerShell" = { Custom-PowerShell }
        "Create Development Environment" = { Create-Dev-Environment }
        "Manage RDP" = { Manage-RDP }
    }
    "Fun" = [ordered]@{
        "Decision Maker" = { Decision-Maker }
        "Fake Hacker Screen" = { Fake-Hacker-Screen }
        "Morse Code" = { Morse-Code }
        "Typing Speed Test" = { Typing-Speed-Test }
        "Reaction Timer" = { Reaction-Timer }
        "Pictionary" = { Pictionary }
        "Minesweeper" = { Minesweeper }
        "Wordle" = { Wordle }
        "Christmas-Countdown" = { Christmas-Countdown }
    }
    "System" = [ordered]@{
        "System Info" = { System-Info }
        "System Monitor" = { System-Monitor }
        "Disk Cleanup" = { Disk-Cleanup }
        "Recent Logs" = { Recent-Logs }
    }
    "Applications" = [ordered]@{
        "Build Companion EXE" = { Build-Companion-EXE }
        "System Setup EXE" = { System-Setup-EXE }
        "System Monitor EXE" = { System-Monitor-EXE }
        "RDP EXE" = { RDP-EXE }
    }
}

# --- Showing the Main Menu ---
function Show-Menu {
    $script:form.Controls.Clear()
    $navHeight = 42
    $navWidth  = [int]($FullWidth / $Modules.Count)
    $navBar    = New-Panel -X 0 -Y 0 -W $FullWidth -H $navHeight -Color $Theme.Surface
    $script:NavButtons = @{}
    $i = 0
    foreach ($moduleName in $Modules.Keys) {
        $btn = New-Button -Text $moduleName -X ($navWidth * $i) -Y 0 -W $navWidth -H $navHeight `
            -OnClick ([scriptblock]::Create("Show-Modules -ModuleName '$moduleName'"))
        $btn.BackColor = $Theme.Surface
        $btn.FlatAppearance.BorderSize = 0
        $btn.Font = $Theme.Font
        $navBar.Controls.Add($btn)
        $script:NavButtons[$moduleName] = $btn
        $i++
    }
    $form.Controls.Add($navBar)
    $form.Controls.Add((New-Panel -X 0 -Y $navHeight -W $FullWidth -H 2 -Color $Theme.Accent))
    $contentY = $navHeight + 2
    $script:ContentPanel = New-Panel -X 0 -Y $contentY -W $FullWidth -H ($FullHeight - $contentY)
    $form.Controls.Add($script:ContentPanel)
}

# --- Populating the Panel with Tools ---
function Show-Modules {
    param([string]$ModuleName)
    foreach ($name in $script:NavButtons.Keys) {
        $script:NavButtons[$name].BackColor = $Theme.Surface
    }
    $script:NavButtons[$ModuleName].BackColor = $Theme.Accent
    $script:ContentPanel.Controls.Clear()
    $cols = 4
    $rows = 4
    $gap  = 16
    $availW = $script:ContentPanel.Width  - ($gap * ($cols + 1))
    $availH = $script:ContentPanel.Height - ($gap * ($rows + 1))
    $btnW = [int]($availW / $cols)
    $btnH = [int]($availH / $rows)
    $col = 0
    $row = 0
    foreach ($toolName in $Modules[$ModuleName].Keys) {
        $x = $gap + $col * ($btnW + $gap)
        $y = $gap + $row * ($btnH + $gap)
        $script:ContentPanel.Controls.Add(
            (New-Button -Text $toolName -X $x -Y $y -W $btnW -H $btnH -OnClick $Modules[$ModuleName][$toolName])
        )
        $col++
        if ($col -ge $cols) { $col = 0; $row++ }
        if ($row -ge $rows) { break }
    }
}




























# -------------------- M O D U L E S --------------------

# --- Microsoft ---
function Sign-In-Microsoft {
    $panel = $script:ContentPanel
    $clientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"; $script:tenant = "organizations"
    $scopes = "Directory.Read.All User.Read.All Group.Read.All Application.Read.All RoleManagement.Read.Directory offline_access"
    $device = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$script:tenant/oauth2/v2.0/devicecode" -Body @{ client_id = $clientId; scope = $scopes } -ErrorAction Stop
    $script:SignInUrl = $device.verification_uri; $script:SignInCode = $device.user_code
    $script:tokenBody = @{ grant_type = "urn:ietf:params:oauth:grant-type:device_code"; client_id = $clientId; device_code = $device.device_code }
    $copy = { param($text) $text | Set-Clipboard; [System.Windows.Forms.MessageBox]::Show("$text has been copied to your clipboard.", "Success") }
    $script:ContentPanel.Controls.Clear()
    $panel.Controls.Add((New-Label -Text "Microsoft Sign In" -X 20 -Y 20 -Size 26))
    $panel.Controls.Add((New-Button -Text "Copy URL" -X (($FullWidth/2)-120) -Y (($FullHeight/2)-100) -W 240 -Size 12 -OnClick {
        [Windows.Forms.Clipboard]::SetText($script:SignInUrl)
    }))
    $panel.Controls.Add((New-Button -Text "Copy Code" -X (($FullWidth/2)-120) -Y (($FullHeight/2)-30) -W 240 -Size 12 -OnClick {
        [Windows.Forms.Clipboard]::SetText($script:SignInCode)
    }))
    $script:signInTimer = New-Object Windows.Forms.Timer
    $script:signInTimer.Interval = [Math]::Max($device.interval, 5) * 1000
    $script:signInTimer.Add_Tick({
        try {
            $token = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$script:tenant/oauth2/v2.0/token" -Body $script:tokenBody -ErrorAction Stop
        } catch {
            $err = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($err.error -eq "authorization_pending") { return }; if ($err.error -eq "slow_down") { $script:signInTimer.Interval += 5000; return }
            $script:signInTimer.Stop(); $msg = if ($err.error_description) { $err.error_description } else { $_.Exception.Message }
            [Windows.Forms.MessageBox]::Show("Sign-in failed: $msg", "Sign-in error") | Out-Null; return
        }
        $script:signInTimer.Stop()
        Connect-MgGraph -AccessToken ($token.access_token | ConvertTo-SecureString -AsPlainText -Force)
        $Modules["Microsoft"] = [ordered]@{
            "Modify a User" = { Modify-User }
            "Modify a Group" = { Modify-Group }
            "Onboard a User" = { Onboard-User }
            "Offboard a User" = { Offboard-User }
            "Generate Security Report" = { Generate-Security-Report }
            "Sign out" = { Sign-Out-Microsoft }
        }
        Show-Modules -ModuleName "Microsoft"
        [Windows.Forms.MessageBox]::Show("Connected as $((Get-MgContext).Account)", "Connected") | Out-Null
    })
    $script:signInTimer.Start()
}

function Sign-Out-Microsoft {
    try {
        Disconnect-MgGraph -ErrorAction Stop | Out-Null
        [Windows.Forms.MessageBox]::Show("Disconnected.", "Disconnected") | Out-Null
    } catch {
        [Windows.Forms.MessageBox]::Show("Not signed in, or disconnect failed: $($_.Exception.Message)", "Disconnect") | Out-Null
    }
    $Modules["Microsoft"] = [ordered]@{
        "Sign in" = { Sign-In-Microsoft }
    }
    Show-Modules -ModuleName "Microsoft"
}

function Modify-User {
    $panel = $script:ContentPanel
    $panel.Controls.Clear()
    $users = Get-MgUser -All | Select-Object DisplayName, UserPrincipalName, Id, AccountEnabled
    foreach ($user in $users) {
        Write-Host "$($user.DisplayName) - $($user.UserPrincipalName) - Enabled: $($user.AccountEnabled)"
    }
}


# --- Crosstek ---
function Asset-Label-Generator {
    $panel = $script:ContentPanel
    $panel.Controls.Clear()
    $panel.Controls.Add((New-Label -Text "Asset Label Generator" -X 20 -Y 20 -Size 26))
    $panel.Controls.Add((New-Label -Text "Customer Name" -X (($FullWidth/2)-80) -Y 140 -Size 16))
    $txtCustomer = New-Object System.Windows.Forms.TextBox -Property @{ Location = "$(($FullWidth/2)-150),180"; Size = '300,26'; Font = New-Object System.Drawing.Font("Segoe UI", 14) }
    $panel.Controls.Add($txtCustomer)
    $panel.Controls.Add((New-Label -Text "Serial Number" -X (($FullWidth/2)-70) -Y 240 -Size 16))
    $txtSerial = New-Object System.Windows.Forms.TextBox -Property @{ Location = "$(($FullWidth/2)-150),280"; Size = '300,26'; Font = New-Object System.Drawing.Font("Segoe UI", 14) }
    $panel.Controls.Add($txtSerial)
    $exportClick = {
        if (-not $global:ImagePlaygroundReady) {
            [System.Windows.Forms.MessageBox]::Show("ImagePlayground module isn't available.`n$global:ImagePlaygroundError", "Missing module"); return
        }
        $customer = $txtCustomer.Text.Trim()
        $serial   = $txtSerial.Text.Trim()
        if (-not $customer -or -not $serial) {
            [System.Windows.Forms.MessageBox]::Show("Enter both a customer name and a serial number.", "Missing info"); return
        }
        $barcodeFile = "$env:TEMP\barcode.png"
        $qrFile      = "$env:TEMP\qr.png"
        New-ImageBarCode -Type Code128 -Value $serial -FilePath $barcodeFile
        New-ImageQRCode -Content $serial -FilePath $qrFile
        $bmp  = New-Object System.Drawing.Bitmap(700, 200)
        $g    = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::White)
        $fontBold  = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
        $fontSmall = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        $centerX   = 40 + (400 / 2)
        $g.DrawString($customer, $fontBold, [System.Drawing.Brushes]::Black, ($centerX - $g.MeasureString($customer, $fontBold).Width / 2), 0)
        $barcodeImg = [System.Drawing.Image]::FromFile($barcodeFile)
        $g.DrawImage($barcodeImg, 40, 40, 400, 100)
        $g.DrawString($serial, $fontBold, [System.Drawing.Brushes]::Black, ($centerX - $g.MeasureString($serial, $fontBold).Width / 2), 122)
        $g.DrawString("www.crosstek.co.uk", $fontSmall, [System.Drawing.Brushes]::Black, 135, 160)
        $qrImg = [System.Drawing.Image]::FromFile($qrFile)
        $g.DrawImage($qrImg, 490, -10, 220, 220)
        $barcodeImg.Dispose(); $qrImg.Dispose(); $g.Dispose()
 
        $sfd = New-Object System.Windows.Forms.SaveFileDialog -Property @{ Filter = "PNG Image (*.png)|*.png"; FileName = "Label_$serial.png" }
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $bmp.Save($sfd.FileName, [System.Drawing.Imaging.ImageFormat]::Png) }
        $bmp.Dispose()
    }.GetNewClosure()
    $panel.Controls.Add((New-Button -Text "Export Label" -X (($FullWidth/2)-80) -Y 350 -W 160 -H 40 -Size 12 -OnClick $exportClick))
}

function System-Setup {
    $panel = $script:ContentPanel
    $panel.Controls.Clear()
    $isAdmin = if ((whoami /groups) -match "S-1-5-32-544") {"This Profile has Local Admin"} else {"This Profile does not have Local Admin"}

    # --- Has Local Admin ---
    $panel.Controls.Add((New-Label -Text "System Setup" -X 20 -Y 20 -Size 26))
    $panel.Controls.Add(( New-Label -Text "• $isAdmin" -X 20 -Y 100 -Size 16  ))

    # --- Office Pinned to Taskbar ---
    $panel.Controls.Add(( New-Label -Text "• Office Pinned to Taskbar" -X 20 -Y 140 -Size 16  ))

    # -> App Defaults
    # -> Chrome + Latest Teams + 7Zip installed
    # -> BitLockered + Key Retrieval
    # -> Other existing Profiles for potential removal
    # -> Up to Date
}

function Password-Generator {
    $offsetX = ($FullWidth / 2) - 215
    $offsetY = ($FullHeight / 2) - 150
    $words = @(
        (Get-Random -InputObject @("blue","fast","calm","bold","warm","kind","true","open","free","glow","pure","wise","cool","fair","firm","gold","leaf","peak","rise","star","best","easy","epic","fine","grow","help","idea","jump","keep")),
        (Get-Random -InputObject @("happy","bring","light","quick","reach","dream","learn","teach","share","trust","smile","spark","shine","grasp","boost","guide","value","climb","voice","bloom","brave","clear","fresh","giant","ideal","laugh","merit")),
        (Get-Random -InputObject @("bright","gentle","honest","summer","winter","spring","autumn","wonder","friend","change","create","dazzle","expand","fluent","golden","harbor","invite","joyful","kindle","mentor","nature","option","polish","rhythm","serene","talent","unique","wisdom"))
    )
    $cap = Get-Random -Minimum 0 -Maximum 3
    $words[$cap] = $words[$cap].Substring(0,1).ToUpper() + $words[$cap].Substring(1)
    $special = Get-Random -InputObject @("!","@","#","%","^","?")
    $uniquePassword = -join (@($words[0], $words[1], $words[2], (Get-Random -Minimum 0 -Maximum 10), $special) | Get-Random -Count 5)
    $push = { param($days, $views)
        $r = Invoke-RestMethod -Uri "https://eu.pwpush.com/p.json" -Method Post -Body @{
            "password[payload]" = $uniquePassword; "password[expire_after_days]" = $days; "password[expire_after_views]" = $views
        }
        "https://eu.pwpush.com/p/$($r.url_token)"
    }.GetNewClosure()
    $shortPushUrl = & $push 3 5
    $longPushUrl  = & $push 30 50
    $copy = { param($text) $text | Set-Clipboard; [System.Windows.Forms.MessageBox]::Show("$text has been copied to your clipboard.", "Success") }
    $panel = $script:ContentPanel
    $panel.Controls.Clear()
    $panel.Controls.Add((New-Label -Text "Password Generator" -X 20 -Y 20 -Size 26))
    $panel.Controls.Add((New-Label -Text "Password :" -X (35 + $offsetX) -Y (10 + $offsetY) -Size 20))
    $panel.Controls.Add((New-Button -Text $uniquePassword -X (220 + $offsetX) -Y (12 + $offsetY) -W 200 -H 40 -OnClick { $uniquePassword | Set-Clipboard }.GetNewClosure()))
    $panel.Controls.Add((New-Label -Text "Short PWPush :" -X (10 + $offsetX) -Y (80 + $offsetY) -Size 20))
    $panel.Controls.Add((New-Button -Text "Click to Copy" -X (220 + $offsetX) -Y (82 + $offsetY) -W 200 -H 40 -OnClick { $shortPushUrl | Set-Clipboard }.GetNewClosure()))
    $panel.Controls.Add((New-Label -Text "Long PWPush :" -X (10 + $offsetX) -Y (150 + $offsetY) -Size 20))
    $panel.Controls.Add((New-Button -Text "Click to Copy" -X (220 + $offsetX) -Y (152 + $offsetY) -W 200 -H 40 -OnClick { $longPushUrl | Set-Clipboard }.GetNewClosure()))
}


# --- Tools ---
function Show-Notepad {
    $panel = $script:ContentPanel
    $panel.Controls.Clear()
    $panel.Controls.Add((New-Label -Text "Notepad" -X 20 -Y 20 -Size 26))
    $textArea = New-TextArea -X 5 -Y 90 -W ($FullWidth - 10) -H ($FullHeight - 140)
    $textArea.Text = Load-Data -Key "Notes" -Default ""
    $textArea.Add_TextChanged({
        Save-Data -Key "Notes" -Value $textArea.Text
    }.GetNewClosure())
    $panel.Controls.Add($textArea)
}

function Create-Dev-Environment {
    $outputFile = "$PWD\Companion-Tool.ps1"
    $counter = 1
    while (Test-Path $outputFile) {
        $outputFile = "$PWD\Companion-Tool ($counter).ps1"
        $counter++
    }
    $script:FullScript | Set-Content $outputFile
    [System.Windows.Forms.MessageBox]::Show("Build complete!`n$outputFile", "Done")
}


# --- System ---
function System-Info {
    $panel = $script:ContentPanel
    $panel.Controls.Clear()

    $cs  = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $os  = Get-CimInstance Win32_OperatingSystem

    $panel.Controls.Add((New-Label -Text "System Info" -X 20 -Y 20 -Size 26))
    $panel.Controls.Add((New-Label -Text "Computer Name : $env:COMPUTERNAME `nLogged in as : $env:USERDOMAIN\$env:USERNAME `nProfile Type : $(($profileType = if ((dsregcmd /status) -match "AzureAdJoined\s*:\s*YES") {"Azure Joined"} elseif ($cs.PartOfDomain) {"Domain Joined"} else {"Local"})) `nBitlocker Enabled (requires Admin): $(((Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue).ProtectionStatus -eq 'On')) `n`nManufacturer: $($cs.Manufacturer) `nModel: $($cs.Model) `nSerial Number: $($bios.SerialNumber) `nBIOS Version: $($bios.SMBIOSBIOSVersion) `nCPU: $((Get-CimInstance Win32_Processor).Name.Trim()) `nGPU: $((Get-CimInstance Win32_VideoController | Select-Object -First 1).Name) `nTotal RAM: $([math]::Round($os.TotalVisibleMemorySize/1MB,2)) GB `nRAM Speed (MHz): $((Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1).Speed) `n`nOS: $($os.Caption) `nBuild: $($os.BuildNumber) `nArchitecture: $($os.OSArchitecture) `nLast Update Check: $((New-Object -ComObject Microsoft.Update.AutoUpdate).Results.LastSearchSuccessDate) `n`nInternet: $(if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue) {"Reachable"} else {"Unreachable"}) `nPublic IP: $(try {Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 3} catch {"Unavailable"}) `nPrivate IP: $((Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -notlike "169.254.*" -and $_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress) `nDefault Gateway: $((Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object {$_.IPv4DefaultGateway} | Select-Object -First 1).IPv4DefaultGateway.NextHop)" -X 20 -Y 90))
}

function System-Monitor {
    $panel = $script:ContentPanel
    $panel.Controls.Clear()
    $os = Get-CimInstance Win32_OperatingSystem
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $topProc = Get-Process | Sort-Object CPU -Descending | Select-Object -First 1
    $netAdapters = Get-NetAdapterStatistics -ErrorAction SilentlyContinue
    $counters = Get-Counter '\Processor(_Total)\% Processor Time','\PhysicalDisk(_Total)\Disk Read Bytes/sec','\PhysicalDisk(_Total)\Disk Write Bytes/sec','\PhysicalDisk(_Total)\Current Disk Queue Length' -SampleInterval 1 -MaxSamples 2 -ErrorAction SilentlyContinue
    $panel.Controls.Add((New-Label -Text "System Monitor" -X 20 -Y 20 -Size 26))
    $panel.Controls.Add((New-Label -Text "System Uptime: $((Get-Date) - $os.LastBootUpTime) `nLast Boot Time: $($os.LastBootUpTime) `nPending Reboot Required: $((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')) `nLast Update Installed: $((Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn) `n`nCPU Usage: $([math]::Round(($counters.CounterSamples | Where-Object {$_.Path -like '*% Processor Time*'} | Select-Object -Last 1).CookedValue,1))% `nTop CPU Process: $($topProc.ProcessName) ($([math]::Round($topProc.CPU,1))s) `nRAM Usage: $([math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB,2)) GB / $([math]::Round($os.TotalVisibleMemorySize/1MB,2)) GB ($([math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/$os.TotalVisibleMemorySize)*100,1))%) `nPage File Usage: $([math]::Round((Get-CimInstance Win32_PageFileUsage).CurrentUsage,0)) MB `nTotal Handles: $((Get-Process | Measure-Object Handles -Sum).Sum) `nProcess Count: $((Get-Process).Count) `n`nDisk Usage (C:): $([math]::Round(($disk.Size - $disk.FreeSpace)/1GB,2)) GB / $([math]::Round($disk.Size/1GB,2)) GB ($([math]::Round((1 - ($disk.FreeSpace/$disk.Size))*100,1))%) `nDisk Read Activity: $([math]::Round((($counters.CounterSamples | Where-Object {$_.Path -like '*Disk Read Bytes*'} | Select-Object -Last 1).CookedValue/1KB),1)) KB/s `nDisk Write Activity: $([math]::Round((($counters.CounterSamples | Where-Object {$_.Path -like '*Disk Write Bytes*'} | Select-Object -Last 1).CookedValue/1KB),1)) KB/s `nDisk Queue Length: $([math]::Round(($counters.CounterSamples | Where-Object {$_.Path -like '*Queue Length*'} | Select-Object -Last 1).CookedValue,2)) `n`nNetwork Sent: $([math]::Round((($netAdapters | Measure-Object -Property SentBytes -Sum).Sum)/1MB,2)) MB `nNetwork Received: $([math]::Round((($netAdapters | Measure-Object -Property ReceivedBytes -Sum).Sum)/1MB,2)) MB `nNetwork Adapters Up: $((Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}).Count) / $((Get-NetAdapter).Count) `nStopped Auto Services: $((Get-Service | Where-Object {$_.StartType -eq 'Automatic' -and $_.Status -ne 'Running'}).Count) `nSystem Errors (24h): $((Get-WinEvent -FilterHashtable @{LogName='System';Level=2;StartTime=(Get-Date).AddHours(-24)} -ErrorAction SilentlyContinue).Count) `nBattery Status: $(if ($bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) {"$($bat.EstimatedChargeRemaining)%"} else {"N/A (Desktop)"})" -X 20 -Y 90))
}


# --- Applications ---
function Build-Companion-EXE {
    $outputPath = Join-Path $script:AppRoot "Companion Tool.exe"
    $iconPath   = Join-Path $script:AppRoot "logo.ico"
    $tempScript = Join-Path $env:TEMP "Companion-Tool.build.ps1"
    $marker     = "# ___INJECT_" + "FULLSCRIPT___"
    try {
        $source  = Get-Content -Path $PSCommandPath -Raw
        $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($source))
        if ($source -notmatch [Regex]::Escape($marker)) {
            throw "Injection marker not found in source."
        }
        $replacement = "`$script:FullScript = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`"$encoded`"))"
        $newSource   = $source -replace [Regex]::Escape($marker), $replacement
        Set-Content -Path $tempScript -Value $newSource -Encoding UTF8
        if (Test-Path $iconPath) {
            Invoke-ps2exe -inputFile $tempScript -outputFile $outputPath -noConsole -iconFile $iconPath
        } else {
            Invoke-ps2exe -inputFile $tempScript -outputFile $outputPath -noConsole
        }
        Remove-Item $tempScript -Force
        [System.Windows.Forms.MessageBox]::Show("Built: $outputPath", "Build complete")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Build failed: $($_.Exception.Message)", "Build error")
    }
}

function RDP-EXE {
    $outputFile = "$PWD\RDP-Agent.exe"
    $counter = 1
    while (Test-Path $outputFile) {
        $outputFile = "$PWD\RDP-Agent ($counter).exe"
        $counter++
    }
    $script = @'
param([switch]$RunAsService)
$taskName = "ClarkeAgent"
$installPath = "C:\ProgramData\ClarkeAgent\agent.exe"
if ($RunAsService) {
    while ($true) {
        try {
            Invoke-WebRequest -Uri "https://automation.harrison-home.co.uk/webhook-test/d8a4d3ae-8d71-4316-af21-70e6ffc9e427" -Method Head -UseBasicParsing -TimeoutSec 10 | Out-Null
        } catch {}
        Start-Sleep -Seconds 60
    }
} else {
    New-Item -ItemType Directory -Path (Split-Path $installPath) -Force | Out-Null
    Copy-Item -Path ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -Destination $installPath -Force
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    $action = New-ScheduledTaskAction -Execute $installPath -Argument "-RunAsService"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Seconds 0) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName $taskName
}
'@
    $tempScript = "$env:TEMP\build_temp.ps1"
    $script | Set-Content $tempScript
    Invoke-ps2exe -inputFile $tempScript -outputFile $outputFile -noConsole -iconFile "$PWD\logo.ico"
    Remove-Item $tempScript -Force
    [System.Windows.Forms.MessageBox]::Show("Build complete!`n$outputFile", "Done")
}




















# -------------------- L A U N C H --------------------
Show-Menu
$form.ShowDialog() | Out-Null
