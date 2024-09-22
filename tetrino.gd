extends CharacterBody2D

# Constants
const FALL_INTERVAL = 0.5  # Time in seconds between each fall step
var pid = null
var antigrav_scene = preload("res://antigrav.tscn")
# Tetromino shapes
const SHAPES = [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],     # I
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],     # O
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],     # T
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1)],     # L
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)],     # J
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],     # S
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]      # Z
]

# Variables
var fall_timer = 0.0
@onready var tile_map = get_parent().get_node("TileMap")
var tile_size = Vector2(128, 128)
var shape = []
var block_scene = preload("res://block.tscn") 
var lift_scene = preload("res://solarlift.tscn") 
var blocks = []
var grav_index = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	# Choose a random shape
	if multiplayer.is_server():
		shape = SHAPES[randi() % SHAPES.size()]
		grav_index = randi_range(0, 10)
	# Generate and add child blocks
	var i = 0
	for block_pos in shape:
		var block_instance = null
		var block_type = Vector2i(1, 1)  # Default block type
		
		if grav_index == i:
			block_instance = lift_scene.instantiate()
			block_type = Vector2i(2, 1)
		else:
			block_instance = block_scene.instantiate()
		
		block_instance.position = Vector2(block_pos.x, block_pos.y) * tile_size + Vector2(64.0, 64.0)
		add_child(block_instance, true)
		
		# Store both position and block_type
		blocks.append({"pos": block_pos, "block_type": block_type})
		i += 1
	
	# Snap the initial position to the TileMap grid
	position = align_to_grid(position)

# Called every physics frame.
func _physics_process(delta):
	if multiplayer.is_server():
		fall_timer += delta
		if fall_timer >= FALL_INTERVAL:
			fall_timer = 0.0
			move_down()

# Function to align a position to the TileMap grid
func align_to_grid(pos: Vector2) -> Vector2:
	return pos.snapped(tile_size)

# Function to move the block down by one tile
func move_down():
	var new_position = position + Vector2(0, tile_size.y)
	
	# Check for collision with the TileMap or boundaries
	if can_move_to(new_position):
		position = align_to_grid(new_position)
	else:
		lock_block()
		# Optionally, emit a signal or notify the game to spawn a new block

# Function to check if the block can move to the specified position
func can_move_to(pos: Vector2) -> bool:
	for block in blocks:
		var block_world_pos = pos + Vector2(block["pos"].x, block["pos"].y) * tile_size
		var cell = tile_map.local_to_map(block_world_pos)
		if tile_map.get_cell_source_id(0, cell) != -1:
			return false
		if tile_map.get_cell_source_id(2, cell) != -1:
			return false
	return true

func move_sideways(x_input: float):
	if x_input == 0:
		return
	var direction = sign(x_input)
	var new_position = position + Vector2(direction * tile_size.x, 0)
	
	if can_move_to(new_position):
		position = align_to_grid(new_position)

# Function to lock the block in place
func lock_block():
	for block in blocks:
		var block_world_pos = position + Vector2(block["pos"].x, block["pos"].y) * tile_size
		var cell = tile_map.local_to_map(block_world_pos)
		tile_map.set_cell(2, cell, 0, block["block_type"])
		if block["block_type"]==Vector2i(2, 1):
			var anti_grav = antigrav_scene.instantiate()
			anti_grav.position = block_world_pos
			tile_map.add_child(anti_grav)

	tile_map.force_update()
	send_tilemap_update.rpc(shape, position)
	queue_free()  # Remove the current block

@rpc("authority", "reliable")
func send_tilemap_update(shape_blocks, pos):
	for block in blocks:
		var block_world_pos = pos + Vector2(block["pos"].x, block["pos"].y) * tile_size
		var cell = tile_map.local_to_map(block_world_pos)
		tile_map.set_cell(2, cell, 0, block["block_type"])

