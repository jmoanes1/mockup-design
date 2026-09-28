# Downloads candidate stock photos at preview size and builds a labelled contact sheet
# so the final image selection can be verified visually before being used in the mockup.
param([switch]$Force)

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

$Root   = Split-Path -Parent $PSScriptRoot
$Review = Join-Path $Root 'assets\_review'
New-Item -ItemType Directory -Force -Path $Review | Out-Null
if ($Force) { Get-ChildItem $Review -File | Remove-Item -Force }

$JpegHeaders = @{ 'Accept' = 'image/jpeg'; 'Referer' = 'https://www.pexels.com/' }

$pexels = @(
  # fauxels business/office series + widely used business & interior photography
  3184291, 3184292, 3184293, 3184306, 3184338, 3184339, 3184353, 3184360,
  3184405, 3184418, 3184423, 3184434, 3184460, 3184465, 3184469, 3184472,
  3184639, 3184644, 3184657, 3184681, 3182759, 3182765, 3182773, 3182812,
  3183150, 3183153, 3183174, 3183197, 1181341, 1181354, 1181396, 1181406,
  1170412, 380768, 37347, 260931, 434840, 2884864, 1595385, 590022,
  2339009, 3075993, 2246476, 906494, 1554646, 2226458, 753331, 1145434,
  2569842, 2760243, 2135677, 2886932, 1084540, 263402, 305566, 1170979,
  264636, 1579253, 1005638, 2026324, 358319, 1637923, 2182970, 2379004,
  1043471, 1516680, 733872, 220453, 1681010, 614810
)

$downloaded = @()
foreach ($id in $pexels) {
  $out = Join-Path $Review "p_$id.jpg"
  if (Test-Path $out) { $downloaded += "p_$id.jpg"; continue }
  try {
    Invoke-WebRequest -Uri "https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=340" `
      -OutFile $out -TimeoutSec 25 -UseBasicParsing -Headers $JpegHeaders
    $b = [System.IO.File]::ReadAllBytes($out)
    if ($b.Length -gt 3000 -and $b[0] -eq 0xFF -and $b[1] -eq 0xD8) { $downloaded += "p_$id.jpg" } else { Remove-Item $out }
  } catch { }
}
Write-Host "PEXELS OK: $($downloaded.Count) / $($pexels.Count)"

# Contact sheet markup
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('<!doctype html><html><head><meta charset="utf-8"><style>
body{font:12px/1.3 "Segoe UI",sans-serif;background:#fff;margin:0;padding:12px}
.grid{display:grid;grid-template-columns:repeat(8,1fr);gap:8px}
figure{margin:0}
img{width:100%;height:120px;object-fit:cover;display:block;background:#eee}
figcaption{font-weight:600;padding:2px 0;color:#111}
</style></head><body><div class="grid">')

foreach ($f in $downloaded) {
  [void]$sb.AppendLine("<figure><img src=""$f""><figcaption>$f</figcaption></figure>")
}

# Wikimedia Commons candidates (skip PDF-derived scans, keep real photography)
if (Test-Path (Join-Path $Root 'assets\img\_commons.txt')) {
  $i = 0
  Get-Content (Join-Path $Root 'assets\img\_commons.txt') -Encoding UTF8 | ForEach-Object {
    $parts = $_ -split "`t"
    if ($parts.Count -ge 3 -and $parts[2] -and $parts[1] -notmatch '\.pdf') {
      $i++
      $name = "c_{0:d2}.jpg" -f $i
      $out  = Join-Path $Review $name
      if (-not (Test-Path $out)) {
        try { Invoke-WebRequest -Uri ($parts[2] + '&width=340') -OutFile $out -TimeoutSec 30 -UseBasicParsing -Headers $JpegHeaders } catch { }
      }
      if (Test-Path $out) {
        $label = ($parts[1] -replace '^File:', '') -replace '&', '&amp;' -replace '<', '&lt;'
        if ($label.Length -gt 58) { $label = $label.Substring(0, 58) }
        [void]$sb.AppendLine("<figure><img src=""$name""><figcaption>$name - $label</figcaption></figure>")
      }
    }
  }
}

[void]$sb.AppendLine('</div></body></html>')
$sheet = Join-Path $Review 'sheet.html'
Set-Content -Path $sheet -Value $sb.ToString() -Encoding UTF8
Write-Host "SHEET: $sheet"
