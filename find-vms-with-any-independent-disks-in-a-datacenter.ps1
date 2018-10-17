########################################
# Script: find-vms-with-any-independent-disks-in-a-datacenter.ps1
# Author: Doug DeFrank
# Date: 2018-10-17
#
# Purpose: Scan a datacenter for VMs with any (persistent or non-persistent) independent disks.
########################################

Write-Host -ForegroundColor Yellow `n "This script will scan the a datacenter object for VMs any (persistent or non-persistent) independent disks." `n

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

### Get all VMs in the chosen datacenter
$DatacenterName = Get-Datacenter | Out-GridView -passthru -Title "Select a datacenter"

### Get all Vms in the chosen datacenter
$vms = $DatacenterName | Get-VM | Sort-Object

### Set the loop variable to 1
$loop = 1

$report = foreach ($vm in $vms) {
    ### Display a progress bar during VM checks
    Write-Progress -Activity "Scanning for VMs with Independent Disks" -Status "Checking $vm" -PercentComplete ($loop/$vms.count * 100)

    ### If the VM boot firmware is set to BIOS, add it to the report
    $vm | Get-HardDisk | Where-Object {$_.Persistence -like "Independent*"}

    $loop++
}

### Check to see if the report is empty
if (!$report) {
    Write-Host -ForegroundColor Red `n "Report is empty. No VMs with independent disks were found."
}

else {

    ### If the report is not empty, ask the user if they want to export the results to a CSV file or not
    Do {
        Write-Host `n "Do you want to export the results to a CSV file?"
        Write-Host "1.) Yes"
        Write-Host "2.) No"
        $csvexportyn = Read-Host
        Switch ($csvexportyn) {

            ### If user chooses 1.) Yes, export to a CSV file in the same location as the script itself
            1 {
                Write-Host `n "Generating CSV > .\$DatacenterName-VMs-with-Independent-Disks-$date.csv"
                $report | Export-CSV -path ".\$DatacenterName-VMs-with-Independent-Disks-$date.csv" -NoTypeInformation
                $yn = $true
            }

            ### If user chooses 2.) No, display a separate window with the results, and exit the script
            2 {
                $report | Out-GridView
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

### Disconnect from the vCenter Server
Write-Host -ForegroundColor Green `n "Disconnecting from the vCenter Server $vCenterServer" `n
Disconnect-VIServer -Server $vCenterServer -confirm:$false | Out-Null
