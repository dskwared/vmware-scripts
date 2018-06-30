##################################################
# Script: configure-ssh-lockdown-mode-in-a-cluster.ps1
# Author: Doug DeFrank
# Date: 2017-10-14
#
# Purpose: Configure SSH, Lockdown mode for all hosts in a cluster
##################################################

Write-Host `n "This script will allow a user to enable or disable SSH as well as Lockdown Mode for all hosts in a cluster."

### Prompt user for vCenter Server name, and connect to it
$vCenterServer = Read-Host -Prompt 'Enter the FQDN of the vCenter Server you want to connect to. (ex. vcenter.domain.com)'
Connect-VIServer -Server $vCenterServer -WarningAction SilentlyContinue | Out-Null

### Prompt the user for the cluster name within that vCenter Server
$ClusterName = Read-Host -Prompt 'Enter the full name of the cluster you want to work with (ex. ProdCluster01)'

### Get information about all hosts in the defined cluster
$vmHosts = Get-Cluster -Name $ClusterName | Get-VMHost | Sort-Object

$cont = ""

Do {
	### Ask the user what step to perform
	Write-Host `n
	Write-Host "Please enter a task to perform on each host in the cluster:"
	Write-Host "1.) Enable SSH"
	Write-Host "2.) Disable Lockdown Mode"
	Write-Host "3.) Disable SSH"
	Write-Host "4.) Enable Lockdown Mode"
	Write-Host "5.) Exit" `n
	$choice = Read-Host

	### Perform a particular task based on user input
	Switch ($choice) {

		### If task #1 is chosen, Enable SSH on all hosts in the cluster
		1 {
			Write-Host -ForegroundColor Yellow `n "Enabling SSH on all hosts in the $ClusterName cluster."
			ForEach ($vmHost in $vmHosts) {
				Start-VMHostService -HostService ($vmHost | Get-VMHostService | Where {$_.key -eq "TSM-SSH"}) -Confirm:$false | Select VMHost,Key,Label,Running
			}
		$cont = $true
		}

		### If task #2 is chosen, Disable Lockdown Mode on all hosts in the cluster
		2 {
			Write-Host -ForegroundColor Yellow `n "Disabling Lockdown Mode on all hosts in the $ClusterName cluster."
			ForEach ($vmHost in $vmHosts) {
				($vmHost | Get-View).ExitLockdownMode()
			}
			$cont = $true
		}
		
		### If task #3 is chosen, Disable SSH on all hosts in the cluster
		3 {
			Write-Host -ForegroundColor Yellow `n "Disabling SSH on all hosts in the $ClusterName cluster."
			ForEach ($vmHost in $vmHosts) {
				Stop-VMHostService -HostService ($vmHost | Get-VMHostService | Where {$_.key -eq "TSM-SSH"}) -Confirm:$false | Select VMHost,Key,Label,Running
			}
			$cont = $true
		}

		### If task #4 is chosen, Enable Lockdown Mode on all hosts in the cluster
		4 {
			Write-Host -ForegroundColor Yellow `n "Enabling Lockdown Mode on all hosts in the $ClusterName cluster."
			ForEach ($vmHost in $vmHosts) {
				($vmHost | Get-View).EnterLockdownMode()
			}
			$cont = $true
		}

		### If task #5 is chosen, exit the script
		5 {
			Write-Host "Exiting..."
			$cont = $false
		}

		### If user enters anything other than 1-5, input is invalid and ask question again
		default {
			Write-Host -ForegroundColor Red ">>> Invalid input. Please select option 1-5."
			$cont = $true
		}
	}
}

### Loop through the script until task #5 (Exit) is chosen
While ($cont)

### Disconnect from the vCenter Server
Disconnect-VIServer -Server $vCenterServer -Confirm:$false | Out-Null
