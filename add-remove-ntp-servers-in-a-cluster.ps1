##################################################
# Script: add-remove-ntp-servers-in-a-cluster.ps1
# Author: Doug DeFrank
# Date: 2017-10-09
# 
# Purpose: Add or remove NTP servers in a VMware cluster
##################################################

Write-Host `n "This script can add or remove NTP servers in a cluster."

### Prompt user for vCenter Server name, and connect to it
$vCenterServer = Read-Host -Prompt 'Enter the FQDN of the vCenter Server you want to connect to. (ex. vcenter.domain.com)'
Connect-VIServer -Server $vCenterServer -WarningAction SilentlyContinue | Out-Null

### Prompt the user for the cluster name within that vCenter Server
$ClusterName = Read-Host -Prompt 'Enter the full name of the cluster you want to work with (ex. ProdCluster01)'

### Get information about all hosts in the defined cluster
$vmHosts = Get-Cluster -Name $ClusterName | Get-VMHost

$cont = ""

Do {
    ### Ask the user if they want to remove all existing NTP servers or not
    Write-Host `n "Would you like to remove all existing NTP servers from the hosts in this cluster? " -NoNewline; Write-Host -ForegroundColor Yellow "[Y]" -NoNewline; Write-Host "es or " -NoNewline; Write-Host -ForegroundColor Yellow "[N]" -NoNewline; Write-Host "o."
    $ntpRemove = Read-Host
    Switch -Wildcard ($ntpRemove) {
        
        ### If user chose Yes, remove all existing NTP servers
        "Y*" {
            ForEach ($vmHost in $vmHosts) {
            Write-Host "------------------------------"
            Write-Host "Removing all NTP Servers from $vmHost"
            $allNtpServers = Get-VMHostNtpServer -VMHost $vmHost
            Remove-VMHostNtpServer -VMHost $vmHost -NtpServer $allNtpServers -Confirm:$false | Out-Null
            Write-Host "All NTP Servers from $vmHost have been removed." `n
        }
        $cont = $true
    }

    ### If user chose No, do not remove any NTP servers
    "N*" {
        $cont = $true
        Write-Host "No NTP Servers have been removed"
    }

    ### If user inputs anything other than Y or N, input is invalid and ask question again.
    default {
        $cont = $false
        Write-Host -ForegroundColor Red ">>> Invalid input. Please answer [Y]es or [N]o"
        }
    }
}
Until ($cont)

Do {
    $newNtpServer = ""
    Write-Host `n "Would you like to add a new NTP Server to all hosts in this cluster? "-NoNewline; Write-Host -ForegroundColor Yellow "[Y]" -NoNewline; Write-Host "es or " -NoNewline; Write-Host -ForegroundColor Yellow "[N]" -NoNewline; Write-Host "o."
    $ntpAdd = Read-Host
    Switch -Wildcard ($ntpAdd) {

        ### If user chose Yes, add a new NTP server
        "Y*" {
            $newNtpServer = Read-Host -Prompt 'Enter the FQDN or IP of the new NTP Server'
            ForEach ($vmHost in $vmHosts) {
            Write-Host "------------------------------"
            Write-Host "Adding new NTP Server to $vmHost"
            Add-VMHostNtpServer -VMHost $vmHost -NtpServer $newNtpServer -Confirm:$false | Out-Null
            Write-Host "NTP Server, $newNtpServer, has been added to $vmHost." `n
        }
        $cont = $true
    }

    ### If the user chose No, proceed without adding any new NTP Servers
    "N*" {
        $cont = $false
        Write-Host "No more NTP Servers have been added."
    }

    ### If user inputs anything other than Y or N, input is invalid and ask question again.
    default {
        $cont = $true
        Write-Host -ForegroundColor Red ">>> Invalid input. Please answer [Y]es or [N]o."
        }
    }
}
While ($cont)

### Restart (or start) the NTP Service on each host in the cluster
ForEach ($vmHost in $vmHosts) {

    ### Look for and check the ntpd service on each host
    $ntpService = Get-VMHostService -VMHost $vmHost | ? {$_.Key -eq 'ntpd'}
    Set-VMHostService $ntpService -Policy On | Out-Null

    ### If the ntpd service is currently running, restart the NTP Service
    If ($ntpService.Running) {
        Restart-VMHostService $ntpService -Confirm:$false
        Write-Host "$ntpService Service on $vmHost was in a " -NoNewline; Write-Host -ForegroundColor Green "Running" -NoNewline; Write-Host " state and has been restarted."
    }

    ### If the ntpd service is NOT running, start the NTP Service
    Else {
        Start-VMHostService $ntpService -Confirm:$false
        Write-Host "$ntpService Service on $vmHost was " -NoNewline; Write-Host -ForegroundColor Yellow "NOT Running" -NoNewline; Write-Host " and has been started."
    }
}

### Disconnect from the vCenter Server
Disconnect-VIServer -Server $vCenterServer -confirm:$false | Out-Null
