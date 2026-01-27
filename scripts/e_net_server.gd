class_name ENetServer
extends Node

#@export var port: int = 4242
@export var max_players: int = 4

func start_server(port : int) -> void:
	var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	network.create_server(port, max_players)
	
	multiplayer.multiplayer_peer = network
	multiplayer.peer_connected.connect(on_peer_connected)
	
	print("Server listening on port: ", port)


func on_peer_connected(id: int) -> void:
	print("New player (", id, ") connected to server!")
