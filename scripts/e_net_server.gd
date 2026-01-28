class_name ENetServer
extends Node

signal spawn_host_player

#@export var port: int = 4242
@export var max_players: int = 4

func start_server(port : int) -> void:
	var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	network.create_server(port, max_players)
	
	multiplayer.multiplayer_peer = network
	
	spawn_host_player.emit()
	print("Server listening on port: ", port)
