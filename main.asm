section .data
  welcome db "HTTP server starting...", 0x0, 0x0A
  welcome_size equ $-welcome
  port dw 5000
  res db "HTTP/1.1 200 OK", 0x0D, 0x0A 
      db "Connection: close", 0x0D, 0x0A
      db "Content-Length: 5", 0x0D, 0x0A
      db 0x0D, 0x0A 
      db "Hello"
  res_size equ $-res
  failure db "Critial error. Exiting...", 0x0, 0X0A
  failure_size equ $-failure
  server_fd dd 0
  conn_log db "Got connection", 0x0A
  conn_log_size equ $-conn_log

section .text
  global _start

; make calling functions easier
%macro fncall 2
  mov rdi, %2
  call %1
%endmacro

%macro fncall2 3
  mov rdi, %2
  mov rsi, %3
  call %1
%endmacro

%macro fncall3 4
  mov rdi, %2
  mov rsi, %3
  mov rdx, %4
  call %1
%endmacro

%macro fncall5 6
  mov rdi, %2
  mov rsi, %3
  mov rdx, %4
  mov r10, %5
  mov r8, %6
  call %1
%endmacro
; end macros

; CONST values
AF_INET equ 2
SOCK_STREAM equ 1
INADDR_ANY equ 0x00000000
SOL_SOCKET equ 1
SO_REUSEADDR equ 2
EXIT_FAILURE equ 1
EXIT_SUCCESS equ 0
STDOUT equ 1
STDIN equ 0
; end CONST values

; syscalls
read:
  mov rax, 0
  syscall
  ret

write:
  mov rax, 1
  syscall
  ret

close:
  mov rax, 3
  syscall
  ret

exit:
  mov rax, 60
  syscall
  ret

socket:
  mov rax, 41
  syscall
  ret

setsockopt:
  mov rax, 54
  syscall
  ret

bind:
  mov rax, 49
  syscall
  ret

listen:
  mov rax, 50
  syscall
  ret

accept:
  mov rax, 43
  syscall
  ret

; util functions
die:
  fncall3 write, STDOUT, failure, failure_size
  fncall exit, EXIT_FAILURE

; (port << 8) | (port >> 8)
htons:
  mov ax, [port]
  mov di, ax
  shr di, 8
  shl ax, 8
  or ax, di
  ret

; handle each connection
listener:
  sub rsp, 24 ; alloc 16 bytes for address and 8 bytes for pointer to size
  mov rax, 16
  mov qword [rsp+16], rax
  lea rdx, [rsp+16]
  ; accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen);
  fncall3 accept, [server_fd], rsp, rdx
  cmp eax, 0
  jl die

  add rsp, 24 ; free stack
  mov rdi, rax ; save accepted socket descriptor

  sub rsp, 1024
  fncall3 read, rdi, rsp, 1024
  add rsp, 1024 ; free stack, I do not care about data

  fncall3 write, rdi, res, res_size
  fncall close, rdi

  fncall3 write, STDOUT, conn_log, conn_log_size

  jmp listener


_start:
  fncall3 write, STDOUT, welcome, welcome_size
  ; create server socket
  fncall3 socket, AF_INET, SOCK_STREAM, 0
  cmp eax, 0
  je die
  mov [server_fd], eax

  sub rsp, 4
  mov dword [rsp], 1
  fncall5 setsockopt, [server_fd], SOL_SOCKET, SO_REUSEADDR, rsp, 4
  cmp eax, 0
  jl die
  add rsp, 4

  ; prepare sockaddr_in (sizeof == 16) on the stack
  sub rsp, 16
  mov word [rsp], AF_INET
  call htons
  mov word [rsp+2], ax
  mov dword [rsp+4], INADDR_ANY
  mov qword [rsp+8], 0

  ; bind socket to address 
  fncall3 bind, [server_fd], rsp, 16
  cmp eax, 0
  jl die

  add rsp, 16 ; free stack

  fncall2 listen, [server_fd], 10
  cmp eax, 0
  jl die

  jmp listener
