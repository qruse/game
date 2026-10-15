extends SceneTree
## art/src/icons/skills/*.svg → art/final/icons/skills/*.png (256px) + 한눈에 보는 시트 art/src/icons/skills_sheet.png
## 실행: tools/icons/render_icons.ps1

const SIZE := 256


func _init() -> void:
	var root := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var src := root.path_join("art/src/icons/skills")
	var dst := root.path_join("art/final/icons/skills")
	DirAccess.make_dir_recursive_absolute(dst)
	var files: Array = Array(DirAccess.get_files_at(src)).filter(func(f): return f.ends_with(".svg"))
	files.sort()
	var cols := 4
	var sheet := Image.create(cols * (SIZE / 2 + 8), int(ceil(files.size() / float(cols))) * (SIZE / 2 + 8), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.12, 0.11, 0.1))
	for i in files.size():
		var text := FileAccess.get_file_as_string(src.path_join(files[i]))
		var img := Image.new()
		var err := img.load_svg_from_string(text, SIZE / 128.0)
		if err != OK:
			push_error("svg 실패: " + files[i])
			continue
		img.save_png(dst.path_join(files[i].get_basename() + ".png"))
		var small := img.duplicate()
		small.resize(SIZE / 2, SIZE / 2, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(small, Rect2i(0, 0, SIZE / 2, SIZE / 2), Vector2i((i % cols) * (SIZE / 2 + 8) + 4, (i / cols) * (SIZE / 2 + 8) + 4))
	sheet.save_png(root.path_join("art/src/icons/skills_sheet.png"))
	print("rendered %d icons" % files.size())
	quit()
