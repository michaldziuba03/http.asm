# http.asm

Simple HTTP server written in assembly for x86_64 architecture and Linux.

This repository contains two versions `main.asm` is non-blocking server with epoll, `basic.asm` is simple blocking server.

## Running

Build script assumes you run it from project root dir.

```sh
chmod +x build.sh
./build.sh run
# if you just want to build:
./build.sh
```

## License

Distributed under the MIT License. See `LICENSE` for more information.
