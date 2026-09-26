# Create VMware-compatible bootable ISO
param(
    [string]$BootImg = "d:\NewX\OS\Try 2\os\build\nova-os.img",
    [string]$IsoPath = "d:\NewX\OS\Try 2\os\build\nova-os-new.iso"
)

$sectorSize = 2048
$bootCatalogSector = 18
$bootImageSector = 20
$rootDirSector = 19
$totalSectors = 21

$bootData = [System.IO.File]::ReadAllBytes($BootImg)
if ($bootData.Length -ne 512) { Write-Host "Error: boot image must be 512 bytes"; exit 1 }
if ($bootData[510] -ne 0x55 -or $bootData[511] -ne 0xAA) { Write-Host "Error: invalid boot signature"; exit 1 }

$isoData = New-Object byte[] ($totalSectors * $sectorSize)

function Write-Str {
    param($buf, $off, $str, $len)
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($str)
    $copyLen = [Math]::Min($bytes.Length, $len)
    [Array]::Copy($bytes, 0, $buf, $off, $copyLen)
    for ($i = $copyLen; $i -lt $len; $i++) { $buf[$off + $i] = 0x20 }
}

function To-Bcd { param($n); return (($n / 10) -shl 4) -bor ($n % 10) }

function Write-Datetime {
    param($buf, $off)
    $buf[$off]   = To-Bcd 20
    $buf[$off+1] = To-Bcd 26
    $buf[$off+2] = To-Bcd 8
    $buf[$off+3] = To-Bcd 25
    $buf[$off+16] = 0
}

function Pack-LE16 { param($buf, $off, $val); $buf[$off] = $val -band 0xFF; $buf[$off+1] = ($val -shr 8) -band 0xFF }
function Pack-BE16 { param($buf, $off, $val); $buf[$off+1] = $val -band 0xFF; $buf[$off] = ($val -shr 8) -band 0xFF }
function Pack-LE32 { param($buf, $off, $val); Pack-LE16 $buf $off ($val -band 0xFFFF); Pack-LE16 $buf ($off+2) (($val -shr 16) -band 0xFFFF) }
function Pack-BE32 { param($buf, $off, $val); Pack-BE16 $buf ($off+2) ($val -band 0xFFFF); Pack-BE16 $buf $off (($val -shr 16) -band 0xFFFF) }

# === Primary Volume Descriptor (Sector 16) ===
$pvdOff = 16 * $sectorSize
$isoData[$pvdOff] = 0x01
[System.Text.Encoding]::ASCII.GetBytes("CD001") | ForEach-Object { $i = 0 } { $isoData[$pvdOff + 1 + $i] = $_; $i++ }
$isoData[$pvdOff + 6] = 0x01

Write-Str $isoData ($pvdOff + 8) "NOVA-OS" 32
Write-Str $isoData ($pvdOff + 40) "NOVA-OS" 32

Pack-LE32 $isoData ($pvdOff + 80) $totalSectors
Pack-BE32 $isoData ($pvdOff + 84) $totalSectors
Pack-LE16 $isoData ($pvdOff + 128) 1
Pack-BE16 $isoData ($pvdOff + 130) 1
Pack-LE16 $isoData ($pvdOff + 132) 1
Pack-BE16 $isoData ($pvdOff + 134) 1
Pack-LE16 $isoData ($pvdOff + 136) $sectorSize
Pack-BE16 $isoData ($pvdOff + 138) $sectorSize
Pack-LE32 $isoData ($pvdOff + 140) 0
Pack-BE32 $isoData ($pvdOff + 144) 0

# Root directory record
$rrOff = $pvdOff + 156
$isoData[$rrOff] = 34
$isoData[$rrOff + 1] = 0
Pack-LE32 $isoData ($rrOff + 2) $rootDirSector
Pack-BE32 $isoData ($rrOff + 6) $rootDirSector
Pack-LE32 $isoData ($rrOff + 10) 0
Pack-BE32 $isoData ($rrOff + 14) 0
Write-Datetime $isoData ($rrOff + 18)
Write-Datetime $isoData ($rrOff + 25)
$isoData[$rrOff + 32] = 0x02
Pack-LE16 $isoData ($rrOff + 28) 1
Pack-BE16 $isoData ($rrOff + 30) 1
$isoData[$rrOff + 33] = 0x00

Write-Str $isoData ($pvdOff + 190) "NOVA-OS" 128
Write-Str $isoData ($pvdOff + 318) "NOVA-OS" 128
Write-Str $isoData ($pvdOff + 446) "NOVA-OS" 128
Write-Str $isoData ($pvdOff + 574) "NOVA-OS" 128

Write-Datetime $isoData ($pvdOff + 813)
Write-Datetime $isoData ($pvdOff + 830)
Write-Datetime $isoData ($pvdOff + 847)
Write-Datetime $isoData ($pvdOff + 864)
$isoData[$pvdOff + 881] = 0x01

# === Boot Record (Sector 17) ===
$brOff = 17 * $sectorSize
$isoData[$brOff] = 0x00
[System.Text.Encoding]::ASCII.GetBytes("CD001") | ForEach-Object { $i = 0 } { $isoData[$brOff + 1 + $i] = $_; $i++ }
$isoData[$brOff + 6] = 0x01
Write-Str $isoData ($brOff + 7) "EL TORITO SPECIFICATION" 23
Pack-LE32 $isoData ($brOff + 71) $bootCatalogSector

# === Boot Catalog (Sector 18) ===
$catOff = 18 * $sectorSize
$isoData[$catOff] = 0x01
$isoData[$catOff + 1] = 0x00
Write-Str $isoData ($catOff + 4) "NOVA-OS" 24

# Checksum
$checksum = 0
for ($i = 0; $i -lt 32; $i += 2) {
    $checksum += $isoData[$catOff + $i] + ($isoData[$catOff + $i + 1] -shl 8)
}
$checksum = (-$checksum) -band 0xFFFF
Pack-LE16 $isoData ($catOff + 28) $checksum
$isoData[$catOff + 30] = 0x55
$isoData[$catOff + 31] = 0xAA

# Boot entry - No emulation
$isoData[$catOff + 32] = 0x88
$isoData[$catOff + 33] = 0x00
Pack-LE16 $isoData ($catOff + 34) 0x0000
$isoData[$catOff + 38] = 0x01
$isoData[$catOff + 39] = 0x00
Pack-LE32 $isoData ($catOff + 40) $bootImageSector

# === Root Directory (Sector 19) ===
$rdOff = 19 * $sectorSize
# '.' entry
$isoData[$rdOff] = 34
Pack-LE32 $isoData ($rdOff + 2) $rootDirSector
Pack-LE32 $isoData ($rdOff + 10) 0
$isoData[$rdOff + 25] = 0x02
Pack-LE16 $isoData ($rdOff + 28) 1
$isoData[$rdOff + 32] = 1
$isoData[$rdOff + 33] = 0x00
# '..' entry
$isoData[$rdOff + 34] = 34
Pack-LE32 $isoData ($rdOff + 36) $rootDirSector
Pack-LE32 $isoData ($rdOff + 44) 0
$isoData[$rdOff + 59] = 0x02
Pack-LE16 $isoData ($rdOff + 62) 1
$isoData[$rdOff + 66] = 1
$isoData[$rdOff + 67] = 0x00

# === Boot Image (Sector 20) ===
$biOff = 20 * $sectorSize
[Array]::Copy($bootData, 0, $isoData, $biOff, 512)

# Write ISO
[System.IO.File]::WriteAllBytes($IsoPath, $isoData)
Write-Host "[OK] Created: $IsoPath"
Write-Host "     Size: $($isoData.Length) bytes"