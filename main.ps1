param (
   [string]$Directory = [System.IO.Path]::GetTempPath(),
   [switch]$ShowLog
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

Start-Process -FilePath azurite -ArgumentList @("--silent", "--location", $dir, "--debug", $debuglog)
#azurite --silent --location $dir --debug $debuglog