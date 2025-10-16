function Send-PatchingEmail {
  param(
      [string]$patchNumber,
      [string]$date,
      [string]$subject
  )

  # Define the list of nodes for each T7 number
  $nodesByPatchNumber = @{
      "1" = "sev-s231", "sev-s234", "sev-s237", "sev-s240", "sev-s245", "sev-s248", "sev-s250", "sev-s251", "sev-s256", "sev-s259", "sev-s261", "sev-s268"
      "2" = "sev-s232", "sev-s235", "sev-s238", "sev-s241", "sev-s243", "sev-s246", "sev-s249", "sev-s252", "sev-s253", "sev-s257", "sev-s262", "sev-s269"
      "3" = "sev-s233", "sev-s236", "sev-s239", "sev-s242", "sev-s244", "sev-s247", "sev-s254", "sev-s255", "sev-s258", "sev-s260", "sev-s263"
  }

  # Determine nodes based on selected T7 number
  $nodes = $nodesByPatchNumber[$patchNumber]

  # Define email template for both "start" and "end" emails
  $bullet = [char]0x2022  # This will create a bullet point (•)

  $emailTemplateStart = @"
Good morning,

This activity will begin shortly.

Please ignore alarms from the following machines:

$($nodes | ForEach-Object { "$bullet $_" } | Out-String)

Notification of end of activity will follow with relative outcome
"@

  $emailTemplateEnd = @"
  Good morning,
  
  The activity has been successfully completed.
  
  It is possible to restart monitoring for the following nodes:
  
  $($nodes | ForEach-Object { "$bullet $_" } | Out-String)

"@

  # Create Outlook application object
  try {
    $outlook = New-Object -ComObject Outlook.Application
  } catch {
    Write-Error "Failed to create Outlook COM object. Is Outlook installed and accessible?"
    return
  }

  # Loop for creating both "start" and "end" emails
  foreach ($emailType in @("Start", "End")) {
    # Create a new mail item
    $mailItem = $outlook.CreateItem(0)  # 0 represents olMailItem

    # Set recipients for the email
    $mailItem.To = $recipients
    $mailItem.CC = $cc
    
    # Set body for the email
    if ($emailType -eq "Start") {
      # Set subject for the email
      $mailItem.Subject = "$subject - 22:00 - $emailType"
      
      $mailItem.Body = $emailTemplateStart
    } else {
      # Set subject for the email
      $mailItem.Subject = "$subject - 02:00 - $emailType"
      
      $mailItem.Body = $emailTemplateEnd
    }
    
    # Display the email message
    $mailItem.Display()
  }
}

# Prompt user for variables
$patchNumber = Read-Host "Enter the patch number (e.g., 1, 2, or 3)"
$date = Get-Date -Format "dd/MM/yyyy"
$subject = "ProjectName - PATCHING T70$patchNumber - Company - CHGT70$patchNumber - $date"
$recipients = "someone@no.it"
$cc = "anyone@no.it"

# Call the function to send emails
Send-PatchingEmail -patchNumber $patchNumber -date $date -subject $subject
