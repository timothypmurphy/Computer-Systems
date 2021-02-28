
#=========================================================================
# Punctuation checker 
#=========================================================================
# Marks misspelled words and punctuation errors in a sentence according to a dictionary
# and punctuation rules
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
dictionary_file_name:   .asciiz  "dictionary.txt"
newline:                .asciiz  "\n"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
content:                .space 2049     # Maximun size of input_file + NULL
.align 4                                # The next field will be aligned
dictionary:             .space 200001   # Maximum number of words in dictionary *
                                        # maximum size of each word + NULL
        
# You can add your data here!
.align 2
dictionarySorted:       .space 1000000
.align 2
tokens:			.space 411850 # Two dimensional tokens array  
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
        sb   $0,  content($t0)          # content[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(input_file)


        # opening file for reading

        li   $v0, 13                    # system call for open file
        la   $a0, dictionary_file_name  # input file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # fopen(dictionary_file, "r")
        
        move $s0, $v0                   # save the file descriptor 

        # reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP2:                             # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # dictionary[idx] = c_input
        la   $a1, dictionary($t0)       # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(dictionary_file);
        blez $v0, END_LOOP2             # if(feof(dictionary_file)) { break }
        lb   $t1, dictionary($t0)               
        lb   $t1, dictionary($t0)               
        beq  $t1, $0,  END_LOOP2        # if(c_input == '\n')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP2
END_LOOP2:
        sb   $0,  dictionary($t0)       # dictionary[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(dictionary_file)
#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------




# You can add your code here!

    jal tokenizer
    jal DictSort
    jal spell_checker
    jal output_tokens
    j main_end

tokenizer:

    la $a1, content    		# array to be processed
    li $a2, 2049     		# size of array to be processed

    la $t6, tokens 		# tokens array to be processed
    li $t5, -1			#$t5 = -1  $t5 is tokens vertical index

Loop1:
    beqz  $a2, End1        	# go to end if all array elements processed
    lb    $a0, 0($a1)     	# load array element into reg $a0
    
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
   
Cont1:
    addi  $a2, $a2, -1    	# $a2--, decrement counter for elements left to be processed in Content
    addi  $a1, $a1, 1   	# $a1++, increment address for next element
    j     Loop1            	# end of iteration, go to next loop
    
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
    li $s1, 10		# $s1 = "\n"
    addi, $s0, $s0, 4		# $s0 = 4
    sw $s1, 0($s0)		# Tokens[$t5][0] = $s1
    j CalcIndex			# go to CalcIndex

        
SameRow:
    addi, $t8, $t8, 1		# $t8++
    j CalcIndex   		# go to CalcIndex
    
CalcIndex:
    li $s0, 201		# $s0 = 2049
    mult $t5, $s0		
    mflo $s0			# $s0 = $t5 * $s0
    add $s0, $s0, $t8		# $s0+=$t8
    li $s1, 4			# $s1 = 4
    mult $s0, $s1		
    mflo $s1			# $s1 = $s1 * $s0 
    add $s0, $t6, $s1		# $s0 = $t6 + $s1
    sw $a0, 0($s0)		# Tokens[$t5][$t8] = $a0
    j Cont1			# go to Cont
    
End1:  
#    li $a3, 411850    	# size of array to be processed
#    la $a1, tokens 		
    
#Loop2:
#    beqz  $a3, End2        	# go to end if all array elements processed
#    lb $a0, 0($a1)		# $a0 = Tokens[$a1]
#    bne $a0, $zero, Print	# if ($a0 != 0) then go to print
#    j Cont2			# go to cont2
#    
#Print:  
#    li    $v0, 11   		# $v0 = 4
#    syscall        		# print_char($a1);
#    
#Cont2:
#    addi  $a3, $a3, -1    	# $a3--
#    addi  $a1, $a1, 4     	# $a1+=4
#    j Loop2			# go to Loop1
#    
#End2:

    jr $ra
    
    
   #############################################################################
   #########     	Dictionary Organiser             ##############################
   ############################################################################# 
   
   
DictSort:

    la $a1, dictionary   		# array to be processed
    li $a2, 200001     		# size of array to be processed

    la $t6, dictionarySorted 		# tokens array to be processed
    li $t5, 0			#$t5 = -1  $t5 is tokens vertical index
    li $t8, -1

LoopD:
    beqz  $a2, EndD        	# go to end if all array elements processed
    lb    $a0, 0($a1)     	# load array element into reg $a0

    li $t1, 10
    beq $a0, $t1, NewLineD
    beq $a0, $zero, EndD
    j SameLineD
    
NewLineD:
    addi $t5, $t5, 1
    li $t8, -1
    j CalcIndexD
    #j ContD


SameLineD:
    addi $t8, $t8, 1
    j CalcIndexD

CalcIndexD:
    li $s0, 20		# $s0 = 2049
    mult $t5, $s0		
    mflo $s0			# $s0 = $t5 * $s0
    add $s0, $s0, $t8		# $s0+=$t8
    li $s1, 4			# $s1 = 4
    mult $s0, $s1		
    mflo $s1			# $s1 = $s1 * $s0 
    add $s0, $t6, $s1		# $s0 = $t6 + $s1
    
    li $t1, 64 			#if(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z') go to IsLet
    slt $t2, $t1, $a0
    j StoreD
    
StoreD:
    sw $a0, 0($s0)		# Tokens[$t5][$t8] = $a0
    j ContD			# go to Cont
    



    
ContD:
    addi  $a2, $a2, -1    	# $a2--, decrement counter for elements left to be processed in Content
    addi  $a1, $a1, 1   	# $a1++, increment address for next element
    j     LoopD            	# end of iteration, go to next loop


EndD:

    

    jr $ra
   
   
   
   #############################################################################
   #########     	SPELL CHECKER             ##############################
   ############################################################################# 
    
    
    
    
    

spell_checker:
    la $t1, tokens    		# array to be processed
    li $t2, 2049   		# size of array to be processed
    la $t3, dictionarySorted    	# array to be processed
    li $t4, 10000  		# size of array to be processed
    li $t5, -1			# vertical index of tokens
    li $t6, -1			# horiztonal index of tokens
    li $t7, -1			# vertical index of dictionary
    li $t8, -1			# index of dictionary
    li $s0, 20			# length of dictionary word
    li $s1, 201			# length of token
    
LoopTok:
    addi $t5, $t5, 1
    addi $t2, $t2, -1
    beq $t2, $zero, LoopEndSpell
    li $t4, 10000
    li $t6, -1
    li $t7, -1			# vertical index of dictionary
    li $t8, -1			# horizontal index of dictionary

    j LoopDict

LoopDict:
    addi $t7, $t7, 1
    addi $t4, $t4, -1
    li $s0, 20
    li $t8, -1
    li $t6, -1
    beq $t4, $zero, CheckCorrect
    j LoopChar
    
LoopChar:
    addi $t6, $t6, 1
    addi $t8, $t8, 1

    j CalcTokIndx
    
ContChar:
    lb $s4, 0($s2)     	# load array element into reg $a0
    lb $s5, 0($s3)     	# load array element into reg $a0
    beq $t6, $zero, IsAlpha 
       
ContAlpha:
    li $t9, 64 			#if(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z') go to IsLet
    slt $s7, $s4, $t9
    beqz $s7, CheckUpper
    j SpellCheckCont

    
CheckUpper:
    li $t9, 91
    slt $s7, $t9, $s4
    beqz $s7, ToLower
    j SpellCheckCont
    

    
ToLower:
    addi $s4, $s4, 32
    j SpellCheckCont
    
    
SpellCheckCont:  
    li $s6, 10
    li $s7, 0
    beq $s4, $s6, CheckSpell
    
KeepGoing:
    bne $s4, $s5, LoopDict
    addi $s0, $s0, -1
    beq $s0, $zero, LoopTok
    j LoopChar
    
CheckSpell:
    beq $s5, $s7, LoopTok   
    j KeepGoing
     
    
CheckCorrect:

    #li $s6, 98
    #beq $s6, $t7, Incorrect
    #j LoopDict
    j Incorrect
    
Incorrect:
    mult $t5, $s1		
    mflo $s2			# $s0 = $t5 * $s0
    li $s3, 4			# $s1 = 4
    mult $s2, $s3		
    mflo $s2			# $s1 = $s1 * $s0 
    add $s2, $t1, $s2		# $s0 = $t6 + $s1


    lw $s4, 0($s2)
    addi $s2, $s2, 4
    lw $s5, 0($s2)
    addi $s2, $s2, -4
    li $s6, 95
    sw $s6, 0($s2)
    li $s7, 10
    li $t9, 1
    j LoopIncor

        
LoopIncor:
    beq $s7, $s5, IncorEnd
    beq $t9, $s5, IncorEnd
    beq $zero, $s5, IncorEnd
    addi $s2, $s2, 4
    sw $s4, 0($s2)
    move $s4, $s5
    addi $s2, $s2, 4
    lw $s5, 0($s2)
    addi $s2, $s2, -4
    j LoopIncor

IncorEnd:
    addi $s2, $s2, 4
    sw $s4, 0($s2)
    addi $s2, $s2, 4
    sw $s6, 0($s2)
    j LoopTok
    
 
    

CalcTokIndx:
    li $s6, 201
    mult $t5, $s6		
    mflo $s2			# $s0 = $t5 * $s0
    add $s2, $s2, $t6		# $s0+=$t8
    li $s3, 4			# $s1 = 4
    mult $s2, $s3		
    mflo $s2			# $s1 = $s1 * $s0 
    add $s2, $t1, $s2		# $s0 = $t6 + $s1
    j CalcDictIndx			# go to Cont    

CalcDictIndx:
    li $s6, 20
    mult $t7, $s6		
    mflo $s3			# $s0 = $t5 * $s0
    add $s3, $s3, $t8		# $s0+=$t8
    li $s4, 4			# $s1 = 4
    mult $s3, $s4		
    mflo $s3			# $s1 = $s1 * $s0 
    add $s3, $t3, $s3		# $s0 = $t6 + $s1
    j ContChar			# go to Cont
    
IsAlpha:

    li $s6, 44 			#if(c == ',' || c == '.' || c == '!' || c == '?') go to Punct:
    beq $s4, $s6, PunctCheck
    
    li $s6, 46
    beq $s4, $s6, PunctCheck
    
    li $s6, 33
    beq $s4, $s6, PunctCheck
    
    li $s6, 63
    beq $s4, $s6, PunctCheck
    
    li $s6, 32			#if(c == ' ') go to IsSpace
    beq $s4, $s6, LoopTok 	
    
    li $s6, 0			#if(c == ' ') go to IsSpace
    beq $s4, $s6, LoopTok 
    
    j ContAlpha
    
LoopEndSpell:

    jr $ra

output_tokens:
    la $a1, tokens    		# array to be processed
    li $a3, 411850
    li $s0, 10

Loop3:
    beqz  $a3, End3        	# go to end if all array elements processed
    lb $a0, 0($a1)		# $a0 = Tokens[$a1]
    beq $a0, $zero, Cont3	# if ($a0 != 0) then go to print
    beq $a0, $s0, Cont3
    j Print3			# go to cont2
    
Print3:  
    li    $v0, 11   		# $v0 = 4
    syscall        		# print_char($a1);
    j Cont3
    
Cont3:
    addi  $a3, $a3, -1    	# $a3--
    addi  $a1, $a1, 4     	# $a1+=4
    j Loop3			# go to Loop1
    
End3:
    
    jr $ra
    
    
    
PunctCheck:
#space before

    li $s6, 201
    addi $t6, $t5, -1
    mult $t6, $s6		
    mflo $t7			# $s0 = $t5 * $s0
    li $s3, 4			# $s1 = 4
    mult $t7, $s3		
    mflo $t7			# $s1 = $s1 * $s0 
    add $t7, $t1, $t7		# $s0 = $t6 + $s1  
    lb $t6, 0($t7)
    li $t8, 32
    
    beq $t8, $t6, PunctIncorrect
    
#Alpha after 

    li $s6, 201
    addi $t6, $t5, 1
    mult $t6, $s6		
    mflo $t7			# $s0 = $t5 * $s0
    li $s3, 4			# $s1 = 4
    mult $t7, $s3		
    mflo $t7			# $s1 = $s1 * $s0 
    add $t7, $t1, $t7		# $s0 = $t6 + $s1  
    lb $t6, 0($t7)
    
    li $t8, 44 			#if(c == ',' || c == '.' || c == '!' || c == '?') go to Punct:
    beq $t6, $t8, ContP1
    
    li $t8, 46
    beq $t6, $t8, ContP1
    
    li $t8, 33
    beq $t6, $t8, ContP1
    
    li $t8, 63
    beq $t6, $t8, ContP1
    
    li $t8, 32			#if(c == ' ') go to IsSpace
    beq $t6, $t8, ContP1 
    
    li $t8, 0			#if(c == ' ') go to IsSpace
    beq $t6, $t8, ContP1 
    
    li $t8, 10			#if(c == ' ') go to IsSpace
    beq $t6, $t8, ContP1 
    
    j PunctIncorrect	
    
ContP1:

# is ellipsis

    li $s6, 201
    move $t6, $t5
    mult $t6, $s6		
    mflo $t7			# $s0 = $t5 * $s0
    li $s3, 4			# $s1 = 4
    mult $t7, $s3		
    mflo $t7			# $s1 = $s1 * $s0 
    add $t7, $t1, $t7		# $s0 = $t6 + $s1  
    
    lb $t6, 0($t7)
    
    li $t8, 46
    
    bne $t8, $t6, ContP2
    addi $t7, $t7, 4 
     
    lb $t6, 0($t7)
    bne $t8, $t6, ContP2
    addi $t7, $t7, 4
    
    lb $t6, 0($t7)
    bne $t8, $t6, ContP2
    li $t8, 10
    addi $t7, $t7, 4
    
    lb $t6, 0($t7)
    bne $t6, $t8, ContP2
    j LoopTok
    
ContP2:

#only one punct mark

    li $s6, 201
    move $t6, $t5
    mult $t6, $s6		
    mflo $t7			# $s0 = $t5 * $s0
    li $s3, 4			# $s1 = 4
    mult $t7, $s3		
    mflo $t7			# $s1 = $s1 * $s0 
    add $t7, $t1, $t7		# $s0 = $t6 + $s1  
    addi $t7, $t7, 4
    lb $t6, 0($t7)
    li $t8, 10
    
    li $t8, 44 			#if(c == ',' || c == '.' || c == '!' || c == '?') go to Punct:
    beq $t6, $t8, PunctIncorrect
    
    li $t8, 46
    beq $t6, $t8, PunctIncorrect
    
    li $t8, 33
    beq $t6, $t8, PunctIncorrect
    
    li $t8, 63
    beq $t6, $t8, PunctIncorrect
    
    j LoopTok



PunctIncorrect:
    mult $t5, $s1		
    mflo $s2			# $s0 = $t5 * $s0
    li $s3, 4			# $s1 = 4
    mult $s2, $s3		
    mflo $s2			# $s1 = $s1 * $s0 
    add $s2, $t1, $s2		# $s0 = $t6 + $s1


    lw $s4, 0($s2)
    addi $s2, $s2, 4
    lw $s5, 0($s2)
    addi $s2, $s2, -4
    li $s6, 95
    sw $s6, 0($s2)
    li $s7, 10
    li $t9, 1
    j LoopIncorP

        
LoopIncorP:
    beq $s7, $s5, IncorEndP
    beq $t9, $s5, IncorEndP
    beq $zero, $s5, IncorEndP
    addi $s2, $s2, 4
    sw $s4, 0($s2)
    move $s4, $s5
    addi $s2, $s2, 4
    lw $s5, 0($s2)
    addi $s2, $s2, -4
    j LoopIncorP

IncorEndP:
    addi $s2, $s2, 4
    sw $s4, 0($s2)
    addi $s2, $s2, 4
    sw $s6, 0($s2)
    j LoopTok
    
        
#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:      
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
