param (
   [string]$Directory = [System.IO.Path]::GetTempPath(),
   [switch]$ShowLog
)

Write-Output "Installing azurite"
npm install -g azurite

Write-Output "Starting azurite"
if ($ismacos -or $islinux) {
   $dir = "$Directory/azurite"
   $null = New-Item -Type Directory -Force -Path $dir
   azurite --silent --location $dir --debug "$dir/debug.log"
}

if ($iswindows) {
   $dir = "$Directory\azurite"
   $null = New-Item -Type Directory -Force -Path 
   azurite --silent --location $dir --debug "$dir\debug.log"
}