section .data
  welcome db "HTTP server starting...", 0, 10
  welcome_size equ $-welcome
  port dw 5000
  res db "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: 5\r\n\r\nHello"
  res_size equ $-res
  failure db "Critial error. Exiting...", 0, 10
  failure_size equ $-failure
  server_fd dd 0

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
; end macros

; CONST values
AF_INET equ 2
SOCK_STREAM equ 1
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
  fncall3 write, 1, failure, failure_size
  fncall exit, EXIT_FAILURE

; (port << 8) | (port >> 8)
htons:
  mov ax, [port]
  mov di, ax
  shr di, 8
  shl ax, 8
  or ax, di
  ret

busy_sleep:
  jmp busy_sleep

_start:
  fncall3 write, STDOUT, welcome, welcome_size
  fncall3 socket, AF_INET, SOCK_STREAM, 0
  cmp eax, 0
  je die
  mov [server_fd], eax
  call busy_sleep
  fncall exit, EXIT_SUCCESS
