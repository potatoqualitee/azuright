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
$null = New-Item -Type Directory -Force -Path $dir

if ($SelfSignedCert) {
   Write-Verbose "Creating and trusting self-signed certificate"
   $CertPath = Join-Path -Path $Directory -ChildPath cert.pem
   $CertKeyPath = Join-Path -Path $Directory -ChildPath key.pem

   if (-not $CertPass) {
      $CertPass = "AzurIte365.Invoke"
   }
   
   if ($isLinux) {
      openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj '/CN=localhost' -keyout $CertKeyPath -out $CertPath -passout pass:$CertPass | Write-Verbose
      $CertPass = $null
      sudo cp $CertPath /etc/ssl/certs/ca.crt | Write-Verbose
      sudo chmod 644 /etc/ssl/certs/ca.crt | Write-Verbose
      sudo update-ca-certificates | Write-Verbose
   }
   if ($isMacOS) {
      # It was super hard to register a self-signed certificate on a Mac
      # so we'll use mkcert -- they got it to work somehow
      Write-Verbose "Installing mkcert"
      $null = wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-darwin-amd64
      $null = chmod +x mkcert-v1.4.3-darwin-amd64
      $null = sudo mv ./mkcert-v1.4.3-darwin-amd64 /usr/local/bin/mkcert

      Write-Verbose "Running mkcert"
      mkcert -install | Write-Verbose
      mkcert -key-file $CertKeyPath -cert-file $CertPath localhost | Write-Verbose
   }
   if ($isWindows) {
      $PfxPath = Join-Path -Path $Directory -ChildPath cert.pfx
      $cert = New-SelfSignedCertificate -DnsName localhost -CertStoreLocation "Cert:\CurrentUser\My" -KeyLength 2048 -KeyExportPolicy Exportable

      
      $securepass = ConvertTo-SecureString -String $CertPass -AsPlainText -Force
      $null = $cert | Export-PfxCertificate -FilePath $PfxPath -Password $securepass -CryptoAlgorithmOption AES256_SHA256 -NoProperties
      $CertPath = $PfxPath
      # trust self signed cert
      Write-Verbose "Trusting certificate"
      $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root","LocalMachine"
      $null = $store.Open("ReadWrite")
      $null = $store.Add($cert)
      $null = $store.Close()
   }
}

Write-Verbose "Installing azurite"
$null = npm install -g azurite

Write-Verbose "Starting azurite"
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

if ($isLinux -or $isMacOS) {
   $null = Start-Process -FilePath azurite -ArgumentList $params -Verbose
} else {
   $null = Start-Process -FilePath azurite.cmd -ArgumentList $params -Verbose
}

Write-Verbose "
Params: $params

Default account name: 
devstoreaccount1

Default account key:
Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==

"

Write-Output "DefaultEndpointsProtocol=$proto;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=$($proto)://localhost:$BlobPort/devstoreaccount1;QueueEndpoint=$($proto)://localhost:$QueuePort/devstoreaccount1;"