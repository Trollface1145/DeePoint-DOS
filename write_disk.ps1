$dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $dir

$imgPath = Join-Path $dir "test_floppy.img"
$bootPath = Join-Path $dir "boot.bin"
$kernelPath = Join-Path $dir "kernel.bin"
$guessPath = Join-Path $dir "guess.bin"
$rpsPath = Join-Path $dir "rps.bin"

Write-Host "Building floppy image..."

# 创建 1.44MB 的空白字节数组（全部为 0）
$floppy = New-Object byte[] 1474560

# 1. 复制引导扇区到偏移 0
$bootBytes = [System.IO.File]::ReadAllBytes($bootPath)
[Array]::Copy($bootBytes, 0, $floppy, 0, $bootBytes.Length)
Write-Host "MBR written to LBA 0"

# 2. 复制内核到偏移 512 (LBA 1)
$kernelBytes = [System.IO.File]::ReadAllBytes($kernelPath)
[Array]::Copy($kernelBytes, 0, $floppy, 512, $kernelBytes.Length)
Write-Host "Kernel written to LBA 1"

# 3. 复制猜数字游戏到偏移 10240 (LBA 20)
$guessBytes = [System.IO.File]::ReadAllBytes($guessPath)
[Array]::Copy($guessBytes, 0, $floppy, 10240, $guessBytes.Length)
Write-Host "Guess game written to LBA 20"

# 4. 复制石头剪刀布到偏移 12288 (LBA 24)
$rpsBytes = [System.IO.File]::ReadAllBytes($rpsPath)
[Array]::Copy($rpsBytes, 0, $floppy, 12288, $rpsBytes.Length)
Write-Host "RPS game written to LBA 24"

# 5. 一次性写入磁盘
[System.IO.File]::WriteAllBytes($imgPath, $floppy)
Write-Host "Floppy image built successfully!" -ForegroundColor Green