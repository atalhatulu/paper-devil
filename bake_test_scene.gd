extends Node3D

func _ready():
    var nav_region = NavigationRegion3D.new()
    var nav_mesh = NavigationMesh.new()
    nav_mesh.agent_height = 1.8
    nav_mesh.agent_radius = 0.5
    nav_mesh.agent_max_climb = 0.6
    nav_mesh.agent_max_slope = 45.0
    nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
    nav_region.navigation_mesh = nav_mesh
    add_child(nav_region)
    
    var t0 = Time.get_ticks_msec()
    nav_region.bake_navigation_mesh(false)
    var t1 = Time.get_ticks_msec()
    print('Ready bake took:', t1 - t0, 'ms')
    print('Polys:', nav_mesh.get_polygon_count())
    if nav_mesh.get_polygon_count() > 0:
        ResourceSaver.save(nav_mesh, 'res://scenes/world/world_nav_mesh.tres')
        print('SAVED world_nav_mesh.tres!')
    get_tree().quit()
