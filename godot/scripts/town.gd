extends RefCounted
## 하웰 마을 허브와 길드 운영 화면 (docs/04-game-flow.md 3.1, 3.8).
## story_main.gd 의 공용 조각(_panel, _btn, _label …)을 빌려 그 화면(screen) 위에 그린다.

const G = preload("res://scripts/guild_defs.gd")
const UI = preload("res://scripts/fk_ui.gd")
const Card = preload("res://scripts/adv_card.gd")
const SDefs = preload("res://scripts/story_defs.gd")

var m  # story_main
var _sel_app := -1  # 스카우트에서 고른 지원자 번호
var _sel_job := -1  # 위탁 의뢰에서 고른 의뢰 번호


func _init(main) -> void:
	m = main


func _fs(a: int, b: int) -> int:
	return a if m.touch else b


# ── 공용 ──

## 위쪽 띠: 왼쪽 화면 이름(+ 작은 설명), 오른쪽 자원
func _head(text: String, sub := "") -> void:
	var band := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var gr := Gradient.new()
	gr.set_color(0, Color(0.03, 0.02, 0.02, 0.92))
	gr.set_color(1, Color(0.03, 0.02, 0.02, 0.0))
	gt.gradient = gr
	band.texture = gt
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.anchor_right = 1.0
	band.offset_bottom = _fs(70, 120)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.screen.add_child(band)
	var v := VBoxContainer.new()
	v.position = Vector2(_fs(16, 28), _fs(8, 14))
	v.add_theme_constant_override("separation", 0)
	m.screen.add_child(v)
	var head := Label.new()
	head.text = text
	m._outlined(head, _fs(20, 32), Color(0.97, 0.86, 0.58))
	v.add_child(head)
	if sub != "":
		var s := Label.new()
		s.text = sub
		m._outlined(s, _fs(11, 17), Color(0.86, 0.8, 0.68))
		s.add_theme_constant_override("outline_size", 4)
		v.add_child(s)
	_status_bar()


## 오른쪽 위: 금화 · 재료 · 명성 · 등급 (아이콘 + 숫자 알약)
func _status_bar() -> void:
	var h := HBoxContainer.new()
	h.anchor_left = 1.0
	h.anchor_right = 1.0
	h.offset_right = -_fs(12, 24)
	h.offset_top = _fs(8, 14)
	h.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	h.add_theme_constant_override("separation", _fs(4, 8))
	m.screen.add_child(h)
	h.add_child(_pill("res_gold", str(Game.gold), "금화"))
	for k in G.MATS:
		h.add_child(_pill("res_" + k, str(Game.mats.get(k, 0)), G.MATS[k]))
	h.add_child(_pill("res_fame", str(Game.fame), "명성"))
	h.add_child(_pill("rank_%d" % Game.rank, G.RANKS[Game.rank].name, "길드 등급", Color(1.0, 0.88, 0.6)))


func _pill(icon: String, value: String, tip: String, col := Color(1.0, 0.96, 0.86)) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.045, 0.035, 0.82)
	sb.border_color = Color(0.48, 0.36, 0.18)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(_fs(12, 18))
	sb.content_margin_left = _fs(4, 6)
	sb.content_margin_right = _fs(8, 14)
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.tooltip_text = tip
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", _fs(3, 6))
	p.add_child(h)
	h.add_child(_icon(icon, _fs(20, 32)))
	var l := Label.new()
	l.text = value
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", m.bold)
	l.add_theme_font_size_override("font_size", _fs(13, 20))
	l.add_theme_color_override("font_color", col)
	h.add_child(l)
	return p


func _icon(name: String, sz: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = UI.tex(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(sz, sz)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## 메뉴 칸: 아이콘 + 제목 + 한 줄 설명 (+ 오른쪽 위 붉은 숫자)
func _tile(icon: String, title: String, sub: String, cb: Callable, badge := 0, primary := false) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, _fs(62, 96))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary:
		b.add_theme_stylebox_override("normal", UI.sbt("btn_gold", 18, 10))
		b.add_theme_stylebox_override("hover", UI.sbt("btn_gold_hover", 18, 10))
	b.pressed.connect(cb)
	m.hover_pop(b, 1.025)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = _fs(8, 14)
	h.offset_right = -_fs(8, 14)
	h.add_theme_constant_override("separation", _fs(8, 14))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var ic := _icon(icon, _fs(40, 64))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_font_override("font", m.bold)
	t.add_theme_font_size_override("font_size", _fs(15, 24))
	t.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72) if primary else UI.GOLD)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	if sub != "":
		var s := Label.new()
		s.text = sub
		s.add_theme_font_size_override("font_size", _fs(11, 17))
		s.add_theme_color_override("font_color", Color(0.86, 0.8, 0.7))
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(s)
	if badge > 0:
		b.add_child(_badge(str(badge)))
	return b


## 붉은 동그라미 숫자 (버튼 오른쪽 위)
func _badge(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", m.bold)
	l.add_theme_font_size_override("font_size", _fs(11, 16))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.78, 0.18, 0.14)
	sb.border_color = Color(0.1, 0.05, 0.03)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = _fs(6, 9)
	sb.content_margin_right = _fs(6, 9)
	l.add_theme_stylebox_override("normal", sb)
	l.anchor_left = 1.0
	l.anchor_right = 1.0
	l.offset_left = -_fs(14, 20)
	l.offset_top = -_fs(8, 12)
	l.custom_minimum_size = Vector2(_fs(20, 30), _fs(20, 30))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## 운영 화면 배경: 지금 길드 하우스를 어둡게
func _dim_bg() -> void:
	var t: Texture2D = Game.tex(G.STAGES[Game.build].bg)
	m.bg.texture = t if t != null else Game.tex("backgrounds/scene/bg_guildhall_ruined.png")
	m.bg.modulate = Color(0.42, 0.4, 0.38)


## 오른쪽 판넬 (내용만큼만 높아진다)
func _side_panel(at := 0.13) -> VBoxContainer:
	var v: VBoxContainer = m._panel(0.6, at, 0.97, at)
	v.get_parent().grow_vertical = Control.GROW_DIRECTION_END
	return v


func _card(a: Dictionary, w: float) -> Control:
	var c := Card.new()
	c.a = a
	c.font = m.theme.default_font
	c.bold = m.bold
	c.custom_minimum_size = Vector2(w, w * 340.0 / 240.0)
	return c


func _card_w() -> float:
	return 150.0 if m.touch else 230.0


func _row_scroll(al: float, at: float, ar: float, ab: float) -> HBoxContainer:
	var sc := ScrollContainer.new()
	sc.anchor_left = al
	sc.anchor_top = at
	sc.anchor_right = ar
	sc.anchor_bottom = ab
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	m.screen.add_child(sc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10 if m.touch else 16)
	sc.add_child(h)
	return h


func _grid_scroll(al: float, at: float, ar: float, ab: float, cols: int) -> GridContainer:
	var sc := ScrollContainer.new()
	sc.anchor_left = al
	sc.anchor_top = at
	sc.anchor_right = ar
	sc.anchor_bottom = ab
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	m.screen.add_child(sc)
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 10 if m.touch else 16)
	g.add_theme_constant_override("v_separation", 10 if m.touch else 16)
	sc.add_child(g)
	return g


func _spacer(v: Control) -> void:
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)


# ── 하웰 마을 ──

func show_town() -> void:
	m._clear()
	Game.stage = "hub"
	var t: Texture2D = Game.tex("backgrounds/scene/bg_town_harwell.png")
	m.bg.texture = t if t != null else Game.tex("backgrounds/scene/bg_village_square.png")
	m.bg.modulate = Color.WHITE
	_head("하웰 마을", "제%d주 · 건물을 눌러 들어간다" % Game.week)
	var map := TownMap.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.screen.add_child(map)
	for id in G.PLACES:
		var p: Dictionary = G.PLACES[id]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		var alert := _alert(id)
		b.text = "  %s  " % p.name
		b.add_theme_font_size_override("font_size", _fs(13, 21))
		if alert:
			b.add_theme_stylebox_override("normal", UI.sbt("btn_gold", 18, 10))
			b.add_theme_stylebox_override("hover", UI.sbt("btn_gold_hover", 18, 10))
			b.add_child(_badge("!"))
		b.pressed.connect(_enter_place.bind(id))
		m.hover_pop(b, 1.06)
		map.add_child(b)
		map.spots.append([b, p.at])
	# 아래 가운데: 이번 주 할 일 한 줄
	var hint := Label.new()
	hint.text = _town_hint()
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_bottom = -_fs(12, 24)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	m._outlined(hint, _fs(13, 21), Color(1.0, 0.94, 0.78))
	hint.add_theme_constant_override("outline_size", 4)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.045, 0.035, 0.85)
	sb.border_color = Color(0.6, 0.46, 0.22)
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.content_margin_left = _fs(20, 40)
	sb.content_margin_right = _fs(20, 40)
	sb.content_margin_top = _fs(6, 10)
	sb.content_margin_bottom = _fs(6, 12)
	hint.add_theme_stylebox_override("normal", sb)
	m.screen.add_child(hint)


func _town_hint() -> String:
	if Game.picks.is_empty() and not _week_quests().is_empty():
		return "길드 하우스의 의뢰 게시판에서 이번 주 의뢰를 고르자."
	if not m._left_quests().is_empty():
		return "의뢰를 떠날 준비가 되면 길드 하우스로."
	return "이번 주 할 일을 마쳤으면 길드 하우스에서 주말을 맞자."


## 새 일이 있는 장소에 붉은 인장
func _alert(id: String) -> bool:
	match id:
		"guild":
			return (Game.picks.is_empty() and not _week_quests().is_empty()) or Game.jobs.any(func(j): return j.crew.is_empty()) and not Game.roster.is_empty()
		"chief":
			return Game.can_rank_up()
		"tavern":
			return not Game.flags.get("rumor_%d" % Game.week, false)
		"square":
			return not Game.news.is_empty() and not Game.flags.get("news_%d" % Game.week, false)
	return false


func _week_quests() -> Array:
	return SDefs.WEEK_QUESTS_BY.get(Game.week, [])


func _enter_place(id: String) -> void:
	match id:
		"guild":
			show_guild()
		_:
			show_place(id)


## 마을 그림(1920×1080, 화면을 덮게 늘림) 위의 자리에 버튼을 맞춘다
class TownMap extends Control:
	var spots: Array = []  # [버튼, 그림 위 자리(0~1)]

	func _process(_d: float) -> void:
		var s := maxf(size.x / 1920.0, size.y / 1080.0)
		var img := Vector2(1920, 1080) * s
		var off := (size - img) / 2.0
		for sp in spots:
			var b: Button = sp[0]
			var p: Vector2 = off + sp[1] * img
			b.position = (p - b.size / 2.0).clamp(Vector2(8, 60), size - b.size - Vector2(8, 8))


# ── 마을 장소 (선술집, 대장간, 잡화점, 촌장 집, 광장) ──

const PLACE_INFO := {
	"tavern": {"bg": "backgrounds/scene/bg_tavern.png", "who": "martha"},
	"smithy": {"bg": "backgrounds/scene/bg_smithy.png", "who": "greta"},
	"store": {"bg": "backgrounds/scene/bg_general_store.png", "who": "pip"},
	"chief": {"bg": "backgrounds/scene/bg_chief_house.png", "who": "tobias"},
	"square": {"bg": "backgrounds/scene/bg_village_square.png", "who": "farmer"},
}


func show_place(id: String) -> void:
	m._clear()
	var info: Dictionary = PLACE_INFO[id]
	var t: Texture2D = Game.tex(info.bg)
	m.bg.texture = t if t != null else Game.tex("backgrounds/scene/bg_village_square.png")
	m.bg.modulate = Color(0.85, 0.83, 0.8)
	_head(G.PLACES[id].name)
	# 주인 스탠딩
	var sp: Dictionary = SDefs.SPEAKERS.get(info.who, {})
	var path: String = sp.get("path", "")
	if path.count("%s") == 1:
		path = path % "neutral"
	var pt: Texture2D = Game.tex(path) if path != "" else null
	if pt != null:
		var pic := TextureRect.new()
		pic.texture = pt
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.anchor_left = 0.02
		pic.anchor_right = 0.5
		pic.anchor_top = 0.08
		pic.anchor_bottom = 1.25
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.screen.add_child(pic)
	var v := _side_panel(0.16)
	v.add_child(m._label(sp.get("name", ""), _fs(16, 26), Color(0.96, 0.84, 0.55), false))
	v.add_child(m.divider(_fs(200, 320)))
	match id:
		"tavern":
			Game.flags["rumor_%d" % Game.week] = true
			for r in G.RUMORS.get(Game.week, []):
				v.add_child(m._label("“%s”" % r, _fs(14, 22)))
			v.add_child(m._label("식재료 납품(마르타 단골도)은 다음 작업에서 연다.", _fs(12, 18), Color(0.75, 0.7, 0.62)))
		"smithy":
			v.add_child(m._label("“어서 와, 단장! 장비 사고팔기랑 강화는 곧 시작할 거야. 무기고를 지어 두면 더 세게 두드려 줄게.”", _fs(14, 22)))
			v.add_child(m._label("장비 사기·강화는 다음 작업에서 연다. 강화 상한은 길드 무기고 레벨을 따른다.", _fs(12, 18), Color(0.75, 0.7, 0.62)))
		"store":
			v.add_child(m._label("“회복약, 선물, 식재료! 뭐든 있습니다. 흥정은 환영이고요, 헤헤.”", _fs(14, 22)))
			v.add_child(m._label("소모품·선물 판매는 다음 작업에서 연다.", _fs(12, 18), Color(0.75, 0.7, 0.62)))
		"chief":
			_chief(v)
		"square":
			Game.flags["news_%d" % Game.week] = true
			if Game.news.is_empty():
				v.add_child(m._label("아직 붙은 소식이 없다. 주말이 지나면 우물가 게시판에 소식이 붙는다.", _fs(14, 22)))
			else:
				var r := RichTextLabel.new()
				r.bbcode_enabled = true
				r.fit_content = true
				r.add_theme_font_size_override("normal_font_size", _fs(14, 22))
				r.text = "\n".join(PackedStringArray(Game.news))
				v.add_child(r)
	v.add_child(m._btn("마을로", show_town))


func _chief(v: VBoxContainer) -> void:
	var next: Dictionary = G.RANKS[Game.rank + 1] if Game.rank + 1 < G.RANKS.size() else {}
	if Game.can_rank_up():
		v.add_child(m._label("“단장, 요즘 길드 이름이 이웃 마을까지 들리더군. 영주님께 올려 둔 서류가 통과됐네.”", _fs(14, 22)))
		v.add_child(m._btn("%s 길드로 승급한다" % next.name, func():
			Game.rank += 1
			Game.week_log.append("승급 · 길드가 %s 등급이 되었다" % G.RANKS[Game.rank].name)
			m._show_toast("하웰 모험가 길드 · %s 등급!" % G.RANKS[Game.rank].name)
			show_place("chief"), true))
	elif next.is_empty():
		v.add_child(m._label("“금패 길드라니. 에드릭 공이 보셨으면 좋아하셨을 게야.”", _fs(14, 22)))
	else:
		v.add_child(m._label("“다른 길드보다 빨리 크고 있어. 그 기세면 곧 %s도 받겠군.”" % next.name, _fs(14, 22)))
		v.add_child(m._label("길드 등급 %s → %s · 명성 %d / %d" % [G.RANKS[Game.rank].name, next.name, Game.fame, next.fame], _fs(13, 20), Color(0.9, 0.85, 0.6)))
	v.add_child(m._label("등급이 오르면 더 크고 보상 좋은 의뢰가 붙고, 지원자 등급도 조금 올라간다.", _fs(12, 18), Color(0.75, 0.7, 0.62)))


# ── 길드 하우스 ──

func show_guild() -> void:
	m.desk.show()


# ── 스카우트실 ──

func show_scout() -> void:
	m._clear()
	_dim_bg()
	var lv: int = Game.facilities.get("scout", 1)
	_head("스카우트실", "%d레벨 · %s" % [lv, G.FACILITIES.scout.fx[lv - 1]])
	if _sel_app < 0 and not Game.applicants.is_empty():
		_sel_app = 0
	# 왼쪽: 지원자 카드 (가운데 정렬, 크게)
	var area := CenterContainer.new()
	area.anchor_left = 0.02
	area.anchor_right = 0.58
	area.anchor_top = 0.12
	area.anchor_bottom = 0.96
	m.screen.add_child(area)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _fs(10, 22))
	area.add_child(row)
	if Game.applicants.is_empty():
		row.add_child(m._label("이번 주 지원자는 모두 계약했거나 떠났다.", _fs(14, 22)))
	var cw := _card_w() * (1.2 if Game.applicants.size() <= 3 else 1.0)
	for i in Game.applicants.size():
		var a: Dictionary = Game.applicants[i]
		var c := _card(a, cw)
		c.note = "계약금 %d" % G.GRADE_INFO[a.grade].fee
		c.selected = i == _sel_app
		c.clicked.connect(func(_c):
			_sel_app = i
			show_scout())
		m.hover_pop(c, 1.04)
		row.add_child(c)
	# 오른쪽: 고른 지원자
	var v := _side_panel(0.13)
	v.add_child(m._label("이번 주 지원자", _fs(18, 28), Color(0.96, 0.84, 0.55), false))
	v.add_child(m.divider(_fs(200, 320)))
	if _sel_app >= 0 and _sel_app < Game.applicants.size():
		var a: Dictionary = Game.applicants[_sel_app]
		var fee: int = G.GRADE_INFO[a.grade].fee
		var gi: Dictionary = G.GRADE_INFO[a.grade]
		v.add_child(m._label("%s급  %s" % [a.grade, a.name], _fs(18, 30), gi.col.lightened(0.45), false))
		v.add_child(m._label("%s · 실력 %d · 특기 %s" % [G.CLASSES[a.cls].name, a.power, ", ".join(PackedStringArray(a.tags))], _fs(13, 20)))
		v.add_child(m._label("특성: " + Card.trait_text(a.trait), _fs(13, 20), Color(0.9, 0.85, 0.65)))
		v.add_child(m._label("위탁 보상에서 %d%%를 몫으로 가져간다." % gi.share, _fs(12, 18), Color(0.8, 0.75, 0.66)))
		var full := Game.roster.size() >= Game.roster_cap()
		var b: Button = m._btn("계약한다 · 금화 %d" % fee, func():
			if Game.hire(a):
				m._show_toast("%s 이(가) 하웰 모험가 길드에 들어왔다." % a.name)
				_sel_app = -1
			show_scout(), true)
		b.disabled = Game.gold < fee or full
		v.add_child(b)
		if full:
			v.add_child(m._label("명부가 꽉 찼다. 숙소를 지으면 늘어난다.", _fs(12, 18), Color(1.0, 0.7, 0.6)))
		elif Game.gold < fee:
			v.add_child(m._label("금화가 모자란다.", _fs(12, 18), Color(1.0, 0.7, 0.6)))
	v.add_child(m._label("명부 %d / %d명 · 뽑지 않은 지원자는 주말에 떠난다. 주급은 없다." % [Game.roster.size(), Game.roster_cap()], _fs(12, 18), Color(0.8, 0.75, 0.66)))
	v.add_child(m._btn("길드로", func():
		_sel_app = -1
		show_guild()))


# ── 모험가 명부 ──

func show_roster() -> void:
	m._clear()
	_dim_bg()
	_head("모험가 명부", "%d / %d명 · 등급 순" % [Game.roster.size(), Game.roster_cap()])
	var grid := _grid_scroll(0.03, 0.12, 0.97, 0.86, 4 if m.touch else 6)
	var sorted := Game.roster.duplicate()
	sorted.sort_custom(func(x, y): return G.GRADES.find(x.grade) > G.GRADES.find(y.grade))
	for a in sorted:
		var c := _card(a, _card_w())
		if a.hurt > 0:
			c.dim = true
			c.note = "다쳐서 쉬는 중"
		elif Game.busy(a.id):
			c.note = "위탁 의뢰에 나감"
		else:
			c.note = "승급까지 성공 %d번" % maxi(0, (2 if a.trait.get("fast", false) else 3) - a.wins) if G.GRADES.find(a.grade) < 4 else "보수 몫 %d%%" % G.GRADE_INFO[a.grade].share
		grid.add_child(c)
	var h := HBoxContainer.new()
	h.anchor_left = 0.3
	h.anchor_right = 0.7
	h.anchor_top = 0.88
	h.anchor_bottom = 0.97
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	m.screen.add_child(h)
	var back: Button = m._btn("길드로", show_guild)
	back.custom_minimum_size.x = _fs(200, 320)
	h.add_child(back)


# ── 위탁 의뢰 ──

func show_jobs() -> void:
	m._clear()
	_dim_bg()
	_head("위탁 의뢰", "명부의 모험가에게 맡긴다 · 결과는 주말 장부에")
	var v: VBoxContainer = m._panel(0.02, 0.1, 0.36, 0.96)
	for i in Game.jobs.size():
		var j: Dictionary = Game.jobs[i]
		var crew: String = ", ".join(PackedStringArray(j.crew.map(func(id): return Game.adventurer(id).name))) if not j.crew.is_empty() else "맡길 사람 없음"
		var b: Button = m._btn("%s%s [%s] 실력 %d\n  → %s" % ["▶ " if i == _sel_job else "", j.name, j.tag, j.req, crew], func():
			_sel_job = i
			show_jobs())
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", _fs(12, 19))
		if not j.crew.is_empty():
			b.add_theme_stylebox_override("normal", UI.sbt("btn_gold", 18, 10))
		v.add_child(b)
	_spacer(v)
	v.add_child(m._btn("길드로", func():
		_sel_job = -1
		show_guild()))
	var side: VBoxContainer = m._panel(0.38, 0.1, 0.98, 0.42)
	if _sel_job < 0 or _sel_job >= Game.jobs.size():
		side.add_child(m._label("왼쪽에서 의뢰를 고르고, 아래 카드를 눌러 모험가를 1~3명 붙인다.", _fs(14, 22)))
		side.add_child(m._label("특기가 맞으면 실력이 25% 더 쳐진다. 보상은 메인 의뢰보다 적고, 모험가 몫을 뗀다. 실패하면 한 주 쉰다.", _fs(12, 18), Color(0.85, 0.8, 0.7)))
		return
	var j: Dictionary = Game.jobs[_sel_job]
	side.add_child(m._label("%s · 특기 %s · 필요 실력 %d" % [j.name, j.tag, j.req], _fs(16, 26), Color(0.96, 0.84, 0.55)))
	var rew := "보상 금화 %d (몫 떼기 전)" % j.gold
	if j.mat != "":
		rew += " · %s %d" % [G.MATS[j.mat], j.mat_n]
	rew += " · 명성 %d" % j.fame
	side.add_child(m._label(rew, _fs(13, 20)))
	var ch := Game.job_chance(j, j.crew)
	var ch_text: String
	if j.crew.is_empty():
		ch_text = "아직 아무도 맡지 않았다."
	elif Game.facilities.get("records", 0) >= 1:
		ch_text = "성공률 %d%%" % roundi(ch * 100)
	else:
		ch_text = "성공 가능성: %s  (기록실을 지으면 숫자로 보인다)" % ("높음" if ch >= 0.7 else ("보통" if ch >= 0.45 else "낮음"))
	side.add_child(m._label(ch_text, _fs(15, 24), Color(0.6, 1.0, 0.6) if ch >= 0.6 else Color(1.0, 0.85, 0.5)))
	# 아래: 맡길 수 있는 모험가 카드
	var row := _row_scroll(0.38, 0.44, 0.98, 0.98)
	for a in Game.roster:
		var on: bool = a.id in j.crew
		var c := _card(a, _card_w() * 0.85)
		c.selected = on
		if a.hurt > 0:
			c.dim = true
			c.note = "다쳐서 쉬는 중"
		elif Game.busy(a.id) and not on:
			c.dim = true
			c.note = "다른 의뢰에 나감"
		elif a.tags.has(j.tag):
			c.note = "특기 맞음 · 실력 ×1.25"
		c.clicked.connect(func(_c):
			if on:
				j.crew.erase(a.id)
			elif a.hurt == 0 and not Game.busy(a.id) and j.crew.size() < 3:
				j.crew.append(a.id)
			show_jobs())
		row.add_child(c)
	if Game.roster.is_empty():
		row.add_child(m._label("명부에 모험가가 없다. 스카우트실에서 계약하자.", _fs(14, 22)))


# ── 재건 공사 · 시설 ──

func show_build() -> void:
	m._clear()
	_dim_bg()
	_head("재건 공사 · 시설", "공사 %d / %d단계 · %s" % [Game.build, G.STAGES.size() - 1, G.STAGES[Game.build].name])
	var v: VBoxContainer = m._panel(0.02, 0.13, 0.4, 0.13)
	v.get_parent().grow_vertical = Control.GROW_DIRECTION_END
	v.add_child(m._label("재건 공사", _fs(18, 28), Color(0.96, 0.84, 0.55), false))
	v.add_child(_stage_track())
	v.add_child(m.divider(_fs(200, 320)))
	if Game.build + 1 < G.STAGES.size():
		var nx: Dictionary = G.STAGES[Game.build + 1]
		v.add_child(m._label("다음 공사 · %s" % nx.name, _fs(16, 26), Color(1.0, 0.88, 0.55), false))
		v.add_child(m._label(nx.desc, _fs(13, 20)))
		var c := Game.stage_cost(Game.build + 1)
		v.add_child(_cost_row(c))
		var b: Button = m._btn("공사한다", func():
			if Game.do_build():
				m._show_toast("'%s' 공사를 마쳤다! 길드 하우스가 달라졌다." % G.STAGES[Game.build].name)
			show_build(), true)
		b.disabled = not Game.can_pay(c)
		v.add_child(b)
		v.add_child(m._label("금화가 모자라면 위탁 의뢰를 꾸준히 돌리자. 공사가 늦어도 이야기는 막히지 않는다.", _fs(11, 17), Color(0.75, 0.7, 0.62)))
	else:
		v.add_child(m._label("길드 하우스 재건을 모두 마쳤다.", _fs(14, 22), Color(0.6, 1.0, 0.6)))
	v.add_child(m._btn("길드로", show_guild))
	# 시설 목록
	var st: Dictionary = G.STAGES[Game.build]
	var f: VBoxContainer = m._panel(0.42, 0.13, 0.98, 0.96)
	var top := HBoxContainer.new()
	f.add_child(top)
	var ft: Label = m._label("시설", _fs(18, 28), Color(0.96, 0.84, 0.55), false)
	ft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(ft)
	top.add_child(m._label("칸 %d / %d · 최고 %d레벨" % [Game.slots_used(), st.slots, st.max_lv], _fs(13, 20), Color(0.9, 0.85, 0.7), false))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	f.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", _fs(6, 10))
	sc.add_child(list)
	for id in G.FACILITY_ORDER:
		list.add_child(_facility_row(id, st))


## 공사 단계 줄: 마친 단계는 금색, 지금 단계는 테두리, 남은 단계는 어둡게
func _stage_track() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	for i in G.STAGES.size():
		if i > 0:
			var line := ColorRect.new()
			line.color = UI.GOLD if i <= Game.build else Color(0.3, 0.26, 0.22)
			line.custom_minimum_size = Vector2(0, 3)
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(line)
		var n := Label.new()
		n.text = str(i) if i > 0 else "폐"
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		n.custom_minimum_size = Vector2(_fs(26, 40), _fs(26, 40))
		n.add_theme_font_override("font", m.bold)
		n.add_theme_font_size_override("font_size", _fs(12, 18))
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(30)
		sb.set_border_width_all(2)
		if i < Game.build or (i == Game.build and i == 0):
			sb.bg_color = Color(0.55, 0.42, 0.18)
			sb.border_color = UI.GOLD
		elif i == Game.build:
			sb.bg_color = Color(0.75, 0.58, 0.25)
			sb.border_color = Color(1.0, 0.92, 0.65)
			sb.set_border_width_all(3)
		else:
			sb.bg_color = Color(0.12, 0.1, 0.08)
			sb.border_color = Color(0.35, 0.3, 0.25)
		n.add_theme_color_override("font_color", Color.WHITE if i <= Game.build else Color(0.55, 0.5, 0.45))
		n.add_theme_stylebox_override("normal", sb)
		n.tooltip_text = G.STAGES[i].name
		n.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(n)
	return h


## 비용: 아이콘 + 필요 수 (모자라면 붉게)
func _cost_row(c: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", _fs(6, 10))
	var items: Array = []
	if c.get("gold", 0) > 0:
		items.append(["res_gold", c.gold, Game.gold, "금화"])
	for k in G.MATS:
		if c.get(k, 0) > 0:
			items.append(["res_" + k, c[k], Game.mats.get(k, 0), G.MATS[k]])
	for it in items:
		var ok: bool = it[2] >= it[1]
		h.add_child(_pill(it[0], "%d" % it[1], "%s · 가진 것 %d" % [it[3], it[2]], Color(1.0, 0.96, 0.86) if ok else Color(1.0, 0.5, 0.42)))
	return h


func _facility_row(id: String, st: Dictionary) -> Control:
	var fd: Dictionary = G.FACILITIES[id]
	var lv: int = Game.facilities.get(id, 0)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.06, 0.75) if lv > 0 else Color(0.06, 0.05, 0.04, 0.6)
	sb.border_color = Color(0.5, 0.38, 0.2) if lv > 0 else Color(0.25, 0.21, 0.17)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(_fs(6, 12))
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", _fs(8, 14))
	p.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", _fs(6, 10))
	v.add_child(name_row)
	name_row.add_child(m._label(fd.name, _fs(14, 22), UI.GOLD if lv > 0 else Color(0.7, 0.65, 0.58), false))
	# 레벨 칸: ◆ 지은 레벨, ◇ 남은 레벨
	var pips := ""
	for i in fd.max:
		pips += "◆" if i < lv else "◇"
	name_row.add_child(m._label(pips, _fs(12, 18), Color(1.0, 0.82, 0.4) if lv > 0 else Color(0.45, 0.4, 0.35), false))
	v.add_child(m._label(fd.fx[lv - 1] if lv > 0 else "지으면: " + fd.fx[0], _fs(11, 17), Color(0.86, 0.8, 0.7) if lv > 0 else Color(0.65, 0.6, 0.55)))
	if lv > 0 and lv < fd.max:
		v.add_child(m._label("다음: " + fd.fx[lv], _fs(10, 15), Color(0.6, 0.56, 0.5)))
	var c := Game.fac_next_cost(id)
	if lv >= fd.max:
		h.add_child(m._label("최고 레벨", _fs(12, 18), Color(0.6, 1.0, 0.6), false))
	elif c.is_empty():
		var why: String = "재건 공사 필요" if lv > 0 or Game.slots_used() < st.slots else "빈 칸 없음"
		var l: Label = m._label(why, _fs(11, 17), Color(0.55, 0.5, 0.45), false)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
	else:
		var r := VBoxContainer.new()
		r.add_theme_constant_override("separation", 4)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(r)
		r.add_child(_cost_row(c))
		var b: Button = m._btn("짓기" if lv == 0 else "%d레벨로" % (lv + 1), func():
			if Game.upgrade(id):
				m._show_toast("%s %d레벨!" % [fd.name, Game.facilities[id]])
			show_build())
		b.disabled = not Game.can_pay(c)
		b.custom_minimum_size.y = _fs(34, 46)
		r.add_child(b)
	return p


# ── 주말 장부 ──

func show_ledger(e: Dictionary, then: Callable) -> void:
	m._clear()
	m.bg.texture = Game.tex("backgrounds/scene/bg_guildhall_camp_night.png")
	m.bg.modulate = Color(0.7, 0.68, 0.65)
	var v: VBoxContainer = m._panel(0.14, 0.06, 0.86, 0.94)
	v.add_child(m._label("단장의 장부 · 제%d주" % e.week, _fs(20, 34), Color(0.96, 0.84, 0.55), false))
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", _fs(13, 21))
	var t := ""
	for ln in e.lines:
		var col := "#e8dcc4"
		if ln.begins_with("수입"):
			col = "#9fe39a"
		elif ln.begins_with("지출"):
			col = "#ffc08a"
		elif ln.begins_with("실패"):
			col = "#ff9a8a"
		elif ln.begins_with("승급") or ln.begins_with("재건"):
			col = "#f2d38a"
		t += "[color=%s]· %s[/color]\n" % [col, ln]
	if e.lines.is_empty():
		t = "이번 주는 적을 게 없었다.\n"
	t += "\n[b]이번 주 수입 %d · 지출 %d · 남은 금화 %d[/b]" % [e.income, e.spend, Game.gold]
	r.text = t
	v.add_child(r)
	v.add_child(m._btn("소식 보기", then, true))
