mkdir -p build && 
nasm -f elf64 main.asm -o build/main.o && 
ld build/main.o -o build/main && 
./build/main
