@echo off
cd /d "%~dp0"

echo ====================================
echo    DeePoint DOS Build System (Modular)
echo ====================================
echo.

echo [1/6] Building MBR (boot.asm)...
nasm -f bin boot.asm -o boot.bin
if %errorlevel% neq 0 goto error

echo [2/6] Building Kernel (kernel.asm)...
nasm -f bin -O2 kernel.asm -o kernel.bin
if %errorlevel% neq 0 goto error

echo [3/6] Building Guess Game (guess.asm)...
nasm -f bin -O2 guess.asm -o guess.bin
if %errorlevel% neq 0 goto error

echo [4/6] Building RPS Game (rps.asm)...
nasm -f bin -O2 rps.asm -o rps.bin
if %errorlevel% neq 0 goto error

echo [5/6] Building Snake Game (snake.asm)...
nasm -f bin -O2 -w-ignore-label-redef-late snake.asm -o snake.bin
if %errorlevel% neq 0 goto error

echo [6/6] Building floppy image...
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