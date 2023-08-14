# Generates a file listing for git to track
# for files that can't be tracked by git
# because the build system makes minor changes to 
# some sound files every single build.



# Ensure sensible behaviour
$ErrorActionPreference = "Stop"

$Root = resolve-path "$PSSCriptRoot/.."
$RegexPattern = [Regex]::Escape($Root)

function Main()
{
	$audio = CreateTree "rom/audio" "tree.txt" "*.ogg"
	$txtr = CreateTree "rom/graphics" "tree.txt" "*.txtr"

	if ($audio -and $txtr)
	{
		exit 0
	}
	exit 1
}



function CreateTree($PartialPath, $ResultFile, $Filter)
{
	$Path = "$PSScriptRoot/../$PartialPath"

	$Destination = "$Path/$ResultFile"


	$oldHash = Get-FileHash $Destination -ErrorAction SilentlyContinue

	$Content = `

	Get-ChildItem -Path $Path `
	-Recurse `
	-File `
	-Filter $Filter `
	-Exclude $ResultFile | `

	# -Recurse -> Go into subdirectories
	# -File    -> List only files
	# -Filter  -> Match a pattern like "*.extensionIWant"
	# -Exclude -> Don't list this file, because it would reference the result tree file itself, 
	#			and would stay outdated forever.

	# Generate a custom object with only these properties
	Select-Object Mode,Length,Directory,Name | `
	ForEach-Object {
		# Remove the full path from the directory
		# because that is not deterministic
		$_.Directory = $_.Directory -replace $RegexPattern, ""

		# Use PowerShell's rediculous convention to pass the object along to the next pipe.
		$_
	} | `

	# Ensure consistent formatting by specifying column widths.
	# We must specify the first one because bugs.
	# We must specify -Autosize because bugs.
	Format-Table -Property @{e="Mode"; width=5},@{e="Length"; width=8},Directory,Name -Autosize| `

	# Ensure the result is actually a string and not some retarded PowerShell object that
	# doesn't ToString() automatically.

	# Replace is needed because Format-Table tries to do funny buisness with the
	# headers and this end up in the file
	Out-String

	# Somewhere down the line we get some formatting characters inserted.
	# These should not be in the file so they have to be removed again.
	$pattern = [Regex]::Escape("[32;1m") + "|" + [Regex]::Escape("[0m")
	$Content = $Content -replace $pattern, ""


	# Write the result to the destination file, overwriting the old file.
	$Content | Set-Content $Destination

	$newHash = Get-FileHash $Destination

	if($oldHash.Hash -ne $newHash.Hash)
	{
		Write-Host "Files tree '$PartialPath' was updated, please check for new changes in git."
		#Write-Host $oldHash.Hash "->" $newHash.Hash
		return $False
	}
	return $True
}




Main
