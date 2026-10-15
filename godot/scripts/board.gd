extends Control
## 전투 칸 그리기 (그레이박스). 누른 칸은 cell_clicked 시그널로 넘긴다.

signal cell_clicked(cell: Vector2i)

const NO_CELL := Vector2i(-1, -1)

const TILE_COL := {
	".": Color(0.40, 0.50, 0.30), ",": Color(0.45, 0.37, 0.25), "^": Color(0.62, 0.60, 0.46),
	"\"": Color(0.20, 0.38, 0.18), "~": Color(0.20, 0.18, 0.14), "=": Color(0.28, 0.45, 0.66),
	"t": Color(0.40, 0.50, 0.30), "#": Color(0.40, 0.50, 0.30), "o": Color(0.40, 0.50, 0.30),
	"h": Color(0.40, 0.50, 0.30), "X": Color(0.24, 0.24, 0.26), "v": Color(0.06, 0.06, 0.08),
}
const TILE_TXT := {
	",": "험지", "^": "높은 곳", "\"": "덤불", "~": "기름", "=": "물", "#": "엄폐물",
	"o": "기름 항아리", "h": "건초", "X": "벽", "v": "낭떠러지",
}

var battle = null
var move_cells: Array = []
var warn_cells: Array = []
var target_cells: Array = []
var area_cells: Array = []
var pending := NO_CELL
var selected_uid := -1
var dim_acted := true
var speed := 1.0
var sprites := {}  # uid -> Texture2D (SD 그림이 있으면 동그라미 대신 그린다)
var bg_tex: Texture2D = null  # 전투 맵 배경 그림. 있으면 칸 영역을 battle.bg_grid 에 맞춰 깐다

## SD 캔버스(512) 안에서 발끝 기준선 위치 (style-guide.md 6절: 아래에서 24px)
const SD_FEET := 488.0 / 512.0
const SD_SCALE := 1.3

var _disp := {}
var _queue := {}
var _floats: Array = []
var _ts := 64.0
var _origin := Vector2.ZERO


func reset() -> void:
	_disp.clear()
	_queue.clear()
	_floats.clear()
	for u in battle.units:
		_disp[u.uid] = Vector2(u.pos)


func queue_move(uid: int, path: Array) -> void:
	if not _queue.has(uid):
		_queue[uid] = []
	for c in path:
		_queue[uid].append(Vector2(c))


func add_float(cell: Vector2i, text: String, col: Color) -> void:
	var n := 0
	for f in _floats:
		if f.cell == cell and f.t < 0.5:
			n += 1
	_floats.append({"cell": cell, "text": text, "color": col, "t": -0.3 * n})


func busy() -> bool:
	for q in _queue.values():
		if not q.is_empty():
			return true
	return false


func _process(delta: float) -> void:
	if battle == null:
		return
	var step := delta * 8.0 * speed
	for u in battle.units:
		if not _disp.has(u.uid):
			_disp[u.uid] = Vector2(u.pos)
		var q: Array = _queue.get(u.uid, [])
		var goal: Vector2 = q[0] if not q.is_empty() else Vector2(u.pos)
		var nv: Vector2 = _disp[u.uid].move_toward(goal, step)
		_disp[u.uid] = nv
		if not q.is_empty() and nv.distance_to(goal) < 0.001:
			q.pop_front()
	for f in _floats:
		f.t += delta * speed
	_floats = _floats.filter(func(f): return f.t < 1.4)
	queue_redraw()


func _rect(c: Vector2i) -> Rect2:
	return Rect2(_origin + Vector2(c) * _ts, Vector2(_ts, _ts))


func _draw() -> void:
	if battle == null:
		return
	var cols: int = battle.cols
	var rows: int = battle.rows
	_ts = floorf(minf(size.x / cols, size.y / rows))
	_origin = ((size - Vector2(cols, rows) * _ts) / 2.0).floor()
	var font := get_theme_default_font()
	var fs := int(_ts * 0.13)
	var line_w := maxf(2.0, _ts * 0.025)
	var has_bg: bool = bg_tex != null and battle.bg_grid.z > 0
	if has_bg:
		var s := _ts / float(battle.bg_grid.z)
		draw_texture_rect(bg_tex, Rect2(_origin - Vector2(battle.bg_grid.x, battle.bg_grid.y) * s, Vector2(bg_tex.get_size()) * s), false)

	for y in rows:
		for x in cols:
			var c := Vector2i(x, y)
			var t: String = battle.tile(c)
			var r := _rect(c)
			if not has_bg:
				draw_rect(r, TILE_COL.get(t, Color.MAGENTA))
			elif t != ".":
				var tc: Color = TILE_COL.get(t, Color.MAGENTA)
				tc.a = 0.55
				draw_rect(r, tc)
			match t:
				"#":
					var rr := r.grow(-_ts * 0.2)
					draw_rect(rr, Color(0.55, 0.38, 0.20))
					draw_rect(rr, Color(0.28, 0.18, 0.08), false, line_w)
					draw_line(rr.position, rr.end, Color(0.28, 0.18, 0.08), line_w)
				"o":
					draw_circle(r.get_center() + Vector2(0, _ts * 0.04), _ts * 0.22, Color(0.72, 0.42, 0.18))
					draw_rect(Rect2(r.get_center() + Vector2(-_ts * 0.08, -_ts * 0.26), Vector2(_ts * 0.16, _ts * 0.1)), Color(0.5, 0.3, 0.12))
				"h":
					draw_rect(r.grow(-_ts * 0.16), Color(0.86, 0.72, 0.34))
					draw_rect(r.grow(-_ts * 0.16), Color(0.55, 0.42, 0.15), false, line_w)
				"^":
					draw_rect(Rect2(r.position, Vector2(_ts, _ts * 0.14)), Color(0.78, 0.76, 0.62))
				"\"":
					for i in 3:
						draw_circle(r.position + Vector2(_ts * (0.25 + 0.25 * i), _ts * 0.62), _ts * 0.14, Color(0.15, 0.30, 0.13))
			if battle.fire.has(c):
				draw_rect(r, Color(1.0, 0.42, 0.08, 0.5))
			if battle.smoke.has(c):
				draw_rect(r, Color(0.85, 0.85, 0.85, 0.45))
			draw_rect(r, Color(0, 0, 0, 0.18 if has_bg else 0.3), false, 1.0)
			var label: String = TILE_TXT.get(t, "")
			if battle.fire.has(c):
				label = ("불 " + label).strip_edges()
			if battle.smoke.has(c):
				label = ("연기 " + label).strip_edges()
			if label != "":
				draw_string(font, r.position + Vector2(5, fs + 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.8))

	for c in move_cells:
		draw_rect(_rect(c), Color(0.3, 0.6, 1.0, 0.35))
	for c in warn_cells:
		draw_rect(_rect(c).grow(-3), Color(1.0, 0.6, 0.15, 0.9), false, line_w)
	for c in area_cells:
		draw_rect(_rect(c), Color(1.0, 0.9, 0.3, 0.25))
	for c in target_cells:
		draw_rect(_rect(c), Color(1.0, 0.25, 0.2, 0.3))
		draw_rect(_rect(c).grow(-2), Color(1.0, 0.35, 0.3, 0.9), false, line_w)
	if pending != NO_CELL:
		draw_rect(_rect(pending).grow(-1), Color(1.0, 0.95, 0.4), false, line_w * 2.0)

	for u in battle.units:
		if u.removed:
			continue
		var p: Vector2 = _origin + (_disp.get(u.uid, Vector2(u.pos)) + Vector2(0.5, 0.45)) * _ts
		var rad := _ts * (0.36 if u.is_boss else 0.31)
		var col: Color = u.color
		if u.downed:
			col = Color(0.35, 0.35, 0.35)
		var tex: Texture2D = sprites.get(u.uid)
		var top_y := p.y - rad
		if tex != null:
			# SD: 발끝을 칸 아래쪽에 맞추고, 발밑에 팀 색 타원
			var feet := p + Vector2(0, _ts * 0.40)
			if u.uid == selected_uid:
				_ellipse(feet, _ts * 0.40, _ts * 0.15, Color(1.0, 1.0, 0.6))
			_ellipse(feet, _ts * 0.34, _ts * 0.11, Color(col, 0.85))
			var sz := _ts * SD_SCALE
			var rect := Rect2(feet.x - sz / 2.0, feet.y - sz * SD_FEET, sz, sz)
			if u.side == "enemy":
				rect = Rect2(rect.position + Vector2(sz, 0), Vector2(-sz, sz))
			var mod := Color.WHITE
			if u.downed:
				mod = Color(0.4, 0.4, 0.4, 0.8)
			elif dim_acted and u.side == "ally" and u.acted:
				mod = Color(0.6, 0.6, 0.6)
			draw_texture_rect(tex, rect, false, mod)
			top_y = feet.y - sz * 0.8
			rad = _ts * 0.40
		else:
			if u.uid == selected_uid:
				draw_circle(p, rad + line_w * 2.5, Color(1.0, 1.0, 0.6))
			draw_circle(p + Vector2(0, rad * 0.18), rad, Color(0, 0, 0, 0.35))
			draw_circle(p, rad, col)
			draw_arc(p, rad, 0, TAU, 40, Color(0.95, 0.95, 0.9) if u.side == "ally" else Color(0.15, 0.02, 0.02), line_w * 1.4)
			var fb := int(rad * 0.95)
			draw_string(font, p + Vector2(-rad, fb * 0.36), u.short, HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, fb, Color.WHITE)
			if dim_acted and u.side == "ally" and u.acted and not u.downed:
				draw_circle(p, rad, Color(0, 0, 0, 0.4))
		var bw := _ts * 0.8
		var bp := p + Vector2(-bw / 2.0, rad + _ts * 0.04)
		var bh := maxf(5.0, _ts * 0.06)
		draw_rect(Rect2(bp, Vector2(bw, bh)), Color(0, 0, 0, 0.7))
		var ratio := float(u.hp) / float(u.max_hp)
		draw_rect(Rect2(bp, Vector2(bw * ratio, bh)), Color(0.35, 0.85, 0.35) if u.side == "ally" else Color(0.9, 0.3, 0.25))
		draw_string(font, bp + Vector2(0, bh + fs), "%d/%d" % [u.hp, u.max_hp], HORIZONTAL_ALIGNMENT_CENTER, bw, fs, Color.WHITE)
		if u.side == "ally" and not u.downed:
			draw_rect(Rect2(bp + Vector2(0, -bh * 0.6), Vector2(bw * u.resolve / 100.0, bh * 0.45)), Color(1.0, 0.85, 0.3))
		var sts: Array = battle.status_names(u)
		if u.downed:
			sts = ["쓰러짐"]
		if not sts.is_empty():
			draw_string(font, Vector2(p.x - _ts / 2.0, top_y - 4), " ".join(PackedStringArray(sts)), HORIZONTAL_ALIGNMENT_CENTER, _ts, fs, Color(1.0, 0.9, 0.6))
		if u.brand > 0:
			var bpos := p + Vector2(rad * 0.85, -rad * 0.85)
			draw_circle(bpos, _ts * 0.12, Color(0.55, 0.25, 0.75))
			draw_string(font, bpos + Vector2(-_ts * 0.12, fs * 0.4), str(u.brand), HORIZONTAL_ALIGNMENT_CENTER, _ts * 0.24, fs + 2, Color.WHITE)

	var ff := int(_ts * 0.2)
	for f in _floats:
		if f.t < 0.0:
			continue
		var fp: Vector2 = _origin + (Vector2(f.cell) + Vector2(0.5, 0.3)) * _ts - Vector2(0, f.t * _ts * 0.45)
		var a := clampf(1.4 - f.t, 0.0, 1.0)
		var fc: Color = f.color
		fc.a = a
		draw_string_outline(font, fp - Vector2(_ts, 0), f.text, HORIZONTAL_ALIGNMENT_CENTER, _ts * 2.0, ff, 6, Color(0, 0, 0, a))
		draw_string(font, fp - Vector2(_ts, 0), f.text, HORIZONTAL_ALIGNMENT_CENTER, _ts * 2.0, ff, fc)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _gui_input(ev: InputEvent) -> void:
	if battle == null:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var c := Vector2i(((ev.position - _origin) / _ts).floor())
		if battle.in_bounds(c):
			cell_clicked.emit(c)
