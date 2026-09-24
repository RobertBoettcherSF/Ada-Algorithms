	.file	"tests.adb"
	.text
	.section	.rodata
.LC1:
	.ascii	"tests.adb:6"
.LC2:
	.ascii	"tests.adb:7"
.LC3:
	.ascii	"tests.adb:8"
	.align 8
.LC0:
	.long	1
	.long	11
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
	leaq	a.0(%rip), %rax
	movl	$1, %ecx
	movl	$2, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__block_sum@PLT
	cmpq	$36, %rax
	je	.L2
	leaq	.LC1(%rip), %rax
	movq	%rax, -48(%rbp)
	leaq	.LC0(%rip), %rax
	movq	%rax, -40(%rbp)
	movq	-48(%rbp), %rsi
	movq	-40(%rbp), %rdi
	movq	%rsi, %rdx
	movq	%rdi, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L2:
	leaq	a.0(%rip), %rax
	movl	$0, %ecx
	movl	$1, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__block_sum@PLT
	cmpq	$1, %rax
	je	.L3
	leaq	.LC2(%rip), %r14
	leaq	.LC0(%rip), %r15
	movq	%r14, %rdx
	movq	%r15, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L3:
	leaq	a.0(%rip), %rax
	movl	$3, %ecx
	movl	$4, %edx
	movl	$4, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__block_sum@PLT
	cmpq	$73, %rax
	je	.L5
	leaq	.LC3(%rip), %r12
	leaq	.LC0(%rip), %r13
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
	.section	.rodata
	.align 32
	.type	a.0, @object
	.size	a.0, 64
a.0:
	.long	1
	.long	2
	.long	3
	.long	4
	.long	5
	.long	6
	.long	7
	.long	8
	.long	9
	.long	1
	.long	2
	.long	3
	.long	4
	.long	5
	.long	6
	.long	7
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
