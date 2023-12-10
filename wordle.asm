

# $s0 stores the address of randomly generated word.
# $s1 stores the attempt count.

.data 
	#user input
	guessword: .space 8 # 1 char takes 1 byte, I love full addr and alignment, so always 8!
	#a: .space "happy", "winner", "hello", "guess", "april", "earth", "water", "fanta" # char a[5][8], 5*8 = 40, aligned! Congrats!
	#prompts
	intro: .asciiz "\n=============================================\nWelcome to Richard Jorne's wordle, let's play\n=============================================\nWhat do you want to do?\n   (1) Play\n   (2) Quit\n"
	wrong_word_prompt: .asciiz "\n(*'O'*) You entered the wrong number!(*'O'*) \n(/`w`)/Please enter again!\n"
	game_begin_prompt: .asciiz "\n(^v^) -----GAME BEGIN----- (^v^)\nGuess a 5-letter lower-case word!\n"
	make_your_guess_prompt: .asciiz "/5) <`w´> Make your guess: "
	bye_prompt: .asciiz "\n(^_^)/ Bye!\n"
	ok_prompt: .asciiz "ok\n"
	bad_prompt: .asciiz "bad\n"
	win_prompt: .asciiz "\n(('w')) Congrats! You win! (('w'))\nThe word was indeed: "
	lose_prompt: .asciiz "\n(T_T) You lose! (T_T)\nThe correct word is: "
	short_word_prompt: .asciiz "\n(*'O'*) You entered a word less than 5 letters!(*'O'*) \n(/`w`)/Please enter again!\n"
	
	#words
	wordlist: .ascii "happy", "phone", "hello", "guess", "april", "earth", "water", "fanta"
	#5*8 bytes
	
	


.text 
	main:
		j game_prologue

		
		
		li $v0, 10 #quit
		syscall
		
	game_prologue:
		prologue_main:
			li $v0, 4 # Print word
			la $a0, intro
			syscall
			
			li $v0, 12 # Ask for input
			syscall
			
			bne $v0, '1', not_1 # v0 != 1, check wrong word or quit.
			jal game
			
			not_1:
				bne $v0, '2', wrong_word # if v0 == 2, quit
			quit:
				li $v0, 4 # Print word
				la $a0, bye_prompt
				syscall
				li $v0, 10 # quit
				syscall
	
			wrong_word:
				li $v0, 4 # Print word
				la $a0, wrong_word_prompt
				syscall
				j prologue_main
		
		lw $ra ($sp)
		addi $sp, $sp, 4
		jr $ra
		
	game:
		# some initialization begin
		
		li $a0, 0
		li $a1, 8
		li $v0, 42 # Random int less than 8, for 0~7
		syscall
		mul $a0, $a0, 5 # a word contains 5 bytes
		la $s0, wordlist
		add $s0, $s0, $a0 # save randomly generated word address to $s0
		
		li $s1, 0 #clear guess count
		li $v0, 4 # Print word
		la $a0, game_begin_prompt
		syscall
		
		# some initialization end
		
		make_guess:
			li $v0, 11 # Print word
			li $a0, '\n'
			syscall
			li $v0, 11 # Print word
			li $a0, '('
			syscall
			li $v0, 1 # Print word
			move $a0, $s1
			addi $a0, $a0, 1
			syscall
			li $v0, 4 # Print word
			la $a0, make_your_guess_prompt
			syscall
		
		read_guess_word:
			li $v0, 8 # Read string (No waiting once finished typing!)
			la $a0, guessword
			li $a1, 6
			syscall
		
		li $v0, 11 # Print return since it automatically returns.
		la $a0, '\n' 
		syscall
		
		li $t0, 0
		la $t1, guessword
		check_input_length:
			# $t0 saves the current run count
			# $t1 saves the char addr
			# $t2 saves the char
			bge $t0, 5, check_guess_word
			add $t0, $t0, 1
			lb $t2, ($t1) #load char to check
			add $t1, $t1, 1
			bne $t2, '\0', check_2
			check_2:
				bne $t2, '\n', check_input_length
			too_short:
				li $v0, 4 # Print word
				la $a0, short_word_prompt
				syscall
				j make_guess
			
		
		check_guess_word:
		# $t0 saves the current [check] letter offset [USERINPUT]
		# $t1 saves the current [check] letter offset address [USERINPUT]
		# $t2 saves the current [checking] letter offset [RANDOM]
		# $t3 saves the current [checking] letter offset address [RANDOM]
		# $t4 saves the current [checking] letter [USERINPUT]
		# $t5 saves whether the letter is in the word, 0 is false, 1 is true
		# $t6 saves the current [checking] letter [RANDOM]
		# $t7 saves correct letter at correct position count
		
		la $t1, guessword #load random word
		li $t0, 0
		li $t2, 0
		li $t5, 0
		li $t7, 0
		
			check_input_loop:
				bge $t0, 5, check_finished # finish checking if already checked for 5 letters of input
				addi $t0, $t0, 1
				
				move $t3, $s0 #load address of random word
				li $t2, 0
				
				li $t5, 0
				
				lb $t4, ($t1) #load char to check
				add $t1, $t1, 1
				
				check_position_loop:
					bge $t2, 5, position_check_finished # finish checking if already checked for 5 letters of correct word
					lb $t6, ($t3) #load char to check
					addi $t3, $t3, 1 #add address of random word (position)
					addi $t2, $t2, 1
					bne $t6, $t4, check_position_loop
					#If the program comes here, it means that this letter is in the word.
					li $t5, 1 #set to 'It is in the word'
					check_same_position:
						bne $t0, $t2, check_position_loop #incorrect position, continue checking
						#same position
						j right_position_letter
					
				position_check_finished:
					beq $t5, 0, wrong_letter #not in the word
					in_word_letter:
						li $a0, '('
						li $v0, 11 #print char
						syscall
						move $a0, $t4
						li $v0, 11 #print char
						syscall
						li $a0, ')'
						li $v0, 11 #print char
						syscall
						j check_input_loop
					wrong_letter:
						li $a0, ' '
						li $v0, 11 #print char
						syscall
						move $a0, $t4
						li $v0, 11 #print char
						syscall
						li $a0, ' '
						li $v0, 11 #print char
						syscall
						j check_input_loop
					right_position_letter:
						addi $t7, $t7, 1
						li $a0, '['
						li $v0, 11 #print char
						syscall
						move $a0, $t4
						li $v0, 11 #print char
						syscall
						li $a0, ']'
						li $v0, 11 #print char
						syscall
						j check_input_loop
					
		check_finished:

			 bne $t7, 5, game_lose #if correct count less than 5, lose
			 game_win:
			 	li $v0, 4 # Print word
				la $a0, win_prompt
				syscall
				j print_correct_word
			 game_lose:
			 	add $s1, $s1, 1
				blt $s1, 5, make_guess # s0 < 5, go back 4 times, execute 5 times in total
			 	li $v0, 4 # Print word
				la $a0, lose_prompt
				syscall
				
			
			print_correct_word:
				li $t0, 0 # $t0 saves print char count
				move $t3, $s0 #$t3 saves the current [checking] letter offset address [RANDOM]
				print_correct_word_loop:
					# $t0 saves output count
					
					lb $a0, ($t3)
					li $v0, 11 #print char
					syscall
					
					addi $t3, $t3, 1

					addi $t0, $t0, 1
					blt $t0, 5, print_correct_word_loop #repeat 4 times, 5 times in total
		game_finish:
			li $a0, '\n'
			li $v0, 11 #print char
			syscall
			li $a0, 1000 #sleep for 1000 ms, to let the player realize
			li $v0, 32
			syscall
			j game_prologue
		

		j quit









