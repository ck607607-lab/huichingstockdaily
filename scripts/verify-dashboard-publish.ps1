param(
  [Parameter(Mandatory = $true)]
  [string]$ExpectedDate,

  [string]$Branch = "main",
  [string]$SiteUrl = "https://huichingstockdaily.netlify.app/"
)

$ErrorActionPreference = "Stop"

function Assert-Contains {
  param(
    [string]$Content,
    [string]$Needle,
    [string]$Label
  )

  if ($Content -notmatch [regex]::Escape($Needle)) {
    throw "$Label does not contain expected text: $Needle"
  }
}

function Read-Utf8 {
  param([string]$Path)
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $repoRoot "index.html"

if (-not (Test-Path $indexPath)) {
  throw "index.html not found at $indexPath"
}

$localHtml = Read-Utf8 -Path $indexPath
Assert-Contains -Content $localHtml -Needle $ExpectedDate -Label "Local index.html"

git -C $repoRoot fetch origin $Branch | Out-Null
$remoteHead = (git -C $repoRoot rev-parse "origin/$Branch").Trim()
$localHead = (git -C $repoRoot rev-parse HEAD).Trim()

if ($remoteHead -ne $localHead) {
  throw "HEAD mismatch: local=$localHead origin/$Branch=$remoteHead"
}

$siteHtml = (Invoke-WebRequest -Uri $SiteUrl -UseBasicParsing).Content
Assert-Contains -Content $siteHtml -Needle $ExpectedDate -Label "Netlify site"

Write-Host "Publish verification passed."
Write-Host "Date      : $ExpectedDate"
Write-Host "Local HEAD: $localHead"
Write-Host "Site URL  : $SiteUrl"
