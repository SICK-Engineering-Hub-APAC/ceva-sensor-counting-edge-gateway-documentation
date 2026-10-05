param(
    [string]$OutputPath = "_site"
)

$ErrorActionPreference = "Stop"

function ConvertTo-HtmlText {
    param([AllowNull()][string]$Value)
    return [System.Net.WebUtility]::HtmlEncode($Value)
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$manifestPath = Join-Path $repoRoot "manuals/sensor-counting-edge-gateway/manifest.json"
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$outputRoot = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $repoRoot $OutputPath
}

if (Test-Path $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
Set-Content -LiteralPath (Join-Path $outputRoot ".nojekyll") -Value "" -Encoding ASCII
$siteAssetsOutput = Join-Path $outputRoot "assets/site"
New-Item -ItemType Directory -Path $siteAssetsOutput -Force | Out-Null
Copy-Item -Path (Join-Path $repoRoot "assets/site/*") -Destination $siteAssetsOutput -Recurse -Force

$slug = [string]$manifest.slug
$title = ConvertTo-HtmlText $manifest.title
$description = ConvertTo-HtmlText $manifest.description
$latest = ConvertTo-HtmlText $manifest.latest
$publicPath = ([string]$manifest.publicPath).Trim("/")
$versionCount = @($manifest.versions).Count
$latestVersionInfo = @($manifest.versions | Where-Object { [string]$_.version -eq [string]$manifest.latest } | Select-Object -First 1)
$appVersions = @($latestVersionInfo.compatibleAppVersions) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
$compatibility = if ($appVersions.Count -gt 0) {
  ConvertTo-HtmlText ("Compatible app: " + ($appVersions -join ", "))
} else {
  "Compatibility not specified"
}
$manualSourceRoot = Join-Path $repoRoot "manuals/$slug"
$manualOutputRoot = Join-Path $outputRoot "manuals/$slug"
$publicOutputRoot = Join-Path $outputRoot $publicPath
New-Item -ItemType Directory -Path $manualOutputRoot -Force | Out-Null

$versionLinks = foreach ($versionInfo in @($manifest.versions)) {
    $version = ConvertTo-HtmlText $versionInfo.version
    $status = ConvertTo-HtmlText $versionInfo.status
    $date = ConvertTo-HtmlText $versionInfo.date
    $summary = ConvertTo-HtmlText $versionInfo.summary
    $dateText = if ([string]::IsNullOrWhiteSpace([string]$date)) { "" } else { " $date" }
    @"
      <li><a href="$version/index.html"><span><strong>$version</strong><br><small>$summary</small></span><span>$status$dateText</span></a></li>
"@
}

$latestSource = Join-Path $manualSourceRoot "versions/$($manifest.latest)"
if (-not (Test-Path (Join-Path $latestSource "index.html"))) {
    throw "Missing index.html for latest version '$($manifest.latest)' at $latestSource"
}

foreach ($versionInfo in @($manifest.versions)) {
    $version = [string]$versionInfo.version
    $versionSource = Join-Path $manualSourceRoot "versions/$version"
    if (-not (Test-Path (Join-Path $versionSource "index.html"))) {
        throw "Missing index.html for version '$version' at $versionSource"
    }

    $versionOutput = Join-Path $manualOutputRoot $version
    New-Item -ItemType Directory -Path $versionOutput -Force | Out-Null
    Copy-Item -Path (Join-Path $versionSource "*") -Destination $versionOutput -Recurse -Force
}

New-Item -ItemType Directory -Path $publicOutputRoot -Force | Out-Null
Copy-Item -Path (Join-Path $latestSource "*") -Destination $publicOutputRoot -Recurse -Force

$versionsPage = @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$title versions</title>
    <link rel="icon" type="image/svg+xml" href="../../$publicPath/assets/images/brand/sick-logo.svg">
    <link rel="stylesheet" href="../../assets/site/site.css">
  </head>
  <body>
    <header class="site-header"><div class="site-header__inner"><a class="brand" href="../../index.html"><img src="../../$publicPath/assets/images/brand/sick-logo.svg" alt="SICK"><span>Sensor Counting Edge Gateway</span></a><a class="header-link" href="../../$publicPath/index.html">Latest manual</a></div></header>
    <main class="site-main">
      <p class="eyebrow">Documentation archive</p>
      <h1>$title</h1>
      <p class="lead">$description</p>
      <ul class="version-list">
$($versionLinks -join "")
      </ul>
    </main>
    <footer class="site-footer">SICK Engineering Hub APAC</footer>
  </body>
</html>
"@
Set-Content -LiteralPath (Join-Path $manualOutputRoot "versions.html") -Value $versionsPage -Encoding UTF8

$latestRedirect = @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="0; url=$latest/index.html">
    <title>$title latest</title>
    <link rel="icon" type="image/svg+xml" href="../../$publicPath/assets/images/brand/sick-logo.svg">
  </head>
  <body><p><a href="$latest/index.html">Open the latest manual ($latest)</a></p></body>
</html>
"@
Set-Content -LiteralPath (Join-Path $manualOutputRoot "index.html") -Value $latestRedirect -Encoding UTF8

$landingPage = @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="$description">
    <title>Sensor Counting Edge Gateway Documentation</title>
    <link rel="icon" type="image/svg+xml" href="$publicPath/assets/images/brand/sick-logo.svg">
    <link rel="stylesheet" href="assets/site/site.css">
  </head>
  <body>
    <header class="site-header">
      <div class="site-header__inner">
        <a class="brand" href="index.html">
          <img class="brand__logo" src="$publicPath/assets/images/brand/sick-logo.svg" alt="SICK">
          <span>Sensor Counting Edge Gateway</span>
        </a>
        <nav class="nav" aria-label="Primary navigation">
          <a href="index.html">Manuals</a>
        </nav>
      </div>
    </header>
    <main class="site-main">
      <section class="hero">
        <p class="eyebrow">Public documentation</p>
        <h1>Sensor Counting Edge Gateway Documentation</h1>
        <p class="lead">
          End-user documentation for operating the Sensor Counting Edge Gateway,
          monitoring counts, reviewing updates, and troubleshooting the system.
        </p>
      </section>
      <section class="manual-grid" aria-label="Documentation list">
        <a class="manual-card" href="$publicPath/index.html">
          <h2>$title</h2>
          <p>$description</p>
          <div class="manual-card__meta">
            <span class="badge">Latest $latest</span>
            <span class="badge">$compatibility</span>
            <span class="badge">$versionCount version(s)</span>
          </div>
        </a>
      </section>
    </main>
    <footer class="site-footer">
      <span>&copy; <span data-current-year></span> SICK Engineering Hub APAC</span>
    </footer>
    <script>document.querySelector('[data-current-year]').textContent = new Date().getFullYear();</script>
  </body>
</html>
"@
Set-Content -LiteralPath (Join-Path $outputRoot "index.html") -Value $landingPage -Encoding UTF8

Write-Host "Built static site at $outputRoot"