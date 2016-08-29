@echo off

echo Copy boot loader.
partcopy bin\stgone.bin disk_image\vandos.flp 0h 1FFh

imdisk -a -f disk_image\myos.flp -s 1440K -m B:

copy bin\stgtwo.bin b:\

::echo Copy additional files.

imdisk -D -m B:
echo Done