extends SceneTree
## art/src/ui/*.svg → godot/ui/*.png. 아이콘은 2배로 (선명하게), 9-slice 틀(btn/panel/chip)은 1배로 (여백이 그림 픽셀 기준)
## 실행: tools/ui/render_ui.ps1

const SCALE := 2.0


func _init() -> void:
	var root := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var src := root.path_join("art/src/ui")
	var dst := root.path_join("godot/ui")
	DirAccess.make_dir_recursive_absolute(dst)
	var n := 0
	for f in DirAccess.get_files_at(src):
		if not f.ends_with(".svg"):
			continue
		var img := Image.new()
		var sc := 1.0 if f.begins_with("btn_") or f.begins_with("panel") or f.begins_with("chip_") else SCALE
		if img.load_svg_from_string(FileAccess.get_file_as_string(src.path_join(f)), sc) != OK:
			push_error("svg 실패: " + f)
			continue
		img.save_png(dst.path_join(f.get_basename() + ".png"))
		n += 1
	print("rendered %d ui images" % n)
	quit()
