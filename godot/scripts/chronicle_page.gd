extends Control
## 써 내려가는 연대기 한 페이지 (docs/04-game-flow.md 3.3).
## 양피지 위에 지나온 칸만 보이고, 칸을 끝낼 때마다 다음 칸으로 잉크 선이 그어지며 연대기 문장이 한 줄씩 적힌다.

const Defs = preload("res://scripts/story_defs.gd")
const K = preload("res://scripts/ui_kit.gd")

const PAPER := K.PAPER
const PAPER_DK := Color(0.62, 0.5, 0.32)
const INK := K.INK
const INK_SOFT := Color(0.37, 0.31, 0.23, 0.6)
const RED_INK := K.WAX
const GOLD := K.BRASS

var bold: Font
var touch := false
var quest := {}
var visited: Array = []
var lines: Array = []
var luck := 0
var done := false  # 완성: 인장과 금테
var title := ""

var _line_t := 1.0  # 가장 최근 잉크 선이 그어진 정도
var _text_t := 1.0  # 가장 최근 문장이 써진 정도
var _t := 0.0
var _prev_n := 0
var _prev_lines := 0
var _noise: NoiseTexture2D


func _ready() -> void:
	_noise = NoiseTexture2D.new()
	_noise.width = 256
	_noise.height = 256
	_noise.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = 0.04
	n.fractal_octaves = 4
	_noise.noise = n


func set_state(q: Dictionary, v: Array, ls: Array, lk: int, d: bool, ttl: String) -> void:
	quest = q
	title = ttl
	if v.size() > _prev_n and _prev_n > 0:
		_line_t = 0.0
	_prev_n = v.size()
	if ls.size() > _prev_lines:
		_text_t = 0.0
	_prev_lines = ls.size()
	visited = v.duplicate()
	lines = ls.duplicate()
	luck = lk
	done = d
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_line_t = minf(1.0, _line_t + delta * 1.6)
	_text_t = minf(1.0, _text_t + delta * 1.2)
	queue_redraw()


func _page_rect() -> Rect2:
	var m := K.px(30)
	return Rect2(Vector2(m, m), size - Vector2(m * 2.0, m * 2.0))


func _node_pos(id: String) -> Vector2:
	var r := _page_rect()
	var p: Vector2 = quest.nodes[id].pos
	# 칸 지도는 머리 아래부터 페이지 64% 높이까지
	var top := K.px(170)
	var bot := r.size.y * 0.62
	return r.position + Vector2(r.size.x * (0.08 + p.x * 0.84), top + (bot - top) * p.y)


func _draw() -> void:
	if quest.is_empty():
		return
	var r := _page_rect()
	var pad := K.px(44)
	# 종이: 그림자, 바탕, 결, 가장자리 얼룩, 안쪽 선
	draw_rect(Rect2(r.position + Vector2(0, K.px(10)), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, PAPER)
	if _noise != null:
		draw_texture_rect(_noise, r, true, Color(0.55, 0.42, 0.22, 0.10))
	for i in 10:
		var c := PAPER_DK
		c.a = 0.07 * (1.0 - i / 10.0)
		draw_rect(r.grow(-i * K.px(3)), c, false, K.px(3))
	draw_rect(r.grow(-K.px(14)), Color(INK, 0.22), false, 1.0)
	if done:
		draw_rect(r.grow(-K.px(8)), GOLD, false, maxf(2.0, K.px(3)))
	# 머리: 머리말 + 의뢰 이름 + 행운 주사위
	var x0 := r.position.x + pad
	var y0 := r.position.y + pad
	draw_string(K.f_cap, Vector2(x0, y0 + K.px(12)), "하웰 모험가 길드 연대기 · 장부 %d쪽" % Game.week, HORIZONTAL_ALIGNMENT_LEFT, -1, K.pxi(12), Color("8a6a3a"))
	draw_string(K.f_title, Vector2(x0, y0 + K.px(56)), quest.get("name", title), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - pad * 2.0 - K.px(200), K.pxi(36), INK)
	var lx := r.end.x - pad
	draw_string(K.f_cap, Vector2(lx - K.px(160), y0 + K.px(12)), "행운 주사위", HORIZONTAL_ALIGNMENT_RIGHT, K.px(160), K.pxi(11), K.INK_2)
	var dr := K.px(10)
	for i in Game.LUCK_MAX:
		var c := Vector2(lx - dr - i * dr * 2.9, y0 + K.px(40))
		var on := (Game.LUCK_MAX - 1 - i) < luck
		var pts := PackedVector2Array([c + Vector2(0, -dr), c + Vector2(dr, 0), c + Vector2(0, dr), c + Vector2(-dr, 0)])
		if on:
			draw_colored_polygon(pts, K.BLUE)
		else:
			pts.append(pts[0])
			draw_polyline(pts, Color(INK, 0.35), 1.5, true)
	var hy := y0 + K.px(80)
	draw_line(Vector2(x0, hy), Vector2(r.end.x - pad, hy), Color(INK, 0.55), maxf(1.0, K.px(2)))
	draw_line(Vector2(x0, hy + K.px(5)), Vector2(r.end.x - pad, hy + K.px(5)), INK_SOFT, 1.0)
	# 지나온 길: 잉크 선 (가장 최근 선은 그려지는 중)
	for i in range(1, visited.size()):
		var a := _node_pos(visited[i - 1])
		var b := _node_pos(visited[i])
		var k := 1.0 if i < visited.size() - 1 else _line_t
		_ink_line(a, a.lerp(b, k))
	# 칸
	var nr := K.px(25)
	for i in visited.size():
		var id: String = visited[i]
		var n: Dictionary = quest.nodes[id]
		var p := _node_pos(id)
		if i == visited.size() - 1 and _line_t < 1.0:
			continue
		var cur := i == visited.size() - 1 and not done
		var red: bool = n.t in ["battle", "end"]
		if cur:
			draw_circle(p, nr * (1.45 + 0.08 * sin(_t * 4.0)), Color(K.BLUE, 0.16))
		draw_circle(p + Vector2(0, K.px(3)), nr, Color(0, 0, 0, 0.12))
		draw_circle(p, nr, K.PAPER_SEL if cur else PAPER.darkened(0.04))
		draw_arc(p, nr, 0, TAU, 40, K.BLUE if cur else (RED_INK if red else INK), maxf(2.0, K.px(2.5)), true)
		var kind: Dictionary = Defs.NODE_KIND[n.t]
		draw_string(K.f_title, p + Vector2(-nr, K.px(8)), kind.mark, HORIZONTAL_ALIGNMENT_CENTER, nr * 2.0, K.pxi(22), RED_INK if n.t == "battle" else INK)
		var label: String = n.get("title", kind.name)
		draw_string(K.f_bold, p + Vector2(-K.px(120), nr + K.px(24)), label, HORIZONTAL_ALIGNMENT_CENTER, K.px(240), K.pxi(14), K.INK_2)
	# 아직 쓰이지 않은 여백: 다음 칸 자리에 물음표
	if not done and _line_t >= 1.0 and not visited.is_empty():
		var last := _node_pos(visited[-1])
		var q := last + Vector2(nr * 3.4, 0)
		if q.x < r.end.x - pad:
			_ink_line(last + Vector2(nr + K.px(6), 0), q - Vector2(K.px(14), 0), true)
			draw_string(K.f_title, q + Vector2(-K.px(20), K.px(9)), "?", HORIZONTAL_ALIGNMENT_CENTER, K.px(40), K.pxi(26), INK_SOFT)
	# 기록 (아래쪽): 머리말 + 최근 네 줄
	var ty := r.position.y + r.size.y * 0.70
	draw_string(K.f_cap, Vector2(x0, ty), "기록", HORIZONTAL_ALIGNMENT_LEFT, -1, K.pxi(12), Color("8a6a3a"))
	draw_line(Vector2(x0 + K.px(40), ty - K.px(4)), Vector2(r.end.x - pad, ty - K.px(4)), INK_SOFT, 1.0)
	var show := lines.slice(maxi(0, lines.size() - 4))
	var lh := K.px(30)
	for i in show.size():
		var s: String = show[i]
		if i == show.size() - 1 and _text_t < 1.0:
			s = s.substr(0, int(s.length() * _text_t))
		var ly := ty + K.px(34) + i * lh
		var dc := Vector2(x0 + K.px(5), ly - K.px(6))
		var d := K.px(4)
		draw_colored_polygon(PackedVector2Array([dc + Vector2(0, -d), dc + Vector2(d, 0), dc + Vector2(0, d), dc + Vector2(-d, 0)]), K.BRASS_DK)
		draw_string(K.f_body, Vector2(x0 + K.px(20), ly), s, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - pad * 2.0 - K.px(20), K.pxi(17), INK if i == show.size() - 1 else K.INK_2)
	# 완성 도장 (붉은 테 글자, 기울여 찍힘)
	if done:
		var sp := Vector2(r.end.x - K.px(150), r.end.y - K.px(110))
		draw_set_transform(sp, deg_to_rad(-11))
		var sw := K.px(118)
		var sh := K.px(56)
		var col := Color(RED_INK, 0.85)
		draw_rect(Rect2(-sw / 2.0, -sh / 2.0, sw, sh), col, false, maxf(2.0, K.px(3)))
		draw_rect(Rect2(-sw / 2.0 + K.px(5), -sh / 2.0 + K.px(5), sw - K.px(10), sh - K.px(10)), Color(col, 0.5), false, 1.0)
		draw_string(K.f_title, Vector2(-sw / 2.0, K.px(11)), "완성", HORIZONTAL_ALIGNMENT_CENTER, sw, K.pxi(30), col)
		draw_set_transform(Vector2.ZERO)


## 손으로 그은 잉크 선: 살짝 흔들리게 여러 토막으로
func _ink_line(a: Vector2, b: Vector2, dashed := false) -> void:
	var n := maxi(2, int(a.distance_to(b) / 14.0))
	var prev := a
	for i in range(1, n + 1):
		var k := float(i) / n
		var p := a.lerp(b, k) + Vector2(0, sin(k * 17.0 + a.x * 0.01) * 2.0)
		if not dashed or i % 2 == 0:
			draw_line(prev, p, INK if not dashed else INK_SOFT, 3.0 if not dashed else 2.0, true)
		prev = p
