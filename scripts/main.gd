class_name Main
extends Node3D

enum GameState { LOBBY, COUNTDOWN, PLAYING, RESOLUTION }

const TASKS = {
	"IceCreamShop": "Go buy 2 chocolate ice cream scoops",
	"Bookstore": "Find the note in 'The Spy HandBook' at the book store",
	"Bench": "Meet the informant at the bench in Central Park",
	"PhoneBooth": "Pick up the phone call at the phone booth"
}


#@onready var multiplayer_menu: MultiplayerMenu = %MultiplayerMenu
@onready var e_net_server: ENetServer = %ENetServer
@onready var e_net_client: ENetClient = %ENetClient
@onready var players: PlayersManager = %Players


@export var task_duration: float = 60.0
@export var resolution_duration: float = 5.0
@export var countdown_duration: float = 3.0



var current_state: GameState = GameState.LOBBY
var active_tasks: Dictionary = {}  # { player_id: { "location": String, "completed": bool } }
var task_timer: float = 0.0
var resolution_timer: float = 0.0
var countdown_timer: float = 0.0


# Track which keys have been revealed per target per recipient
# Structure: { recipient_id: { target_id: [used_keys] } }
var intel_history: Dictionary = {}

signal state_changed(new_state: GameState)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%MultiplayerMenu.host_server_request.connect(e_net_server.start_server)
	%MultiplayerMenu.join_server_request.connect(e_net_client.connect_to_server)

	e_net_server.spawn_host_player.connect(players.spawn_host_player)

	e_net_client.connection_failed.connect(%MultiplayerMenu.on_connection_failed)
	e_net_client.server_disconnected.connect(%MultiplayerMenu.on_server_disconnected)

	%MultiplayerMenu.start_game_request.connect(start_game)
	

	state_changed.connect(_on_state_changed)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# Hide world until game starts
	%World.visible = false
	
	# Wait a moment for spawning to happen
	await get_tree().create_timer(1.0).timeout
	await get_tree().physics_frame



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !multiplayer.is_server():
		return
	
	match current_state:
		GameState.COUNTDOWN:
			countdown_timer -= delta
			if countdown_timer <= 0:
				start_task_phase()
		
		GameState.PLAYING:
			task_timer -= delta
			sync_task_timer.rpc(task_timer)
			if task_timer <= 0:
				resolve_tasks()
		
		GameState.RESOLUTION:
			resolution_timer -= delta
			if resolution_timer <= 0:
				start_task_phase()


# Called by host clicking "Start"
func start_game():
	if !multiplayer.is_server():
		return
	current_state = GameState.COUNTDOWN
	countdown_timer = countdown_duration
	sync_state.rpc(GameState.COUNTDOWN)


func start_task_phase():
	current_state = GameState.PLAYING
	
	# Activate NPCs on first task phase
	for player in players.get_children():
		if player.is_npc and !player.npc_active:
			player.activate_npc()
			
	assign_tasks()
	task_timer = task_duration
	sync_state.rpc(GameState.PLAYING)


func resolve_tasks():
	current_state = GameState.RESOLUTION
	
	# Check who completed/failed
	for player_id in active_tasks:
		if active_tasks[player_id].completed:
			# Success - generate intel for this player about a random other player
			give_intel_on_success(player_id)
		else:
			# Fail - give intel about this player to everyone else
			give_intel_on_fail(player_id)
	
	active_tasks.clear()
	resolution_timer = resolution_duration
	sync_state.rpc(GameState.RESOLUTION)


func assign_tasks():
	active_tasks.clear()
	var location_names = TASKS.keys()
	
	#print("=== Assigning tasks ===")
	#print("Players found: ", players.get_children().size())
	
	for player in players.get_children():
		#print("  Checking: ", player.name, " is_npc: ", player.is_npc)
		if player.is_npc:
			continue
		
		var location = location_names[randi() % location_names.size()]
		active_tasks[int(player.name)] = {
			"location": location,
			"completed": false
		}
		
		#print("  Assigning task to player ", player.name, ": ", TASKS[location])
		player.receive_task.rpc_id(int(player.name), TASKS[location], location)


# Called by Area3D when player enters location
func on_player_entered_location(player_id: int, location_name: String):
	if current_state != GameState.PLAYING:
		return
	
	#print("Player ", player_id, " entered ", location_name)
	
	if active_tasks.has(player_id):
		#print("  Their task location: ", active_tasks[player_id].location)
		if active_tasks[player_id].location == location_name:
			active_tasks[player_id].completed = true
			#print("  TASK COMPLETED!")


func generate_intel_clue_for_key(target_traits: Dictionary, key: String) -> String:
	match key:
		"hair_color":
			return "• One spy has %s hair" % target_traits.hair_color
		"shirt_color":
			return "• One spy is wearing a %s shirt" % target_traits.shirt_color
		"pants_color":
			return "• One spy is wearing %s pants" % target_traits.pants_color
		"has_hat":
			return "• One spy is %s a hat" % ("wearing" if target_traits.has_hat else "not wearing")
		"has_glasses":
			return "• One spy %s sunglasses" % ("has" if target_traits.has_glasses else "has no")
		"has_backpack":
			return "• One spy %s a backpack" % ("carries" if target_traits.has_backpack else "does not carry")
	return ""


func generate_intel_clue(target_traits: Dictionary) -> String:
	var keys = ["hair_color", "shirt_color", "pants_color", "has_hat", "has_glasses", "has_backpack"]
	var key = keys[randi() % keys.size()]
	return generate_intel_clue_for_key(target_traits, key)


func get_random_other_player(exclude_id: int) -> CharacterBody3D:
	var other_players: Array = []
	for player in players.get_children():
		if player.is_npc:
			continue
		if int(player.name) == exclude_id:
			continue
		other_players.append(player)
	
	if other_players.is_empty():
		return null
	
	return other_players[randi() % other_players.size()]


func give_intel_on_success(player_id: int):
	var target = get_random_other_player(player_id)
	if target == null:
		return
	
	var clue = get_unused_clue(player_id, int(target.name), target.traits)
	if clue.is_empty():
		return
	
	var player = players.get_node(str(player_id))
	player.receive_intel.rpc_id(player_id, clue)


func give_intel_on_fail(player_id: int):
	var failed_player = players.get_node(str(player_id))
	
	for player in players.get_children():
		if player.is_npc:
			continue
		if int(player.name) == player_id:
			continue
		
		var clue = get_unused_clue(int(player.name), player_id, failed_player.traits)
		if clue.is_empty():
			continue
		
		player.receive_intel.rpc_id(int(player.name), clue)


func get_unused_clue(recipient_id: int, target_id: int, target_traits: Dictionary) -> String:
	# Initialize tracking dicts if needed
	if !intel_history.has(recipient_id):
		intel_history[recipient_id] = {}
	if !intel_history[recipient_id].has(target_id):
		intel_history[recipient_id][target_id] = []
	
	var used_keys: Array = intel_history[recipient_id][target_id]
	var all_keys = ["hair_color", "shirt_color", "pants_color", "has_hat", "has_glasses", "has_backpack"]
	
	# Filter out already used keys
	var available_keys: Array = all_keys.filter(func(key): return !used_keys.has(key))
	
	if available_keys.is_empty():
		return ""  # All clues about this target already revealed
	
	# Pick random available key
	var key = available_keys[randi() % available_keys.size()]
	
	# Track it
	intel_history[recipient_id][target_id].append(key)
	
	return generate_intel_clue_for_key(target_traits, key)


func _on_peer_disconnected(id: int) -> void:
	# Clean up active tasks for disconnected player
	if active_tasks.has(id):
		active_tasks.erase(id)

	# Clean up intel history for disconnected player
	if intel_history.has(id):
		intel_history.erase(id)
	for recipient_id in intel_history:
		if intel_history[recipient_id].has(id):
			intel_history[recipient_id].erase(id)


# When game state changes, show/hide world
func _on_state_changed(new_state: GameState) -> void:
	match new_state:
		GameState.COUNTDOWN:
			%World.visible = true
			%MultiplayerMenu.hide_lobby()
			%IntelHUD.visible = true
		GameState.RESOLUTION:
			%GameHUD.hide_hud()



# RPCs
@rpc("authority", "call_local", "reliable")
func sync_state(new_state: GameState):
	current_state = new_state
	state_changed.emit(new_state)


@rpc("authority", "call_local", "reliable")
func sync_task_timer(time_left: float):
	task_timer = time_left
	#print("sync_task_timer called, game_hud: ", %GameHUD)
	%GameHUD.update_timer(time_left)
