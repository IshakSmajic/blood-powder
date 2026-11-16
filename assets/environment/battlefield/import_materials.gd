@tool
extends EditorScenePostImport
## The supplied map stores its palette in glTF COLOR_0, in linear space.

func _post_import(scene: Node) -> Object:
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		for surface in node.mesh.get_surface_count():
			var material := node.mesh.surface_get_material(surface) as StandardMaterial3D
			if material != null:
				material.vertex_color_use_as_albedo = true
				material.vertex_color_is_srgb = false
	return scene
