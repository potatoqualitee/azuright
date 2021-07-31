param (
   [string[]]$Install,
   [switch]$ShowLog
)

Write-Output "Installing azurite"
npm install -g azurite

if ($ismacos -or $islinux) {
   
}

if ($iswindows) {
   
}

<#
azurite --silent --location c:\azurite --debug c:\azurite\debug.log

#>