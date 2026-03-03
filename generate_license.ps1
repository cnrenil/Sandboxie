
Add-Type -AssemblyName System.Security

# Load our private key (BCRYPT ECCPRIVATE_BLOB)
$privKeyFile = "o:\repos\Sandboxie\Sandboxie_PrivateKey.blob"
if (-not (Test-Path $privKeyFile)) {
    Write-Error "Private key file not found at $privKeyFile"
    exit 1
}
$privKeyBytes = [System.IO.File]::ReadAllBytes($privKeyFile)

# Import the key to CNG
$key = [System.Security.Cryptography.CngKey]::Import($privKeyBytes, [System.Security.Cryptography.CngKeyBlobFormat]::EccPrivateBlob)
$ecdsa = New-Object System.Security.Cryptography.ECDsaCng($key)
$ecdsa.HashAlgorithm = [System.Security.Cryptography.CngAlgorithm]::Sha256

# Define the license tags
$tags = @(
    "SOFTWARE: Sandboxie-Plus",
    "TYPE: DEVELOPER",
    "LEVEL: HUGE",
    "DATE: 01.01.2024",
    "DAYS: 3650",
    "OPTIONS: SBOX, EBOX, NETI, DESK, NoCR",
    "UPDATEKEY: MyOwnDeveloperKey123"
)

# Hash the tags in the exact same way as the Sandboxie driver
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hasher = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256)

foreach ($line in $tags) {
    $parts = $line.Split(':', 2)
    $name = $parts[0].Trim()
    $value = $parts[1].Trim()
    
    # Hash name (as UTF8)
    $nameBytes = [System.Text.Encoding]::UTF8.GetBytes($name)
    $hasher.AppendData($nameBytes)
    
    # Hash value (as UTF8)
    $valueBytes = [System.Text.Encoding]::UTF8.GetBytes($value)
    $hasher.AppendData($valueBytes)
}

$finalHash = $hasher.GetHashAndReset()

# Sign the hash
$signature = $ecdsa.SignHash($finalHash)
$signatureB64 = [System.Convert]::ToBase64String($signature)

# Generate Certificate.dat content
$certContent = ""
foreach ($line in $tags) {
    $certContent += "$line`r`n"
}
$certContent += "SIGNATURE: $signatureB64`r`n"

# Add BOM (Sandboxie seems to use Stream_Read_BOM)
$utf8WithBom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText("o:\repos\Sandboxie\Certificate.dat", $certContent, $utf8WithBom)

Write-Host "License generated successfully: o:\repos\Sandboxie\Certificate.dat"
Write-Host "Values hashed and signed."
