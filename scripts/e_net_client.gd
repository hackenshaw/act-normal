class_name ENetClient
extends Node


signal connection_failed
signal server_disconnected


func connect_to_server(host_ip: String, port: int) -> void:
	var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	network.create_client(host_ip, port)

	multiplayer.multiplayer_peer = network
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_connected_to_server() -> void:
	pass


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()
