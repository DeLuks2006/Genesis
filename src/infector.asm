;-----------------------------------------------------------------
;                                                    infector.asm
;-----------------------------------------------------------------
; rax 	rdi 	rsi 	rdx 	r10 	r8 	r9
; nasm -f elf64 infector.asm -o infector.o
; ld infector.o -o infector

section .text
global _start
_start:
; open file         ; open(filename, flags, mode)
  mov   rdx, 0x1FF  ; RW* mode
  mov   rsi, 66     ; O_CREAT | O_RDWR flags
  lea   rdi, file   ; filename
  mov   rax, 0x02   ; sys_open
  syscall

  test  rax, rax
  js    exit

  mov   rdi, rax
  push  rax         ; save fd

; get string        ; lseek(fd, offset, whence) (0x08)
  mov   rdx, 0x00   ; seek_set
  mov   rsi, 0x2000 ; offset
  mov   rax, 0x08   ; sys_lseek
  syscall

  test  rax, rax
  js    close

; read file         ; read(fd, buf, count)
  mov   rdx, 0x0d   ; count
  lea   rsi, cntnt  ; buf
  mov   rax, 0x00   ; sys_read
  syscall
  
  test  rax, rax
  js    close

; write file        ; write(fd, buf, size)
  mov   rdx, rax    ; len
  lea   rsi, [rel cntnt]; buf
  mov   rdi, 0x01   ; fd
  mov   rax, 0x01   ; sys_write
  syscall


close:
  pop   rdi         ; restore fd
  mov   rax, 0x03   ; sys_close
  syscall

exit:
  mov   rdi, 0x00   ; return value
  mov   rax, 0x3c   ; exit
  syscall 

section .bss
cntnt   resb  0x0d

section .data
file  db  "target.elf", 0x00

; TODO:
; - overwrite string with "infected\n\0"
