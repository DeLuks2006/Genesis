src	:= src
bin	:= bin
target := Genesis
asm := $(src)/$(target).asm
nasm := nasm
aflags := -f elf64
ld := ld

all: $(asm)
	@ echo "[*] Assembling file..."
	@ $(nasm) $(aflags) $(asm) -o $(target).o
	@ mkdir -p $(bin)
	@ echo "[*] Linking..."
	@ $(ld) $(target).o -o $(bin)/$(target)
	@ rm $(target).o
	@ cp test/target_exec bin/target
	@ echo "[*] Placed test-binary into bin/ folder."

debug: $(asm)
	@ echo "[*] Assembling file..."
	@ $(nasm) $(aflags) $(asm) -o $(target).o -g
	@ mkdir -p $(bin)
	@ echo "[*] Linking..."
	@ $(ld) $(target).o -o $(bin)/$(target)
	@ rm $(target).o
	@ cp test/target_exec bin/target
	@ echo "[*] Placed test-binary into bin/ folder."

clean:
	@ echo "[*] Cleaning up..."
	@ rm -rf bin/

