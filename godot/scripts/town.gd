extends RefCounted
## 하웰 마을 허브와 길드 운영 화면 (docs/04-game-flow.md 3.1, 3.8).
## 디자인 규칙은 ui_kit.gd (확정 시안: design/mockups/guild_desk_v5.html). 길드 하우스 로비는 guild_desk.gd.

const G = preload("res://scripts/guild_defs.gd")
const K = preload("res://scripts/ui_kit.gd")
const Desk = preload("res://scripts/guild_desk.gd")
const Card = preload("res://scripts/adv_card.gd")
const SDefs = preload("res://scripts/story_defs.gd")
const Talk = preload("res://scripts/talk.gd")
const P = preload("res://scripts/party_defs.gd")
const FDefs = preload("res://scripts/fk_defs.gd")

const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

var m  # story_main
var _sel_app := -1  # 스카우트에서 고른 지원자 번호
var _sel_job := -1  # 위탁 의뢰에서 고른 의뢰 번호
var _smith_sel := ""  # 대장간에서 고른 동료


func _init(main) -> void:
	m = main


# ── 공용 ──

## 운영 화면 틀: 배경(지금 길드 하우스, 어둡게) + 그늘 + 왼쪽 위 돌아가기·제목 + 오른쪽 위 자원
func _frame(title: String, cap: String, back: Callable, bg := "", dim := 0.5) -> Control:
	m._clear()
	var path: String = bg if bg != "" else G.STAGES[Game.build].bg
	var t: Texture2D = Game.tex(path)
	m.bg.texture = t if t != null else Game.tex("backgrounds/scene/bg_guildhall_ruined.png")
	m.bg.modulate = Color(dim, dim * 0.98, dim * 0.96)
	var s: Control = m.screen
	Desk.shade(s)
	var h := K.hbox(14)
	h.position = Vector2(K.px(26), K.px(22))
	s.add_child(h)
	var b := K.btn_sub("", "i_back", back, 46, 46)
	b.tooltip_text = "돌아가기"
	h.add_child(b)
	var v := K.vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	if cap != "":
		v.add_child(K.shadowed(K.cap(cap)))
	v.add_child(K.shadowed(K.title(title, 30)))
	s.add_child(Desk.resource_bar())
	return s


## 오른쪽 카드 (내용만큼 높아진다)
func _side(width := 560.0, top := 92.0) -> VBoxContainer:
	var c := K.card(20, 22)
	c.anchor_left = 1.0
	c.anchor_right = 1.0
	c.offset_left = -K.px(30 + width)
	c.offset_right = -K.px(30)
	c.offset_top = K.px(top)
	m.screen.add_child(c)
	var v := K.vbox(10)
	c.add_child(v)
	return v


func _card(a: Dictionary, w: float) -> Control:
	var c := Card.new()
	c.a = a
	c.font = K.f_body
	c.bold = K.f_bold
	c.custom_minimum_size = Vector2(w, w * 340.0 / 240.0)
	return c


func _card_w() -> float:
	return K.px(190)


func _hr() -> ColorRect:
	var r := ColorRect.new()
	r.color = K.HAIR
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 비용 줄: 아이콘 + 필요 수 (모자라면 붉게)
func _cost(c: Dictionary, size := 15.0) -> HBoxContainer:
	var h := K.hbox(12)
	if c.get("gold", 0) > 0:
		h.add_child(_cost_item("res_gold", Game.gold, c.gold, size))
	for k in G.MATS:
		if c.get(k, 0) > 0:
			h.add_child(_cost_item("res_" + k, Game.mats.get(k, 0), c[k], size))
	return h


func _cost_item(icon: String, have: int, need: int, size: float) -> Control:
	var h := K.hbox(5)
	h.add_child(K.icon(icon, size + 4, Color.WHITE))
	h.add_child(K.num(str(need), size, Color.WHITE if have >= need else K.BAD))
	h.tooltip_text = "가진 것 %d" % have
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	return h


## 그림 위 아래쪽 한 줄 안내 (대사 띠와 같은 모양)
func _hint(text: String) -> void:
	var box := Desk.SayBox.new()
	for sd in [["left", 20], ["right", 60], ["top", 12], ["bottom", 13]]:
		box.add_theme_constant_override("margin_" + sd[0], K.pxi(sd[1]))
	box.add_child(K.label(text, 17, Color.WHITE))
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = K.px(30)
	box.offset_bottom = -K.px(28)
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	m.screen.add_child(box)


# ── 하웰 마을 ──

const PLACE_ICON := {"guild": "i_sword", "tavern": "i_mug", "smithy": "i_anvil", "store": "i_shop", "chief": "i_house", "square": "i_well"}


func show_town() -> void:
	m._clear()
	Game.stage = "hub"
	var t: Texture2D = Game.tex("backgrounds/scene/bg_town_harwell.png")
	m.bg.texture = t if t != null else Game.tex("backgrounds/scene/bg_village_square.png")
	m.bg.modulate = Color.WHITE
	var s: Control = m.screen
	# 위쪽만 살짝 어둡게
	var top := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill_to = Vector2(0, 1)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.16, 0.82, 1.0])
	gr.colors = PackedColorArray([Color(0.03, 0.04, 0.08, 0.6), Color(0.03, 0.04, 0.08, 0), Color(0.03, 0.04, 0.08, 0), Color(0.03, 0.04, 0.08, 0.55)])
	gt.gradient = gr
	top.texture = gt
	top.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(top)
	# 왼쪽 위: 문장 + 마을 이름 + 주차
	var h := K.hbox(14)
	h.position = Vector2(K.px(30), K.px(22))
	s.add_child(h)
	h.add_child(K.icon("emblem_harwell", 54, Color.WHITE))
	var v := K.vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(K.shadowed(K.cap("건물을 눌러 들어간다")))
	v.add_child(K.shadowed(K.title("하웰 마을", 32)))
	h.add_child(Desk.week_stamp())
	s.add_child(Desk.resource_bar())
	var map := TownMap.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(map)
	for id in G.PLACES:
		var p: Dictionary = G.PLACES[id]
		var plate := _plate(id, p.name, _alert(id))
		map.add_child(plate)
		map.spots.append([plate, p.at])
	_hint(_town_hint())


## 건물 이름표: 남색 판 + 선 아이콘 + 이름 (+ 붉은 !)
func _plate(id: String, text: String, alert: bool) -> Button:
	var normal := K.sb_flat(Color(0.05, 0.075, 0.13, 0.9), Color(K.BRASS, 0.7) if alert else K.LINE, 1, 10)
	var hover := K.sb_flat(K.PAPER, K.BLUE, 0, 10)
	hover.border_width_bottom = K.pxi(3)
	for sb in [normal, hover]:
		sb.content_margin_left = K.px(12)
		sb.content_margin_right = K.px(16)
		sb.content_margin_top = K.px(7)
		sb.content_margin_bottom = K.px(7)
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = K.pxi(8)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var h := K.hbox(8)
	b.add_child(h)
	var ic := K.icon(PLACE_ICON.get(id, "i_house"), 20, K.BRASS_HI)
	h.add_child(ic)
	var l := K.bold(text, 16, Color.WHITE)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	# 버튼 크기 = 안쪽 내용 + 여백
	h.position = Vector2(K.px(12), K.px(7))
	b.custom_minimum_size = h.get_combined_minimum_size() + Vector2(K.px(28), K.px(14))
	h.resized.connect(func(): b.custom_minimum_size = h.size + Vector2(K.px(28), K.px(14)))
	if alert:
		var bd := K.badge("!")
		bd.position = Vector2(-K.px(8), -K.px(8))
		b.add_child(bd)
	b.mouse_entered.connect(func():
		ic.modulate = K.BLUE
		l.add_theme_color_override("font_color", K.INK))
	b.mouse_exited.connect(func():
		ic.modulate = K.BRASS_HI
		l.add_theme_color_override("font_color", Color.WHITE))
	b.pressed.connect(_enter_place.bind(id))
	return b


func _town_hint() -> String:
	if not Game.flags.get("picked_%d" % Game.week, false) and not _week_quests().is_empty():
		return "길드 하우스에서 이번 의뢰를 고르자."
	if not m._left_quests().is_empty():
		return "의뢰를 떠날 준비가 되면 길드 하우스로."
	return "할 일을 마쳤으면 길드 하우스에서 장부를 정리하자."


## 새 일이 있는 장소에 붉은 표시
func _alert(id: String) -> bool:
	match id:
		"guild":
			return Game.bond_ready("nora") > 0 or (not Game.flags.get("picked_%d" % Game.week, false) and not _week_quests().is_empty()) or (Game.jobs.any(func(j): return j.crew.is_empty()) and not Game.roster.is_empty())
		"chief":
			return Game.can_rank_up()
		"tavern":
			return not Game.flags.get("rumor_%d" % Game.week, false) or Game.bond_ready("martha") > 0
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


## 마을 그림(1920×1080, 화면을 덮게 늘림) 위의 자리에 이름표를 맞춘다
class TownMap extends Control:
	var spots: Array = []  # [이름표, 그림 위 자리(0~1)]

	func _process(_d: float) -> void:
		var s := maxf(size.x / 1920.0, size.y / 1080.0)
		var img := Vector2(1920, 1080) * s
		var off := (size - img) / 2.0
		for sp in spots:
			var b: Control = sp[0]
			var p: Vector2 = off + sp[1] * img
			b.size = b.get_combined_minimum_size()
			b.position = (p - b.size / 2.0).clamp(Vector2(8, 90), size - b.size - Vector2(8, 8))


# ── 마을 장소 (선술집, 대장간, 잡화점, 촌장 집, 광장) ──

const PLACE_INFO := {
	"tavern": {"bg": "backgrounds/scene/bg_tavern.png", "who": "martha", "cap": "단골 술집"},
	"smithy": {"bg": "backgrounds/scene/bg_smithy.png", "who": "wolfram", "cap": "무기와 갑옷"},
	"store": {"bg": "backgrounds/scene/bg_general_store.png", "who": "pip", "cap": "회복약 · 선물 · 식재료"},
	"chief": {"bg": "backgrounds/scene/bg_chief_house.png", "who": "tobias", "cap": "길드 등급"},
	"square": {"bg": "backgrounds/scene/bg_village_square.png", "who": "farmer", "cap": "소식 게시판"},
}


func show_place(id: String) -> void:
	var info: Dictionary = PLACE_INFO[id]
	_frame(G.PLACES[id].name, info.cap, show_town, info.bg, 0.86)
	# 주인 스탠딩
	var sp: Dictionary = SDefs.SPEAKERS.get(info.who, {})
	var path: String = sp.get("path", "")
	if path.count("%s") == 1:
		path = path % "neutral"
	var pt: Texture2D = Game.tex(path) if path != "" else null
	var pic_ref: TextureRect = null
	if pt != null:
		var pic := TextureRect.new()
		pic_ref = pic
		pic.texture = pt
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		var hh := K.px(1180)
		pic.size = Vector2(hh * pt.get_width() / pt.get_height(), hh)
		pic.anchor_top = 1.0
		pic.anchor_bottom = 1.0
		pic.position.x = K.px(90)
		pic.offset_top = -hh + K.px(340)
		pic.offset_bottom = K.px(340)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.screen.add_child(pic)
		m.screen.move_child(pic, 2)
	var v := _side(540, 120)
	v.add_child(K.cap(G.PLACES[id].name))
	v.add_child(K.title(sp.get("name", ""), 30))
	v.add_child(K.spacer(0, 4))
	match id:
		"tavern":
			Game.flags["rumor_%d" % Game.week] = true
			for r in G.RUMORS.get(Game.week, []):
				v.add_child(_quote(r))
			var back := func(): show_place("tavern")
			v.add_child(_bond_row("martha", back))
			var acts := K.hbox(8)
			acts.add_child(Talk.button(m, "martha", back, 46, 170))
			acts.add_child(Talk.gift_button(m, "martha", back, 46, 110))
			var fed: bool = Game.flags.get("food_%d" % Game.week, false)
			var fb := K.btn_sub("이번 납품 끝" if fed else "식재료 납품", "res_herb", _deliver_food, 46, 170)
			fb.disabled = fed or (Game.food_count() < 1 and Game.mats.get("herb", 0) < 1)
			fb.tooltip_text = "잡화점 식재료 1개 (없으면 약초 1) → 마르타 호감도 +%d (장부 한 쪽에 한 번)" % FOOD_BOND
			acts.add_child(fb)
			v.add_child(acts)
			v.add_child(_note("마르타를 누르면 말을 건다. 식재료 납품은 잡화점 식재료나 약초 1개, 장부 한 쪽에 한 번. 의뢰를 성공해도 호감도가 조금 오른다."))
			if pic_ref != null:
				_talk_on_click(pic_ref, "martha")
		"smithy":
			_smithy(v)
		"store":
			_store(v)
		"chief":
			_chief(v)
		"square":
			Game.flags["news_%d" % Game.week] = true
			if Game.news.is_empty():
				v.add_child(_quote("아직 붙은 소식이 없다. 장부를 마감하면 우물가 게시판에 소식이 붙는다."))
			else:
				v.add_child(K.cap("우물가 게시판 · 지난 소식"))
				for it in Game.news:
					v.add_child(_hr())
					v.add_child(news_row(it, 14))
	v.add_child(K.spacer(0, 6))
	var back := K.btn_sub("마을로", "i_town", show_town, 50, 0)
	v.add_child(back)


const NEWS_TAG := {"ok": ["성공", K.GOOD], "half": ["절반", Color("ffd28a")], "miss": ["놓침", K.BAD], "quiet": ["소식", K.DIM], "rumor": ["소문", K.BRASS_HI]}


## 소식 한 줄: [kind, 이름, 글] → 색 칩 + 이름 + 글
func news_row(it, size := 16.0) -> Control:
	var h := K.hbox(12)
	if it is String:
		h.add_child(K.label(it, size, Color("e3e6ec"), null, true))
		return h
	var tg: Array = NEWS_TAG.get(it[0], NEWS_TAG.quiet)
	var chip := K.chip(tg[0], Color(tg[1], 0.2), tg[1], size - 3)
	chip.custom_minimum_size.x = K.px(48)
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(chip)
	var v := K.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(K.bold(it[1], size + 1))
	v.add_child(K.label(it[2], size - 1, K.DIM, null, true))
	h.add_child(v)
	return h


const FOOD_BOND := 6  # 식재료 납품 한 번


## 마르타에게 식재료 납품 (잡화점 식재료, 없으면 약초 1): 한 주에 한 번, 호감도
func _deliver_food() -> void:
	if Game.food_count() > 0:
		var f := Game.use_food()
		Game.week_log.append("납품 · 마르타에게 %s" % P.ITEMS[f].name)
	elif not Game.pay({"herb": 1}, "마르타에게 식재료 납품"):
		return
	Game.flags["food_%d" % Game.week] = true
	var before: int = Game.bond.get("martha", 0)
	Game.add_bond("martha", FOOD_BOND)
	var got: int = Game.bond.get("martha", 0) - before
	m._show_toast("마르타: 오, 싱싱한데! · 호감도 +%d" % got if got > 0 else "마르타: 고마워! (호감도가 다음 이야기 문턱에 닿아 있다)")
	show_place("tavern")


## 장소 주인 그림을 누르면 일반 대화 한 줄 (아래 대사 띠)
func _talk_on_click(pic: TextureRect, id: String) -> void:
	var box := Desk.SayBox.new()
	for sd in [["left", 20], ["right", 60], ["top", 12], ["bottom", 13]]:
		box.add_theme_constant_override("margin_" + sd[0], K.pxi(sd[1]))
	var l := K.label(Talk.idle_line(id), 17, Color.WHITE)
	box.add_child(l)
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = K.px(30)
	box.offset_bottom = -K.px(28)
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	m.screen.add_child(box)
	pic.mouse_filter = Control.MOUSE_FILTER_STOP
	pic.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pic.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			l.text = Talk.idle_line(id)
			Talk._type(l))


## NPC 호감도 줄: 이름 + 마름모 3개 + 막대 (+ 이야기 버튼)
func _bond_row(id: String, back: Callable) -> Control:
	var b: Dictionary = Game.bond_def(id)
	var v := K.vbox(6)
	var h := K.hbox(8)
	h.add_child(K.label(b.meter, 13, K.DIM))
	var seen: int = Game.bond_seen.get(id, 0)
	for i in 3:
		h.add_child(K.Diamond.make(K.px(7), K.BRASS_HI, i < seen, i < seen))
	var bar := Desk.Bar.new()
	bar.ratio = Game.bond_ratio(id)
	bar.col = K.BLUE_HI
	bar.custom_minimum_size = Vector2(K.px(120), K.px(4))
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bar)
	h.add_child(K.num(str(Game.bond.get(id, 0)), 13, K.DIM))
	v.add_child(h)
	var st := Game.bond_ready(id)
	if st > 0:
		v.add_child(K.btn_main("%s의 이야기 %s" % [b.name, ROMAN[st - 1]], b.stage_names[st - 1],
			func(): Desk.play_bond(m, id, st, back), 50))
	elif seen < 3:
		v.add_child(K.label("다음 이야기 · %s" % b.stage_names[seen], 13, K.DIM))
	return v


## 대사 한 덩이: 왼쪽 놋쇠 선 + 글
func _quote(text: String) -> Control:
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", K.pxi(14))
	var l := K.label("“%s”" % text, 16, Color("e9e4da"), null, true)
	mc.add_child(l)
	var line := ColorRect.new()
	line.color = Color(K.BRASS, 0.7)
	line.custom_minimum_size = Vector2(maxf(2.0, K.px(2)), 0)
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(line)
	return mc


func _note(text: String) -> Label:
	return K.label(text, 13, K.DIM, null, true)


func _chief(v: VBoxContainer) -> void:
	var next: Dictionary = G.RANKS[Game.rank + 1] if Game.rank + 1 < G.RANKS.size() else {}
	if Game.can_rank_up():
		v.add_child(_quote("단장, 요즘 길드 이름이 이웃 마을까지 들리더군. 영주님께 올려 둔 서류가 통과됐네."))
		v.add_child(K.btn_main("%s 길드로 승급" % next.name, "명성 %d" % Game.fame, func():
			Game.rank += 1
			Game.week_log.append("승급 · 길드가 %s 등급이 되었다" % G.RANKS[Game.rank].name)
			m._show_toast("하웰 모험가 길드 · %s 등급!" % G.RANKS[Game.rank].name)
			show_place("chief")))
	elif next.is_empty():
		v.add_child(_quote("금패 길드라니. 에드릭 공이 보셨으면 좋아하셨을 게야."))
	else:
		v.add_child(_quote("다른 길드보다 빨리 크고 있어. 그 기세면 곧 %s도 받겠군." % next.name))
		var row := K.hbox(10)
		row.add_child(K.icon("rank_%d" % Game.rank, 26, Color.WHITE))
		row.add_child(K.bold(G.RANKS[Game.rank].name, 16, K.BRASS_HI))
		row.add_child(K.label("→", 16, K.DIM))
		row.add_child(K.icon("rank_%d" % (Game.rank + 1), 26, Color.WHITE))
		row.add_child(K.bold(next.name, 16, Color.WHITE))
		row.add_child(K.spacer(0, 0, true))
		row.add_child(K.icon("res_fame", 20, Color.WHITE))
		row.add_child(K.num("%d / %d" % [Game.fame, next.fame], 16, Color.WHITE))
		v.add_child(row)
		var bar := Desk.Bar.new()
		bar.ratio = clampf(float(Game.fame) / next.fame, 0, 1)
		bar.col = K.BRASS_HI
		bar.custom_minimum_size = Vector2(0, K.px(5))
		v.add_child(bar)
	v.add_child(_note("등급이 오르면 더 크고 보상 좋은 의뢰가 붙고, 지원자 등급도 조금 올라간다."))


# ── 길드 하우스 ──

func show_guild() -> void:
	m.desk.show()


# ── 스카우트실 ──

func show_scout() -> void:
	var lv: int = Game.facilities.get("scout", 1)
	_frame("스카우트실", "%s레벨 · %s" % [ROMAN[lv - 1], G.FACILITIES.scout.fx[lv - 1]], func():
		_sel_app = -1
		show_guild())
	if _sel_app < 0 and not Game.applicants.is_empty():
		_sel_app = 0
	# 왼쪽: 지원자 카드
	var area := CenterContainer.new()
	area.anchor_right = 1.0
	area.anchor_bottom = 1.0
	area.offset_left = K.px(30)
	area.offset_right = -K.px(30 + 520 + 20)
	area.offset_top = K.px(100)
	area.offset_bottom = -K.px(30)
	m.screen.add_child(area)
	var row := K.hbox(18)
	area.add_child(row)
	if Game.applicants.is_empty():
		row.add_child(K.shadowed(K.label("이번 지원자는 모두 계약했거나 떠났다.", 17)))
	for i in Game.applicants.size():
		var a: Dictionary = Game.applicants[i]
		var c := _card(a, _card_w() * (1.15 if Game.applicants.size() <= 3 else 1.0))
		c.note = "계약금 %d" % G.GRADE_INFO[a.grade].fee
		c.selected = i == _sel_app
		c.clicked.connect(func(_c):
			_sel_app = i
			show_scout())
		m.hover_pop(c, 1.04)
		row.add_child(c)
	# 오른쪽: 고른 지원자
	var v := _side(520)
	v.add_child(K.cap("이번 지원자 · %d명" % Game.applicants.size()))
	if _sel_app >= 0 and _sel_app < Game.applicants.size():
		var a: Dictionary = Game.applicants[_sel_app]
		var gi: Dictionary = G.GRADE_INFO[a.grade]
		var nm := K.hbox(10)
		nm.add_child(_grade_chip(a.grade))
		nm.add_child(K.title(a.name, 30))
		v.add_child(nm)
		v.add_child(K.label("%s · 특기 %s" % [G.CLASSES[a.cls].name, ", ".join(PackedStringArray(a.tags))], 15, Color("dfe3ea")))
		v.add_child(_stat_row("실력", str(a.power)))
		v.add_child(_stat_row("특성", Card.trait_text(a.trait)))
		v.add_child(_stat_row("보수 몫", "위탁 보상의 %d%%" % gi.share))
		v.add_child(_hr())
		var fee: int = gi.fee
		var full := Game.roster.size() >= Game.roster_cap()
		var b := K.btn_main("계약한다", "금화 %d" % fee, func():
			if Game.hire(a):
				m._show_toast("%s 이(가) 하웰 모험가 길드에 들어왔다." % a.name)
				_sel_app = -1
			show_scout())
		b.disabled = Game.gold < fee or full
		v.add_child(b)
		if full:
			v.add_child(K.label("명부가 꽉 찼다. 숙소를 지으면 늘어난다.", 13, K.BAD))
		elif Game.gold < fee:
			v.add_child(K.label("금화가 모자란다.", 13, K.BAD))
	v.add_child(_note("명부 %d / %d명 · 뽑지 않은 지원자는 장부를 마감하면 떠난다. 주급은 없다." % [Game.roster.size(), Game.roster_cap()]))


func _grade_chip(grade: String) -> Label:
	var l := K.num(grade, 18, Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sb := K.sb_flat(G.GRADE_INFO[grade].col, Color(1, 1, 1, 0.35), 1)
	sb.set_corner_radius_all(K.pxi(4))
	l.add_theme_stylebox_override("normal", sb)
	l.custom_minimum_size = Vector2(K.px(34), K.px(34))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _stat_row(key: String, val: String) -> Control:
	var h := K.hbox(12)
	var k := K.label(key, 13, K.DIM)
	k.custom_minimum_size.x = K.px(64)
	h.add_child(k)
	var v := K.label(val, 15, Color.WHITE, null, true)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	return h


# ── 모험가 명부 ──

func show_roster() -> void:
	_frame("모험가 명부", "%d / %d명 · 등급 순" % [Game.roster.size(), Game.roster_cap()], show_guild)
	var sc := ScrollContainer.new()
	sc.anchor_right = 1.0
	sc.anchor_bottom = 1.0
	sc.offset_left = K.px(30)
	sc.offset_right = -K.px(30)
	sc.offset_top = K.px(110)
	sc.offset_bottom = -K.px(24)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	m.screen.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 4 if m.touch else 7
	grid.add_theme_constant_override("h_separation", K.pxi(14))
	grid.add_theme_constant_override("v_separation", K.pxi(14))
	sc.add_child(grid)
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
	if Game.roster.is_empty():
		grid.add_child(K.shadowed(K.label("명부가 비었다. 스카우트실에서 모험가를 들이자.", 17)))


# ── 위탁 의뢰 ──

func show_jobs() -> void:
	_frame("위탁 의뢰", "명부의 모험가에게 맡긴다 · 결과는 장부 마감 때", func():
		_sel_job = -1
		show_guild())
	if _sel_job < 0 and not Game.jobs.is_empty():
		_sel_job = 0
	# 왼쪽: 의뢰 목록
	var lc := K.card(20, 18)
	lc.offset_left = K.px(30)
	lc.offset_top = K.px(100)
	lc.custom_minimum_size.x = K.px(520)
	m.screen.add_child(lc)
	var lv := K.vbox(8)
	lc.add_child(lv)
	lv.add_child(K.cap("이번 위탁 · %d건" % Game.jobs.size()))
	for i in Game.jobs.size():
		lv.add_child(_job_row(i))
	# 오른쪽 위: 고른 의뢰
	var v := _side(1600 - 30 - 520 - 30 - 20 - 30, 100)
	if _sel_job < 0 or _sel_job >= Game.jobs.size():
		v.add_child(K.label("왼쪽에서 의뢰를 고르고, 아래 카드를 눌러 모험가를 1~3명 붙인다.", 16, Color.WHITE, null, true))
		return
	var j: Dictionary = Game.jobs[_sel_job]
	v.add_child(K.cap("특기 %s · 필요 실력 %d" % [j.tag, j.req]))
	v.add_child(K.title(j.name, 28))
	var rw := K.hbox(16)
	rw.add_child(_cost_item("res_gold", 99999, j.gold, 16))
	if j.mat != "":
		rw.add_child(_cost_item("res_" + j.mat, 99999, j.mat_n, 16))
	rw.add_child(_cost_item("res_fame", 99999, j.fame, 16))
	rw.add_child(K.label("(몫 떼기 전)", 13, K.DIM))
	v.add_child(rw)
	var ch := Game.job_chance(j, j.crew)
	var ch_text: String
	if j.crew.is_empty():
		ch_text = "아직 아무도 맡지 않았다."
	elif Game.facilities.get("records", 0) >= 1:
		ch_text = "성공률 %d%%" % roundi(ch * 100)
	else:
		ch_text = "성공 가능성 %s  ·  기록실을 지으면 숫자로 보인다" % ("높음" if ch >= 0.7 else ("보통" if ch >= 0.45 else "낮음"))
	v.add_child(K.bold(ch_text, 17, Color("9fe39a") if ch >= 0.6 else (K.BRASS_HI if not j.crew.is_empty() else K.DIM)))
	v.add_child(_note("특기가 맞으면 실력이 25% 더 쳐진다. 실패하면 다친 모험가는 한 차례 쉰다."))
	# 아래: 맡길 수 있는 모험가 카드
	var sc := ScrollContainer.new()
	sc.anchor_right = 1.0
	sc.anchor_bottom = 1.0
	sc.offset_left = K.px(30 + 520 + 20)
	sc.offset_right = -K.px(30)
	sc.offset_top = K.px(400)
	sc.offset_bottom = -K.px(24)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	m.screen.add_child(sc)
	var row := K.hbox(14)
	sc.add_child(row)
	for a in Game.roster:
		var on: bool = a.id in j.crew
		var c := _card(a, _card_w() * 0.92)
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
		row.add_child(K.shadowed(K.label("명부에 모험가가 없다. 스카우트실에서 계약하자.", 17)))


## 위탁 의뢰 한 줄: 특기 · 이름 · 필요 실력 · 맡은 사람
func _job_row(i: int) -> Control:
	var j: Dictionary = Game.jobs[i]
	var sel := i == _sel_job
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := K.sb_flat(Color(1, 1, 1, 0.035), Color(1, 1, 1, 0.07), 1)
	var on := K.sb_flat(Color(K.BRASS, 0.12), Color(K.BRASS, 0.6), 1)
	b.add_theme_stylebox_override("normal", on if sel else normal)
	b.add_theme_stylebox_override("hover", on)
	b.add_theme_stylebox_override("pressed", on)
	b.custom_minimum_size = Vector2(0, K.px(66))
	b.pressed.connect(func():
		_sel_job = i
		show_jobs())
	var h := K.hbox(12)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = K.px(14)
	h.offset_right = -K.px(14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var tg := K.bold(j.tag, 12, K.INK)
	var tsb := K.sb_flat(K.BRASS_HI if sel else Color(K.PAPER, 0.85))
	tsb.content_margin_left = K.px(7)
	tsb.content_margin_right = K.px(7)
	tg.add_theme_stylebox_override("normal", tsb)
	tg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tg)
	var v := K.vbox(1)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(K.bold(j.name, 16, Color.WHITE))
	var crew: String = ", ".join(PackedStringArray(j.crew.map(func(id): return Game.adventurer(id).name))) if not j.crew.is_empty() else "맡길 사람 없음"
	v.add_child(K.label(crew, 12.5, K.BRASS_HI if not j.crew.is_empty() else K.DIM))
	var rq := K.vbox(0)
	rq.alignment = BoxContainer.ALIGNMENT_CENTER
	var rl := K.label("필요 실력", 10.5, K.DIM)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rq.add_child(rl)
	var rn := K.num(str(j.req), 19, Color.WHITE)
	rn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rq.add_child(rn)
	h.add_child(rq)
	if not j.crew.is_empty():
		h.add_child(K.icon("i_check", 18, Color("9fe39a")))
	return b


# ── 재건 공사 · 시설 ──

func show_build() -> void:
	_frame("재건 공사 · 시설", "공사 %d / %d단계 · %s" % [Game.build, G.STAGES.size() - 1, G.STAGES[Game.build].name], show_guild)
	# 왼쪽: 공사
	var lc := K.card(20, 22)
	lc.offset_left = K.px(30)
	lc.offset_top = K.px(100)
	lc.custom_minimum_size.x = K.px(600)
	m.screen.add_child(lc)
	var v := K.vbox(10)
	lc.add_child(v)
	v.add_child(K.cap("재건 공사"))
	v.add_child(K.title("지금 · %s" % G.STAGES[Game.build].name, 28))
	v.add_child(Desk.StageTrack.make(Game.build))
	v.add_child(_hr())
	if Game.build + 1 < G.STAGES.size():
		var nx: Dictionary = G.STAGES[Game.build + 1]
		var t := K.hbox(10)
		t.add_child(K.num(ROMAN[Game.build], 20, K.BRASS_HI))
		t.add_child(K.bold(nx.name, 20, Color.WHITE))
		v.add_child(t)
		v.add_child(K.label(nx.desc, 15, Color("d8dce4"), null, true))
		var c := Game.stage_cost(Game.build + 1)
		var cr := K.hbox(10)
		cr.add_child(K.label("필요", 13, K.DIM))
		cr.add_child(_cost(c, 17))
		v.add_child(cr)
		var b := K.btn_main("공사한다", nx.name, func():
			if Game.do_build():
				m._show_toast("'%s' 공사를 마쳤다! 길드 하우스가 달라졌다." % G.STAGES[Game.build].name)
			show_build())
		b.disabled = not Game.can_pay(c)
		v.add_child(b)
		v.add_child(_note("금화가 모자라면 위탁 의뢰를 꾸준히 돌리자. 공사가 늦어도 이야기는 막히지 않는다."))
	else:
		v.add_child(K.bold("길드 하우스 재건을 모두 마쳤다.", 17, Color("9fe39a")))
	# 오른쪽: 시설
	var st: Dictionary = G.STAGES[Game.build]
	var rc := K.card(20, 22)
	rc.anchor_left = 0.0
	rc.anchor_right = 1.0
	rc.anchor_bottom = 1.0
	rc.offset_left = K.px(30 + 600 + 20)
	rc.offset_right = -K.px(30)
	rc.offset_top = K.px(100)
	rc.offset_bottom = -K.px(24)
	m.screen.add_child(rc)
	var f := K.vbox(10)
	rc.add_child(f)
	var top := K.hbox(10)
	f.add_child(top)
	var tl := K.vbox(2)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.add_child(K.cap("시설"))
	tl.add_child(K.title("길드 시설", 28))
	top.add_child(tl)
	var slot := K.vbox(4)
	slot.alignment = BoxContainer.ALIGNMENT_END
	var sl := K.label("칸 %d / %d · 최고 %d레벨" % [Game.slots_used(), st.slots, st.max_lv], 13, K.DIM)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slot.add_child(sl)
	var dots := K.hbox(6)
	dots.alignment = BoxContainer.ALIGNMENT_END
	for i in st.slots:
		dots.add_child(K.Diamond.make(K.px(9), K.BRASS_HI, i < Game.slots_used(), i < Game.slots_used()))
	slot.add_child(dots)
	top.add_child(slot)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	f.add_child(sc)
	var list := K.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for id in G.FACILITY_ORDER:
		list.add_child(_facility_row(id, st))


func _facility_row(id: String, st: Dictionary) -> Control:
	var fd: Dictionary = G.FACILITIES[id]
	var lv: int = Game.facilities.get(id, 0)
	var p := PanelContainer.new()
	var sb := K.sb_flat(Color(1, 1, 1, 0.045) if lv > 0 else Color(0, 0, 0, 0.2), Color(K.BRASS, 0.35) if lv > 0 else Color(1, 1, 1, 0.06), 1)
	sb.set_content_margin_all(K.px(12))
	p.add_theme_stylebox_override("panel", sb)
	var h := K.hbox(14)
	p.add_child(h)
	var v := K.vbox(3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nr := K.hbox(10)
	nr.add_child(K.bold(fd.name, 17, Color.WHITE if lv > 0 else Color(0.75, 0.78, 0.84)))
	for i in fd.max:
		nr.add_child(K.Diamond.make(K.px(7), K.BRASS_HI if i < lv else Color(K.BRASS, 0.45), i < lv))
	v.add_child(nr)
	v.add_child(K.label(fd.fx[lv - 1] if lv > 0 else "지으면 · " + fd.fx[0], 13.5, Color("d8dce4") if lv > 0 else K.DIM))
	if lv > 0 and lv < fd.max:
		v.add_child(K.label("다음 · " + fd.fx[lv], 12.5, Color(K.DIM, 0.8)))
	var c := Game.fac_next_cost(id)
	if lv >= fd.max:
		var l := K.bold("최고 레벨", 14, Color("9fe39a"))
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
	elif c.is_empty():
		var why: String = "재건 공사 필요" if lv > 0 or Game.slots_used() < st.slots else "빈 칸 없음"
		var r := K.hbox(6)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(K.icon("i_lock", 16, K.DIM))
		r.add_child(K.label(why, 13, K.DIM))
		h.add_child(r)
	else:
		var r := K.vbox(6)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var cr := _cost(c, 14)
		cr.alignment = BoxContainer.ALIGNMENT_END
		r.add_child(cr)
		var b := K.btn_main("짓기" if lv == 0 else "%s레벨로" % ROMAN[lv], "", func():
			if Game.upgrade(id):
				m._show_toast("%s %d레벨!" % [fd.name, Game.facilities[id]])
			show_build(), 40)
		b.custom_minimum_size.x = K.px(150)
		b.disabled = not Game.can_pay(c)
		r.add_child(b)
		h.add_child(r)
	return p


# ── 주말 장부 ──

func show_ledger(e: Dictionary, then: Callable) -> void:
	m._clear()
	m.bg.texture = Game.tex("backgrounds/scene/bg_guildhall_camp_night.png")
	m.bg.modulate = Color(0.5, 0.5, 0.52)
	Desk.shade(m.screen)
	m.screen.add_child(Desk.resource_bar())
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.screen.add_child(cc)
	var c := K.card(20, 28)
	c.custom_minimum_size = Vector2(K.px(820), 0)
	cc.add_child(c)
	var v := K.vbox(10)
	c.add_child(v)
	var top := K.hbox(12)
	v.add_child(top)
	var tl := K.vbox(2)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.add_child(K.cap("장부 %d쪽 결산" % e.week))
	tl.add_child(K.title("단장의 장부", 34))
	top.add_child(tl)
	top.add_child(K.icon("i_ledger", 40, K.BRASS_HI))
	v.add_child(_hr())
	if e.lines.is_empty():
		v.add_child(K.label("이번엔 적을 게 없었다.", 16, K.DIM))
	for ln in e.lines:
		v.add_child(_ledger_line(ln))
	v.add_child(_hr())
	var tot := K.hbox(28)
	tot.alignment = BoxContainer.ALIGNMENT_END
	tot.add_child(_total("수입", "+%d" % e.income, Color("9fe39a")))
	tot.add_child(_total("지출", "-%d" % e.spend, Color("ffc08a")))
	tot.add_child(_total("남은 금화", str(Game.gold), K.BRASS_HI))
	v.add_child(tot)
	if Game.bond_seen.get("nora", 0) >= 1:  # 노라 1단계: 다음 주 예상 수입
		var fc := K.hbox(8)
		fc.add_child(K.chip("부관 노라", Color(K.BLUE, 0.35), Color.WHITE, 12))
		fc.add_child(K.label("다음 쪽 예상 수입 약 %d 금화 (최근 장부 평균)" % _forecast(), 14, K.DIM))
		v.add_child(fc)
	_debt_row(v, e, then)
	v.add_child(K.spacer(0, 6))
	v.add_child(K.btn_main("소식 보기", "장부 %d쪽 마무리" % e.week, then))


## 금저울 상회 빚: 남은 빚, 이번 장까지 갚을 몫, 갚기 버튼 (docs/04-game-flow.md 3.8 ⑥)
func _debt_row(v: VBoxContainer, e: Dictionary, then: Callable) -> void:
	if Game.debt <= 0:
		return
	v.add_child(_hr())
	var h := K.hbox(10)
	var tv := K.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var due := Game.debt_due()
	tv.add_child(K.bold("금저울 상회 빚 · 남은 %d 금화" % Game.debt, 16, Color("ffd28a")))
	tv.add_child(K.label(("이번 장이 끝나기 전에 %d 금화를 더 갚아야 한다. 못 갚으면 다음 장에 무보수 추심 의뢰가 붙는다." % due) if due > 0 else "이번 장 몫은 다 갚았다.", 13, K.DIM, null, true))
	h.add_child(tv)
	for n in [100, due]:
		if n <= 0 or (n == due and due == 100):
			continue
		var amt: int = mini(n, Game.debt)
		var b := K.btn_sub("%d 갚기" % amt if n == 100 else "몫 다 갚기", "res_gold", func():
			var before := Game.gold
			if Game.pay_debt(amt):
				e.lines.append("지출 · 금저울 상회 빚 갚기 (금화 %d)" % (before - Game.gold))
				e.spend += before - Game.gold
			show_ledger(e, then), 40, 130)
		b.disabled = Game.gold < amt
		h.add_child(b)
	v.add_child(h)


## 최근 장부 3주 수입 평균
func _forecast() -> int:
	var last: Array = Game.ledger.slice(maxi(0, Game.ledger.size() - 3))
	if last.is_empty():
		return 0
	var s := 0
	for e in last:
		s += int(e.income)
	return roundi(float(s) / last.size())


## 장부 한 줄: 종류 표시 + 내용
func _ledger_line(ln: String) -> Control:
	var kind := ln.get_slice(" · ", 0)
	var body := ln.substr(kind.length() + 3) if ln.find(" · ") >= 0 else ln
	var col: Color = {"수입": Color("9fe39a"), "지출": Color("ffc08a"), "실패": Color("ff9a8a"), "승급": K.BRASS_HI, "재건": K.BRASS_HI}.get(kind, K.DIM)
	var h := K.hbox(12)
	var tag := K.bold(kind, 12, K.INK)
	var sb := K.sb_flat(col)
	sb.content_margin_left = K.px(8)
	sb.content_margin_right = K.px(8)
	tag.add_theme_stylebox_override("normal", sb)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.custom_minimum_size.x = K.px(44)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(tag)
	var l := K.label(body, 15, Color("e3e6ec"), null, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h


func _total(key: String, val: String, col: Color) -> Control:
	var v := K.vbox(0)
	var k := K.label(key, 12, K.DIM)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(k)
	var n := K.num(val, 24, col)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(n)
	return v


# ── 대장간: 동료 장비 바꾸기 · 강화 (강화 상한은 무기고) ──

func _smithy(v: VBoxContainer) -> void:
	v.add_child(_quote("왔나, 단장. 쓰던 건 값 쳐서 받아 주지. 오늘은 뭘 두드릴까."))
	if _smith_sel == "" or not Game.heroes.has(_smith_sel):
		_smith_sel = Game.party[0]
	var hs := K.hbox(6)
	for k in Game.heroes:
		var b := K.btn_sub(FDefs.HEROES[k].name, "", func():
			_smith_sel = k
			show_place("smithy"), 36, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if k == _smith_sel:
			b.add_theme_stylebox_override("normal", K.sb_flat(Color(K.BLUE, 0.45), K.BLUE_HI, 1))
		hs.add_child(b)
	v.add_child(hs)
	var cap: int = Game.plus_cap()
	v.add_child(K.label("강화 상한 +%d (무기고 %d레벨)" % [cap, Game.facilities.get("armory", 0)], 13, K.DIM))
	for kind in ["weapon", "armor"]:
		v.add_child(_hr())
		var g: Array = Game.heroes[_smith_sel][kind]
		var row := K.hbox(8)
		row.add_child(K.chip(P.GEAR_KIND[kind], Color(1, 1, 1, 0.08), K.DIM, 12))
		var nl := K.bold(P.gear_name(_smith_sel, kind, g[0], g[1]), 17)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		row.add_child(K.label(_gear_fx(kind, g[0], g[1]), 13, K.DIM))
		v.add_child(row)
		# 강화
		var ph := K.hbox(10)
		if g[1] < cap:
			var c := P.plus_cost(g[0], g[1])
			ph.add_child(_cost(c, 14))
			ph.add_child(K.spacer(0, 0, true))
			var pb := K.btn_sub("강화 +%d" % (g[1] + 1), "i_hammer", func():
				if Game.plus_gear(_smith_sel, kind):
					m._show_toast("볼프람: 됐다. 한결 단단해졌어.")
				show_place("smithy"), 38, 150)
			pb.disabled = not Game.can_pay(c)
			ph.add_child(pb)
		else:
			ph.add_child(K.label("강화 상한에 닿았다. 무기고를 올리면 더 할 수 있다." if Game.facilities.get("armory", 0) < 3 else "더 강화할 수 없다.", 13, K.DIM, null, true))
		v.add_child(ph)
		# 다음 단계 장비
		var nt: int = g[0] + 1
		if nt < P.TIERS.size():
			var th := K.hbox(10)
			var tv := K.vbox(2)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(K.label("새 장비 · %s (%s)" % [P.gear_name(_smith_sel, kind, nt, 0), _gear_fx(kind, nt, 0)], 14, Color("e3e6ec"), null, true))
			var c2 := Game.gear_buy_cost(_smith_sel, kind, nt)
			var ch := K.hbox(8)
			ch.add_child(_cost(c2, 13))
			var sell := Game.gear_sell_value(_smith_sel, kind)
			if sell > 0:
				ch.add_child(K.label("쓰던 것 판값 +%d" % sell, 12, K.GOOD))
			tv.add_child(ch)
			th.add_child(tv)
			var locked: bool = Game.build < P.TIERS[nt].build
			var bb := K.btn_sub("공사 %d단계 뒤" % P.TIERS[nt].build if locked else "사기", "i_anvil", func():
				if Game.buy_gear(_smith_sel, kind, nt):
					m._show_toast("볼프람: 새 물건이다. 아껴 써라.")
				show_place("smithy"), 38, 150)
			bb.disabled = locked or not Game.can_pay(c2)
			th.add_child(bb)
			v.add_child(th)
	v.add_child(_note("무기는 스킬 위력, 방어구는 방어와 체력을 올린다. 새 장비를 사면 쓰던 장비는 30% 값에 판다."))


func _gear_fx(kind: String, tier: int, plus: int) -> String:
	if kind == "weapon":
		return "위력 +%d" % (tier + plus)
	return "방어 +%d · 체력 +%d" % [tier, plus * 2]


# ── 잡화점: 소모품 · 선물 · 식재료 ──

const STORE_KIND := [["use", "소모품"], ["gift", "선물 · 동료와 노라, 마르타에게"], ["food", "식재료 · 마르타 납품, 주방 도시락"]]


func _store(v: VBoxContainer) -> void:
	v.add_child(_quote("회복약, 선물, 식재료! 뭐든 있습니다. 흥정은 환영이고요, 헤헤."))
	for kd in STORE_KIND:
		v.add_child(K.cap(kd[1]))
		var gr := GridContainer.new()
		gr.columns = 2
		gr.add_theme_constant_override("h_separation", K.pxi(8))
		gr.add_theme_constant_override("v_separation", K.pxi(6))
		for id in P.STORE_ORDER:
			var it: Dictionary = P.ITEMS[id]
			if it.kind != kd[0]:
				continue
			var p := K.pick(func():
				if Game.buy_item(id):
					m._show_toast("핍: %s, 여기 있습니다! 헤헤." % it.name)
				show_place("store"), 8)
			p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p.disabled = Game.gold < it.gold
			p.tooltip_text = it.desc
			var h := K.hbox(6)
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var nl := K.bold(it.name, 14, Color.WHITE if not p.disabled else K.DIM)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(nl)
			if Game.items.get(id, 0) > 0:
				h.add_child(K.num("×%d" % Game.items[id], 12, K.DIM))
			h.add_child(K.icon("res_gold", 16, Color.WHITE))
			h.add_child(K.num(str(it.gold), 14, Color.WHITE if not p.disabled else K.BAD))
			p.add_child(h)
			gr.add_child(p)
		v.add_child(gr)
	v.add_child(_note("누르면 하나 산다. 회복약은 전투에서, 행운 부적은 의뢰를 떠날 때 저절로 쓴다. 선물은 길드의 동료 화면에서 준다."))