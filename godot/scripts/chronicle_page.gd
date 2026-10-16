extends Control
## 써 내려가는 연대기 한 페이지 (docs/04-game-flow.md 3.3).
## 양피지 위에 지나온 칸만 보이고, 칸을 끝낼 때마다 다음 칸으로 잉크 선이 그어지며 연대기 문장이 한 줄씩 적힌다.

const Defs = preload("res://scripts/story_defs.gd")
const UI = preload("res://scripts/fk_ui.gd")

const PAPER := Color(0.91, 0.84, 0.68)
const PAPER_DK := Color(0.72, 0.6, 0.42)
const INK := Color(0.22, 0.14, 0.09)
const INK_SOFT := Color(0.35, 0.25, 0.16, 0.85)
const RED_INK := Color(0.55, 0.12, 0.1)
const GOLD := Color(0.78, 0.6, 0.22)

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
var _dice_on: Texture2D = UI.tex("fate_on")
var _dice_off: Texture2D = UI.tex("fate_off")


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
	return Rect2(Vector2(size.x * 0.03, size.y * 0.04), Vector2(size.x * 0.94, size.y * 0.92))


func _node_pos(id: String) -> Vector2:
	var r := _page_rect()
	var p: Vector2 = quest.nodes[id].pos
	# 칸 지도는 페이지 위쪽 60% 안에
	return r.position + Vector2(r.size.x * (0.06 + p.x * 0.88), r.size.y * (0.14 + p.y * 0.46))


func _draw() -> void:
	if quest.is_empty():
		return
	var font := get_theme_default_font()
	var r := _page_rect()
	# 양피지: 그림자, 바탕, 가장자리 얼룩, 테두리
	draw_rect(Rect2(r.position + Vector2(8, 10), r.size), Color(0, 0, 0, 0.45))
	draw_rect(r, PAPER)
	for i in 14:
		var k := i / 14.0
		var c := PAPER_DK
		c.a = 0.10 * (1.0 - k)
		draw_rect(r.grow(-i * 4.0), c, false, 4.0)
	draw_rect(r.grow(-18), INK_SOFT, false, 1.5)
	if done:
		draw_rect(r.grow(-10), GOLD, false, 4.0)
		draw_rect(r.grow(-24), GOLD, false, 1.5)
	var fs := int(clampf(size.y * 0.032, 14, 30))
	# 제목
	draw_string(bold, r.position + Vector2(40, 30 + fs * 1.2), title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 260, fs + 4, INK)
	draw_line(r.position + Vector2(40, 40 + fs * 1.5), Vector2(r.end.x - 40, r.position.y + 40 + fs * 1.5), INK_SOFT, 1.5)
	# 행운 주사위 트레이 (오른쪽 위)
	var dsz := fs * 1.6
	for i in 3:
		var t: Texture2D = _dice_on if i < luck else _dice_off
		if t != null:
			draw_texture_rect(t, Rect2(Vector2(r.end.x - 40 - (3 - i) * (dsz + 6), r.position.y + 22), Vector2(dsz, dsz)), false)
	# 지나온 길: 잉크 선 (가장 최근 선은 그려지는 중)
	for i in range(1, visited.size()):
		var a := _node_pos(visited[i - 1])
		var b := _node_pos(visited[i])
		var k := 1.0 if i < visited.size() - 1 else _line_t
		_ink_line(a, a.lerp(b, k))
	# 칸
	var nr := fs * 1.3
	for i in visited.size():
		var id: String = visited[i]
		var n: Dictionary = quest.nodes[id]
		var p := _node_pos(id)
		if i == visited.size() - 1 and _line_t < 1.0:
			continue
		var cur := i == visited.size() - 1 and not done
		if cur:
			draw_circle(p, nr * (1.35 + 0.08 * sin(_t * 4.0)), Color(0.9, 0.7, 0.25, 0.35))
		draw_circle(p, nr, PAPER.lightened(0.15) if cur else PAPER.darkened(0.06))
		draw_arc(p, nr, 0, TAU, 40, RED_INK if n.t in ["battle", "end"] else INK, 3.0, true)
		var kind: Dictionary = Defs.NODE_KIND[n.t]
		draw_string(bold, p + Vector2(-nr, fs * 0.38), kind.mark, HORIZONTAL_ALIGNMENT_CENTER, nr * 2.0, fs, RED_INK if n.t == "battle" else INK)
		var label: String = n.get("title", kind.name)
		draw_string(font, p + Vector2(-140, nr + fs * 1.1), label, HORIZONTAL_ALIGNMENT_CENTER, 280, int(fs * 0.8), INK)
	# 아직 쓰이지 않은 여백: 다음 칸 자리에 물음표
	if not done and _line_t >= 1.0 and not visited.is_empty():
		var last := _node_pos(visited[-1])
		var q := last + Vector2(nr * 3.2, 0)
		if q.x < r.end.x - 40:
			_ink_line(last + Vector2(nr + 6, 0), q - Vector2(fs * 0.6, 0), true)
			draw_string(bold, q + Vector2(-fs, fs * 0.4), "?", HORIZONTAL_ALIGNMENT_CENTER, fs * 2.0, fs + 6, INK_SOFT)
	# 연대기 문장 (아래쪽)
	var ty := r.position.y + r.size.y * 0.7
	draw_line(Vector2(r.position.x + 40, ty - fs), Vector2(r.end.x - 40, ty - fs), INK_SOFT, 1.0)
	var show := lines.slice(maxi(0, lines.size() - 4))
	for i in show.size():
		var s: String = show[i]
		if i == show.size() - 1 and _text_t < 1.0:
			s = s.substr(0, int(s.length() * _text_t))
		draw_string(font, Vector2(r.position.x + 48, ty + i * fs * 1.45 + fs * 0.4), "— " + s, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 96, int(fs * 0.85), INK)
	# 완성 인장
	if done:
		var sp := Vector2(r.end.x - 110, r.end.y - 110)
		draw_circle(sp, 58, Color(0.6, 0.1, 0.1, 0.92))
		draw_arc(sp, 50, 0, TAU, 40, Color(0.85, 0.35, 0.3), 2.0, true)
		draw_string(bold, sp + Vector2(-60, fs * 0.35), "완성", HORIZONTAL_ALIGNMENT_CENTER, 120, fs, Color(1.0, 0.9, 0.8))


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
