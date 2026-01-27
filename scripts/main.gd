class_name Main
extends Node3D

@onready var multiplayer_menu: Control = $GUI/MultiplayerMenu
@onready var e_net_server: ENetServer = $ServerInterface/ENetServer
@onready var e_net_client: ENetClient = $ServerInterface/ENetClient


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
