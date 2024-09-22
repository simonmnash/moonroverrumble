extends CharacterBody2D

const ACCELERATION = 1500.0  # Acceleration rate
const MAX_SPEED = 800.0      # Maximum horizontal speed
const FRICTION = 400.0        # Friction applied when no input
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_jumping = false
var pid = null
var nametag = null
var movement_direction = 0
var username
var displayed_time_remaining = 10.0:
	set (v):
		displayed_time_remaining = v
		$Camera2D/CanvasLayer/VBoxContainer/HBoxContainer4/Label.text = str(int(v))

var winner = '':
	set(v):
		winner = v
		if len(v) > 0:
			$Camera2D/CanvasLayer/VBoxContainer2/HBoxContainer/Label2.text = str(v)
		
var drop_mode = false :
	set (v):
		drop_mode = v
		if drop_mode:
			$Camera2D/CanvasLayer/HBoxContainer/Instructions.text = "Press SPACE to exit drop mode and regain movement."
		else:
			$Camera2D/CanvasLayer/HBoxContainer/Instructions.text = "Press SPACE to call for a supply drop."

var final_winner = "":
	set(v):
		final_winner = v
		if len(v) > 0:
			$Camera2D/CanvasLayer/Label.text = str(v) + " wins"

func _ready():
	if self.pid == multiplayer.get_unique_id():
		$Camera2D.enabled = true
	else:
		$Camera2D.enabled = false

func _physics_process(delta):
	if multiplayer.is_server():
		handle_input(delta)
		apply_physics(delta)
		move_and_slide()

func _process(delta):
	# local player controls
	var x_input := Input.get_axis("ui_left", "ui_right")
	if not multiplayer.is_server():
		if drop_mode:
			if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
				set_block_movement.rpc_id(1, x_input)
		else:
			set_x_movement.rpc_id(1, x_input)
	if Input.is_action_just_released("dropmode"):
		if drop_mode:
			drop_mode = false
		else:
			drop_mode = true
			request_supply_drop.rpc()

@rpc("any_peer")
func request_supply_drop():
	if multiplayer.is_server():
		if multiplayer.get_remote_sender_id() == pid:
			EventBut.emit_signal("request_supply_drop", self.pid)

@rpc("any_peer")
func set_x_movement(amount: float):
	if multiplayer.get_remote_sender_id() != pid:
		return
	movement_direction = clampf(amount, -1.0, 1.0)

@rpc("any_peer")
func set_block_movement(amount):
	if multiplayer.get_remote_sender_id() != pid:
		return
	EventBut.emit_signal("move_block", self.pid, clampf(amount, -1.0, 1.0))
	
func handle_input(delta):
	# Handle horizontal input for left and right movement
	var direction = movement_direction

	if direction != 0:
		# Apply acceleration in the direction of input
		velocity.x += direction * ACCELERATION * delta
	else:
		# Apply friction to slow down when there's no input
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Clamp the velocity to the maximum speed
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)


func apply_physics(delta):
	# Always apply gravity
	velocity.y += GRAVITY * delta
	# Rotate the buggy based on floor normal if on floor
	if is_on_floor():
		var floor_normal = get_floor_normal()
		rotation = floor_normal.angle() + PI / 2


func _on_effect_range_area_entered(area):
	if multiplayer.is_server():
		if area.is_in_group("antigrav"):
			GRAVITY = -1*abs(GRAVITY)


func _on_effect_range_area_exited(area):
	if multiplayer.is_server():
		if area.is_in_group("antigrav"):
			GRAVITY = abs(GRAVITY)
