extends Node2D

var player_scn = preload("res://player.tscn")
var tetrino_scn = preload("res://tetrino.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBut.connect("highlight_grid", highlight_tiles_above)
	EventBut.connect("request_supply_drop", add_tetrino)
	EventBut.connect("move_block", move_block)

var winner = ""
var winning_height = 0
var counter = 90
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if multiplayer.is_server():
		for player in $Players.get_children():
			if player.global_position.y < winning_height:
				for p in $Players.get_children():
					winner = player.username
					p.winner = player.username
				winning_height = player.global_position.y

func _on_jam_connect_player_connected(pid, username):
	spawn_player(pid, username)

func _on_jam_connect_player_disconnected(pid, username):
	pass # Replace with function body.

func spawn_player(pid: int, nametag: String):
	var p: CharacterBody2D = player_scn.instantiate()
	p.pid = pid
	p.nametag = nametag
	p.position = $Players.position
	p.username = nametag
	p.name = str(pid)
	p.winner = winner
	$Players.add_child(p, true)

func highlight_tiles_above(position):
	# Clear previous highlights
	$TileMap.clear_layer(1)  # Assuming layer 1 is used for highlights
	# Get player's position in tile coordinates
	for p in $Players.get_children():
		if p.pid == multiplayer.get_unique_id() and p.drop_mode:
			var player_tile_pos = $TileMap.local_to_map(self.to_local(p.global_position))
			# Highlight 5 tiles above the player
			add_tetrino.rpc()
			for j in range(3, 9):
				for i in range(0, 18):
						var tile_pos = Vector2i(player_tile_pos.x+ j, player_tile_pos.y - i)
						$TileMap.set_cell(1, tile_pos, 0, Vector2i(0, 2), 0)


func add_tetrino(pid):
	var t = tetrino_scn.instantiate()
	var p = $Players.get_node(str(pid))
	
	#t.global_position = Vector2(7.0*128.0, -1280.0) + p.global_position
	#t.global_position = t.global_position.snapped(Vector2(128.0, 128.0))
	var player_tile_pos = $TileMap.local_to_map(self.to_local(p.global_position))
	var tile_pos = Vector2i(player_tile_pos.x+ 5, player_tile_pos.y - 10)
	t.global_position = $TileMap.map_to_local(tile_pos)
	t.pid = pid
	self.add_child(t, true)
	
func move_block(pid, amount):
	for c in get_children():
		if c.is_in_group("block") and c.pid == pid:
			c.move_sideways(amount)

func _on_jam_connect_player_joined(pid, username):
	$Camera2D.enabled = false

func _on_timer_timeout():
	if multiplayer.is_server():
		for player in $Players.get_children():
			counter = counter - 1.0
			player.displayed_time_remaining = counter
			if player.displayed_time_remaining < 1.0:
				$Timer.stop()
				for p in $Players.get_children():
					player.final_winner = winner
