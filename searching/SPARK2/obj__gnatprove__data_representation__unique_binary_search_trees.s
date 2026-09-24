	.file	"unique_binary_search_trees.adb"
	.text
	.align 2
	.globl	unique_binary_search_trees__TtableBIP
	.type	unique_binary_search_trees__TtableBIP, @function
unique_binary_search_trees__TtableBIP:
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
	.size	unique_binary_search_trees__TtableBIP, .-unique_binary_search_trees__TtableBIP
	.align 2
	.globl	unique_binary_search_trees__number_of_trees
	.type	unique_binary_search_trees__number_of_trees, @function
unique_binary_search_trees__number_of_trees:
.LFB3:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -4(%rbp)
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	leaq	unique_binary_search_trees__catalan(%rip), %rax
	movl	(%rdx,%rax), %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	unique_binary_search_trees__number_of_trees, .-unique_binary_search_trees__number_of_trees
	.globl	unique_binary_search_trees_E
	.data
	.align 2
	.type	unique_binary_search_trees_E, @object
	.size	unique_binary_search_trees_E, 2
unique_binary_search_trees_E:
	.zero	2
	.section	.rodata
	.align 32
	.type	unique_binary_search_trees__catalan, @object
	.size	unique_binary_search_trees__catalan, 68
unique_binary_search_trees__catalan:
	.long	1
	.long	1
	.long	2
	.long	5
	.long	14
	.long	42
	.long	132
	.long	429
	.long	1430
	.long	4862
	.long	16796
	.long	58786
	.long	208012
	.long	742900
	.long	2674440
	.long	9694845
	.long	35357670
	.ident	"GCC: (GNAT-FSF-builds) 16.1.0"
	.section	.note.GNU-stack,"",@progbits
