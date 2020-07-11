# Exchange Online

### Configure junk email settings

https://docs.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell?view=exchange-ps

```powershell
# Run as administrator
Set-ExecutionPolicy RemoteSigned
winrm quickconfig
# Check "Basic = true"
winrm get winrm/config/client/auth
winrm set winrm/config/client/auth @{Basic="true"}
# Stop it
Stop-Service winrm
```

https://rakhesh.com/windows/how-to-undo-changes-made-by-winrm-quickconfig/

```powershell
$UserCredential = Get-Credential
# Enter admin account and password

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking
```

https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-junk-email-settings-on-exo-mailboxes?view=o365-worldwide

```powershell
# Disable the junk email rule in a mailbox
Set-MailboxJunkEmailConfiguration -Identity user@example.com -Enabled $false
# For all users
$All = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
$All | foreach {Set-MailboxJunkEmailConfiguration $_.Name -Enabled $false}
# Check
Get-MailboxJunkEmailConfiguration -Identity user@example.com

# Afer you have finished
Remove-PSSession $Session
```
