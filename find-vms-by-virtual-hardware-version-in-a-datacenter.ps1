############################################################
# Script: find-vms-by-virtual-hardware-version-in-a-datacenter.ps1
# Author: Doug DeFrank
# Date: 2018-10-29
#
# Purpose: Find VMs in a Datacenter, based on virtual hardware version.
############################################################

Write-Host -ForegroundColor Yellow `n "This script will find VMs based on specific virtual hardware version in a datacenter." `n

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

### Display a dialog box asking the user to choose a particular datacenter object.
$DatacenterName = Get-Datacenter | Out-GridView -passthru -Title "Select a datacenter"

### Ask User for Virtual Hardware version
Do {
    Write-Host `n "What Virtual Hardware Version are you looking for?"
    Write-Host "[4] Version 4 (ESX 3.x)"
    Write-Host "[7] Version 7 (ESX/ESXi 4.x)"
    Write-Host "[8] Version 8 (ESXi 5.0)"
    Write-Host "[9] Version 9 (ESXi 5.1)"
    Write-Host "[10] Version 10 (ESXi 5.5)"
    Write-Host "[11] Version 11 (ESXi 6.0)"
    Write-Host "[13] Version 13 (ESXi 6.5)"
    Write-Host "[14] Version 14 (ESXi 6.7)"
    $hwVersionChoice = Read-Host "Please enter your selection"
    Switch ($hwVersionChoice) {

        ### If user chooses [4], find all VMs with virtual hardware version 4
        4 { $hwVersion = "04"; $vhwLoop = $true }

        ### If user chooses [7], find all VMs with virtual hardware version 7
        7 { $hwVersion = "07"; $vhwLoop = $true }

        ### If user chooses [8], find all VMs with virtual hardware version 8
        8 { $hwVersion = "08"; $vhwLoop = $true }

        ### If user chooses [9], find all VMs with virtual hardware version 9
        9 { $hwVersion = "09"; $vhwLoop = $true }
        
        ### If user chooses [10], find all VMs with virtual hardware version 10
        10 { $hwVersion = 10; $vhwLoop = $true }
        
        ### If user chooses [11], find all VMs with virtual hardware version 11
        11 { $hwVersion = 11; $vhwLoop = $true }
        
        ### If user chooses [13], find all VMs with virtual hardware version 13
        13 { $hwVersion = 13; $vhwLoop = $true }

        ### If user chooses [14], find all VMs with virtual hardware version 14
        14 { $hwVersion = 14; $vhwLoop = $true }        

        ### Validate the input. If it's not a valid choice, repeat the question
        default {
        Write-Host -ForegroundColor Red ">>> Invalid input. Please select a valid hardware version."
        $vhwLoop = $false
        }
        
    }
    
}

### Loop through the "Choose a Virtual Hardware Version" question until a valid choice is made
Until ($vhwLoop)

### Get all Vms in the chosen cluster
$vms = $DatacenterName | Get-VM | Sort-Object

### Set the loop variable to 1
$loop = 1

$report = foreach ($vm in $vms) {
    ### Display a progress bar during VM checks
    Write-Progress -Activity "Scanning for VMs based on virtual hardware version" -Status "Checking $vm" -PercentComplete ($loop/$vms.count * 100)

    ### Find all VMs based on Virtual Hardware version selected
    if ($vm.ExtensionData.Config.Version -eq "vmx-$hwVersion") {
        $vm | Select-Object Name,@{N='HW Version';E={$_.ExtensionData.Config.Version}}
    }

    $loop++
}

### Check to see if the report is empty
if (!$report) {
    Write-Host -ForegroundColor Red `n "Report is empty. No VMs with Virtual Hardware $hwVersionChoice were found."
}

else {

    ### If the report is not empty, ask the user if they want to export the results to a CSV file or not
    Do {
        Write-Host `n "Do you want to export the results to a CSV file?"
        Write-Host "1.) Yes"
        Write-Host "2.) No"
        $csvexportyn = Read-Host "Please enter your selection"
        Switch ($csvexportyn) {

            ### If user chooses 1.) Yes, export to a CSV file in the same location as the script itself
            1 {
                $CSVOutputPath = ".\$DatacenterName-VMs-with-Virtual-Hardware-$hwVersionChoice-$date.csv"
                Write-Host -ForegroundColor "Yellow" `n "Generating CSV > $CSVOutputPath"
                $report | Export-CSV -path "$CSVOutputPath" -NoTypeInformation
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
Write-Host -ForegroundColor Green `n "Disconnecting from the vCenter Server, $vCenterServer." `n
Disconnect-VIServer -Server $vCenterServer -confirm:$false | Out-Null
