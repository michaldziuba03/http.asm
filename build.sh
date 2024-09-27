#!/bin/sh

on_build() {
  if [ "$1" = "run" ]; then
    ./build/main
  else
    echo "Successful build."
  fi
}

mkdir -p build && 
nasm -f elf64 main.asm -o build/main.o && 
ld build/main.o -o build/main &&
on_build "$1"
