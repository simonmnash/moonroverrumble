extends TileMap

# Simulate a simple physics process to determine if towers should fall on layer 2
func simulate_physics():
	var layer = 2  # Layer where player-placed towers are located
	for cell in get_used_cells(layer):
		var tile_data = get_cell_tile_data(layer, cell)

# Calculate the center of gravity for a given tower cell
func get_center_of_gravity(cell):
	# Placeholder for center of gravity calculation
	# For simplicity, return the cell position
	return cell

# Determine if the tower is off balance
func is_off_balance(center_of_gravity):
	# Placeholder for balance check
	# Simple condition: center of gravity x is not zero
	return center_of_gravity.x != 0

# Handle tower falling logic on layer 2
func fall_tower(cell):
	print("Tower at ", cell, " is falling!")
	# Replace the tower tile with a fallen state or remove it
	set_cell(2, cell, -1)  # Removes the tile by setting source_id to -1

func _on_tile_physics_clock_timeout():
	if multiplayer.is_server(): 
		simulate_physics()
