extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var core_instance: MeshInstance3D

func setup(start_pos: Vector3, end_pos: Vector3, tracer_color: Color = Color(2.5, 1.8, 0.5, 1.0)) -> void:
	var dist = start_pos.distance_to(end_pos)
	if dist < 0.05:
		queue_free()
		return

	global_position = (start_pos + end_pos) * 0.5
	look_at(end_pos, Vector3.UP)

	# 1. Dış Katman: Çizgi roman siyah mürekkep dış konturu
	var ink_mat = StandardMaterial3D.new()
	ink_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink_mat.albedo_color = Color(0.04, 0.04, 0.06, 0.95)
	ink_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var outer_cyl = CylinderMesh.new()
	# Tapered aksiyon çizgisi: Namluya yakın kısım kalın, hedefe giden uç sivri
	outer_cyl.top_radius = 0.012
	outer_cyl.bottom_radius = 0.042
	outer_cyl.height = dist
	outer_cyl.material = ink_mat

	mesh_instance.mesh = outer_cyl
	mesh_instance.rotation_degrees.x = 90.0

	# 2. İç Katman: Parlak kağıt dolgusu / çizgi roman vurgu çekirdeği
	core_instance = MeshInstance3D.new()
	add_child(core_instance)

	var core_mat = StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Çekirdek: Beyaz ağırlıklı, silahın rengiyle hafif tonlanmış
	var core_color = Color.WHITE.lerp(tracer_color, 0.3)
	core_color.a = 1.0
	core_mat.albedo_color = core_color
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var inner_cyl = CylinderMesh.new()
	inner_cyl.top_radius = 0.005
	inner_cyl.bottom_radius = 0.022
	inner_cyl.height = dist * 0.99
	inner_cyl.material = core_mat

	core_instance.mesh = inner_cyl
	core_instance.rotation_degrees.x = 90.0

	# 3. Çizgi Roman Kapanış Animasyonu (Snap & Collapse)
	# Sabit lazer çubuğu gibi kalmak yerine anında enine büzülüp ileri fırlar
	var duration = randf_range(0.07, 0.09)
	var tween = create_tween()

	# Çizginin enine çöküşü (kalınlık sıfıra iner)
	tween.parallel().tween_property(self, "scale:x", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale:y", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Hızlı ileri atılma (merminin uçup gitme hissi)
	var forward_vec = (end_pos - start_pos).normalized() * minf(dist * 0.2, 2.5)
	tween.parallel().tween_property(self, "global_position", global_position + forward_vec, duration)

	# Saydamlık sönümlenmesi
	tween.parallel().tween_property(ink_mat, "albedo_color:a", 0.0, duration)
	tween.parallel().tween_property(core_mat, "albedo_color:a", 0.0, duration)

	tween.tween_callback(queue_free)
