	.file	"tests.adb"
	.text
	.section	.rodata
.LC1:
	.ascii	"tests.adb:5"
.LC2:
	.ascii	"tests.adb:6"
.LC3:
	.ascii	"tests.adb:7"
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
	movl	$0, %edi
	call	unique_binary_search_trees_ii_lite__root_choices@PLT
	testl	%eax, %eax
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
	movl	$1, %edi
	call	unique_binary_search_trees_ii_lite__root_choices@PLT
	cmpl	$1, %eax
	je	.L3
	leaq	.LC2(%rip), %r14
	leaq	.LC0(%rip), %r15
	movq	%r14, %rdx
	movq	%r15, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L3:
	movl	$16, %edi
	call	unique_binary_search_trees_ii_lite__root_choices@PLT
	cmpl	$16, %eax
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
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
