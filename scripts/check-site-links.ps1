param(
  [string]$SourceDir = ".",
  [string]$SiteOrigin = "https://www.mindevo.club",
  [switch]$CheckExternal
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$resolvedSourceDir = (Resolve-Path -LiteralPath $SourceDir).Path
if (!(Test-Path $resolvedSourceDir -PathType Container)) {
  throw "SourceDir does not exist: $SourceDir"
}

$pathSeparator = [IO.Path]::DirectorySeparatorChar
$gitSegment = "$pathSeparator.git$pathSeparator"

$htmlFiles = Get-ChildItem -Path $resolvedSourceDir -Recurse -Filter *.html | Where-Object {
  $_.FullName -notlike "*$gitSegment*"
}

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$checked = 0
$allowedExternalFailures = @(
  "https://beian.miit.gov.cn/"
)

function Resolve-LocalTarget {
  param(
    [string]$CurrentFile,
    [string]$Link
  )

  $withoutHash = ($Link -split "#")[0]
  $target = ($withoutHash -split "\?")[0]
  if ([string]::IsNullOrWhiteSpace($target)) { return $null }

  if ($target.StartsWith("/")) {
    $path = Join-Path $resolvedSourceDir $target.TrimStart("/")
  } else {
    $path = Join-Path (Split-Path $CurrentFile -Parent) $target
  }

  $full = [IO.Path]::GetFullPath($path)
  if ((Test-Path $full -PathType Container)) {
    $full = Join-Path $full "index.html"
  } elseif ($Link.EndsWith("/")) {
    $full = Join-Path $full "index.html"
  }

  return $full
}

foreach ($file in $htmlFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw
  $matches = [regex]::Matches($content, '(?:href|src)=["'']([^"'']+)["'']', 'IgnoreCase')

  foreach ($match in $matches) {
    $link = $match.Groups[1].Value.Trim()
    if (
      !$link -or
      $link.StartsWith("#") -or
      $link.StartsWith("tel:") -or
      $link.StartsWith("mailto:") -or
      $link.StartsWith("javascript:")
    ) {
      continue
    }

    $checked++

    if ($link.StartsWith($SiteOrigin)) {
      $localLink = $link.Substring($SiteOrigin.Length)
      if ([string]::IsNullOrWhiteSpace($localLink)) { $localLink = "/" }
      $target = Resolve-LocalTarget -CurrentFile $file.FullName -Link $localLink
      if ($target -and !(Test-Path $target -PathType Leaf)) {
        $failures.Add("$($file.FullName): missing same-site target: $link -> $target")
      }
      continue
    }

    if ($link -match "^https?://") {
      if ($CheckExternal) {
        try {
          try {
            Invoke-WebRequest -Uri $link -UseBasicParsing -Method Head -TimeoutSec 20 | Out-Null
          } catch {
            Invoke-WebRequest -Uri $link -UseBasicParsing -TimeoutSec 20 | Out-Null
          }
        } catch {
          if ($allowedExternalFailures -contains $link) {
            $warnings.Add("$($file.FullName): external link requires manual check: $link")
          } else {
            $failures.Add("$($file.FullName): external link failed: $link")
          }
        }
      }
      continue
    }

    $target = Resolve-LocalTarget -CurrentFile $file.FullName -Link $link
    if ($target -and !(Test-Path $target -PathType Leaf)) {
      $failures.Add("$($file.FullName): missing local target: $link -> $target")
    }
  }
}

Write-Output "Checked $checked links across $($htmlFiles.Count) HTML files."

if ($warnings.Count -gt 0) {
  Write-Output "Warnings:"
  $warnings | ForEach-Object { Write-Output "- $_" }
}

if ($failures.Count -gt 0) {
  Write-Output "Broken links:"
  $failures | ForEach-Object { Write-Output "- $_" }
  exit 1
}

Write-Output "All checked links passed."
