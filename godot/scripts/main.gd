extends Control
## 전투 그레이박스 프로토타입 화면 (docs/05-combat.md 17절 검증용)
## 실행 옵션 (-- 뒤에): --map=0..3  --party=lina,cecile,adelheid  --select  --shot=경로.png

const Battle = preload("res://scripts/battle.gd")
const Defs = preload("res://scripts/defs.gd")
const Board = preload("res://scripts/board.gd")

const MAPS := [
	{"path": "res://maps/bt_ch1_forest_ambush.txt", "name": "숲속 매복 · 5×4 (좁은 맵, 포위당한 채 시작)"},
	{"path": "res://maps/bt_ch1_forest_clearing.txt", "name": "숲속 공터 · 7×5 (기본, 기름·건초, 궁수의 나팔)"},
	{"path": "res://maps/bt_ch1_village_outskirts.txt", "name": "마을 외곽 · 9×5 (넓은 맵, 진흙길, 늑대 우두머리)"},
	{"path": "res://maps/bt_ch1_bandit_cliff.txt", "name": "도적 절벽 · 8×6 (보스: 붉은 수염)"},
]
const NO_CELL := Vector2i(-1, -1)

var battle = null
var board: Control
var state := "menu"
var sel = null
var mode := "idle"
var cur := ""
var pending := NO_CELL
var fate_pick := -1
var brand_pick := -1
var party: Array = ["lina", "cecile", "adelheid"]
var map_idx := 1
var speed := 1.0
var _msg := ""
var _shot := ""
var _demo := false
var _shot_at: Array = []
var touch := false  # 터치 기기용 배치
var icons := {}  # 스킬 id -> 아이콘 Texture2D (art/final/icons/skills)

var menu: Control
var hud: Control
var round_lbl: Label
var fate_box: HBoxContainer
var speed_btn: Button
var end_btn: Button
var info: RichTextLabel
var actions: HFlowContainer
var hint: Label
var ok_btn: Button
var cancel_btn: Button
var log_box: RichTextLabel
var over: PanelContainer
var over_lbl: RichTextLabel
var party_lbl: Label
var event_lbl: Label


func _ready() -> void:
	# 휴대폰·태블릿: 기준 화면 높이를 540 으로 줄여 글자와 버튼을 2배로 키우고, 기록창과 아래 칸을 좁힌다
	touch = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or "--touch" in OS.get_cmdline_user_args() or get_window().size.y < 700
	if touch:
		get_window().content_scale_size = Vector2i(960, 540)
	_setup_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.10, 0.09)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	_build_hud()
	_build_menu()
	_build_over()
	hud.visible = false
	var auto_start := false
	var auto_select := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			map_idx = int(a.get_slice("=", 1))
			auto_start = true
		elif a.begins_with("--party="):
			party = Array(a.get_slice("=", 1).split(",", false))
		elif a.begins_with("--shot="):
			_shot = a.get_slice("=", 1)
		elif a == "--select":
			auto_select = true
		elif a == "--demo":
			_demo = true
		elif a.begins_with("--at="):
			_shot_at = Array(a.get_slice("=", 1).split(",", false)).map(func(x): return float(x))
	if auto_start:
		_start()
		if auto_select:
			sel = battle.side_units("ally")[0]
			_refresh()
	if _demo and battle != null:
		_run_demo()
	if _shot != "":
		_take_shot()


func _take_shot() -> void:
	if _shot_at.is_empty():
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_png(_shot)
	else:
		var t0 := 0.0
		for i in _shot_at.size():
			await get_tree().create_timer(_shot_at[i] - t0).timeout
			t0 = _shot_at[i]
			get_viewport().get_texture().get_image().save_png(_shot.replace(".png", "_%d.png" % i))
	get_tree().quit()


## 확인용: 아군도 자동으로 움직여 전투 한 판을 끝까지 돌린다. 첫 턴에 세실은 궁극기를 쓴다 (컷인, 동작 연출 확인)
func _run_demo() -> void:
	await get_tree().create_timer(0.5).timeout
	var first := true
	while battle != null and battle.result == "":
		for a in battle.side_units("ally"):
			if battle.result != "":
				break
			if first and a.key == "cecile":
				a.resolve = 100
				battle.use_skill(a, a.ult, a.pos)
			else:
				battle.auto_act(a)
			_flush()
			_refresh()
			await _wait_board()
		first = false
		if battle.result != "":
			break
		await _end_turn()
		await _wait_board()
	_check_over()
	print("demo result: %s, rounds %d, downs %d" % [battle.result, battle.round_no, battle.downs])


func _setup_theme() -> void:
	var th := Theme.new()
	# 웹에는 시스템 글꼴이 없어서 함께 넣은 Noto Sans KR 을 먼저 쓴다 (tools/web/prepare_web.py)
	if ResourceLoader.exists("res://fonts/NotoSansKR-Game.ttf"):
		th.default_font = load("res://fonts/NotoSansKR-Game.ttf")
	else:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "Noto Sans CJK KR", "Noto Sans KR", "Apple SD Gothic Neo", "sans-serif"])
		th.default_font = f
	th.default_font_size = 18 if touch else 22
	theme = th


func _place(c: Control, al: float, at: float, ar: float, ab: float, l: float, t: float, r: float, b: float) -> void:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44 if touch else 52)
	b.focus_mode = FOCUS_NONE
	b.pressed.connect(cb)
	return b


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.15, 0.13)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	return sb


# ── 화면 만들기 ─────────────────────────────────────

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(PRESET_FULL_RECT)
	add_child(hud)

	var top := HBoxContainer.new()
	_place(top, 0, 0, 1, 0, 16, 8, -16, 64)
	top.add_theme_constant_override("separation", 12)
	hud.add_child(top)
	round_lbl = Label.new()
	round_lbl.add_theme_font_size_override("font_size", 28)
	round_lbl.custom_minimum_size.x = 160
	top.add_child(round_lbl)
	var fl := Label.new()
	fl.text = "운명"
	top.add_child(fl)
	fate_box = HBoxContainer.new()
	top.add_child(fate_box)
	event_lbl = Label.new()
	event_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	event_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
	event_lbl.add_theme_font_size_override("font_size", 20)
	top.add_child(event_lbl)
	speed_btn = _btn("1배속", _toggle_speed)
	top.add_child(speed_btn)
	end_btn = _btn("  턴 종료  ", _end_turn)
	top.add_child(end_btn)
	top.add_child(_btn("처음으로", _to_menu))

	board = Board.new()
	board.clip_contents = true
	var log_w := 230 if touch else 440
	var bot_h := 150 if touch else 228
	_place(board, 0, 0, 1, 1, 8 if touch else 16, 64 if touch else 72, -(log_w + 16), -(bot_h + 8))
	board.cell_clicked.connect(_on_cell)
	hud.add_child(board)

	log_box = RichTextLabel.new()
	_place(log_box, 1, 0, 1, 1, -log_w, 64 if touch else 72, -8 if touch else -16, -(bot_h + 8))
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size", 13 if touch else 17)
	log_box.add_theme_stylebox_override("normal", _panel_style())
	hud.add_child(log_box)

	var bottom := VBoxContainer.new()
	_place(bottom, 0, 1, 1, 1, 8 if touch else 16, -bot_h, -8 if touch else -16, -4)
	hud.add_child(bottom)
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.fit_content = true
	info.custom_minimum_size.y = 0 if touch else 62
	info.add_theme_font_size_override("normal_font_size", 15 if touch else 20)
	info.add_theme_font_size_override("bold_font_size", 17 if touch else 22)
	bottom.add_child(info)
	actions = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	bottom.add_child(actions)
	var row := HBoxContainer.new()
	bottom.add_child(row)
	hint = Label.new()
	hint.size_flags_horizontal = SIZE_EXPAND_FILL
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	row.add_child(hint)
	ok_btn = _btn("  실행  ", _confirm)
	row.add_child(ok_btn)
	cancel_btn = _btn("  취소  ", _cancel)
	row.add_child(cancel_btn)


func _build_menu() -> void:
	menu = CenterContainer.new()
	menu.set_anchors_preset(PRESET_FULL_RECT)
	add_child(menu)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	menu.add_child(v)
	var t := Label.new()
	t.text = "Project D20 · 전투 그레이박스"
	t.add_theme_font_size_override("font_size", 40)
	v.add_child(t)
	party_lbl = Label.new()
	v.add_child(party_lbl)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 18)
	v.add_child(ph)
	for k in Defs.ALLIES.keys():
		var d: Dictionary = Defs.ALLIES[k]
		var cb := CheckBox.new()
		cb.text = "%s (%s)" % [d.name, d.role]
		cb.button_pressed = k in party
		cb.focus_mode = FOCUS_NONE
		cb.toggled.connect(_on_party.bind(k))
		ph.add_child(cb)
	for i in MAPS.size():
		var b := _btn(MAPS[i].name, _pick_map.bind(i))
		b.custom_minimum_size = Vector2(640, 64)
		v.add_child(b)
	var note := Label.new()
	note.text = "네모 박스 그레이박스입니다. 수치와 규칙은 docs/05-combat.md 기준"
	note.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	v.add_child(note)
	_update_party_lbl()


func _build_over() -> void:
	over = PanelContainer.new()
	_place(over, 0.5, 0.5, 0.5, 0.5, -300, -190, 300, 190)
	over.add_theme_stylebox_override("panel", _panel_style())
	add_child(over)
	var v := VBoxContainer.new()
	over.add_child(v)
	over_lbl = RichTextLabel.new()
	over_lbl.bbcode_enabled = true
	over_lbl.fit_content = true
	over_lbl.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(over_lbl)
	var h := HBoxContainer.new()
	v.add_child(h)
	h.add_child(_btn("  다시 하기  ", _start))
	h.add_child(_btn("  처음으로  ", _to_menu))
	over.visible = false


# ── 흐름 ────────────────────────────────────────────

func _on_party(on: bool, key: String) -> void:
	if on and not key in party:
		party.append(key)
	elif not on:
		party.erase(key)
	_update_party_lbl()


func _update_party_lbl() -> void:
	var names: Array = []
	for k in party:
		names.append(Defs.ALLIES[k].name)
	party_lbl.text = "파티 %d/3: %s   (3명을 고르고 맵을 누르면 시작)" % [party.size(), ", ".join(PackedStringArray(names))]
	party_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6) if party.size() == 3 else Color(1.0, 0.6, 0.5))


func _pick_map(i: int) -> void:
	if party.size() != 3:
		return
	map_idx = i
	_start()


func _start() -> void:
	battle = Battle.new()
	battle.setup(MAPS[map_idx].path, party)
	board.battle = battle
	board.reset()
	_load_sprites()
	log_box.clear()
	menu.visible = false
	over.visible = false
	hud.visible = true
	sel = null
	_reset_mode()
	battle.begin_ally_turn()
	state = "player"
	_flush()
	sel = battle.side_units("ally")[0] if not battle.side_units("ally").is_empty() else null
	_refresh()


## 그림을 찾는다: 웹 빌드는 godot/art (tools/web/prepare_web.py 가 복사), PC 실행은 저장소의 art/final 을 직접 읽는다.
## 없으면 동그라미로 그린다
func _load_sprites() -> void:
	board.sprites.clear()
	board.cutins.clear()
	icons.clear()
	board.bg_tex = null
	var map_id: String = battle.title.get_slice(" ", 0)
	if battle.bg_grid.z > 0:
		board.bg_tex = _tex("backgrounds/battle/%s.png" % map_id)
	for u in battle.units:
		if u.side != "ally":
			continue
		var folder: String = Defs.ALLIES[u.key].get("art", "")
		if folder == "":
			continue
		var pre := folder.get_slice("_", 0)
		var frames := {}
		for pose in ["idle", "attack", "skill", "hit", "down"]:
			var t := _tex("characters/%s/%s_sd_%s.png" % [folder, pre, pose])
			if t != null:
				frames[pose] = t
		if frames.has("idle"):
			board.sprites[u.uid] = frames
		var ct := _tex("characters/%s/%s_cutin.png" % [folder, pre])
		if ct != null:
			board.cutins[u.uid] = ct
		var acts: Array = Defs.ALLIES[u.key].actions
		for pair in [[acts[1], "skill1"], [acts[2], "skill2"], [Defs.ALLIES[u.key].ult, "ult"]]:
			var it := _tex("icons/skills/%s_icon_%s.png" % [pre, pair[1]])
			if it != null:
				icons[pair[0]] = it


## rel: art/final 아래 경로
func _tex(rel: String) -> Texture2D:
	var res := "res://art/" + rel
	if ResourceLoader.exists(res):
		return load(res)
	var path := ProjectSettings.globalize_path("res://").path_join("../art/final/" + rel)
	if OS.has_feature("web") or not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if img != null else null


func _to_menu() -> void:
	state = "menu"
	battle = null
	board.battle = null
	hud.visible = false
	over.visible = false
	menu.visible = true


func _flush() -> void:
	if battle == null:
		return
	for ev in battle.events:
		match ev.t:
			"log":
				log_box.add_text(ev.text + "\n")
			_:
				board.push(ev)
	battle.events.clear()


func _reset_mode() -> void:
	mode = "idle"
	cur = ""
	pending = NO_CELL
	fate_pick = -1
	brand_pick = -1


func _targets() -> Array:
	match cur:
		"help":
			return battle.help_targets(sel)
		"swap":
			return battle.swap_targets(sel)
	return battle.skill_targets(sel, cur)


func _on_cell(cell: Vector2i) -> void:
	if state != "player":
		return
	if mode == "brand":
		var e = battle.unit_at(cell)
		if e != null and e.side == "enemy" and e.alive():
			battle.place_brand(brand_pick, e)
			_flush()
		_reset_mode()
		_refresh()
		return
	if mode == "target":
		if cell in _targets():
			if pending == cell:
				_confirm()
			else:
				pending = cell
				_refresh()
			return
		_reset_mode()
	var u = battle.unit_at(cell)
	if u != null and u.side == "ally" and not u.downed:
		sel = u
		_refresh()
		return
	if sel != null and sel.side == "ally" and cell in board.move_cells:
		battle.move_ally(sel, cell)
		_flush()
		_refresh()
		_check_over()
		return
	if u != null:
		sel = u
	_refresh()


func _pick_action(sid: String) -> void:
	if state != "player" or sel == null:
		return
	_reset_mode()
	cur = sid
	mode = "target"
	var tg := _targets()
	if tg.size() == 1 or (Defs.SKILLS.has(sid) and Defs.SKILLS[sid].target == "self"):
		pending = tg[0] if not tg.is_empty() else NO_CELL
	_refresh()


func _confirm() -> void:
	if state != "player" or mode != "target" or pending == NO_CELL or sel == null:
		return
	match cur:
		"help":
			battle.help_up(sel, pending)
		"swap":
			battle.swap(sel, pending)
		_:
			battle.use_skill(sel, cur, pending, fate_pick)
	_reset_mode()
	_flush()
	_refresh()
	_check_over()


func _cancel() -> void:
	_reset_mode()
	_refresh()


func _on_fate(i: int) -> void:
	if state != "player":
		return
	if mode == "target" and Defs.SKILLS.get(cur, {}).get("attack", false):
		fate_pick = -1 if fate_pick == i else i
		_refresh()
		return
	if battle.brand_used:
		_msg = "운명 낙인은 턴마다 한 번만 찍을 수 있습니다"
		_refresh()
		return
	var again := mode == "brand" and brand_pick == i
	_reset_mode()
	if not again:
		mode = "brand"
		brand_pick = i
	_refresh()


func _guard() -> void:
	battle.guard(sel)
	_flush()
	_refresh()


func _undo() -> void:
	battle.undo_move(sel)
	_flush()
	_refresh()


func _wait() -> void:
	sel.acted = true
	sel.move_left = 0
	for a in battle.side_units("ally"):
		if not a.acted:
			sel = a
			break
	_reset_mode()
	_refresh()


func _toggle_speed() -> void:
	speed = 2.0 if speed == 1.0 else 1.0
	board.speed = speed
	speed_btn.text = "%d배속" % int(speed)


func _end_turn() -> void:
	if state != "player":
		return
	var b = battle
	state = "enemy"
	_reset_mode()
	sel = null
	b.end_ally_turn()
	b.begin_enemy_turn()
	_flush()
	_refresh()
	for e in b.side_units("enemy"):
		if battle != b or b.result != "":
			break
		await _wait_board()
		if battle != b:
			return
		b.enemy_act(e)
		_flush()
		_refresh()
		await get_tree().create_timer(0.35 / speed).timeout
	if battle != b:
		return
	await _wait_board()
	b.end_enemy_turn()
	b.end_round()
	if b.result == "":
		b.begin_ally_turn()
	_flush()
	state = "player"
	var allies: Array = b.side_units("ally")
	sel = allies[0] if not allies.is_empty() else null
	_refresh()
	_check_over()


func _wait_board() -> void:
	while board.busy():
		await get_tree().process_frame


func _check_over() -> void:
	if battle == null or battle.result == "":
		return
	state = "over"
	var win: bool = battle.result == "win"
	var t := "[font_size=40][b]%s[/b][/font_size]\n" % ("승리!" if win else "패배")
	t += "%d라운드 · 쓰러진 횟수 %d\n\n" % [battle.round_no, battle.downs]
	var hidden := 0
	for lg in battle.legends:
		if lg["done"]:
			t += "[color=#ffd966]【전설 장면】 %s[/color]\n" % lg["text"]
		else:
			hidden += 1
	if hidden > 0:
		t += "[color=#aaaaaa]아직 남지 않은 장면 %d개 · 소문: %s[/color]\n" % [hidden, battle.rumor]
	over_lbl.text = t
	over.visible = true
	_refresh()


# ── 표시 갱신 ───────────────────────────────────────

func _refresh() -> void:
	if battle == null:
		return
	round_lbl.text = "라운드 %d" % battle.round_no
	event_lbl.text = battle.upcoming_text()
	for c in fate_box.get_children():
		c.queue_free()
	for i in battle.fate.size():
		var v: int = battle.fate[i]
		var b := _btn("[%d]" % v, _on_fate.bind(i))
		b.custom_minimum_size = Vector2(72, 52)
		if i == fate_pick or i == brand_pick:
			b.modulate = Color(1.0, 0.9, 0.35)
		elif v >= 15:
			b.modulate = Color(0.7, 1.0, 0.7)
		elif v <= 6:
			b.modulate = Color(1.0, 0.7, 1.0)
		fate_box.add_child(b)
	if battle.fate.is_empty():
		var l := Label.new()
		l.text = "없음"
		fate_box.add_child(l)
	end_btn.disabled = state != "player"
	if sel != null and sel.removed:
		sel = null

	board.move_cells = []
	board.warn_cells = []
	board.target_cells = []
	board.area_cells = []
	board.pending = pending
	board.selected_uid = sel.uid if sel != null else -1
	board.dim_acted = state == "player"
	if state == "player" and sel != null and sel.side == "ally" and not sel.downed:
		if mode == "target":
			board.target_cells = _targets()
			if pending != NO_CELL and Defs.SKILLS.has(cur):
				board.area_cells = battle.area_of(cur, sel, pending)
		elif mode == "idle":
			var mt: Array = battle.move_targets(sel)
			board.move_cells = mt
			board.warn_cells = mt.filter(func(c): return battle.provokes(sel, c))
	if mode == "brand":
		for e in battle.side_units("enemy"):
			board.target_cells.append(e.pos)
	_build_actions()
	_update_info()
	_update_hint()


func _build_actions() -> void:
	for c in actions.get_children():
		c.queue_free()
	if state != "player" or sel == null or sel.side != "ally" or sel.downed:
		return
	var busy: bool = sel.acted
	for sid in sel.actions + [sel.ult]:
		var s: Dictionary = Defs.SKILLS[sid]
		var label: String = s.name
		var dis := busy
		if sid == sel.ult:
			label = "궁극기: %s (%d%%)" % [s.name, sel.resolve]
			dis = dis or sel.resolve < 100
		else:
			var cdv: int = sel.cooldowns.get(sid, 0)
			if cdv > 0:
				label += " (대기 %d)" % cdv
				dis = true
		var b := _btn("  %s  " % label, _pick_action.bind(sid))
		b.disabled = dis
		if icons.has(sid):
			b.icon = icons[sid]
			b.add_theme_constant_override("icon_max_width", 44)
		b.tooltip_text = s.desc
		if sid == cur:
			b.modulate = Color(1.0, 0.9, 0.4)
		actions.add_child(b)
	var g := _btn("  방어  ", _guard)
	g.disabled = busy
	actions.add_child(g)
	if not battle.help_targets(sel).is_empty():
		var hb := _btn("  일으키기  ", _pick_action.bind("help"))
		hb.disabled = busy
		actions.add_child(hb)
	if "guide" in sel.traits:
		var sw := _btn("  자리 바꾸기  ", _pick_action.bind("swap"))
		sw.disabled = battle.swap_targets(sel).is_empty()
		actions.add_child(sw)
	if battle.can_undo(sel):
		actions.add_child(_btn("  이동 되돌리기  ", _undo))
	var w := _btn("  행동 끝  ", _wait)
	w.disabled = sel.acted and sel.move_left == 0
	actions.add_child(w)


func _update_info() -> void:
	if sel == null:
		info.text = "[color=#aaaaaa]아군을 눌러 선택하세요. 적을 누르면 정보가 보입니다.[/color]"
		return
	var u = sel
	var t := "[b]%s[/b]" % u.name
	if u.role != "":
		t += " (%s)" % u.role
	t += "   HP %d/%d   방어 %d   이동 %d" % [u.hp, u.max_hp, battle.eff_ac(u), u.move]
	if u.side == "ally":
		t += " (남은 %d)   결의 %d/100" % [u.move_left, u.resolve]
	else:
		t += "   명중 +%d   피해 %s   사거리 %d" % [u.atk, u.dmg, u.atk_range]
	if u.brand > 0:
		t += "   [color=#d9a0ff]낙인 %d[/color]" % u.brand
	var sts: Array = battle.status_names(u)
	if u.downed:
		sts = ["쓰러짐 (옆 아군이 일으키기 가능)"]
	if not sts.is_empty():
		t += "\n상태: " + ", ".join(PackedStringArray(sts))
	var trs: Array = []
	for tr in u.traits:
		trs.append(Defs.TRAITS.get(tr, tr))
	if not trs.is_empty():
		t += "\n[color=#bbbbbb]" + " · ".join(PackedStringArray(trs)) + "[/color]"
	info.text = t


func _update_hint() -> void:
	var h := ""
	if state == "enemy":
		h = "적의 턴…"
	elif state == "over":
		h = ""
	elif mode == "brand":
		h = "운명 낙인: 적을 누르면 그 적의 다음 d20이 %d로 정해집니다 (턴당 1회, 행동 소모 없음)" % battle.fate[brand_pick]
	elif mode == "target":
		if pending == NO_CELL:
			h = "빨간 칸에서 대상을 고르세요."
			if Defs.SKILLS.get(cur, {}).get("attack", false):
				h += " 위쪽 운명 주사위를 누르면 굴리는 대신 그 눈을 씁니다."
		else:
			var fv: int = battle.fate[fate_pick] if fate_pick >= 0 else 0
			h = battle.preview_text(sel, cur, pending, fv) + "   → 한 번 더 누르거나 [실행]"
	elif sel != null and sel.side == "ally" and not sel.downed:
		h = "파란 칸: 이동 (주황 테두리 = 빈틈 공격 받음) · 아래에서 행동 선택 · 운명 주사위를 그냥 누르면 적에게 낙인"
	else:
		h = "아군을 누르세요"
	if _msg != "":
		h = _msg
		_msg = ""
	hint.text = h
	ok_btn.disabled = not (mode == "target" and pending != NO_CELL)
	cancel_btn.disabled = mode == "idle"
