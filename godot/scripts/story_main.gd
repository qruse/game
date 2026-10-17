extends Control
## 1장 체험판 흐름: 제목 → 오프닝 → 하웰 마을 ⇄ 길드 하우스(의뢰 게시판, 위탁 의뢰, 스카우트, 재건) → 이번 주 의뢰(셋 중 둘)
## → 의뢰마다 연대기 페이지 → 주말 장부 → 소식 → 다음 주 … → 결전 → 끝. 마을·운영 화면은 town.gd.
## 전투 칸은 fk.tscn 으로 넘어갔다가 Game.battle_res 를 들고 돌아온다.
## 실행 옵션 (-- 뒤에): --story-shot=경로.png --story-at=초 --goto=town|hub|place:장소|scout|jobs|roster|build|ledger|board|page:퀘스트|news|end|scene:장면|battle:퀘스트:칸 (+ --demo 면 전투 자동)

const Defs = preload("res://scripts/story_defs.gd")
const UI = preload("res://scripts/fk_ui.gd")
const ScenePlayer = preload("res://scripts/scene_player.gd")
const Page = preload("res://scripts/chronicle_page.gd")
const Battle = preload("res://scripts/fk_battle.gd")
const Town = preload("res://scripts/town.gd")

var touch := false
var town  # 마을·길드 운영 화면
var bold: Font
var bg: TextureRect
var screen: Control
var player: Control
var toast: Label
var _toast_t := 0.0
var _shot := ""
var _shot_at := 1.5

# 연대기 화면
var page_view: Control
var side: VBoxContainer
var _luck_use := false
var _board_sel := ""


func _ready() -> void:
	touch = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or "--touch" in OS.get_cmdline_user_args() or get_window().size.y < 700
	if touch:
		get_window().content_scale_size = Vector2i(960, 540)
	var t: Dictionary = UI.make_theme(touch)
	theme = t.theme
	bold = t.bold
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	town = Town.new(self)
	var black := ColorRect.new()
	black.color = Color(0.06, 0.05, 0.04)
	black.set_anchors_preset(PRESET_FULL_RECT)
	add_child(black)
	bg = TextureRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	# 가장자리를 어둡게 (그림 위 글자·틀이 떠 보이게)
	var vig := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.1, 1.1)
	var gr := Gradient.new()
	gr.set_color(0, Color(0, 0, 0, 0.0))
	gr.set_color(1, Color(0, 0, 0, 0.75))
	gr.add_point(0.45, Color(0, 0, 0, 0.0))
	gt.gradient = gr
	vig.texture = gt
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.set_anchors_preset(PRESET_FULL_RECT)
	vig.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(vig)
	screen = Control.new()
	screen.set_anchors_preset(PRESET_FULL_RECT)
	add_child(screen)
	player = ScenePlayer.new()
	player.touch = touch
	player.bold = bold
	add_child(player)
	toast = Label.new()
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 0.12
	toast.grow_horizontal = GROW_DIRECTION_BOTH
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outlined(toast, 16 if touch else 24, Color(1.0, 0.9, 0.65))
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.07, 0.05, 0.04, 0.88)
	tsb.border_color = UI.GOLD
	tsb.border_width_top = 2
	tsb.border_width_bottom = 2
	tsb.set_corner_radius_all(4)
	tsb.content_margin_left = 40
	tsb.content_margin_right = 40
	tsb.content_margin_top = 10
	tsb.content_margin_bottom = 12
	toast.add_theme_stylebox_override("normal", tsb)
	toast.modulate.a = 0.0
	toast.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(toast)

	var goto := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--story-shot="):
			_shot = a.get_slice("=", 1)
		elif a.begins_with("--story-at="):
			_shot_at = float(a.get_slice("=", 1))
		elif a.begins_with("--goto="):
			goto = a.get_slice("=", 1)
	if _shot != "":
		_take_shot()
	# 전투에서 돌아왔으면 그 자리로
	if not Game.battle_res.is_empty():
		var res: Dictionary = Game.battle_res
		Game.battle_res = {}
		if Game.stage == "finale":
			_finale_result(res)
		else:
			_show_page()
			_battle_result(res)
		return
	if goto != "" and not Game.flags.get("_goto_done", false):
		_debug_goto(goto)
		Game.flags["_goto_done"] = true
		return
	_show_title()


func _take_shot() -> void:
	await get_tree().create_timer(_shot_at).timeout
	get_viewport().get_texture().get_image().save_png(_shot)
	get_tree().quit()


func _debug_goto(g: String) -> void:
	Game.reset()
	match g.get_slice(":", 0):
		"town":
			town.show_town()
		"hub":
			_show_hub()
		"scout":
			town.show_scout()
		"place":
			town.show_place(g.get_slice(":", 1))
		"roster":
			for gr in ["S", "A", "B", "C", "D"]:
				Game.roster.append(Game.make_adventurer(gr))
			Game.facilities["dorm"] = 2
			town.show_roster()
		"jobs":
			for gr in ["C", "D"]:
				Game.roster.append(Game.make_adventurer(gr))
			Game.jobs[0].crew = [Game.roster[0].id, Game.roster[2].id]
			town._sel_job = 0
			town.show_jobs()
		"build":
			Game.gold = 900
			Game.mats = {"wood": 8, "iron": 3, "herb": 2}
			town.show_build()
		"ledger":
			Game.roster.append(Game.make_adventurer("C"))
			Game.jobs[0].crew = [Game.roster[0].id, Game.roster[2].id]
			Game.jobs[1].crew = [Game.roster[1].id]
			Game.quest_reward("북쪽 마을의 도적", true)
			town.show_ledger(Game.settle(), _show_news)
		"board":
			Game.picks = ["trapper"]
			_board_sel = "bandits"
			_board()
		"page":
			Game.picks = [g.get_slice(":", 1), "archive"]
			_open_page(g.get_slice(":", 1))
		"news":
			Game.picks = ["bandits", "trapper"]
			Game.results = {"bandits": "ok", "trapper": "ng"}
			Game.settle()
			_show_news()
		"scene":
			_play(g.get_slice(":", 1), func(_s, _k): _show_hub())
		"battle":
			# 페이지를 그 칸까지 진행한 상태로 만들고 바로 전투로
			var qid := g.get_slice(":", 1)
			var nid := g.get_slice(":", 2)
			Game.picks = [qid]
			Game.stage = "page"
			Game.page = {"quest": qid, "node": nid, "lines": ["시험: 전투 칸까지 왔다."], "visited": ["start", "n1", nid], "vars": {"ambush": true}, "luck": 2, "fail": false, "done": false}
			var n: Dictionary = Defs.QUESTS[qid].nodes[nid]
			Game.battle_req = {"idx": n.battle, "party": Game.party.duplicate(), "luck": 2, "ambush": n.has("ambush_text")}
			get_tree().change_scene_to_file.call_deferred("res://fk.tscn")
		"end":
			Game.pages = [{"quest": "bandits", "lines": ["샘플 문장 하나.", "샘플 문장 둘."]}, {"quest": "trapper", "lines": ["샘플 문장 셋."]}]
			Game.results = {"bandits": "ok", "trapper": "ng"}
			_show_end()


# ── 공용 ────────────────────────────────────────────

func _clear() -> void:
	for c in screen.get_children():
		c.queue_free()
	page_view = null
	# 화면이 바뀔 때 살짝 밝아지며 나타난다
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.22)


func _btn(text: String, cb: Callable, big := false) -> Button:
	var b := Button.new()
	b.text = "  %s  " % text
	b.focus_mode = FOCUS_NONE
	b.custom_minimum_size = Vector2(0, (48 if touch else 64) if big else (40 if touch else 52))
	if big:
		b.add_theme_stylebox_override("normal", UI.sbt("btn_gold", 18, 9.0 if touch else 12.0))
		b.add_theme_stylebox_override("hover", UI.sbt("btn_gold_hover", 18, 9.0 if touch else 12.0))
		b.add_theme_color_override("font_color", Color(1.0, 0.94, 0.75))
	b.pressed.connect(cb)
	hover_pop(b)
	return b


## 마우스를 올리면 살짝 커진다
func hover_pop(c: Control, k := 1.03) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size / 2.0)
	c.mouse_entered.connect(func():
		if c is BaseButton and c.disabled:
			return
		c.create_tween().tween_property(c, "scale", Vector2(k, k), 0.08))
	c.mouse_exited.connect(func(): c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.1))


func _outlined(l: Label, sz: int, col: Color) -> void:
	l.add_theme_font_override("font", bold)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)


func _label(text: String, sz: int, col := UI.CREAM, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _panel(al: float, at: float, ar: float, ab: float) -> VBoxContainer:
	var p := PanelContainer.new()
	p.anchor_left = al
	p.anchor_top = at
	p.anchor_right = ar
	p.anchor_bottom = ab
	screen.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10 if touch else 14)
	p.add_child(v)
	return v


func _show_toast(text: String) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	_toast_t = 3.5


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		toast.modulate.a = clampf(_toast_t, 0.0, 1.0)


## 장면 재생. 건너뛰면 요약 한 줄을 띄운다
func _play(id: String, then: Callable) -> void:
	for c in player.finished.get_connections():
		player.finished.disconnect(c.callable)
	player.finished.connect(func(summary: String, skipped: bool):
		if skipped and summary != "":
			_show_toast(summary)
		then.call(summary, skipped), CONNECT_ONE_SHOT)
	player.play(id)


# ── 제목 ────────────────────────────────────────────

func _show_title() -> void:
	_clear()
	bg.texture = Game.tex("backgrounds/scene/bg_guildhall_past.png")
	bg.modulate = Color(0.5, 0.46, 0.42)
	var c := CenterContainer.new()
	c.set_anchors_preset(PRESET_FULL_RECT)
	screen.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10 if touch else 16)
	c.add_child(v)
	var em := TextureRect.new()
	em.texture = UI.tex("emblem_harwell")
	em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	em.custom_minimum_size = Vector2(0, 110 if touch else 190)
	v.add_child(em)
	var t := Label.new()
	t.text = "몰락한 길드 재건하기"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outlined(t, 44 if touch else 80, Color(0.97, 0.86, 0.58))
	t.add_theme_constant_override("outline_size", 14)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("shadow_offset_y", 6)
	v.add_child(t)
	v.add_child(divider(360.0 if touch else 520.0))
	var s := _label("하웰 모험가 길드  ·  1장 체험판", 15 if touch else 24, Color(0.88, 0.82, 0.7), false)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16 if touch else 36)
	v.add_child(gap)
	var bw := 300.0 if touch else 440.0
	var b1 := _btn("이야기 시작", func():
		Game.reset()
		_play("opening", func(_s, _k): town.show_town()), true)
	b1.custom_minimum_size.x = bw
	b1.size_flags_horizontal = SIZE_SHRINK_CENTER
	v.add_child(b1)
	var b2 := _btn("전투 시험판", func(): get_tree().change_scene_to_file("res://fk.tscn"))
	b2.custom_minimum_size.x = bw
	b2.size_flags_horizontal = SIZE_SHRINK_CENTER
	v.add_child(b2)


## 금색 장식 줄
func divider(w: float) -> TextureRect:
	var d := TextureRect.new()
	d.texture = UI.tex("orn_divider")
	d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	d.custom_minimum_size = Vector2(w, w * 24.0 / 360.0)
	d.size_flags_horizontal = SIZE_SHRINK_CENTER
	d.mouse_filter = MOUSE_FILTER_IGNORE
	return d


# ── 길드 (허브) ─────────────────────────────────────

## 길드 하우스 (단장의 책상). 마을에서 들어온다 (town.gd)
func _show_hub() -> void:
	town.show_guild()


## 주말: 위탁 의뢰 결과까지 정리한 장부 → 소식
func _weekend() -> void:
	town.show_ledger(Game.settle(), _show_news)


func _left_quests() -> Array:
	return Game.picks.filter(func(q): return not Game.results.has(q))


# ── 이번 주 의뢰: 지도 위 셋 중 둘 ─────────────────

func _show_board() -> void:
	if Defs.SCENES.has("week%d" % Game.week):
		_play("week%d" % Game.week, func(_s, _k): _board())
	else:
		_board()


func _board() -> void:
	_clear()
	Game.stage = "hub"
	bg.texture = Game.tex("backgrounds/scene/bg_world_map.png")
	bg.modulate = Color.WHITE
	var head := Label.new()
	head.text = "이번 주 의뢰 · 둘만 고를 수 있다"
	head.position = Vector2(24, 18)
	_outlined(head, 20 if touch else 32, Color(1.0, 0.92, 0.7))
	screen.add_child(head)
	for qid in Defs.WEEK_QUESTS_BY.get(Game.week, []):
		var q: Dictionary = Defs.QUESTS[qid]
		var b := Button.new()
		b.focus_mode = FOCUS_NONE
		var on: bool = qid in Game.picks
		b.text = ("✔ " if on else "") + q.name
		b.add_theme_font_size_override("font_size", 14 if touch else 22)
		b.anchor_left = q.pin.x * 0.62
		b.anchor_top = q.pin.y
		b.anchor_right = q.pin.x * 0.62
		b.anchor_bottom = q.pin.y
		b.offset_right = 260 if not touch else 170
		b.offset_bottom = 54 if not touch else 38
		if on:
			b.add_theme_stylebox_override("normal", UI.sbt("btn_gold", 18, 10))
		b.pressed.connect(func():
			_board_sel = qid
			_board())
		screen.add_child(b)
	var v := _panel(0.64, 0.12, 0.97, 0.92)
	if _board_sel == "":
		v.add_child(_label("지도의 의뢰를 눌러 살펴본다.", 14 if touch else 22))
	else:
		var q: Dictionary = Defs.QUESTS[_board_sel]
		v.add_child(_label(q.name, 18 if touch else 28, Color(0.96, 0.84, 0.55)))
		v.add_child(_label("의뢰인: %s · %s의 인장" % [q.client, q.seal], 12 if touch else 18, Color(0.8, 0.75, 0.65)))
		v.add_child(_label(q.desc, 14 if touch else 22))
		var on: bool = _board_sel in Game.picks
		var b := _btn("고르지 않기" if on else "이 의뢰를 맡는다", func():
			if _board_sel in Game.picks:
				Game.picks.erase(_board_sel)
			elif Game.picks.size() < Defs.WEEK_PICKS:
				Game.picks.append(_board_sel)
			_board())
		b.disabled = not on and Game.picks.size() >= Defs.WEEK_PICKS
		v.add_child(b)
	var sp := Control.new()
	sp.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(sp)
	v.add_child(_label("고른 의뢰 %d / %d · 고르지 않은 의뢰는 다음 주 소식으로 돌아온다" % [Game.picks.size(), Defs.WEEK_PICKS], 12 if touch else 18, Color(0.85, 0.8, 0.7)))
	var go := _btn("이번 주 확정", func():
		_board_sel = ""
		_start_quest(Game.picks[0]), true)
	go.disabled = Game.picks.size() < Defs.WEEK_PICKS
	v.add_child(go)


# ── 의뢰: 시작 장면 → 연대기 페이지 → 마무리 장면 ───

func _start_quest(qid: String) -> void:
	_play(Defs.QUESTS[qid].intro, func(_s, _k): _open_page(qid))


func _open_page(qid: String) -> void:
	Game.stage = "page"
	Game.page = {"quest": qid, "node": "start", "lines": [], "visited": ["start"], "vars": {}, "luck": Game.LUCK_START, "fail": false, "done": false}
	_show_page()
	var q: Dictionary = Defs.QUESTS[qid]
	_add_line("단장 일행은 '%s' 의뢰를 맡아 길을 나섰다." % q.name)
	_enter(q.nodes.start.next)


func _show_page() -> void:
	_clear()
	bg.texture = null
	page_view = Page.new()
	page_view.bold = bold
	page_view.touch = touch
	page_view.anchor_right = 0.66
	page_view.anchor_bottom = 1.0
	screen.add_child(page_view)
	side = _panel(0.665, 0.04, 0.985, 0.96)
	_sync_page()


func _sync_page() -> void:
	var p: Dictionary = Game.page
	var q: Dictionary = Defs.QUESTS[p.quest]
	page_view.set_state(q, p.visited, p.lines, p.luck, p.done, "하웰 모험가 길드 연대기 · 제%d주 · %s" % [Game.week, q.name])


func _add_line(s: String) -> void:
	Game.page.lines.append(s)
	_sync_page()


func _side_clear() -> void:
	for c in side.get_children():
		c.queue_free()


func _enter(id: String) -> void:
	var p: Dictionary = Game.page
	p.node = id
	if p.visited.is_empty() or p.visited[-1] != id:
		p.visited.append(id)
	_sync_page()
	var n: Dictionary = Defs.QUESTS[p.quest].nodes[id]
	await get_tree().create_timer(0.6).timeout
	_side_clear()
	match n.t:
		"talk":
			_talk(n)
		"battle":
			_battle_node(n)
		"camp":
			_camp(n)
		"end":
			_finish_page()


func _talk(n: Dictionary) -> void:
	var fs := 14 if touch else 22
	side.add_child(_label(n.title, 18 if touch else 30, Color(0.96, 0.84, 0.55)))
	side.add_child(_label(n.text, fs))
	var p: Dictionary = Game.page
	for ch in n.choices:
		var who: Dictionary = Game.best(ch.stat, ch.get("who", ""))
		if who.is_empty():
			continue
		var pct := roundi(Game.chance(who.mod, ch.dc) * 100)
		var tag := "[%s · %s]" % [load("res://scripts/fk_defs.gd").STAT[ch.stat], who.name]
		var b := _btn("%s %s  %d%%" % [tag, ch.label, pct if not _luck_use else 100], _choose.bind(ch, who))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		side.add_child(b)
	var sp := Control.new()
	sp.size_flags_vertical = SIZE_EXPAND_FILL
	side.add_child(sp)
	var lb := CheckButton.new()
	lb.text = "행운 주사위로 확정 성공 (남은 %d)" % p.luck
	lb.button_pressed = _luck_use
	lb.disabled = p.luck <= 0
	lb.focus_mode = FOCUS_NONE
	lb.add_theme_font_size_override("font_size", 13 if touch else 20)
	lb.toggled.connect(func(on: bool):
		_luck_use = on
		_side_clear()
		_talk(n))
	side.add_child(lb)


func _choose(ch: Dictionary, who: Dictionary) -> void:
	var p: Dictionary = Game.page
	var ok := false
	var roll := 0
	var used: bool = _luck_use and p.luck > 0
	_luck_use = false
	if used:
		p.luck -= 1
		ok = true
	else:
		roll = randi_range(1, 20)
		ok = roll == 20 or (roll != 1 and roll + who.mod >= ch.dc)
		if roll == 20:
			p.luck = mini(Game.LUCK_MAX, p.luck + 1)
	_sync_page()
	_side_clear()
	var fs := 14 if touch else 22
	var big := Label.new()
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if used:
		big.text = "행운 주사위 · 확정 성공"
	else:
		big.text = "d20: %d %s %d = %d  (필요 %d)" % [roll, "+" if who.mod >= 0 else "-", absi(who.mod), roll + who.mod, ch.dc]
	_outlined(big, 18 if touch else 30, Color(0.6, 1.0, 0.6) if ok else Color(1.0, 0.55, 0.5))
	side.add_child(big)
	var res := _label("성공!" if ok else "실패…", 20 if touch else 34, Color(0.6, 1.0, 0.6) if ok else Color(1.0, 0.55, 0.5), false)
	res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side.add_child(res)
	if roll == 20:
		side.add_child(_label("자연 20! 행운 주사위 +1", fs, Color(1.0, 0.85, 0.4)))
	var out: Dictionary = ch.ok if ok else ch.ng
	side.add_child(_label(out.line, fs))
	side.add_child(_btn("계속", func(): _apply(out), true))


## 선택 결과 적용: 연대기 문장, 페이지 변수, 깃발, 다음 칸
func _apply(out: Dictionary) -> void:
	var p: Dictionary = Game.page
	_add_line(out.line)
	for k in out.get("set", {}):
		p.vars[k] = out.set[k]
	if out.has("flag"):
		Game.flags[out.flag] = true
	if out.get("fail", false):
		p.fail = true
	_enter(out.next)


func _battle_node(n: Dictionary) -> void:
	var p: Dictionary = Game.page
	var fs := 14 if touch else 22
	side.add_child(_label(n.title, 18 if touch else 30, Color(1.0, 0.6, 0.5)))
	side.add_child(_label(n.text, fs))
	if p.vars.get("ambush", false) and n.has("ambush_text"):
		side.add_child(_label("기습! " + n.ambush_text, fs, Color(0.6, 1.0, 0.6)))
	var names: Array = Game.party.map(func(k): return load("res://scripts/fk_defs.gd").HEROES[k].name)
	side.add_child(_label("파티: " + ", ".join(PackedStringArray(names)), 12 if touch else 18, Color(0.8, 0.75, 0.65)))
	side.add_child(_label("행운 주사위 %d개를 들고 간다" % p.luck, 12 if touch else 18, Color(0.85, 0.7, 1.0)))
	var sp := Control.new()
	sp.size_flags_vertical = SIZE_EXPAND_FILL
	side.add_child(sp)
	side.add_child(_btn("전투 시작", func():
		Game.battle_req = {"idx": n.battle, "party": Game.party.duplicate(), "luck": p.luck, "ambush": p.vars.get("ambush", false) and n.has("ambush_text")}
		get_tree().change_scene_to_file("res://fk.tscn"), true))


func _battle_result(res: Dictionary) -> void:
	var p: Dictionary = Game.page
	p.luck = res.get("luck", p.luck)
	p.vars.erase("ambush")
	_sync_page()
	var n: Dictionary = Defs.QUESTS[p.quest].nodes[p.node]
	var win: bool = res.result == "win"
	var out: Dictionary = n.win if win else n.lose
	_side_clear()
	var big := _label("승리!" if win else "패배…", 22 if touch else 40, Color(0.6, 1.0, 0.6) if win else Color(1.0, 0.55, 0.5), false)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side.add_child(big)
	side.add_child(_label(out.line, 14 if touch else 22))
	side.add_child(_btn("계속", func(): _apply(out), true))


func _camp(n: Dictionary) -> void:
	var p: Dictionary = Game.page
	side.add_child(_label(n.title, 18 if touch else 30, Color(1.0, 0.75, 0.45)))
	side.add_child(_label(n.text, 14 if touch else 22))
	side.add_child(_label("캠프: 행운 주사위 1개를 더 굴린다 (최대 %d)" % Game.LUCK_MAX, 12 if touch else 18, Color(0.85, 0.7, 1.0)))
	side.add_child(_btn("쉬어 간다", func():
		p.luck = mini(Game.LUCK_MAX, p.luck + 1)
		_apply({"line": n.line, "next": n.next}), true))


func _finish_page() -> void:
	var p: Dictionary = Game.page
	var q: Dictionary = Defs.QUESTS[p.quest]
	var ok: bool = not p.fail
	p.done = true
	Game.results[p.quest] = "ok" if ok else "ng"
	if ok and q.has("ok_flag"):
		Game.flags[q.ok_flag] = true
	Game.pages.append({"quest": p.quest, "lines": p.lines.duplicate()})
	_sync_page()
	var rew: Dictionary = Game.quest_reward(q.name, ok)
	side.add_child(_label("페이지 완성", 20 if touch else 34, Color(0.96, 0.84, 0.55)))
	side.add_child(_label("의뢰 성공" if ok else "의뢰는 절반만 이뤘다", 14 if touch else 22, Color(0.6, 1.0, 0.6) if ok else Color(1.0, 0.7, 0.5)))
	side.add_child(_label("보상: 금화 %d · 명성 %d" % [rew.gold, rew.fame], 13 if touch else 20, Color(1.0, 0.9, 0.6)))
	side.add_child(_btn("마무리", func():
		_play(q.outro_ok if ok else q.outro_ng, func(_s, _k): _show_hub()), true))


# ── 주말 소식 → 결전 ───────────────────────────────

func _week_news() -> Array:
	var out: Array = []
	for qid in Defs.WEEK_QUESTS_BY.get(Game.week, []):
		var q: Dictionary = Defs.QUESTS[qid]
		if not qid in Game.picks:
			out.append("[color=#ffb08a]✖ %s[/color] — %s" % [q.name, q.skip.news])
			Game.flags[q.skip.flag] = true
		else:
			var ok: bool = Game.results.get(qid, "") == "ok"
			out.append("%s %s — %s" % ["[color=#9aff9a]✔[/color]" if ok else "[color=#ffd28a]△[/color]", q.name, "성공" if ok else "절반의 성공"])
	return out


func _finale_mods() -> Dictionary:
	var luck := Game.LUCK_START
	var boss := 0
	var notes: Array = []
	if Game.flags.get("village_saved", false):
		luck += 1
		notes.append("북쪽 마을 자경단이 횃불을 들고 왔다 · 행운 주사위 +1")
	if Game.flags.get("village_raided", false):
		notes.append("털린 북쪽 마을은 아무도 오지 않았다")
	if Game.flags.get("supply_cut", false):
		boss -= 15
		notes.append("보급이 끊겨 굶주린 붉은 수염 · 보스 체력 -15")
	elif Game.flags.get("supply_strong", false):
		boss += 10
		notes.append("보급이 넉넉한 붉은 수염 · 보스 체력 +10")
	if Game.flags.get("redbeard_note", false):
		luck += 1
		notes.append("서고에서 찾은 쪽지로 습격을 미리 알았다 · 행운 주사위 +1")
	return {"luck": mini(luck, Game.LUCK_MAX), "boss_hp": boss, "notes": notes}


func _show_news() -> void:
	_clear()
	bg.texture = Game.tex("backgrounds/scene/bg_guildhall_camp_night.png")
	bg.modulate = Color(0.75, 0.72, 0.7)
	var v := _panel(0.15, 0.08, 0.85, 0.92)
	v.add_child(_label("주말 · 이번 주 소식", 20 if touch else 34, Color(0.96, 0.84, 0.55)))
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.add_theme_font_size_override("normal_font_size", 14 if touch else 22)
	var lines := _week_news()
	if lines.is_empty():
		lines = ["조용한 한 주였다. 위탁 의뢰를 맡은 모험가들만 바삐 오갔다."]
	Game.news = lines.duplicate()
	r.text = "\n".join(PackedStringArray(lines))
	v.add_child(r)
	if Game.week < Defs.FINALE_WEEK:
		var sp0 := Control.new()
		sp0.size_flags_vertical = SIZE_EXPAND_FILL
		v.add_child(sp0)
		v.add_child(_label("다음 주에도 의뢰는 들어온다. 스카우트실에 새 지원자가 찾아온다.", 13 if touch else 20, Color(0.85, 0.8, 0.7)))
		v.add_child(_btn("다음 주로", func():
			Game.week += 1
			Game.picks = []
			Game.new_week()
			town.show_town(), true))
		return
	var m := _finale_mods()
	v.add_child(_label("결전 준비", 16 if touch else 26, Color(1.0, 0.6, 0.5)))
	var r2 := RichTextLabel.new()
	r2.bbcode_enabled = true
	r2.fit_content = true
	r2.add_theme_font_size_override("normal_font_size", 13 if touch else 20)
	r2.text = "\n".join(PackedStringArray(m.notes.map(func(s): return "· " + s))) if not m.notes.is_empty() else "· 특별한 도움은 없다"
	v.add_child(r2)
	var sp := Control.new()
	sp.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(sp)
	v.add_child(_btn("결전: 붉은 수염의 습격", func():
		_play("finale_in", func(_s, _k): _go_finale()), true))


func _go_finale() -> void:
	Game.stage = "finale"
	var m := _finale_mods()
	Game.battle_req = {"idx": Defs.FINALE_BATTLE, "party": Game.party.duplicate(), "luck": m.luck, "boss_hp": m.boss_hp}
	get_tree().change_scene_to_file("res://fk.tscn")


func _finale_result(res: Dictionary) -> void:
	if res.result == "win":
		_play("finale_ok", func(_s, _k): _show_end())
		return
	_clear()
	bg.texture = Game.tex("backgrounds/scene/bg_guildhall_ruined.png")
	bg.modulate = Color(0.5, 0.45, 0.45)
	var v := _panel(0.3, 0.3, 0.7, 0.7)
	v.add_child(_label("길드가 무너질 위기다…", 20 if touch else 32, Color(1.0, 0.55, 0.5)))
	v.add_child(_btn("다시 맞선다", _go_finale, true))
	v.add_child(_btn("처음으로", _show_title))


func _show_end() -> void:
	_clear()
	Game.stage = "end"
	bg.texture = Game.tex("backgrounds/scene/bg_room_archive.png")
	bg.modulate = Color(0.6, 0.55, 0.5)
	var v := _panel(0.18, 0.06, 0.82, 0.94)
	v.add_child(_label("1장 체험판 끝 · 단장이 쓴 연대기", 20 if touch else 34, Color(0.96, 0.84, 0.55)))
	var r := _chronicle_text()
	r.text += "\n[i]하웰 모험가 길드의 간판이 다시 걸렸다… 다음 이야기는 2장에서.[/i]"
	v.add_child(r)
	v.add_child(_btn("처음으로", _show_title, true))


## 완성한 페이지들을 이어 쓴 연대기 글
func _chronicle_text() -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.size_flags_vertical = SIZE_EXPAND_FILL
	var fs := 15 if touch else 24
	r.add_theme_font_size_override("normal_font_size", fs)
	r.add_theme_font_size_override("italics_font_size", fs)
	r.add_theme_font_size_override("bold_font_size", fs + 4)
	r.add_theme_font_override("bold_font", bold)
	r.add_theme_constant_override("line_separation", 6)
	var t := ""
	for pg in Game.pages:
		var res: String = Game.results.get(pg.quest, "")
		var tag := "  [color=#8fc48a]완수[/color]" if res == "ok" else ("  [color=#d9796a]실패[/color]" if res == "ng" else "")
		t += "[b][color=#f2d38a]%s[/color][/b]%s\n" % [Defs.QUESTS[pg.quest].name, tag]
		for ln in pg.lines:
			t += "[color=#e8dcc4]— %s[/color]\n" % ln
		t += "\n"
	r.text = t
	return r


func _show_book() -> void:
	_clear()
	bg.modulate = Color(0.5, 0.48, 0.45)
	var v := _panel(0.18, 0.06, 0.82, 0.94)
	v.add_child(_label("연대기", 20 if touch else 34, Color(0.96, 0.84, 0.55)))
	var r := _chronicle_text()
	if Game.pages.is_empty():
		r.text = "아직 완성한 페이지가 없다."
	v.add_child(r)
	v.add_child(_btn("돌아가기", _show_hub, true))
