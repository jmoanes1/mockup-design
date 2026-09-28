# =============================================================================
#  Renders a mockup page in headless Chrome and slices the screenshot into
#  readable bands for visual review (assets\_review).
#  Usage: powershell -ExecutionPolicy Bypass -File tools\screenshot.ps1 -Page index.html
# =============================================================================
param(
  [Parameter(Mandatory = $true)][string]$Page,
  [int]$Width = 1440,
  [int]$Height = 4400,
  [int]$Bands = 3,
  [int]$BandWidth = 1200,
  [switch]$Mobile,
  [string]$Out
)

$ProgressPreference = 'SilentlyContinue'
$Root   = Split-Path -Parent $PSScriptRoot
$Review = Join-Path $Root 'assets\_review'
New-Item -ItemType Directory -Force -Path $Review | Out-Null

$chrome = @(
  'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
  'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $chrome) { throw 'Geen Chrome of Edge gevonden.' }

$slug = if ($Out) { $Out } else { [System.IO.Path]::GetFileNameWithoutExtension($Page) }
if ($Mobile) { $slug = "$slug-mobile" }
$png  = Join-Path $Review "$slug.png"
$url  = 'file:///' + ((Resolve-Path (Join-Path $Root $Page)).Path -replace '\\', '/')

# Chrome enforces a minimum window width of roughly 500 px on Windows, so the
# mobile view uses 500 px; narrower requests are cropped, not re-laid-out.
$size = if ($Mobile) { "500,$($Height)" } else { "$Width,$($Height)" }
$profile = Join-Path $env:TEMP ("cr_" + [System.Guid]::NewGuid().ToString('N').Substring(0, 8))

& $chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 `
  --force-prefers-reduced-motion --virtual-time-budget=4500 --window-size=$size --screenshot="$png" `
  --user-data-dir=$profile $url 2>&1 | Out-Null
Start-Sleep -Milliseconds 700

if (-not (Test-Path $png)) { throw "Screenshot mislukt voor $url" }
Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Drawing
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$enc  = New-Object System.Drawing.Imaging.EncoderParameters(1)
$enc.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]78)

$src = [System.Drawing.Image]::FromFile($png)
$bandHeight = [int][Math]::Ceiling($src.Height / $Bands)
$scale = [Math]::Min(1.0, $BandWidth / $src.Width)

for ($i = 0; $i -lt $Bands; $i++) {
  $y = $i * $bandHeight
  $h = [Math]::Min($bandHeight, $src.Height - $y)
  if ($h -le 0) { break }
  $w = [int]($src.Width * $scale)
  $hh = [int]($h * $scale)
  $bmp = New-Object System.Drawing.Bitmap($w, $hh)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $w, $hh)), (New-Object System.Drawing.Rectangle(0, $y, $src.Width, $h)), [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $file = Join-Path $Review ("{0}_b{1}.jpg" -f $slug, ($i + 1))
  $bmp.Save($file, $jpeg, $enc)
  $bmp.Dispose()
  Write-Host "band: $file"
}
$enc.Dispose()
$src.Dispose()
Write-Host "full: $png ($([Math]::Round((Get-Item $png).Length / 1KB)) kB)"
