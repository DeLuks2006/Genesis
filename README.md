<h1 align=center>Genesis</h1>
<p align=center>An ELF Virus Leveraging The PT_NOTE to PT_LOAD Technique.</p>

This is my first ever virus for 64bit Linux ELF binaries. It infects all 
64bit ELF binaries in the current directory (non-recursively) using the 
`PT_NOTE->PTLOAD` technique and displaysa little message as a payload. 
All infected binaries are marked with `GNS` in the ELF header padding.

> [!WARNING]
> Even though it doesn't have a desctructive payload, this is (obviously) 
> a destructive binary, run at your own risk. I am not in any way, shape 
> or form responsible for the damages you cause with this.
>
> That being said, please don't spread this out in the wild. :)

## Build:

Building the project is straight-forward:

```sh
# For standard assembling:
make

# For assembling with debug info:
make debug
```

The resulting binary will be created in `bin/`.

## Demo:

\< demo-video placeholder \>

