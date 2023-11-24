# A terrible idea: JZFORTH

- A FORTH for ARM Jazelle
  - it will be inspired by jonesforth
- A handcrafted ELF
  - a few pages of ARM code for initialization and opcode handlers
    - a handler for syscall instructions
  - "JVM" code for the static forth dictionary
    - assembled with a jvm assembler
    - implements a runtime forth compiler
    - special functionality to write the current process to a file and to
      undefine words / free memory

## Implementation details

- Syscalls use the impdep1 JVM instruction
  - fe 01  syscall1
    arg0, sysnr -> ret
  - fe 00  syscall0
    sysnr -> ret
- Memory layout
  - Base image
    - ELF header and Program header
      - Forth entry word in `e_ident`
    - ARM initialization code
    - hello world in jvm code
    - basic forth dictionary in jvm code
  - Stack
    - Jazelle handler table
    - Locals table
- JVM locals: important forth state
  - space for temporaries
  - base image start and end
  - return address
  - return stack pointer
- calls
  - call: jsr foo
  - leaf functions
    - prologue: `astore #5` - save RA to local
    - epilogue: `ret #5`
  - functions that call other functions
    - prologue: push RA to return stack
    - epilogue: pop RA from return stack, write to local, `ret`


## Hello world

A _hello world_ in JVM assembly:
(the numbers on the left are the current stack depth)

```
// write the well-known message
0   bipush length

1   load BASE from locals
2   sipush offset of string
3   iadd

2   bipush 1 = stdout

3   iconst_4 = SYS_write

4   syscall3 (fe 03)
1   pop

// exit
0   bipush 42
1   iconst_1 = SYS_exit
2   syscall1 (fe 01)
```


## References

- [Jonesforth](http://git.annexia.org/?p=jonesforth.git;a=blob;f=jonesforth.S;h=45e6e854a5d2a4c3f26af264dfce56379d401425;hb=HEAD) ([GitHub mirror](https://github.com/nornagon/jonesforth))
- [A Whirlwind Tutorial on Creating Really Teensy ELF Executables for Linux](http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html)
