	.file	"out_of_boundary_paths_lite.adb"
	.text
	.section	.rodata
.LC0:
	.ascii	"out_of_boundary_paths_lite.adb"
	.zero	1
	.text
	.align 2
	.globl	out_of_boundary_paths_lite__immediate_exits
	.type	out_of_boundary_paths_lite__immediate_exits, @function
out_of_boundary_paths_lite__immediate_exits:
.LFB2:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movl	%edi, -20(%rbp)
	movl	%esi, -24(%rbp)
	movl	$0, -4(%rbp)
	cmpl	$1, -20(%rbp)
	jne	.L2
	movl	$1, -4(%rbp)
.L2:
	cmpl	$4, -20(%rbp)
	jne	.L3
	movl	-4(%rbp), %eax
	addl	$1, %eax
	testl	%eax, %eax
	js	.L4
	cmpl	$4, %eax
	jle	.L5
.L4:
	leaq	.LC0(%rip), %rax
	movl	$7, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Range_Check@PLT
.L5:
	movl	%eax, -4(%rbp)
.L3:
	cmpl	$1, -24(%rbp)
	jne	.L6
	movl	-4(%rbp), %eax
	addl	$1, %eax
	testl	%eax, %eax
	js	.L7
	cmpl	$4, %eax
	jle	.L8
.L7:
	leaq	.LC0(%rip), %rax
	movl	$8, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Range_Check@PLT
.L8:
	movl	%eax, -4(%rbp)
.L6:
	cmpl	$4, -24(%rbp)
	jne	.L9
	movl	-4(%rbp), %eax
	addl	$1, %eax
	testl	%eax, %eax
	js	.L10
	cmpl	$4, %eax
	jle	.L11
.L10:
	leaq	.LC0(%rip), %rax
	movl	$9, %esi
	movq	%rax, %rdi
	call	__gnat_rcheck_CE_Range_Check@PLT
.L11:
	movl	%eax, -4(%rbp)
.L9:
	movl	-4(%rbp), %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	out_of_boundary_paths_lite__immediate_exits, .-out_of_boundary_paths_lite__immediate_exits
	.globl	out_of_boundary_paths_lite_E
	.data
	.align 2
	.type	out_of_boundary_paths_lite_E, @object
	.size	out_of_boundary_paths_lite_E, 2
out_of_boundary_paths_lite_E:
	.zero	2
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
