#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Sanan S. Rao, 1006577697, raosanan, sanan.rao@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 2
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

# Internal Settings
.eqv BASE_ADDRESS 0x10008000
.eqv SLEEP_TIME 20

# Physics Settings
.eqv GRAVITY 1
.eqv MAX_VELOCITY 5
.eqv JETPACK_STRENGTH 8

# #
.eqv BACKGROUND_COLOR  0x00b7ef
.eqv FRAMEBUFFER_SIZE 65532

.eqv FRAME_MAX_WIDTH 127
.eqv FRAME_MAX_HEIGHT 127


# Player Character
.eqv CHARACTER_WIDTH 10
.eqv CHARACTER_HEIGHT 20


.data
	padding: .space FRAMEBUFFER_SIZE

	# State
	player_info: .word 25, 25, 0, 0 # X, Y, velX, velY
	platform0: .word 0, 0, 0 # X, Y, velX


	# Graphics Buffers
	paintBuffer: .space FRAMEBUFFER_SIZE

.text
.globl main


#############
# GAME LOOP #
#############

main:
	jal paintBackground


	GAMELOOP:

		# PAINT GROUND
		add $a0, $zero, 0
		add $a1, $zero, 118
		jal paintGround

		# PAINT CLOUDS
		add $a0, $zero, 0
		add $a1, $zero, 0
		jal paintCloud
		add $a0, $zero, 25
		add $a1, $zero, 15
		jal paintCloud
		add $a0, $zero, 68
		add $a1, $zero, 7
		jal paintCloud
		add $a0, $zero, 92
		add $a1, $zero, 12
		jal paintCloud

		la $t0, player_info
		lw $t1, 0($t0)
		lw $t2, 4($t0)

		addi $sp, $sp, -4
		sw $t1, 0($sp)
		addi $sp, $sp, -4
		sw $t2, 0($sp)


		# UPDATE PLAYER PHYSICS
		jal handlePlayerPhysics
		# Player Inputs
		jal handlePlayerInputs
		# PLATFORM PHYSICS


		# Draw the player
		la $t0, player_info
		lw $a0, 0($t0) # get player X
		lw $a1, 4($t0) # get player Y
		jal paintCharacter

		# CLEAR PLAYER OLD PIXELS
		lw $a1, 0($sp)
		addi $sp, $sp, 4
		lw $a0, 0($sp)
		addi $sp, $sp, 4
		li $a2, CHARACTER_WIDTH
		li $a3, CHARACTER_HEIGHT
		jal clearArea

        # DRAW PLATFORMS


		# CLEAR THE PAINT & CLEAR BUFFERs
		jal clearPaintBuffer

		# SLEEP
		li $v0, 32
		li $a0, SLEEP_TIME
		syscall

		j GAMELOOP

###########
# PHYSICS #
###########

handlePlayerPhysics:
	la $t0, player_info
	lw $t1, 0($t0) # get player X
	lw $t2, 4($t0) # get player Y
	lw $t3, 8($t0) # get player velX
	lw $t4, 12($t0) # get player velY

	# Gravity
	sub $t4, $t4, GRAVITY
	li $t5, MAX_VELOCITY # load max velocity
	mul $t5, $t5, -1
	bgt $t4, $t5, NOCAP
	move $t4, $t5
	NOCAP:
		sw $t4, 12($t0)

	#Flip Y velocity
	mul $t4, $t4, -1

	# Add velocities
	add $t1, $t1, $t3
	add $t2, $t2, $t4

	# Left Collision
	bgt $t1, $zero, NOLEFTCOLL
	move $t1, $zero
	NOLEFTCOLL:

	# Right Collision
	add $s0, $t1, CHARACTER_WIDTH
	blt $s0, FRAME_MAX_WIDTH, NORIGHTCOLL
	li $t1, FRAME_MAX_WIDTH
	sub $t1, $t1, CHARACTER_WIDTH
	#move $t1, $s0
	NORIGHTCOLL:

	# Ground collision
	add $t3, $t2, CHARACTER_HEIGHT #calculate bottom of player
	li $t4, FRAME_MAX_HEIGHT
	sub $t4, $t4, 6
	blt $t3, $t4, NOGROUNDCAP
	li $t3, FRAME_MAX_HEIGHT
	sub $t3, $t3, 6
	sub $t3, $t3, CHARACTER_HEIGHT
	move $t2, $t3
	NOGROUNDCAP:

	# Update Position
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	#Reset X Velocity
	sw $zero, 8($t0)
	jr $ra




####################
# HELPER FUNCTIONS #
####################

resetGame:
	la $t0, player_info
	li $t1, 0
	li $t2, 25
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	jal clearPaintBuffer
	j main

# Player Inputs
handlePlayerInputs:
	move $s0, $ra

	jal getKeyInput
	la $t1, player_info
	beq $v0, 0x20, respond_to_space
	beq $v0, 0x61, respond_to_a
	beq $v0, 0x64, respond_to_d
	beq $v0, 0x70, respond_to_p

	j returnInput

	respond_to_space:
		li $t0, JETPACK_STRENGTH
		sw $t0, 12($t1)
		j returnInput
	respond_to_a:
		li $t0, -3
		sw $t0, 8($t1)
		j returnInput
	respond_to_d:
		li $t0, 3
		sw $t0, 8($t1)
		j returnInput
	respond_to_p:
		j resetGame

	returnInput:
	move $ra, $s0
	jr $ra
# Input Detection
getKeyInput:
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened
	li $v0, 0
	jr $ra
	keypress_happened:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
	move $v0, $t2
	jr $ra

# Utility

convertXYToOffset:
	# x in $a0
	# y in $a1

	# Calculate Y offset
	add $t0, $zero, $a1
	sll $t0, $t0, 9
	# Calculate X offset
	add $t1, $zero, $a0
	sll $t1, $t1, 2
	# Sum
	add $t0, $t0, $t1
	move $v0, $t0
	jr $ra

# Graphics Buffer Functions

clearArea:
	# save RA
	move $t7, $ra
	move $s3, $a0 # get player X
	move $s4, $a1 # get player Y
	li $s7, BASE_ADDRESS
	li $s1, 0 # x = 0
	li $s2, 0 # y = 0
	la $k0, paintBuffer
	li $t8, BACKGROUND_COLOR
	clearAreaLoop: bgt $s1, $a2, clearAreaExit # loop while x < CHARACTER_WIDTH

		clearAreaLoop2: bgt $s2, $a3, clearAreaExit2 # loop while y < CHARACTER_HEIGHT

			add $a0, $s1, $s3 # player x + x
			add $a1, $s2, $s4 # player y + y
			jal convertXYToOffset
			add $s5, $k0, $v0 # add increment to paint buffer
			lw $s6, 0($s5) # load paint buffer value
			bne $s6, 0, afterClearArea

			# clear pixel
			add $t9, $s7, $v0 # add increment to base
			sw $t8, 0($t9)

			afterClearArea:
			add $s2, $s2, 1
			j clearAreaLoop2
		clearAreaExit2:

		add $s1, $s1, 1
		li $s2, 0 # y = 0
		j clearAreaLoop
	clearAreaExit:

	move $ra, $t7
	jr $ra


clearPaintBuffer:
	li $t1, 0
	add $t2, $zero, $zero # i = 0 in $t2
	li $t3, FRAMEBUFFER_SIZE # framebuffer size in $t3
	clearPaintBufferLoop: bgt $t2, $t3, clearPaintBufferExit # loop until end of framebuffer
		la $t0, paintBuffer # load address of paint buffer
		add $t0, $t0, $t2  # add increment to address
		sw $t1, 0($t0) # set to 0
		add $t2, $t2, 4 # increment i by 4
		j clearPaintBufferLoop
	clearPaintBufferExit: jr $ra



# Painting Functions

paintPixel:
	#store $ra
	move $t2, $ra
	# x in $a0
	# y in $a1
	# color in $a2
	jal convertXYToOffset
	li $t0, BASE_ADDRESS
	add $t1, $t0, $v0
	sw $a2, 0($t1)

	# Update paint buffer
	la $t0, paintBuffer
	add $t0, $t0, $v0
	li $t1, 1
	sw $t1, 0($t0) # update value in paint buffer to 1

	move $ra, $t2
	jr $ra

paintBackground:
	li $t1, BACKGROUND_COLOR # background color in $t1
	add $t2, $zero, $zero # i = 0 in $t2
	li $t3, FRAMEBUFFER_SIZE # framebuffer size in $t3
	paintBackgroundLoop: bgt $t2, $t3, paintBackgroundExit # loop until end of framebuffer
		li $t0, BASE_ADDRESS # base address in $t0
		add $t0, $t0, $t2  # add increment to address
		sw $t1, 0($t0) # color the tile
		add $t2, $t2, 4 # increment i by 4
		j paintBackgroundLoop
	paintBackgroundExit: jr $ra

paintPlatform:
	# x in $a0
	# y in $a1

	#store x and y and $ra
	move $t6, $a0
	move $t7, $a1
	move $t5, $ra

	# Paint the platform
	add $a0, $t6, 3
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 0
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 0
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 0
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 0
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 0
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 0
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 0
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 0
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 0
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 1
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 1
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 1
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 1
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 1
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 1
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 1
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 1
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 1
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 1
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 1
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 1
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 1
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 1
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 1
li $a2, 0x215c0b
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 1
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 1
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 2
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 2
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 2
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 2
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 2
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 2
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 3
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 3
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 3
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 4
li $a2, 0x523522
jal paintPixel

	move $ra, $t5
	jr $ra


paintCharacter:
	# x in $a0
	# y in $a1

	#store x and y and $ra
	move $t6, $a0
	move $t7, $a1
	move $t5, $ra

	# Paint the character
	add $a0, $t6, 5
add $a1, $t7, 1
li $a2, 0xf26166
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 1
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 1
li $a2, 0xd11b24
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 1
li $a2, 0xd11b24
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 2
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 2
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 2
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 2
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 2
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 3
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 3
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 3
li $a2, 0x1debeb
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 3
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 3
li $a2, 0x1debeb
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 4
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 4
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 4
li $a2, 0xffea8f
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 4
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 4
li $a2, 0xffea8f
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 5
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 5
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 5
li $a2, 0xb29d42
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 5
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 5
li $a2, 0xb29d42
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 6
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 6
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 6
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 6
li $a2, 0xb29d42
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 7
li $a2, 0xa3151c
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 7
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 7
li $a2, 0xcc1a23
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 7
li $a2, 0xcc1a23
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 7
li $a2, 0xf26166
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 7
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 7
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 7
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 8
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 8
li $a2, 0xb29d42
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 8
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 8
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 8
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 8
li $a2, 0x91f5f5
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 8
li $a2, 0x1debeb
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 8
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 8
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 9
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 9
li $a2, 0x1debeb
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 9
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 9
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 9
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 9
li $a2, 0x1debeb
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 9
li $a2, 0x91f5f5
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 9
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 9
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 9
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 10
li $a2, 0xc05b5e
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 10
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 10
li $a2, 0xb29d42
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 10
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 10
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 10
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 10
li $a2, 0xb29d42
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 10
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 10
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 11
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 11
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 11
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 11
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 11
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 11
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 11
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 11
li $a2, 0xcc1a23
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 12
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 12
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 12
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 12
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 12
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 12
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 12
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 13
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 13
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 13
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 13
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 13
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 14
li $a2, 0xba1820
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 14
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 14
li $a2, 0xffe15e
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 14
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 15
li $a2, 0xf2ce4b
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 15
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 15
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 15
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 16
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 16
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 16
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 16
li $a2, 0xed1c24
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 17
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 17
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 17
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 17
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 17
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 17
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 18
li $a2, 0xdebeb
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 18
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 18
li $a2, 0xa51419
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 19
li $a2, 0xdebeb
jal paintPixel

	move $ra, $t5
	jr $ra

paintCloud:
	# x in $a0
	# y in $a1

	#store x and y and $ra
	move $t6, $a0
	move $t7, $a1
	move $t5, $ra

	# Paint the cloud
	add $a0, $t6, 11
add $a1, $t7, 1
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 1
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 1
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 1
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 2
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 2
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 2
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 2
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 2
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 2
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 2
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 3
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 3
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 3
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 3
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 3
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 3
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 3
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 3
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 3
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 4
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 4
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 4
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 4
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 4
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 5
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 5
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 5
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 6
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 6
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 6
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 6
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 6
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 6
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 6
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 7
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 7
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 7
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 7
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 7
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 7
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 7
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 8
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 8
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 8
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 8
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 8
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 8
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 8
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 8
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 9
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 9
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 9
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 9
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 9
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 9
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 9
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 10
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 10
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 10
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 10
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 10
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 10
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 11
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 11
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 11
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 11
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 11
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 11
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 11
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 12
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 12
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 12
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 13
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 13
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 13
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 13
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 13
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 13
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 13
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 13
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 13
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 13
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 14
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 14
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 14
li $a2, 0xcff1ff
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 14
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 14
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 14
li $a2, 0xffffff
jal paintPixel


	move $ra, $t5
	jr $ra


paintGround:
	#store x and y and $ra
	move $t6, $a0
	move $t7, $a1
	move $t5, $ra

	# Paint the ground
	add $a0, $t6, 8
add $a1, $t7, 0
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 0
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 0
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 0
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 1
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 2
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 39
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 2
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 2
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 112
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 113
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 114
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 117
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 118
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 119
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 120
add $a1, $t7, 2
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 121
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 122
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 123
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 2
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 126
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 127
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 128
add $a1, $t7, 2
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 3
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 39
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 3
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 3
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 3
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 3
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 112
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 113
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 114
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 117
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 118
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 119
add $a1, $t7, 3
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 120
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 121
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 122
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 123
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 126
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 127
add $a1, $t7, 3
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 128
add $a1, $t7, 3
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 4
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 4
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 4
li $a2, 0xff82c9
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 39
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 4
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 4
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 4
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 112
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 113
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 114
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 117
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 118
add $a1, $t7, 4
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 119
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 120
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 121
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 122
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 123
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 4
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 126
add $a1, $t7, 4
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 127
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 128
add $a1, $t7, 4
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 5
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 5
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 5
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 5
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 39
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 5
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 5
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 5
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 5
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 5
li $a2, 0x45ab20
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 5
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 5
li $a2, 0x265c12
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 112
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 113
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 114
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 117
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 118
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 119
add $a1, $t7, 5
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 120
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 121
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 122
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 123
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 126
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 127
add $a1, $t7, 5
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 128
add $a1, $t7, 5
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 39
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 6
li $a2, 0x35801a
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 112
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 113
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 114
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 117
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 118
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 119
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 120
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 121
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 122
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 123
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 126
add $a1, $t7, 6
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 127
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 128
add $a1, $t7, 6
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 39
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 112
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 113
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 114
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 117
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 118
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 119
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 120
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 121
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 122
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 123
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 126
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 127
add $a1, $t7, 7
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 128
add $a1, $t7, 7
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 39
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 112
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 113
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 114
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 117
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 118
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 119
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 120
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 121
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 122
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 123
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 126
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 127
add $a1, $t7, 8
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 128
add $a1, $t7, 8
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 39
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 112
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 113
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 114
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 115
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 116
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 117
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 118
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 119
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 120
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 121
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 122
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 123
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 124
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 125
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 126
add $a1, $t7, 9
li $a2, 0x70492f
jal paintPixel

add $a0, $t6, 127
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

add $a0, $t6, 128
add $a1, $t7, 9
li $a2, 0x5c3c27
jal paintPixel

	move $ra, $t5
	jr $ra
















