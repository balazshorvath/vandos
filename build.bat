@echo off
echo Building bootloader

nasm -O0 -f bin -o bin\stgone.bin bootloader\stgone.asm
nasm -O0 -f bin -o bin\stgtwo.bin bootloader\stgtwo.asm

echo Bootloader is built.
echo Done