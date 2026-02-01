class_name Main
extends Node3D

enum GameState { LOBBY, COUNTDOWN, PLAYING, RESOLUTION }

const TASKS = {
	"IceCreamShop": "Go buy 2 chocolate ice cream scoops",
	"BookStore": "Find the note in 'The Spy HandBook' at the book store",
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

signal state_changed(new_state: GameState)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%MultiplayerMenu.host_server_request.connect(e_net_server.start_server)
	%MultiplayerMenu.join_server_request.connect(e_net_client.connect_to_server)

	e_net_server.spawn_host_player.connect(players.spawn_host_player)
	
	%MultiplayerMenu.start_game_request.connect(start_game)
	

	state_changed.connect(_on_state_changed)
	
	# Hide world until game starts
	%World.visible = false
	
	# Wait a moment for spawning to happen, then check
	await get_tree().create_timer(1.0).timeout
	
	print("World visible: ", %World.visible)
	print("World is_visible_in_tree: ", %World.is_visible_in_tree())
	print("Players visible: ", players.visible)
	print("Players is_visible_in_tree: ", players.is_visible_in_tree())
	print("Players parent: ", players.get_parent().name)
	print("Players parent visible: ", players.get_parent().visible)
	print("Players parent is_visible_in_tree: ", players.get_parent().is_visible_in_tree())



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
	
	print("Player ", player_id, " entered ", location_name)
	
	if active_tasks.has(player_id):
		#print("  Their task location: ", active_tasks[player_id].location)
		if active_tasks[player_id].location == location_name:
			active_tasks[player_id].completed = true
			#print("  TASK COMPLETED!")


# Placeholder for later
func give_intel_on_success(player_id: int):
	print("Player ", player_id, " succeeded - TODO: give intel")

func give_intel_on_fail(player_id: int):
	print("Player ", player_id, " failed - TODO: give intel")

# When game state changes, show/hide world
func _on_state_changed(new_state: GameState) -> void:
	match new_state:
		GameState.COUNTDOWN:
			%World.visible = true
			%MultiplayerMenu.hide_lobby()





# RPCs
@rpc("authority", "call_local", "reliable")
func sync_state(new_state: GameState):
	current_state = new_state
	state_changed.emit(new_state)

@rpc("authority", "call_local", "reliable")
func sync_task_timer(time_left: float):
	task_timer = time_left
