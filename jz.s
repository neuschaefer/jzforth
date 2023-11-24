# SPDX-License-Identifier: LGPL-2.1
#
# A minimal Jazelle runtime environment. Not a JVM.
#
# The goal is to get into Jazelle mode as quickly as possible, with as little
# ARM code as possible. Syscalls are handled by the impdep1 instruction handler.

	.equ	BASE, 0x00200000 //  2 MiB
	.equ	SIZE, 0x02000000 // 32 MiB

# The ELF header.
#
# This one is especially inspired by the
# "Whirlwind Tutorial on Creating Really Teensy ELF Executables for Linux"
#  -- http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html

ehdr:
	.byte	0x7f,'E','L','F'	// e_ident
	.byte	1,1			// Type and endianness
	.asciz	"JZ"			// Programm ID or Forth entry word

	.org	16
	.short	2			// e_type = ET_EXEC
	.short	0x28			// e_machine = ARM
	.word	1			// e_version = 1
	.word	_start+BASE		// e_entry = _start
	.word	phdr			// e_phoff = offset of program header
phdr:	.word	1			// e_shoff		// p_type = PT_LOAD
	.word	0			// e_flags		// p_offset
	.word	BASE			// lo:e_ehsize		// p_vaddr = BASE
					// hi:e_phentsize
	.short	1			// e_phnum		// p_paddr
	.short	0			// e_shentsize		// p_paddr
	.word	SIZE			// lo:e_shnum=0		// p_filesz = 32 MiB
					// hi:e_shstridx
	.word	SIZE						// p_memsz
	.word	7						// p_flags = RWX
	.word	0x1000						// p_align


# At offset 64, our ARM code begins.
#
# Special thanks to Hackspire:
#  -- https://hackspire.org/index.php/Jazelle

_start:
# Wait for it....
	mov	r0, #0
	mov	r1, sp
	mov	r2, #1
	mov	r7, #3
	swi	#0


# First, memory.

	sub	sp, #0x440		// allocate space for the handler table
	bic	sp, #0x3fc		// and align to 1024 (0x400)
	mov	r5, sp			// set handler table pointer

	sub	sp, #0x400		// allocate 256 x 32-bit for the JVM stack
	mov	r6, sp			// set JVM stack pointer

	sub	sp, #0x400		// allocate 256 x 32-bit for locals
	mov	r7, sp			// set locals pointer
	mov	r8, sp			// set constants pointer

	mov	r1, #0
loopidoo:
	ldr	r0, =0xbeee000		// install opcode handlers, defaults first
	orr	r0, r1, lsl #2
	str	r0, [r5, r1, lsl #2]
	add	r1, #1
	cmp	r1, #0x108
	bne	loopidoo

	adr	r0, syscall		// install opcode handlers
	str	r0, [r5, #0xfe*4]	// impdep1 = syscall
	#str	r0, [r5, #0xac*4]	// impdep1 = syscall
	#adr	r0, enter_jz
	#str	r0, [r5, #0x410]	// config invalid handler
	#ldr	r0, =0xbead000
	#str	r0, [r5, #0x400]

	mov	r0, #0
	mov	r1, #0
	mov	r2, #0
	mov	r3, #0


# Then, Jazelle entry

enter_jz:
	mrc	p14, 7, r4, c0, c0, 0	// read the ID for good luck
	mov	r0, #1
	mcr	p14, 7, r0, c2, c0, 0	// Set 'Jazelle Enabled' bit

	adr	r12, jz_unavailable
	adr	lr, bytecode
	bxj	r12


# And special case handlers

jz_unavailable:
	mov	r0, #1			// No Jazelle? I'm out.
exit:
	mov	r7, #1
	swi	#0

syscall:
	mov	r0, #2			// Nice try.
	b	exit


# At offset 256, bytecode!

	.org 256
bytecode:
	.byte 0x05, 0x06		// push 2 and 3
	.byte 0x60			// iadd
	.byte 0,0,0,0
	.byte 0xa7, 0xff, 0xfc		// goto loop

	// exit
	.byte 0x10, 42			// 0  bipush 42
	.byte 0, 0, 0
	.byte 0x04			// 1  iconst_1 = SYS_exit
	.byte 0, 0, 0
	.byte 0xa7, 0xff, 0xfc
	.byte 0xac, 1 			// 2  syscall1 (fe 01)
