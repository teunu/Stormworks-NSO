# Make the Vehicle Xml multiline so that it's easier to see diffs of them.


# (?mi)                Set MultiLine mode and case insensitive
#      (?<!            Look in front of the potential match and if the sub-regex matches discard it.
#          ^           Match start of string/line
#           [ `t]*     Any number (or none at all) of spaces or tabs (tab is escaped using `).
#                 )    End lookbehind.
#                  <   Match a single '<' character
$regex   = "(?mi)(?<!^[ `t]*)<"
$replace = "`n<"


# Ensure sensible behaviour
$ErrorActionPreference = "Stop"

$files  = Get-ChildItem -Recurse -File -Filter "*.xml"        -Path "$PSScriptRoot/../rom/data/debris/"
$files += Get-ChildItem -Recurse -File -Filter "vehicle*.xml" -Path "$PSScriptRoot/../rom/data/missions/"
$files += Get-ChildItem -Recurse -File -Filter "*.xml"        -Path "$PSScriptRoot/../rom/data/preset_vehicles_advanced/"

$files | ForEach-Object `
{
	$file = $_

	$content = Get-Content -Raw $file

	$content = $content -replace $regex, $replace

	$content | Set-Content $file -NoNewline

	# Output file name using powershell's rediculous convention.
	"$file"
}

