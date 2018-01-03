##################################################
# Script: find-other-nics-in-a-cluster.ps1
# Author: Doug DeFrank
# Date: 2017-12-27
#
# Purpose: Find non-VMXNET3 adapters in a VMware Cluster
##################################################

### Initialize array(s)
$report = @()

$date = Get-Date -format "yyyyMMdd"

Write-Host "This script will find all VM's that have e1000, e1000e, or other non-VMXNET3 adapters in a given cluster." `n

### Prompt the user for vCenter Server name, and connect to it.
$vCenterServer = Read-Host -Prompt 'Enter the FQDN of the vCenter Server you want to connect to. (ex. vcenter.domain.com)'
Connect-VIServer -Server $vCenterServer -WarningAction SiletlyContinue | Out-Null

### Prompt the user for the cluster name within that vCenter Server
$ClusterName = Read-Host -Prompt 'Enter the full name of the cluster you want to work with (ex. Prod-Cluster-01)'

### Get information about all VMs in the defined cluster
$VMs = Get-Cluster -Name $ClusterName | Get-VM | Sort-Object

$NotVmxnet3 = $VMs | Get-NetworkAdapter | Where-Object {$_.type -ne 'vmxnet3'} 

foreach ($vm in $NotVmxnet3) {
    $row = "" | Select-Object VMName,NICAdapter,NetworkName,AdapterType
    $row.VMName = $vm.Parent
    $row.NICAdapter = $vm.Name
    $row.NetworkName = $vm.NetworkName
    $row.AdapterType = $vm.Type

    ### Build the report
    $report += $row
}

### If the report is empty, notify the user that no non-VMXNET3 NICs were detected.
If (!$report) {
    Write-Host -ForegroundColor Yellow "There were no non-VMXNET3 NICs detected in the cluster $ClusterName" `n
}

### Display the report results
Else {

    ### Ask the user if they want to generate a CSV file of the results
    Do {
        Write-Host `n "Do you want to export the results to a CSV file?"
        Write-Host "1.) Yes"
        Write-Host "2.) No"
        $Choice = Read-Host
        Switch ($Choice) {

            ### If the user answers 1 (Yes), generate a CSV file
            1 {
            Write-Host "Generating a CSV report in the same directory as this PowerCLI script."
            $report | Export-CSV ".\NIC-Report-for-$ClusterName-$date.csv" -NoTypeInformation
            $cont = $true
            }

            ### If the user answers 2 (No), do nothing
            2 { $cont = $true}

            ### Validate that the user input is either a 1 or a 2. Otherwise, ask the question again.
            default {
            $cont = $false
            Write-Host -ForegroundColor Red ">>> Invalid input. Please answer [1] for Yes or [2] for No."
            }
        }
    }

    ### Repeat the question until valid input is received
    Until ($cont)
}

### Disconnect from the vCenter Server
Disconnect-VIServer -Server $vCenterServer -confirm:$false | Out-Null
