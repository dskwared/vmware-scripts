############################################################
# Script: find-host-profiles-in-vcenter.ps1
# Author: Doug DeFrank
# Date: 2019-07-30
#
# Purpose: Find Host Profiles (incl. versions) in vCenter.
############################################################

Write-Host `n "This script will find host profiles that are defined in vCenter and report the Name, Version, and Description of each." `n

### Define the date in the yyyyMMdd format
$date = Get-Date -format "yyyyMMdd"

### Prompt user for vCenter Server name, and connect to it
$vCenterServer = Read-Host -Prompt 'Enter the FQDN of the vCenter Server you want to connect to (ex. vcenter.domain.com)'

### This Try/Catch statement will stop the script if a vCenter Server doesn't exist, a bad username/password is entered, etc.
Try {
    Connect-VIServer -Server $vCenterServer -ErrorAction Stop | Out-Null
}

Catch {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Could not connect to the vCenter Server [$vCenterServer]." `n
    Exit
}

### Get all VMs in the chosen cluster
$HostProfiles = Get-VMHostProfile | Sort-Object | Select-Object Name,@{N='Version';E={$_.ExtensionData.Config.ApplyProfile.ProfileVersion}},Description

if ($HostProfiles) {
    ### Ask the user if they want to export the results to a CSV file
    Do {
        Write-Host `n "Do you want to export the results to a CSV file?"
        Write-Host "1.) Yes"
        Write-Host "2.) No"
        $csvexportyn = Read-Host
        Switch ($csvexportyn) {

            ### If user chooses 1.) Yes, display the output and export the results to a CSV file in the same location as the script itself
            1 {
                $HostProfiles | Out-GridView
                Write-Host `n "Exporting CSV..."
                $HostProfiles | Export-CSV -path ".\$vCenterServer-host-profile-report-$date.csv" -NoTypeInformation
                $yn = $true
            }

            ### If user chooses 2.) No, display a separate window with the results, and exit the script
            2 {
                $HostProfiles | Out-GridView
                $yn = $true
            }

            ### Validate the input. If it's not a 1 or a 2, repeat the question
            default {
                Write-Host -ForegroundColor Red ">>> Invalid input. Please enter a [1] for Yes or a [2] for No."
                $yn = $false
            }
        }
    }

    ### Loop through the "Export CSV" question until a valid choice is made
    Until ($yn)
}

Else {
    Write-Host -ForegroundColor Yellow "No host profiles detected on vCenter $vCenterServer."
}

### Disconnect from the vCenter Server
Write-Host `n -ForegroundColor Green "Disconnecting from the vCenter Server $vCenterServer."
Disconnect-VIServer -Server $vCenterServer -confirm:$false | Out-Null
