$dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $dir

$imgPath = Join-Path $dir "test_floppy.img"
$bootPath = Join-Path $dir "boot.bin"
$kernelPath = Join-Path $dir "kernel.bin"

# 创建 1.44MB 软盘镜像（如果不存在）
if (-not (Test-Path $imgPath)) {
    Write-Host "Creating 1.44MB floppy image..."
    fsutil file createnew $imgPath 1474560 | Out-Null
}

$img = [System.IO.File]::OpenWrite($imgPath)

# 写入 MBR 到偏移 0
$boot = [System.IO.File]::ReadAllBytes($bootPath)
$img.Seek(0, 'Begin') | Out-Null
$img.Write($boot, 0, $boot.Length)
Write-Host "MBR written to LBA 0"

# 写入 Kernel 到偏移 512 (LBA 1)
$kernel = [System.IO.File]::ReadAllBytes($kernelPath)
$img.Seek(512, 'Begin') | Out-Null
$img.Write($kernel, 0, $kernel.Length)
Write-Host "Kernel written to LBA 1"

$img.Close()
Write-Host "Floppy image built successfully!"