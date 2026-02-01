class_name GameHUD
extends Control

@onready var task_label: Label = %TaskLabel
@onready var timer_label: Label = %TimerLabel



func show_hud(task_description: String) -> void:
	visible = true
	task_label.text = task_description

func update_timer(time_left: float) -> void:
	timer_label.text = "%02d" % int(ceil(time_left))

func hide_hud() -> void:
	visible = false
	task_label.text = ""
	timer_label.text = ""
