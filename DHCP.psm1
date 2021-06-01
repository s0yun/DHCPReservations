#Requires -Version 5.1 -RunAsAdministrator
<#
.SYNOPSIS
  Create DHCP reservations.
.DESCRIPTION
  An arguably pointless script to add IPv4 DHCP reservations to a Windows DHCP server.
.PARAMETER Scope
  The DHCP scope ID (e.g. 192.168.1.0)
.PARAMETER ClientIP
  The client's desired IP address.
.PARAMETER ClientMAC
  The client's MAC address.
.PARAMETER ClientDescription
  Description of client for DHCP reservation.
.PARAMETER Server
  DHCP server IP or DNS name.
.PARAMETER WhatIf
  PowerShell default WhatIf param.
.PARAMETER Confirm
  PowerShell default Confirm param.
.PARAMETER Verbose
  PowerShell default Verbose param.
.NOTES
  Version:				2.0
  Author:				s0yun, tigattack
  Modification Date:	11/05/2021
  Purpose/Change:		Pimped.
#>

function New-DHCPReservation {
	[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')]
	Param (
		[Alias('Scope')]
		[Parameter(Mandatory=$true)]
		[String]$scopeId,

		[Alias('ClientIP')]
		[Parameter(Mandatory=$true)]
		[ValidatePattern("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")]
		[Net.IPAddress]$ipAddr,

		[Alias('ClientMAC')]
		[Parameter(Mandatory=$true)]
		[ValidatePattern("^([a-fA-F0-9]{2}[:.-]?){5}[a-fA-F0-9]{2}$")]
		[String]$macAddr,

		[Alias('ClientDescription')]
		[Parameter(Mandatory=$false)]
		[String]$description,

		[Alias('Server')]
		[Parameter(Mandatory=$true)]
		[String]$dhcpServer
	)

	begin {
		try {
			# Convert MAC to compatible format (dash-separated)
			$macAddr = Switch ($macAddr) {
				{$_ -match '^([a-fA-F0-9]{2}[:]){5}[a-fA-F0-9]{2}$'} {
					$macAddr.Replace(':','-')
					Break
				}
				{$_ -match '^([a-fA-F0-9]{2}[.]){5}[a-fA-F0-9]{2}$'} {
					$macAddr.Replace('.','-')
					Break
				}
				{$_ -match '^([a-fA-F0-9]{2}){5}[a-fA-F0-9]{2}$'} {
					$macAddr.Insert(2,'-').`
						Insert(5,'-').`
						Insert(8,'-').`
						Insert(11,'-').`
						Insert(14,'-')
					Break
				}
				Default {$macAddr}
			}
		}
		catch {
			Throw $_.Exception.Message
		}
	}

	process {
		try {
			# Check for existing DHCP reservation with same MAC
			If (Get-DhcpServerv4Reservation -ComputerName $dhcpServer -ScopeId $scopeId -ClientId $macAddr -ErrorAction SilentlyContinue) {

				if($PSCmdlet.ShouldProcess(
					$dhcpServer,
					"Add-DhcpServerv4Reservation")
				)
				{
					Write-Warning "A DHCP reservation already exists for MAC address $macAddr."

					$replacePrompt = Read-Host -Prompt "`nDo you wish to replace the existing reservation for this client? (y/n)"

					Switch ($replacePrompt) {
						'Y' {$replace = $true}
						'N' {$replace = $false}
						Default {
							Write-Warning 'Invalid response. Exiting.'
							Break
						}
					}

					If (-not $replace) {
						Write-Output "`nNo action taken. Please manually resolve this conflict and retry."
						Break
					}
				}
			}
		}
		catch {
			Throw $_.Exception.Message
		}

		try {
			# Check for existing DHCP reservation with same IP
			If ((-not $replace) -and (Get-DhcpServerv4Reservation -IPAddress $ipAddr -ComputerName $dhcpServer -ErrorAction SilentlyContinue)) {

				Write-Warning "A DHCP reservation already exists for IP address $ipAddr.`nPlease manually resolve this conflict and retry."
				Break
			}
		}
		catch {
			Throw $_.Exception.Message
		}

		try {
			# If old reservation should be replaced
			If ($replace) {
				# ShouldProcess (-WhatIf) handling
				if($PSCmdlet.ShouldProcess(
					$dhcpServer,
					"Remove-DhcpServerv4Reservation")
				)
				{
					# Remove reservation
					Remove-DhcpServerv4Reservation -ScopeID $scopeId -ClientId $macAddr -ComputerName $dhcpServer
				}
			}
		}
		catch {
			Throw $_.Exception.Message
		}

		try {
			# ShouldProcess (-WhatIf) handling
			if($PSCmdlet.ShouldProcess(
				$dhcpServer,
				"Add-DhcpServerv4Reservation")
			)
			{
				# Add reservation
				Add-DhcpServerv4Reservation -ScopeId $scopeId -IPAddress $ipAddr -ClientId $macAddr -Description $description -ComputerName $dhcpServer

				# Output reservation
				Get-DhcpServerv4Reservation -ScopeId $ScopeID -ClientId $macAddr -ComputerName $dhcpServer | Format-Table -AutoSize
			}
		}
		catch {
			Throw $_.Exception.Message
		}
	}

	end {}
}
