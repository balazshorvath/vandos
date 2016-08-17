@echo off

echo Copy boot loader.
partcopy bin\boot.bin disk_image\myos.flp 0h 1FFh

echo Copy additional files.
imdisk -a -f disk_image\myos.flp -s 1440K -m B:

copy bin\stgtwo.bin b:\

imdisk -D -m B:
echo Done