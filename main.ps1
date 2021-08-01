param (
   [string]$Directory,
   [int]$BlobPort,
   [int]$QueuePort,
   [int]$TablePort,
   [switch]$Silent,
   [switch]$Loose,
   [switch]$OAuth,
   [switch]$SelfSignedCert,
   [string]$CertPath,
   [string]$CertKeyPath,
   [string]$CertPassword
)

if ($OAuth -and -not $CertPath -and -not $SelfSignedCert) {
   throw "CertPath or SelfSignedCert are required when using OAuth"
}

if ($CertPath -and -not $CertKeyPath -and -not $CertPassword) {
   throw "CertKeyPath or CertPasswor are required when using CertPath"
}

if (-not $Directory) {
   $Directory = [System.IO.Path]::GetTempPath()
}

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

if ($CertPath) {
   $params += "--cert", $CertPath
}

if ($CertKeyPath) {
   $params += "--key", $CertKeyPath
}

if ($CertPassword) {
   $params += "--pwd", $CertPassword
}

Start-Process -FilePath azurite -ArgumentList $params

Write-Output "

Default account name: 
devstoreaccount1

Default account key:
Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==

Connection string: 
DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:$BlobPort/devstoreaccount1;QueueEndpoint=http://127.0.0.1:$QueuePort/devstoreaccount1;

"