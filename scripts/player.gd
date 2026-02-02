extends CharacterBody3D

const COLORS = {
	"red": Color.RED,
	"blue": Color.BLUE,
	"green": Color.GREEN,
	"yellow": Color.YELLOW,
	"black": Color.BLACK,
	"white": Color.WHITE,
	"brown": Color.BROWN,
	"purple": Color.PURPLE,
	"orange": Color.ORANGE,
	"pink": Color.PINK
}

var traits = {
	"hair_color": "white",
	"shirt_color": "white",
	"pants_color": "white",
	"has_hat": false,
	"has_glasses": false,
	"has_backpack": false,
}


@onready var camera_mount: Node3D = $CameraMount
@onready var visuals: Node3D = $Visuals
@onready var camera_3d: Camera3D = %Camera3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var _last_synced_position: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3.ZERO
var _lerp_smooth: float = 30.0

var is_npc: bool = false
# NPC variables
var npc_target_location: String = ""
var npc_idle_timer: float = 0.0
var npc_state: String = "idle"  # "idle" or "moving"
var npc_path: PackedVector3Array
var npc_active: bool = false
var npc_stuck_timer: float = 0.0
var npc_last_position: Vector3 = Vector3.ZERO

var npc_locations: Dictionary = {}

@export var spawn_pos := Vector3.ZERO
@export var sensitivity_horizontal: float = 0.5
@export var sensitivity_vertical: float = 0.5
@export var min_pitch: float = -30.0
@export var max_pitch: float = 30.0

@export var npc_idle_min: float = 0.0
@export var npc_idle_max: float = 10.0

var current_task_location: String = ""

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
	if spawn_pos != Vector3.ZERO:
		global_position = spawn_pos



func randomize_traits():
	var color_names = COLORS.keys()
	traits.hair_color = color_names[randi() % color_names.size()]
	traits.shirt_color = color_names[randi() % color_names.size()]
	traits.pants_color = color_names[randi() % color_names.size()]
	traits.has_hat = randf() > 0.5
	traits.has_glasses = randf() > 0.5
	traits.has_backpack = randf() > 0.5



func apply_traits():
	if %Hair.material_override == null:
		%Hair.material_override = StandardMaterial3D.new()
	if %Torso.material_override == null:
		%Torso.material_override = StandardMaterial3D.new()
	if %Legs.material_override == null:
		%Legs.material_override = StandardMaterial3D.new()
		
	%Hair.get_active_material(0).albedo_color = COLORS[traits.hair_color]
	%Torso.get_active_material(0).albedo_color = COLORS[traits.shirt_color]
	%Legs.get_active_material(0).albedo_color = COLORS[traits.pants_color]
	%Hat.visible = traits.has_hat
	%Glasses.visible = traits.has_glasses
	%Backpack.visible = traits.has_backpack


func _ready() -> void:
	if is_npc:
		camera_3d.queue_free()
		set_process_input(false)
		# Random initial idle so NPCs don't all move together
		npc_idle_timer = randf_range(npc_idle_min, npc_idle_max)
		npc_state = "idle"
	if not is_multiplayer_authority():
		camera_3d.queue_free()



func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity_horizontal))
		visuals.rotate_y(deg_to_rad(event.relative.x * sensitivity_horizontal))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sensitivity_vertical))
		# Clamp the vertical rotation
		camera_mount.rotation_degrees.x = clamp(camera_mount.rotation_degrees.x, min_pitch, max_pitch)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): 
		# Detect when synchronizer updates position (it changed from last frame)
		if global_position != _last_synced_position:
			_target_position = global_position
			_last_synced_position = global_position
			
		# Interpolate toward target
		global_position = global_position.lerp(_target_position, _lerp_smooth * delta)
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_npc:
		# Handle jump.
		#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			#velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
			visuals.look_at(global_position + direction)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else: # it is an npc
		npc_process(delta)
		
	move_and_slide()


func npc_process(delta: float) -> void:
	match npc_state:
		"idle":
			npc_idle_timer -= delta
			velocity.x = 0
			velocity.z = 0
			if npc_idle_timer <= 0:
				pick_new_npc_target()
		
		"moving":
			# Stuck detection
			if global_position.distance_to(npc_last_position) < 0.01:
				npc_stuck_timer += delta
				if npc_stuck_timer > npc_idle_max:
					# Stuck - pick a new target
					npc_stuck_timer = 0.0
					pick_new_npc_target()
					return
			else:
				npc_stuck_timer = 0.0
				npc_last_position = global_position
			if npc_path.is_empty():
				# Arrived at destination - start idle
				npc_state = "idle"
				npc_idle_timer = randf_range(npc_idle_min, npc_idle_max)
				velocity.x = 0
				velocity.z = 0
			else:
				var next_point = npc_path[0]
				#print("  next_point: ", next_point, " current: ", global_position, " distance: ", global_position.distance_to(next_point))
				var direction = (next_point - global_position).normalized()
				
				# Check if we're close enough to this waypoint
				if global_position.distance_to(next_point) < 0.5:
					npc_path.remove_at(0)
				else:
					velocity.x = direction.x * SPEED
					velocity.z = direction.z * SPEED
					var look_dir = Vector3(direction.x, 0.0, direction.z)
					if look_dir.length_squared() > 0.001:
						visuals.look_at(global_position + look_dir)
	
	

func pick_new_npc_target() -> void:
	var location_names = npc_locations.keys()
	
	# Pick a random location that's different from current
	var new_target = npc_target_location
	while new_target == npc_target_location:
		new_target = location_names[randi() % location_names.size()]
	
	npc_target_location = new_target
	
	# Get target position
	var target_pos = npc_locations[npc_target_location].get_node("MeetingPoint").global_position
	#print("NPC ", name, " from: ", global_position, " to: ", target_pos, " is_server: ", multiplayer.is_server())

	# Wait for nav map to sync
	await get_tree().physics_frame
	
	# Get navigation path
	var map = get_world_3d().navigation_map
	var start = NavigationServer3D.map_get_closest_point(map, global_position)
	var end = NavigationServer3D.map_get_closest_point(map, target_pos)
	
	npc_path = NavigationServer3D.map_get_path(
		map,
		start,
		end,
		true
	)
	#print("  path result: ", npc_path)
	npc_state = "moving"


func activate_npc() -> void:
	npc_active = true
	npc_idle_timer = randf_range(npc_idle_min, npc_idle_max)
	npc_state = "idle"


@rpc("any_peer", "call_remote", "reliable")
func set_spawn_position(pos):
	#print("Set Spawn Position RPC called")
	global_position = pos


@rpc("any_peer", "call_remote", "reliable")
func set_traits(new_traits: Dictionary):
	#print("Player ", name, " received traits: ", new_traits, " from peer: ", multiplayer.get_remote_sender_id())
	traits = new_traits
	apply_traits()
	
	
@rpc("any_peer", "call_local", "reliable")
func receive_task(task_description: String, location_name: String):
	current_task_location = location_name
	if is_multiplayer_authority():
		# Find GameHUD and show task
		get_tree().get_root().get_node("Main/GUI/GameHUD").show_hud(task_description)

@rpc("any_peer", "call_local", "reliable")
func receive_intel(intel_text: String):
	if is_multiplayer_authority():
		get_tree().get_root().get_node("Main/GUI/IntelHUD").add_intel(intel_text)
	
	
