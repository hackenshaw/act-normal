class_name ENetClient
extends Node


func connect_to_server(host_ip: String, port: int) -> void:
	var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	network.create_client(host_ip, port)
	
	multiplayer.multiplayer_peer = network
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.peer_connected.connect(on_peer_connected)
	
	print("Connecting to ", host_ip, ":", port)


func on_connected_to_server() -> void:
	print("Connected to server!")


func on_peer_connected(id: int) -> void:
	print("New player (", id, ") joined game!")
