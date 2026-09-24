	.file	"num_matrix_block_sum.adb"
	.text
	.align 2
	.globl	num_matrix_block_sum__TmatrixBIP
	.type	num_matrix_block_sum__TmatrixBIP, @function
num_matrix_block_sum__TmatrixBIP:
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
	.size	num_matrix_block_sum__TmatrixBIP, .-num_matrix_block_sum__TmatrixBIP
	.section	.rodata
.LC0:
	.ascii	"num_matrix_block_sum.adb"
	.zero	1
	.text
	.align 2
	.type	num_matrix_block_sum__in_block, @function
num_matrix_block_sum__in_block:
.LFB3:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movl	%edi, -4(%rbp)
	movl	%esi, -8(%rbp)
	movl	%edx, -12(%rbp)
	movl	%ecx, -16(%rbp)
	movl	%r8d, -20(%rbp)
	movl	-4(%rbp), %eax
	cmpl	-12(%rbp), %eax
	jl	.L4
	movl	$0, %edx
	movl	-4(%rbp), %eax
	subl	-12(%rbp), %eax
	jno	.L5
	movl	$1, %edx
.L5:
	movl	%edx, %eax
	testl	%eax, %eax
	je	.L7
	leaq	.LC0(%rip), %rax
	movl	$5, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Overflow_Check@PLT
.L7:
	movl	-4(%rbp), %eax
	subl	-12(%rbp), %eax
	cmpl	-20(%rbp), %eax
	jle	.L10
.L4:
	movl	-12(%rbp), %eax
	cmpl	-4(%rbp), %eax
	jl	.L11
	movl	$0, %edx
	movl	-12(%rbp), %eax
	subl	-4(%rbp), %eax
	jno	.L12
	movl	$1, %edx
.L12:
	movl	%edx, %eax
	testl	%eax, %eax
	je	.L14
	leaq	.LC0(%rip), %rax
	movl	$5, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Overflow_Check@PLT
.L14:
	movl	-12(%rbp), %eax
	subl	-4(%rbp), %eax
	cmpl	-20(%rbp), %eax
	jg	.L11
.L10:
	movl	-8(%rbp), %eax
	cmpl	-16(%rbp), %eax
	jl	.L17
	movl	$0, %edx
	movl	-8(%rbp), %eax
	subl	-16(%rbp), %eax
	jno	.L18
	movl	$1, %edx
.L18:
	movl	%edx, %eax
	testl	%eax, %eax
	je	.L20
	leaq	.LC0(%rip), %rax
	movl	$6, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Overflow_Check@PLT
.L20:
	movl	-8(%rbp), %eax
	subl	-16(%rbp), %eax
	cmpl	-20(%rbp), %eax
	jle	.L23
.L17:
	movl	-16(%rbp), %eax
	cmpl	-8(%rbp), %eax
	jl	.L11
	movl	$0, %edx
	movl	-16(%rbp), %eax
	subl	-8(%rbp), %eax
	jno	.L24
	movl	$1, %edx
.L24:
	movl	%edx, %eax
	testl	%eax, %eax
	je	.L26
	leaq	.LC0(%rip), %rax
	movl	$6, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Overflow_Check@PLT
.L26:
	movl	-16(%rbp), %eax
	subl	-8(%rbp), %eax
	cmpl	-20(%rbp), %eax
	jg	.L11
.L23:
	movl	$1, %eax
	jmp	.L29
.L11:
	movl	$0, %eax
.L29:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	num_matrix_block_sum__in_block, .-num_matrix_block_sum__in_block
	.align 2
	.type	num_matrix_block_sum__contribution, @function
num_matrix_block_sum__contribution:
.LFB4:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -8(%rbp)
	movl	%esi, -12(%rbp)
	movl	%edx, -16(%rbp)
	movl	%ecx, -20(%rbp)
	movl	%r8d, -24(%rbp)
	movl	%r9d, -28(%rbp)
	movl	-28(%rbp), %edi
	movl	-24(%rbp), %ecx
	movl	-20(%rbp), %edx
	movl	-16(%rbp), %esi
	movl	-12(%rbp), %eax
	movl	%edi, %r8d
	movl	%eax, %edi
	call	num_matrix_block_sum__in_block
	testb	%al, %al
	je	.L32
	cmpl	$0, -12(%rbp)
	jle	.L33
	cmpl	$4, -12(%rbp)
	jle	.L34
.L33:
	leaq	.LC0(%rip), %rax
	movl	$12, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Range_Check@PLT
.L34:
	cmpl	$0, -16(%rbp)
	jle	.L35
	cmpl	$4, -16(%rbp)
	jle	.L36
.L35:
	leaq	.LC0(%rip), %rax
	movl	$12, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Range_Check@PLT
.L36:
	movl	-12(%rbp), %eax
	movslq	%eax, %rcx
	movl	-16(%rbp), %eax
	movslq	%eax, %rdx
	movq	-8(%rbp), %rax
	subq	$1, %rcx
	salq	$2, %rcx
	addq	%rcx, %rdx
	subq	$1, %rdx
	movl	(%rax,%rdx,4), %eax
	jmp	.L37
.L32:
	movl	$0, %eax
.L37:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE4:
	.size	num_matrix_block_sum__contribution, .-num_matrix_block_sum__contribution
	.align 2
	.globl	num_matrix_block_sum__block_sum
	.type	num_matrix_block_sum__block_sum, @function
num_matrix_block_sum__block_sum:
.LFB5:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$40, %rsp
	.cfi_offset 3, -24
	movq	%rdi, -24(%rbp)
	movl	%esi, -28(%rbp)
	movl	%edx, -32(%rbp)
	movl	%ecx, -36(%rbp)
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$1, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	movslq	%eax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$2, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$3, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$4, %edx
	movl	$1, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$1, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$2, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$3, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$4, %edx
	movl	$2, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$1, %edx
	movl	$3, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$2, %edx
	movl	$3, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$3, %edx
	movl	$3, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$4, %edx
	movl	$3, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$1, %edx
	movl	$4, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$2, %edx
	movl	$4, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$3, %edx
	movl	$4, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rax, %rbx
	movl	-36(%rbp), %esi
	movl	-32(%rbp), %ecx
	movl	-28(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%esi, %r9d
	movl	%ecx, %r8d
	movl	%edx, %ecx
	movl	$4, %edx
	movl	$4, %esi
	movq	%rax, %rdi
	call	num_matrix_block_sum__contribution
	cltq
	addq	%rbx, %rax
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE5:
	.size	num_matrix_block_sum__block_sum, .-num_matrix_block_sum__block_sum
	.globl	num_matrix_block_sum_E
	.data
	.align 2
	.type	num_matrix_block_sum_E, @object
	.size	num_matrix_block_sum_E, 2
num_matrix_block_sum_E:
	.zero	2
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
