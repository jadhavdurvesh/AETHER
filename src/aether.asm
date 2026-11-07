BITS 64
DEFAULT REL

%define SYS_read 0
%define SYS_write 1
%define SYS_open 2
%define SYS_close 3
%define SYS_exit 60
%define O_RDONLY 0
%define MAX_FILE 16777216
%define ELF_HEADER_SIZE 64
%define PROGRAM_HEADER_SIZE 56

section .data
usage db "AETHER - x86-64 ELF inspector",10,"Usage: aether <elf64-file>",10,0
usage_len equ $-usage
err_open db "aether: cannot open input file",10
err_open_len equ $-err_open
err_read db "aether: failed to read input file",10
err_read_len equ $-err_read
err_too_large db "aether: input exceeds 16 MiB limit",10
err_too_large_len equ $-err_too_large
err_format db "aether: invalid or unsupported ELF64 file",10
err_format_len equ $-err_format
err_bounds db "aether: malformed ELF table bounds",10
err_bounds_len equ $-err_bounds
msg_file db "ELF64 file: "
msg_file_len equ $-msg_file
msg_entry db 10,"Entry point:          0x"
msg_entry_len equ $-msg_entry
msg_phoff db "Program header offset: 0x"
msg_phoff_len equ $-msg_phoff
msg_shoff db "Section header offset: 0x"
msg_shoff_len equ $-msg_shoff
msg_type db "ELF type:              0x"
msg_type_len equ $-msg_type
msg_machine db "Machine:               0x"
msg_machine_len equ $-msg_machine
msg_phnum db "Program headers:       "
msg_phnum_len equ $-msg_phnum
msg_shnum db "Section headers:       "
msg_shnum_len equ $-msg_shnum
msg_segments db 10,"PROGRAM HEADERS",10," idx  type      flags     file-offset       virtual-address   file-size         memory-size",10
msg_segments_len equ $-msg_segments
msg_segment db "  "
msg_segment_len equ $-msg_segment
newline db 10
hex_digits db "0123456789abcdef"
section_msg db 10,"SECTION TABLE",10," idx  name-offset  type      flags             address           offset            size",10
section_msg_len equ $-section_msg
msg_no_ph db "(no program headers)",10
msg_no_ph_len equ $-msg_no_ph
msg_no_sh db "(no section headers)",10
msg_no_sh_len equ $-msg_no_sh

section .bss
file_buffer resb MAX_FILE+1
file_size resq 1
phoff resq 1
shoff resq 1
phentsize resq 1
phnum resq 1
shentsize resq 1
shnum resq 1
hex_buffer resb 17
dec_buffer resb 24
path_ptr resq 1
loop_index resq 1
table_ptr resq 1

section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl .usage
    mov rsi, [rsp+16]
    mov [path_ptr], rsi
    mov rax, SYS_open
    mov rdi, rsi
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    test rax, rax
    js .open_error
    mov r12, rax

    ; Read until EOF: a single read syscall is allowed to return a short
    ; result even when more bytes are available.
    xor r14, r14
.read_more:
    mov rax, SYS_read
    mov rdi, r12
    lea rsi, [file_buffer+r14]
    mov rdx, MAX_FILE
    sub rdx, r14
    test rdx, rdx
    jz .read_limit
    syscall
    test rax, rax
    js .read_error_close
    jz .read_done
    add r14, rax
    jmp .read_more
.read_limit:
    ; Distinguish an exactly-full file from one that exceeds the limit.
    mov rax, SYS_read
    mov rdi, r12
    lea rsi, [file_buffer+MAX_FILE]
    mov rdx, 1
    syscall
    test rax, rax
    js .read_error_close
    test rax, rax
    jnz .too_large_close
.read_done:
    mov rax, SYS_close
    mov rdi, r12
    syscall
    mov r13, r14
    test r13, r13
    jle .read_error
    jmp .after_read
.read_error_close:
    mov rax, SYS_close
    mov rdi, r12
    syscall
    jmp .read_error
.too_large_close:
    mov rax, SYS_close
    mov rdi, r12
    syscall
    mov rsi, err_too_large
    mov rdx, err_too_large_len
    jmp fail_with_code
.after_read:
    cmp r13, ELF_HEADER_SIZE
    jb .format_error
    mov [file_size], r13

    ; ELF identification: magic, 64-bit class, little endian, current version.
    cmp dword [file_buffer], 0x464c457f
    jne .format_error
    cmp byte [file_buffer+4], 2
    jne .format_error
    cmp byte [file_buffer+5], 1
    jne .format_error
    cmp byte [file_buffer+6], 1
    jne .format_error
    cmp dword [file_buffer+20], 1
    jne .format_error
    cmp word [file_buffer+52], ELF_HEADER_SIZE
    jb .format_error
    cmp word [file_buffer+18], 62
    jne .format_error

    mov rax, [file_buffer+32]
    mov [phoff], rax
    mov rax, [file_buffer+40]
    mov [shoff], rax
    movzx rax, word [file_buffer+54]
    mov [phentsize], rax
    movzx rax, word [file_buffer+56]
    mov [phnum], rax
    movzx rax, word [file_buffer+58]
    mov [shentsize], rax
    movzx rax, word [file_buffer+60]
    mov [shnum], rax

    ; Validate table ranges before dereferencing.
    mov rax, [phoff]
    mov rcx, [phnum]
    mov rdx, [phentsize]
    test rcx, rcx
    jz .check_sections
    cmp rax, ELF_HEADER_SIZE
    jb .bounds_error
    cmp rdx, PROGRAM_HEADER_SIZE
    jb .bounds_error
    imul rcx, rdx
    jo .bounds_error
    add rax, rcx
    jc .bounds_error
    cmp rax, [file_size]
    ja .bounds_error

.check_sections:
    mov rax, [shoff]
    mov rcx, [shnum]
    mov rdx, [shentsize]
    test rcx, rcx
    jz .print_report
    cmp rax, ELF_HEADER_SIZE
    jb .bounds_error
    cmp rdx, 64
    jb .bounds_error
    imul rcx, rdx
    jo .bounds_error
    add rax, rcx
    jc .bounds_error
    cmp rax, [file_size]
    ja .bounds_error

.print_report:
    mov rsi, msg_file
    mov rdx, msg_file_len
    call write_stdout
    mov rsi, [path_ptr]
    call write_cstr
    mov rsi, msg_type
    mov rdx, msg_type_len
    call write_stdout
    movzx rax, word [file_buffer+16]
    call print_hex
    call print_nl
    mov rsi, msg_machine
    mov rdx, msg_machine_len
    call write_stdout
    movzx rax, word [file_buffer+18]
    call print_hex
    call print_nl
    mov rsi, msg_entry
    mov rdx, msg_entry_len
    call write_stdout
    mov rax, [file_buffer+24]
    call print_hex
    call print_nl
    mov rsi, msg_phoff
    mov rdx, msg_phoff_len
    call write_stdout
    mov rax, [phoff]
    call print_hex
    call print_nl
    mov rsi, msg_shoff
    mov rdx, msg_shoff_len
    call write_stdout
    mov rax, [shoff]
    call print_hex
    call print_nl
    mov rsi, msg_phnum
    mov rdx, msg_phnum_len
    call write_stdout
    mov rax, [phnum]
    call print_dec
    call print_nl
    mov rsi, msg_shnum
    mov rdx, msg_shnum_len
    call write_stdout
    mov rax, [shnum]
    call print_dec
    call print_nl

    call print_program_headers
    call print_section_headers
    xor rdi, rdi
    jmp exit_process

.usage:
    mov rsi, usage
    mov rdx, usage_len
    jmp fail_with_code
.open_error:
    mov rsi, err_open
    mov rdx, err_open_len
    jmp fail_with_code
.read_error:
    mov rsi, err_read
    mov rdx, err_read_len
    jmp fail_with_code
.format_error:
    mov rsi, err_format
    mov rdx, err_format_len
    jmp fail_with_code
.bounds_error:
    mov rsi, err_bounds
    mov rdx, err_bounds_len
.fail_unused:
    jmp fail_with_code

fail_with_code:
    call write_stderr
    mov rdi, 1
    jmp exit_process

exit_process:
    mov rax, SYS_exit
    syscall

write_stdout:
    mov rax, SYS_write
    mov rdi, 1
    syscall
    ret
write_stderr:
    mov rax, SYS_write
    mov rdi, 2
    syscall
    ret
write_cstr:
    ; RSI points to a zero-terminated string.
    push rsi
    xor rdx, rdx
.count:
    cmp byte [rsi+rdx], 0
    je .emit
    inc rdx
    jmp .count
.emit:
    pop rsi
    jmp write_stdout

print_nl:
    mov rsi, newline
    mov rdx, 1
    jmp write_stdout

; Print RAX as a fixed-width 16-digit hexadecimal number.
print_hex:
    push rbx
    push rcx
    push rdx
    push rsi
    mov rbx, rax
    lea rsi, [hex_buffer+16]
    mov byte [rsi], 0
    mov rcx, 16
.loop:
    dec rsi
    mov rdx, rbx
    and rdx, 15
    mov dl, [hex_digits+rdx]
    mov [rsi], dl
    shr rbx, 4
    loop .loop
    mov rdx, 16
    call write_stdout
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Print unsigned RAX in decimal.
print_dec:
    push rbx
    push rcx
    push rdx
    push rsi
    lea rsi, [dec_buffer+23]
    mov byte [rsi], 0
    mov rbx, 10
    mov rcx, 0
    test rax, rax
    jnz .convert
    dec rsi
    mov byte [rsi], '0'
    inc rcx
    jmp .emit
.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    inc rcx
    test rax, rax
    jnz .convert
.emit:
    mov rdx, rcx
    call write_stdout
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

print_program_headers:
    mov rax, [phnum]
    test rax, rax
    jnz .start
    mov rsi, msg_no_ph
    mov rdx, msg_no_ph_len
    jmp write_stdout
.start:
    mov rsi, msg_segments
    mov rdx, msg_segments_len
    call write_stdout
    mov qword [loop_index], 0
    mov rax, [phoff]
    lea rbx, [file_buffer+rax]
    mov [table_ptr], rbx
.loop:
    mov rax, [loop_index]
    cmp rax, [phnum]
    jae .done
    mov rsi, msg_segment
    mov rdx, msg_segment_len
    call write_stdout
    mov rax, [loop_index]
    call print_dec
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    movzx rax, dword [rbx]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    movzx rax, dword [rbx+4]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov rax, [rbx+8]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov rax, [rbx+16]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov rax, [rbx+32]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov rax, [rbx+40]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rax, [phentsize]
    add [table_ptr], rax
    inc qword [loop_index]
    jmp .loop
.done:
    ret

print_section_headers:
    mov rax, [shnum]
    test rax, rax
    jnz .start
    mov rsi, msg_no_sh
    mov rdx, msg_no_sh_len
    jmp write_stdout
.start:
    mov rsi, section_msg
    mov rdx, section_msg_len
    call write_stdout
    mov qword [loop_index], 0
    mov rax, [shoff]
    lea rbx, [file_buffer+rax]
    mov [table_ptr], rbx
.loop:
    mov rax, [loop_index]
    cmp rax, [shnum]
    jae .done
    mov rbx, [table_ptr]
    mov rax, [loop_index]
    call print_dec
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov eax, [rbx]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov eax, [rbx+4]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov rax, [rbx+8]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov rax, [rbx+16]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov rax, [rbx+24]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rbx, [table_ptr]
    mov rax, [rbx+32]
    call print_hex
    mov rsi, newline
    mov rdx, 1
    call write_stdout
    mov rax, [shentsize]
    add [table_ptr], rax
    inc qword [loop_index]
    jmp .loop
.done:
    ret
