#Set-StrictMode -Version Latest
#####################################################
# Get-SitecoreSite
#####################################################
<#PSScriptInfo

.VERSION 0.2

.GUID 731386ca-0f32-4eea-ac72-0b67f84ede51

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell sitecore iis

.LICENSEURI https://github.com/SharedSitecore/Get-SitecoreSite/blob/main/LICENSE

.PROJECTURI https://github.com/SharedSitecore/Get-SitecoreSite

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

<# 

.DESCRIPTION 
Get-SitecoreSite by name - default return list of all Sitecore sites

.PARAMETER name
Name of site - if empty returns list of all Sitecore sites within wwwroot

.PARAMETER wwwroot
Path of IIS Inetpub WWWROOT - if empty reads from registry

.PARAMETER mode
Mode of operation - default: registry/filesystem, requires admin: IISAdministration and Microsoft.Web.Administration.dll

.EXAMPLE
PS> .\Get-SitecoreSite

.EXAMPLE
PS> .\Get-SitecoreSite 'sitename in iis'

#> 
#####################################################
# Get-SitecoreSite
#####################################################
Param(
	# Name of Sitecore Site in IIS
	[Parameter(Mandatory = $false, position=0)] [string]$name,
	[Parameter(Mandatory = $false, position=1)] [string]$wwwroot,
	[Parameter(Mandatory = $false, position=2)] [string]$mode = 'registry'
)
begin {
	$ProgressPreference = 'SilentlyContinue'
	$ErrorActionPreference = 'Stop'
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
	Write-Verbose "$PSScriptName $name $mode called by:$PSCallingScript"
}
process {
	Write-Verbose "$PSScriptName $name $mode start"
	
	switch ($mode) {
		'registry' { 
			if (!$wwwroot) {$wwwroot = (Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\InetStp -Name "PathWWWRoot").PathWWWRoot}
			Write-Verbose "wwwroot:$wwwroot"
			if (!$name) {
				[array]$sites = @(Get-ChildItem $wwwroot -Directory | ForEach-Object { $_.FullName})
			} else {
				if ((Test-Path $name)) {
					[array]$sites = @($name)
				} else {
					[array]$sites = @(Get-ChildItem $wwwroot -Directory -Filter $name | ForEach-Object { $_.FullName})
				}
			}
		}
		'iis' { 
			try {
				$command = Get-Command -Name Get-IISSite #'IISAdministration'
			} catch {
			}
			if (!$command) {
				Install-Module IISAdministration -Confirm:$False -Force -Scope AllUsers
				Import-Module IISAdministration -Force -Scope Global
			}
	
			if (!$name) {
				$sites = Get-IISSite
				#$sites = Get-website | select name,id,state,physicalpath
			} else {
				$sites = Get-IISSite $name
				#$sites = Get-website $name | select name,id,state,physicalpath
			}
			#$path = $site.physicalpath
		}
		'dll' { 
			[Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
			#[Void][Reflection.Assembly]::UnsafeLoadFrom("Microsoft.Web.Administration")
			
			$server = New-Object Microsoft.Web.Administration.ServerManager
			$sites = @()
			foreach($site in $server.Sites) {
				foreach ($app in $site.Applications) {
					if ($site.Name -like $name) {
						sites.Add($app.VirtualDirectories["/"].PhysicalPath)
					}
				}
			}
		}
	}

	if (!$sites) {
		throw "$PSScriptName ERROR no sites found in IIS named:$name"
	}
	Write-Verbose "sites:$($sites -join ',')"
	#$results = @()
	$results = [System.Collections.ArrayList]$results = @();
	#$collection = {$results}.Invoke()
	foreach($site in $sites)
	{
		if (!$site) {
			Write-Verbose "$PSScriptName NO site/path!"
		} else {
			if (!(Test-Path ($site))) {
				Write-Verbose "$PSScriptName ERROR site not found? $site"
			} else {
				$sitecoreSite = Test-Path (Join-Path $site '/bin/Sitecore.Kernel.dll')
				#Write-Host "$($site):$sitecoreSite"
				if ($sitecoreSite) { $results.Add($site) | Out-Null } else {Write-Verbose "SKIP $site - Sitecore.Kernel.dll NOT FOUND"}
			}
		}
	}
	Write-Verbose "results:$($results -join ',')"
	Write-Verbose "$PSScriptName $name end"
	return @($results)
}