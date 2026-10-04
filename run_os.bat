@echo off
cd /d "%~dp0"

echo ====================================
echo    DeePoint DOS Build System (Floppy)
echo ====================================
echo.

echo [1/3] Building MBR (boot.asm)...
nasm -f bin boot.asm -o boot.bin
if %errorlevel% neq 0 goto error

echo [2/3] Building Kernel (kernel.asm)...
nasm -f bin kernel.asm -o kernel.bin
if %errorlevel% neq 0 goto error

echo [3/3] Building floppy image...
powershell -ExecutionPolicy Bypass -File "%~dp0write_disk.ps1"
if %errorlevel% neq 0 goto error

echo.
echo Starting QEMU with SeaBIOS + Audio...
"C:\Program Files\qemu\qemu-system-i386.exe" -L "C:\Program Files\qemu\share" -audiodev dsound,id=audio0 -machine pcspk-audiodev=audio0 -drive file=test_floppy.img,format=raw,if=floppy,index=0 -boot order=a

echo.
echo QEMU exited.
pause
exit /b

:error
echo.
echo [ERROR] Build or write failed! Check errors above.
pause