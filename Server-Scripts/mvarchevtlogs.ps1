$hst = $env:computername

if (test-path \\rps001\e$\evtlogarch\$hst) {
	$dest = "\\rps001\e$\evtlogarch\$hst" }
else {
	new-item -itemtype directory -path \\rps001\e$\evtlogarch\$hst
	$dest = "\\rps001\e$\evtlogarch\$hst"
}

$startdir = "c:\windows\system32\winevt\logs\"
$archives = get-childitem $startdir -filter Archive*

if ($archives){
	foreach ($archive in $archives) {
		$path = $startdir + $archive.name
		move-item -path $path -destination 
	}
}