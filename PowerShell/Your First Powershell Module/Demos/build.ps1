Set-Location $PSScriptRoot
$scriptRoot = ($PWD.ProviderPath, $PSScriptRoot)[!!$PSScriptRoot]
Get-ChildItem $scriptRoot -Directory | Remove-Item -Recurse -Force
Clear-Host
$moduleName = 'SQLSatJacksonville2025'

return

#region Setup
# get the current script directory
$modulePath = Join-Path $scriptRoot $moduleName
$copyPath = 'C:\Users\anthony.wilhelm\OneDrive - Moser Consulting, Inc\Repos\Presentations\SampleCode\'

$newDirSplat = @{
	ItemType = 'Directory'
	Force    = $true
}
New-Item @newDirSplat -Path $modulePath
New-Item @newDirSplat -Path (Join-Path $modulePath 'Private')
New-Item @newDirSplat -Path (Join-Path $modulePath 'Public')

$manifestFile = Join-Path $modulePath ('{0}.psd1' -f $moduleName)
$moduleFile = Join-Path $modulePath ('{0}.psm1' -f $moduleName)
#endregion

Write-Verbose ('Manifest File: {0}' -f $manifestFile) -Verbose
Write-Verbose ('Module File: {0}' -f $moduleFile) -Verbose

#TODO change to splatting
#create the manifest (.psd1) and module file (.psm1)
New-ModuleManifest -Path $manifestFile -Author 'Tony Wilhelm' -PowerShellVersion 5.0 -RequiredModules ('dbatools', @{ModuleName = 'dbatools'; ModuleVersion = '2.0.0.0' }) -CompanyName 'SQL Saturday Jacksonville' -Copyright '(c) Anthony Wilhelm. All rights reserved.' -Description 'This module is used a demo for the my presentation' -CmdletsToExport '' -FunctionsToExport '' -AliasesToExport ''

#Copy over the sample module file
Join-Path $copyPath 'SampleModule.psm1' -Resolve |
	Copy-Item -Destination $moduleFile -Force

#Run PSScript Analyzer
Get-ChildItem -Path $modulePath -Recurse -Filter '*.ps1'
Invoke-ScriptAnalyzer -Path $manifestFile