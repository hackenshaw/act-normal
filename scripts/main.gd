class_name Main
extends Node3D

@onready var multiplayer_menu: MultiplayerMenu = %MultiplayerMenu
@onready var e_net_server: ENetServer = %ENetServer
@onready var e_net_client: ENetClient = %ENetClient
@onready var players: PlayersManager = %Players


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer_menu.host_server_request.connect(e_net_server.start_server)
	multiplayer_menu.join_server_request.connect(e_net_client.connect_to_server)

	e_net_server.spawn_host_player.connect(players.spawn_host_player)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
