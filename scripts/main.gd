class_name Main
extends Node3D

@onready var multiplayer_menu: MultiplayerMenu = %MultiplayerMenu
@onready var e_net_server: ENetServer = %ENetServer
@onready var e_net_client: ENetClient = %ENetClient


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer_menu.host_server_request.connect(e_net_server.start_server)
	multiplayer_menu.join_server_request.connect(e_net_client.connect_to_server)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
