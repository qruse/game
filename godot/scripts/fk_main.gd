extends Control
## 포 더 킹식 전투 시험판 화면.
## 실행 옵션 (-- 뒤에): --battle=0|1  --party=lina,cecile,adelheid  --demo  --shot=경로.png  --at=초,초,…  --touch

signal acted

const Battle = preload("res://scripts/fk_battle.gd")
const Defs = preload("res://scripts/fk_defs.gd")
const Stage = preload("res://scripts/fk_stage.gd")
const UI = preload("res://scripts/fk_ui.gd")

## 적 그림이 아직 없어서, 동료 SD 를 어둡게 칠해 자리만 잡는다
const ENEMY_SIL := {"bandit": "C01_lina", "archer": "C03_adelheid", "wolf": "C02_cecile", "redbeard": "C01_lina"}
## 적 그림 폴더 (art/final/enemies/<ID>). 그림은 왼쪽을 보고 있다
const ENEMY_ART := {"bandit": "E01", "archer": "E02", "wolf": "E03", "redbeard": "B01"}

var battle = null
var stage: Control
var state := "menu"  # menu / wait / player / over
var actor = null
var aim_enemy := -1  # 무대에서 고른 적 (공격 대상)
var aim_ally := -1  # 고른 동료 (치유·축복 대상)
var aim_obj := -1  # 고른 오브젝트 (불꽃 화살로 불붙이기)
var locks := 0  # 다음 행동에 쓸 운명 주사위 개수
var party: Array = ["lina", "cecile", "adelheid"]
var battle_idx := 0
var speed := 1.0
var touch := false
var icons := {}
var portraits := {}
var _demo := false
var _shot := ""
var _shot_at: Array = []
var _pick := ""  # 확인용: 첫 동료 차례에 미리 고를 대상 (행동,대상번호 예: adel_fire,4)

var menu: Control
var hud: Control
var round_lbl: Label
var turnbar: Control
var event_lbl: Label
var speed_btn: Button
var log_btn: Button
var card_pic: TextureRect
var card_bars: Control
var actions: HFlowContainer
var hint: RichTextLabel
var fate_row: HBoxContainer
var bold_font: FontVariation
var st_icons := {}
var log_box: RichTextLabel
var over: PanelContainer
var over_lbl: RichTextLabel
var party_lbl: Label


func _ready() -> void:
	touch = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or "--touch" in OS.get_cmdline_user_args() or get_window().size.y < 700
	if touch:
		get_window().content_scale_size = Vector2i(960, 540)
	_setup_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.07)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	_build_hud()
	_build_menu()
	_build_over()
	hud.visible = false
	var auto_start := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--battle="):
			battle_idx = int(a.get_slice("=", 1))
			auto_start = true
		elif a.begins_with("--party="):
			party = Array(a.get_slice("=", 1).split(",", false))
		elif a.begins_with("--shot="):
			_shot = a.get_slice("=", 1)
		elif a == "--demo":
			_demo = true
			auto_start = true
		elif a.begins_with("--pick="):
			_pick = a.get_slice("=", 1)
		elif a.begins_with("--at="):
			_shot_at = Array(a.get_slice("=", 1).split(",", false)).map(func(x): return float(x))
	if auto_start:
		_start()
	if _shot != "":
		_take_shot()


func _take_shot() -> void:
	if _shot_at.is_empty():
		_shot_at = [1.5]
	var t0 := 0.0
	for i in _shot_at.size():
		await get_tree().create_timer(_shot_at[i] - t0).timeout
		t0 = _shot_at[i]
		var path := _shot if _shot_at.size() == 1 else _shot.replace(".png", "_%d.png" % i)
		get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


func _setup_theme() -> void:
	var th := Theme.new()
	var base: Font
	if ResourceLoader.exists("res://fonts/NotoSansKR-Game.ttf"):
		base = load("res://fonts/NotoSansKR-Game.ttf")
	else:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "Noto Sans CJK KR", "Noto Sans KR", "Apple SD Gothic Neo", "sans-serif"])
		base = f
	# 기본 글꼴은 조금 굵게 (가변 글꼴 기본 굵기는 작은 글자에서 흐리다)
	var mid := FontVariation.new()
	mid.base_font = base
	mid.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 520}
	th.default_font = mid
	th.default_font_size = 16 if touch else 22
	# 굵은 글꼴: 가변 글꼴의 굵기 축을 700으로
	bold_font = FontVariation.new()
	bold_font.base_font = base
	bold_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	# 버튼과 판넬은 tools/ui 로 그린 틀
	var m := 9.0 if touch else 12.0
	for st in [["normal", "btn_normal"], ["hover", "btn_hover"], ["pressed", "btn_pressed"], ["disabled", "btn_disabled"]]:
		th.set_stylebox(st[0], "Button", UI.sbt(st[1], 18, m))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", UI.CREAM)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", UI.GOLD)
	th.set_color("font_disabled_color", "Button", Color(0.5, 0.46, 0.42))
	th.set_font("font", "Button", bold_font)
	th.set_stylebox("panel", "PanelContainer", UI.sbt("panel", 30, 12.0 if touch else 18.0))
	th.set_stylebox("panel", "Panel", UI.sbt("panel", 30, 12))
	th.set_color("font_color", "Label", UI.CREAM)
	th.set_color("default_color", "RichTextLabel", UI.CREAM)
	th.set_font("bold_font", "RichTextLabel", bold_font)
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
	b.custom_minimum_size = Vector2(0, 40 if touch else 52)
	b.focus_mode = FOCUS_NONE
	b.pressed.connect(cb)
	return b


## 작은 버튼 (위 오른쪽 메뉴용)
func _small_btn(text: String, cb: Callable) -> Button:
	var b := _btn(text, cb)
	b.custom_minimum_size = Vector2(0, 34 if touch else 44)
	b.add_theme_font_size_override("font_size", 13 if touch else 18)
	return b


func _panel_style(_a := 1.0) -> StyleBox:
	return UI.sbt("panel", 30, 10.0 if touch else 16.0)


func _outlined(l: Label, size: int, col: Color) -> void:
	l.add_theme_font_override("font", bold_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)


# ── 화면 만들기 ─────────────────────────────────────
# 무대가 화면 전체를 쓰고, 그 위에 차례 줄·라운드 표시·메뉴·아래 판넬을 띄운다

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(PRESET_FULL_RECT)
	add_child(hud)
	var bot_h := 150 if touch else 236
	var card_w := 170 if touch else 300
	var lift := 34 if touch else 70  # 초상 카드가 판넬 위로 올라오는 높이

	stage = Stage.new()
	stage.clip_contents = true
	_place(stage, 0, 0, 1, 1, 0, 0, 0, -bot_h + 8)
	stage.picked.connect(_on_pick)
	hud.add_child(stage)

	# 왼쪽 위: 라운드와 다가오는 사건
	var tl := VBoxContainer.new()
	_place(tl, 0, 0, 0, 0, 12, 8, 520, 90)
	tl.add_theme_constant_override("separation", 0)
	hud.add_child(tl)
	round_lbl = Label.new()
	_outlined(round_lbl, 22 if touch else 34, UI.GOLD)
	tl.add_child(round_lbl)
	event_lbl = Label.new()
	_outlined(event_lbl, 12 if touch else 18, Color(1.0, 0.62, 0.35))
	event_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_lbl.custom_minimum_size.x = 300 if touch else 480
	tl.add_child(event_lbl)

	# 가운데 위: 차례 줄
	turnbar = UI.TurnBar.new()
	turnbar.font = bold_font
	_place(turnbar, 0.5, 0, 0.5, 0, -260 if touch else -460, 4, 260 if touch else 460, 62 if touch else 100)
	turnbar.mouse_filter = MOUSE_FILTER_IGNORE
	hud.add_child(turnbar)

	# 오른쪽 위: 메뉴
	var tr := HBoxContainer.new()
	_place(tr, 1, 0, 1, 0, -(250 if touch else 380), 8, -10, 52 if touch else 60)
	tr.alignment = BoxContainer.ALIGNMENT_END
	tr.add_theme_constant_override("separation", 6)
	hud.add_child(tr)
	speed_btn = _small_btn(" ▶ 1배속 ", _toggle_speed)
	tr.add_child(speed_btn)
	log_btn = _small_btn(" 기록 ", func(): log_box.visible = not log_box.visible)
	tr.add_child(log_btn)
	tr.add_child(_small_btn(" 처음으로 ", _to_menu))

	log_box = RichTextLabel.new()
	_place(log_box, 1, 0, 1, 1, -(300 if touch else 520), 60 if touch else 80, -8, -bot_h - 8)
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size", 12 if touch else 17)
	log_box.add_theme_stylebox_override("normal", _panel_style())
	log_box.visible = false
	hud.add_child(log_box)

	# 아래 판넬
	var bottom := PanelContainer.new()
	_place(bottom, 0, 1, 1, 1, card_w + 4, -bot_h, -4, -4)
	hud.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8 if touch else 16)
	bottom.add_child(row)

	# 왼쪽 아래: 차례인 동료의 초상 카드 (판넬 위로 솟는다)
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", UI.sbt("panel_light", 30, 0))
	_place(card, 0, 1, 0, 1, 4, -(bot_h + lift), card_w, -4)
	hud.add_child(card)
	card_pic = TextureRect.new()
	card_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	card_pic.clip_contents = true
	_place(card_pic, 0, 0, 1, 1, 7, 7, -7, -7)
	card.add_child(card_pic)
	card_bars = UI.CardBars.new()
	card_bars.font = theme.default_font
	card_bars.bold = bold_font
	card_bars.compact = touch
	_place(card_bars, 0, 1, 1, 1, 7, -(70 if touch else 124), -7, -7)
	card.add_child(card_bars)

	# 가운데: 행동 카드
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	actions = HFlowContainer.new()
	actions.size_flags_horizontal = SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation", 4 if touch else 8)
	actions.add_theme_constant_override("v_separation", 4 if touch else 8)
	scroll.add_child(actions)

	# 오른쪽: 대상 안내 + 운명 주사위
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 220 if touch else 420
	row.add_child(side)
	hint = RichTextLabel.new()
	hint.bbcode_enabled = true
	hint.size_flags_vertical = SIZE_EXPAND_FILL
	hint.add_theme_font_size_override("normal_font_size", 12 if touch else 20)
	hint.add_theme_font_size_override("bold_font_size", 14 if touch else 24)
	side.add_child(hint)
	var fr := HBoxContainer.new()
	fr.add_theme_constant_override("separation", 4)
	side.add_child(fr)
	var fl := Label.new()
	fl.text = "운명"
	_outlined(fl, 13 if touch else 18, Color(0.85, 0.7, 1.0))
	fr.add_child(fl)
	fate_row = HBoxContainer.new()
	fate_row.add_theme_constant_override("separation", 2)
	fr.add_child(fate_row)

func _build_menu() -> void:
	menu = CenterContainer.new()
	menu.set_anchors_preset(PRESET_FULL_RECT)
	add_child(menu)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	menu.add_child(v)
	var t := Label.new()
	t.text = "Project D20 · 전투 시험판 (판정 칸 방식)"
	t.add_theme_font_size_override("font_size", 26 if touch else 40)
	v.add_child(t)
	party_lbl = Label.new()
	v.add_child(party_lbl)
	var ph := HFlowContainer.new()
	ph.add_theme_constant_override("h_separation", 18)
	v.add_child(ph)
	for k in Defs.HEROES.keys():
		var d: Dictionary = Defs.HEROES[k]
		var cb := CheckBox.new()
		cb.text = "%s (%s)" % [d.name, d.role]
		cb.button_pressed = k in party
		cb.focus_mode = FOCUS_NONE
		cb.toggled.connect(_on_party.bind(k))
		ph.add_child(cb)
	for i in Defs.BATTLES.size():
		var b := _btn("%s · %s" % [Defs.BATTLES[i].name, Defs.BATTLES[i].desc], _pick_battle.bind(i))
		b.custom_minimum_size = Vector2(0, 52 if touch else 64)
		v.add_child(b)
	var old := _btn("이전 방식 (칸 이동 전투)", func(): get_tree().change_scene_to_file("res://main.tscn"))
	old.modulate = Color(0.75, 0.75, 0.75)
	v.add_child(old)
	var note := Label.new()
	note.text = "행동마다 판정 칸을 굴려 성공한 칸만큼 효과가 납니다. 주변 환경(항아리, 고목, 방책…)도 쓸 수 있습니다"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 600 if touch else 900
	note.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	v.add_child(note)
	_update_party_lbl()


func _build_over() -> void:
	over = PanelContainer.new()
	_place(over, 0.5, 0.5, 0.5, 0.5, -260, -150, 260, 150)
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


# ── 메뉴 ────────────────────────────────────────────

func _on_party(on: bool, key: String) -> void:
	if on and not key in party:
		party.append(key)
	elif not on:
		party.erase(key)
	_update_party_lbl()


func _update_party_lbl() -> void:
	var names: Array = party.map(func(k): return Defs.HEROES[k].name)
	party_lbl.text = "파티 %d/3: %s   (3명을 고르고 전투를 누르면 시작)" % [party.size(), ", ".join(PackedStringArray(names))]
	party_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6) if party.size() == 3 else Color(1.0, 0.6, 0.5))


func _pick_battle(i: int) -> void:
	if party.size() != 3:
		return
	battle_idx = i
	_start()


func _to_menu() -> void:
	state = "menu"
	battle = null
	stage.battle = null
	hud.visible = false
	over.visible = false
	menu.visible = true


# ── 전투 흐름 ───────────────────────────────────────

func _start() -> void:
	battle = Battle.new()
	battle.setup(battle_idx, party)
	stage.battle = battle
	stage.reset()
	_load_art()
	log_box.clear()
	menu.visible = false
	over.visible = false
	hud.visible = true

	_loop()


func _loop() -> void:
	var b = battle
	_reset_pick()
	while battle == b and b.result == "":
		var u = b.advance()
		if u == null:
			b.end_round()
			_flush()
			_refresh()
			await _wait_stage()
			continue
		state = "wait"
		actor = u
		var go: bool = b.begin_turn(u)
		_flush()
		_refresh()
		await _wait_stage()
		if battle != b:
			return
		if go and b.result == "":
			if u.side == "ally" and not _demo:
				state = "player"
				stage.inspect_uid = -1
				_reset_pick()
				if _pick.begins_with("obj,"):
					aim_obj = int(_pick.get_slice(",", 1))
					stage.found[aim_obj] = true
					_pick = ""
				if _pick != "":
					var tg: Array = b.targets(u, _pick.get_slice(",", 0))
					var ref: Dictionary = tg[mini(int(_pick.get_slice(",", 1)), tg.size() - 1)]
					if ref.k == "o":
						aim_obj = ref.id
					elif ref.k == "u":
						aim_enemy = ref.uid
					_pick = ""
				_refresh()
				await acted
				if battle != b:
					return
			elif u.side == "ally":
				await get_tree().create_timer(0.3 / speed).timeout
				b.auto_act(u)
			else:
				await get_tree().create_timer(0.25 / speed).timeout
				b.enemy_act(u)
			_flush()
			_refresh()
			await _wait_stage()
			if battle != b:
				return
		b.end_turn(u)
	if battle == b:
		_check_over()


func _wait_stage() -> void:
	while stage.busy():
		await get_tree().process_frame


func _flush() -> void:
	for ev in battle.events:
		if ev.t == "log":
			log_box.add_text(ev.text + "\n")
		else:
			if ev.t == "spawn":
				_load_unit_art(battle.unit(ev.uid))
				_sync_faces()
			stage.push(ev)
	battle.events.clear()


func _check_over() -> void:
	state = "over"
	var win: bool = battle.result == "win"
	var t := "[font_size=40][b]%s[/b][/font_size]\n" % ("승리!" if win else "패배")
	t += "%d라운드 · 쓰러진 횟수 %d · 남은 운명 주사위 %d" % [battle.round_no, battle.downs, battle.fate]
	over_lbl.text = t
	over.visible = true
	_refresh()
	if _demo:
		print("demo result: %s, rounds %d, downs %d" % [battle.result, battle.round_no, battle.downs])


# ── 동료 차례: 대상은 무대에서 미리 고르고, 행동 버튼을 누르면 바로 굴린다 ─

func _reset_pick() -> void:
	locks = 0


## 이 행동을 지금 누르면 누구에게 쓰는지. 고른 대상이 맞지 않으면 기본 대상(맨 앞 적, 가장 다친 동료)
func _target_for(aid: String) -> Dictionary:
	var tg: Array = battle.targets(actor, aid)
	if tg.is_empty():
		return {}
	if tg[0].k == "self":
		return tg[0]
	for ref in [{"k": "o", "id": aim_obj}, {"k": "u", "uid": aim_enemy}, {"k": "u", "uid": aim_ally}]:
		if ref in tg:
			return ref
	var best: Dictionary = {}
	var best_v := 9.0
	for ref in tg:
		if ref.k != "u":
			continue
		var u = battle.unit(ref.uid)
		var v: float = float(u.slot) if u.side == "enemy" else (0.0 if u.downed else float(u.hp) / u.max_hp)
		if v < best_v:
			best_v = v
			best = ref
	return best if not best.is_empty() else tg[0]


func _pick_action(aid: String) -> void:
	if state != "player":
		return
	var t := _target_for(aid)
	if t.is_empty():
		return
	state = "wait"
	battle.act(actor, aid, t, locks)
	_reset_pick()
	aim_obj = -1
	acted.emit()


func _on_pick(ref: Dictionary) -> void:
	# 오브젝트를 누르면 이름이 드러나고, 지금 동료가 그걸로 할 수 있는 일이 아래에 나온다
	if ref.k == "o":
		stage.found[ref.id] = true
		if state == "player" and not battle.obj(ref.id).used:
			aim_obj = -1 if aim_obj == ref.id else ref.id
		_refresh()
		return
	var u = battle.unit(ref.uid)
	if u.side == "enemy":
		aim_enemy = u.uid
	else:
		aim_ally = u.uid
	stage.inspect_uid = u.uid
	_refresh()




func _toggle_speed() -> void:
	speed = 2.0 if speed == 1.0 else 1.0
	stage.speed = speed
	speed_btn.text = " ▶ %d배속 " % int(speed)


# ── 그림 ────────────────────────────────────────────

func _load_art() -> void:
	stage.sprites.clear()
	stage.cutins.clear()
	stage.silhouettes.clear()
	icons.clear()
	portraits.clear()
	stage.bg_tex = _tex(battle.bg)
	for u in battle.units:
		_load_unit_art(u)
	st_icons.clear()
	for k in ["stun", "burn", "taunt", "guard", "stealth", "bless", "oath", "smoke", "cover"]:
		var t := UI.tex("st_" + k)
		if t != null:
			st_icons[k] = t
	stage.st_icons = st_icons
	stage.bold_font = bold_font
	stage.panel_sb = UI.sbt("panel", 30, 0)
	_sync_faces()


## 차례 줄 초상: SD 대기 그림 (실루엣만 있는 적은 실루엣)
func _sync_faces() -> void:
	turnbar.faces.clear()
	for u in battle.units:
		if stage.sprites.has(u.uid):
			turnbar.faces[u.uid] = stage.sprites[u.uid].idle
		elif stage.silhouettes.has(u.uid):
			turnbar.faces[u.uid] = stage.silhouettes[u.uid]


func _load_unit_art(u) -> void:
	if u.side == "enemy":
		var eid: String = ENEMY_ART.get(u.key, "")
		var ef := {}
		for pose in ["idle", "attack", "skill", "hit", "down"]:
			var et := _tex("enemies/%s/%s_sd_%s.png" % [eid, eid, pose])
			if et != null:
				ef[pose] = et
		if ef.has("idle"):
			stage.sprites[u.uid] = ef
			return
		var folder: String = ENEMY_SIL.get(u.key, "C01_lina")
		var t := _tex("characters/%s/%s_sd_idle.png" % [folder, folder.get_slice("_", 0)])
		if t != null:
			stage.silhouettes[u.uid] = t
		return
	var pre: String = u.art.get_slice("_", 0)
	var frames := {}
	for pose in ["idle", "attack", "skill", "hit", "down"]:
		var t := _tex("characters/%s/%s_sd_%s.png" % [u.art, pre, pose])
		if t != null:
			frames[pose] = t
	if frames.has("idle"):
		stage.sprites[u.uid] = frames
	var ct := _tex("characters/%s/%s_cutin.png" % [u.art, pre])
	if ct != null:
		stage.cutins[u.uid] = ct
	var pt := _tex("characters/%s/%s_portrait_combat_neutral.png" % [u.art, pre])
	if pt != null:
		# 얼굴 위주로 위쪽만 잘라 쓴다
		var at := AtlasTexture.new()
		at.atlas = pt
		var w := pt.get_width()
		at.region = Rect2(w * 0.2, pt.get_height() * 0.03, w * 0.6, w * 0.75)
		portraits[u.uid] = at
	for pair in [[u.skills[0], "basic"], [u.skills[1], "skill1"], [u.skills[2], "skill2"], [u.ult, "ult"]]:
		var it := _tex("icons/skills/%s_icon_%s.png" % [pre, pair[1]])
		if it != null:
			icons[pair[0]] = it


## rel: art/final 아래 경로. 웹 빌드는 godot/art (tools/web/prepare_web.py 가 복사), PC 실행은 저장소의 art/final
func _tex(rel: String) -> Texture2D:
	var res := "res://art/" + rel
	if ResourceLoader.exists(res):
		return load(res)
	var path := ProjectSettings.globalize_path("res://").path_join("../art/final/" + rel)
	if OS.has_feature("web") or not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if img != null else null


# ── 표시 갱신 ───────────────────────────────────────

func _refresh() -> void:
	if battle == null:
		return
	round_lbl.text = "ROUND %d" % battle.round_no
	event_lbl.text = battle.upcoming_text()
	turnbar.battle = battle
	turnbar.queue_redraw()
	_fix_aims()
	var refs: Array = []
	if state == "player":
		for r in [{"k": "u", "uid": aim_enemy}, {"k": "u", "uid": aim_ally}]:
			if r.uid != -1:
				refs.append(r)
	stage.targets = refs
	stage.pending = {"k": "u", "uid": aim_enemy}
	stage.focus_obj = aim_obj
	_update_card()
	_build_actions()
	_update_side()


func _update_card() -> void:
	var u = actor
	if stage.inspect_uid != -1 and battle.unit(stage.inspect_uid) != null:
		u = battle.unit(stage.inspect_uid)
	card_bars.battle = battle
	card_bars.u = u
	card_bars.st_icons = st_icons
	card_bars.queue_redraw()
	if u == null:
		card_pic.texture = null
		return
	# 적은 스탠딩이 없어서 SD 를 크게 보여 준다
	card_pic.texture = portraits.get(u.uid, null)
	if card_pic.texture == null and stage.sprites.has(u.uid):
		var at := AtlasTexture.new()
		at.atlas = stage.sprites[u.uid].idle
		at.region = Rect2(96, 16, 320, 400)
		card_pic.texture = at
	card_pic.flip_h = false

## 쓰러진 적이나 쓴 오브젝트를 고르고 있으면 다시 고른다 (적은 맨 앞)
func _fix_aims() -> void:
	var e = battle.unit(aim_enemy)
	if e == null or not e.alive():
		var es: Array = battle.side_units("enemy")
		aim_enemy = es[0].uid if not es.is_empty() else -1
	var a = battle.unit(aim_ally)
	if a == null or a.removed:
		aim_ally = -1
	if aim_obj != -1 and battle.obj(aim_obj).used:
		aim_obj = -1
	locks = mini(locks, battle.fate)


## 행동 카드 하나: 위에 아이콘, 아래에 이름과 판정 칸·확률
func _card(a: Dictionary, icon: Texture2D, style: String) -> Button:
	var label: String = a.name
	var sub := ""
	if a.slots > 0:
		sub = "◆".repeat(a.slots)
	var t := _target_for(a.id) if a.ready else {}
	if not t.is_empty() and a.slots > 0:
		sub += " %d%%" % roundi(battle.preview(actor, a.id, t).chance * 100)
	if a.note != "":
		sub = a.note
	var b := _btn("%s\n%s" % [label, sub] if sub != "" else label, _pick_action.bind(a.id))
	b.custom_minimum_size = Vector2(86, 104) if touch else Vector2(132, 156)
	b.add_theme_font_size_override("font_size", 11 if touch else 17)
	b.disabled = not a.ready
	b.tooltip_text = a.desc
	if icon != null:
		b.icon = icon
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 46 if touch else 76)
	if style != "" and a.ready:
		var m := 9.0 if touch else 12.0
		b.add_theme_stylebox_override("normal", UI.sbt("btn_" + style, 18, m))
		b.add_theme_stylebox_override("hover", UI.sbt("btn_" + style + "_hover", 18, m))
	return b


const ENV_ICON := {"hide": "stealth", "cover_self": "guard", "explode": "burn", "crush": "stun", "break_cover": "cover"}


func _build_actions() -> void:
	for c in actions.get_children():
		c.queue_free()
	if state != "player" or actor == null or actor.side != "ally":
		return
	for a in battle.actions_for(actor):
		var ic: Texture2D = icons.get(a.id, st_icons.get("guard") if a.id == "guard" else null)
		actions.add_child(_card(a, ic, "gold" if a.kind == "ult" else ""))
	if aim_obj == -1:
		return
	# 살펴본 오브젝트: 이 동료가 쓸 수 있는 방법만 (동료마다 다르다)
	var o: Dictionary = battle.obj(aim_obj)
	var oa: Array = battle.obj_actions(actor, aim_obj)
	if oa.is_empty():
		var l := Label.new()
		l.text = "%s\n지금 동료로는\n쓸 방법이 안 보인다" % o.name
		_outlined(l, 11 if touch else 16, Color(0.7, 0.7, 0.7))
		actions.add_child(l)
		return
	for a in oa:
		var ea: Dictionary = battle.env_act(a.id)
		var ic: Texture2D = icons.get(ea.skill) if ea.has("skill") else st_icons.get(ENV_ICON.get(ea.get("effect", ""), ""))
		actions.add_child(_card(a, ic, "env"))


func _update_side() -> void:
	for c in fate_row.get_children():
		c.queue_free()
	for i in Battle.FATE_MAX:
		var d := TextureButton.new()
		d.ignore_texture_size = true
		d.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		d.custom_minimum_size = Vector2(34, 34) if touch else Vector2(52, 52)
		d.focus_mode = FOCUS_NONE
		var name := "fate_off"
		if i < battle.fate:
			name = "fate_lock" if i < locks else "fate_on"
		d.texture_normal = UI.tex(name)
		d.disabled = state != "player" or i >= battle.fate
		d.tooltip_text = "누르면 다음 행동의 앞 칸부터 확정 성공"
		d.pressed.connect(_on_fate.bind(i))
		fate_row.add_child(d)
	if state == "over":
		hint.text = ""
		return
	if state != "player":
		hint.text = "[color=#a89a88]%s 차례…[/color]" % (actor.name if actor != null else "")
		return
	var t := "[b][color=#f0d79a]%s 차례[/color][/b]\n" % actor.name
	var e = battle.unit(aim_enemy)
	if e != null:
		t += "[color=#ff9a8a]▶ %s[/color] [color=#a89a88]방어 %d[/color]\n" % [e.name, battle.eff_def(e)]
	if aim_ally != -1:
		t += "[color=#9aff9a]♥ %s[/color]\n" % battle.unit(aim_ally).name
	if aim_obj != -1:
		for a in battle.obj_actions(actor, aim_obj):
			t += "[color=#b8ff9a]%s[/color]\n" % a.desc
	if locks > 0:
		t += "[color=#e0b0ff]운명 %d칸 확정[/color]\n" % locks
	t += "[color=#8a8070]무대를 눌러 대상 바꾸기 · 주변 살펴보기[/color]"
	hint.text = t


## 운명 주사위 i 번째를 누르면 그 개수까지 쓰고, 이미 쓴 것을 누르면 거기서부터 뺀다
func _on_fate(i: int) -> void:
	if state != "player":
		return
	locks = i if i < locks else i + 1
	locks = mini(locks, battle.fate)
	_refresh()