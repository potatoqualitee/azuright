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

if ($SelfSignedCert) {
   if (-not $CertPass) {
      $CertPass = "AzurIte365.Invoke"
   }
   if ($isLinux -or $isMacOs) {
      # Create self signed cert on linux using openssl
      $CertPath = Join-Path -Path $dir -ChildPath cert.pem
      $CertKeyPath = Join-Path -Path $dir -ChildPath key.pem
      $cmd = "openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj '/CN=localhost' -keyout $CertKeyPath -out $CertPath -passout pass:$CertPass"
      $null = $PSCmdlet.Invoke($cmd)

      # register with Linux
      if ($isLinux) {
         sudo cp $CertPath /etc/ssl/certs/ca.crt
         sudo chmod 644 /etc/ssl/certs/ca.crt
         sudo update-ca-certificates
      }
   } else {
      # create a self signed cert on Windows
      $cert = New-SelfSignedCertificate -DnsName localhost -CertStoreLocation "Cert:\CurrentUser\My" -KeyLength 2048 -KeyExportPolicy Exportable

      # Export Self signed cert to PFX with password Hello123!
      $securepass = (New-Object PSCredential -ArgumentList "nada", $CertPass).Password
      $cert | Export-PfxCertificate -FilePath $CertPath -Password $securepass

      # register self signed cert on Windows
      # $cert | Register-SelfSignedCertificate -CertStoreLocation "Cert:\CurrentUser\My"
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

Start-Process -FilePath azurite -ArgumentList $params

Write-Output "
$(if (-not $CertPass) {
   "Params: $params"
})

Default account name: 
devstoreaccount1

Default account key:
Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==

Connection string: 
DefaultEndpointsProtocol=$proto;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=$($proto)://127.0.0.1:$BlobPort/devstoreaccount1;QueueEndpoint=$($proto)://127.0.0.1:$QueuePort/devstoreaccount1;

"