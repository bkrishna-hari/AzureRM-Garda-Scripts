﻿<#
.DESCRIPTION
    This scipt reads currently available backup policies by Device.

.PARAMS 

    SubscriptionId: Specifies the ID of the subscription.
    DeviceName: Specifies the name of the StorSimple device on which to create/update the volume.
    ResourceGroupName: Specifies the name of the resource group on which to create/update the volume.
    ManagerName: Specifies the name of the resource (StorSimple device manager) on which to create/update the volume.

#>

Param
(
    [parameter(Mandatory = $true, HelpMessage = "Specifies the ID of the subscription.")]
    [String]
    $SubscriptionId,

    [parameter(Mandatory = $true, HelpMessage = "Specifies the name of the resource group on which to read backup schedules and backup catalogs.")]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory = $true, HelpMessage = "Specifies the name of the resource (StorSimple device manager) on which to read backup schedules and backup catalogs.")]
    [String]
    $ManagerName,

    [parameter(Mandatory = $true, HelpMessage = "Specifies the name of the StorSimple device on which to read backup schedules and backup catalogs.")]
    [String]
    $DeviceName
)

# Set Current directory path
$ScriptDirectory = (Get-Location).Path

#Set dll path
$ActiveDirectoryPath = Join-Path $ScriptDirectory "Dependencies\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
$ClientRuntimeAzurePath = Join-Path $ScriptDirectory "Dependencies\Microsoft.Rest.ClientRuntime.Azure.dll"
$ClientRuntimePath = Join-Path $ScriptDirectory "Dependencies\Microsoft.Rest.ClientRuntime.dll"
$NewtonsoftJsonPath = Join-Path $ScriptDirectory "Dependencies\Newtonsoft.Json.dll"
$AzureAuthenticationPath = Join-Path $ScriptDirectory "Dependencies\Microsoft.Rest.ClientRuntime.Azure.Authentication.dll"
$StorSimple8000SeresePath = Join-Path $ScriptDirectory "Dependencies\Microsoft.Azure.Management.Storsimple8000series.dll"

#Load all required assemblies
[System.Reflection.Assembly]::LoadFrom($ActiveDirectoryPath) | Out-Null
[System.Reflection.Assembly]::LoadFrom($ClientRuntimeAzurePath) | Out-Null
[System.Reflection.Assembly]::LoadFrom($ClientRuntimePath) | Out-Null
[System.Reflection.Assembly]::LoadFrom($NewtonsoftJsonPath) | Out-Null
[System.Reflection.Assembly]::LoadFrom($AzureAuthenticationPath) | Out-Null
[System.Reflection.Assembly]::LoadFrom($StorSimple8000SeresePath) | Out-Null

# Print methods
Function PrettyWriter($Content, $Color = "Yellow") { 
    Write-Host $Content -Foregroundcolor $Color 
}

# Define constant variables (DO NOT CHANGE BELOW VALUES)
$FrontdoorUrl = "urn:ietf:wg:oauth:2.0:oob"
$TokenUrl = "https://management.azure.com"
$TenantId = "1950a258-227b-4e31-a9cf-717495945fc2"
$DomainId = "72f988bf-86f1-41af-91ab-2d7cd011db47"

$FrontdoorUri = New-Object System.Uri -ArgumentList $FrontdoorUrl
$TokenUri = New-Object System.Uri -ArgumentList $TokenUrl

$AADClient = [Microsoft.Rest.Azure.Authentication.ActiveDirectoryClientSettings]::UsePromptOnly($TenantId, $FrontdoorUri)

# Set Synchronization context
$SyncContext = New-Object System.Threading.SynchronizationContext
[System.Threading.SynchronizationContext]::SetSynchronizationContext($SyncContext)

# Verify User Credentials
$Credentials = [Microsoft.Rest.Azure.Authentication.UserTokenProvider]::LoginWithPromptAsync($DomainId, $AADClient).GetAwaiter().GetResult()
$StorSimpleClient = New-Object Microsoft.Azure.Management.StorSimple8000Series.StorSimple8000SeriesManagementClient -ArgumentList $TokenUri, $Credentials

# Set SubscriptionId
$StorSimpleClient.SubscriptionId = $SubscriptionId

# Get all backup policies by Device
try {
    $BackupPolicies = [Microsoft.Azure.Management.StorSimple8000Series.BackupPoliciesOperationsExtensions]::ListByDevice($StorSimpleClient.BackupPolicies, $DeviceName, $ResourceGroupName, $ManagerName)
}
catch {
    # Print error details
    Write-Error $_.Exception.Message
    break
}


# Print backup policies
PrettyWriter "`nBackups policies:"
if ($BackupPolicies -ne $null -and $BackupPolicies.Length -gt 0) {
    $BackupPolicies | Sort-Object Name
} else {
    Write-Error "No backup policy is configured."
}
