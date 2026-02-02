extends Area3D


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
