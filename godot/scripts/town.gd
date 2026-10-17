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

func _head(text: String) -> void:
	var head := Label.new()
	head.text = text
	head.position = Vector2(24, 14)
	m._outlined(head, _fs(20, 32), Color(0.96, 0.84, 0.55))
	m.screen.add_child(head)
	_status_bar()


## 오른쪽 위: 금화 · 재료 · 명성 · 등급
func _status_bar() -> void:
	var l := Label.new()
	var parts: Array = ["금화 %d" % Game.gold]
	for k in G.MATS:
		parts.append("%s %d" % [G.MATS[k], Game.mats.get(k, 0)])
	parts.append("명성 %d · %s" % [Game.fame, G.RANKS[Game.rank].name])
	l.text = "  ".join(PackedStringArray(parts))
	l.anchor_left = 1.0
	l.anchor_right = 1.0
	l.offset_left = -900
	l.offset_right = -24
	l.offset_top = 18
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	m._outlined(l, _fs(13, 22), Color(1.0, 0.95, 0.8))
	m.screen.add_child(l)


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
	_head("제%d주 · 하웰 마을" % Game.week)
	var map := TownMap.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.screen.add_child(map)
	for id in G.PLACES:
		var p: Dictionary = G.PLACES[id]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		var alert := _alert(id)
		b.text = "  %s%s  " % [p.name, "  !" if alert else ""]
		b.add_theme_font_size_override("font_size", _fs(13, 21))
		if alert:
			b.add_theme_stylebox_override("normal", UI.sbt("btn_gold", 18, 10))
		b.pressed.connect(_enter_place.bind(id))
		map.add_child(b)
		map.spots.append([b, p.at])
	var hint: Label = m._label(_town_hint(), _fs(13, 20), Color(1.0, 0.95, 0.8))
	hint.anchor_left = 0.25
	hint.anchor_right = 0.75
	hint.anchor_top = 0.92
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m._outlined(hint, _fs(13, 20), Color(1.0, 0.95, 0.8))
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
	var v: VBoxContainer = m._panel(0.52, 0.14, 0.97, 0.9)
	v.add_child(m._label(sp.get("name", ""), _fs(16, 26), Color(0.96, 0.84, 0.55), false))
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
	_spacer(v)
	v.add_child(m._btn("마을로", show_town, true))


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
	m._clear()
	Game.stage = "hub"
	var t: Texture2D = Game.tex(G.STAGES[Game.build].bg)
	m.bg.texture = t if t != null else Game.tex("backgrounds/scene/bg_guildhall_ruined.png")
	m.bg.modulate = Color(0.8, 0.78, 0.75)
	_head("제%d주 · 하웰 모험가 길드 · %s" % [Game.week, G.STAGES[Game.build].name])
	var v: VBoxContainer = m._panel(0.64, 0.12, 0.97, 0.94)
	v.add_child(m._label("단장의 책상", _fs(18, 28), Color(0.96, 0.84, 0.55), false))
	var left: Array = m._left_quests()
	if Game.picks.is_empty() and not _week_quests().is_empty():
		v.add_child(m._btn("의뢰 게시판 · 이번 주 의뢰", m._show_board, true))
	elif not left.is_empty():
		v.add_child(m._label("다음 의뢰: %s" % SDefs.QUESTS[left[0]].name, _fs(14, 22)))
		v.add_child(m._btn("출발", func(): m._start_quest(left[0]), true))
	else:
		if _week_quests().is_empty():
			v.add_child(m._label("이번 주는 큰 의뢰가 없다. 위탁 의뢰를 돌리고 결전에 대비하자.", _fs(13, 20)))
		v.add_child(m._btn("주말을 맞는다 (장부 정리)", m._weekend, true))
	var idle := Game.jobs.filter(func(j): return j.crew.is_empty()).size()
	v.add_child(m._btn("위탁 의뢰 (%d개 · 맡길 일 %d)" % [Game.jobs.size(), idle], show_jobs))
	v.add_child(m._btn("스카우트실 (지원자 %d명)" % Game.applicants.size(), show_scout))
	v.add_child(m._btn("모험가 명부 (%d / %d)" % [Game.roster.size(), Game.roster_cap()], show_roster))
	v.add_child(m._btn("재건 공사 · 시설", show_build))
	v.add_child(m._btn("연대기 (%d쪽)" % Game.pages.size(), m._show_book))
	_spacer(v)
	v.add_child(m._btn("마을로", show_town))


# ── 스카우트실 ──

func show_scout() -> void:
	m._clear()
	m.bg.modulate = Color(0.45, 0.43, 0.4)
	var lv: int = Game.facilities.get("scout", 1)
	_head("스카우트실 %d레벨 · %s" % [lv, G.FACILITIES.scout.fx[lv - 1]])
	var row := _row_scroll(0.03, 0.12, 0.62, 0.95)
	if Game.applicants.is_empty():
		row.add_child(m._label("이번 주 지원자는 모두 계약했거나 떠났다.", _fs(14, 22)))
	for i in Game.applicants.size():
		var a: Dictionary = Game.applicants[i]
		var c := _card(a, _card_w())
		c.note = "계약금 %d" % G.GRADE_INFO[a.grade].fee
		c.selected = i == _sel_app
		c.clicked.connect(func(_c):
			_sel_app = i
			show_scout())
		row.add_child(c)
	var v: VBoxContainer = m._panel(0.64, 0.12, 0.97, 0.94)
	v.add_child(m._label("이번 주 지원자", _fs(18, 28), Color(0.96, 0.84, 0.55), false))
	v.add_child(m._label("뽑지 않은 지원자는 주말이 지나면 떠난다. 주급은 없고, 위탁 보상에서 몫을 떼어 간다.", _fs(12, 18), Color(0.85, 0.8, 0.7)))
	v.add_child(m._label("명부 %d / %d (숙소를 지으면 늘어난다)" % [Game.roster.size(), Game.roster_cap()], _fs(13, 20)))
	if _sel_app >= 0 and _sel_app < Game.applicants.size():
		var a: Dictionary = Game.applicants[_sel_app]
		var fee: int = G.GRADE_INFO[a.grade].fee
		v.add_child(m._label("%s급 %s · %s" % [a.grade, a.name, G.CLASSES[a.cls].name], _fs(15, 24), Color(0.96, 0.84, 0.55)))
		var b: Button = m._btn("계약한다 (금화 %d)" % fee, func():
			if Game.hire(a):
				m._show_toast("%s 이(가) 하웰 모험가 길드에 들어왔다." % a.name)
				_sel_app = -1
			show_scout(), true)
		b.disabled = Game.gold < fee or Game.roster.size() >= Game.roster_cap()
		v.add_child(b)
	else:
		v.add_child(m._label("카드를 눌러 살펴본다.", _fs(14, 22)))
	_spacer(v)
	v.add_child(m._btn("길드로", func():
		_sel_app = -1
		show_guild()))


# ── 모험가 명부 ──

func show_roster() -> void:
	m._clear()
	m.bg.modulate = Color(0.45, 0.43, 0.4)
	_head("모험가 명부 %d / %d" % [Game.roster.size(), Game.roster_cap()])
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
	h.add_child(m._btn("길드로", show_guild, true))


# ── 위탁 의뢰 ──

func show_jobs() -> void:
	m._clear()
	m.bg.modulate = Color(0.45, 0.43, 0.4)
	_head("위탁 의뢰 · 명부의 모험가에게 맡긴다 (결과는 주말 장부에)")
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
		show_guild(), true))
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
	m.bg.texture = Game.tex(G.STAGES[Game.build].bg)
	m.bg.modulate = Color(0.45, 0.43, 0.4)
	_head("재건 공사 · 시설")
	var v: VBoxContainer = m._panel(0.02, 0.1, 0.38, 0.94)
	v.add_child(m._label("재건 공사 · 지금: %s" % G.STAGES[Game.build].name, _fs(16, 26), Color(0.96, 0.84, 0.55)))
	v.add_child(m._label(G.STAGES[Game.build].desc, _fs(13, 20)))
	if Game.build + 1 < G.STAGES.size():
		var nx: Dictionary = G.STAGES[Game.build + 1]
		v.add_child(m._label("다음 공사: %s" % nx.name, _fs(15, 24), Color(1.0, 0.85, 0.5)))
		v.add_child(m._label(nx.desc, _fs(13, 20)))
		var c := Game.stage_cost(Game.build + 1)
		v.add_child(m._label("필요: " + G.cost_text(c), _fs(13, 20), Color(0.9, 0.85, 0.6)))
		var b: Button = m._btn("공사한다", func():
			if Game.do_build():
				m._show_toast("'%s' 공사를 마쳤다! 길드 하우스가 달라졌다." % G.STAGES[Game.build].name)
			show_build(), true)
		b.disabled = not Game.can_pay(c)
		v.add_child(b)
		v.add_child(m._label("금화가 모자라면 위탁 의뢰를 꾸준히 돌리자. 공사가 늦어도 이야기는 막히지 않는다.", _fs(12, 18), Color(0.75, 0.7, 0.62)))
	else:
		v.add_child(m._label("길드 하우스 재건을 모두 마쳤다.", _fs(14, 22), Color(0.6, 1.0, 0.6)))
	_spacer(v)
	v.add_child(m._btn("길드로", show_guild, true))
	# 시설 목록
	var st: Dictionary = G.STAGES[Game.build]
	var f: VBoxContainer = m._panel(0.4, 0.1, 0.98, 0.94)
	f.add_child(m._label("시설 %d / %d칸 · 최고 %d레벨 (스카우트실 %d)" % [Game.slots_used(), st.slots, st.max_lv, st.scout_max], _fs(16, 26), Color(0.96, 0.84, 0.55)))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	f.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6 if m.touch else 10)
	sc.add_child(list)
	for id in G.FACILITY_ORDER:
		var fd: Dictionary = G.FACILITIES[id]
		var lv: int = Game.facilities.get(id, 0)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		list.add_child(h)
		var info: Label = m._label("", _fs(13, 20))
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.text = "%s  %s\n  %s" % [fd.name, ("%d레벨" % lv) if lv > 0 else "(없음)",
			fd.fx[lv - 1] if lv > 0 else "지으면: " + fd.fx[0]]
		h.add_child(info)
		var c := Game.fac_next_cost(id)
		var label: String
		if lv >= fd.max:
			label = "최고 레벨"
		elif c.is_empty():
			label = "재건 공사 필요" if lv > 0 or Game.slots_used() < st.slots else "빈 칸 없음"
		else:
			label = "%s · %s" % ["짓기" if lv == 0 else "%d레벨로" % (lv + 1), G.cost_text(c)]
		var b: Button = m._btn(label, func():
			if Game.upgrade(id):
				m._show_toast("%s %d레벨!" % [fd.name, Game.facilities[id]])
			show_build())
		b.add_theme_font_size_override("font_size", _fs(12, 18))
		b.disabled = c.is_empty() or not Game.can_pay(c)
		h.add_child(b)


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
