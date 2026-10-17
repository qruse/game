extends Control
## 모험가 카드 (일러스트 없음). 틀 그림은 tools/icons/adventurer_cards.py → tools/ui/render_ui.ps1 로 구운 godot/ui/card_frame_*.png,
## 직업 문장은 godot/ui/cls_*.png. 글자는 위에 겹친 Ink 가 그린다. 카드 좌표계는 SVG 와 같은 240×340.
## (호환 렌더러에서 한 _draw 안에 그림과 글자를 섞으면 그림이 하얗게 나와서 그림은 TextureRect 로 따로 둔다)

signal clicked(card)

const G = preload("res://scripts/guild_defs.gd")
const UI = preload("res://scripts/fk_ui.gd")
const INK := Color(0.11, 0.07, 0.05)

var a := {}  # 모험가
var font: Font
var bold: Font
var selected := false
var dim := false  # 다쳤거나 다른 일에 나감
var note := ""  # 카드 아래 덧붙이는 말 (계약금, 부상 등)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	var frame := TextureRect.new()
	frame.texture = UI.tex("card_frame_" + a.grade)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.set_anchors_preset(PRESET_FULL_RECT)
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(frame)
	var icon := TextureRect.new()
	icon.texture = UI.tex("cls_" + a.cls)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.anchor_left = 78.0 / 240.0
	icon.anchor_right = 162.0 / 240.0
	icon.anchor_top = 62.0 / 340.0
	icon.anchor_bottom = 146.0 / 340.0
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(icon)
	var ink := Ink.new()
	ink.card = self
	ink.set_anchors_preset(PRESET_FULL_RECT)
	ink.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(ink)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()


static func trait_text(t: Dictionary) -> String:
	var s: String = t.name
	if t.has("chance"):
		s += " · %s성공률 %+d%%" % [(t.tag + " ") if t.has("tag") else "", roundi(t.chance * 100)]
	if t.has("gold"):
		s += " · 보상 %+d%%" % roundi(t.gold * 100)
	if t.get("safe", false):
		s += " · 실패해도 안 다침"
	if t.get("fast", false):
		s += " · 승급이 빠름"
	return s


## 카드 위 글자·태그·선택 테두리
class Ink extends Control:
	var card

	func _text(p: Vector2, s: String, sz: float, col: Color, f: Font, outline := 0) -> void:
		var k := size.x / 240.0
		var fs := maxi(8, int(sz * k))
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(p.x * k - w / 2.0, p.y * k)
		if outline > 0:
			draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, INK)
		draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	func _draw() -> void:
		var a: Dictionary = card.a
		var font: Font = card.font
		var bold: Font = card.bold
		var k := size.x / 240.0
		var gcol: Color = G.GRADE_INFO[a.grade].col
		_text(Vector2(44, 57), a.grade, 30, Color.WHITE, bold, 4)
		_text(Vector2(194, 41), "실력", 10, Color(0.95, 0.9, 0.78), font)
		_text(Vector2(194, 59), str(a.power), 18, Color.WHITE, bold)
		_text(Vector2(120, 198), a.name, 17, Color.WHITE, bold, 3)
		_text(Vector2(120, 226), G.CLASSES[a.cls].name, 14, INK, bold)
		var tags: Array = a.tags
		var w := 54.0
		var x0 := 120.0 - (tags.size() * w + (tags.size() - 1) * 8.0) / 2.0
		for i in tags.size():
			var r := Rect2(Vector2(x0 + i * (w + 8.0), 236) * k, Vector2(w, 22) * k)
			var sb := StyleBoxFlat.new()
			sb.bg_color = gcol
			sb.set_corner_radius_all(int(11 * k))
			sb.border_color = INK
			sb.set_border_width_all(maxi(1, int(1.5 * k)))
			draw_style_box(sb, r)
			_text(Vector2(x0 + i * (w + 8.0) + w / 2.0, 252), tags[i], 13, Color.WHITE, bold)
		_text(Vector2(120, 290), card.trait_text(a.trait), 13, INK, font)
		var note: String = card.note if card.note != "" else "보수 몫 %d%%" % G.GRADE_INFO[a.grade].share
		_text(Vector2(120, 316), note, 13, gcol.darkened(0.3), bold)
		if card.dim:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
		if card.selected:
			draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color(1.0, 0.85, 0.35), false, 5.0 * k)
