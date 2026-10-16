extends Control
## 니케식 짧은 이야기 장면: 배경 + 스탠딩 1~2명 + 아래 대사창(이름표).
## 누르면 다음 줄. 오른쪽 위에 자동 / 건너뛰기. 건너뛰면 요약 한 줄을 남긴다 (docs/04-game-flow.md 3.7)

signal finished(summary: String, skipped: bool)

const Defs = preload("res://scripts/story_defs.gd")
const CPS := 38.0  # 초당 글자 수
const AUTO_WAIT := 1.6

var touch := false
var bold: Font

var _scene := {}
var _i := 0
var _t := 0.0
var _auto := false
var _auto_t := 0.0
var _slots := ["", ""]  # 왼쪽·오른쪽에 선 사람
var _last := ""

var _bg: TextureRect
var _cg: TextureRect
var _pics: Array = []
var _box: PanelContainer
var _name: Label
var _text: RichTextLabel
var _auto_btn: Button


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(PRESET_FULL_RECT)
	black.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(black)
	_bg = _full_tex()
	for i in 2:
		var p := TextureRect.new()
		p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(p)
		_pics.append(p)
	_cg = _full_tex()
	# 대사창
	_box = PanelContainer.new()
	_box.mouse_filter = MOUSE_FILTER_IGNORE
	_box.anchor_left = 0.04
	_box.anchor_right = 0.96
	_box.anchor_top = 0.72
	_box.anchor_bottom = 0.97
	add_child(_box)
	var v := VBoxContainer.new()
	v.mouse_filter = MOUSE_FILTER_IGNORE
	_box.add_child(v)
	_name = Label.new()
	_name.add_theme_font_override("font", bold)
	_name.add_theme_font_size_override("font_size", 18 if touch else 28)
	_name.add_theme_color_override("font_color", Color(0.96, 0.82, 0.5))
	v.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.mouse_filter = MOUSE_FILTER_IGNORE
	_text.size_flags_vertical = SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 18 if touch else 30)
	_text.add_theme_font_size_override("italics_font_size", 18 if touch else 30)
	v.add_child(_text)
	# 자동 / 건너뛰기
	var h := HBoxContainer.new()
	h.anchor_left = 1.0
	h.anchor_right = 1.0
	h.offset_left = -330 if not touch else -230
	h.offset_right = -16
	h.offset_top = 14
	h.alignment = BoxContainer.ALIGNMENT_END
	add_child(h)
	_auto_btn = _small("자동", _toggle_auto)
	h.add_child(_auto_btn)
	h.add_child(_small("건너뛰기", _skip))
	visible = false


func _full_tex() -> TextureRect:
	var t := TextureRect.new()
	t.set_anchors_preset(PRESET_FULL_RECT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _small(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = "  %s  " % text
	b.focus_mode = FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 34 if touch else 46)
	b.add_theme_font_size_override("font_size", 13 if touch else 18)
	b.pressed.connect(cb)
	return b


func play(id: String) -> void:
	_scene = Defs.SCENES[id]
	_i = 0
	_slots = ["", ""]
	_last = ""
	_auto = false
	_auto_btn.text = "  자동  "
	_bg.texture = Game.tex(_scene.get("bg", ""))
	_cg.texture = Game.tex(_scene.get("cg", ""))
	visible = true
	_show_line()


func _show_line() -> void:
	var ln: Array = _scene.lines[_i]
	var who: String = ln[0]
	var cg_on: bool = _cg.texture != null and _i < int(_scene.get("cg_lines", 0))
	_cg.visible = cg_on
	if who != "" and not cg_on:
		_stand(who, ln[1])
	# 말하는 사람은 밝게, 듣는 사람은 어둡게. 해설이면 둘 다 어둡게
	for s in 2:
		var p: TextureRect = _pics[s]
		p.visible = _slots[s] != "" and not cg_on
		var lit: bool = _slots[s] == who
		p.modulate = Color.WHITE if lit else Color(0.5, 0.5, 0.55)
	var sp: Dictionary = Defs.SPEAKERS.get(who, {})
	_name.text = sp.get("name", "")
	_name.visible = who != ""
	_text.text = ("[i]%s[/i]" % ln[2]) if who == "" else ln[2]
	_text.visible_ratio = 0.0
	_t = 0.0
	_auto_t = 0.0


## 스탠딩 세우기: 이미 서 있으면 표정만 바꾸고, 새 사람은 방금 말한 사람의 반대쪽에 선다
func _stand(who: String, expr: String) -> void:
	var slot := _slots.find(who)
	if slot == -1:
		var last_slot := _slots.find(_last) if _last != "" else -1
		slot = 1 if last_slot == 0 else 0
		if _slots[0] == "" and last_slot == -1:
			slot = 0
		_slots[slot] = who
	_last = who
	var sp: Dictionary = Defs.SPEAKERS.get(who, {})
	var path: String = sp.get("path", "")
	if path == "":
		_pics[slot].texture = null
		return
	if path.count("%s") == 2:
		path = path % [sp.outfit, expr if expr != "" else "neutral"]
	elif path.count("%s") == 1:
		path = path % _npc_expr(expr)
	var t := Game.tex(path)
	if t == null and path.contains("_portrait_"):
		t = Game.tex(path.get_slice("_portrait_", 0) + "_portrait_%s_neutral.png" % sp.get("outfit", "combat"))
	_pics[slot].texture = t


## 동료 표정 이름을 NPC 표정 3종으로
func _npc_expr(e: String) -> String:
	if e in ["smile", "positive", "embarrassed"]:
		return "positive"
	if e in ["angry", "sad", "negative"]:
		return "negative"
	return "neutral"


func _layout() -> void:
	# 스탠딩: 화면 높이의 1.35배로 크게 세워 무릎 아래는 대사창 뒤로 숨긴다
	var h := size.y * 1.32
	var w := h * 2.0 / 3.0
	for s in 2:
		var p: TextureRect = _pics[s]
		var cx := size.x * (0.27 if s == 0 else 0.73)
		p.position = Vector2(cx - w / 2.0, size.y * 0.03)
		p.size = Vector2(w, h)


func _process(delta: float) -> void:
	if not visible:
		return
	_layout()
	_t += delta
	var n := maxi(1, _text.get_total_character_count())
	_text.visible_ratio = clampf(_t * CPS / n, 0.0, 1.0)
	if _auto and _text.visible_ratio >= 1.0:
		_auto_t += delta
		if _auto_t >= AUTO_WAIT:
			_next()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if _text.visible_ratio < 1.0:
			_t = 999.0
		else:
			_next()
		accept_event()


func _next() -> void:
	_i += 1
	if _i >= _scene.lines.size():
		visible = false
		finished.emit(_scene.get("summary", ""), false)
		return
	_show_line()


func _toggle_auto() -> void:
	_auto = not _auto
	_auto_btn.text = "  자동 ▶  " if _auto else "  자동  "


func _skip() -> void:
	visible = false
	finished.emit(_scene.get("summary", ""), true)
