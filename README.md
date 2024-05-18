# [DEMO] Building executable for *Raspberry Pi* Zero/1B/1B+ using `gcc-arm-linux-gnueabihf` cross compiler

This is demonstration of compiling executable for *Raspberry Pi* *Zero*/*1B*/*1B+* using *standard* `gcc-arm-linux-gnueabihf` cross-compiler on Debian or Ubuntu. No additional toolchains are required.

> [!IMPORTANT]
> This demo is intended to use in *dockerized* environment. In *VS Code* just reopen this repo in container. `devcontainer.json` is provided.

As a bonus this code also show you how to use external `arm-none-linux-gnueabihf` cross-compiler from [ARM GNU Toolchain](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain).

## Background

Thoretically if you want to build executable or schared library for *Raspberry Pi* you can use *standard* `arm-linux-gnueabihf-gcc` cross-compiler from *Debian* or *Ubuntu*. Just proper compilation flags should be specified. You can use flags described [here](https://gist.github.com/fm4dd/c663217935dc17f0fc73c9c81b0aa845):

```sh
arm-linux-gnueabihf-gcc -mcpu=arm1176jzf-s -mfloat-abi=hard -mfpu=vfp -o hello-world hello-world.c
```

but compiler generates error:

```sh
hello-world.c: In function ‘main’:
hello-world.c:3:6: sorry, unimplemented: Thumb-1 hard-float VFP ABI
    3 | void main()
      |      ^~~~
```

This issue can be easly fixed just by adding `-marm` option (`-mthumb` is a default in modern compilers):

```sh
arm-linux-gnueabihf-gcc -marm -mcpu=arm1176jzf-s -mfloat-abi=hard -mfpu=vfp -o hello-world hello-world.c
```

Now executable gets created but if you try to run it on **real hardware** application just segfaults:

```sh
./main
Segmentation fault
```

Now things gets complicated. Let's examine generated binary a bit:

```sh
$ arm-linux-gnueabihf-readelf -A hello-world
Attribute Section: aeabi
File Attributes
  Tag_CPU_name: "7-A"
  Tag_CPU_arch: v7
  Tag_CPU_arch_profile: Application
  Tag_ARM_ISA_use: Yes
  Tag_THUMB_ISA_use: Thumb-2
  Tag_FP_arch: VFPv3-D16
  Tag_ABI_PCS_wchar_t: 4
  Tag_ABI_FP_rounding: Needed
  Tag_ABI_FP_denormal: Needed
  Tag_ABI_FP_exceptions: Needed
  Tag_ABI_FP_number_model: IEEE 754
  Tag_ABI_align_needed: 8-byte
  Tag_ABI_align_preserved: 8-byte, except leaf SP
  Tag_ABI_enum_size: int
  Tag_ABI_VFP_args: VFP registers
  Tag_CPU_unaligned_access: v6
  Tag_Virtualization_use: TrustZone
```

and below is output of similar command executed on *Raspberry Pi OS* (*Raspbian*):

```sh
pi@raspberrypi:~ $ readelf -A /bin/bash
Attribute Section: aeabi
File Attributes
  Tag_CPU_name: "6"
  Tag_CPU_arch: v6
  Tag_ARM_ISA_use: Yes
  Tag_THUMB_ISA_use: Thumb-1
  Tag_FP_arch: VFPv2
  Tag_ABI_PCS_wchar_t: 4
  Tag_ABI_FP_rounding: Needed
  Tag_ABI_FP_denormal: Needed
  Tag_ABI_FP_exceptions: Needed
  Tag_ABI_FP_number_model: IEEE 754
  Tag_ABI_align_needed: 8-byte
  Tag_ABI_align_preserved: 8-byte, except leaf SP
  Tag_ABI_enum_size: int
  Tag_ABI_VFP_args: VFP registers
  Tag_CPU_unaligned_access: v6

```

The core difference is `Tag_CPU_arch`. `v6` is an expected value. So binary was created for wrong CPU architecture. Generated code works fine on newer models of *Raspberry Pi* but it is incompatible with *RPi Zero/1B/1B+* models with older CPU (SoC).

This demo code demostrates how to build binary with proper CPU architecture. In general you have to:

* prepare *sysroot* from *Raspberry Pi OS*,
* fix so-called *startfiles*.

More information you can find on [Wiki pages](//github.com/RoEdAl/rpi0-cross-compile/wiki) of this project.
