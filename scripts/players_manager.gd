class_name PlayersManager
extends Node


const PLAYER_SCENE = preload("uid://c3liq1sfmyqp4")

@onready var spawn_points = %SpawnPoints.get_children()

@export var NPC_count: int = 15

var spawn_index = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(on_peer_connected)
	
	if multiplayer.is_server():
		spawn_npcs()


func on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		var player = PLAYER_SCENE.instantiate()
		player.name = str(id)
		
		player.position = spawn_points[spawn_index % spawn_points.size()].position
		#print(player.name, " is spawned at ", player.position)
		
		add_child(player, true)
		player.set_spawn_position.rpc(spawn_points[spawn_index % spawn_points.size()].position)
		spawn_index += 1
		
		player.randomize_traits()
		player.apply_traits()
		player.set_traits.rpc(player.traits)
		
		print("Parent node: ", self.name)
		print("Children before spawn: ", get_children())

		for child in get_children():
			print("  Child: ", child.name, " type: ", child.get_class())
	
		for child in get_children():
			if child != player and child.has_method("set_traits"):
				print("  Sending traits of player ", child.name, ": ", child.traits)
				# Send existing player's traits only to the new client
				child.set_traits.rpc_id(id, child.traits)


func spawn_host_player() -> void:
	on_peer_connected(1)


func spawn_npcs():
	for i in range(NPC_count):
		var npc = PLAYER_SCENE.instantiate()  # Same scene as players!
		npc.name = "NPC_" + str(i)
		npc.is_npc = true  # Flag it as NPC
		
		add_child(npc, true)
		npc.set_multiplayer_authority(1)
		
		# Random spawn position
		var spawn_pos = spawn_points[randi() % spawn_points.size()].position
		npc.position = spawn_pos
		
		# Randomize traits
		npc.randomize_traits()
		npc.apply_traits()
		npc.set_traits.rpc(npc.traits)
