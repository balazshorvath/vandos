@echo off
echo Building bootloader

nasm -O0 -f bin -o bin\boot.bin boot.asm
nasm -O0 -f bin -o bin\stgtwo.bin stgtwo.asm

echo Bootloader is built.
echo Done