# Enable Exchange or 365 automatic reply / out of office on weekdays between 00:00 and 07:00 for a generic mailbox

$identity = "generic@user.com"
$notify = "admin@user.com"
$smtpServer = "fqdn"
$fromAddress = "server@user.com"
$date = get-date
$outfile = "C:\Scripts\AutoReply\Results.txt"
$autoReplyState = (Get-MailboxAutoReplyConfiguration -Identity $identity).AutoReplyState

function setAutomaticReply {
    Set-MailboxAutoReplyConfiguration -Identity $identity -AutoReplyState Enabled
    if ($?) { Send-MailMessage -To $notify -Subject "AutoReply Enabled" -From $fromAddress -SmtpServer $smtpServer }
    Write-Output "Enabled" | Out-File $outfile
}

function disableAutomaticReply {
    Set-MailboxAutoReplyConfiguration -Identity $identity -AutoReplyState Disabled
    if ($?) { Send-MailMessage -To $notify -Subject "AutoReply Disabled" -From $fromAddress -SmtpServer $smtpServer }
    Write-Output "Disabled" | Out-File $outfile
}

# le 6 or dayofweek value so that it turns on at 00:00 on Saturday
if ($autoReplyState -eq "Disabled" -and $date.hour -lt 7 -and $date.DayOfWeek.value__ -le 6) {
    setAutomaticReply
} elseif ($autoReplyState -eq "Enabled" -and $date.hour -ge 7 -and $date.DayOfWeek.value__ -le 5) {
    disableAutomaticReply
} else {
    Write-Output "No action test" | Out-File $outfile
}
