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
const Kit = preload("res://scripts/ui_kit.gd")
const Desk = preload("res://scripts/guild_desk.gd")
const G = preload("res://scripts/guild_defs.gd")
const FDefs = preload("res://scripts/fk_defs.gd")
const Talk = preload("res://scripts/talk.gd")
const PDefs = preload("res://scripts/party_defs.gd")
const Mates = preload("res://scripts/companions.gd")

var touch := false
var town  # 마을·길드 운영 화면
var mates  # 동료 화면 (companions.gd)
var desk  # 길드 하우스 로비
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
var autoplay := false  # 자동 플레이 시험(sims/playtest.gd): 장면을 건너뛴다


func _ready() -> void:
	touch = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or "--touch" in OS.get_cmdline_user_args() or get_window().size.y < 700
	if touch:
		get_window().content_scale_size = Vector2i(960, 540)
	var t: Dictionary = UI.make_theme(touch)
	theme = t.theme
	bold = t.bold
	Kit.setup(touch, theme.default_font, bold)
	Kit.apply_theme(theme)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	town = Town.new(self)
	mates = Mates.new(self)
	desk = Desk.new(self, town)
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
	toast.add_theme_font_override("font", Kit.f_bold)
	toast.add_theme_font_size_override("font_size", Kit.pxi(17))
	toast.add_theme_color_override("font_color", Color.WHITE)
	var tsb := Kit.sb_flat(Color(0.05, 0.075, 0.13, 0.94), Kit.LINE, 1, 12)
	tsb.border_color = Kit.BRASS
	tsb.border_width_left = Kit.pxi(3)
	tsb.shadow_color = Color(0, 0, 0, 0.4)
	tsb.shadow_size = Kit.pxi(10)
	tsb.content_margin_left = Kit.px(26)
	tsb.content_margin_right = Kit.px(30)
	tsb.content_margin_top = Kit.px(10)
	tsb.content_margin_bottom = Kit.px(11)
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
	if _shot != "" or goto != "":
		Game.save_path = "user://autosave_test.dat"
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
		"title":
			_show_title()
		"continue":
			_start_game()
		"playtest":
			load("res://sims/playtest.gd").run(self)
		"mates":
			# mates:cecile:bond
			Game.flags["seen_week%d" % Game.week] = true
			Game.give_xp("lina", 150)
			Game.heroes.lina.weapon = [1, 1]
			Game.items = {"potion": 2, "apple": 1, "tea": 2, "knight_book": 1}
			Game.bond_seen["lina"] = 1
			Game.bond["lina"] = 14
			mates.show(g.get_slice(":", 1) if g.get_slice_count(":") > 1 else "lina", g.get_slice(":", 2) if g.get_slice_count(":") > 2 else "grow")
		"town":
			town.show_town()
		"hub":
			Game.flags["seen_week%d" % Game.week] = true
			if g.get_slice(":", 1) == "pick":
				Game.picks = ["bandits"]
			if g.get_slice(":", 1) == "bond":
				Game.bond["nora"] = 30
				Game.bond_seen["nora"] = 0
			_show_hub()
		"scout":
			town.show_scout()
		"place":
			Game.bond["martha"] = 30
			Game.gold = 700
			Game.mats = {"wood": 4, "iron": 4, "herb": 2}
			Game.items = {"potion": 1, "meat": 1, "flowers": 1}
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
			if g.get_slice(":", 1) == "rec":
				Game.facilities["records"] = 3
			Game.picks = ["trapper"]
			_board_sel = "bandits"
			if g.get_slice(":", 1) == "2":  # 2쪽 의뢰 지도
				Game.week = 2
				Game.picks = ["hideout"]
				_board_sel = "boars"
			_board()
		"page":
			Game.picks = [g.get_slice(":", 1), "archive"]
			_open_page(g.get_slice(":", 1))
		"news":
			Game.picks = ["bandits", "trapper"]
			Game.results = {"bandits": "ok", "trapper": "ng"}
			if g.get_slice(":", 1) == "rumor":
				Game.bond_seen["martha"] = 2
			Game.settle()
			_show_news()
		"scene":  # scene:장면[:줄 번호]
			_play(g.get_slice(":", 1), func(_s, _k): _show_hub())
			if g.get_slice_count(":") > 2:
				player._i = int(g.get_slice(":", 2))
				player._show_line()
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
		"lose":
			_finale_result({"result": "lose"})
		"talk":
			# talk:nora (질문) / talk:nora:2 (두 번째 대답을 고른 뒤)
			Game.flags["seen_week%d" % Game.week] = true
			var id := g.get_slice(":", 1)
			if id == "martha":
				town.show_place("tavern")
			else:
				_show_hub()
			Talk.open(self, id, _show_hub)
			var ans := int(g.get_slice(":", 2)) if g.get_slice_count(":") > 2 else 0
			if ans > 0:
				var picks := screen.get_child(screen.get_child_count() - 1).find_children("*", "MarginContainer", true, false).filter(func(n): return n is Kit.Pick)
				picks[ans - 1].cb.call()
		"book":
			Game.pages = [{"quest": "bandits", "lines": ["단장 일행은 '북쪽 마을의 도적' 의뢰를 맡아 길을 나섰다.", "겁먹은 마을 사람들이 도적이 오는 길을 알려 주었다."]}, {"quest": "trapper", "lines": ["숲 가장자리에서 덫 사냥꾼의 흔적을 찾았다."]}]
			Game.results = {"bandits": "ok", "trapper": "ng"}
			_show_book()
		"end":
			Game.pages =[{"quest": "bandits", "lines": ["샘플 문장 하나.", "샘플 문장 둘."]}, {"quest": "trapper", "lines": ["샘플 문장 셋."]}]
			Game.results = {"bandits": "ok", "trapper": "ng"}
			_show_end()


# ── 공용 ────────────────────────────────────────────

func _clear() -> void:
	Game.save()  # 자동 저장: 화면이 바뀔 때마다
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
	if autoplay:
		then.call_deferred("", true)
		return
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
	bg.modulate = Color(0.72, 0.68, 0.64)
	Kit.shade(screen, "l", 0.92, 0.62)
	Kit.shade(screen, "b", 0.7, 0.4)
	# 왼쪽 기둥: 문장 · 제목 · 버튼
	var v := Kit.vbox(0)
	v.anchor_top = 0.5
	v.anchor_bottom = 0.5
	v.offset_left = Kit.px(110)
	v.grow_vertical = GROW_DIRECTION_BOTH
	screen.add_child(v)
	var top := Kit.hbox(16)
	top.add_child(Kit.icon("emblem_harwell", 72, Color.WHITE))
	var tv := Kit.vbox(4)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_child(Kit.cap("HARWELL ADVENTURERS' GUILD"))
	var sub := Kit.hbox(8)
	sub.add_child(Kit.Diamond.make(Kit.px(6), Kit.BRASS))
	sub.add_child(Kit.label("하웰 모험가 길드 · 1장 체험판", 14, Color("d5d9e3")))
	tv.add_child(sub)
	top.add_child(tv)
	v.add_child(top)
	v.add_child(Kit.spacer(0, 18))
	v.add_child(Kit.shadowed(Kit.title("몰락한 길드", 84, Color("f4efe4"))))
	var t2 := Kit.hbox(18)
	t2.add_child(Kit.shadowed(Kit.title("재건하기", 84, Kit.BRASS_HI)))
	var ln := Desk.Bar.new()
	ln.ratio = 1.0
	ln.col = Color(Kit.BRASS, 0.6)
	ln.custom_minimum_size = Vector2(Kit.px(150), 1)
	ln.size_flags_vertical = SIZE_SHRINK_CENTER
	t2.add_child(ln)
	v.add_child(t2)
	v.add_child(Kit.spacer(0, 14))
	v.add_child(Kit.shadowed(Kit.label("무너진 길드 하우스를 다시 세우고, 흩어진 모험가를 모은다.", 17, Color("cfd4de"))))
	v.add_child(Kit.spacer(0, 44))
	# 게임 시작 하나: 자동 저장이 있으면 그 자리에서, 없으면 처음부터
	var b1 := Kit.btn_main("게임 시작", _save_note(), _start_game, 60)
	b1.custom_minimum_size.x = Kit.px(380)
	b1.size_flags_horizontal = SIZE_SHRINK_BEGIN
	v.add_child(b1)
	v.add_child(Kit.spacer(0, 10))
	var b2 := Kit.btn_sub("전투 시험판", "i_sword", func(): get_tree().change_scene_to_file("res://fk.tscn"), 50, 380)
	b2.size_flags_horizontal = SIZE_SHRINK_BEGIN
	v.add_child(b2)
	var ver := Kit.label("PROJECT D20 · 체험판", 11, Color(1, 1, 1, 0.35), Kit.f_cap)
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = Kit.px(110)
	ver.offset_top = -Kit.px(44)
	screen.add_child(ver)
	desk._slide_in(v, Vector2(-Kit.px(30), 0))


## 게임 시작 버튼의 작은 글: 저장이 있으면 몇 주차·공사 단계
func _save_note() -> String:
	var d := _peek_save()
	if d.is_empty():
		return "새 이야기"
	return "장부 %d쪽 · %s" % [d.get("week", 1), G.STAGES[clampi(d.get("build", 0), 0, G.STAGES.size() - 1)].name]


func _peek_save() -> Dictionary:
	var f := FileAccess.open(Game.save_path, FileAccess.READ)
	if f == null:
		return {}
	var d = str_to_var(f.get_as_text())
	f.close()
	# 체험판을 끝까지 본 저장은 새로 시작한다
	if not d is Dictionary or d.get("stage", "") == "end":
		return {}
	return d


## 게임 시작: 자동 저장이 있으면 그 자리로, 없으면 오프닝부터
func _start_game() -> void:
	if _peek_save().is_empty() or not Game.load_save():
		Game.clear_save()
		Game.reset()
		_play("opening", func(_s, _k): town.show_town())
		return
	match Game.stage:
		"page":
			if Game.page.get("done", false):
				_show_hub()
			else:
				_show_page()
				var node: String = Game.page.node
				_enter(Defs.QUESTS[Game.page.quest].nodes.start.next if node == "start" else node)
		"weekend":
			town.show_ledger(Game.settle(), _show_news)
		"news", "finale":
			_show_news()
		_:
			town.show_town()

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
	desk.show()


## 주말: 위탁 의뢰 결과까지 정리한 장부 → 소식
func _weekend() -> void:
	Game.stage = "weekend"
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
	var quests: Array = Defs.WEEK_QUESTS_BY.get(Game.week, [])
	var confirmed: bool = Game.flags.get("picked_%d" % Game.week, false)
	if _board_sel == "" and not quests.is_empty():
		_board_sel = quests[0]
	town._frame("의뢰 지도", "장부 %d쪽 · %s" % [Game.week, "이번 의뢰를 정했다" if confirmed else "둘만 고를 수 있다"],
		func():
			_board_sel = ""
			_show_hub(), "backgrounds/scene/bg_world_map.png", 0.92)
	Game.stage = "hub"
	for qid in quests:
		var q: Dictionary = Defs.QUESTS[qid]
		var pin := _map_pin(qid, qid == _board_sel, qid in Game.picks)
		pin.anchor_left = q.pin.x * 0.62
		pin.anchor_right = pin.anchor_left
		pin.anchor_top = q.pin.y
		pin.anchor_bottom = q.pin.y
		pin.offset_left = -Kit.px(28)
		pin.offset_top = -Kit.px(28)
		screen.add_child(pin)
	var v: VBoxContainer = town._side(520)
	if _board_sel == "":
		v.add_child(Kit.label("지금은 지도에 붙은 의뢰가 없다.", 16, Kit.DIM, null, true))
		return
	var q: Dictionary = Defs.QUESTS[_board_sel]
	var head := Kit.hbox(14)
	head.add_child(Kit.seal(Desk.SEAL_KIND.get(q.get("seal", ""), "crown"), 64))
	var hv := Kit.vbox(2)
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	hv.add_child(Kit.cap("의뢰처 · %s (%s)" % [q.get("client", ""), Desk.SEAL_NAME.get(q.get("seal", ""), "")]))
	hv.add_child(Kit.title(q.name, 30))
	head.add_child(hv)
	v.add_child(head)
	var meta := Kit.hbox(8)
	for tg in q.get("tags", []):
		meta.add_child(Kit.chip(tg, Color(1, 1, 1, 0.08), Color("dfe3ea")))
	meta.add_child(Kit.spacer(4))
	meta.add_child(Kit.label("위험", 12, Kit.DIM))
	for r in 3:
		meta.add_child(Kit.Diamond.make(Kit.px(7), Kit.BAD if r < q.get("risk", 1) else Color(1, 1, 1, 0.2), r < q.get("risk", 1)))
	v.add_child(meta)
	v.add_child(Kit.spacer(0, 2))
	v.add_child(Kit.label(q.desc, 16, Color("e3e6ec"), null, true))
	v.add_child(Kit.spacer(0, 2))
	var rw := Kit.hbox(8)
	rw.add_child(Kit.label("보상", 13, Kit.DIM))
	rw.add_child(Kit.icon("res_gold", 20, Color.WHITE))
	rw.add_child(Kit.num(str(G.QUEST_REWARD[Game.chapter()].ok.gold), 17))
	rw.add_child(Kit.spacer(6))
	rw.add_child(Kit.icon("res_fame", 18, Color.WHITE))
	rw.add_child(Kit.num("+%d" % G.QUEST_REWARD[Game.chapter()].ok.fame, 17))
	v.add_child(rw)
	_enemy_preview(v, q)
	v.add_child(Kit.spacer(0, 4))
	v.add_child(Kit.hr())
	v.add_child(Kit.spacer(0, 4))
	var st := Kit.hbox(8)
	st.add_child(Kit.label("고른 의뢰", 13, Kit.DIM))
	for i in Defs.WEEK_PICKS:
		st.add_child(Kit.Diamond.make(Kit.px(9), Kit.BRASS_HI, i < Game.picks.size(), i < Game.picks.size()))
	st.add_child(Kit.num("%d / %d" % [Game.picks.size(), Defs.WEEK_PICKS], 14, Kit.DIM))
	v.add_child(st)
	if confirmed:
		v.add_child(Kit.label("이번 의뢰는 이미 정했다. 길드 하우스에서 출발한다.", 14, Kit.DIM, null, true))
		return
	v.add_child(Kit.label("고르지 않은 의뢰는 장부를 마감할 때 소식으로 돌아온다.", 13, Kit.DIM, null, true))
	v.add_child(Kit.spacer(0, 4))
	var acts := Kit.hbox(10)
	v.add_child(acts)
	var on: bool = _board_sel in Game.picks
	var tg_b := Kit.btn_sub("빼기" if on else "맡는다", "i_close" if on else "i_check", func():
		if _board_sel in Game.picks:
			Game.picks.erase(_board_sel)
		elif Game.picks.size() < Defs.WEEK_PICKS:
			Game.picks.append(_board_sel)
		_board(), 54, 150)
	tg_b.disabled = not on and Game.picks.size() >= Defs.WEEK_PICKS
	acts.add_child(tg_b)
	var need: int = Defs.WEEK_PICKS - Game.picks.size()
	var go := Kit.btn_main("의뢰 확정", ("%d개 더" % need) if need > 0 else "첫 의뢰로 출발", func():
		_board_sel = ""
		Game.flags["picked_%d" % Game.week] = true
		_start_quest(Game.picks[0]))
	go.disabled = need > 0
	go.size_flags_horizontal = SIZE_EXPAND_FILL
	acts.add_child(go)


## 기록실 2레벨: 의뢰의 전투 칸 적 구성, 3레벨: 적 체력과 공격력까지
func _enemy_preview(v: VBoxContainer, q: Dictionary) -> void:
	var lv: int = Game.facilities.get("records", 0)
	var fights: Array = []
	for nid in q.nodes:
		var n: Dictionary = q.nodes[nid]
		if n.t == "battle" and not n.battle in fights:
			fights.append(n.battle)
	if fights.is_empty():
		return
	if lv < 2:
		v.add_child(Kit.label("적 구성은 기록실 2레벨부터 보인다.", 12, Kit.DIM))
		return
	v.add_child(Kit.cap("기록실 · 예상되는 적"))
	for bi in fights:
		var cnt := {}
		for e in FDefs.BATTLES[bi].enemies:
			cnt[e] = cnt.get(e, 0) + 1
		var h := HFlowContainer.new()
		h.add_theme_constant_override("h_separation", Kit.pxi(6))
		h.add_theme_constant_override("v_separation", Kit.pxi(4))
		for e in cnt:
			var en: Dictionary = FDefs.ENEMIES[e]
			var t: String = "%s ×%d" % [en.name, cnt[e]] if cnt[e] > 1 else en.name
			if lv >= 3:
				t += " (체력 %d · 공격 %d)" % [en.hp, en.power]
			h.add_child(Kit.chip(t, Color(Kit.BAD, 0.15), Color("ffd2c8"), 12))
		v.add_child(h)


## 지도 위 의뢰 핀: 봉랍 인장 + 이름표 (고른 의뢰는 파랑, 보고 있는 의뢰는 놋쇠 테)
func _map_pin(qid: String, sel: bool, picked: bool) -> Button:
	var q: Dictionary = Defs.QUESTS[qid]
	var b := Button.new()
	b.focus_mode = FOCUS_NONE
	b.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	var h := Kit.hbox(0)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(h)
	var sl := Kit.seal(Desk.SEAL_KIND.get(q.get("seal", ""), "crown"), 56)
	h.add_child(sl)
	var plate := PanelContainer.new()
	plate.mouse_filter = MOUSE_FILTER_IGNORE
	var sb := Kit.sb_flat(Kit.BLUE if picked else Color(0.05, 0.075, 0.13, 0.92), Kit.BRASS_HI if sel else Kit.LINE, 2 if sel else 1, 0, 10)
	sb.content_margin_left = Kit.px(12)
	sb.content_margin_right = Kit.px(14)
	sb.content_margin_top = Kit.px(6)
	sb.content_margin_bottom = Kit.px(7)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = Kit.pxi(8)
	plate.add_theme_stylebox_override("panel", sb)
	plate.size_flags_vertical = SIZE_SHRINK_CENTER
	var pv := Kit.hbox(8)
	if picked:
		pv.add_child(Kit.icon("i_check", 18, Color.WHITE))
	pv.add_child(Kit.bold(q.name, 16, Color.WHITE))
	plate.add_child(pv)
	h.add_child(plate)
	b.custom_minimum_size = h.get_combined_minimum_size()
	h.resized.connect(func(): b.custom_minimum_size = h.size)
	b.mouse_entered.connect(func(): h.create_tween().tween_property(h, "position:y", -Kit.px(3), 0.08))
	b.mouse_exited.connect(func(): h.create_tween().tween_property(h, "position:y", 0.0, 0.1))
	b.pressed.connect(func():
		_board_sel = qid
		_board())
	return b


# ── 의뢰: 시작 장면 → 연대기 페이지 → 마무리 장면 ───

func _start_quest(qid: String) -> void:
	_play(Defs.QUESTS[qid].intro, func(_s, _k): _open_page(qid))


func _open_page(qid: String) -> void:
	Game.stage = "page"
	# 마르타 3단계(길드의 식탁): 출발 도시락 → 행운 주사위 +1
	var luck0: int = mini(Game.LUCK_MAX, Game.LUCK_START + (1 if Game.bond_seen.get("martha", 0) >= 3 else 0))
	Game.page = {"quest": qid, "node": "start", "lines": [], "visited": ["start"], "vars": {}, "luck": luck0, "fail": false, "done": false}
	var q: Dictionary = Defs.QUESTS[qid]
	var prep: Array = []
	# 행운 부적: 빈 행운 주사위가 있으면 하나 쓴다
	if luck0 < Game.LUCK_MAX and Game.use_item("charm"):
		Game.page.luck += 1
		prep.append("행운 부적을 하나 챙겼다.")
	# 주방 2레벨: 식재료 하나로 도시락 → 이번 의뢰 전투에서 동료 체력 +
	var kl: int = Game.facilities.get("kitchen", 0)
	if kl >= 2:
		var food := Game.use_food()
		if food != "":
			Game.page.vars["lunch"] = 8 if kl >= 3 else 4
			prep.append("주방에서 %s(으)로 도시락을 쌌다." % PDefs.ITEMS[food].name)
	_show_page()
	_add_line("단장 일행은 '%s' 의뢰를 맡아 길을 나섰다." % q.name)
	for s in prep:
		_add_line(s)
	_enter(q.nodes.start.next)


func _show_page() -> void:
	_clear()
	var t: Texture2D = Game.tex(G.STAGES[Game.build].bg)
	bg.texture = t if t != null else Game.tex("backgrounds/scene/bg_guildhall_ruined.png")
	bg.modulate = Color(0.34, 0.34, 0.36)
	page_view = Page.new()
	page_view.bold = bold
	page_view.touch = touch
	page_view.anchor_right = 0.655
	page_view.anchor_bottom = 1.0
	screen.add_child(page_view)
	var c := Kit.card(20, 26)
	c.anchor_left = 0.655
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = Kit.px(6)
	c.offset_right = -Kit.px(30)
	c.offset_top = Kit.px(30)
	c.offset_bottom = -Kit.px(30)
	screen.add_child(c)
	side = Kit.vbox(12)
	c.add_child(side)
	_sync_page()


## 옆 칸 머리: 머리말 + 제목
func _side_head(cap: String, title: String, col := Color.WHITE) -> void:
	side.add_child(Kit.cap(cap))
	side.add_child(Kit.title(title, 32, col))
	side.add_child(Kit.spacer(0, 2))


func _side_text(text: String, col := Color("e3e6ec"), size := 17.0) -> Label:
	var l := Kit.label(text, size, col, null, true)
	side.add_child(l)
	return l


func _side_fill() -> void:
	side.add_child(Kit.spacer(0, 0, true))


## 행운 주사위 줄: 머리말 + 마름모 + 남은 수
func _luck_line(n: int) -> HBoxContainer:
	var h := Kit.hbox(10)
	h.add_child(Kit.label("행운 주사위", 13, Kit.DIM))
	h.add_child(Kit.luck_row(n, Game.LUCK_MAX))
	return h


func _sync_page() -> void:
	var p: Dictionary = Game.page
	var q: Dictionary = Defs.QUESTS[p.quest]
	page_view.set_state(q, p.visited, p.lines, p.luck, p.done, "하웰 모험가 길드 연대기 · 장부 %d쪽 · %s" % [Game.week, q.name])


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
	Game.save()
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
	var p: Dictionary = Game.page
	_side_head("판정 칸 · 고를 수 있는 길", n.title)
	_side_text(n.text)
	side.add_child(Kit.spacer(0, 4))
	for ch in n.choices:
		var who: Dictionary = Game.best(ch.stat, ch.get("who", ""))
		if who.is_empty():
			continue
		side.add_child(_choice(ch, who))
	_side_fill()
	side.add_child(Kit.hr())
	var lh := _luck_line(p.luck)
	lh.add_child(Kit.spacer(0, 0, true))
	var lb := Kit.btn_sub("확정 성공 켜짐" if _luck_use else "행운 주사위 쓰기", "i_star", func():
		_luck_use = not _luck_use
		_side_clear()
		_talk(n), 42, 190)
	lb.disabled = p.luck <= 0
	if _luck_use:
		lb.add_theme_stylebox_override("normal", Kit.sb_flat(Color(Kit.BLUE, 0.35), Kit.BLUE_HI, 1))
	lh.add_child(lb)
	side.add_child(lh)


## 선택지 한 줄: 능력치 칩 + 맡는 사람 / 고르는 말 / 성공 확률
func _choice(ch: Dictionary, who: Dictionary) -> Control:
	var pct := 100 if _luck_use else roundi(Game.chance(who.mod, ch.dc) * 100)
	var b := Kit.pick(_choose.bind(ch, who))
	var h := Kit.hbox(14)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(h)
	var lv := Kit.vbox(5)
	lv.size_flags_horizontal = SIZE_EXPAND_FILL
	var tg := Kit.hbox(8)
	tg.add_child(Kit.chip(FDefs.STAT[ch.stat], Kit.BLUE, Color.WHITE, 12))
	tg.add_child(Kit.label(who.name, 13, Kit.DIM))
	lv.add_child(tg)
	lv.add_child(Kit.label(ch.label, 17, Color.WHITE, Kit.f_bold, true))
	h.add_child(lv)
	var rv := Kit.vbox(0)
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.custom_minimum_size.x = Kit.px(64)
	var n := Kit.num("%d" % pct, 26, Kit.BRASS_HI if _luck_use else (Kit.GOOD if pct >= 70 else (Color.WHITE if pct >= 40 else Kit.BAD)))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(n)
	var pl := Kit.label("성공 %", 11, Kit.DIM)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(pl)
	h.add_child(rv)
	return b


func _choose(ch: Dictionary, who: Dictionary) -> void:
	var p: Dictionary = Game.page
	var ok := false
	var roll := 0
	var used: bool = _luck_use and p.luck > 0
	_luck_use = false
	if used:
		p.luck -= 1
		ok = true
		Game.add_bond(who.key, G.CB_LUCK)  # 그 동료 판정에 행운 주사위를 써 줌
	else:
		roll = randi_range(1, 20)
		ok = roll == 20 or (roll != 1 and roll + who.mod >= ch.dc)
		if roll == 20:
			p.luck = mini(Game.LUCK_MAX, p.luck + 1)
	Game.add_bond(who.key, G.CB_CHECK_OK if ok else G.CB_CHECK_NG)  # "믿고 맡겨 줬다"
	_sync_page()
	_side_clear()
	side.add_child(Kit.cap("판정 · %s · %s" % [FDefs.STAT[ch.stat], who.name]))
	side.add_child(Kit.spacer(0, 6))
	# 주사위 칸: 큰 숫자 + 식
	var dice := Kit.card(14, 18)
	dice.accent = false
	var dh := Kit.hbox(22)
	dice.add_child(dh)
	var dv := Kit.vbox(0)
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.custom_minimum_size.x = Kit.px(110)
	if used:
		var dd := Kit.Diamond.make(Kit.px(34), Kit.BLUE_HI, true, true)
		dd.size_flags_horizontal = SIZE_SHRINK_CENTER
		dv.add_child(dd)
	else:
		var dn := Kit.num(str(roll), 64, Kit.BRASS_HI if roll == 20 else (Kit.BAD if roll == 1 else Color.WHITE))
		dn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dv.add_child(dn)
	var dl := Kit.cap("행운" if used else "d20")
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(dl)
	dh.add_child(dv)
	var fv := Kit.vbox(4)
	fv.alignment = BoxContainer.ALIGNMENT_CENTER
	if used:
		fv.add_child(Kit.label("행운 주사위를 썼다", 15, Kit.DIM))
		fv.add_child(Kit.bold("확정 성공", 18))
	else:
		fv.add_child(Kit.label("%d %s %d (%s)" % [roll, "+" if who.mod >= 0 else "−", absi(who.mod), FDefs.STAT[ch.stat]], 15, Kit.DIM))
		var tot := Kit.hbox(8)
		tot.add_child(Kit.num(str(roll + who.mod), 26))
		var nd := Kit.label("/ 필요 %d" % ch.dc, 15, Kit.DIM)
		nd.size_flags_vertical = SIZE_SHRINK_END
		tot.add_child(nd)
		fv.add_child(tot)
	dh.add_child(fv)
	side.add_child(dice)
	side.add_child(Kit.spacer(0, 6))
	side.add_child(Kit.title("성공" if ok else "실패", 40, Kit.GOOD if ok else Kit.BAD))
	if roll == 20:
		side.add_child(Kit.chip("자연 20 · 행운 주사위 +1", Color(Kit.BRASS, 0.25), Kit.BRASS_HI, 13))
	var out: Dictionary = ch.ok if ok else ch.ng
	_side_text(out.line)
	_side_fill()
	side.add_child(Kit.btn_main("계속", "연대기에 적는다", func(): _apply(out), 58))


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
	_side_head("전투 칸", n.title, Color("ffd2c8"))
	_side_text(n.text)
	if p.vars.get("ambush", false) and n.has("ambush_text"):
		var am := Kit.hbox(8)
		am.add_child(Kit.chip("기습", Color(Kit.GOOD, 0.25), Kit.GOOD, 13))
		var al := Kit.label(n.ambush_text, 15, Kit.GOOD, null, true)
		al.size_flags_horizontal = SIZE_EXPAND_FILL
		am.add_child(al)
		side.add_child(am)
	side.add_child(Kit.spacer(0, 4))
	side.add_child(Kit.hr())
	side.add_child(Kit.cap("출전 파티"))
	var party := Kit.hbox(8)
	for k in Game.party:
		party.add_child(Kit.chip(FDefs.HEROES[k].name, Color(1, 1, 1, 0.08), Color("e3e6ec"), 14))
	side.add_child(party)
	side.add_child(_luck_line(p.luck))
	_side_fill()
	side.add_child(Kit.btn_main("전투 시작", "파티 %d명" % Game.party.size(), func():
		Game.battle_req = {"idx": n.battle, "party": Game.party.duplicate(), "luck": p.luck, "ambush": p.vars.get("ambush", false) and n.has("ambush_text"), "lunch": p.vars.get("lunch", 0)}
		get_tree().change_scene_to_file("res://fk.tscn"), 58))


func _battle_result(res: Dictionary) -> void:
	var p: Dictionary = Game.page
	p.luck = res.get("luck", p.luck)
	_sync_potions(res)
	p.vars.erase("ambush")
	_sync_page()
	var n: Dictionary = Defs.QUESTS[p.quest].nodes[p.node]
	var win: bool = res.result == "win"
	var out: Dictionary = n.win if win else n.lose
	_side_clear()
	_side_head("전투 결과 · %s" % n.title, "승리" if win else "패배", Kit.GOOD if win else Kit.BAD)
	_side_text(out.line)
	side.add_child(_luck_line(p.luck))
	_side_fill()
	side.add_child(Kit.btn_main("계속", "연대기에 적는다", func(): _apply(out), 58))


func _camp(n: Dictionary) -> void:
	var p: Dictionary = Game.page
	_side_head("야영 칸", n.title, Color("ffe1b0"))
	_side_text(n.text)
	side.add_child(Kit.spacer(0, 4))
	side.add_child(_luck_line(p.luck))
	# 마르타 1단계(단골): 싸 준 음식으로 야영 칸 행운 주사위 +1 더
	var gain := 2 if Game.bond_seen.get("martha", 0) >= 1 else 1
	var kitchen: bool = Game.facilities.get("kitchen", 0) >= 1  # 주방 1레벨: 야영 행운 +1
	if kitchen:
		gain += 1
	_side_text("모닥불 곁에서 쉬면 행운 주사위가 %d개 돌아온다 (최대 %d)." % [gain, Game.LUCK_MAX], Kit.DIM, 14)
	if Game.bond_seen.get("martha", 0) >= 1:
		side.add_child(Kit.chip("마르타가 싸 준 음식 · 행운 +1", Color(Kit.GOOD, 0.2), Kit.GOOD, 13))
	if kitchen:
		side.add_child(Kit.chip("길드 주방의 야영 요리 · 행운 +1", Color(Kit.GOOD, 0.2), Kit.GOOD, 13))
	_side_fill()
	side.add_child(Kit.btn_main("쉬어 간다", "행운 +%d" % gain, func():
		p.luck = mini(Game.LUCK_MAX, p.luck + gain)
		_apply({"line": n.line, "next": n.next}), 58))


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
	for k in Game.party:
		Game.add_bond(k, G.CB_PAGE)
	var xp := Game.quest_xp(PDefs.XP_OK if ok else PDefs.XP_NG)
	_side_head("페이지 완성 · %s" % q.name, "의뢰 성공" if ok else "절반의 성공", Kit.GOOD if ok else Color("ffd28a"))
	_side_text("연대기에 한 페이지가 더해졌다." if ok else "의뢰는 절반만 이뤘다. 그래도 길은 기록에 남는다.")
	side.add_child(Kit.spacer(0, 4))
	side.add_child(Kit.hr())
	side.add_child(Kit.cap("받은 보상"))
	var rw := Kit.hbox(10)
	rw.add_child(Kit.icon("res_gold", 28, Color.WHITE))
	rw.add_child(Kit.num("+%d" % rew.gold, 24))
	rw.add_child(Kit.spacer(10))
	rw.add_child(Kit.icon("res_fame", 24, Color.WHITE))
	rw.add_child(Kit.num("+%d" % rew.fame, 24))
	side.add_child(rw)
	if ok and q.has("ok_items"):
		var got: Array = []
		for id in q.ok_items:
			Game.items[id] = Game.items.get(id, 0) + int(q.ok_items[id])
			got.append("%s %d개" % [PDefs.ITEMS[id].name, q.ok_items[id]])
		side.add_child(Kit.label("받은 물건 · " + ", ".join(PackedStringArray(got)), 15, Kit.GOOD))
	_xp_rows(xp)
	_side_fill()
	side.add_child(Kit.btn_main("마무리", "길드로 돌아간다", func():
		_play(q.outro_ok if ok else q.outro_ng, func(_s, _k): _show_hub()), 58))


## 전투에서 쓴 회복약을 가방에 반영
func _sync_potions(res: Dictionary) -> void:
	if not res.has("potions"):
		return
	var n: int = res.potions
	if n > 0:
		Game.items["potion"] = n
	else:
		Game.items.erase("potion")


## 경험치 줄: 동료 이름 · +경험치 · 레벨 업
func _xp_rows(xp: Array) -> void:
	if xp.is_empty():
		return
	side.add_child(Kit.cap("경험치"))
	for r in xp:
		var h := Kit.hbox(10)
		h.add_child(Kit.bold(r[0], 15))
		h.add_child(Kit.num("+%d" % r[1], 15, Kit.DIM))
		if r[2] > 0:
			h.add_child(Kit.chip("레벨 업 · Lv %d" % r[3], Color(Kit.BLUE, 0.5), Color.WHITE, 12))
		side.add_child(h)


# ── 주말 소식 → 결전 ───────────────────────────────

func _week_news() -> Array:
	var out: Array = []
	for qid in Defs.WEEK_QUESTS_BY.get(Game.week, []):
		var q: Dictionary = Defs.QUESTS[qid]
		if not qid in Game.picks:
			out.append(["miss", q.name, q.skip.news])
			Game.flags[q.skip.flag] = true
		else:
			var ok: bool = Game.results.get(qid, "") == "ok"
			out.append(["ok" if ok else "half", q.name, "의뢰를 마쳤다." if ok else "절반만 이뤘다."])
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
	if Game.bond_seen.get("martha", 0) >= 3:
		luck += 1
		notes.append("마르타가 싸 준 결전 도시락 · 행운 주사위 +1")
	if Game.flags.get("redbeard_note", false):
		luck += 1
		notes.append("서고에서 찾은 쪽지로 습격을 미리 알았다 · 행운 주사위 +1")
	var lunch := 0
	if Game.flags.get("farm_saved", false):
		lunch = 4
		notes.append("토비아스가 보낸 마을 곡식 · 동료 체력 +4")
	if Game.flags.get("hideout_hit", false):
		boss -= 10
		notes.append("소굴을 털려 기가 꺾인 붉은 수염 · 보스 체력 -10")
	var ambush: bool = Game.flags.get("raid_plan", false)
	if ambush:
		notes.append("습격 길을 미리 알고 매복했다 · 적은 첫 차례에 움직이지 못한다")
	return {"luck": mini(luck, Game.LUCK_MAX), "boss_hp": boss, "lunch": lunch, "ambush": ambush, "notes": notes}


func _show_news() -> void:
	_clear()
	bg.texture = Game.tex("backgrounds/scene/bg_guildhall_camp_night.png")
	bg.modulate = Color(0.7, 0.68, 0.68)
	Kit.shade(screen, "b", 0.8, 0.5)
	screen.add_child(Desk.resource_bar())
	var v := _center_card(820)
	v.add_child(Kit.cap("장부 %d쪽 · 마감" % Game.week))
	v.add_child(Kit.title("그간의 소식", 34))
	v.add_child(Kit.spacer(0, 4))
	var lines := _week_news()
	if lines.is_empty():
		lines = [["quiet", "조용한 나날", "위탁 의뢰를 맡은 모험가들만 바삐 오갔다."]]
	# 마르타 2단계(그때 그 국자): 선술집 소문 한 줄 (다음 주 의뢰 힌트)
	var rumors: Array = G.RUMORS.get(Game.week + 1, [])
	if Game.bond_seen.get("martha", 0) >= 2 and not rumors.is_empty():
		lines.append(["rumor", "선술집 소문", rumors[0]])
	Game.news = lines.duplicate()
	for it in lines:
		v.add_child(Kit.hr())
		v.add_child(town.news_row(it))
	v.add_child(Kit.hr())
	if Game.week < Defs.FINALE_WEEK:
		v.add_child(Kit.spacer(0, 6))
		v.add_child(Kit.label("다음 쪽에도 의뢰는 들어온다. 스카우트실에 새 지원자가 찾아온다.", 14, Kit.DIM, null, true))
		v.add_child(Kit.spacer(0, 6))
		v.add_child(Kit.btn_main("다음 장부로", "장부 %d쪽" % (Game.week + 1), func():
			Game.week += 1
			Game.picks = []
			Game.new_week()
			town.show_town(), 58))
		return
	var m := _finale_mods()
	v.add_child(Kit.spacer(0, 10))
	v.add_child(Kit.cap("결전 준비", Kit.BAD))
	if m.notes.is_empty():
		v.add_child(Kit.label("특별한 도움은 없다.", 15, Kit.DIM))
	for s in m.notes:
		var h := Kit.hbox(10)
		h.add_child(Kit.Diamond.make(Kit.px(6), Kit.BRASS))
		var l := Kit.label(s, 15, Color("e3e6ec"), null, true)
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		h.add_child(l)
		v.add_child(h)
	var due := Game.debt_due()
	if due > 0:
		var dh := Kit.hbox(10)
		var dl := Kit.label("금저울 상회 빚: 이번 장 몫 %d 금화가 남았다. 결전 전에 못 갚으면 다음 장에 무보수 추심 의뢰가 붙는다." % due, 14, Color("ffd28a"), null, true)
		dl.size_flags_horizontal = SIZE_EXPAND_FILL
		dh.add_child(dl)
		var db := Kit.btn_sub("몫 다 갚기", "res_gold", func():
			Game.pay_debt(due)
			_show_news(), 40, 130)
		db.disabled = Game.gold < due
		dh.add_child(db)
		v.add_child(dh)
	v.add_child(Kit.spacer(0, 8))
	v.add_child(Kit.btn_main("결전", "붉은 수염의 습격", func():
		_play("finale_in", func(_s, _k): _go_finale()), 58))


## 가운데 카드 (내용만큼 높아진다)
func _center_card(w: float) -> VBoxContainer:
	var c := Kit.card(20, 28)
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.offset_left = -Kit.px(w / 2.0)
	c.offset_right = Kit.px(w / 2.0)
	c.grow_vertical = GROW_DIRECTION_BOTH
	screen.add_child(c)
	var v := Kit.vbox(10)
	c.add_child(v)
	desk._slide_in(c, Vector2(0, Kit.px(20)))
	return v


func _go_finale() -> void:
	Game.stage = "finale"
	var m := _finale_mods()
	Game.battle_req = {"idx": Defs.FINALE_BATTLE, "party": Game.party.duplicate(), "luck": m.luck, "boss_hp": m.boss_hp, "lunch": m.lunch, "ambush": m.ambush}
	get_tree().change_scene_to_file("res://fk.tscn")


func _finale_result(res: Dictionary) -> void:
	_sync_potions(res)
	if res.result == "win":
		# 이번 장 상회 빚 몫을 못 갚았으면 다음 장에 추심 의뢰
		if Game.debt_due() > 0:
			Game.flags["collect_ch2"] = true
		var fr: Dictionary = G.FINALE_REWARD[Game.chapter()]
		Game.earn(fr.gold, fr.mats, fr.fame, "결전 승리")
		Game.flags["chapter1_done"] = true
		for k in Game.party:
			Game.add_bond(k, G.CB_FINALE)
		Game.quest_xp(PDefs.XP_FINALE)
		_play("finale_ok", func(_s, _k): _show_end())
		return
	_clear()
	bg.texture = Game.tex("backgrounds/scene/bg_guildhall_ruined.png")
	bg.modulate = Color(0.45, 0.42, 0.44)
	Kit.shade(screen, "b", 0.8, 0.5)
	var v := _center_card(620)
	v.add_child(Kit.cap("결전 · 패배", Kit.BAD))
	v.add_child(Kit.title("길드가 무너질 위기다", 34))
	v.add_child(Kit.label("붉은 수염 일당이 길드 하우스 문턱까지 밀고 들어왔다. 다시 맞서면 처음부터 싸운다.", 15, Kit.DIM, null, true))
	v.add_child(Kit.spacer(0, 8))
	var h := Kit.hbox(10)
	h.add_child(Kit.btn_sub("처음으로", "i_back", _show_title, 58, 170))
	var again := Kit.btn_main("다시 맞선다", "결전", _go_finale, 58)
	again.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(again)
	v.add_child(h)


func _show_end() -> void:
	_clear()
	Game.stage = "end"
	bg.texture = Game.tex("backgrounds/scene/bg_room_archive.png")
	bg.modulate = Color(0.55, 0.52, 0.5)
	Kit.shade(screen, "b", 0.8, 0.5)
	var c := _book_card()
	c.head.add_child(Kit.cap("1장 체험판 끝"))
	c.head.add_child(Kit.title("단장이 쓴 연대기", 36))
	_chronicle(c.list)
	var close := Kit.label("하웰 모험가 길드의 간판이 다시 걸렸다. 다음 이야기는 2장에서.", 16, Kit.BRASS_HI, null, true)
	c.list.add_child(Kit.spacer(0, 8))
	c.list.add_child(close)
	c.foot.add_child(Kit.btn_main("처음으로", "제목 화면", _show_title, 58))


## 연대기 책 카드: 머리 + 스크롤 목록 + 아래 버튼 자리. {v, list}
func _book_card() -> Dictionary:
	var c := Kit.card(20, 30)
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_bottom = 1.0
	c.offset_left = -Kit.px(430)
	c.offset_right = Kit.px(430)
	c.offset_top = Kit.px(96)
	c.offset_bottom = -Kit.px(40)
	screen.add_child(c)
	var v := Kit.vbox(14)
	c.add_child(v)
	var head := Kit.vbox(2)
	v.add_child(head)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = SIZE_EXPAND_FILL
	var list := Kit.vbox(8)
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	sc.add_child(list)
	v.add_child(sc)
	var foot := Kit.vbox(0)
	v.add_child(foot)
	desk._slide_in(c, Vector2(0, Kit.px(20)))
	return {"head": head, "list": list, "foot": foot}


## 완성한 페이지들: 의뢰 이름 + 완수/실패 + 연대기 문장
func _chronicle(list: VBoxContainer) -> void:
	if Game.pages.is_empty():
		list.add_child(Kit.label("아직 완성한 페이지가 없다. 의뢰를 마치면 여기에 한 장씩 쌓인다.", 16, Kit.DIM, null, true))
		return
	for i in Game.pages.size():
		var pg: Dictionary = Game.pages[i]
		var res: String = Game.results.get(pg.quest, "")
		if i > 0:
			list.add_child(Kit.spacer(0, 6))
		list.add_child(Kit.hr())
		var h := Kit.hbox(12)
		h.add_child(Kit.num(Desk.ROMAN[i % Desk.ROMAN.size()], 16, Kit.BRASS))
		h.add_child(Kit.title(Defs.QUESTS[pg.quest].name, 24))
		if res == "ok":
			h.add_child(Kit.chip("완수", Color(Kit.GOOD, 0.2), Kit.GOOD))
		elif res == "ng":
			h.add_child(Kit.chip("실패", Color(Kit.BAD, 0.2), Kit.BAD))
		list.add_child(h)
		for ln in pg.lines:
			var row := Kit.hbox(14)
			var bar := ColorRect.new()
			bar.color = Color(Kit.BRASS, 0.45)
			bar.custom_minimum_size = Vector2(maxf(2.0, Kit.px(2)), 0)
			bar.mouse_filter = MOUSE_FILTER_IGNORE
			row.add_child(bar)
			var l := Kit.label(ln, 16, Color("e3e6ec"), null, true)
			l.size_flags_horizontal = SIZE_EXPAND_FILL
			row.add_child(l)
			list.add_child(row)


func _show_book() -> void:
	town._frame("연대기", "완성한 페이지 %d장" % Game.pages.size(), _show_hub, "backgrounds/scene/bg_room_archive.png", 0.5)
	var c := _book_card()
	c.head.add_child(Kit.cap("하웰 모험가 길드 연대기"))
	c.head.add_child(Kit.title("단장이 쓴 기록", 32))
	_chronicle(c.list)
