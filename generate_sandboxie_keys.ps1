
Add-Type -AssemblyName System.Security

# Setup creation parameters to allow private key export
$creationParams = New-Object System.Security.Cryptography.CngKeyCreationParameters
$creationParams.ExportPolicy = [System.Security.Cryptography.CngExportPolicies]::AllowPlaintextExport

# Create a new ECDSA P-256 key
$key = [System.Security.Cryptography.CngKey]::Create([System.Security.Cryptography.CngAlgorithm]::ECDsaP256, $null, $creationParams)

# Export in BCRYPT format
$pubBlob = $key.Export([System.Security.Cryptography.CngKeyBlobFormat]::EccPublicBlob)
$privBlob = $key.Export([System.Security.Cryptography.CngKeyBlobFormat]::EccPrivateBlob)

$formattedPub = ""
for ($i = 0; $i -lt $pubBlob.Count; $i++) {
    $formattedPub += "0x{0:X2}" -f $pubBlob[$i]
    if ($i -lt $pubBlob.Count - 1) {
        $formattedPub += ", "
        if (($i + 1) % 16 -eq 0) { $formattedPub += "`r`n    " }
    }
}

Write-Host "--- NEW PUBLIC KEY HEX ---"
Write-Host $formattedPub
Write-Host "--- END ---"

[System.IO.File]::WriteAllBytes("o:\repos\Sandboxie\Sandboxie_PrivateKey.blob", $privBlob)
[System.IO.File]::WriteAllBytes("o:\repos\Sandboxie\Sandboxie_PublicKey.blob", $pubBlob)

Write-Host "Saved private key blob to: o:\repos\Sandboxie\Sandboxie_PrivateKey.blob"
Write-Host "Saved public key blob to: o:\repos\Sandboxie\Sandboxie_PublicKey.blob"
