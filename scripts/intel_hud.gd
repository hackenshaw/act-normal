class_name IntelHUD
extends Control

@onready var intel_label: Label = %IntelLabel

var collected_intel: Array = []


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("inventory"):
		visible = !visible

func add_intel(intel_text: String) -> void:
	collected_intel.append(intel_text)
	update_intel_display()


func clear_intel() -> void:
	collected_intel.clear()
	
func update_intel_display() -> void:
	if collected_intel.is_empty():
		intel_label.text = "No intel yet"
	else:
		intel_label.text = "\n".join(collected_intel)
