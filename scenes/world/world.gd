extends Node3D

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var yellow_gate: Node3D = get_node_or_null("YellowGate")
@onready var wave_manager: Node3D = get_node_or_null("WaveManager")

func _ready() -> void:
	if nav_region:
		nav_region.bake_navigation_mesh(false)
	
	if yellow_gate and wave_manager:
		yellow_gate.gate_opened.connect(wave_manager.on_north_arena_entered)
