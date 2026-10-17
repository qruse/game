extends RefCounted
## 동료 화면: 왼쪽 동료 목록, 가운데 스탠딩(누르면 한 줄), 오른쪽 카드
## 편성 · 레벨 · 능력치 · 장비 · 스킬 (docs/04-game-flow.md 9.2). 동료 호감도는 없다 (2026-10-17 사용자)

const K = preload("res://scripts/ui_kit.gd")
const G = preload("res://scripts/guild_defs.gd")
const P = preload("res://scripts/party_defs.gd")
const FDefs = preload("res://scripts/fk_defs.gd")
const SDefs = preload("res://scripts/story_defs.gd")
const Desk = preload("res://scripts/guild_desk.gd")
const Talk = preload("res://scripts/talk.gd")

const SKILL_ICON := ["basic", "skill1", "skill2", "ult"]

var m  # story_main
var sel := ""
var _say: Label


func _init(main) -> void:
	m = main


func show(key := "") -> void:
	if key != "":
		sel = key
	if sel == "" or not Game.heroes.has(sel):
		sel = Game.party[0] if not Game.party.is_empty() else Game.heroes.keys()[0]
	m.town._frame("동료", "편성 · 장비 · 레벨 · 스킬", m.desk.show)
	var s: Control = m.screen
	_portrait(s)
	_list(s)
	_card(s)
	_hint(s)


# ── 왼쪽: 동료 목록 ──

func _list(s: Control) -> void:
	var v := K.vbox(8)
	v.position = Vector2(K.px(30), K.px(100))
	v.custom_minimum_size.x = K.px(250)
	s.add_child(v)
	v.add_child(K.shadowed(K.cap("파티 %d / 3 · 누르면 본다" % Game.party.size())))
	for k in Game.heroes:
		var d: Dictionary = FDefs.HEROES[k]
		var h: Dictionary = Game.heroes[k]
		var p := K.pick(show.bind(k), 10)
		var row := K.hbox(10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(row)
		var face := TextureRect.new()
		var pt: Texture2D = Game.tex("characters/%s/%s_portrait_combat_neutral.png" % [d.art, d.art.get_slice("_", 0)])
		if pt != null:
			var at := AtlasTexture.new()
			at.atlas = pt
			var w := pt.get_width()
			at.region = Rect2(w * 0.28, pt.get_height() * 0.05, w * 0.44, w * 0.44)
			face.texture = at
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.custom_minimum_size = Vector2(K.px(52), K.px(52))
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(face)
		var tv := K.vbox(2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nh := K.hbox(6)
		nh.add_child(K.bold(d.name, 17, K.BRASS_HI if k == sel else Color.WHITE))
		nh.add_child(K.num("Lv %d" % h.lv, 14, K.DIM))
		tv.add_child(nh)
		tv.add_child(K.label(d.role, 12, K.DIM))
		row.add_child(tv)
		if k in Game.party:
			row.add_child(K.chip("파티", Color(K.BLUE, 0.6), Color.WHITE, 11))
		if k == sel:
			p.add_theme_constant_override("margin_left", K.pxi(20))
		v.add_child(p)


# ── 가운데: 스탠딩 (누르면 한 줄) ──

func _portrait(s: Control) -> void:
	var d: Dictionary = FDefs.HEROES[sel]
	var pre: String = d.art.get_slice("_", 0)
	var tex: Texture2D = Game.tex("characters/%s/%s_portrait_combat_neutral.png" % [d.art, pre])
	if tex == null:
		return
	var pic := TextureRect.new()
	pic.texture = tex
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var hh := K.px(1240)
	var tw: float = hh * tex.get_width() / tex.get_height()
	pic.anchor_left = 0.43
	pic.anchor_right = 0.43
	pic.anchor_top = 1.0
	pic.anchor_bottom = 1.0
	pic.offset_left = -tw / 2.0
	pic.offset_right = tw / 2.0
	pic.offset_top = -hh + K.px(420)
	pic.offset_bottom = K.px(420)
	pic.mouse_filter = Control.MOUSE_FILTER_STOP
	pic.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if Talk.T.TALKS.has(sel):
		pic.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _say != null:
				_say.text = Talk.idle_line(sel)
				Talk._type(_say))
	s.add_child(pic)
	s.move_child(pic, 2)


## 아래: 이름 + 한마디 띠
func _hint(s: Control) -> void:
	var box := Desk.SayBox.new()
	for sd in [["left", 20], ["right", 60], ["top", 12], ["bottom", 13]]:
		box.add_theme_constant_override("margin_" + sd[0], K.pxi(sd[1]))
	var v := K.vbox(4)
	box.add_child(v)
	v.add_child(K.title(FDefs.HEROES[sel].name, 20, K.BRASS_HI))
	_say = K.label(Talk.idle_line(sel) if Talk.T.TALKS.has(sel) else "", 17, Color.WHITE, null, true)
	_say.custom_minimum_size.x = K.px(520)
	v.add_child(_say)
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = K.px(300)
	box.offset_bottom = -K.px(28)
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	s.add_child(box)


# ── 오른쪽 카드 ──

func _card(s: Control) -> void:
	var c := K.card(20, 22)
	c.anchor_left = 1.0
	c.anchor_right = 1.0
	c.offset_left = -K.px(30 + 540)
	c.offset_right = -K.px(30)
	c.offset_top = K.px(92)
	s.add_child(c)
	var v := K.vbox(10)
	c.add_child(v)
	var d: Dictionary = FDefs.HEROES[sel]
	var h: Dictionary = Game.heroes[sel]
	# 머리: 이름 · 역할 · 레벨 · 경험치
	var hd := K.hbox(10)
	var nv := K.vbox(0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(K.cap(d.role))
	nv.add_child(K.title(d.name, 30))
	hd.add_child(nv)
	var lv := K.vbox(2)
	lv.alignment = BoxContainer.ALIGNMENT_END
	var ll := K.num("Lv %d" % h.lv, 24, K.BRASS_HI)
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lv.add_child(ll)
	var xb := Desk.Bar.new()
	xb.ratio = 1.0 if h.lv >= P.LV_MAX else float(h.xp) / P.xp_need(h.lv)
	xb.col = K.BLUE_HI
	xb.custom_minimum_size = Vector2(K.px(120), K.px(4))
	xb.tooltip_text = "경험치 %d / %d" % [h.xp, P.xp_need(h.lv)]
	xb.mouse_filter = Control.MOUSE_FILTER_PASS
	lv.add_child(xb)
	hd.add_child(lv)
	v.add_child(hd)
	_grow(v)


func _grow(v: VBoxContainer) -> void:
	var d: Dictionary = FDefs.HEROES[sel]
	var h: Dictionary = Game.heroes[sel]
	var bo := Game.hero_bonus(sel)
	# 편성
	var inp: bool = sel in Game.party
	var ph := K.hbox(10)
	var pl := K.label("이번 의뢰에 데려간다" if inp else "길드에 남는다 (훈련장이 있으면 경험치 일부)", 14, K.GOOD if inp else K.DIM, null, true)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ph.add_child(pl)
	var pb := K.btn_sub("파티에서 빼기" if inp else "파티에 넣기", "i_people", _toggle_party, 38, 150)
	pb.disabled = (inp and Game.party.size() <= 1) or (not inp and Game.party.size() >= 3) or Game.stage == "page"
	ph.add_child(pb)
	v.add_child(ph)
	v.add_child(K.hr())
	# 능력치
	v.add_child(K.cap("능력치"))
	var st := K.hbox(16)
	for it in [["체력", d.hp + bo.hp, bo.hp], ["방어", d.def + bo.def, bo.def], ["위력", bo.power, bo.power], ["속도", d.spd, 0]]:
		var sv := K.vbox(0)
		sv.add_child(K.label(it[0], 12, K.DIM))
		var nh := K.hbox(4)
		nh.add_child(K.num(("+%d" % it[1]) if it[0] == "위력" else str(it[1]), 22))
		if it[2] > 0 and it[0] != "위력":
			nh.add_child(K.num("+%d" % it[2], 13, K.GOOD))
		sv.add_child(nh)
		st.add_child(sv)
	var mods := K.vbox(0)
	mods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ms: Array = []
	for k in FDefs.STAT:
		ms.append("%s %+d" % [FDefs.STAT[k], d.mod.get(k, 0)])
	mods.add_child(K.label("판정 보정", 12, K.DIM))
	mods.add_child(K.label("  ".join(PackedStringArray(ms)), 13, Color("e3e6ec")))
	st.add_child(mods)
	v.add_child(st)
	v.add_child(K.hr())
	# 장비
	var gh := K.hbox(8)
	var gc := K.cap("장비 · 대장간에서 바꾸고 강화한다")
	gc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gh.add_child(gc)
	v.add_child(gh)
	for kind in ["weapon", "armor"]:
		var g: Array = h[kind]
		var row := K.hbox(10)
		row.add_child(K.chip(P.GEAR_KIND[kind], Color(1, 1, 1, 0.08), K.DIM, 12))
		var gl := K.bold(P.gear_name(sel, kind, g[0], g[1]), 16)
		gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(gl)
		var fx := ""
		if kind == "weapon":
			fx = "위력 +%d" % (g[0] + g[1])
		else:
			fx = "방어 +%d · 체력 +%d" % [g[0], g[1] * 2]
		row.add_child(K.label(fx, 13, K.DIM))
		v.add_child(row)
	v.add_child(K.hr())
	# 스킬
	v.add_child(K.cap("스킬 · 위력은 레벨(짝수마다 +1)과 무기로 오른다"))
	var pre: String = d.art.get_slice("_", 0)
	var sk: Array = d.skills + [d.ult]
	for i in sk.size():
		var s: Dictionary = FDefs.SKILLS[sk[i]]
		var row := K.hbox(10)
		var ic := TextureRect.new()
		ic.texture = Game.tex("icons/skills/%s_icon_%s.png" % [pre, SKILL_ICON[i]])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.custom_minimum_size = Vector2(K.px(36), K.px(36))
		row.add_child(ic)
		var sv := K.vbox(0)
		sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nh := K.hbox(8)
		nh.add_child(K.bold(s.name, 15, K.BRASS_HI if i == 3 else Color.WHITE))
		if i == 3:
			nh.add_child(K.chip("궁극기", Color(K.BLUE, 0.5), Color.WHITE, 11))
		elif s.has("cd"):
			nh.add_child(K.label("대기 %d" % s.cd, 12, K.DIM))
		sv.add_child(nh)
		var desc: String = s.desc
		if s.has("power") and bo.power > 0:
			desc += "  (+%d)" % bo.power
		sv.add_child(K.label(desc, 13, K.DIM, null, true))
		row.add_child(sv)
		v.add_child(row)


func _toggle_party() -> void:
	if sel in Game.party:
		if Game.party.size() > 1:
			Game.party.erase(sel)
	elif Game.party.size() < 3:
		Game.party.append(sel)
	show()
