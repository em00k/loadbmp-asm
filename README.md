![alt text](https://raw.githubusercontent.com/em00k/loadbmp-asm/master/outputs/9bit-emk.png)

# update 
loadbmp-resample-palette-fade.asm is an updated version that will resample the colours
to the nextpalette RGB999. Input should still be 256*192 256 colours.

This is not the only way to resample colours, there are various methods each with their
own pros and cons. 

verysimplebmp.asm shows how to include a bmp into your NEX file and point L2 at 
that RAM with reg $12 

# loadbmp on the ZX Next : loadbmp-nonfu.asm
 Loading a 256 index BMP on the ZX Next

Bitmaps when saved as a 256 index BMP are more often then not stored upside down.
This means to display the file on Layer2 you need to flip the image, or process the
image each time you make a change. 

This example shows you how to load a bmp into L2 while only using a small footprint.

Memory location $4000 - $5fff is used to load the data direct to the Layer 2 banks. 
As the data is stored backwards in a lot of cases the code will load the BMP in 8kb 
chunks and swap each of the 32 lines from top to bottom resulting in the correct image.

The palette will be remapped if you use loadbmp-resample-palette-fade, loadbmp-nonfu.asm
requires the BMP to already have the Next uniform 256 cokour palatte. 

run a.bat to assemble loadbmp-nonfu.asm and run with Cspect. 
run b.bat to assemble loadbmp-resample-palette-fade.asm and run with Cspect. 
run c.bat to assemble verysimplebmp.asm and run with Cspect. 

The image should be 256*192 256 colours indexed. The header and palette is currently skipped
and data from 1078 is used. 

The default layer ram bank is set with reg $12 - this uses a 16kb bank value and we set this 
to 16. When we load in the bitmap data we use 8kb banks, we double this 16 *2 and load in to bank 32, 
which is paged in to MMU slote 2 $4000 - $5fff. 

I did originally have it work at $2000 $3fff which was ideal as it was well away from any 
other code, however this turned out to only work in CSpect! So had to move it $4000. 

