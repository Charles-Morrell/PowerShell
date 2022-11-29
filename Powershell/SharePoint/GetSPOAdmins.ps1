<#
.SYNOPSIS
Generate report of all SharePoint Site Collection Administrators.

.DESCRIPTION
Generate a CSV report of all SharePoint Site Collection Administrators.

.NOTES
Date Created:   24/11/2022
Date Modified:  24/11/2022
Author:         Charlie Morrell
#>

#Requires -Modules ExchangeOnlineManagement
#Requires -Modules Microsoft.Online.SharePoint.PowerShell

Import-Module -Name ExchangeOnlineManagement
Import-Module -Name Microsoft.Online.SharePoint.PowerShell


$Report = @() 
$ReportPath = "$($env:TMP)\SPOSiteAdmins_" + (Get-Date -Format yyyy-MM-ddTHHmm) + ".csv"
$SPOSites = Get-SPOSite -Limit All | Select-Object Title,Url

foreach ($SPOSite in $SPOSites) {
    Write-Host "Getting details for $($SPOSite.Url)..." -ForegroundColor Cyan
    try {
        $SPOSiteAdmins = Get-SPOUser -Site $SPOSite.Url | Where-Object { $_.IsSiteAdmin -eq $true }
    }
    catch {
        if (!$AdminUsername) {
            $AdminUsername = Read-Host "Please enter your administrator username."
        }
        Set-SPOUser -Site $SPOSite.Url -LoginName $AdminUsername -IsSiteCollectionAdmin $true -InformationAction SilentlyContinue 
        $SPOSiteAdmins = Get-SPOUser -Site $SPOSite.Url | Where-Object { ($_.IsSiteAdmin -eq $true) -and ($_.LoginName -notlike $AdminUsername)}
        Set-SPOUser -Site $SPOSite.Url -LoginName $AdminUsername -IsSiteCollectionAdmin $false  -InformationAction SilentlyContinue 
    }

    foreach ($SPOSiteAdmin in $SPOSiteAdmins) {
        $Obj = New-Object PSObject
        $Obj | Add-Member -MemberType NoteProperty -Name 'Site Name' -Value $SPOSite.Title
        $Obj | Add-Member -MemberType NoteProperty -Name 'URL' -Value $SPOSite.Url
        $Obj | Add-Member -MemberType NoteProperty -Name 'Admin Name' -Value $SPOSiteAdmin.DisplayName
        $Obj | Add-Member -MemberType NoteProperty -Name 'Login Name' -Value $SPOSiteAdmin.LoginName
        $Obj | Add-Member -MemberType NoteProperty -Name 'Is Group' -Value $SPOSiteAdmin.IsGroup
        $Report += $Obj
    }
}

$Report | Sort-Object 'Site Name','Admin Name' | Export-Csv -Path $ReportPath -NoTypeInformation -Force

if ($IsWindows) {
    [console]::beep(500,1000)
}

Write-Host "Script complete." -ForegroundColor Green