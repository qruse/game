extends Control
## 포 더 킹식 전투 시험판 화면.
## 실행 옵션 (-- 뒤에): --battle=0|1  --party=lina,cecile,adelheid  --demo  --shot=경로.png  --at=초,초,…  --touch

signal acted

const Battle = preload("res://scripts/fk_battle.gd")
const Defs = preload("res://scripts/fk_defs.gd")
const Stage = preload("res://scripts/fk_stage.gd")

## 적 그림이 아직 없어서, 동료 SD 를 어둡게 칠해 자리만 잡는다
const ENEMY_SIL := {"bandit": "C01_lina", "archer": "C03_adelheid", "wolf": "C02_cecile", "redbeard": "C01_lina"}

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
var timeline: HBoxContainer
var fate_lbl: Label
var event_lbl: Label
var speed_btn: Button
var log_btn: Button
var card_pic: TextureRect
var card_txt: RichTextLabel
var actions: HFlowContainer
var hint: RichTextLabel
var fate_btn: Button
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
	if ResourceLoader.exists("res://fonts/NotoSansKR-Game.ttf"):
		th.default_font = load("res://fonts/NotoSansKR-Game.ttf")
	else:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "Noto Sans CJK KR", "Noto Sans KR", "Apple SD Gothic Neo", "sans-serif"])
		th.default_font = f
	th.default_font_size = 16 if touch else 22
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


func _panel_style(a := 1.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.13, 0.11, a)
	sb.border_color = Color(0.55, 0.45, 0.28)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6 if touch else 10)
	return sb


# ── 화면 만들기 ─────────────────────────────────────

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(PRESET_FULL_RECT)
	add_child(hud)
	var top_h := 44 if touch else 64
	var bot_h := 160 if touch else 260

	stage = Stage.new()
	stage.clip_contents = true
	_place(stage, 0, 0, 1, 1, 0, top_h, 0, -bot_h)
	stage.picked.connect(_on_pick)
	hud.add_child(stage)

	var top := HBoxContainer.new()
	_place(top, 0, 0, 1, 0, 8, 2, -8, top_h - 2)
	top.add_theme_constant_override("separation", 8 if touch else 12)
	hud.add_child(top)
	round_lbl = Label.new()
	round_lbl.add_theme_font_size_override("font_size", 20 if touch else 28)
	top.add_child(round_lbl)
	timeline = HBoxContainer.new()
	timeline.add_theme_constant_override("separation", 4)
	top.add_child(timeline)
	event_lbl = Label.new()
	event_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	event_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_lbl.clip_text = true
	event_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
	top.add_child(event_lbl)
	fate_lbl = Label.new()
	fate_lbl.add_theme_color_override("font_color", Color(0.85, 0.65, 1.0))
	top.add_child(fate_lbl)
	speed_btn = _btn("1배속", _toggle_speed)
	top.add_child(speed_btn)
	log_btn = _btn("기록", func(): log_box.visible = not log_box.visible)
	top.add_child(log_btn)
	top.add_child(_btn("처음으로", _to_menu))

	log_box = RichTextLabel.new()
	_place(log_box, 1, 0, 1, 1, -(300 if touch else 520), top_h + 4, -4, -bot_h - 4)
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size", 12 if touch else 17)
	log_box.add_theme_stylebox_override("normal", _panel_style(0.88))
	log_box.visible = false
	hud.add_child(log_box)

	var bottom := PanelContainer.new()
	_place(bottom, 0, 1, 1, 1, 0, -bot_h, 0, 0)
	bottom.add_theme_stylebox_override("panel", _panel_style())
	hud.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8 if touch else 14)
	bottom.add_child(row)

	# 차례인 동료 카드 (스탠딩 얼굴 + 수치)
	var card := HBoxContainer.new()
	card.custom_minimum_size.x = 250 if touch else 430
	row.add_child(card)
	card_pic = TextureRect.new()
	card_pic.custom_minimum_size = Vector2(90, 0) if touch else Vector2(170, 0)
	card_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	card.add_child(card_pic)
	card_txt = RichTextLabel.new()
	card_txt.bbcode_enabled = true
	card_txt.size_flags_horizontal = SIZE_EXPAND_FILL
	card_txt.add_theme_font_size_override("normal_font_size", 13 if touch else 19)
	card_txt.add_theme_font_size_override("bold_font_size", 16 if touch else 24)
	card.add_child(card_txt)

	# 행동이 많으면 아래로 스크롤 (환경 행동까지 9개 안팎)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	actions = HFlowContainer.new()
	actions.size_flags_horizontal = SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation", 4 if touch else 6)
	actions.add_theme_constant_override("v_separation", 4 if touch else 6)
	scroll.add_child(actions)

	# 대상 안내 + 운명 주사위
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 230 if touch else 420
	row.add_child(side)
	hint = RichTextLabel.new()
	hint.bbcode_enabled = true
	hint.size_flags_vertical = SIZE_EXPAND_FILL
	hint.add_theme_font_size_override("normal_font_size", 12 if touch else 18)
	side.add_child(hint)
	fate_btn = _btn("운명 주사위 안 씀", _cycle_fate)
	side.add_child(fate_btn)


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


## 운명 주사위: 누를 때마다 다음 행동에 쓸 개수가 0 → 1 → … → 가진 개수 → 0
func _cycle_fate() -> void:
	locks = 0 if locks >= battle.fate else locks + 1
	_refresh()

func _toggle_speed() -> void:
	speed = 2.0 if speed == 1.0 else 1.0
	stage.speed = speed
	speed_btn.text = "%d배속" % int(speed)


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


func _load_unit_art(u) -> void:
	if u.side == "enemy":
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
	round_lbl.text = "라운드 %d" % battle.round_no
	event_lbl.text = battle.upcoming_text()
	fate_lbl.text = "운명 " + "●".repeat(battle.fate) + "○".repeat(Battle.FATE_MAX - battle.fate)
	_build_timeline()
	_fix_aims()
	var refs: Array = []
	if state == "player":
		for r in [{"k": "u", "uid": aim_enemy}, {"k": "u", "uid": aim_ally}]:
			if (r.k == "u" and r.uid != -1) or (r.k == "o" and r.id != -1):
				refs.append(r)
	stage.targets = refs
	stage.pending = {"k": "u", "uid": aim_enemy}
	stage.focus_obj = aim_obj
	_update_card()
	_build_actions()
	_update_side()


func _build_timeline() -> void:
	for c in timeline.get_children():
		c.queue_free()
	for i in battle.order.size():
		var u = battle.unit(battle.order[i])
		if u == null or u.removed or (i < battle.turn_idx):
			continue
		var l := Label.new()
		l.text = u.name if not touch else u.name.substr(0, 2)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.32, 0.5) if u.side == "ally" else Color(0.45, 0.16, 0.14)
		if i == battle.turn_idx:
			sb.border_color = Color(1.0, 0.85, 0.3)
			sb.set_border_width_all(3)
		if u.downed:
			sb.bg_color = Color(0.25, 0.25, 0.25)
		sb.set_corner_radius_all(4)
		sb.set_content_margin_all(3 if touch else 6)
		l.add_theme_stylebox_override("normal", sb)
		l.add_theme_font_size_override("font_size", 13 if touch else 18)
		timeline.add_child(l)


func _update_card() -> void:
	var u = actor
	if stage.inspect_uid != -1 and battle.unit(stage.inspect_uid) != null:
		u = battle.unit(stage.inspect_uid)
	if u == null:
		card_pic.texture = null
		card_txt.text = ""
		return
	card_pic.texture = portraits.get(u.uid, null)
	var t := "[b]%s[/b]" % u.name
	if u.role != "":
		t += " [color=#bbbbbb]%s[/color]" % u.role
	t += "\nHP %d/%d · 방어 %d · 속도 %d" % [u.hp, u.max_hp, battle.eff_def(u), u.spd]
	if u.side == "ally":
		var ms: Array = []
		for k in ["str", "dex", "int", "cha"]:
			ms.append("%s %+d" % [Defs.STAT[k], u.mods[k]])
		t += "\n[color=#bbbbbb]%s[/color]" % " ".join(PackedStringArray(ms))
		t += "\n결의 %d%%" % u.resolve
	else:
		t += "\n명중 %+d · 피해 %d · 판정 %d칸" % [u.atk, u.power, u.slots]
	var sts: Array = battle.status_names(u)
	if u.downed:
		sts = ["쓰러짐"]
	if not sts.is_empty():
		t += "\n[color=#ffd966]%s[/color]" % ", ".join(PackedStringArray(sts))
	card_txt.text = t


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


func _build_actions() -> void:
	for c in actions.get_children():
		c.queue_free()
	if state != "player" or actor == null or actor.side != "ally":
		return
	for a in battle.actions_for(actor):
		var label: String = a.name
		if a.slots > 0:
			label += " " + "◆".repeat(a.slots)
		var t := _target_for(a.id) if a.ready else {}
		if not t.is_empty() and a.slots > 0:
			var pv: Dictionary = battle.preview(actor, a.id, t)
			label += " %d%%" % roundi(pv.chance * 100)
		if a.note != "":
			label += " (%s)" % a.note
		var b := _btn(" %s " % label, _pick_action.bind(a.id))
		if touch:
			b.custom_minimum_size.y = 34
			b.add_theme_font_size_override("font_size", 14)
		b.disabled = not a.ready
		b.tooltip_text = a.desc
		if icons.has(a.id):
			b.icon = icons[a.id]
			b.add_theme_constant_override("icon_max_width", 22 if touch else 40)
		if a.kind == "env":
			b.add_theme_color_override("font_color", Color(0.75, 1.0, 0.6))
		elif a.kind == "ult":
			b.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		actions.add_child(b)
	if aim_obj == -1:
		return
	# 살펴본 오브젝트: 이 동료가 쓸 수 있는 방법만 (동료마다 다르다)
	var o: Dictionary = battle.obj(aim_obj)
	var oa: Array = battle.obj_actions(actor, aim_obj)
	var l := Label.new()
	l.text = "%s:" % o.name if not oa.is_empty() else "%s: 지금 동료로는 쓸 방법이 안 보인다" % o.name
	l.add_theme_color_override("font_color", Color(0.75, 1.0, 0.6) if not oa.is_empty() else Color(0.7, 0.7, 0.7))
	l.add_theme_font_size_override("font_size", 14 if touch else 20)
	actions.add_child(l)
	for a in oa:
		var label: String = a.name + " " + "◆".repeat(a.slots)
		var t := _target_for(a.id) if a.ready else {}
		if not t.is_empty() and a.slots > 0:
			label += " %d%%" % roundi(battle.preview(actor, a.id, t).chance * 100)
		if a.note != "":
			label += " (%s)" % a.note
		var b := _btn(" %s " % label, _pick_action.bind(a.id))
		if touch:
			b.custom_minimum_size.y = 34
			b.add_theme_font_size_override("font_size", 14)
		b.disabled = not a.ready
		b.tooltip_text = a.desc
		b.add_theme_color_override("font_color", Color(0.75, 1.0, 0.6))
		actions.add_child(b)


func _ref_name(r: Dictionary) -> String:
	if r.k == "o":
		return battle.obj(r.id).name
	var u = battle.unit(r.uid)
	return u.name if u != null else ""


func _update_side() -> void:
	fate_btn.disabled = state != "player" or battle.fate == 0
	fate_btn.text = "운명 주사위 %d개 사용 (앞 칸부터 확정 성공)" % locks if locks > 0 else "운명 주사위 안 씀 (%d개 있음)" % battle.fate
	fate_btn.modulate = Color(0.85, 0.6, 1.0) if locks > 0 else Color.WHITE
	if state == "over":
		hint.text = ""
		return
	if state != "player":
		hint.text = "[color=#aaaaaa]%s 차례…[/color]" % (actor.name if actor != null else "")
		return
	var t := "[b]%s 차례[/b] · 버튼을 누르면 바로 행동\n" % actor.name
	var e = battle.unit(aim_enemy)
	if e != null:
		t += "[color=#ff9a8a]공격 대상: %s (방어 %d)[/color]\n" % [e.name, battle.eff_def(e)]
	if aim_obj != -1:
		for a in battle.obj_actions(actor, aim_obj):
			t += "[color=#b8ff9a]%s[/color]\n" % a.desc
	if aim_ally != -1:
		t += "[color=#9aff9a]도울 동료: %s[/color]\n" % battle.unit(aim_ally).name
	t += "[color=#bbbbbb]대상은 무대에서 눌러 바꾸기 · 주변에 쓸 만한 게 있는지 눌러 보기[/color]"
	hint.text = t