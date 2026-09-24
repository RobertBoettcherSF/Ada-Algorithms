	.file	"last_stone_weight_ii.adb"
	.text
	.align 2
	.globl	last_stone_weight_ii__TstonesBIP
	.type	last_stone_weight_ii__TstonesBIP, @function
last_stone_weight_ii__TstonesBIP:
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
	.size	last_stone_weight_ii__TstonesBIP, .-last_stone_weight_ii__TstonesBIP
	.section	.rodata
.LC0:
	.ascii	"last_stone_weight_ii.adb"
	.zero	1
	.text
	.align 2
	.type	last_stone_weight_ii__difference, @function
last_stone_weight_ii__difference:
.LFB3:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movl	%edi, -20(%rbp)
	movl	%esi, -24(%rbp)
	movl	-20(%rbp), %eax
	cltq
	movl	-24(%rbp), %edx
	movslq	%edx, %rdx
	addq	%rdx, %rdx
	subq	%rdx, %rax
	movq	%rax, -8(%rbp)
	cmpq	$0, -8(%rbp)
	jns	.L4
	movabsq	$-9223372036854775808, %rax
	cmpq	%rax, -8(%rbp)
	jne	.L5
	leaq	.LC0(%rip), %rax
	movl	$7, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Overflow_Check@PLT
.L5:
	movq	-8(%rbp), %rax
	negq	%rax
	jmp	.L6
.L4:
	movq	-8(%rbp), %rax
.L6:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	last_stone_weight_ii__difference, .-last_stone_weight_ii__difference
	.align 2
	.globl	last_stone_weight_ii__min_remaining_weight
	.type	last_stone_weight_ii__min_remaining_weight, @function
last_stone_weight_ii__min_remaining_weight:
.LFB4:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$160, %rsp
	movq	%rdi, -152(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	20(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -12(%rbp)
	movl	-12(%rbp), %eax
	cltq
	movq	%rax, -8(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %eax
	movl	%eax, -16(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -20(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -24(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -28(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -32(%rbp)
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	movl	%eax, -36(%rbp)
	movq	-152(%rbp), %rax
	movl	4(%rax), %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -40(%rbp)
	movq	-152(%rbp), %rax
	movl	4(%rax), %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -44(%rbp)
	movq	-152(%rbp), %rax
	movl	4(%rax), %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -48(%rbp)
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	movl	%eax, -52(%rbp)
	movq	-152(%rbp), %rax
	movl	8(%rax), %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -56(%rbp)
	movq	-152(%rbp), %rax
	movl	8(%rax), %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -60(%rbp)
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	movl	%eax, -64(%rbp)
	movq	-152(%rbp), %rax
	movl	12(%rax), %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -68(%rbp)
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	movl	%eax, -72(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -76(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -80(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -84(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -88(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -92(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -96(%rbp)
	movq	-152(%rbp), %rax
	movl	4(%rax), %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -100(%rbp)
	movq	-152(%rbp), %rax
	movl	4(%rax), %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -104(%rbp)
	movq	-152(%rbp), %rax
	movl	4(%rax), %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -108(%rbp)
	movq	-152(%rbp), %rax
	movl	8(%rax), %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -112(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -116(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -120(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -124(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -128(%rbp)
	movq	-152(%rbp), %rax
	movl	4(%rax), %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -132(%rbp)
	movq	-152(%rbp), %rax
	movl	(%rax), %edx
	movq	-152(%rbp), %rax
	movl	4(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	8(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	12(%rax), %eax
	addl	%eax, %edx
	movq	-152(%rbp), %rax
	movl	16(%rax), %eax
	addl	%edx, %eax
	movl	%eax, -136(%rbp)
	movl	-16(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L8
	movl	-16(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L8:
	movl	-20(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L9
	movl	-20(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L9:
	movl	-24(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L10
	movl	-24(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L10:
	movl	-28(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L11
	movl	-28(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L11:
	movl	-32(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L12
	movl	-32(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L12:
	movl	-36(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L13
	movl	-36(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L13:
	movl	-40(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L14
	movl	-40(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L14:
	movl	-44(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L15
	movl	-44(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L15:
	movl	-48(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L16
	movl	-48(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L16:
	movl	-52(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L17
	movl	-52(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L17:
	movl	-56(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L18
	movl	-56(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L18:
	movl	-60(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L19
	movl	-60(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L19:
	movl	-64(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L20
	movl	-64(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L20:
	movl	-68(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L21
	movl	-68(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L21:
	movl	-72(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L22
	movl	-72(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L22:
	movl	-76(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L23
	movl	-76(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L23:
	movl	-80(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L24
	movl	-80(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L24:
	movl	-84(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L25
	movl	-84(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L25:
	movl	-88(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L26
	movl	-88(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L26:
	movl	-92(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L27
	movl	-92(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L27:
	movl	-96(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L28
	movl	-96(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L28:
	movl	-100(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L29
	movl	-100(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L29:
	movl	-104(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L30
	movl	-104(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L30:
	movl	-108(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L31
	movl	-108(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L31:
	movl	-112(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L32
	movl	-112(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L32:
	movl	-116(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L33
	movl	-116(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L33:
	movl	-120(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L34
	movl	-120(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L34:
	movl	-124(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L35
	movl	-124(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L35:
	movl	-128(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L36
	movl	-128(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L36:
	movl	-132(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L37
	movl	-132(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L37:
	movl	-136(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	cmpq	%rax, -8(%rbp)
	jle	.L38
	movl	-136(%rbp), %edx
	movl	-12(%rbp), %eax
	movl	%edx, %esi
	movl	%eax, %edi
	call	last_stone_weight_ii__difference
	movq	%rax, -8(%rbp)
.L38:
	movq	-8(%rbp), %rax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE4:
	.size	last_stone_weight_ii__min_remaining_weight, .-last_stone_weight_ii__min_remaining_weight
	.globl	last_stone_weight_ii_E
	.data
	.align 2
	.type	last_stone_weight_ii_E, @object
	.size	last_stone_weight_ii_E, 2
last_stone_weight_ii_E:
	.zero	2
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
