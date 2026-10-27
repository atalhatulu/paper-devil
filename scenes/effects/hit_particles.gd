extends CPUParticles3D

func activate(pos: Vector3, hit_direction: Vector3 = Vector3.ZERO) -> void:
	global_position = pos
	if hit_direction.length_squared() > 0.01:
		direction = (hit_direction.normalized() + Vector3(0, 0.4, 0)).normalized()
	restart()
	emitting = true
	get_tree().create_timer(lifetime + 0.1).timeout.connect(queue_free)
