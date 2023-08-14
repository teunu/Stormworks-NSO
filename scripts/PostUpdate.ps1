# Ensure sensible behaviour
$ErrorActionPreference = "Stop"
& "$PSScriptRoot\DefinitionAttributesOnNewLines.ps1"
& "$PSScriptRoot\VehicleXmlFormatter.ps1"
& "$PSScriptRoot\SpecialReport.ps1"