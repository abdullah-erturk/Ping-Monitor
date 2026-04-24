@echo off
set "__SCP=%~f0"
powershell -ExecutionPolicy Bypass -Command "$InputEncoding = [System.Text.Encoding]::UTF8; $OutputEncoding = [System.Text.Encoding]::UTF8; Get-Content -LiteralPath '%~f0' -Encoding UTF8 | Select-Object -Skip 5 | Out-String | iex"
exit /b

Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.Security

# --- Helpers ---
function Protect { param($s); if(!$s){return ""}; $b=[System.Text.Encoding]::UTF8.GetBytes($s); $e=[System.Security.Cryptography.ProtectedData]::Protect($b,$null,[System.Security.Cryptography.DataProtectionScope]::LocalMachine); return [Convert]::ToBase64String($e) }
function Unprotect { param($s); if(!$s){return ""}; try{$b=[Convert]::FromBase64String($s); $d=[System.Security.Cryptography.ProtectedData]::Unprotect($b,$null,[System.Security.Cryptography.DataProtectionScope]::LocalMachine); return [System.Text.Encoding]::UTF8.GetString($d)}catch{return $s} }

# --- Environment ---
$script:isMonitoring = $false
$ScriptPath = $env:__SCP
if (-not $ScriptPath) { $ScriptPath = $MyInvocation.MyCommand.Path }
$scriptDir = Split-Path $ScriptPath -Parent
$langDir = Join-Path $scriptDir "Lang"
$configFile = Join-Path $scriptDir "config.ini"
$logFile = Join-Path $scriptDir "service_log.txt"
$serviceName = "PingMonitorSvc"

# --- Self-Elevation (Auto-Admin) ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        $c = "`$env:__SCP = '$ScriptPath'; `$InputEncoding = [System.Text.Encoding]::UTF8; `$OutputEncoding = [System.Text.Encoding]::UTF8; Get-Content -LiteralPath '$ScriptPath' -Encoding UTF8 | Select-Object -Skip 5 | Out-String | iex"
        Start-Process powershell.exe "-Window Hidden -NoProfile -ExecutionPolicy Bypass -Command `"$c`"" -Verb RunAs
        exit
    } catch { [System.Windows.Forms.MessageBox]::Show("Admin privileges are required!") ; exit }
}

# --- Fallback Strings (English-base) ---
$script:strings = @{ 
    "Title"="Ping Monitor"; "StatusIdle"="Idle"; "About"="About"; 
    "AboutMsg"="This application was coded by Abdullah ERTÜRK.";
    "TestEmail"="Test Email"; "TestEmailSuccess"="Test email sent successfully.";
    "TestEmailFail"="Error: Email could not be sent."; "CopyAll"="Copy All"; "ClearLog"="Clear Log";
    "ServiceStopping"="Stopping..."; "ServiceRemoving"="Removing...";
    "ServiceDesc"="Enterprise monitoring service that tracks targets and provides alerts.";
    "CaptionSuccess"="Success"; "CaptionError"="Error"; "CaptionConfirm"="Confirm"; "CaptionWarning"="Warning";
    "InvalidInterval"="Ping interval must be at least 5 seconds."
}

# --- Theme Colors ---
$bgColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
$accentColor = [System.Drawing.Color]::FromArgb(66, 153, 225)
$txtColor = [System.Drawing.Color]::FromArgb(45, 55, 72)
$saveBtnColor = [System.Drawing.Color]::FromArgb(72, 187, 120)
$editBtnColor = [System.Drawing.Color]::FromArgb(113, 128, 150)
$removeBtnColor = [System.Drawing.Color]::IndianRed
$testBtnColor = [System.Drawing.Color]::FromArgb(155, 89, 182)

# --- GUI Setup ---
$script:form = New-Object System.Windows.Forms.Form
$script:form.Size = "740,680"
$script:form.BackColor = $bgColor
$script:form.FormBorderStyle = "FixedSingle"
$script:form.MaximizeBox = $false
$script:form.StartPosition = "CenterScreen"
$script:form.AcceptButton = $null
$script:form.CancelButton = $null
$script:form.Text = "..."

$fT = "Segoe UI Semibold,12"; $fL = "Segoe UI Semibold,9"; $fI = "Segoe UI,10"; $fB = "Segoe UI Bold,9"

$CL = { param($T, $Top, $Left=40) $l=New-Object System.Windows.Forms.Label; $l.Text=$T; $l.Top=$Top; $l.Left=$Left; $l.AutoSize=$true; $l.Font=$fL; $l.ForeColor=$txtColor; $script:form.Controls.Add($l); return $l }
$CI = { param($Top, $Left=40, $W=300, $P=$false, $M=$false) $i=New-Object System.Windows.Forms.TextBox; $i.Top=$Top; $i.Left=$Left; $i.Width=$W; $i.Font=$fI; $i.BackColor=[System.Drawing.Color]::White; $i.BorderStyle="FixedSingle"; if($M){$i.Multiline=$true; $i.Height=130; $i.ScrollBars="Vertical"}else{$i.Height=25}; if($P){$i.PasswordChar='*'}; $script:form.Controls.Add($i); return $i }
$CB = { param($T, $Top, $Left, $W, $C) $b=New-Object System.Windows.Forms.Button; $b.FlatStyle="Flat"; $b.BackColor=$C; $b.ForeColor=[System.Drawing.Color]::White; $b.Top=$Top; $b.Left=$Left; $b.Width=$W; $b.Height=35; $b.Font=$fB; $b.FlatAppearance.BorderSize=0; $b.Text=$T; $script:form.Controls.Add($b); return $b }

# UI Components
$script:lblH = New-Object System.Windows.Forms.Label; $script:lblH.Font=$fT; $script:lblH.ForeColor=$accentColor; $script:lblH.Top=15; $script:lblH.Left=40; $script:lblH.AutoSize=$true; $script:form.Controls.Add($script:lblH)

# -- Left Column --
$script:lblTarget = &$CL "..." 55 40; $script:txtTarget = &$CI 80 40 320 $false $true
$script:lblRecipients = &$CL "..." 220 40; $script:txtRecipients = &$CI 245 40 320 $false $true

# -- Right Column --
$script:lblSender = &$CL "..." 55 380; $script:txtSender = &$CI 80 380 320
$script:lblSmtpServer = &$CL "..." 110 380; $script:txtSmtpServer = &$CI 135 380 320
$script:lblSmtpPort = &$CL "..." 165 380; $script:txtSmtpPort = &$CI 190 380 320
$script:lblSmtpUser = &$CL "..." 220 380; $script:txtSmtpUser = &$CI 245 380 320
$script:lblSmtpPass = &$CL "..." 275 380; $script:txtSmtpPass = &$CI 300 380 320 $true
$script:lblInterval = &$CL "..." 330 380; $script:txtInterval = &$CI 355 380 120
$script:txtInterval.Text = "60"
$script:lastValidInterval = "60"

$script:cmbLang = New-Object System.Windows.Forms.ComboBox; $script:cmbLang.FlatStyle="Flat"; $script:cmbLang.DropDownStyle="DropDownList"; [void]$script:cmbLang.Items.Add("Turkish"); [void]$script:cmbLang.Items.Add("English"); $script:cmbLang.Top=355; $script:cmbLang.Left=520; $script:cmbLang.Width=110; $script:form.Controls.Add($script:cmbLang)

# -- Bottom Area --
$script:btnSave = &$CB "Save" 410 40 120 $saveBtnColor
$script:btnEdit = &$CB "Edit" 410 175 120 $editBtnColor; $script:btnEdit.Enabled=$false
$script:btnTestMail = &$CB "Test" 410 310 120 $testBtnColor
$script:btnShowLog = &$CB "Log" 410 500 180 $editBtnColor
$script:btnClearLog = &$CB "Clear" 460 500 180 $removeBtnColor

$script:btnInstallSvc = &$CB "Install" 460 40 160 $accentColor
$script:btnUninstallSvc = &$CB "Uninstall" 460 215 160 $removeBtnColor

$pnl = New-Object System.Windows.Forms.Panel; $pnl.Top=515; $pnl.Left=40; $pnl.Width=640; $pnl.Height=75; $pnl.BackColor=[System.Drawing.Color]::FromArgb(237, 242, 247); $script:form.Controls.Add($pnl)
$script:lblSvcT = New-Object System.Windows.Forms.Label; $script:lblSvcT.Font=$fL; $script:lblSvcT.Top=10; $script:lblSvcT.Left=15; $script:lblSvcT.AutoSize=$true; $pnl.Controls.Add($script:lblSvcT)
$script:lblSvcV = New-Object System.Windows.Forms.Label; $script:lblSvcV.Font="Segoe UI Semibold,11"; $script:lblSvcV.Top=35; $script:lblSvcV.Left=15; $script:lblSvcV.AutoSize=$true; $pnl.Controls.Add($script:lblSvcV)

# Status Bar
$strip = New-Object System.Windows.Forms.StatusStrip; $strip.SizingGrip = $false
$script:statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel; $strip.Items.Add($script:statusLabel) | Out-Null
$spacer = New-Object System.Windows.Forms.ToolStripStatusLabel; $spacer.Spring = $true; $strip.Items.Add($spacer) | Out-Null
$script:aboutLabel = New-Object System.Windows.Forms.ToolStripStatusLabel; $script:aboutLabel.IsLink = $true; $script:aboutLabel.LinkBehavior = "HoverUnderline"; $strip.Items.Add($script:aboutLabel) | Out-Null
$script:form.Controls.Add($strip)

# --- Logic ---

function GetHtmlReport {
    param($Title, $Status, $Detail)
    $color = if($Status -eq "SUCCESS"){"#38a169"}else{"#e53e3e"}
    return @"
<html><body style='font-family:Segoe UI,Tahoma,Arial;color:#2d3748;line-height:1.6;background-color:#f7fafc;padding:20px;'>
<div style='max-width:600px;margin:0 auto;background:#fff;padding:40px;border-radius:10px;box-shadow:0 4px 6px rgba(0,0,0,0.1);'>
<h2 style='color:#4299e1;margin-top:0;'>$Title</h2>
<hr style='border:0;border-top:1px solid #edf2f7;margin:20px 0;'>
<p style='font-size:16px;'><b>Status:</b> <span style='color:$color;'>$Status</span></p>
<p><b>Target:</b> $($script:txtTarget.Text)</p>
<p><b>Timestamp:</b> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
<div style='background:#fefcbf;padding:15px;border-left:4px solid #ecc94b;margin:20px 0;'>$Detail</div>
<p style='font-size:12px;color:#718096;margin-top:40px;'>This automated report was generated by <b>Ping Monitor</b>.<br>Coded by <b>Abdullah ERT&Uuml;RK</b><br><a href='https://github.com/abdullah-erturk' style='color:#4299e1;text-decoration:none;'>github.com/abdullah-erturk</a><br><a href='https://erturk-dev.netlify.app' style='color:#4299e1;text-decoration:none;'>erturk-dev.netlify.app</a></p>
</div></body></html>
"@
}

function SendMail {
    param($IsTest=$false)
    try {
        $smtp = New-Object System.Net.Mail.SmtpClient($script:txtSmtpServer.Text, [int]$script:txtSmtpPort.Text)
        $smtp.UseDefaultCredentials = $false
        $smtp.EnableSsl = $true
        $smtp.Credentials = New-Object System.Net.NetworkCredential($script:txtSmtpUser.Text.Trim(), $script:txtSmtpPass.Text.Trim())
        
        $receivers = $script:txtRecipients.Text.Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries)
        if($receivers.Count -eq 0){ throw "No recipients" }
        
        $msg = New-Object System.Net.Mail.MailMessage
        $msg.From = New-Object System.Net.Mail.MailAddress($script:txtSender.Text.Trim(), "Ping Monitor")
        $receivers | % { $msg.To.Add($_) }
        
        $subject = "Ping Alert: target is down!"
        $repTitle = "Ping Alert!"; $repStatus = "FAILED"; $repDetail = "Target $($script:txtTarget.Text) is unreachable."
        
        if($IsTest){
            $subject = "Ping Monitor: Test Connection"
            $repTitle = "Connection Test"; $repStatus = "SUCCESS"; $repDetail = "Your SMTP settings are correctly configured."
        }

        $msg.Subject = $subject
        $msg.IsBodyHtml = $true
        $msg.Body = GetHtmlReport $repTitle $repStatus $repDetail
        
        $smtp.Send($msg)
        return $true
    } catch { 
        throw "SMTP Auth Error for $($script:txtSmtpUser.Text): " + $_.Exception.Message
    }
}

function ToggleInputs {
    param($E)
    @($script:txtTarget, $script:txtRecipients, $script:txtSender, $script:txtSmtpServer, $script:txtSmtpPort, $script:txtSmtpUser, $script:txtSmtpPass, $script:txtInterval) | % { $_.ReadOnly = -not $E; $_.BackColor = if($E){[System.Drawing.Color]::White}else{[System.Drawing.Color]::FromArgb(235, 237, 240)} }
    $script:btnSave.Enabled = $E; $script:btnEdit.Enabled = -not $E; $script:btnTestMail.Enabled = $true
    $script:cmbLang.Enabled = $true
}

# --- Timer for Auto-Refresh and GUI Ping ---
$script:mainTimer = New-Object System.Windows.Forms.Timer
$script:mainTimer.Interval = 5000
$script:mainTimer.Add_Tick({
    # 1. Refresh Service Status (Lightweight)
    $isSvcRunning = RefreshSvcStatus

    # 2. GUI Monitoring (Live Feedback) - only if monitoring is enabled AND service is NOT running
    if($script:isMonitoring -and !$isSvcRunning) {
        $targets = $script:txtTarget.Text.Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries)
        if($targets.Count -gt 0) {
            $results = @()
            foreach($t in $targets) {
                $tr = $t.Trim(); if(!$tr){continue}
                try {
                    $p = New-Object System.Net.NetworkInformation.Ping
                    # Adjusted timeout to 500ms for better balance between speed and reliability
                    $res = $p.Send($tr, 500)
                    if($res.Status -eq "Success") { $results += "$($tr): OK" }
                    else { $results += "$($tr): FAIL" }
                } catch { $results += "$($tr): ERR" }
            }
            $script:statusLabel.Text = "$($script:strings.StatusMonitoring) | " + ($results -join ", ")
        }
    }
})

function RefreshSvcStatus {
    try { $svc = Get-Service $serviceName -ErrorAction SilentlyContinue
        if(!$svc){ $script:lblSvcV.Text=$script:strings.ServiceNotInstalled; $script:lblSvcV.ForeColor=[System.Drawing.Color]::Gray; return $false }
        elseif($svc.Status -eq "Running"){ 
            if($script:lblSvcV.Text -ne $script:strings.ServiceRunning){ $script:lblSvcV.Text=$script:strings.ServiceRunning; $script:lblSvcV.ForeColor=[System.Drawing.Color]::Green }
            if(!$script:isMonitoring) { $script:isMonitoring = $true; ToggleInputs $false; $script:statusLabel.Text=$script:strings.StatusMonitoring }
            return $true
        }
        else { 
            if($script:lblSvcV.Text -ne $script:strings.ServiceStopped){ 
                $script:lblSvcV.Text=$script:strings.ServiceStopped; $script:lblSvcV.ForeColor=[System.Drawing.Color]::Red 
                # Auto-unlock UI if service is stopped externally
                if($script:isMonitoring) { $script:isMonitoring = $false; ToggleInputs $true; $script:statusLabel.Text=$script:strings.StatusIdle }
            }
            return $false
        }
    } catch { return $false }
}

function ApplyLanguage {
    param($IsSilent=$false)
    $script:strings = @{ 
        "Title"="Ping Monitor"; "TargetAddress"="Target IP/Domain Addresses (One per line)"; "RecipientEmails"="Email Addresses"; "SenderEmail"="Sender Email"; 
        "SMTPServer"="SMTP Server"; "SMTPPort"="Port (587 Rec., 465 fail)"; "SMTPUser"="Username"; "SMTPPass"="Password or App Password"; 
        "Save"="Save"; "Edit"="Edit"; "StatusIdle"="Idle"; "StatusMonitoring"="Monitoring"; 
        "InstallService"="Install Service"; "UninstallService"="Uninstall Service"; "ServiceStatusLabel"="Service Status:"; 
        "ServiceNotInstalled"="Not installed"; "ServiceRunning"="RUNNING"; 
        "ServiceStopped"="STOPPED"; "ShowLog"="Show Log"; "About"="About"; "AboutMsg"="This application was coded by Abdullah ERTÜRK."; 
        "LogCaption"="Service Log"; "LogNotFound"="Log Not Found."; "TestEmail"="Test E-Mail"; 
        "TestEmailSuccess"="Test E-Mail sent successfully."; "TestEmailFail"="Error: E-Mail could not be sent.";
        "InvalidInput"="Error: Please enter a valid target address."; "AdminRequired"="Error: Administrator privileges are required.";
        "ServiceInstalled"="Service has been successfully installed."; "ServiceRemoved"="Service has been successfully removed.";
        "PingInterval"="Ping Interval (Seconds)"; "CopyAll"="Copy All"; "ClearLog"="Clear Log";
        "ServiceStopping"="Stopping..."; "ServiceRemoving"="Removing...";
        "ServiceDesc"="Enterprise monitoring service for tracking targets and alerting.";
        "CaptionSuccess"="Success"; "CaptionError"="Error"; "CaptionConfirm"="Confirm"; "CaptionWarning"="Warning"; "ClearLogConfirm"="Log file will be cleared. Do you want to continue?";
        "InvalidInterval"="Ping interval must be at least 5 seconds."
    }
    $lang = $script:cmbLang.SelectedItem; if (-not $lang) { $lang = "Turkish" }
    $langFile = Join-Path $langDir "$lang.ini"
    if(Test-Path $langFile){
        try { 
            $lines = Get-Content -LiteralPath $langFile -Encoding UTF8 -ErrorAction SilentlyContinue
            foreach($line in $lines){ if($line -match "([^=]+)=(.*)"){ $script:strings[$Matches[1].Trim()]=$Matches[2].Trim() } } 
        } catch {} 
    }

    $script:form.Text = "Ping Monitor | made by Abdullah ERTURK"; $script:lblH.Text = "Ping Monitor"
    $script:lblTarget.Text=$script:strings.TargetAddress; $script:lblRecipients.Text=$script:strings.RecipientEmails
    $script:lblSender.Text=$script:strings.SenderEmail; $script:lblSmtpServer.Text=$script:strings.SMTPServer
    $script:lblSmtpPort.Text=$script:strings.SMTPPort; $script:lblSmtpUser.Text=$script:strings.SMTPUser; $script:lblSmtpPass.Text=$script:strings.SMTPPass
    $script:lblInterval.Text=$script:strings.PingInterval; $script:descText = $script:strings.ServiceDesc
    $script:btnSave.Text=$script:strings.Save; $script:btnEdit.Text=$script:strings.Edit; $script:btnTestMail.Text=$script:strings.TestEmail
    $script:btnInstallSvc.Text=$script:strings.InstallService; $script:btnUninstallSvc.Text=$script:strings.UninstallService
    $script:lblSvcT.Text=$script:strings.ServiceStatusLabel; $script:btnShowLog.Text=$script:strings.ShowLog; $script:btnClearLog.Text=$script:strings.ClearLog
    $script:aboutLabel.Text = $script:strings.About
    
    if(!$IsSilent) { $script:statusLabel.Text = if($script:isMonitoring){$script:strings.StatusMonitoring}else{$script:strings.StatusIdle} }

    RefreshSvcStatus
}

function LoadConfig {
    if (Test-Path $configFile) { try { $c=@{}; foreach($l in [System.IO.File]::ReadLines($configFile, [System.Text.Encoding]::UTF8)){ if($l -match "([^=]+)=(.*)"){ $c[$Matches[1].Trim()]=$Matches[2].Trim() } }
    if($c.Target){$script:txtTarget.Text=$c.Target.Replace(";", "`r`n")}; if($c.Sender){$script:txtSender.Text=$c.Sender}; if($c.SmtpServer){$script:txtSmtpServer.Text=$c.SmtpServer}; if($c.SmtpPort){$script:txtSmtpPort.Text=$c.SmtpPort}; if($c.SmtpUser){$script:txtSmtpUser.Text=$c.SmtpUser}
    if($c.SmtpPass){$script:txtSmtpPass.Text=Unprotect $c.SmtpPass}; if($c.PingInterval){$script:txtInterval.Text=$c.PingInterval; $script:lastValidInterval=$c.PingInterval}
    if($c.Language){$idx=$script:cmbLang.Items.IndexOf($c.Language); if($idx -ne -1){$script:cmbLang.SelectedIndex=$idx}}; if($c.Recipients){$script:txtRecipients.Text=$c.Recipients.Replace(";", "`r`n")} } catch {} }
    if($script:cmbLang.SelectedIndex -eq -1){$script:cmbLang.SelectedIndex=0}
}

# --- Event Handlers ---
$script:cmbLang.Add_SelectedIndexChanged({ ApplyLanguage })

$script:btnTestMail.Add_Click({
    $script:btnTestMail.Enabled = $false
    try {
        if(SendMail -IsTest $true){ [System.Windows.Forms.MessageBox]::Show($script:strings.TestEmailSuccess) }
        else { [System.Windows.Forms.MessageBox]::Show($script:strings.TestEmailFail + " (Check logs/settings)") }
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message)
    }
    $script:btnTestMail.Enabled = $true
})

$script:aboutLabel.add_Click({
    $a = New-Object System.Windows.Forms.Form; $a.Text = $script:strings.About; $a.Size = "450,340"; $a.StartPosition = "CenterParent"; $a.FormBorderStyle = "FixedDialog"; $a.MaximizeBox=$false; $a.BackColor=$bgColor
    $l1 = New-Object System.Windows.Forms.Label; $l1.Text = $script:strings.AboutMsg; $l1.Top=20; $l1.Left=20; $l1.Width=400; $l1.Height=30; $l1.Font=$fB; $l1.TextAlign="MiddleCenter"; $a.Controls.Add($l1)
    $lD = New-Object System.Windows.Forms.Label; $lD.Text = $script:strings.ServiceDesc; $lD.Top=55; $lD.Left=30; $lD.Width=380; $lD.Height=80; $lD.Font=$fL; $lD.TextAlign="MiddleCenter"; $a.Controls.Add($lD)
    $lG = New-Object System.Windows.Forms.LinkLabel; $lG.Text = "github.com/abdullah-erturk"; $lG.Top=145; $lG.Left=20; $lG.Width=400; $lG.Height=30; $lG.Font=$fI; $lG.TextAlign="MiddleCenter"; $lG.Add_Click({ [System.Diagnostics.Process]::Start("https://github.com/abdullah-erturk") }); $a.Controls.Add($lG)
    $lN = New-Object System.Windows.Forms.LinkLabel; $lN.Text = "erturk.netlify.app"; $lN.Top=185; $lN.Left=20; $lN.Width=400; $lN.Height=30; $lN.Font=$fI; $lN.TextAlign="MiddleCenter"; $lN.Add_Click({ [System.Diagnostics.Process]::Start("https://erturk.netlify.app") }); $a.Controls.Add($lN)
    $bOK = New-Object System.Windows.Forms.Button; $bOK.Text="OK"; $bOK.Top=240; $bOK.Left=175; $bOK.Width=100; $bOK.Height=35; $bOK.FlatStyle="Flat"; $bOK.BackColor=$accentColor; $bOK.ForeColor=[System.Drawing.Color]::White; $bOK.Add_Click({ $a.Close() }); $a.Controls.Add($bOK)
    $a.ShowDialog()
})

$script:btnShowLog.Add_Click({ 
    if(Test-Path $logFile){ 
        $m = New-Object System.Windows.Forms.Form; $m.Text=$script:strings.LogCaption; $m.Size="600,450"; $m.StartPosition="CenterParent"; $m.BackColor=$bgColor
        $txt = New-Object System.Windows.Forms.TextBox; $txt.Multiline=$true; $txt.ReadOnly=$true; $txt.Dock="Fill"; $txt.ScrollBars="Both"; $txt.Font="Consolas,9"
        $lines = ([System.IO.File]::ReadAllLines($logFile, [System.Text.Encoding]::UTF8) | Select-Object -Last 100) -join "`r`n"
        $txt.Text = $lines; $txt.SelectionStart = $txt.Text.Length; $txt.ScrollToCaret()
        
        $pnlB = New-Object System.Windows.Forms.Panel; $pnlB.Height = 50; $pnlB.Dock = "Bottom"
        $btnCopy = New-Object System.Windows.Forms.Button; $btnCopy.Text = $script:strings.CopyAll; $btnCopy.Width = 120; $btnCopy.Height = 30; $btnCopy.Left = 20; $btnCopy.Top = 10; $btnCopy.FlatStyle = "Flat"; $btnCopy.BackColor = $accentColor; $btnCopy.ForeColor = [System.Drawing.Color]::White; $btnCopy.Font = $fB
        $btnCopy.Add_Click({ if($txt.Text){ [System.Windows.Forms.Clipboard]::SetText($txt.Text) } })
        $pnlB.Controls.Add($btnCopy)
        
        $m.Controls.Add($txt); $m.Controls.Add($pnlB); $m.ShowDialog()
    } else { [System.Windows.Forms.MessageBox]::Show($script:strings.LogNotFound) } 
})

$script:btnClearLog.Add_Click({ 
    try { 
        if(Test-Path $logFile){ 
            $r = [System.Windows.Forms.MessageBox]::Show($script:strings.ClearLogConfirm, $script:strings.CaptionConfirm, 4, 32)
            if($r -eq "Yes") {
                [System.IO.File]::WriteAllText($logFile, "", [System.Text.Encoding]::UTF8)
                [System.Windows.Forms.MessageBox]::Show($script:strings.ClearLog + ": OK", $script:strings.CaptionSuccess, 0, 64) 
            }
        } 
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, $script:strings.CaptionError, 0, 16) }
})

$script:btnSave.Add_Click({
    if([string]::IsNullOrWhiteSpace($script:txtTarget.Text)){ [System.Windows.Forms.MessageBox]::Show($script:strings.InvalidInput); return }
    $iv = 0; if(![int]::TryParse($script:txtInterval.Text, [ref]$iv) -or $iv -lt 5) { 
        [System.Windows.Forms.MessageBox]::Show($script:strings.InvalidInterval, $script:strings.CaptionWarning, 0, 48)
        $script:txtInterval.Text = $script:lastValidInterval
        return 
    }
    $script:lastValidInterval = $iv.ToString()
    $targets = $script:txtTarget.Text.Replace("`r`n", ";")
    $pass = Protect $script:txtSmtpPass.Text
    $cfg="[Config]`r`nTarget=$($targets)`r`nRecipients=$($script:txtRecipients.Text.Replace("`r`n",";"))`r`nSender=$($script:txtSender.Text)`r`nSmtpServer=$($script:txtSmtpServer.Text)`r`nSmtpPort=$($script:txtSmtpPort.Text)`r`nSmtpUser=$($script:txtSmtpUser.Text)`r`nSmtpPass=$($pass)`r`nLanguage=$($script:cmbLang.SelectedItem)`r`nPingInterval=$($script:txtInterval.Text)"
    [System.IO.File]::WriteAllText($configFile, $cfg, [System.Text.Encoding]::UTF8); $script:isMonitoring=$true; ToggleInputs $false
})

$script:btnEdit.Add_Click({ $script:isMonitoring=$false; ToggleInputs $true; $script:statusLabel.Text=$script:strings.StatusIdle })

$script:btnInstallSvc.Add_Click({
    $exe = Join-Path $scriptDir "PingMonitorSvc.exe"; $cs = @'
using System; using System.IO; using System.Net; using System.Net.Mail; using System.Net.NetworkInformation; using System.ServiceProcess; using System.Threading; using System.Collections.Generic; using System.Text; using System.Linq; using System.Security.Cryptography; using System.Threading.Tasks;
public class PingMonitorSvc : ServiceBase {
    private Thread _w; private volatile bool _r; private readonly object _l = new object();
    static void Main() { ServiceBase.Run(new PingMonitorSvc()); }
    public PingMonitorSvc() { ServiceName = "PingMonitorSvc"; }
    protected override void OnStart(string[] a) { _r=true; _w=new Thread(Loop){IsBackground=true}; _w.Start(); }
    protected override void OnStop() { _r=false; if(_w!=null)_w.Join(2000); }
    private Dictionary<string,string> Ri(string p){ var d=new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase); if(!File.Exists(p))return d; try{foreach(var l in File.ReadAllLines(p,Encoding.UTF8)){ string r=l.Trim(); if(string.IsNullOrEmpty(r)||r.StartsWith(";")||r.StartsWith("["))continue; int e=r.IndexOf('='); if(e>0) d[r.Substring(0,e).Trim()]=r.Substring(e+1).Trim(); }}catch{} return d; }
    private string Up(string s){ if(string.IsNullOrEmpty(s))return ""; try{ var b=Convert.FromBase64String(s); var d=ProtectedData.Unprotect(b,null,DataProtectionScope.LocalMachine); return Encoding.UTF8.GetString(d); }catch{ return s; } }
    private void L(string g, string m){ try{ var lines=File.Exists(g)?File.ReadAllLines(g).ToList():new List<string>(); lines.Add(DateTime.Now+" "+m); if(lines.Count>1000)lines.RemoveAt(0); File.WriteAllLines(g,lines); }catch{} }
    private void Sm(Dictionary<string,string> i, string t, bool rec, string g){
        try{ 
            using(var s=new SmtpClient(i["SmtpServer"],int.Parse(i["SmtpPort"]))){ 
                s.EnableSsl=true; s.Credentials=new NetworkCredential(i["SmtpUser"],Up(i["SmtpPass"]));
                var m = new MailMessage(); m.From = new MailAddress(i["Sender"], "Ping Monitor Service");
                foreach(var r in i["Recipients"].Split(';')) if(!string.IsNullOrEmpty(r)) m.To.Add(r);
                m.Subject = (rec?"RECOVERY: ":"Ping Alert: ") + t; m.IsBodyHtml = true;
                string color = rec?"#38a169":"#e53e3e"; string status = rec?"RECOVERED (UP)":"FAILED (DOWN)"; string tit = rec?"Target Restored":"Ping Alert!";
                m.Body = string.Format(@"<html><body style='font-family:Segoe UI;background:#f7fafc;padding:20px;'><div style='max-width:600px;margin:0 auto;background:#fff;padding:40px;border-radius:10px;box-shadow:0 4px 6px rgba(0,0,0,0.1);border-top:5px solid {0};'>
                    <h2 style='color:#4299e1;margin-top:0;'>{1}</h2><p><b>Target:</b> {2}</p><p><b>Status:</b> <span style='color:{0};'>{3}</span></p><hr style='border:0;border-top:1px solid #edf2f7;margin:20px 0;'>
                    <p style='font-size:12px;color:#718096;margin-top:40px;'>This automated report was generated by <b>Ping Monitor</b>.<br>Coded by <b>Abdullah ERTURK</b><br><a href='https://github.com/abdullah-erturk' style='color:#4299e1;text-decoration:none;'>github.com/abdullah-erturk</a><br><a href='https://erturk.netlify.app' style='color:#4299e1;text-decoration:none;'>erturk.netlify.app</a></p></div></body></html>", color, tit, t, status);
                s.Send(m); 
            }
        }catch(Exception ex){ L(g, "Mail Err: " + ex.Message); }
    }
    private void Loop(){
        string d = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\'); string c = Path.Combine(d,"config.ini"); string g = Path.Combine(d,"service_log.txt");
        L(g,"Started."); var fc = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase); var la = new Dictionary<string, DateTime>(StringComparer.OrdinalIgnoreCase);
        while(_r){
            try {
                var i=Ri(c); if(!i.ContainsKey("Target")){Thread.Sleep(5000);continue;}
                var ts = i["Target"].Split(new[] {';'}, StringSplitOptions.RemoveEmptyEntries);
                int wait = i.ContainsKey("PingInterval")?int.Parse(i["PingInterval"]):60;
                Parallel.ForEach(ts, t => {
                    string tr = t.Trim(); if(string.IsNullOrEmpty(tr)) return;
                    bool ok=false; try{using(var p=new Ping()){ok=(p.Send(tr,3000).Status==IPStatus.Success);}}catch{ok=false;}
                    bool sendAlert=false; bool sendRec=false; int currentFc = 0;
                    lock(_l){
                        if(!fc.ContainsKey(tr)) fc[tr]=0;
                        if(ok){
                            if(fc[tr]>=6){ sendRec=true; }
                            fc[tr]=0;
                        } else { 
                            fc[tr]++; currentFc = fc[tr];
                            if(fc[tr]>=6){
                                if(!la.ContainsKey(tr) || (DateTime.Now - la[tr]).TotalMinutes >= 30){
                                    sendAlert=true; la[tr]=DateTime.Now;
                                }
                                fc[tr]=6;
                            }
                        }
                    }
                    if(sendRec){ 
                        lock(_l){ if(la.ContainsKey(tr)) la.Remove(tr); }
                        L(g, "Recovered: "+tr); Sm(i, tr, true, g); 
                    }
                    if(sendAlert){ L(g, "Alert Sent: "+tr); Sm(i, tr, false, g); }
                    if(!ok && currentFc > 0) L(g, "Fail " + currentFc + ": " + tr);
                });
                for(int j=0; j<wait && _r; j++) Thread.Sleep(1000);
            } catch(Exception ex){ L(g, "Loop Err: "+ex.Message); Thread.Sleep(5000); }
        }
    }
}
'@
    try {
        if(Get-Service $serviceName -ErrorAction SilentlyContinue){ 
            $script:lblSvcV.Text = $script:strings.ServiceStopping; Stop-Service $serviceName -ErrorAction SilentlyContinue; Start-Sleep -s 3; sc.exe delete $serviceName; Start-Sleep -s 1
        }
        Add-Type -TypeDefinition $cs -OutputAssembly $exe -OutputType ConsoleApplication -ReferencedAssemblies "System","System.ServiceProcess","System.Net","System.Security","System.Core" -ErrorAction Stop
        New-Service $serviceName -BinaryPathName "`"$exe`"" -DisplayName "Ping Monitor Service" -StartupType Automatic -ErrorAction Stop
        sc.exe description $serviceName "$($script:descText)"
        sc.exe config $serviceName obj= "LocalSystem"; Start-Service $serviceName; ApplyLanguage
        [System.Windows.Forms.MessageBox]::Show($script:strings.ServiceInstalled, $script:strings.CaptionSuccess, 0, 64)
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, $script:strings.CaptionError, 0, 16) }
})

$script:btnUninstallSvc.Add_Click({
    try {
        if(Get-Service $serviceName -ErrorAction SilentlyContinue){
            $script:lblSvcV.Text = $script:strings.ServiceRemoving; $script:lblSvcV.ForeColor = [System.Drawing.Color]::Orange
            Stop-Service $serviceName -ErrorAction SilentlyContinue; Start-Sleep -s 3;
            sc.exe delete $serviceName; Start-Sleep -s 1
            ApplyLanguage; [System.Windows.Forms.MessageBox]::Show($script:strings.ServiceRemoved, $script:strings.CaptionSuccess, 0, 64)
        }
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, $script:strings.CaptionError, 0, 16) }
})

# --- Execution ---
$script:form.Add_Shown({ LoadConfig; ApplyLanguage; $script:mainTimer.Start() })
$script:form.ShowDialog()
