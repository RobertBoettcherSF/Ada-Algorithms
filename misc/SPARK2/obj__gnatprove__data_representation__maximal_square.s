	.file	"maximal_square.adb"
	.text
	.align 2
	.globl	maximal_square__TmatrixBIP
	.type	maximal_square__TmatrixBIP, @function
maximal_square__TmatrixBIP:
.LFB2:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, %rax
	movq	%rsi, %rcx
	movq	%rax, %rax
	movl	$0, %edx
	movq	%rcx, %rdx
	movq	%rax, -16(%rbp)
	movq	%rdx, -8(%rbp)
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	maximal_square__TmatrixBIP, .-maximal_square__TmatrixBIP
	.section	.rodata
	.align 8
.LC1:
	.ascii	"failed precondition from maximal_square.adb:4"
.LC2:
	.ascii	"maximal_square.adb"
	.zero	1
	.align 8
.LC0:
	.long	1
	.long	45
	.text
	.align 2
	.type	maximal_square__all_2, @function
maximal_square__all_2:
.LFB3:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset 3, -24
	movq	%rdi, -24(%rbp)
	movl	%esi, -28(%rbp)
	movl	%edx, -32(%rbp)
	cmpl	$3, -28(%rbp)
	setg	%dl
	cmpl	$3, -32(%rbp)
	setg	%al
	orl	%edx, %eax
	testb	%al, %al
	je	.L4
	leaq	.LC1(%rip), %rcx
	leaq	.LC0(%rip), %rbx
	movq	%rcx, %rdx
	movq	%rbx, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L4:
	cmpl	$0, -28(%rbp)
	js	.L5
	cmpl	$3, -28(%rbp)
	jle	.L6
.L5:
	leaq	.LC2(%rip), %rax
	movl	$6, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Index_Check@PLT
.L6:
	cmpl	$0, -32(%rbp)
	js	.L7
	cmpl	$3, -32(%rbp)
	jle	.L8
.L7:
	leaq	.LC2(%rip), %rax
	movl	$6, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Index_Check@PLT
.L8:
	cmpl	$0, -28(%rbp)
	js	.L9
	cmpl	$3, -28(%rbp)
	jle	.L10
.L9:
	leaq	.LC2(%rip), %rax
	movl	$6, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Index_Check@PLT
.L10:
	cmpl	$0, -32(%rbp)
	js	.L11
	cmpl	$3, -32(%rbp)
	jle	.L12
.L11:
	leaq	.LC2(%rip), %rax
	movl	$6, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Index_Check@PLT
.L12:
	movl	-28(%rbp), %eax
	movslq	%eax, %rcx
	movl	-32(%rbp), %eax
	movslq	%eax, %rdx
	movq	-24(%rbp), %rax
	subq	$1, %rcx
	salq	$2, %rcx
	addq	%rcx, %rdx
	subq	$1, %rdx
	movl	(%rax,%rdx,4), %eax
	cmpl	$1, %eax
	sete	%sil
	movl	-28(%rbp), %eax
	addl	$1, %eax
	movslq	%eax, %rcx
	movl	-32(%rbp), %eax
	movslq	%eax, %rdx
	movq	-24(%rbp), %rax
	subq	$1, %rcx
	salq	$2, %rcx
	addq	%rcx, %rdx
	subq	$1, %rdx
	movl	(%rax,%rdx,4), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%eax, %esi
	movl	-28(%rbp), %eax
	movslq	%eax, %rcx
	movl	-32(%rbp), %eax
	addl	$1, %eax
	movslq	%eax, %rdx
	movq	-24(%rbp), %rax
	subq	$1, %rcx
	salq	$2, %rcx
	addq	%rcx, %rdx
	subq	$1, %rdx
	movl	(%rax,%rdx,4), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%eax, %esi
	movl	-28(%rbp), %eax
	addl	$1, %eax
	movslq	%eax, %rcx
	movl	-32(%rbp), %eax
	addl	$1, %eax
	movslq	%eax, %rdx
	movq	-24(%rbp), %rax
	subq	$1, %rcx
	salq	$2, %rcx
	addq	%rcx, %rdx
	subq	$1, %rdx
	movl	(%rax,%rdx,4), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%esi, %eax
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	maximal_square__all_2, .-maximal_square__all_2
	.section	.rodata
	.align 8
.LC3:
	.ascii	"failed precondition from maximal_square.adb:9"
	.text
	.align 2
	.type	maximal_square__all_3, @function
maximal_square__all_3:
.LFB4:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset 13, -24
	.cfi_offset 12, -32
	.cfi_offset 3, -40
	movq	%rdi, -40(%rbp)
	movl	%esi, -44(%rbp)
	movl	%edx, -48(%rbp)
	cmpl	$2, -44(%rbp)
	setg	%dl
	cmpl	$2, -48(%rbp)
	setg	%al
	orl	%edx, %eax
	testb	%al, %al
	je	.L15
	leaq	.LC3(%rip), %rcx
	leaq	.LC0(%rip), %rbx
	movq	%rcx, %rdx
	movq	%rbx, %rax
	movq	%rdx, %rdi
	movq	%rax, %rsi
	call	system__assertions__raise_assert_failure@PLT
.L15:
	movl	-44(%rbp), %eax
	leal	1(%rax), %r12d
	testl	%r12d, %r12d
	jle	.L16
	cmpl	$4, %r12d
	jle	.L17
.L16:
	leaq	.LC2(%rip), %rax
	movl	$11, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Range_Check@PLT
.L17:
	movl	-48(%rbp), %eax
	leal	1(%rax), %ebx
	testl	%ebx, %ebx
	jle	.L18
	cmpl	$4, %ebx
	jle	.L19
.L18:
	leaq	.LC2(%rip), %rax
	movl	$11, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Range_Check@PLT
.L19:
	cmpl	$-1, -44(%rbp)
	jl	.L20
	cmpl	$2, -44(%rbp)
	jle	.L21
.L20:
	leaq	.LC2(%rip), %rax
	movl	$11, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Index_Check@PLT
.L21:
	cmpl	$-1, -48(%rbp)
	jl	.L22
	cmpl	$2, -48(%rbp)
	jle	.L23
.L22:
	leaq	.LC2(%rip), %rax
	movl	$11, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Index_Check@PLT
.L23:
	movl	-48(%rbp), %edx
	movl	-44(%rbp), %ecx
	movq	-40(%rbp), %rax
	movl	%ecx, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	movl	%eax, %r13d
	movl	-48(%rbp), %edx
	movq	-40(%rbp), %rax
	movl	%r12d, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	andl	%eax, %r13d
	movl	%r13d, %r12d
	movl	-44(%rbp), %ecx
	movq	-40(%rbp), %rax
	movl	%ebx, %edx
	movl	%ecx, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	movl	%r12d, %esi
	andl	%eax, %esi
	movl	-44(%rbp), %eax
	addl	$2, %eax
	movslq	%eax, %rcx
	movl	-48(%rbp), %eax
	addl	$2, %eax
	movslq	%eax, %rdx
	movq	-40(%rbp), %rax
	subq	$1, %rcx
	salq	$2, %rcx
	addq	%rcx, %rdx
	subq	$1, %rdx
	movl	(%rax,%rdx,4), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%esi, %eax
	addq	$24, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE4:
	.size	maximal_square__all_3, .-maximal_square__all_3
	.align 2
	.type	maximal_square__all_4, @function
maximal_square__all_4:
.LFB5:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	$1, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	maximal_square__all_3
	movl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	12(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	28(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	44(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	48(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	52(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	56(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	60(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	andl	%edx, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE5:
	.size	maximal_square__all_4, .-maximal_square__all_4
	.align 2
	.type	maximal_square__any_1, @function
maximal_square__any_1:
.LFB6:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	cmpl	$1, %eax
	sete	%dl
	movq	-8(%rbp), %rax
	movl	4(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	8(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	12(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	16(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	20(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	24(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	28(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	32(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	36(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	40(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	44(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	48(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	52(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	56(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%eax, %edx
	movq	-8(%rbp), %rax
	movl	60(%rax), %eax
	cmpl	$1, %eax
	sete	%al
	orl	%edx, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE6:
	.size	maximal_square__any_1, .-maximal_square__any_1
	.align 2
	.type	maximal_square__any_2, @function
maximal_square__any_2:
.LFB7:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset 3, -24
	movq	%rdi, -24(%rbp)
	movq	-24(%rbp), %rax
	movl	$1, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	movl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$2, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$3, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$1, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$2, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$3, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$1, %edx
	movl	$3, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$2, %edx
	movl	$3, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$3, %edx
	movl	$3, %esi
	movq	%rax, %rdi
	call	maximal_square__all_2
	orl	%ebx, %eax
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE7:
	.size	maximal_square__any_2, .-maximal_square__any_2
	.align 2
	.globl	maximal_square__largest_side
	.type	maximal_square__largest_side, @function
maximal_square__largest_side:
.LFB8:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset 3, -24
	movq	%rdi, -24(%rbp)
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	maximal_square__all_4
	testb	%al, %al
	je	.L32
	movl	$4, %eax
	jmp	.L33
.L32:
	movq	-24(%rbp), %rax
	movl	$1, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	maximal_square__all_3
	movl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$2, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	maximal_square__all_3
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$1, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	maximal_square__all_3
	orl	%eax, %ebx
	movq	-24(%rbp), %rax
	movl	$2, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	maximal_square__all_3
	orl	%ebx, %eax
	testb	%al, %al
	je	.L34
	movl	$3, %eax
	jmp	.L33
.L34:
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	maximal_square__any_2
	testb	%al, %al
	je	.L35
	movl	$2, %eax
	jmp	.L33
.L35:
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	maximal_square__any_1
	testb	%al, %al
	je	.L36
	movl	$1, %eax
	jmp	.L33
.L36:
	movl	$0, %eax
.L33:
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE8:
	.size	maximal_square__largest_side, .-maximal_square__largest_side
	.globl	maximal_square_E
	.data
	.align 2
	.type	maximal_square_E, @object
	.size	maximal_square_E, 2
maximal_square_E:
	.zero	2
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
