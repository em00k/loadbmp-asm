# loadbmp
 Loading a 256 index BMP on the ZX Next

Bitmaps when saved as a 256 index BMP are more often then not stored upside down.
This means to display the file on Layer2 you need to flip the image, or process the
image each time you make a change. 

This example shows you how to load a bmp into L2 while only using a small foot print.

Memory location $2000 - $3fff is used to load the data direct to the Layer 2 banks. 
As the data is stored backwards in a lot of cases the code will load the BMP in 8kb 
chunks and swap chunks of 32 lines from top to bottom resulting in the correct image.

There's no palette quantizing so the BMP needs to have the default Next's uniform
palette without writing additional code to handle the palette data. 

run a.bat to assemble and run with Cspect. 

The image should be 256*192 256 colours indexed. The header and palette is currently skipped
and data from 1078 is used. 

The default layer ram bank is set with reg $12 - this uses a 16kb bank value so it is 
set to 16. When we load in the bitmap data we use 8kb banks so we double this 16 *2 so 
load in from bank 32, which is paged in to MMU slote 1 $2000 - $3fff. 

