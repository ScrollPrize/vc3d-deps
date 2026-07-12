param(
    [Parameter(Mandatory = $true)]
    [string]$Archive
)

$ErrorActionPreference = 'Stop'
$Destination = 'C:\msys64'

if (-not $IsWindows) {
    throw 'The VC3D UCRT64 snapshot can only be restored on Windows.'
}
if (-not (Test-Path -LiteralPath $Archive -PathType Leaf)) {
    throw "Snapshot not found: $Archive"
}

$sevenZip = Join-Path $env:ProgramFiles '7-Zip\7z.exe'
if (-not (Test-Path -LiteralPath $sevenZip -PathType Leaf)) {
    throw "7-Zip was not found at $sevenZip"
}

if (Test-Path -LiteralPath $Destination) {
    Remove-Item -LiteralPath $Destination -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
& $sevenZip x '-y' "-o$Destination" $Archive
if ($LASTEXITCODE -ne 0) {
    throw "7-Zip failed to restore the snapshot (exit $LASTEXITCODE)."
}

$bash = Join-Path $Destination 'usr\bin\bash.exe'
$compiler = Join-Path $Destination 'ucrt64\bin\g++.exe'
if (-not (Test-Path -LiteralPath $bash) -or -not (Test-Path -LiteralPath $compiler)) {
    throw 'Restored snapshot is incomplete: bash.exe or UCRT64 g++.exe is missing.'
}

"$Destination\ucrt64\bin" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
"$Destination\usr\bin" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
'MSYSTEM=UCRT64' | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
'CHERE_INVOKING=1' | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append

Write-Host "Restored VC3D UCRT64 dependencies to $Destination"
