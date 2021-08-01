[CmdletBinding()]
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
   [string]$CertPass
)

if ($OAuth -and -not $CertPath -and -not $SelfSignedCert) {
   throw "CertPath or SelfSignedCert are required when using OAuth"
}

if ($CertPath -and -not $CertKeyPath -and -not $CertPass) {
   throw "CertKeyPath or CertPass are required when using CertPath"
}

if (-not $Directory) {
   $Directory = [System.IO.Path]::GetTempPath()
} else {
   if (-not (Test-Path -Path $Directory)) {
      $null = New-Item -ItemType Directory -Path $Directory -Force
   }
}

$dir = Join-Path -Path $Directory -ChildPath azurite
$debuglog = Join-Path -Path $dir -ChildPath debug.log

Write-Verbose "Installing azurite"
$null = npm install -g azurite

Write-Verbose "Starting azurite"
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

if ($SelfSignedCert) {
   Write-Verbose "Creating self-signed certificate"
   $CertPath = Join-Path -Path $dir -ChildPath cert.pem
   $CertKeyPath = Join-Path -Path $dir -ChildPath key.pem

   if (-not $CertPass) {
      $CertPass = "AzurIte365.Invoke"
   }

   if ($isLinux -or $isMacOs) {
      $null = openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj '/CN=localhost' -keyout $CertKeyPath -out $CertPath -passout pass:$CertPass

      if ($isLinux) {
         $null = sudo cp $CertPath /etc/ssl/certs/ca.crt
         $null = sudo chmod 644 /etc/ssl/certs/ca.crt
         $null = sudo update-ca-certificates
      } else {
         $null = sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $CertPath
      }
   } else {
      $cert = New-SelfSignedCertificate -DnsName localhost -CertStoreLocation "Cert:\CurrentUser\My" -KeyLength 2048 -KeyExportPolicy Exportable

      $securepass = ConvertTo-SecureString -String $CertPass -AsPlainText -Force
      $null = $cert | Export-PfxCertificate -FilePath $CertPath -Password $securepass
   }
}

if ($CertPath) {
   $proto = "https"
   $params += "--cert", $CertPath
} else {
   $proto = "http"
}

if ($CertKeyPath) {
   $params += "--key", $CertKeyPath
}

if ($CertPass) {
   $params += "--pwd", $CertPass
}

$null = Start-Process -FilePath azurite -ArgumentList $params

Write-Verbose "
Params: $params

Default account name: 
devstoreaccount1

Default account key:
Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="

Write-Output "DefaultEndpointsProtocol=$proto;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=$($proto)://127.0.0.1:$BlobPort/devstoreaccount1;QueueEndpoint=$($proto)://127.0.0.1:$QueuePort/devstoreaccount1;"