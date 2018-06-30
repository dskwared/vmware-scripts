############################################################
# Script: find-uefi-vms-in-a-datacenter.ps1
# Author: Doug DeFrank
# Date: 2018-06-30
# 
# Purpose: Find UEFI-enabled VMs in a specific VMware datacenter
############################################################

Write-Host `n "This script will find all UEFI-enabled VMs in a specific VMware datacenter." `n

### Define the date in the yyyyMMdd format
$date = Get-Date -format "yyyyMMdd"

### Prompt user for vCenter Server name, and connect to it
$vCenterServer = Read-Host -Prompt 'Enter the FQDN of the vCenter Server you want to connect to. (vcenter.domain.com)'
Connect-VIServer -Server $vCenterServer -WarningAction SilentlyContinue | Out-Null

### Choose a datacenter name
$DatacenterName = Get-Datacenter | Out-GridView -PassThru -Title "Select a Datacenter"

### Get all VMs in the chosen datacenter
$vms = $DatacenterName | Get-VM | Sort-Object

### Set the loop variable to 1
$loop = 1

$report = foreach ($vm in $vms) {
    ### Display a progress bar during VM checks
    Write-Progress -Activity "Scanning for UEFI-enabled VMs..." -Status "Checking $vm" -PercentComplete ($loop/$vms.count * 100)

    ### If the VM boot firmware is set to EFI, add it to the report
    if ($vm.ExtensionData.Config.Firmware -eq "efi") {
        $vm | Select-Object Name,@{N='Firmware';E={$_.ExtensionData.Config.Firmware}}
    }
    $loop++
}

### Check to see if the report is empty
if (!$report) {
    Write-Host -ForegroundColor Red `n "No UEFI-enabled VMs found."
}

### If UEFI VMs are found, ask the user if they want to export the results to a CSV file
else {
    Do {
        Write-Host `n "Do you want to export the results to a CSV file?"
        Write-Host "1.) Yes"
        Write-Host "2.) No"
        $csvexportyn = Read-Host
        Switch ($csvexportyn) {

            ### If user chooses 1.) Yes, export to a CSV file in the same location as the script itself
            1 {
                Write-Host `n "Generating CSV > .\$DatacenterName-EFI-VM-Report-$date.csv"
                $report | Export-CSV -path ".\$DatacenterName-EFI-VM-Report-$date.csv" -NoTypeInformation
                $yn = $true
            }
            
            ### If user chooses 2.) No, display a separate window with the scan results, and exit the script
            2 {
                $report | Out-GridView
                $yn = $true
            }

            ### Validate the user input. If it's not a 1 or a 2, repeat the question
            default {
                Write-Host -ForegroundColor Red ">>> Invalid input. Please enter a [1] for Yes or a [2] for No."
                $yn = $false
            }
        }
    }

    ### Loop through the "Export CSV" question until a valid choice is made
    Until ($yn)
}

### Disconnect from the vCenter Server
Write-Host `n "Script Complete. Disconnecting from vCenter Server $vCenterServer."
Disconnect-VIServer -Server $vCenterServer -Confirm:$false | Out-Null