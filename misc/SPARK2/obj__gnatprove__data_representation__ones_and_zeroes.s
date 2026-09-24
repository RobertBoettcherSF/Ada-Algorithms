	.file	"ones_and_zeroes.adb"
	.text
	.align 2
	.globl	ones_and_zeroes__TcountsBIP
	.type	ones_and_zeroes__TcountsBIP, @function
ones_and_zeroes__TcountsBIP:
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
	.size	ones_and_zeroes__TcountsBIP, .-ones_and_zeroes__TcountsBIP
	.align 2
	.type	ones_and_zeroes__fits, @function
ones_and_zeroes__fits:
.LFB3:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -4(%rbp)
	movl	%esi, -8(%rbp)
	movl	%edx, -12(%rbp)
	movl	%ecx, -16(%rbp)
	movl	-4(%rbp), %eax
	cmpl	-12(%rbp), %eax
	setle	%dl
	movl	-8(%rbp), %eax
	cmpl	-16(%rbp), %eax
	setle	%al
	andl	%edx, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	ones_and_zeroes__fits, .-ones_and_zeroes__fits
	.align 2
	.globl	ones_and_zeroes__max_form
	.type	ones_and_zeroes__max_form, @function
ones_and_zeroes__max_form:
.LFB4:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$56, %rsp
	.cfi_offset 3, -24
	movq	%rdi, %rax
	movq	%rsi, %r10
	movq	%rax, %rsi
	movl	$0, %edi
	movq	%r10, %rdi
	movq	%rsi, -32(%rbp)
	movq	%rdi, -24(%rbp)
	movq	%rdx, -48(%rbp)
	movq	%rcx, -40(%rbp)
	movl	%r8d, -52(%rbp)
	movl	%r9d, -56(%rbp)
	movl	-48(%rbp), %edx
	movl	-44(%rbp), %eax
	addl	%eax, %edx
	movl	-40(%rbp), %eax
	addl	%eax, %edx
	movl	-36(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-32(%rbp), %edx
	movl	-28(%rbp), %eax
	addl	%eax, %edx
	movl	-24(%rbp), %eax
	addl	%eax, %edx
	movl	-20(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	testb	%al, %al
	je	.L6
	movl	$4, %eax
	jmp	.L7
.L6:
	movl	-48(%rbp), %edx
	movl	-44(%rbp), %eax
	addl	%eax, %edx
	movl	-40(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-32(%rbp), %edx
	movl	-28(%rbp), %eax
	addl	%eax, %edx
	movl	-24(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	movl	%eax, %ebx
	movl	-48(%rbp), %edx
	movl	-44(%rbp), %eax
	addl	%eax, %edx
	movl	-36(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-32(%rbp), %edx
	movl	-28(%rbp), %eax
	addl	%eax, %edx
	movl	-20(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	orl	%eax, %ebx
	movl	-48(%rbp), %edx
	movl	-40(%rbp), %eax
	addl	%eax, %edx
	movl	-36(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-32(%rbp), %edx
	movl	-24(%rbp), %eax
	addl	%eax, %edx
	movl	-20(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	orl	%eax, %ebx
	movl	-44(%rbp), %edx
	movl	-40(%rbp), %eax
	addl	%eax, %edx
	movl	-36(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-28(%rbp), %edx
	movl	-24(%rbp), %eax
	addl	%eax, %edx
	movl	-20(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	orl	%ebx, %eax
	testb	%al, %al
	je	.L8
	movl	$3, %eax
	jmp	.L7
.L8:
	movl	-48(%rbp), %edx
	movl	-44(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-32(%rbp), %edx
	movl	-28(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	movl	%eax, %ebx
	movl	-48(%rbp), %edx
	movl	-40(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-32(%rbp), %edx
	movl	-24(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	orl	%eax, %ebx
	movl	-48(%rbp), %edx
	movl	-36(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-32(%rbp), %edx
	movl	-20(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	orl	%eax, %ebx
	movl	-44(%rbp), %edx
	movl	-40(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-28(%rbp), %edx
	movl	-24(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	orl	%eax, %ebx
	movl	-44(%rbp), %edx
	movl	-36(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-28(%rbp), %edx
	movl	-20(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	orl	%eax, %ebx
	movl	-40(%rbp), %edx
	movl	-36(%rbp), %eax
	leal	(%rdx,%rax), %esi
	movl	-24(%rbp), %edx
	movl	-20(%rbp), %eax
	leal	(%rdx,%rax), %edi
	movl	-56(%rbp), %edx
	movl	-52(%rbp), %eax
	movl	%edx, %ecx
	movl	%eax, %edx
	call	ones_and_zeroes__fits
	orl	%ebx, %eax
	testb	%al, %al
	je	.L9
	movl	$2, %eax
	jmp	.L7
.L9:
	movl	-48(%rbp), %esi
	movl	-32(%rbp), %eax
	movl	-56(%rbp), %ecx
	movl	-52(%rbp), %edx
	movl	%eax, %edi
	call	ones_and_zeroes__fits
	movl	%eax, %ebx
	movl	-44(%rbp), %esi
	movl	-28(%rbp), %eax
	movl	-56(%rbp), %ecx
	movl	-52(%rbp), %edx
	movl	%eax, %edi
	call	ones_and_zeroes__fits
	orl	%eax, %ebx
	movl	-40(%rbp), %esi
	movl	-24(%rbp), %eax
	movl	-56(%rbp), %ecx
	movl	-52(%rbp), %edx
	movl	%eax, %edi
	call	ones_and_zeroes__fits
	orl	%eax, %ebx
	movl	-36(%rbp), %esi
	movl	-20(%rbp), %eax
	movl	-56(%rbp), %ecx
	movl	-52(%rbp), %edx
	movl	%eax, %edi
	call	ones_and_zeroes__fits
	orl	%ebx, %eax
	testb	%al, %al
	je	.L10
	movl	$1, %eax
	jmp	.L7
.L10:
	movl	$0, %eax
.L7:
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE4:
	.size	ones_and_zeroes__max_form, .-ones_and_zeroes__max_form
	.globl	ones_and_zeroes_E
	.data
	.align 2
	.type	ones_and_zeroes_E, @object
	.size	ones_and_zeroes_E, 2
ones_and_zeroes_E:
	.zero	2
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
