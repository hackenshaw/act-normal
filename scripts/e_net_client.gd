class_name ENetClient
extends Node


func connect_to_server(host_ip: String, port: int) -> void:
	var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	network.create_client(host_ip, port)
	
	multiplayer.multiplayer_peer = network
	multiplayer.connected_to_server.connect(on_connected_to_server)
	
	print("Connecting to ", host_ip, ":", port)


func on_connected_to_server() -> void:
	print("Connected to server!")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
