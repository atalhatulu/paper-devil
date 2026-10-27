extends SceneTree

var baked = false

func _process(delta) -> bool:
    if baked:
        return false
    baked = true
    var world = root.get_child(root.get_child_count() - 1)
    print('World in tree:', world.name)
    var nav_region = NavigationRegion3D.new()
    var nav_mesh = NavigationMesh.new()
    nav_mesh.agent_height = 1.8
    nav_mesh.agent_radius = 0.5
    nav_mesh.agent_max_climb = 0.6
    nav_mesh.agent_max_slope = 45.0
    nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
    nav_region.navigation_mesh = nav_mesh
    world.add_child(nav_region)
    
    var source_geometry = NavigationMeshSourceGeometryData3D.new()
    NavigationServer3D.parse_source_geometry_data(nav_mesh, source_geometry, world)
    NavigationServer3D.bake_from_source_geometry_data(nav_mesh, source_geometry)
    
    print('Baked vertices count:', nav_mesh.get_vertices().size())
    print('Baked polygon count:', nav_mesh.get_polygon_count())
    
    if nav_mesh.get_polygon_count() > 0:
        ResourceSaver.save(nav_mesh, 'res://scenes/world/world_nav_mesh.tres')
        print('Saved res://scenes/world/world_nav_mesh.tres successfully!')
    quit()
    return true

func _init():
    change_scene_to_file('res://scenes/world/world.tscn')
