param (
   [string]$Directory = [System.IO.Path]::GetTempPath(),
   [int]$BlobPort = "10000",
   [int]$QueuePort = "10001",
   [int]$TablePort = "10002",
   [switch]$Silent,
   [switch]$Loose,
   [switch]$OAuth
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

$params = @("--location", $dir, "--debug", $debuglog, "--blobPort", $BlobPort, "--queuePort", $QueuePort, "--tablePort", $TablePort)

if ($Silent) {
   $params += "--silent"
}
if ($Loose) {
   $params += "--loose"
}
if ($OAuth) {
   $params += "--oauth"
}

Start-Process -FilePath azurite -ArgumentList $params

Write-Output "Default account name: devstoreaccount1`n"
Write-Output "Default account key:`n Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="