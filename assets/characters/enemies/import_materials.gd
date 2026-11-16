@tool
extends EditorScenePostImport
## Soldier palette is linear glTF vertex color, rather than textures.

func _post_import(scene: Node) -> Object:
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		for surface in node.mesh.get_surface_count():
			var colors: PackedColorArray = node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
			var material := node.mesh.surface_get_material(surface) as StandardMaterial3D
			if material != null and not colors.is_empty():
				material.vertex_color_use_as_albedo = true
				material.vertex_color_is_srgb = false
	return scene
