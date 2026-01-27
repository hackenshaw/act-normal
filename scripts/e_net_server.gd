class_name ENetServer
extends Node

#@export var port: int = 4242
#@export var max_players: int = 4

func start_server(port : int, max_players: int) -> void:
	var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	network.create_server(port, max_players)
	
	multiplayer.multiplayer_peer = network
	
	print("Server listening on port ", port)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
