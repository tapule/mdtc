# MegaDrive Toolchain
A Linux m68k toolchain for MegaDrive development.

## Toolchain
This Makefile will download and build the following packages:
- Binutils 2.43.1
- GCC (m68k-elf) 14.2.0
- GDB 15.1
- SJasm 0.39
- Siktools master branch
- MDTools main branch
- Blastem tip tag (Nightly equivalent)
- Newlib main branch

Packages are pulled from their own mirrors or git repositories:
- https://ftp.gnu.org/gnu
- https://gcc.gnu.org/pub/gcc/infrastructure (GCC, GDB)
- https://sourceware.org/git/newlib-cygwin.git (Newlib)
- https://github.com/konamiman/sjasm
- https://github.com/sikthehedgehog/mdtools
- https://github.com/tapule/mdtools
- https://www.retrodev.com/repos/blastem
- https://github.com/libsdl-org/SDL (Blastem)
- https://github.com/nigels-com/glew (Blastem)

There are some other dependencies needed to build some packages from the toolchain: `gcc, tar, wget, git, mercurial, libasound2-dev, libpulse-dev, libpng-dev`. Please check out your package manager's documentation to install them.

## Building
To build the toolchain run:
- `make`

By default, the toolchain will be built only with C language support, but you can specify other languages by overriding `LANGS` makefile variable:
- `make LANGS=c,c++`

Newlib is not built by default. You can build it with:
- `make with-newlib`

## Installation
To install the toolchain run:
- `make install`

This will compile and install the toolchain by default to `toolchain` directory. You can specify the installation directory by overriding `INSTALL_DIR` makefile variable:
- `make install INSTALL_DIR=/path/to/toolchain`

Maybe you want to add the toolchain's path to your environment PATH:
- `export PATH=$PATH:/path/to/toolchain/bin:/path/to/toolchain/blastem`

## Thanks to...
- [andwn](https://github.com/andwn) for its [Marsdev](https://github.com/andwn/marsdev) toolchain. This toolchain is based on his work.
- [Sik](https://github.com/sikthehedgehog) for his fantastic MegaDrive tools.
- [Mike Pavone's](https://www.retrodev.com/) BlastEm Sega Genesis/Megadrive emulator.
- All the guys in the Spanish Megadrive telegram group. You rock!!

## MIT License
Copyright (c) 2024 Juan Ángel Moreno (@_tapule)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
