<h1 align=center>Genesis</h1>
<p align=center>A simple appending ELF virus written in ASM</p>

## How it should probably work
1. save old entry point
2. overwrite old entry point with EOF
3. append virus (basically this whole procedure + dir traversal with check for ELF files)
4. jmp back to old entry point 

