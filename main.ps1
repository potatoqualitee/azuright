param (
   [string]$Directory = [System.IO.Path]::GetTempPath(),
   [int]$BlobPort = "10000",
   [int]$QueuePort = "10001",
   [int]$TablePort = "10002"
)

if ($ismacos -or $islinux) {
   $dir = "$Directory/azurite"
   $debuglog = "$dir/debug.log"
}

if ($iswindows) {
   $dir = "$Directory\azurite"
   $debuglog = "$dir\debug.log"
}

Write-Output "Installing azurite"
npm install -g azurite

Write-Output "Starting azurite"
$null = New-Item -Type Directory -Force -Path $dir

Start-Process -FilePath azurite -ArgumentList @("--silent", "--location", $dir, "--debug", $debuglog, "--blobPort", $BlobPort, "--queuePort", $QueuePort, "--tablePort", $TablePort)