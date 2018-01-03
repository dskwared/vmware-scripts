############################################################
# Script: create-new-vm-port-groups-in-a-cluster.ps1
# Author: Doug DeFrank
# Date: 2017-10-04
#
# Purpose: Create a new VM port group on a virtual standard
#   switch in a given cluster.
############################################################

Write-Host `n "This script will create new VM port group(s) for an existing standard switch in a given cluster." `n

### Prompt the user for vCenter Server name, and connect to it.
$vCenterServer = Read-Host -Prompt 'Enter the FQDN of the vCenter Server you want to connect to (ex. vcenter.domain.com)'
Connect-VIServer -Server $vCenterServer -WarningAction SilentlyContinue | Out-Null

### Prompt the user for the cluster name within the defined vCenter Server
$ClusterName = Read-Host -Prompt 'Enter the full name of the cluster where the VM port group should be created (ex: Cluster01)'

### Get information about all hosts in the defined cluster
$vmHosts = Get-Cluster -Name $ClusterName | Get-VMHost

Do {
     ### Define the vSwitch where the port group should be created
     $vSwitch = Read-Host -Prompt 'Enter the name of the vSwitch for the new connection (ex: vSwitch1 or vSwitch2)'
     
     ### Prompt the user for the name of the VM port group to be created
     $PortGroup = Read-Host -Prompt 'Enter the name of the VM port group you want to create (ex: Prod412)
     
     ### Prompt the user for the VLAN ID
     $vlan = ""
     $vlaninput = $false
     
     Do {
          ### Ask the user for the VLAN ID and validate that the response is within the VLAN range of 1 through 4094
          $vlan = Read-Host -Prompt 'Enter the VLAN ID for the VM port group (ex: any whole number between 1 and 4094)'
          Switch -Regex ($vlan) {
               "^([1-9][0-9]{0,2}|[1-3][0-9][0-9][0-9]|40([0-8][0-9]|9[0-4]))$" {
                    Write-Host "$vlan is a valid VLAN number."
                    $vlaninput = $true
               }
               default {
                    Write-Host -ForegroundColor Red ">>> Invalid input. Please enter a whole number between 1 and 4094."
                    $vlaninput = $false
               }
          }
     }

     # Keep asking the VLAN ID question until valid input is entered.
     Until ($vlaninput)

     ### For each host in the cluster, create the VM port group
     ForEach ($vmHost in $vmHosts) {
          $vss = Get-VirtualSwitch -VMHost $vmHost -Name $vSwitch
          New-VirtualPortGroup -Name "$PortGroup" -VirtualSwitch $vss -VlanId $vlan -Confirm:$false
     }
     
     ### Ask the user if they want to add another VM port group
     Write-Host `n "Create another VM port group in this cluster? " -NoNewline; Write-Host -ForegroundColor Yellow "[Y]" -NoNewline; Write-Host "es or " -NoNewline; Write-Host -ForegroundColor Yellow "[N]" -NoNewline; Write-Host "o."
     $Repeat = Read-Host
     Switch -Wildcard ($Repeat) {
          "Y*" {$cont = $true}
          "N*" {$cont = $false}
          default {
               $cont = $true
               Write-Host -ForegroundColor Red ">>> Invalid input. Please enter [Y]es or [N]o."
          }
     }
}

### Keep looping through the script until the user responds with [N]o.
While ($cont)

### Disconnect from the vCenter Server
Disconnect-VIServer -Server $vCenterServer -Confirm:$false | Out-Null
