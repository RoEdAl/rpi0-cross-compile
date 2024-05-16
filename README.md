# [DEMO] Building executable for *Raspberry Pi* Zero/1B/1B+ using `gcc-arm-linux-gnueabihf` cross compiler

This is demonstration of compiling executable for *Raspberry Pi* *Zero*/*1B*/*1B+* using *standard* `gcc-arm-linux-gnueabihf` cross-compiler on Debian or Ubuntu. No additional tollchains are required.

> [!IMPORTANT]
> This demo is intended to use in *dockerized* environment. In *VS Code* just reopen this repo in container. `devcontainer.json` is provided.

## Background

Thoretically if you want to build executable or schared library for *Raspberry Pi* you can use *standard* `arm-linux-gnueabihf-gcc` cross-compiler from *Debian* or *Ubuntu*. Just proper compilation flags should be specified. You can use flags described [here](https://gist.github.com/fm4dd/c663217935dc17f0fc73c9c81b0aa845):

```sh
arm-linux-gnueabihf-gcc -mcpu=arm1176jzf-s -mfloat-abi=hard -mfpu=vfp -o main main.c
```

but compiler generates error:

```sh
main.c: In function ‘main’:
main.c:11:5: sorry, unimplemented: Thumb-1 ‘hard-float’ VFP ABI
```

This issue can be easly fixed just by adding `-marm` option:

```sh
arm-linux-gnueabihf-gcc -marm -mcpu=arm1176jzf-s -mfloat-abi=hard -mfpu=vfp -o main main.c
```

Now executable gets created but if you try to run it on **real hardware** application just segfaults:

```sh
./main
Segmentation fault
```

Now things gets complicated. Let's examine generated binary a bit:

```sh
$ readelf -A main
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
```

and this is output of similar command executed on *Raspberry Pi OS* (*Raspbian*):

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

The core difference is `Tag_CPU_arch`. `v6` is an expected value. So binary is creaded for wrong CPU architecture. Generated code works fine on newer models of *Raspberry Pi* but is incompatible with *RPi Zero/1B/1B+* models with older CPU (SoC).

This demo code demostrates how to build binary with proper CPU architecture. In general you have to:

* prepare SYSROOT from *Raspberry Pi OS*,
* fix so-called *startup* objects.

More information you can find on Wiki pages of this project.
