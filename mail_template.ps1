# Parameters must be first!
param(
    [string]$Arg1,
    [string]$Arg2
)

# Initialize variables
$patchNumber = $null
$dateInput = $null

# Parse arguments
if ($Arg1 -and $Arg2) {
    # Two arguments provided - figure out which is which
    if ($Arg1.Length -eq 1 -and $Arg2.Length -eq 4) {
        $patchNumber = $Arg1
        $dateInput = $Arg2
    } elseif ($Arg1.Length -eq 4 -and $Arg2.Length -eq 1) {
        $patchNumber = $Arg2
        $dateInput = $Arg1
    } else {
        Write-Error "Invalid arguments. Usage: .\mailTemplate.ps1 [patch#] [DDMM] or [DDMM] [patch#]"
        Write-Host "Examples:"
        Write-Host "  .\mailTemplate.ps1 2 2710"
        Write-Host "  .\mailTemplate.ps1 2710 2"
        Write-Host "  .\mailTemplate.ps1 2"
        Write-Host "  .\mailTemplate.ps1"
        exit
    }
} elseif ($Arg1) {
    # One argument - determine if it's patch number or date
    if ($Arg1.Length -eq 1) {
        $patchNumber = $Arg1
    } elseif ($Arg1.Length -eq 4) {
        $dateInput = $Arg1
        # Patch number will be prompted below
    } else {
        Write-Error "Invalid argument. Must be 1 digit (patch #) or 4 digits (DDMM)"
        Write-Host "Usage: .\mailTemplate.ps1 [patch#] [DDMM]"
        exit
    }
}

# Prompt for missing patch number if needed
if (-not $patchNumber) {
    $patchNumber = Read-Host "Enter the patch number (e.g., 1, 2, or 3)"
}

# Validate patch number
if ($patchNumber -notmatch '^[1-3]$') {
    Write-Error "Patch number must be 1, 2, or 3"
    exit
}

# Handle date
if ($dateInput) {
    $day = $dateInput.Substring(0, 2)
    $month = $dateInput.Substring(2, 2)
    $year = (Get-Date).Year
    try {
        $dateObj = Get-Date -Year $year -Month $month -Day $day
        $date = $dateObj.ToString("dd/MM/yyyy")
    } catch {
        Write-Warning "Invalid date '$dateInput'. Using today's date."
        $date = Get-Date -Format "dd/MM/yyyy"
    }
} else {
    $date = Get-Date -Format "dd/MM/yyyy"
}

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

# Set up email details
$subject = "FastDelivery - PATCHING T70$patchNumber - CHGT70$patchNumber - $date"
$recipients = "someone@mail.hi; someone_else@isp.tv"
$cc = "mind@your.own; some@mail.no"

# Call the function to send emails
Send-PatchingEmail -patchNumber $patchNumber -date $date -subject $subject
