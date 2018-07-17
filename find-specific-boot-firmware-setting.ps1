############################################################
# Script: find-specific-vm-boot-firmware-setting.ps1
# Author: Doug DeFrank
# Date: 2018-07-12
#
# Purpose: Find a specific VMs' boot firmware in vSphere.
############################################################

Write-Host `n -ForegroundColor Yellow "This script will find and report a specific VM's boot firmware setting (BIOS or UEFI)."
Write-Host -ForegroundColor Yellow " It will continue asking for user input (a VM name) unless X is entered." `n

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

### This script is designed to look up a VM's boot firmware setting.
### The script will continue asking for a VM name unless an X is entered.

Do {
    ### Ask the user what VM to find
    $vm = Read-Host -Prompt "Find the boot firmware setting for which VM [press X to exit]"
    if ($vm -eq 'x' -or $vm -eq 'X') {
        $yn1 = $false
    }

    Else {
        ### Lookup the VM in the environment.
        ### If the VM exists, report the boot firmware setting.
        ### However, if it doesn't exist, report that the VM couldn't be found.
        $yn1 = $true
        Try {
            $vmlookup = Get-VM $vm -ErrorAction Stop
            Write-Host `n "Found the virtual machine, $vm."
            $vmlookup | Format-List Name,@{N='Firmware';E={$_.ExtensionData.Config.Firmware}}
        }

        Catch {
            Write-Host -ForegroundColor Red -BackgroundColor Black "The VM [$vm] was not found in the vCenter Server [$vCenterServer]." `n
        }
    }
}

### Ask the "Find Which VM" question again unless the user chose 2 (No) for the "Look up another VM" question
While ($yn1)

### Disconnect from the vCenter Server
Write-Host -ForegroundColor Green `n "Disconnecting from the vCenter Server"
Disconnect-VIServer -Server $vCenterServer -confirm:$false | Out-Null
