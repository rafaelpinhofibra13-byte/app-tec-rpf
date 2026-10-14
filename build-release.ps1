param(
    [Parameter(Mandatory = $true)]
    [string]$BaseApk,
    [Parameter(Mandatory = $true)]
    [string]$VersionName,
    [Parameter(Mandatory = $true)]
    [int]$VersionCode,
    [Parameter(Mandatory = $true)]
    [string]$ApktoolJar,
    [Parameter(Mandatory = $true)]
    [string]$SourceHtml,
    [Parameter(Mandatory = $true)]
    [string]$KeystorePath,
    [string]$OutputDirectory = ".",
    [string]$KeyAlias = "androiddebugkey",
    [string]$KeystorePassword = "android"
)

$ErrorActionPreference = "Stop"

foreach ($path in @($BaseApk, $ApktoolJar, $SourceHtml, $KeystorePath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Arquivo obrigatorio nao encontrado: $path"
    }
}

if ($VersionCode -lt 2) {
    throw "VersionCode deve ser maior que o codigo da APK original (1)."
}
if ($VersionName -notmatch '^\d+\.\d+\.\d+$') {
    throw "VersionName deve usar o formato semantico X.Y.Z."
}

$buildTools = Join-Path $env:LOCALAPPDATA "Android\Sdk\build-tools\36.0.0"
$zipalign = Join-Path $buildTools "zipalign.exe"
$apksigner = Join-Path $buildTools "apksigner.bat"
foreach ($tool in @($zipalign, $apksigner)) {
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
        throw "Ferramenta Android nao encontrada: $tool"
    }
}

$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
[IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
$stage = Join-Path $env:TEMP ("a" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$unsigned = Join-Path $env:TEMP ("AppTecRPF-unsigned-" + [guid]::NewGuid().ToString("N") + ".apk")
$aligned = Join-Path $env:TEMP ("AppTecRPF-aligned-" + [guid]::NewGuid().ToString("N") + ".apk")
$output = Join-Path $OutputDirectory "SuperAppTecnico-$VersionName.apk"
$updateUrl = "https://rafaelpinhofibra13-byte.github.io/app-tec-rpf/update.json"

try {
    & java -jar $ApktoolJar d -f $BaseApk -o $stage
    if ($LASTEXITCODE -ne 0) { throw "Falha ao decodificar o APK base." }

    Copy-Item -LiteralPath $SourceHtml -Destination (Join-Path $stage "assets\index.html") -Force

    $activityPath = Join-Path $stage "smali_classes3\com\rafaelpinhofibra\superapp\MainActivity.smali"
    $activity = [IO.File]::ReadAllText($activityPath)
    $placeholder = "https://SEU-DOMINIO.com/downloads/update.json"
    if (-not $activity.Contains($placeholder)) {
        throw "URL de atualizacao esperada nao encontrada em MainActivity.smali."
    }
    $activity = $activity.Replace($placeholder, $updateUrl)
    [IO.File]::WriteAllText($activityPath, $activity, [Text.UTF8Encoding]::new($false))

    $apktoolConfig = Join-Path $stage "apktool.yml"
    $config = [IO.File]::ReadAllText($apktoolConfig)
    $config = [regex]::new('(?m)^  versionCode: .+$').Replace($config, "  versionCode: $VersionCode", 1)
    $config = [regex]::new('(?m)^  versionName: .+$').Replace($config, "  versionName: $VersionName", 1)
    [IO.File]::WriteAllText($apktoolConfig, $config, [Text.UTF8Encoding]::new($false))

    & java -jar $ApktoolJar b $stage -o $unsigned
    if ($LASTEXITCODE -ne 0) { throw "Falha ao reconstruir o APK." }

    & $zipalign -f -p 4 $unsigned $aligned
    if ($LASTEXITCODE -ne 0) { throw "Falha no alinhamento do APK." }

    & $apksigner sign --ks $KeystorePath --ks-key-alias $KeyAlias --ks-pass "pass:$KeystorePassword" --key-pass "pass:$KeystorePassword" --out $output $aligned
    if ($LASTEXITCODE -ne 0) { throw "Falha ao assinar o APK." }

    & $zipalign -c -p 4 $output
    if ($LASTEXITCODE -ne 0) { throw "A verificacao de alinhamento falhou." }

    & $apksigner verify --verbose $output
    if ($LASTEXITCODE -ne 0) { throw "A verificacao da assinatura falhou." }

    Write-Output "APK pronto: $output"
}
finally {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
    foreach ($temporaryFile in @($unsigned, $aligned)) {
        if (Test-Path -LiteralPath $temporaryFile) {
            Remove-Item -LiteralPath $temporaryFile -Force
        }
    }
}
