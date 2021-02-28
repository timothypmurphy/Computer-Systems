
#=========================================================================
# Spell checker 
#=========================================================================
# Marks misspelled words in a sentence according to a dictionary
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

# You can add your data here!#



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
        beq  $t1, $0,  END_LOOP2        # if(c_input == '\0')
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

    jr $ra
    
    
   #############################################################################
   #########     	Dictionary Organiser             ##############################
   ############################################################################# 
   
   
DictSort:

    la $a1, dictionary   		# dictionary array
    li $a2, 200001     		
	
    la $t6, dictionarySorted		# dictionarySorted array 		
    li $t5, 0				# $t5 = 0;
    li $t8, -1				# $t8 = -1

LoopD:
    beqz  $a2, EndD        		# while ($a2 != 0)
    lb    $a0, 0($a1)     		# $a0 = dictionary[$a1];

    li $t1, 10				# $t1 = 10;
    beq $a0, $t1, NewLineD		# if($a0 == $t1) then go to NewLineD
    beq $a0, $zero, EndD		# else if ($a0 == 0) then go to EndD
    j SameLineD				# else go to SameLineD
    
NewLineD:
    addi $t5, $t5, 1			# $t5++;
    li $t8, -1				# $t8 = -1;
    j CalcIndexD			# go to CalcIndexD


SameLineD:
    addi $t8, $t8, 1			# $t8++;
    j CalcIndexD			# go to CalcIndexD

CalcIndexD:
    li $s0, 20				# $s0 = 20;
    mult $t5, $s0			
    mflo $s0				# $s0 = $t5 * $s0;
    add $s0, $s0, $t8			# $s0 += $t8;
    li $s1, 4				# $s1 = 4;
    mult $s0, $s1		
    mflo $s1			 	# $s1 = $s0 * $s1;
    add $s0, $t6, $s1			# $s0 = $t6 + $s1;
    
    li $t1, 64 				# $t1 = 64;
    slt $t2, $t1, $a0			# if ($t1 > $a0) then $t2 = 0;
    j StoreD				# go to StoreD
    
StoreD:
    sw $a0, 0($s0)			# sortedDictionary[$s0] = $a0;
    j ContD				# go to ContD
    
ContD:
    addi  $a2, $a2, -1    		# $a2--;
    addi  $a1, $a1, 1   		# $a1++;
    j     LoopD            		# go to LoopD


EndD:

    

    jr $ra				# return;
   
   
   
   #############################################################################
   #########     	SPELL CHECKER             ##############################
   ############################################################################# 
    
    
    
    
    

spell_checker:
    la $t1, tokens    			# Tokens array
    li $t2, 2049   			# Length of tokens array			$t2 = 2049;
    la $t3, dictionarySorted    	# 2D dictionary array	
    li $t4, 10000  			# Length of 2D dictionary array			$t4 = 10000;
    li $t5, -1				# Tokens array vertical index			$t5 = -1;
    li $t6, -1				# Tokens array horizontal index			$t6 = -1;
    li $t7, -1				# Dictionary array vertical index		$t7 = -1;
    li $t8, -1				# Dictionary array horizontal index		$t8 = -1;
    li $s0, 20				# Longest length of a word in the dictonary	$s0 = 20 ;
    li $s1, 201				# Longest length of a token			$s1 = 201;
    
LoopTok:
    addi $t5, $t5, 1			# $t5++;
    addi $t2, $t2, -1			# $t2--;
    beq $t2, $zero, LoopEndSpell	# if $t2 == 0 then go to LoopEndSpell
    li $t4, 10000			# $t4 = 10000;
    li $t6, -1				# $t6 = -1;
    li $t7, -1				# $t7 = -1;
    li $t8, -1				# $t8 = -1;

    j LoopDict				# go to LoopDict

LoopDict:
    addi $t7, $t7, 1			# $t7++;
    addi $t4, $t4, -1			# $t4--;
    li $s0, 20				# $s0 = 20;
    li $t8, -1				# $t8 = -1;
    li $t6, -1				# $t6 = -1;
    beq $t4, $zero, CheckCorrect	# if $t4 == 0 then go to CheckCorrect
    j LoopChar				# else go to LoopChar
    
LoopChar:
    addi $t6, $t6, 1			# $t6++;
    addi $t8, $t8, 1			# $t8++;

    j CalcTokIndx			# go to CalcTokIndx
    
ContChar:
    lb $s4, 0($s2)     			# $s4 = tokens[$s2];
    lb $s5, 0($s3)     			# $s5 = sortedDictionary[$s3];
    beq $t6, $zero, IsAlpha 		# if $t6 == 0 then go to IsAlpha;
       
ContAlpha:
    li $t9, 64 				# $t9 = 64;
    slt $s7, $s4, $t9			# if($s4 < $t9) then $s7 = 1; else $s7 = 0;
    beqz $s7, CheckUpper		# if ($s7 == 0) then go to CheckUpper
    j SpellCheckCont			# else go to SpellCheckCont

    
CheckUpper:
    li $t9, 91				# $t9 = 91;
    slt $s7, $t9, $s4			# if($t9 < $s4) then $s7 = 1; else $s7 = 0;
    beqz $s7, ToLower			# if ($s7 == 0) then go to ToLower
    j SpellCheckCont			# else go to SpellCheckCont
    
ToLower:
    addi $s4, $s4, 32			# $s4 += 32;
    j SpellCheckCont			# gp tp SpellCheckCont
    
    
SpellCheckCont:  
    li $s6, 10				# $s6 = 10;
    li $s7, 0				# $s7 = 0;
    beq $s4, $s6, CheckSpell		# if($s4 == $s6) then go to CheckSpell
    
KeepGoing:
    bne $s4, $s5, LoopDict		# if($s4 != $s5) then go to LoopDict
    addi $s0, $s0, -1			# $s0 -= 1;
    beq $s0, $zero, LoopTok		# if ($0 == 0) then go to LoopTok
    j LoopChar				# else go to LoopChar
    
CheckSpell:
    beq $s5, $s7, LoopTok   		# if ($s5 == $s7) then go to LoopTok
    j KeepGoing				# else go to KeepGoing
     
    
CheckCorrect:
    j Incorrect				# go to Incorrect
    
Incorrect:
    mult $t5, $s1			
    mflo $s2				# $s2 = $t5 * $s1;
    li $s3, 4				# $s3 = 4;
    mult $s2, $s3			
    mflo $s2				# $s2 = $s2 * $s3;
    add $s2, $t1, $s2			# $s2 += $t1;


    lw $s4, 0($s2)			# $s4 = Tokens[$s2];
    addi $s2, $s2, 4			# $s2 += 4;
    lw $s5, 0($s2)			# $s5 = Tokens[$s2];
    addi $s2, $s2, -4			# $s2 -= 4;
    li $s6, 95				# $s6 = _;
    sw $s6, 0($s2)			# Tokens[$s2] = $s6;
    li $s7, 10				# $s7 = 10;
    li $t9, 1				# $t9 = 1;
    j LoopIncor				# go to LoopIncor

        
LoopIncor:
    beq $s7, $s5, IncorEnd		# if ($s7 == $s5) then go to IncorEnd
    beq $t9, $s5, IncorEnd		# if ($t9 == $s5) then go to IncorEnd
    beq $zero, $s5, IncorEnd		# if ($s5 == 0) then go to IncorEnd
    addi $s2, $s2, 4			# $s2 += 4;
    sw $s4, 0($s2)			# Tokens[$s2] = $s4;
    move $s4, $s5			# $s4 = $s5;
    addi $s2, $s2, 4			# $s2 += 4;
    lw $s5, 0($s2)			# $s5 = Tokens[$s2];
    addi $s2, $s2, -4			# $s2 -= 4;
    j LoopIncor				# go to LoopIncor

IncorEnd:
    addi $s2, $s2, 4			# $s2 += 4;
    sw $s4, 0($s2)			# Tokens[$s2] = $s4;
    addi $s2, $s2, 4			# $s2 += 4;
    sw $s6, 0($s2)			# Tokens[$s2] = $s6;
    j LoopTok				# go to LoopTok;
    
 
    

CalcTokIndx:
    li $s6, 201				# $s6 = 201;
    mult $t5, $s6			
    mflo $s2				# $s2 = $t5 * $s6;
    add $s2, $s2, $t6			# $s2 += $t6;
    li $s3, 4				# $s3 = 4;
    mult $s2, $s3		
    mflo $s2				# $s2 = $s2 * $s3;
    add $s2, $t1, $s2			# $2 += $t1;
    j CalcDictIndx		  	# go to CalcDictIndx

CalcDictIndx:
    li $s6, 20				# $s6 = 20;
    mult $t7, $s6			
    mflo $s3				# $s3 = $t7 * $s6;
    add $s3, $s3, $t8			# $s3 += $t8;
    li $s4, 4				# $s4 = 4;
    mult $s3, $s4		
    mflo $s3			 	# $s3 = $s3 * $s4;
    add $s3, $t3, $s3			# $s3 += $t3;
    j ContChar				# go to ContChar
    
IsAlpha:

    li $s6, 44 				
    beq $s4, $s6, LoopTok		# if($s4 = ',' || $s4 = '.' || $s4 = '!' || $s4 = '?' || $s4 = ' ' || $s4 = '\0') then go to LoopTok
    
    li $s6, 46				
    beq $s4, $s6, LoopTok
    
    li $s6, 33
    beq $s4, $s6, LoopTok
    
    li $s6, 63
    beq $s4, $s6, LoopTok
    
    li $s6, 32			
    beq $s4, $s6, LoopTok 	
    
    li $s6, 0			
    beq $s4, $s6, LoopTok 
    
    j ContAlpha				# else go to ContAlpha
    
LoopEndSpell:

    jr $ra				# return;

output_tokens:
    la $a1, tokens    			
    li $a3, 411850
    li $s0, 10

Loop3:
    beqz  $a3, End3        		# while ($a3 != 0)
    lb $a0, 0($a1)			
    beq $a0, $zero, Cont3	
    beq $a0, $s0, Cont3
    j Print3			
    
Print3:  
    li    $v0, 11   			# output Tokens[$a3];
    syscall        			# $a3--;
    j Cont3
    
Cont3:
    addi  $a3, $a3, -1    	
    addi  $a1, $a1, 4     	
    j Loop3			
    
End3:
    
    jr $ra				# return;
        
          
        
#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:      
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
