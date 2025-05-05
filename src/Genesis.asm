;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                   genesis.asm ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nasm -f elf64 genesis.asm -o genesis.o
; ld genesis.o -o genesis

; Note: Because I'm weird I decided to use camelCase for 
;       variables and macros ;)

section .text
global _start
_start:
  ;; SAVE ARGV
  ;; GET FILE
  ;; OPEN + MMAP 
  ;; CHECK IF ELF
    ;; IF YES -> CONTINUE
    ;; ELSE -> EXIT
  ;; CHECK ALREADY INFECTED
    ;; IF NOT -> CONTINUE
    ;; ELSE -> EXIT
  ;; SAVE OLD ENTRY
  ;; LOOP THROUGH PHDR
    ;; IF PH_TYPE -> PT_NOTE THEN BREAK
  ;; CONVERT TO PT_LOAD
  ;; WRITE SELF AT LOCATION
  ;; OVERWRITE ENTRYPOINT
  ;; WRITE OLD ENTRYPOINT AT SELF
  ;; EXEC PAYLOAD (PRINT STDOUT)
  ret
