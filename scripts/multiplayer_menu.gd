extends Control


signal join_server_request(ip: String, port: int)
signal host_server_request(port: int)

signal start_game_request


@onready var player_name: LineEdit = %PlayerName
@onready var host_port: LineEdit = %HostPort
@onready var host_button: Button = %HostButton
@onready var join_ip: LineEdit = %JoinIP
@onready var join_port: LineEdit = %JoinPort
@onready var join_button: Button = %JoinButton


func _ready() -> void:
	host_button.pressed.connect(on_host_server_button_pressed)
	join_button.pressed.connect(on_join_server_button_pressed)


func on_host_server_button_pressed() -> void:
	set_player_name()
	var port: int = host_port.placeholder_text.to_int() if host_port.text == "" else host_port.text.to_int()
	host_server_request.emit(port)
	host_button.disabled = true
	show_lobby(true)  # true = is host


func on_join_server_button_pressed() -> void:
	set_player_name()
	var ip: String = join_ip.placeholder_text if join_ip.text == "" else join_ip.text
	var port: int = join_port.placeholder_text.to_int() if join_port.text == "" else join_port.text.to_int()
	join_server_request.emit(ip, port)
	join_button.disabled = true
	show_lobby(false)  # false = is client

func set_player_name() -> void:
	if player_name.text.is_empty():
		PeerData.name = "Player" + str(randi_range(100_000_000, 999_999_999))
	else:
		PeerData.name = player_name.text


# Lobby UI functions
func show_lobby(is_host: bool) -> void:
	# Hide the main menu panel
	%Panel.visible = false
	# Show lobby panel (we'll create this)
	%LobbyPanel.visible = true
	# Only host sees Start button
	%StartButton.visible = is_host


func hide_lobby() -> void:
	visible = false


func _on_start_button_pressed() -> void:
	start_game_request.emit()
