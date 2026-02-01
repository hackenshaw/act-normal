extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body):
	# Only run on server
	if !multiplayer.is_server():
		return
	
	# Ignore NPCs for now
	if body.is_npc:
		return
	
	# Notify GameManager
	get_tree().get_root().get_node("Main").on_player_entered_location(int(body.name), get_parent().name)

func _on_body_exited(body):
	if !multiplayer.is_server():
		return
	
	if body.is_npc:
		return
	
	print("Player ", body.name, " exited ", get_parent().name)


func _on_detection_area_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
