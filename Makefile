src	:= src
bin	:= bin
target := Genesis
asm := $(src)/$(target).asm
nasm := nasm
aflags := -f elf64
ld := ld

all: $(asm)
	@echo "[#] Assembling file..."
	$(nasm) $(aflags) $(asm) -o $(target).o
	@mkdir -p $(bin)
	@echo "[#] Linking..."
	$(ld) $(target).o -o $(bin)/$(target)
	rm $(target).o

debug: $(asm)
	@echo "[#] Assembling file..."
	$(nasm) $(aflags) $(asm) -o $(target).o -g
	@mkdir -p $(bin)
	@echo "[#] Linking..."
	$(ld) $(target).o -o $(bin)/$(target)
	rm $(target).o

clean: $(bin)/$(target)
	@echo "[#] Cleaning up..."
	rm -rf bin/

