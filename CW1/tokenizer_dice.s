
#=========================================================================
# Tokenizer
#=========================================================================
# Split a string into alphabetic, punctuation and space tokens
# 
# Inf2C Computer Systems
# 
# Siavash Katebzadeh
# 8 Oct 2018
# 
#
#=========================================================================
# DATA SEGMENT
#=========================================================================
.data
#-------------------------------------------------------------------------
# Constant strings
#-------------------------------------------------------------------------

input_file_name:        .asciiz  "input.txt"   
newline:                .asciiz  "\n"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
content:                .space 2049     # Maximun size of input_file + NULL


# You can add your data here!

.align 2
tokens:			.space 409800 # Two dimensional tokens array
.align 2
#=========================================================================
# TEXT SEGMENT  
#=========================================================================
.text

#-------------------------------------------------------------------------
# MAIN code block
#-------------------------------------------------------------------------

.globl main                     # Declare main label to be globally visible.
                                # Needed for correct operation with MARS
main:
        
#-------------------------------------------------------------------------
# Reading file block. DO NOT MODIFY THIS BLOCK
#-------------------------------------------------------------------------

# opening file for reading

        li   $v0, 13                    # system call for open file
        la   $a0, input_file_name       # input file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # open a file
        
        move $s0, $v0                   # save the file descriptor 

# reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP:                              # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # content[idx] = c_input
        la   $a1, content($t0)          # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(input_file);
        blez $v0, END_LOOP              # if(feof(input_file)) { break }
        lb   $t1, content($t0)          
        addi $v0, $0, 10                # newline \n
        beq  $t1, $v0, END_LOOP         # if(c_input == '\n')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP
END_LOOP:
        sb   $0,  content($t0)

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(input_file)
#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------

    la $a1, content    		# array to be processed
    li $a2, 2049     		# size of array to be processed

    la $t6, tokens 		# tokens array to be processed
    li $t5, -1			#$t5 = -1  $t5 is tokens vertical index

loop:
    beqz  $a2, end        	# go to end if all array elements processed
    lb    $a0, 0($a1)     	# load array element into reg $a0
    #beqz  $a0, end	  	#end when all chaacters processed
    
    li $t1, 44 			#if(c == ',' || c == '.' || c == '!' || c == '?') go to Punct:
    beq $a0, $t1, Punct
    
    li $t1, 46
    beq $a0, $t1, Punct
    
    li $t1, 33
    beq $a0, $t1, Punct
    
    li $t1, 63
    beq $a0, $t1, Punct
    
    li $t1, 32			#if(c == ' ') go to IsSpace
    beq $a0, $t1, IsSpace 	
    
    li $t1, 64 			#if(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z') go to IsLet
    slt $t2, $t1, $a0
    beqz $t2, IsLet
    
    li $t1, 91
    slt $t2, $a0, $t1
    beqz $t2, IsLet
    
    li $t1, 96
    slt $t2, $t1, $a0
    beqz $t2, IsLet
    
    li $t1, 123
    slt $t2, $a0, $t1
    beqz $t2, IsLet
   
Cont:
    addi  $a2, $a2, -1    	# $a2--, decrement counter for elements left to be processed in Content
    addi  $a1, $a1, 1   	# $a1++, increment address for next element
    j     loop            	# end of iteration, go to next loop
    
IsLet:
    li $t3, 1 			# $t3 = 1 (Letter character), $t3 represents what type of character is being processed
    bne $t3, $t4, NewRow 	# if ($t3 != $t4) then go to NewRow
    j SameRow			# else go to SameRow

Punct:
    li $t3, 2 			# $t3 = 2 (Punctuation character)
    bne $t3, $t4, NewRow 	# if ($t3 != $t4) then go to NewRow
    j SameRow			# else go to SameRow
    
IsSpace:
    li $t3, 3 			# $t3 = 3 (Space character)
    bne $t3, $t4, NewRow 	# if ($t3 != $t4) then go to NewRow
    j SameRow			# else go to SameRow
    
NewRow:
    move $t4, $t3		# $t4 = $t3
    li $s1, -1			# $s1 = -1
    li $t8, 0			# $t8 = 0
    bne $t5, $s1, addnewline	# if ($t5 != $s1) then go to addnewline
    addi $t5, $t5, 1 		# $t5++
    j CalcIndex			# go to CalcIndex
    
addnewline:
    addi $t5, $t5, 1 		# t5++
    la $s1, newline		# $s1 = "\n"
    addi, $s0, $s0, 4		# $s0 = 4
    sw $s1, 0($s0)		# Tokens[$t5][0] = $s1
    j CalcIndex			# go to CalcIndex

        
SameRow:
    addi, $t8, $t8, 1		# $t8++
    j CalcIndex   		# go to CalcIndex
    
CalcIndex:
    li $s0, 2049		# $s0 = 2049
    mult $t5, $s0		
    mflo $s0			# $s0 = $t5 * $s0
    add $s0, $s0, $t8		# $s0+=$t8
    li $s1, 4			# $s1 = 4
    mult $s0, $s1		
    mflo $s1			# $s1 = $s1 * $s0 
    add $s0, $t6, $s1		# $s0 = $t6 + $s1
    sw $a0, 0($s0)		# Tokens[$t5][$t8] = $a0
    j Cont			# go to Cont
    
end:   
    #li $a0, 1			# $a0 = 1
    #addi $s0, $s0, 4		# $s0+=4
    #sw $a0, 0($s0)		# Tokens[$t5][$t8] = 1
    li $a3, 409800     	# size of array to be processed
    la $a1, tokens 		
    #li $t0, 1			# $t0 = 1
    
Loop1:
    beqz  $a3, end1        	# go to end if all array elements processed
    lb $a0, 0($a1)		# $a0 = Tokens[$a1]
    #beq $a0, $t0, end1		# if ($a0 == $t0) then go to end1
    bne $a0, $zero, print	# if ($a0 != 0) then go to print
    j cont2			# go to cont2
    
print:  
    li    $v0, 11   		# $v0 = 4
    syscall        		# print_char($a1);
    
cont2:
    addi  $a3, $a3, -1    	# $a3--
    addi  $a1, $a1, 4     	# $a1+=4
    j Loop1			# go to Loop1
    
end1:

        
        
#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:      
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
