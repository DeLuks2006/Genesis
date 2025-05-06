%define SYS_READ        0x0000
%define SYS_OPEN        0x0002
%define SYS_CLOSE       0x0003
%define SYS_GETDENTS64  0x00D9
%define SYS_EXIT        0x003c

%define DT_REG          0x0008
%define O_RDONLY        0x0000
%define O_RDWR          0x0002

%define ELF_MAGIC       0x464c457f
%define SZ_DENT         0x0100

; WRAPPERS -------------------------------------------------------------------
%macro Open 3           ; open(filename, flags)
  mov   rdi, %1         ; 1st arg: filename pointer
  mov   rsi, %2         ; 2nd arg: flags
  mov   rdx, %3         ; 3rd arg: mode
  mov   rax, SYS_OPEN   ; syscall number
  syscall
%endmacro

%macro Read 3
  mov   rdi, %1         ; fd
  mov   rsi, %2         ; buf
  mov   rdx, %3         ; count
  mov   rax, SYS_READ
  syscall
%endmacro

%macro GetDents64 3
  mov   rdi,  %1        ; 1st arg: fd of directory
  mov   rsi,  %2        ; 2nd arg: out buffer
  mov   rdx,  %3        ; 3rd arg: sizeof buffer
  mov   rax,  SYS_GETDENTS64
  syscall
%endmacro

%macro Close 1
  mov   rdi, %1         ; 1st arg: fd
  mov   rax, SYS_CLOSE  ; close(fd)
  syscall
%endmacro

%macro Exit 1
  mov   rdi,  %1        ; Return value = 0
  mov   rax,  SYS_EXIT  ; sys_exit
  syscall
%endmacro
