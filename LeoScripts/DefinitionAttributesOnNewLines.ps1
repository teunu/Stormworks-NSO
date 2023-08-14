# Changes the definition.xml files to have each attribute of the
# <definition ...> on a separate line.
# Because it's way easier to read and track ghanges that way.



# Ensure sensible behaviour
$ErrorActionPreference = "Stop"


# (                          Start capture group
#  <definition               Literal string '<definition ' (Note the space)
#              .*            Followed by any character any number of times
#                ="          Until the literal string '="'
#                  [^"]*     Followed by any number of not "
#                       "    Followed by that "
#                        )   End of the capture group
#                            Literal string ' ' (a single space)
$regex = '(<definition .*="[^"]*") '
$replace = "`$1`n"


$Files = Get-ChildItem -Recurse -File -Filter "*.xml" -Path "$PSScriptRoot/../rom/data/definitions/"
$Files += Get-ChildItem -Recurse -File -Filter "*.xml" -Path "$PSScriptRoot/../rom/graphics/particles/"


$Files | ForEach-Object `
{
	$file = $_

	$content = Get-Content -Raw $file

	$counter = -1


	do {
		$counter++
		$oldValue = $content
		$content = $content -replace $regex, $replace
	}
	while ($oldValue -ne $content)


	$content | Set-Content $file -NoNewline


	"$file $counter"

	return
}