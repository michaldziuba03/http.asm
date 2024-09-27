section .data
  welcome db "Welcome", 0, 10
  welcome_size equ $-welcome 

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

_start:
  fncall3 write, 1, welcome, welcome_size
  fncall exit, 0
