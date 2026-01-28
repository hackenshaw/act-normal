class_name PlayersManager
extends Node

const PLAYER_SCENE = preload("uid://c3liq1sfmyqp4")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(on_peer_connected)


func on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		var player = PLAYER_SCENE.instantiate()
		player.name = str(id)
		
		add_child(player)


func spawn_host_player() -> void:
	on_peer_connected(1)
