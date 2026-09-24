	.file	"tests.adb"
	.text
	.section	.rodata
.LC3:
	.ascii	"tests.adb:5"
.LC4:
	.ascii	"tests.adb:6"
	.align 32
.LC0:
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.long	1
	.align 8
.LC1:
	.long	1
	.long	11
	.align 32
.LC2:
	.long	1
	.long	0
	.long	1
	.long	0
	.long	0
	.long	1
	.long	0
	.long	1
	.long	1
	.long	0
	.long	1
	.long	0
	.long	0
	.long	1
	.long	0
	.long	1
	.text
	.align 2
	.globl	_ada_tests
	.type	_ada_tests, @function
_ada_tests:
.LFB1:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	.cfi_offset 15, -24
	.cfi_offset 14, -32
	.cfi_offset 13, -40
	.cfi_offset 12, -48
	leaq	.LC0(%rip), %rax
	movq	%rax, %rdi
	call	count_square_submatrices_with_all_ones__count_squares@PLT
	cmpq	$30, %rax
	je	.L2
	leaq	.LC3(%rip), %r14
	leaq	.LC1(%rip), %r15
	movq	%r14, %rdx
	movq	%r15, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L2:
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	call	count_square_submatrices_with_all_ones__count_squares@PLT
	cmpq	$8, %rax
	je	.L4
	leaq	.LC4(%rip), %r12
	leaq	.LC1(%rip), %r13
	movq	%r12, %rdx
	movq	%r13, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L4:
	nop
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	_ada_tests, .-_ada_tests
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
