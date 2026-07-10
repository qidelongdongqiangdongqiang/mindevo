param(
  [string]$SourceDir = "."
)

$ErrorActionPreference = "Stop"

$resolvedSourceDir = (Resolve-Path -LiteralPath $SourceDir).Path
$gitSegment = [IO.Path]::DirectorySeparatorChar + ".git" + [IO.Path]::DirectorySeparatorChar
$htmlFiles = Get-ChildItem -Path $resolvedSourceDir -Recurse -Filter *.html | Where-Object {
  $_.FullName -notlike "*$gitSegment*" -and $_.Name -ne "live-home-final.html"
}

$failures = New-Object System.Collections.Generic.List[string]
$shareScript = '/assets/js/wechat-share.js?v=20260710'

foreach ($file in $htmlFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw
  $hasOgTitle = $content -match '<meta\s+property=["'']og:title["'']'
  if ($hasOgTitle) {
    foreach ($required in @(
      '<script src="https://res.wx.qq.com/open/js/jweixin-1.6.0.js"></script>',
      "<script src=`"$shareScript`"></script>"
    )) {
      if ($content -notlike "*$required*") {
        $failures.Add("$($file.FullName): missing WeChat share loader: $required")
      }
    }
  }

  if ($content -match 'spectrum-ai-4/index\.html') {
    $failures.Add("$($file.FullName): use canonical /programs/spectrum-ai-4/ instead of index.html links")
  }
}

foreach ($requiredFile in @(
  "assets/js/wechat-share.js",
  "services/wechat-share/wechat_signature_service.py",
  "ops/wechat-share/install-wechat-share-root.sh",
  "ops/wechat-share/mindevo-wechat-share.service",
  "ops/wechat-share/mindevo-wechat-share-nginx.conf"
)) {
  $path = Join-Path $resolvedSourceDir $requiredFile
  if (!(Test-Path -LiteralPath $path -PathType Leaf)) {
    $failures.Add("missing required WeChat automation file: $requiredFile")
  }
}

if ($failures.Count -gt 0) {
  Write-Output "WeChat share checks failed:"
  $failures | ForEach-Object { Write-Output "- $_" }
  exit 1
}

Write-Output "WeChat share checks passed."
