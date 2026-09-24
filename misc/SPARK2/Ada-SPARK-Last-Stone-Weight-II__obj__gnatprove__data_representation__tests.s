	.file	"tests.adb"
	.text
	.section	.rodata
.LC4:
	.ascii	"tests.adb:5"
.LC5:
	.ascii	"tests.adb:6"
.LC6:
	.ascii	"tests.adb:7"
	.align 16
.LC0:
	.long	2
	.long	7
	.long	4
	.long	1
	.long	8
	.long	1
	.align 8
.LC1:
	.long	1
	.long	11
	.align 16
.LC2:
	.long	10
	.long	9
	.long	8
	.long	7
	.long	6
	.long	5
	.align 16
.LC3:
	.long	0
	.long	0
	.long	0
	.long	0
	.long	0
	.long	0
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
	subq	$16, %rsp
	.cfi_offset 15, -24
	.cfi_offset 14, -32
	.cfi_offset 13, -40
	.cfi_offset 12, -48
	leaq	.LC0(%rip), %rax
	movq	%rax, %rdi
	call	last_stone_weight_ii__min_remaining_weight@PLT
	cmpq	$1, %rax
	je	.L2
	leaq	.LC4(%rip), %rax
	movq	%rax, -48(%rbp)
	leaq	.LC1(%rip), %rax
	movq	%rax, -40(%rbp)
	movq	-48(%rbp), %rsi
	movq	-40(%rbp), %rdi
	movq	%rsi, %rdx
	movq	%rdi, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L2:
	leaq	.LC2(%rip), %rax
	movq	%rax, %rdi
	call	last_stone_weight_ii__min_remaining_weight@PLT
	cmpq	$1, %rax
	je	.L3
	leaq	.LC5(%rip), %r14
	leaq	.LC1(%rip), %r15
	movq	%r14, %rdx
	movq	%r15, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L3:
	leaq	.LC3(%rip), %rax
	movq	%rax, %rdi
	call	last_stone_weight_ii__min_remaining_weight@PLT
	testq	%rax, %rax
	je	.L5
	leaq	.LC6(%rip), %r12
	leaq	.LC1(%rip), %r13
	movq	%r12, %rdx
	movq	%r13, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L5:
	nop
	addq	$16, %rsp
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
