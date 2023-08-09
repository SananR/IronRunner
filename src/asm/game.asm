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
# - Milestones 1-3
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Fail Condition w/ Game Over Screen (1pt)
# 2. Moving Objects (enemies) (2 pts)
# 3. Moving Platforms (2 pts)
# 4. Jetpack w/ parabolic motion (2 pts)
# 5. Animated sprites (enemies, player jetpack) (2 pts)
#
# Link to video demonstration for final submission:
# - https://youtu.be/uwmmsh78KPE
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
# https://github.com/SananR/IronRunner/
#
# Any additional information that the TA needs to know:
# - Will severely lag Mars due to being over 26k lines of code :(
# - If anything goes wrong, or my video doesn't work or anything like that
# - you can contact me 4039669126, or raosanan@gmail.com 
#
#####################################################################

# Internal Settings
.eqv BASE_ADDRESS 0x10008000
.eqv SLEEP_TIME 1

# Physics Settings
.eqv GRAVITY 1
.eqv MAX_VELOCITY 5
.eqv JETPACK_STRENGTH 5

# #
.eqv BACKGROUND_COLOR  0x00b7ef
.eqv FRAMEBUFFER_SIZE 65532

.eqv FRAME_MAX_WIDTH 127
.eqv FRAME_MAX_HEIGHT 127

# ROCKET
.eqv ROCKET_WIDTH 20
.eqv ROCKET_HEIGHT 10

# Player Character
.eqv CHARACTER_WIDTH 10
.eqv CHARACTER_HEIGHT 20

# Platform
.eqv PLATFORM_WIDTH 32
.eqv PLATFORM_HEIGHT 5

.data
	padding: .space FRAMEBUFFER_SIZE

	# State
	player_info: .word 25, 25, 0, 0 # X, Y, velX, velY
	jetpack_fire: .word 1, -50, 0, 0, 0  # active, X, Y, frame, ticks 
	platform0: .word 130, 40, -1 # X, Y, velX
	platform1: .word 130, 80, -2 # X, Y, velX
	rocket0: .word 130, 100, -3
	rocket0_fire: .word 1, -50, 0, 0, 0  # active, X, Y, frame, ticks 
	gameover: .word 0

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
		
		# Game Over Screen
		la $a0, gameover
		lw $a0, 0($a0)
		bne $a0, 1, GAMENOTOVER
		
		#jal paintBackground
		jal paintGameOver
		jal handlePlayerInputs
		j GAMELOOP

		GAMENOTOVER:


		# PAINT GROUND
		add $a0, $zero, -1
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
		
		# Push old rockets X and Y to stack
		la $t0, rocket0
		lw $t1, 0($t0)
		lw $t2, 4($t0)

		addi $sp, $sp, -4
		sw $t1, 0($sp)
		addi $sp, $sp, -4
		sw $t2, 0($sp)
		
		# Push old platforms X and Y to stack
		la $t0, platform0
		lw $t1, 0($t0)
		lw $t2, 4($t0)

		addi $sp, $sp, -4
		sw $t1, 0($sp)
		addi $sp, $sp, -4
		sw $t2, 0($sp)
		
		la $t0, platform1
		lw $t1, 0($t0)
		lw $t2, 4($t0)

		addi $sp, $sp, -4
		sw $t1, 0($sp)
		addi $sp, $sp, -4
		sw $t2, 0($sp)

		# Push old player X and Y to stack
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
		jal handlePlatformPhysics
		# ROCKET PHYSICS
		jal handleRocketPhysics
		
		# JETPACK ANIMATION
		jal handleJetpackAnimation
		# ROCKET0 ANIMATION
		jal handleRocket0Animation
		
		
		# Draw platforms
		la $t0, platform0
		lw $a0, 0($t0) # get platform X
		lw $a1, 4($t0) # get platform Y
		jal paintPlatform
		la $t0, platform1
		lw $a0, 0($t0) # get platform X
		lw $a1, 4($t0) # get platform Y
		jal paintPlatform

		# Draw the player
		la $t0, player_info
		lw $a0, 0($t0) # get player X
		lw $a1, 4($t0) # get player Y
		jal paintCharacter

		# Draw the rockets
		la $t0, rocket0
		lw $a0, 0($t0) # get X
		lw $a1, 4($t0) # get Y
		jal paintRocket
		
		# Draw Jetpack Fire
		la $t0, jetpack_fire
		lw $a0, 4($t0) # get X
		lw $a1, 8($t0) # get Y
		lw $a2, 12($t0) # get Y
		jal paintJetpackFire
		
		# Draw Rocket0 Fire
		la $t0, rocket0_fire
		lw $a0, 4($t0) # get X
		lw $a1, 8($t0) # get Y
		lw $a2, 12($t0) # get Y
		jal paintRocket0Fire

		# CLEAR PLAYER OLD PIXELS
		lw $a1, 0($sp)
		addi $sp, $sp, 4
		lw $a0, 0($sp)
		addi $sp, $sp, 4
		li $a2, CHARACTER_WIDTH
		li $a3, CHARACTER_HEIGHT
		add $a3, $a3, 5
		jal clearArea

        # CLEAR OLD PLATFORM PIXELS
        lw $a1, 0($sp)
		addi $sp, $sp, 4
		lw $a0, 0($sp)
		addi $sp, $sp, 4
		li $a2, PLATFORM_WIDTH
		li $a3, PLATFORM_HEIGHT
		jal clearArea
        lw $a1, 0($sp)
		addi $sp, $sp, 4
		lw $a0, 0($sp)
		addi $sp, $sp, 4
		jal clearArea
		
        # CLEAR OLD ROCKET PIXELS
        lw $a1, 0($sp)
		addi $sp, $sp, 4
		lw $a0, 0($sp)
		addi $sp, $sp, 4
		li $a2, ROCKET_WIDTH
		li $a3, ROCKET_HEIGHT
		add $a2, $a2, 5
		jal clearArea

		# CLEAR THE PAINT BUFFER
		jal clearPaintBuffer

		# SLEEP
		li $v0, 32
		li $a0, SLEEP_TIME
		syscall

		j GAMELOOP



##############
# ANIMATIONS #
##############
handleRocket0Animation:
	#save ra
	move $t8, $ra
	
	la $t0, rocket0_fire
	lw $t1, 0($t0) # get active
	
	beq $t1, $zero, ROCKET0FIRENOTACTIVE 
	
	# Set x and y to rocket0
	la $t2, rocket0
	lw $t3, 0($t2)
	add $t3, $t3, 5
	sw $t3, 4($t0)
	lw $t3, 4($t2)
	sw $t3, 8($t0)
	
	lw $t4, 12($t0) # get frame
	lw $t5, 16($t0) # get ticks
	
	add $t5, $t5, 1
	bge $t5, 1, ROCKET0FIRELOOP
	sw $t5, 16($t0)
	j ROCKET0FIREAFTER
	
	ROCKET0FIRELOOP:
	li $t3, 1
	slt $t2, $t4, $t3
	sw $t2, 12($t0)
	sw $zero, 16($t0)
	j ROCKET0FIREAFTER
	
	ROCKET0FIRENOTACTIVE:
	
	li $t2, -50
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	
	
	ROCKET0FIREAFTER:
	
	move $ra, $t8
	jr $ra
	
handleJetpackAnimation:
	#save ra
	move $t8, $ra
	
	la $t0, jetpack_fire
	lw $t1, 0($t0) # get active
	
	beq $t1, $zero, JETPACKNOTACTIVE 
	
	# Set x and y to player
	la $t2, player_info
	lw $t3, 0($t2)
	sw $t3, 4($t0)
	lw $t3, 4($t2)
	add $t3, $t3, 5
	sw $t3, 8($t0)
	
	lw $t4, 12($t0) # get frame
	lw $t5, 16($t0) # get ticks
	
	add $t5, $t5, 1
	bge $t5, 1, JETPACKLOOP
	sw $t5, 16($t0)
	j JETPACKAFTER
	
	JETPACKLOOP:
	li $t3, 1
	slt $t2, $t4, $t3
	sw $t2, 12($t0)
	sw $zero, 16($t0)
	j JETPACKAFTER
	
	JETPACKNOTACTIVE:
	
	li $t2, -50
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	
	
	JETPACKAFTER:
	
	move $ra, $t8
	jr $ra




###########
# PHYSICS #
###########

handleRocketPhysics:
	#save ra
	move $t7, $ra
	la $t0, rocket0
	lw $t1, 0($t0) # get rocket0 X
	lw $t2, 4($t0) # get rocket0 Y
	lw $t3, 8($t0) # get rocket0 velX
	
	# Add velocity
	add $t1, $t1, $t3

	# Left Collision
	li $s0, ROCKET_WIDTH
	mul $s0, $s0, -1
	bgt $t1, $s0, NOLEFTCOLLROCKET
	# Random Y
	li $a0, 110
	jal randomNumber
	move $t2, $v0
	# Random X
	li $a0, 100
	jal randomNumber
	li $t1, FRAME_MAX_WIDTH
	add $t1, $t1, $v0
	# Random Velocity
	li $a0, 10
	jal randomNumber
	addi $v0, $v0, 3
	mul $v0, $v0, -1
	move $t3, $v0
	
	NOLEFTCOLLROCKET:

	# Update Position
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t3, 8($t0)
	
	move $ra, $t7
	jr $ra
	
handlePlatformPhysics:
	# save ra
	move $t7, $ra
	# Platform 0
	la $t0, platform0
	lw $t1, 0($t0) # get platform0 X
	lw $t2, 4($t0) # get platform0 Y
	lw $t3, 8($t0) # get platform0 velX
	
	# Add velocity
	add $t1, $t1, $t3

	# Left Collision
	li $s0, PLATFORM_WIDTH
	mul $s0, $s0, -1
	bgt $t1, $s0, NOLEFTCOLLPLATFORM0	
	# Random X
	li $a0, 200
	jal randomNumber
	li $t1, FRAME_MAX_WIDTH
	add $t1, $t1, $v0
	
	# Random velocity
	li $a0, 4
	jal randomNumber
	addi $v0, $v0, 1
	mul $v0, $v0, -1
	move $t3, $v0
	NOLEFTCOLLPLATFORM0:

	# Update Position
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t3, 8($t0)
	
	# Platform 1
	la $t0, platform1
	lw $t1, 0($t0) # get platform1 X
	lw $t2, 4($t0) # get platform1 Y
	lw $t3, 8($t0) # get platform1 velX
	
	# Add velocity
	add $t1, $t1, $t3

	# Left Collision
	li $s0, PLATFORM_WIDTH
	mul $s0, $s0, -1
	bgt $t1, $s0, NOLEFTCOLLPLATFORM1
	# Random X
	li $a0, 200
	jal randomNumber
	li $t1, FRAME_MAX_WIDTH
	add $t1, $t1, $v0
	
	# Random velocity
	li $a0, 4
	jal randomNumber
	addi $v0, $v0, 1
	mul $v0, $v0, -1
	move $t3, $v0
	NOLEFTCOLLPLATFORM1:

	# Update Position
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t3, 8($t0)
	
	move $ra, $t7
	jr $ra

handlePlayerPhysics:
	# store $ra
	move $t9, $ra
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

	# Add y velocity
	add $t2, $t2, $t4
	sw $t2, 4($t0)
	
	# push all to stack
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	addi $sp, $sp, -4
	sw $t3, 0($sp)
	addi $sp, $sp, -4
	sw $t4, 0($sp)
	
	# Platform0 Collision (Y)
	jal platform0Collision
	
	# restore values
	lw $t4, 0($sp)
	addi $sp, $sp, 4
	lw $t3, 0($sp)
	addi $sp, $sp, 4
	lw $t2, 0($sp)
	addi $sp, $sp, 4
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, noPlatform0Collision
	blt $t4, 0, noPlatform0Collision
	la $s1, platform0
	lw $s2, 4($s1)
	sub $s2, $s2, CHARACTER_HEIGHT
	move $t2, $s2
	noPlatform0Collision:
	
	# push all to stack
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	addi $sp, $sp, -4
	sw $t3, 0($sp)
	addi $sp, $sp, -4
	sw $t4, 0($sp)
	
	# Platform1 Collision (Y)
	jal platform1Collision
	
	# restore values
	lw $t4, 0($sp)
	addi $sp, $sp, 4
	lw $t3, 0($sp)
	addi $sp, $sp, 4
	lw $t2, 0($sp)
	addi $sp, $sp, 4
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, noPlatform1Collision
	blt $t4, 0, noPlatform1Collision
	la $s1, platform1
	lw $s2, 4($s1)
	sub $s2, $s2, CHARACTER_HEIGHT
	move $t2, $s2
	noPlatform1Collision:
	
	add $t1, $t1, $t3 # add x velocity
	
	# Left Collision
	bgt $t1, $zero, NOLEFTCOLLPLAYER
	move $t1, $zero
	NOLEFTCOLLPLAYER:

	# Right Collision
	add $s0, $t1, CHARACTER_WIDTH
	blt $s0, FRAME_MAX_WIDTH, NORIGHTCOLLPLAYER
	li $t1, FRAME_MAX_WIDTH
	sub $t1, $t1, CHARACTER_WIDTH
	#move $t1, $s0
	NORIGHTCOLLPLAYER:

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
	
	# Top collision
	bgt $t2, $zero, NOCEILCAP
	li $t3, FRAME_MAX_HEIGHT
	move $t2, $zero
	NOCEILCAP:

	# Rocket0 Collision
	# push all to stack
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	addi $sp, $sp, -4
	sw $t3, 0($sp)
	addi $sp, $sp, -4
	sw $t4, 0($sp)
	
	# Rocket0 Collision (Y)
	jal rocket0Collision
	
	# restore values
	lw $t4, 0($sp)
	addi $sp, $sp, 4
	lw $t3, 0($sp)
	addi $sp, $sp, 4
	lw $t2, 0($sp)
	addi $sp, $sp, 4
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	beq $v0, 0, noRocket0Collision
	blt $t4, 0, noRocket0Collision
	la $v0, gameover
	li $v1, 1
	sw $v1, 0($v0)
	noRocket0Collision:

	# Update Position
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	#Reset X Velocity
	sw $zero, 8($t0)
	
	move $ra, $t9
	jr $ra

##############
# COLLISIONS #
##############

rocket0Collision:
	la $t0, player_info
	lw $t1, 0($t0) # player Left
	lw $t2, 4($t0) # player Top
	add $t3, $t1, CHARACTER_WIDTH # player Right
	add $t4, $t2, CHARACTER_HEIGHT # player Bottom
	sub $t4, $t4, 2
	add $t2, $t2, 2
	
	la $t0, rocket0
	lw $s1, 0($t0) # rocket0 Left
	lw $s2, 4($t0) # rocket0 Top
	add $s3, $s1, ROCKET_WIDTH # rocket0 Right
	add $s4, $s2, ROCKET_HEIGHT # rocket0 Bottom
	
	bgt $t1, $s3, rocket0NoIntersect
	bgt $s1, $t3, rocket0NoIntersect
	bgt $t2, $s4, rocket0NoIntersect
	bgt $s2, $t4, rocket0NoIntersect
	
	rocket0YesIntersect:
	li $v0, 1
	jr $ra
	rocket0NoIntersect:
	li $v0, 0
	jr $ra

platform1Collision:
	la $t0, player_info
	lw $t1, 0($t0) # player Left
	lw $t2, 4($t0) # player Top
	add $t3, $t1, CHARACTER_WIDTH # player Right
	add $t4, $t2, CHARACTER_HEIGHT # player Bottom
	sub $t4, $t4, 2
	
	la $t0, platform1
	lw $s1, 0($t0) # platform1 Left
	lw $s2, 4($t0) # platform1 Top
	add $s3, $s1, PLATFORM_WIDTH # platform1 Right
	add $s4, $s2, PLATFORM_HEIGHT # platform1 Bottom
	
	bgt $t1, $s3, platform1NoIntersect
	bgt $s1, $t3, platform1NoIntersect
	bgt $t2, $s4, platform1NoIntersect
	bgt $s2, $t4, platform1NoIntersect
	
	platform1YesIntersect:
	li $v0, 1
	jr $ra
	platform1NoIntersect:
	li $v0, 0
	jr $ra
	
platform0Collision:
	la $t0, player_info
	lw $t1, 0($t0) # player Left
	lw $t2, 4($t0) # player Top
	add $t3, $t1, CHARACTER_WIDTH # player Right
	add $t4, $t2, CHARACTER_HEIGHT # player Bottom
	sub $t4, $t4, 2
	
	la $t0, platform0
	lw $s1, 0($t0) # platform0 Left
	lw $s2, 4($t0) # platform0 Top
	add $s3, $s1, PLATFORM_WIDTH # platform0 Right
	add $s4, $s2, PLATFORM_HEIGHT # platform0 Bottom
	
	bgt $t1, $s3, platform0NoIntersect
	bgt $s1, $t3, platform0NoIntersect
	bgt $t2, $s4, platform0NoIntersect
	bgt $s2, $t4, platform0NoIntersect
	
	platform0YesIntersect:
	li $v0, 1
	jr $ra
	platform0NoIntersect:
	li $v0, 0
	jr $ra
	


####################
# HELPER FUNCTIONS #
####################

randomNumber:
	move $a1, $a0
	li $v0, 42
	li $a0, 0
	syscall
	move $v0, $a0
	jr $ra

resetGame:
	la $t0, player_info
	li $t1, 0
	li $t2, 25
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	la $t0, platform0
	li $t1, 130
	sw $t1, 0($t0)
	li $t1, 40
	sw $t1, 4($t0)
	li $t1, -1
	sw $t1, 8($t0)
	la $t0, platform1
	li $t1, 130
	sw $t1, 0($t0)
	li $t1, 80
	sw $t1, 4($t0)
	li $t1, -2
	sw $t1, 8($t0)
	la $t0, rocket0
	li $t1, 130
	sw $t1, 0($t0)
	li $t1, 100
	sw $t1, 4($t0)
	li $t1, -3
	sw $t1, 8($t0)
	la $t0, gameover
	sw $zero, 0($t0)
	
	jal clearPaintBuffer
	j main

# Player Inputs
handlePlayerInputs:
	move $s0, $ra

	# set fire not active
	la $t2, jetpack_fire
	sw $zero, 0($t2)
	
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
		# set fire active
		la $t2, jetpack_fire
		li $t3, 1
		sw $t3, 0($t2)
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
	
	# Skip pixels outside of the frame
	blt $a0, 0, SKIPPAINTPIXEL
	bgt $a0, FRAME_MAX_WIDTH, SKIPPAINTPIXEL
	blt $a1, 0, SKIPPAINTPIXEL
	bgt $a1, FRAME_MAX_HEIGHT, SKIPPAINTPIXEL
	
	jal convertXYToOffset
	li $t0, BASE_ADDRESS
	add $t1, $t0, $v0
	sw $a2, 0($t1)

	# Update paint buffer
	la $t0, paintBuffer
	add $t0, $t0, $v0
	li $t1, 1
	sw $t1, 0($t0) # update value in paint buffer to 1

	SKIPPAINTPIXEL:
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

paintGameOver:
	move $t5, $ra
	
	# Paint GameOver
	li $t6, 0
	li $t7, 0
	
	add $a0, $t6, 22
add $a0, $t6, 22
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 11
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 12
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 20
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 21
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 22
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 23
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 24
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 25
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 26
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 27
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 28
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 29
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 30
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 31
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 35
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 36
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 37
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 38
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 39
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 40
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 41
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 42
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 43
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 44
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 45
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 46
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 47
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 48
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 34
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 44
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 49
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 50
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 51
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 21
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 52
li $a2, 0xffde00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 86
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 92
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 102
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 109
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 110
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 111
add $a1, $t7, 52
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 53
li $a2, 0xffda00
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 53
li $a2, 0xffdc00
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 53
li $a2, 0xffdc00
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 53
li $a2, 0xffda00
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 53
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 54
li $a2, 0xffde00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 54
li $a2, 0xffe400
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 54
li $a2, 0xffe800
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 54
li $a2, 0xffe800
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 54
li $a2, 0xffe400
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 54
li $a2, 0xffde00
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 108
add $a1, $t7, 54
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 22
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 23
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 24
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 29
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 55
li $a2, 0xffde00
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 55
li $a2, 0xffeb00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 55
li $a2, 0xfff400
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 55
li $a2, 0xfff600
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 55
li $a2, 0xfff600
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 55
li $a2, 0xfff300
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 55
li $a2, 0xffea00
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 55
li $a2, 0xffde00
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 81
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 97
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 55
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 62
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 63
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 63
li $a2, 0x5c0f0f
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 63
li $a2, 0x521010
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 63
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 63
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 63
li $a2, 0x610d0d
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 63
li $a2, 0x600d0d
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 63
li $a2, 0x4d0909
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 63
li $a2, 0x600d0d
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 63
li $a2, 0x6b0f0f
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 63
li $a2, 0x6a0f0f
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 63
li $a2, 0x6b0f0f
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 63
li $a2, 0x6a0f0f
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 63
li $a2, 0x781111
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 63
li $a2, 0x600d0d
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 63
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 63
li $a2, 0x5a0e0e
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 63
li $a2, 0x7c1515
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 63
li $a2, 0x7c1515
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 63
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 64
li $a2, 0x881616
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 64
li $a2, 0x811010
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 64
li $a2, 0x780202
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 64
li $a2, 0x780202
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 64
li $a2, 0x960404
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 64
li $a2, 0x860303
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 64
li $a2, 0x860303
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 64
li $a2, 0x950404
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 64
li $a2, 0x910404
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 64
li $a2, 0x900404
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 64
li $a2, 0x730202
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 64
li $a2, 0x7f0303
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 64
li $a2, 0xad0e0e
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 64
li $a2, 0x921616
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 64
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 64
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 65
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 65
li $a2, 0x7a1515
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 65
li $a2, 0x891818
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 65
li $a2, 0x721111
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 65
li $a2, 0x7e0f0f
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 65
li $a2, 0x990707
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 65
li $a2, 0xa20000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 65
li $a2, 0xa50000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 65
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 65
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 65
li $a2, 0xb80000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 65
li $a2, 0xb80000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 65
li $a2, 0xb80000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 65
li $a2, 0xa50000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 65
li $a2, 0xa50000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 65
li $a2, 0x940000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 65
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 65
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 65
li $a2, 0x840000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 65
li $a2, 0xa20000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 65
li $a2, 0xa20a0a
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 65
li $a2, 0x931515
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 65
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 65
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 65
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 65
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 66
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 66
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 66
li $a2, 0x8a1818
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 66
li $a2, 0x841313
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 66
li $a2, 0x8b0a0a
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 66
li $a2, 0xa90202
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 66
li $a2, 0xcb0000
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 66
li $a2, 0xcd0000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 66
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 66
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 66
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 66
li $a2, 0xb80000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 66
li $a2, 0xb80000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 66
li $a2, 0xb80000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 66
li $a2, 0xb80000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 66
li $a2, 0xb80000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 66
li $a2, 0xb60000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 66
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 66
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 66
li $a2, 0xd60404
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 66
li $a2, 0xa30000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 66
li $a2, 0x810000
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 66
li $a2, 0x680505
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 66
li $a2, 0x841212
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 66
li $a2, 0x7d1515
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 66
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 66
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 66
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 67
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 67
li $a2, 0x941a1a
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 67
li $a2, 0x7b1414
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 67
li $a2, 0x781111
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 67
li $a2, 0x940808
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 67
li $a2, 0xfb0101
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 67
li $a2, 0xe30000
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 67
li $a2, 0x9e4606
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 67
li $a2, 0xaf713f
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 67
li $a2, 0xc88a45
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 67
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 67
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 67
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 67
li $a2, 0xcd0000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 67
li $a2, 0xcd0000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 67
li $a2, 0xcd0000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 67
li $a2, 0xcb0000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 67
li $a2, 0xe00808
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 67
li $a2, 0xdb7f2d
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 67
li $a2, 0xc17e34
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 67
li $a2, 0xc27a2f
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 67
li $a2, 0xce6c1a
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 67
li $a2, 0xca0000
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 67
li $a2, 0xb50000
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 67
li $a2, 0x940808
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 67
li $a2, 0x931515
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 67
li $a2, 0x7d1515
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 67
li $a2, 0x7c1515
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 67
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 67
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 68
li $a2, 0x761414
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 68
li $a2, 0x7e1313
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 68
li $a2, 0xb10e0e
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 68
li $a2, 0xe10000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 68
li $a2, 0xb5835a
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 68
li $a2, 0xceaa6f
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 68
li $a2, 0xf6e885
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 68
li $a2, 0xfaed6f
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 68
li $a2, 0xffdb05
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 68
li $a2, 0xcd0000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 68
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 68
li $a2, 0xd69c4a
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 68
li $a2, 0xd7ab56
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 68
li $a2, 0xdaaf58
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 68
li $a2, 0xd69845
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 68
li $a2, 0xce6c1a
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 68
li $a2, 0xa60a0a
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 68
li $a2, 0x961515
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 68
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 68
li $a2, 0x7c1515
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 68
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 69
li $a2, 0x741212
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 69
li $a2, 0xa81414
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 69
li $a2, 0xd40404
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 69
li $a2, 0xb50000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 69
li $a2, 0x3d3d3d
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 69
li $a2, 0xc9aa78
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 69
li $a2, 0xf5f09c
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 69
li $a2, 0xf8f79d
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 69
li $a2, 0xf6f663
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 69
li $a2, 0xfbf231
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 69
li $a2, 0xe5c85d
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 69
li $a2, 0xeee26d
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 69
li $a2, 0xefe56f
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 69
li $a2, 0xe2c45f
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 69
li $a2, 0xdd9c40
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 69
li $a2, 0xf5760d
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 69
li $a2, 0xca0000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 69
li $a2, 0xb80c0c
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 69
li $a2, 0x931515
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 69
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 69
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 70
li $a2, 0x951515
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 70
li $a2, 0xb70808
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 70
li $a2, 0x9f6030
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 70
li $a2, 0xb57b41
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 70
li $a2, 0xead590
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 70
li $a2, 0xf8f79e
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 70
li $a2, 0xf9f99e
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 70
li $a2, 0xf7f772
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 70
li $a2, 0xf9f94b
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 70
li $a2, 0xe7ca55
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 70
li $a2, 0xf1e86f
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 70
li $a2, 0xf4ee72
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 70
li $a2, 0xf0e970
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 70
li $a2, 0xe3c257
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 70
li $a2, 0xe4992d
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 70
li $a2, 0xe26a02
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 70
li $a2, 0x960808
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 70
li $a2, 0x971616
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 70
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 71
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 71
li $a2, 0x801515
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 71
li $a2, 0x9c0c0c
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 71
li $a2, 0xbc0000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 71
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 71
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 71
li $a2, 0x9d6235
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 71
li $a2, 0xddb684
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 71
li $a2, 0xf6f29d
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 71
li $a2, 0xf9f99e
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 71
li $a2, 0xf9f99e
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 71
li $a2, 0xf7f772
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 71
li $a2, 0xf9f94b
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 71
li $a2, 0xfefe59
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 71
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 71
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 71
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 71
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 71
li $a2, 0xffff51
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 71
li $a2, 0xfcfc77
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 71
li $a2, 0xf1e261
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 71
li $a2, 0xf4f171
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 71
li $a2, 0xf4f274
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 71
li $a2, 0xf3ec6d
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 71
li $a2, 0xe2b64a
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 71
li $a2, 0xe48723
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 71
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 71
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 71
li $a2, 0xc20000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 71
li $a2, 0xab0c0c
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 71
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 72
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 72
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 72
li $a2, 0x961515
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 72
li $a2, 0xb30606
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 72
li $a2, 0xc60000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 72
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 72
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 72
li $a2, 0xc27942
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 72
li $a2, 0xe1c289
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 72
li $a2, 0xf8f69e
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 72
li $a2, 0xf9f99e
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 72
li $a2, 0xfbfbbb
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 72
li $a2, 0xfafa92
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 72
li $a2, 0xfdfd6f
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 72
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 72
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 72
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 72
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 72
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 72
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 72
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 72
li $a2, 0xfbfb3b
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 72
li $a2, 0xf5f060
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 72
li $a2, 0xf5f36f
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 72
li $a2, 0xf4f272
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 72
li $a2, 0xe6cd5f
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 72
li $a2, 0xd58e3f
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 72
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 72
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 72
li $a2, 0xb70000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 72
li $a2, 0xb00707
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 72
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 73
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 73
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 73
li $a2, 0x901010
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 73
li $a2, 0xb90202
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 73
li $a2, 0xcb0808
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 73
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 73
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 73
li $a2, 0xd5a37c
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 73
li $a2, 0xe6ce8e
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 73
li $a2, 0xf8f79e
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 73
li $a2, 0xf9f99d
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 73
li $a2, 0xf9f95e
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 73
li $a2, 0xfcfc33
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 73
li $a2, 0xffff07
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 73
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 73
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 73
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 73
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 73
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 73
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 73
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 73
li $a2, 0xffff51
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 73
li $a2, 0xfbfb3a
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 73
li $a2, 0xf7f35f
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 73
li $a2, 0xf5f270
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 73
li $a2, 0xecdf6b
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 73
li $a2, 0xce9048
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 73
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 73
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 73
li $a2, 0xcb0000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 73
li $a2, 0x900505
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 73
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 73
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 74
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 74
li $a2, 0x921717
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 74
li $a2, 0xa80a0a
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 74
li $a2, 0xcb0000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 74
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 74
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 74
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 74
li $a2, 0xdaae80
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 74
li $a2, 0xecdb92
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 74
li $a2, 0xf8f89d
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 74
li $a2, 0xfbfb84
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 74
li $a2, 0xfefe18
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 74
li $a2, 0xffff04
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 74
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 74
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 74
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 74
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 74
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 74
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 74
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 74
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 74
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 74
li $a2, 0xffff07
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 74
li $a2, 0xfafa43
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 74
li $a2, 0xf6f269
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 74
li $a2, 0xecdf6b
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 74
li $a2, 0xd6a755
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 74
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 74
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 74
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 74
li $a2, 0x980101
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 74
li $a2, 0x9a1313
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 74
li $a2, 0x9a1b1b
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 74
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 75
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 75
li $a2, 0x9f1717
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 75
li $a2, 0xa00606
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 75
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 75
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 75
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 75
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 75
li $a2, 0xdebd5e
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 75
li $a2, 0xf5ef97
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 75
li $a2, 0xfafa84
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 75
li $a2, 0xffff0a
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 75
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 75
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 75
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 75
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 75
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 75
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 75
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 75
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 75
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 75
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 75
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 75
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 75
li $a2, 0xfefe5d
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 75
li $a2, 0xf5ef53
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 75
li $a2, 0xeddf67
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 75
li $a2, 0xddb75a
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 75
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 75
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 75
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 75
li $a2, 0xb60000
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 75
li $a2, 0x860c0c
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 75
li $a2, 0x9a1a1a
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 75
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 76
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 76
li $a2, 0x951313
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 76
li $a2, 0xa20606
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 76
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 76
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 76
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 76
li $a2, 0xe2a236
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 76
li $a2, 0xf6ef84
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 76
li $a2, 0xfbfb77
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 76
li $a2, 0xffff53
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 76
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 76
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 76
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 76
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 76
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 76
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 76
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 76
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 76
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 76
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 76
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 76
li $a2, 0xffff4d
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 76
li $a2, 0xe5e545
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 76
li $a2, 0xe5e546
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 76
li $a2, 0xe3e323
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 76
li $a2, 0xf9f950
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 76
li $a2, 0xeac84b
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 76
li $a2, 0xedc83f
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 76
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 76
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 76
li $a2, 0xe40000
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 76
li $a2, 0x730707
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 76
li $a2, 0x9c1a1a
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 76
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 77
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 77
li $a2, 0x961313
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 77
li $a2, 0x9f0606
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 77
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 77
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 77
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 77
li $a2, 0xfcd157
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 77
li $a2, 0xfde858
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 77
li $a2, 0xffff4f
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 77
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 77
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 77
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 77
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 77
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 77
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 77
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 77
li $a2, 0xe5e403
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 77
li $a2, 0xe4e412
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 77
li $a2, 0xf7c91b
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 77
li $a2, 0xfbc911
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 77
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 77
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 77
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 77
li $a2, 0x860606
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 77
li $a2, 0x9e1919
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 77
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 78
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 78
li $a2, 0x961313
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 78
li $a2, 0xa20606
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 78
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 78
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 78
li $a2, 0xff8c00
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 78
li $a2, 0xffd44d
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 78
li $a2, 0xe5cd45
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 78
li $a2, 0xe5e545
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 78
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 78
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 78
li $a2, 0xe5e400
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 78
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 78
li $a2, 0xe59a00
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 78
li $a2, 0xff9700
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 78
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 78
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 78
li $a2, 0x8e0505
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 78
li $a2, 0xa01818
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 78
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 79
li $a2, 0xa91616
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 79
li $a2, 0xa20606
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 79
li $a2, 0xfea74d
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 79
li $a2, 0xe5b545
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 79
li $a2, 0xe5c845
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 79
li $a2, 0xe5e545
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 79
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 79
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 79
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 79
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 79
li $a2, 0xcd6b00
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 79
li $a2, 0xe56900
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 79
li $a2, 0xa20606
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 79
li $a2, 0x931515
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 79
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 80
li $a2, 0xa91616
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 80
li $a2, 0xa20606
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 80
li $a2, 0xcc7b3d
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 80
li $a2, 0xfe9e4d
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 80
li $a2, 0xe5aa45
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 80
li $a2, 0xe5e545
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 80
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 80
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 80
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 80
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 80
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 80
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 80
li $a2, 0xb8b800
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 80
li $a2, 0xb50707
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 80
li $a2, 0x941515
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 80
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 81
li $a2, 0xa91616
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 81
li $a2, 0x9f0606
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 81
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 81
li $a2, 0xcc7d3d
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 81
li $a2, 0xffb24d
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 81
li $a2, 0xe5b245
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 81
li $a2, 0x454545
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 81
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 81
li $a2, 0xcdcc00
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 81
li $a2, 0xcd6b00
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 81
li $a2, 0xcd6000
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 81
li $a2, 0xb50707
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 81
li $a2, 0x961414
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 81
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 82
li $a2, 0xa71717
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 82
li $a2, 0xb00707
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 82
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 82
li $a2, 0xcc863d
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 82
li $a2, 0xffca4d
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 82
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 82
li $a2, 0xffffff
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 82
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 82
li $a2, 0xa56e00
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 82
li $a2, 0xcd7900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 82
li $a2, 0xb30707
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 82
li $a2, 0x841212
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 82
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 83
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 83
li $a2, 0x8f1616
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 83
li $a2, 0xb30c0c
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 83
li $a2, 0xcb0000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 83
li $a2, 0xcd8c3d
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 83
li $a2, 0xffbd00
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 83
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 83
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 83
li $a2, 0xffe400
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 83
li $a2, 0xffca00
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 83
li $a2, 0xffcc00
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 83
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 83
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 83
li $a2, 0xe5b400
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 83
li $a2, 0xffc900
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 83
li $a2, 0xffb700
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 83
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 83
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 83
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 83
li $a2, 0xffac00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 83
li $a2, 0xffba00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 83
li $a2, 0xffb100
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 83
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 83
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 83
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 83
li $a2, 0xffab00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 83
li $a2, 0xffb700
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 83
li $a2, 0xffd100
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 83
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 83
li $a2, 0xb89700
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 83
li $a2, 0xe59a00
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 83
li $a2, 0xac0808
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 83
li $a2, 0x7f1414
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 83
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 84
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 84
li $a2, 0x8b1818
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 84
li $a2, 0xa21111
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 84
li $a2, 0xc00303
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 84
li $a2, 0xcc6700
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 84
li $a2, 0xfab20e
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 84
li $a2, 0xfefe12
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 84
li $a2, 0xe5e503
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 84
li $a2, 0xffe100
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 84
li $a2, 0xe5c200
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 84
li $a2, 0xe5d300
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 84
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 84
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 84
li $a2, 0xffea00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 84
li $a2, 0xffe700
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 84
li $a2, 0xffc900
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 84
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 84
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 84
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 84
li $a2, 0xffdb00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 84
li $a2, 0xffe400
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 84
li $a2, 0xffe500
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 84
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 84
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 84
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 84
li $a2, 0xffdc00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 84
li $a2, 0xffdf00
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 84
li $a2, 0xe5d300
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 84
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 84
li $a2, 0xb8a600
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 84
li $a2, 0xe59f00
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 84
li $a2, 0xa60b0b
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 84
li $a2, 0x7e1414
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 84
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 85
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 85
li $a2, 0x9a1b1b
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 85
li $a2, 0x8a1111
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 85
li $a2, 0xb40707
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 85
li $a2, 0xd46812
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 85
li $a2, 0xcc8427
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 85
li $a2, 0xe8ab31
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 85
li $a2, 0xf8d421
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 85
li $a2, 0xe5c102
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 85
li $a2, 0xe5d100
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 85
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 85
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 85
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 85
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 85
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 85
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 85
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 85
li $a2, 0xe5dd00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 85
li $a2, 0xe5db00
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 85
li $a2, 0xe5dd00
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 85
li $a2, 0xcdc100
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 85
li $a2, 0xb89700
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 85
li $a2, 0xffa900
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 85
li $a2, 0x920909
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 85
li $a2, 0x8d1717
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 85
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 86
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 86
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 86
li $a2, 0x871111
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 86
li $a2, 0xd20c0c
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 86
li $a2, 0xae5f21
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 86
li $a2, 0xa16131
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 86
li $a2, 0xce8741
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 86
li $a2, 0xe9b93c
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 86
li $a2, 0xe2c510
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 86
li $a2, 0xe5de00
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 86
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 86
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 86
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 86
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 86
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 86
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 86
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 86
li $a2, 0xe5dd00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 86
li $a2, 0xe5db00
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 86
li $a2, 0xcdc200
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 86
li $a2, 0xb8a600
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 86
li $a2, 0xcd9400
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 86
li $a2, 0xe57b00
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 86
li $a2, 0x9e0d0d
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 86
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 86
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 87
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 87
li $a2, 0xa71717
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 87
li $a2, 0x9e0b0b
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 87
li $a2, 0x8d1010
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 87
li $a2, 0x9d6134
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 87
li $a2, 0xaf6c3a
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 87
li $a2, 0xcba846
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 87
li $a2, 0xcabd1d
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 87
li $a2, 0xe5e300
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 87
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 87
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 87
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 87
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 87
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 87
li $a2, 0xffe500
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 87
li $a2, 0xe5c400
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 87
li $a2, 0xcdae00
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 87
li $a2, 0xb87f00
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 87
li $a2, 0xe58700
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 87
li $a2, 0xb50000
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 87
li $a2, 0x920e0e
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 87
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 88
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 88
li $a2, 0x991818
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 88
li $a2, 0xa41111
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 88
li $a2, 0x7c0f0f
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 88
li $a2, 0x9c6134
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 88
li $a2, 0xc27941
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 88
li $a2, 0xc9a84d
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 88
li $a2, 0xc7bd2f
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 88
li $a2, 0xe5e303
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 88
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 88
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 88
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 88
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 88
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 88
li $a2, 0xffdf00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 88
li $a2, 0xe5ae00
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 88
li $a2, 0xe59700
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 88
li $a2, 0xcd6b00
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 88
li $a2, 0xfd7803
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 88
li $a2, 0x960707
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 88
li $a2, 0x831313
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 88
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 49
add $a1, $t7, 89
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 89
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 89
li $a2, 0x7e0f0f
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 89
li $a2, 0x721111
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 89
li $a2, 0xae6e3b
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 89
li $a2, 0xb67b3e
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 89
li $a2, 0xdaca43
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 89
li $a2, 0xe4e212
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 89
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 89
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 89
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 89
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 89
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 89
li $a2, 0xfff400
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 89
li $a2, 0xe5c800
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 89
li $a2, 0xcd7700
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 89
li $a2, 0xcc6000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 89
li $a2, 0x960707
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 89
li $a2, 0x931616
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 89
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 89
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 90
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 90
li $a2, 0x810d0d
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 90
li $a2, 0x841212
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 90
li $a2, 0xae6e3b
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 90
li $a2, 0xaf6f3d
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 90
li $a2, 0xc69841
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 90
li $a2, 0xcbc51f
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 90
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 90
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 90
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 90
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 90
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 90
li $a2, 0xfffe00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 90
li $a2, 0xe5dc00
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 90
li $a2, 0xa57200
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 90
li $a2, 0xf68810
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 90
li $a2, 0x7b0f0f
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 90
li $a2, 0x7c1515
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 90
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 91
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 91
li $a2, 0x930f0f
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 91
li $a2, 0x7a1010
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 91
li $a2, 0x7c1414
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 91
li $a2, 0xc27941
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 91
li $a2, 0xba7f3d
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 91
li $a2, 0xc3b232
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 91
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 91
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 91
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 91
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 91
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 91
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 91
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 91
li $a2, 0xcdcc00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 91
li $a2, 0xb8ae00
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 91
li $a2, 0xe49f02
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 91
li $a2, 0xb80c0c
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 91
li $a2, 0x7f1414
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 91
li $a2, 0x7c1515
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 91
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 92
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 92
li $a2, 0x841313
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 92
li $a2, 0x840f0f
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 92
li $a2, 0x8e1616
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 92
li $a2, 0xb0703b
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 92
li $a2, 0xb1703a
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 92
li $a2, 0xb89739
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 92
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 92
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 92
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 92
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 92
li $a2, 0x00eaff
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 92
li $a2, 0x948b00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 92
li $a2, 0xb89600
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 92
li $a2, 0xf69610
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 92
li $a2, 0x8e1111
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 92
li $a2, 0x7d1515
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 92
li $a2, 0x6e1212
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 92
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 50
add $a1, $t7, 93
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 51
add $a1, $t7, 93
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 93
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 93
li $a2, 0x8a1111
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 93
li $a2, 0x9f6232
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 93
li $a2, 0xc47a41
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 93
li $a2, 0xc97b3e
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 93
li $a2, 0xc9c935
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 93
li $a2, 0xb7b70c
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 93
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 93
li $a2, 0xcdb600
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 93
li $a2, 0x946d00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 93
li $a2, 0xcb6e05
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 93
li $a2, 0x9b0e0e
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 93
li $a2, 0x841414
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 93
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 93
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 93
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 94
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 94
li $a2, 0x961515
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 94
li $a2, 0x971515
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 94
li $a2, 0x9f6232
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 94
li $a2, 0xc87c3f
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 94
li $a2, 0xbe6a29
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 94
li $a2, 0xcccc12
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 94
li $a2, 0xcdcd00
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 94
li $a2, 0xffff00
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 94
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 94
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 94
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 94
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 94
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 94
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 94
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 94
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 94
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 94
li $a2, 0xffc500
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 94
li $a2, 0x946100
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 94
li $a2, 0xa34d00
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 94
li $a2, 0xaa0f0f
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 94
li $a2, 0x731212
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 94
li $a2, 0x9d1b1b
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 94
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 95
li $a2, 0xb16f39
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 95
li $a2, 0xb26e38
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 95
li $a2, 0xb66a31
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 95
li $a2, 0xc9671c
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 95
li $a2, 0xe5e506
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 95
li $a2, 0x944b00
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 95
li $a2, 0xa44b00
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 95
li $a2, 0xb35f1c
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 95
li $a2, 0x901717
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 76
add $a1, $t7, 95
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 96
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 96
li $a2, 0x771d1d
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 96
li $a2, 0xab7040
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 96
li $a2, 0xb2703a
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 96
li $a2, 0xa75f28
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 96
li $a2, 0xfbfa2f
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 96
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 96
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 96
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 96
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 96
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 96
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 96
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 96
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 96
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 96
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 96
li $a2, 0xa54800
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 96
li $a2, 0xb05308
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 96
li $a2, 0x8b1111
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 96
li $a2, 0x7d1515
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 96
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 97
li $a2, 0x7f1a1a
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 97
li $a2, 0xcdcd00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 97
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 97
li $a2, 0xe5e500
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 97
li $a2, 0xcdcd00
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 97
li $a2, 0x9e561b
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 97
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 56
add $a1, $t7, 98
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 98
li $a2, 0x7b1c1c
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 98
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 98
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 98
li $a2, 0xb8b800
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 98
li $a2, 0xcdcd00
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 98
li $a2, 0xa5a500
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 98
li $a2, 0xa5a500
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 98
li $a2, 0xa5a500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 98
li $a2, 0xa5a500
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 98
li $a2, 0xa5a500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 98
li $a2, 0x767600
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 98
li $a2, 0xa5a500
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 98
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 98
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 98
li $a2, 0xa61919
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 98
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 98
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 57
add $a1, $t7, 99
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 99
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 99
li $a2, 0xaa500d
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 99
li $a2, 0xb8b800
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 99
li $a2, 0xb8b800
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 99
li $a2, 0xa5a500
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 99
li $a2, 0xb8b800
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 99
li $a2, 0xb8b800
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 99
li $a2, 0xcdcd00
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 99
li $a2, 0x949400
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 99
li $a2, 0xcdcd00
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 99
li $a2, 0xcdcd00
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 99
li $a2, 0xb5611c
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 99
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 99
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 58
add $a1, $t7, 100
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 100
li $a2, 0xfd0101
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 100
li $a2, 0xe50000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 100
li $a2, 0xe56200
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 100
li $a2, 0xe56200
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 100
li $a2, 0xb84f00
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 100
li $a2, 0xb84f00
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 100
li $a2, 0xa54600
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 100
li $a2, 0xe56200
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 100
li $a2, 0xe36402
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 100
li $a2, 0xe17a24
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 100
li $a2, 0xca7e3e
jal paintPixel

add $a0, $t6, 70
add $a1, $t7, 100
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 71
add $a1, $t7, 100
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 64
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 69
add $a1, $t7, 101
li $a2, 0x000000
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 59
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 60
add $a1, $t7, 113
li $a2, 0xff8600
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 113
li $a2, 0xff8700
jal paintPixel

add $a0, $t6, 62
add $a1, $t7, 113
li $a2, 0xff8700
jal paintPixel

add $a0, $t6, 63
add $a1, $t7, 113
li $a2, 0xff8700
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 113
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 87
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 88
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 90
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 91
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 103
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 104
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 106
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 107
add $a1, $t7, 113
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 28
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 55
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 114
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 114
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 114
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 114
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 114
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 114
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 114
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 26
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 27
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 31
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 53
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 54
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 73
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 115
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 94
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 95
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 99
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 115
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 32
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 43
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 48
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 116
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 65
add $a1, $t7, 116
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 68
add $a1, $t7, 116
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 116
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 74
add $a1, $t7, 116
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 116
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 85
add $a1, $t7, 116
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 100
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 116
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 25
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 30
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 33
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 35
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 36
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 37
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 38
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 40
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 41
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 42
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 45
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 46
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 47
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 52
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 61
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 66
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 67
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 72
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 75
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 77
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 78
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 79
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 80
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 82
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 83
add $a1, $t7, 117
li $a2, 0xff8500
jal paintPixel

add $a0, $t6, 84
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 89
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 93
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 96
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 98
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 101
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

add $a0, $t6, 105
add $a1, $t7, 117
li $a2, 0xff8400
jal paintPixel

	move $ra, $t5
	jr $ra

paintRocket0Fire:
	# x in $a0
	# y in $a1
	# frame in $a2

	#store x, y, frame and $ra
	move $t6, $a0
	move $t7, $a1
	move $t8, $a2
	move $t5, $ra
	
	beq $t8, 0, ROCKETFIREFRAME0
	
add $a0, $t6, 18
add $a1, $t7, 2
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 2
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 3
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 3
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 3
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 3
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 3
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 4
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 4
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 4
li $a2, 0xff8119
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 4
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 4
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 4
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 5
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 5
li $a2, 0xff8119
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 5
li $a2, 0xff8119
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 5
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 5
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 5
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 6
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 6
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 6
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 7
li $a2, 0xff2929
jal paintPixel
	
	j AFTERPAINTROCKETFIRE
	
	ROCKETFIREFRAME0:
	
	add $a0, $t6, 18
add $a1, $t7, 0
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 0
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 1
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 1
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 2
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 2
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 2
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 2
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 2
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 3
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 3
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 3
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 3
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 3
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 4
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 4
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 4
li $a2, 0xff8119
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 4
li $a2, 0xff8119
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 4
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 4
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 5
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 5
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 5
li $a2, 0xff8119
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 5
li $a2, 0xff8119
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 5
li $a2, 0x7c3e0b
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 5
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 5
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 6
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 6
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 6
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 6
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 6
li $a2, 0xb25a11
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 7
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 7
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 7
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 7
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 19
add $a1, $t7, 7
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 7
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 8
li $a2, 0xff2929
jal paintPixel

add $a0, $t6, 20
add $a1, $t7, 8
li $a2, 0xb21c1c
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 9
li $a2, 0xb21c1c
jal paintPixel
	
	AFTERPAINTROCKETFIRE:
	move $ra, $t5
	jr $ra
	

paintJetpackFire:
	# x in $a0
	# y in $a1
	# frame in $a2

	#store x, y, frame and $ra
	move $t6, $a0
	move $t7, $a1
	move $t8, $a2
	move $t5, $ra
	
	beq $t8, 0, FIREFRAME0
	
	add $a0, $t6, 2
add $a1, $t7, 13
li $a2, 0x4dbdb
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 14
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 14
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 14
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 14
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 15
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 15
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 15
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 16
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 16
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 19
li $a2, 0xffd900
jal paintPixel
	
	j AFTERPAINTFIRE
	
	FIREFRAME0:
	
	add $a0, $t6, 2
add $a1, $t7, 13
li $a2, 0x4dbdb
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 13
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 14
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 14
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 14
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 14
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 14
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 15
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 15
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 15
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 16
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 16
li $a2, 0xffec7f
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 16
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 17
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 18
li $a2, 0xffd900
jal paintPixel
	
	AFTERPAINTFIRE:
	move $ra, $t5
	jr $ra
	


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

paintRocket:
	#store x and y and $ra
	move $t6, $a0
	move $t7, $a1
	move $t5, $ra
	# Paint the cloud
	add $a0, $t6, 5
add $a1, $t7, 0
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 0
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 0
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 0
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 0
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 0
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 1
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 1
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 1
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 1
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 1
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 1
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 1
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 1
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 1
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 1
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 1
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 1
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 1
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 1
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 1
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 1
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 2
li $a2, 0x979797
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 2
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 2
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 2
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 2
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 2
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 2
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 2
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 2
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 2
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 2
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 2
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 2
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 2
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 2
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 2
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 2
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 3
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 3
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 3
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 3
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 3
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 3
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 3
li $a2, 0x2e2e2e
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 3
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 3
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 3
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 3
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 3
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 3
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 3
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 3
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 3
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 3
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 3
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 4
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 4
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 4
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 4
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 4
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 4
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 4
li $a2, 0x2e2e2e
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 4
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 4
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 4
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 4
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 4
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 4
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 4
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 4
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 4
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 4
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 4
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 5
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 5
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 5
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 5
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 5
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 5
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 5
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 5
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 5
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 5
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 5
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 5
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 5
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 5
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 5
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 5
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 5
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 5
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 1
add $a1, $t7, 6
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 6
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 6
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 6
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 6
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 6
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 6
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 6
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 6
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 6
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 6
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 6
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 6
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 6
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 6
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 6
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 6
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 6
li $a2, 0x404040
jal paintPixel

add $a0, $t6, 2
add $a1, $t7, 7
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 7
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 7
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 7
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 7
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 7
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 7
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 7
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 7
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 7
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 7
li $a2, 0x8c8c8c
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 7
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 7
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 7
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 7
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 7
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 3
add $a1, $t7, 8
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 4
add $a1, $t7, 8
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 8
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 8
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 8
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 8
add $a1, $t7, 8
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 9
add $a1, $t7, 8
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 10
add $a1, $t7, 8
li $a2, 0x434343
jal paintPixel

add $a0, $t6, 11
add $a1, $t7, 8
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 12
add $a1, $t7, 8
li $a2, 0x616161
jal paintPixel

add $a0, $t6, 13
add $a1, $t7, 8
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 14
add $a1, $t7, 8
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 8
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 8
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 8
li $a2, 0x00ffae
jal paintPixel

add $a0, $t6, 5
add $a1, $t7, 9
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 6
add $a1, $t7, 9
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 7
add $a1, $t7, 9
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 15
add $a1, $t7, 9
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 16
add $a1, $t7, 9
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 17
add $a1, $t7, 9
li $a2, 0x00b279
jal paintPixel

add $a0, $t6, 18
add $a1, $t7, 9
li $a2, 0x00b279
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
















