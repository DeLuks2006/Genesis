src	:= src
bin	:= bin
target := infector
asm := $(src)/$(target).asm
nasm := nasm
nflags := -f elf64
ld := ld
debug := -g

all: $(asm)
	@echo "[#] Assembling file..."
	$(nasm) $(nflags) $(asm) -o $(target).o
	@mkdir -p $(bin)
	@echo "[#] Linking..."
	$(ld) $(target).o -o $(bin)/$(target)
	rm $(target).o

debug: $(asm)
	@echo "[#] Assembling file..."
	$(nasm) $(nflags) $(asm) -o $(target).o $(debug)
	@mkdir -p $(bin)
	@echo "[#] Linking..."
	$(ld) $(target).o -o $(bin)/$(target)
	rm $(target).o

clean: $(bin)/$(target)
	@echo "[#] Cleaning up..."
	rm -rf bin/

