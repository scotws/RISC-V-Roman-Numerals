# Roman Numerals in RISC-V RV32
# Scot W. Stevenson
# First version 2023-03-16
# This version 2023-03-16
# RV32 for RARS 1.6 https://github.com/TheThirdOne/rars

	.eqv SYS_PRINTINT 1	# RARS system call value to print integer
	.eqv SYS_READSTRING 8	# RARS system call value to read string
	.eqv SYS_EXIT 10	# RARS system call value for exit
	.eqv MAXCHAR 255	# max number of chars to read from user

	.data
digits: 
	.asciz "mdclxvi"	# we use lowercase internally
values:
	.half 1000, 500, 100, 50, 10, 5, 1
buffer:
	.space MAXCHAR		# reserve space for input from user	
	
	
	.text
start:
	# get number in Roman numerals as ASCII string from user
	# will be stored zero-terminated
		li a7, SYS_READSTRING	
		la a0, buffer		# address of buffer to store string
		li a1, MAXCHAR		# max number of chars accepted
		ecall
	
		la a1, buffer
		li a6, 0		# accumulator for result of conversion
		li a3, 0		# value of previous numeral
	
main_loop:
		lbu a0, 0(a1)		# get char from Roman string
		beqz a0, done		# quit if we are at end of string
	
	# We do not need to save ra to the stack in this example because we are calling a leaf
	# subroutine and are usings RARS. On a real RISC-V system, this may be different
	
		jal is_roman		# call subroutine: 0 if not Roman, otherwise value of char
		beqz a0, done		# quit if not valid Roman numeral
	
		ble a0, a3, positive	# if numeral less or equal to previous numeral, just add
	
	# value of numeral is larger than that of previous numeral, so we have a situation
	# such as "IV" where we should have subtracted. We make up for it by subtracting the
	# previous value twice
	
		slli a3, a3, 1		# double value of previous numeral
		neg a3, a3		# make new value negative
		add a6, a6, a3		# fall through to positive
	
positive:
		add a6, a6, a0		# add value to accumulator
		addi a1, a1, 1		# increase pointer to next char
		mv a3, a0		# make current value new previous value
		j main_loop
	
done:
	# print resulting number
		li a7, SYS_PRINTINT
		mv a0, a6
		ecall
		
		li a7, SYS_EXIT
		ecall	
	
	
# Subroutine: Check if ASCII char in a0 is an upper- or lowercase Roman numeral. If yes,
# return value of numeral in a0; if not, return 0
# The subroutine uses temporary registers such as t0 while the main routine uses a0 etc
	
is_roman:
	# force ASCII lower case by setting bit 5
		li t0, 0x20
		or a0, t0, a0
	
		la t0, digits		# base address of roman digit list
		li t1, 0		# index register
	
is_roman_loop:
		add t2, t0, t1		# create actual address of char
		lbu t6, 0(t2)		# get char of valid Roman char
		beqz t6, is_roman_done	# quit if we are at end of char list
		beq a0, t6, found_char	# we have found a match, go get value
	
		addi t1, t1, 1		# no match, try next char
		j is_roman_loop
	
found_char:
		la t0, values		# base address of halfwords with values
		slli t1, t1, 1		# shift index for halfwords
		add t2, t0, t1		# create actual address of value
		lhu a0, 0(t2)		# get value, unsigned load is paranoid
		ret
	
is_roman_done:
		li a0, 0		# if we ended up here no valid value was found
		ret	
