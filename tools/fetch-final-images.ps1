# =============================================================================
#  Grip op China / Yu Shan Management - redesign mockup
#  Fetches the final photography at usable resolution into assets\img\
#  Sources: Wikimedia Commons (CC / public domain) + Pexels (free licence).
#  Usage:  powershell -ExecutionPolicy Bypass -File tools\fetch-final-images.ps1
# =============================================================================
param([int]$MaxWidth = 1800, [int]$Quality = 82)

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

$Root = Split-Path -Parent $PSScriptRoot
$Dst  = Join-Path $Root 'assets\img'
New-Item -ItemType Directory -Force -Path $Dst | Out-Null

$Headers = @{ 'Accept' = 'image/jpeg'; 'Referer' = 'https://www.pexels.com/'; 'User-Agent' = 'Mozilla/5.0 (mockup asset fetch)' }

# --- Pexels: photo id -> target file name -----------------------------------
$pexels = @(
  @{ Id = 1181406; Name = 'meeting-room' },
  @{ Id = 1181396; Name = 'meeting-team' },
  @{ Id = 380768;  Name = 'office-open' },
  @{ Id = 2886932; Name = 'greenhouse' },
  @{ Id = 1170979; Name = 'healthcare-clinic' },
  @{ Id = 264636;  Name = 'produce-market' },
  @{ Id = 590022;  Name = 'plan-strategy' }
)

# --- Wikimedia Commons: thumb url -> target file name ------------------------
$commons = @(
  @{ Name = 'hero-hongkong-night';      Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a4/Hong_Kong_Harbour_Night_2019-06-11.jpg/1920px-Hong_Kong_Harbour_Night_2019-06-11.jpg' },
  @{ Name = 'skyline-hongkong-day';     Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/18/Hong_Kong_Night_Skyline.jpg/1920px-Hong_Kong_Night_Skyline.jpg' },
  @{ Name = 'skyline-hongkong-night-2'; Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8d/Hong_Kong_skyscrapers_in_a_night_of_typhoon.jpg/1920px-Hong_Kong_skyscrapers_in_a_night_of_typhoon.jpg' },
  @{ Name = 'skyline-hongkong-icc';     Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/51/International_Commerce_Centre_on_Victoria_Harbour.jpg/1920px-International_Commerce_Centre_on_Victoria_Harbour.jpg' },
  @{ Name = 'skyline-shanghai';         Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/df/Pudong_Shanghai_November_2017_panorama.jpg/1920px-Pudong_Shanghai_November_2017_panorama.jpg' },
  @{ Name = 'boardroom-dialogue';       Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d5/A_boardroom_dialogue_session_at_the_2011_Horasis_Global_Arab_Business_Meeting_%286247249028%29.jpg/1920px-A_boardroom_dialogue_session_at_the_2011_Horasis_Global_Arab_Business_Meeting_%286247249028%29.jpg' },
  @{ Name = 'boardroom-horasis';        Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0a/Horasis_Global_China_Business_Meeting_2013_-_boardroom_panel_%2810865474346%29.jpg/1920px-Horasis_Global_China_Business_Meeting_2013_-_boardroom_panel_%2810865474346%29.jpg' },
  @{ Name = 'port-yangshan';            Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4d/Shanghai-Yangshan-Port-Containers2013-01.JPG/1920px-Shanghai-Yangshan-Port-Containers2013-01.JPG' },
  @{ Name = 'retail-aisle';             Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b9/REMA_1000_rengj%C3%B8ringsmidler_Nylonvask_-_supermarket_interior_aisle_shelves_cleaning_products_-_T%C3%B8nsberg_Norway_2017-11-03_c.jpg/1920px-REMA_1000_rengj%C3%B8ringsmidler_Nylonvask_-_supermarket_interior_aisle_shelves_cleaning_products_-_T%C3%B8nsberg_Norway_2017-11-03_c.jpg' },
  @{ Name = 'steel-inventory';          Url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1b/Factory_steel_coil_inventory.jpg/1920px-Factory_steel_coil_inventory.jpg' }
)

function Get-Image {
  param([string]$Url, [string]$Path)
  try {
    Invoke-WebRequest -Uri $Url -OutFile $Path -TimeoutSec 45 -UseBasicParsing -Headers $Headers
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    # Guard: Pexels may answer with AVIF/WebP despite the .jpeg path
    if ($bytes.Length -lt 5000 -or $bytes[0] -ne 0xFF -or $bytes[1] -ne 0xD8) {
      Remove-Item $Path -Force -ErrorAction SilentlyContinue
      return $false
    }
    return $true
  } catch {
    Remove-Item $Path -Force -ErrorAction SilentlyContinue
    return $false
  }
}

$failed = @()

foreach ($p in $pexels) {
  $file = Join-Path $Dst "$($p.Name).jpg"
  $url  = "https://images.pexels.com/photos/$($p.Id)/pexels-photo-$($p.Id).jpeg?auto=compress&cs=tinysrgb&w=1800"
  if (Get-Image -Url $url -Path $file) { Write-Host "OK   pexels $($p.Id) -> $($p.Name).jpg" }
  else { $failed += "pexels $($p.Id)"; Write-Warning "FAIL pexels $($p.Id)" }
  Start-Sleep -Milliseconds 250
}

foreach ($c in $commons) {
  $file = Join-Path $Dst "$($c.Name).jpg"
  if (Get-Image -Url $c.Url -Path $file) { Write-Host "OK   commons -> $($c.Name).jpg" }
  else { $failed += "commons $($c.Name)"; Write-Warning "FAIL commons $($c.Name)" }
  Start-Sleep -Milliseconds 250
}

# --- JPEG encoder -----------------------------------------------------------
Add-Type -AssemblyName System.Drawing
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)

# --- Wikimedia Commons: locator map (SVG rendered to PNG, flattened) -------
# File:China Hong Kong 4 levels localisation.svg - CC BY-SA 3.0,
# Joowwww / Moddlyg / Pethrus (Wikimedia Commons).
$mapSrc = Join-Path $Dst '_map-source.png'
$mapUrl = 'https://commons.wikimedia.org/wiki/Special:FilePath/China%20Hong%20Kong%204%20levels%20localisation.svg?width=1920'
try {
  Invoke-WebRequest -Uri $mapUrl -OutFile $mapSrc -TimeoutSec 60 -UseBasicParsing `
    -Headers @{ 'Accept' = 'image/png'; 'User-Agent' = 'Mozilla/5.0 (mockup asset fetch)' }
  Add-Type -AssemblyName System.Drawing
  $png = [System.Drawing.Image]::FromFile($mapSrc)
  $flat = New-Object System.Drawing.Bitmap($png.Width, $png.Height)
  $graphics = [System.Drawing.Graphics]::FromImage($flat)
  $graphics.Clear([System.Drawing.Color]::White)
  $graphics.InterpolationMode = 'HighQualityBicubic'
  $graphics.DrawImage($png, 0, 0, $png.Width, $png.Height)
  $graphics.Dispose()
  $png.Dispose()
  $flat.Save((Join-Path $Dst 'hongkong-map.jpg'), $jpeg)
  $flat.Dispose()
  Remove-Item $mapSrc -Force
  Write-Host 'OK   commons -> hongkong-map.jpg'
} catch {
  $failed += 'commons hongkong-map'
  Write-Warning 'FAIL commons hongkong-map'
  Remove-Item $mapSrc -Force -ErrorAction SilentlyContinue
}

# --- Normalise: cap the width and re-encode at a web-friendly quality --------
Get-ChildItem (Join-Path $Dst '*.jpg') | Where-Object { $_.Name -notlike '_src-*' } | ForEach-Object {
  $img = [System.Drawing.Image]::FromFile($_.FullName)
  if ($img.Width -gt $MaxWidth) {
    $h = [int]($img.Height * $MaxWidth / $img.Width)
    $bmp = New-Object System.Drawing.Bitmap($MaxWidth, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.DrawImage($img, 0, 0, $MaxWidth, $h)
    $g.Dispose()
    $img.Dispose()
    $img = $bmp
  }
  $tmp = $_.FullName + '.tmp.jpg'
  $img.Save($tmp, $jpeg, $encParams)
  $img.Dispose()
  Move-Item $tmp $_.FullName -Force
  $final = [System.Drawing.Image]::FromFile($_.FullName)
  Write-Host ("     {0,-30} {1}x{2}  {3:n0} kB" -f $_.Name, $final.Width, $final.Height, ($_.Length / 1KB))
  $final.Dispose()
}
$encParams.Dispose()

if ($failed.Count) { Write-Warning ("Mislukt: " + ($failed -join ', ')) } else { Write-Host "Alle afbeeldingen opgehaald." }
