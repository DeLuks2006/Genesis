<h1 align=center>Genesis</h1>
<p align=center>An ELF Virus Leveraging The PT_NOTE to PT_LOAD Technique.</p>

## How it should probably work
1. save old entry point
2. overwrite old entry point with EOF
3. append virus (basically this whole procedure + dir traversal with check for ELF files)
4. jmp back to old entry point 

