param(
 [Parameter(Mandatory=$true)][string]$SourceFolder,
 [Parameter(Mandatory=$true)][string]$ProjectFolder
)
$ErrorActionPreference='Stop'
try {
 $projectFile=Join-Path $ProjectFolder 'project.godot'
 if (-not (Test-Path -LiteralPath $projectFile -PathType Leaf)) {throw "Not a Godot project: $ProjectFolder"}
 $names=@('q1_1.png','q1_2.png','q1_3.png','q1_4.png','q1_5.png','q2_1.png','q2_2.png','q2_3.png','q2_4.png')
 foreach($name in $names) {
   $src=Join-Path $SourceFolder $name
   if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {throw "Missing original image: $name"}
   $stream=[System.IO.File]::OpenRead($src)
   try {
      $signature=New-Object byte[] 8
      if ($stream.Read($signature,0,8) -ne 8) { throw "File too short: $name" }
      if ([System.BitConverter]::ToString($signature) -ne '89-50-4E-47-0D-0A-1A-0A') {throw "This is not a real PNG: $name"}
   } finally { $stream.Close() }
 }
 $dest=Join-Path $ProjectFolder 'Stage3Assets'
 if (-not (Test-Path -LiteralPath $dest -PathType Container)) {throw "Missing Stage3Assets folder: $dest"}
 $stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
 $backup=Join-Path $ProjectFolder "Stage3Assets_backup_$stamp"
 Copy-Item -LiteralPath $dest -Destination $backup -Recurse -Force
 foreach($name in $names) {
   Copy-Item -LiteralPath (Join-Path $SourceFolder $name) -Destination (Join-Path $dest $name) -Force
 }
 Write-Host "SUCCESS: 9 genuine source PNGs installed. Backup: $backup"
 exit 0
} catch {
 Write-Error $_
 exit 1
}
