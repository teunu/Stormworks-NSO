$erroractionpreference = "Stop"
$regex = [regex]::new("mega_island_(\d+)_(\d+).ply")

get-childItem `
| foreach-object {
	$filename = $_.name
	$match = $regex.Match($filename)
	if( $match.Success) {
		$oldname = $_
		$x = $match.Groups[1].Value
		$y = $match.Groups[2].Value
		$newname = "$($x)_$y.ply"	
		move-item -path $filename -destination $newname
		write-host "$filename -> $newname"
	}
}