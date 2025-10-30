<h1 align=center>Genesis</h1>
<p align=center>An ELF Virus Leveraging The PT_NOTE to PT_LOAD Technique.</p>

This is my first ever virus for 64bit Linux ELF binaries. It infects all 
64bit ELF binaries in the current directory (non-recursively) using the 
`PT_NOTE->PT_LOAD` technique and displays a little message as a payload. 
All infected binaries are marked with `GNS` in the ELF header padding.

> [!WARNING]
> Even though it doesn't have a destructive payload, this is (obviously) 
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

## Project Structure:

The project is structured in the following way:

```txt
.
├── Makefile
├── README.md       <-- You are here :)
├── src
│   ├── Genesis.asm <-- The actual Virus Source
│   ├── Macros.asm  <-- Helper Macros
│   └── Structs.asm <-- Struct definitions
└── test
    └── target      <-- 'Hello World' Bin for Testing Purposes
```

## Possible Improvements:

Due to the virus being a quick little side project, I made it pretty stupid so
there is a lot to improve. For one, the payload, or the whole virus, could be 
encrypted and then decrypted at runtime. One could also find a better way to 
watermark the infected files instead of overwriting the ELF header padding.
Additionally the file-enumeration logic could be rewritten to recurse into 
directories. Finally instead of overwriting the `e_entry` value, one could patch 
`cxa_finalize`.

Further Ideas:

- Mutation engine via basic block shuffling
- Encryption via simple XOR
- Compression using the ZX0 algorithm (decompress backwards to save memory)

