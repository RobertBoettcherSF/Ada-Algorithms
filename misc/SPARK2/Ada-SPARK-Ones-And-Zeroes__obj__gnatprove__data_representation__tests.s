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
	pushq	%rbx
	subq	$88, %rsp
	.cfi_offset 15, -24
	.cfi_offset 14, -32
	.cfi_offset 13, -40
	.cfi_offset 12, -48
	.cfi_offset 3, -56
	movq	%r10, %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	movq	%rax, %r10
	movq	%r10, %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, %r10
	movq	%r11, %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, %r11
	movq	%r11, %rax
	movl	%eax, %eax
	movq	%rax, %r11
	movq	%rcx, %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, %rcx
	movq	%rcx, %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, %rcx
	movq	%rbx, %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	movq	%rax, %rbx
	movq	%rbx, %rax
	movl	%eax, %edx
	movabsq	$8589934592, %rax
	orq	%rdx, %rax
	movq	%rax, %rbx
	movq	%rcx, %rsi
	movq	%rbx, %rax
	movl	$2, %r9d
	movl	$3, %r8d
	movq	%r10, %rdx
	movq	%r11, %rcx
	movq	%rsi, %rdi
	movq	%rax, %rsi
	call	ones_and_zeroes__max_form@PLT
	cmpl	$3, %eax
	je	.L2
	leaq	.LC1(%rip), %rax
	movq	%rax, -128(%rbp)
	leaq	.LC0(%rip), %rax
	movq	%rax, -120(%rbp)
	movq	-128(%rbp), %rbx
	movq	-120(%rbp), %rsi
	movq	%rbx, %rdx
	movq	%rsi, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L2:
	movq	%r14, %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, %r14
	movq	%r14, %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, %r14
	movq	%r15, %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, %r15
	movq	%r15, %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, %r15
	movq	-80(%rbp), %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, -80(%rbp)
	movq	-80(%rbp), %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, -80(%rbp)
	movq	-72(%rbp), %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, -72(%rbp)
	movq	-72(%rbp), %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, -72(%rbp)
	movq	-80(%rbp), %rax
	movq	-72(%rbp), %rdx
	movq	%rax, %rsi
	movq	%rdx, %rax
	movl	$1, %r9d
	movl	$1, %r8d
	movq	%r14, %rdx
	movq	%r15, %rcx
	movq	%rsi, %rdi
	movq	%rax, %rsi
	call	ones_and_zeroes__max_form@PLT
	cmpl	$1, %eax
	je	.L3
	leaq	.LC2(%rip), %rax
	movq	%rax, -112(%rbp)
	leaq	.LC0(%rip), %rax
	movq	%rax, -104(%rbp)
	movq	-112(%rbp), %rbx
	movq	-104(%rbp), %rsi
	movq	%rbx, %rdx
	movq	%rsi, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L3:
	movq	%r12, %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, %r12
	movq	%r12, %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, %r12
	movq	%r13, %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, %r13
	movq	%r13, %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, %r13
	movq	-64(%rbp), %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, -64(%rbp)
	movq	-64(%rbp), %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, -64(%rbp)
	movq	-56(%rbp), %rdx
	movabsq	$-4294967296, %rax
	andq	%rdx, %rax
	orq	$1, %rax
	movq	%rax, -56(%rbp)
	movq	-56(%rbp), %rax
	movl	%eax, %edx
	movabsq	$4294967296, %rax
	orq	%rdx, %rax
	movq	%rax, -56(%rbp)
	movq	-64(%rbp), %rax
	movq	-56(%rbp), %rdx
	movq	%rax, %rsi
	movq	%rdx, %rax
	movl	$0, %r9d
	movl	$0, %r8d
	movq	%r12, %rdx
	movq	%r13, %rcx
	movq	%rsi, %rdi
	movq	%rax, %rsi
	call	ones_and_zeroes__max_form@PLT
	testl	%eax, %eax
	je	.L5
	leaq	.LC3(%rip), %rax
	movq	%rax, -96(%rbp)
	leaq	.LC0(%rip), %rax
	movq	%rax, -88(%rbp)
	movq	-96(%rbp), %rbx
	movq	-88(%rbp), %rsi
	movq	%rbx, %rdx
	movq	%rsi, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L5:
	nop
	addq	$88, %rsp
	popq	%rbx
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
