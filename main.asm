section .data
  welcome db "HTTP server starting...", 0, 10
  welcome_size equ $-welcome 

section .text
  global _start

print_welcome:
  mov rax, 1
  mov rdi, 1
  mov rsi, welcome
  mov rdx, welcome_size
  syscall

exit:
  mov rax, 60
  mov rdi, 0
  syscall

_start:
  call print_welcome
  jmp exit
