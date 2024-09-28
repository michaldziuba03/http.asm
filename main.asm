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
  epoll_fd dd 0
  conn_log db "Got connection", 0x0A
  conn_log_size equ $-conn_log
  alive db "ALIVE", 0x0A
  alive_size equ $-alive

section .text
  global _start

AF_INET equ 2
SOCK_STREAM equ 1
INADDR_ANY equ 0x00000000
SOL_SOCKET equ 1
SO_REUSEADDR equ 2

EXIT_FAILURE equ 1
EXIT_SUCCESS equ 0

STDOUT equ 1
STDIN equ 0

F_GETFL equ 3
F_SETFL equ 4
O_NONBLOCK equ 0x800

MAX_EVENTS equ 512
EPOLL_CTL_ADD equ 1
EPOLLIN equ 0x001
EPOLLOUT equ 0x004
EPOLLHUP equ 0x010
EPOLLRDHUP equ 0x2000
EPOLLERR equ 0x008
EPOLLET equ -0x80000000

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

%macro fncall4 5
  mov rdi, %2
  mov rsi, %3
  mov rdx, %4
  mov r10, %5
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

; syscalls
read:
  mov rax, 0
  syscall
  ret

write:
  mov rax, 1
  syscall
  ret

alivez:
  fncall3 write, STDOUT, alive, alive_size
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

fcntl:
  mov rax, 72
  syscall
  ret

epoll_create1:
  mov rax, 291
  syscall
  ret

epoll_wait:
  mov rax, 232
  syscall
  ret

epoll_ctl:
  mov rax, 233
  syscall
  ret


; (port << 8) | (port >> 8)
htons:
  mov ax, [port]
  mov di, ax
  shr di, 8
  shl ax, 8
  or ax, di
  ret

die:
  fncall3 write, STDOUT, failure, failure_size
  fncall exit, EXIT_FAILURE

set_nonblocking:
  mov r9, rdi

  fncall3 fcntl, r9, F_GETFL, 0
  cmp rax, -1
  je die

  or eax, O_NONBLOCK
  fncall3 fcntl, r9, F_SETFL, rax
  cmp rax, -1
  je die
  ret

handle_accept:
  sub rsp, 24 ; alloc 16 bytes for address and 8 bytes for pointer to size
  mov rax, 16
  mov qword [rsp+16], rax
  lea rdx, [rsp+16]

  fncall3 accept, [server_fd], rsp, rdx
  cmp eax, -1
  je die
  add rsp, 24

  mov r9, rax
  ; make accepted socket nonblocking
  fncall set_nonblocking, r9

  sub rsp, 16
  mov eax, EPOLLIN
  mov dword [rsp], eax
  mov dword [rsp+8], r9d
  fncall4 epoll_ctl, [epoll_fd], EPOLL_CTL_ADD, r9, rsp
  add rsp, 16

  fncall3 write, STDOUT, conn_log, conn_log_size

  jmp finish_poll

handle_request:
  mov r9, rdi
  sub rsp, 1024
  fncall3 read, r9, rsp, 1024
  add rsp, 1024 ; free stack, I do not care about that data

  fncall3 write, r9, res, res_size
  fncall close, r9
  ret

evloop:
  sub rsp, 16 * MAX_EVENTS

  fncall4 epoll_wait, [epoll_fd], rsp, MAX_EVENTS, -1
  cmp eax, 0
  jl die

  mov r15, rax  ; events count
  mov rbx, 0  ; offset
  
poll_loop:
  mov rax, 16
  imul rax, rbx
  
  ; addressing struct
  mov rsi, [rsp+rax+8]
  cmp esi, [server_fd]
  je handle_accept
  fncall handle_request, rsi  ; else pass fd

finish_poll:
  inc rbx
  dec r15
  cmp r15, 0
  jg poll_loop

  add rsp, 16 * MAX_EVENTS

  jmp evloop

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

  fncall set_nonblocking, [server_fd]

  fncall epoll_create1, 0
  cmp eax, 0
  jl die
  mov [epoll_fd], eax

  mov eax, [server_fd]
  sub rsp, 16
  mov dword [rsp], EPOLLIN | EPOLLET
  mov dword [rsp+8], eax

  ; epoll_ctl(epoll_fd, EPOLL_CTL_ADD, server_fd, &ev)
  fncall4 epoll_ctl, [epoll_fd], EPOLL_CTL_ADD, [server_fd], rsp
  cmp eax, 0
  jl die
  add rsp, 16

  call evloop

  fncall close, [server_fd]
  fncall close, [epoll_fd]
  fncall exit, EXIT_SUCCESS
