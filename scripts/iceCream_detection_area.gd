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
	
	print("something entered ", body.name)
	# Ignore NPCs for now
	if body.is_npc:
		return
	
	print("Player ", body.name, " entered ", get_parent().name)

func _on_body_exited(body):
	if !multiplayer.is_server():
		return
	
	if body.is_npc:
		return
	
	print("Player ", body.name, " exited ", get_parent().name)
