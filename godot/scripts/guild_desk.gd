extends RefCounted
## 길드 하우스 로비 (확정 시안: design/mockups/guild_desk_v5.html).
## 왼쪽 리나 + 한마디, 오른쪽 이번 주 의뢰서와 재건 공사, 아래 메뉴 칸.

const K = preload("res://scripts/ui_kit.gd")
const G = preload("res://scripts/guild_defs.gd")
const SDefs = preload("res://scripts/story_defs.gd")
const Talk = preload("res://scripts/talk.gd")

## 의뢰 인장 → 봉랍 그림
const SEAL_KIND := {"왕관": "crown", "교회": "dawn", "상회": "scales", "쥐": "rat"}
const SEAL_NAME := {"왕관": "왕관", "교회": "새벽빛 교회", "상회": "금저울 상회", "쥐": "회색 쥐"}
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]

var m  # story_main
var town  # town.gd
var _say_lbl: Label  # 노라 한마디 (그림을 누르면 바뀐다)


func _init(main, t) -> void:
	m = main
	town = t


func show() -> void:
	m._clear()
	Game.stage = "hub"
	# 이번 주 장면을 아직 안 봤으면 먼저 (짧은 장면)
	var wk := "week%d" % Game.week
	if SDefs.SCENES.has(wk) and not Game.flags.get("seen_" + wk, false):
		Game.flags["seen_" + wk] = true
		m._play(wk, func(_s, _k): show())
		return
	var t: Texture2D = Game.tex(G.STAGES[Game.build].bg)
	m.bg.texture = t if t != null else Game.tex("backgrounds/scene/bg_guildhall_ruined.png")
	m.bg.modulate = Color(0.78, 0.76, 0.74)
	var s: Control = m.screen
	shade(s)
	_hero(s)
	_head(s)
	s.add_child(resource_bar())
	_right(s)
	_say(s)
	_dock(s)


# ── 배경 위 그늘 (오른쪽과 위아래를 남색으로) ──

static func shade(s: Control) -> void:
	var g := TextureRect.new()
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.34, 0.62, 1.0])
	gr.colors = PackedColorArray([Color(0.03, 0.04, 0.08, 0), Color(0.03, 0.04, 0.08, 0), Color(0.03, 0.04, 0.08, 0.55), Color(0.03, 0.04, 0.08, 0.86)])
	gt.gradient = gr
	g.texture = gt
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(g)
	var v := TextureRect.new()
	var vt := GradientTexture2D.new()
	vt.fill_from = Vector2(0, 0)
	vt.fill_to = Vector2(0, 1)
	var vr := Gradient.new()
	vr.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	vr.colors = PackedColorArray([Color(0.03, 0.04, 0.08, 0.62), Color(0.03, 0.04, 0.08, 0), Color(0.03, 0.04, 0.08, 0), Color(0.03, 0.04, 0.08, 0.88)])
	vt.gradient = vr
	v.texture = vt
	v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(v)


## 로비 왼쪽: 부관 노라 (동료가 로비를 차지하지 않게. docs/04-game-flow.md 3.1)
func _hero(s: Control) -> void:
	var expr := "positive" if _week_done() else "neutral"
	var tex: Texture2D = Game.tex("npcs/N14_nora/N14_portrait_%s.png" % expr)
	if tex == null:
		tex = Game.tex("npcs/N14_nora/N14_portrait_neutral.png")
	if tex == null:
		return
	var h := TextureRect.new()
	h.texture = tex
	h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var hh := K.px(1290)
	h.size = Vector2(hh * tex.get_width() / tex.get_height(), hh)
	h.anchor_top = 1.0
	h.anchor_bottom = 1.0
	h.position = Vector2(K.px(70), 0)
	h.offset_top = -hh + K.px(430)
	h.offset_bottom = K.px(430)
	# 누르면 일반 대화 한 줄 (니케식, 제한 없음)
	h.mouse_filter = Control.MOUSE_FILTER_STOP
	h.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	h.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _say_lbl != null:
			_say_lbl.text = Talk.idle_line("nora")
			Talk._type(_say_lbl))
	s.add_child(h)
	# 천천히 숨쉬기
	h.pivot_offset = Vector2(h.size.x / 2.0, h.size.y)
	var tw := h.create_tween().set_loops()
	tw.tween_property(h, "scale", Vector2(1.0, 1.006), 2.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(h, "scale", Vector2.ONE, 2.2).set_trans(Tween.TRANS_SINE)


# ── 왼쪽 위: 문장 · 이름 · 주차 도장 ──

func _head(s: Control) -> void:
	var h := K.hbox(14)
	h.position = Vector2(K.px(30), K.px(22))
	s.add_child(h)
	var em := K.icon("emblem_harwell", 60, Color.WHITE)
	h.add_child(em)
	var v := K.vbox(2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(K.shadowed(K.title("하웰 모험가 길드", 34)))
	var sub := K.hbox(8)
	sub.add_child(K.Diamond.make(K.px(6), K.BRASS))
	sub.add_child(K.shadowed(K.label("길드 하우스 · %s" % G.STAGES[Game.build].name, 13, Color("d5d9e3"))))
	v.add_child(sub)
	h.add_child(K.spacer(2))
	h.add_child(week_stamp())


## 주차 도장: 놋쇠 테 동그라미 (똑바로)
static func week_stamp() -> Control:
	var c := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.16, 0.92)
	sb.border_color = K.BRASS
	sb.set_border_width_all(maxi(1, K.pxi(1.5)))
	sb.set_corner_radius_all(K.pxi(40))
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = K.pxi(8)
	c.add_theme_stylebox_override("panel", sb)
	c.custom_minimum_size = Vector2(K.px(66), K.px(66))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := K.vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var n := K.num(str(Game.week), 26, K.BRASS_HI)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var l := K.label("쪽", 10, K.BRASS)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return c


# ── 오른쪽 위: 자원 띠 (다른 화면도 쓴다) ──

static func resource_bar() -> Control:
	var p := PanelContainer.new()
	var sb := K.sb_panel(12, K.NAVY, K.LINE, 0)
	sb.content_margin_left = K.px(8)
	sb.content_margin_right = K.px(4)
	sb.content_margin_top = K.px(6)
	sb.content_margin_bottom = K.px(6)
	p.add_theme_stylebox_override("panel", sb)
	p.anchor_left = 1.0
	p.anchor_right = 1.0
	p.offset_right = -K.px(30)
	p.offset_top = K.px(26)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var h := K.hbox(0)
	p.add_child(h)
	var items: Array = [["res_gold", Game.gold, "금화"]]
	for k in G.MATS:
		items.append(["res_" + k, Game.mats.get(k, 0), G.MATS[k]])
	items.append(["res_fame", Game.fame, "명성"])
	for i in items.size():
		if i > 0:
			var sep := ColorRect.new()
			sep.color = K.HAIR
			sep.custom_minimum_size = Vector2(1, K.px(26))
			sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(sep)
		var it := K.hbox(7)
		it.add_child(K.spacer(5))
		it.add_child(K.icon(items[i][0], 26, Color.WHITE))
		var n := K.num(str(items[i][1]), 18, Color("f4f1ea"))
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		it.add_child(n)
		it.add_child(K.spacer(5))
		it.tooltip_text = items[i][2]
		it.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(it)
	# 길드 등급
	var r := PanelContainer.new()
	var rs := K.sb_flat(Color(K.BRASS, 0.14), Color(K.BRASS, 0.45), 1)
	rs.content_margin_left = K.px(10)
	rs.content_margin_right = K.px(14)
	r.add_theme_stylebox_override("panel", rs)
	r.tooltip_text = "길드 등급"
	var rh := K.hbox(6)
	r.add_child(rh)
	rh.add_child(K.icon("rank_%d" % Game.rank, 22, Color.WHITE))
	var rl := K.bold(G.RANKS[Game.rank].name, 14, K.BRASS_HI)
	rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rh.add_child(rl)
	h.add_child(K.spacer(4))
	h.add_child(r)
	return p


# ── 오른쪽 기둥: 이번 주 의뢰 + 재건 공사 ──

func _right(s: Control) -> void:
	var col := K.vbox(14)
	col.anchor_left = 1.0
	col.anchor_right = 1.0
	col.offset_left = -K.px(30 + 600)
	col.offset_right = -K.px(30)
	col.offset_top = K.px(92)
	s.add_child(col)
	col.add_child(_board())
	col.add_child(_build())
	_slide_in(col, Vector2(K.px(40), 0))


func _week_quests() -> Array:
	return SDefs.WEEK_QUESTS_BY.get(Game.week, [])


func _board() -> Control:
	var c := K.card(20, 22)
	var v := K.vbox(0)
	c.add_child(v)
	var quests := _week_quests()
	var confirmed: bool = Game.flags.get("picked_%d" % Game.week, false)
	# 머리
	var ph := K.hbox()
	v.add_child(ph)
	var left := K.vbox(3)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(K.cap("의뢰 게시판 · 장부 %d쪽" % Game.week))
	left.add_child(K.title("이번 의뢰", 32))
	ph.add_child(left)
	if not quests.is_empty():
		var pk := K.vbox(8)
		pk.alignment = BoxContainer.ALIGNMENT_END
		var cl := K.cap("맡을 수 있는 의뢰" if not confirmed else "진행 중")
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pk.add_child(cl)
		var d := K.hbox(8)
		d.alignment = BoxContainer.ALIGNMENT_END
		var done_n := Game.picks.filter(func(q): return Game.results.has(q)).size()
		for i in SDefs.WEEK_PICKS:
			var on: bool = (i < done_n) if confirmed else (i < Game.picks.size())
			d.add_child(K.Diamond.make(K.px(10), K.BRASS_HI, on, on))
		var cnt := "%d / %d" % [done_n if confirmed else Game.picks.size(), SDefs.WEEK_PICKS]
		d.add_child(K.num(cnt, 13, K.DIM))
		pk.add_child(d)
		ph.add_child(pk)
	v.add_child(K.spacer(0, 16))
	# 의뢰서
	var list := K.vbox(10)
	v.add_child(list)
	if quests.is_empty():
		list.add_child(K.label("지금은 큰 의뢰가 없다. 위탁 의뢰를 돌리고 다음 일에 대비하자.", 15, K.DIM, null, true))
	var shown: Array = Game.picks if confirmed else quests
	for i in shown.size():
		var qid: String = shown[i]
		list.add_child(_ticket(qid, i, confirmed))
	v.add_child(K.spacer(0, 18))
	# 버튼
	var acts := K.hbox(10)
	v.add_child(acts)
	acts.add_child(K.btn_sub("의뢰 지도", "i_map", m._board))
	var main: Button
	if quests.is_empty() or (confirmed and m._left_quests().is_empty()):
		main = K.btn_main("장부 정리", "이번 쪽을 마감한다", m._weekend)
	elif not confirmed:
		var need: int = SDefs.WEEK_PICKS - Game.picks.size()
		main = K.btn_main("의뢰 확정", ("%d개 더 고르세요" % need) if need > 0 else "첫 의뢰로 출발", func():
			Game.flags["picked_%d" % Game.week] = true
			m._start_quest(Game.picks[0]))
		main.disabled = need > 0
	else:
		var nxt: String = m._left_quests()[0]
		main = K.btn_main("출발", SDefs.QUESTS[nxt].name, func(): m._start_quest(nxt))
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acts.add_child(main)
	return c


func _ticket(qid: String, i: int, confirmed: bool) -> Control:
	var q: Dictionary = SDefs.QUESTS[qid]
	var picked: bool = qid in Game.picks
	var res: String = Game.results.get(qid, "")
	var t := Ticket.new()
	t.sel = picked and not confirmed or (confirmed and res == "")
	t.done = res != ""
	t.custom_minimum_size = Vector2(0, K.px(96))
	var h := K.hbox(0)
	t.add_child(h)
	# 왼쪽 표: 인장 + 로마 숫자
	var stub := K.vbox(2)
	stub.alignment = BoxContainer.ALIGNMENT_CENTER
	stub.custom_minimum_size = Vector2(K.px(84), 0)
	var sk: String = SEAL_KIND.get(q.get("seal", ""), "crown")
	var sl := K.seal(sk, 54)
	sl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stub.add_child(sl)
	var rn := K.num(ROMAN[i % ROMAN.size()], 14, Color("dce6fa") if t.sel else K.INK_2)
	rn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stub.add_child(rn)
	h.add_child(stub)
	# 본문
	var body := MarginContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for sd in [["left", 18], ["right", 16], ["top", 12], ["bottom", 11]]:
		body.add_theme_constant_override("margin_" + sd[0], K.pxi(sd[1]))
	var bv := K.vbox(1)
	body.add_child(bv)
	bv.add_child(K.label("의뢰처 · %s (%s)" % [q.get("client", ""), SEAL_NAME.get(q.get("seal", ""), "")], 11.5, Color("8a6a3a"), K.f_bold))
	bv.add_child(K.bold(q.name, 19, K.INK))
	var ds := K.label(q.get("short", q.get("desc", "")), 13, K.INK_2)
	ds.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ds.custom_minimum_size.x = K.px(260)
	bv.add_child(ds)
	var meta := K.hbox(8)
	for tg in q.get("tags", []):
		meta.add_child(_tag(tg))
	var rk := K.hbox(3)
	rk.add_child(K.label("위험", 11.5, K.INK_2))
	for r in 3:
		rk.add_child(K.Diamond.make(K.px(6), K.WAX if r < q.get("risk", 1) else Color(K.INK, 0.22)))
	meta.add_child(rk)
	bv.add_child(K.spacer(0, 4))
	bv.add_child(meta)
	h.add_child(body)
	# 오른쪽 표: 보상 또는 결과
	var rw := K.vbox(3)
	rw.alignment = BoxContainer.ALIGNMENT_CENTER
	rw.custom_minimum_size = Vector2(K.px(108), 0)
	if res != "":
		var ok := res == "ok"
		var r := K.bold("성공" if ok else "실패", 18, Color("3f7a3a") if ok else K.WAX)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rw.add_child(r)
	else:
		var g := K.hbox(5)
		g.alignment = BoxContainer.ALIGNMENT_CENTER
		g.add_child(K.icon("res_gold", 21, Color.WHITE))
		g.add_child(K.num(str(G.QUEST_REWARD[Game.chapter()].ok.gold), 22, K.INK))
		rw.add_child(g)
		var f := K.hbox(3)
		f.alignment = BoxContainer.ALIGNMENT_CENTER
		f.add_child(K.icon("res_fame", 13, Color.WHITE))
		f.add_child(K.num("+%d" % G.QUEST_REWARD[Game.chapter()].ok.fame, 11.5, K.INK_2))
		rw.add_child(f)
	h.add_child(rw)
	# 채택 도장
	if picked:
		t.add_child(_chop("채택" if res == "" else "완료"))
	if not confirmed:
		t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		t.clicked.connect(func():
			if qid in Game.picks:
				Game.picks.erase(qid)
			elif Game.picks.size() < SDefs.WEEK_PICKS:
				Game.picks.append(qid)
			show())
	return t


func _tag(text: String) -> Control:
	var l := K.label(text, 11.5, Color("3b3022"), K.f_bold)
	var sb := K.sb_flat(Color(K.INK, 0.08))
	sb.content_margin_left = K.px(8)
	sb.content_margin_right = K.px(8)
	sb.content_margin_top = K.px(1)
	sb.content_margin_bottom = K.px(1)
	l.add_theme_stylebox_override("normal", sb)
	return l


## 붉은 도장 (살짝 기울여 찍힌 느낌)
func _chop(text: String) -> Control:
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := K.label(text, 19, K.WAX, K.f_title)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = Color(K.WAX, 0.85)
	sb.set_border_width_all(maxi(2, K.pxi(2.5)))
	sb.set_corner_radius_all(K.pxi(5))
	sb.content_margin_left = K.px(9)
	sb.content_margin_right = K.px(9)
	sb.content_margin_bottom = K.px(1)
	l.add_theme_stylebox_override("normal", sb)
	l.modulate.a = 0.88
	l.anchor_left = 1.0
	l.anchor_right = 1.0
	l.offset_left = -K.px(122 + 64)
	l.offset_right = l.offset_left
	l.grow_horizontal = Control.GROW_DIRECTION_END
	l.offset_top = K.px(10)
	l.rotation = deg_to_rad(-11)
	wrap.add_child(l)
	return wrap


## 의뢰서 바탕: 종이 + 절취선 + 구멍 (+ 고른 표는 파랗게)
class Ticket extends MarginContainer:
	signal clicked
	var sel := false
	var done := false
	static var noise: NoiseTexture2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		if noise == null:
			noise = NoiseTexture2D.new()
			noise.width = 256
			noise.height = 128
			noise.seamless = true
			var n := FastNoiseLite.new()
			n.frequency = 0.05
			n.fractal_octaves = 4
			noise.noise = n

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
			accept_event()

	func _draw() -> void:
		var k: float = size.y / 96.0
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("fbf5e6") if sel else (Color("e6dcc6") if done else Color("efe6d3")))
		if noise != null:
			draw_texture_rect(noise, r, true, Color(0.55, 0.42, 0.22, 0.10))
		var sx := 84.0 * k
		var rx := size.x - 108.0 * k
		if sel:
			draw_rect(Rect2(0, 0, sx, size.y), Color("2f5fb8"))
			draw_rect(r, Color("2f5fb8"), false, maxf(2.0, 2.0 * k))
		var dash := Color(0.37, 0.31, 0.23, 0.4)
		draw_dashed_line(Vector2(sx, 4 * k), Vector2(sx, size.y - 4 * k), Color(1, 1, 1, 0.45) if sel else dash, maxf(1.0, 1.5 * k), 5.0 * k)
		draw_dashed_line(Vector2(rx, 4 * k), Vector2(rx, size.y - 4 * k), dash, maxf(1.0, 1.5 * k), 5.0 * k)
		# 구멍 (판 색)
		for p in [Vector2(sx, 0), Vector2(sx, size.y)]:
			draw_circle(p, 7.0 * k, Color(0.04, 0.055, 0.1))


# ── 재건 공사 ──

func _build() -> Control:
	var c := K.card(0, 0)
	c.accent = false
	for sd in [["left", 22], ["right", 22], ["top", 15], ["bottom", 16]]:
		c.add_theme_constant_override("margin_" + sd[0], K.pxi(sd[1]))
	var v := K.vbox(0)
	c.add_child(v)
	var top := K.hbox(8)
	v.add_child(top)
	top.add_child(K.bold("재건 공사", 16))
	top.add_child(K.num("%d / %d" % [Game.build, G.STAGES.size() - 1], 16, K.BRASS_HI))
	top.add_child(K.spacer(0, 0, true))
	var last := Game.build + 1 >= G.STAGES.size()
	if not last:
		var nx := K.hbox(4)
		nx.add_child(K.label("다음 공사 ·", 13, K.DIM))
		nx.add_child(K.bold(G.STAGES[Game.build + 1].name, 13, Color.WHITE))
		top.add_child(nx)
	v.add_child(K.spacer(0, 14))
	v.add_child(StageTrack.make(Game.build))
	if not last:
		var cost := Game.stage_cost(Game.build + 1)
		var need := K.hbox(10)
		v.add_child(K.spacer(0, 10))
		var hr := ColorRect.new()
		hr.color = K.HAIR
		hr.custom_minimum_size = Vector2(0, 1)
		v.add_child(hr)
		v.add_child(K.spacer(0, 10))
		v.add_child(need)
		need.add_child(K.label("필요", 12.5, K.DIM))
		var items: Array = []
		if cost.get("gold", 0) > 0:
			items.append(["res_gold", Game.gold, cost.gold])
		for mk in G.MATS:
			if cost.get(mk, 0) > 0:
				items.append(["res_" + mk, Game.mats.get(mk, 0), cost[mk]])
		for it in items:
			var ok: bool = it[1] >= it[2]
			var col := Color.WHITE if ok else K.BAD
			var row := K.hbox(6)
			row.add_child(K.icon(it[0], 18, Color.WHITE))
			row.add_child(K.num("%d / %d" % [it[1], it[2]], 14, col))
			var bar := Bar.new()
			bar.ratio = clampf(float(it[1]) / maxf(1.0, it[2]), 0.0, 1.0)
			bar.col = K.BRASS_HI if ok else K.BAD
			bar.custom_minimum_size = Vector2(K.px(64), K.px(4))
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(bar)
			need.add_child(row)
			need.add_child(K.spacer(6))
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			town.show_build())
	return c


class Bar extends Control:
	var ratio := 0.0
	var col := Color.WHITE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.1))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), col)


## 공사 단계 줄: 마름모 + 로마 숫자 + 이름
class StageTrack extends Control:
	var cur := 0
	var names: Array = []

	static func make(c: int) -> StageTrack:
		var t := StageTrack.new()
		t.cur = c
		t.names = ["폐허", "지붕", "큰 홀", "2층", "별채", "완공"]
		t.custom_minimum_size = Vector2(0, K.px(50))
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return t

	func _ready() -> void:
		var n := names.size()
		for i in n:
			var lab := K.label(names[i], 11.5, K.BRASS_HI if i <= cur else (Color.WHITE if i == cur + 1 else K.DIM), K.f_bold if i == cur + 1 else null)
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lab.set_meta("i", i)
			add_child(lab)
			var rn := K.num("·" if i == 0 else ROMAN[i - 1], 11, K.INK if i <= cur else (K.BRASS_HI if i == cur + 1 else K.DIM))
			rn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			rn.set_meta("r", i)
			add_child(rn)
		resized.connect(_place)
		_place()

	func _xs() -> Array:
		var n := names.size()
		var pad := K.px(26)
		var out: Array = []
		for i in n:
			out.append(pad + (size.x - pad * 2.0) * i / (n - 1))
		return out

	func _place() -> void:
		var xs := _xs()
		for ch in get_children():
			var w := K.px(60)
			if ch.has_meta("i"):
				ch.position = Vector2(xs[ch.get_meta("i")] - w / 2.0, K.px(30))
				ch.size = Vector2(w, K.px(16))
			elif ch.has_meta("r"):
				ch.position = Vector2(xs[ch.get_meta("r")] - w / 2.0, K.px(13) - K.px(9))
				ch.size = Vector2(w, K.px(18))
		queue_redraw()

	func _draw() -> void:
		var xs := _xs()
		var y := K.px(13)
		draw_line(Vector2(xs[0], y), Vector2(xs[-1], y), Color(K.BRASS, 0.3), 1.0)
		if cur > 0:
			draw_line(Vector2(xs[0], y), Vector2(xs[cur], y), K.BRASS_HI, maxf(2.0, K.px(3)))
		elif xs.size() > 1:
			draw_line(Vector2(xs[0], y), Vector2(lerpf(xs[0], xs[1], 0.5), y), K.BRASS_HI, maxf(2.0, K.px(3)))
		var r := K.px(13) * 1.0
		for i in xs.size():
			var c := Vector2(xs[i], y)
			var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
			if i <= cur:
				for g in 2:
					var gr := r * (1.25 + g * 0.3)
					draw_colored_polygon(PackedVector2Array([c + Vector2(0, -gr), c + Vector2(gr, 0), c + Vector2(0, gr), c + Vector2(-gr, 0)]), Color(K.BRASS_HI, 0.12))
				draw_colored_polygon(pts, K.BRASS)
			else:
				draw_colored_polygon(pts, Color(0.06, 0.09, 0.15))
				pts.append(pts[0])
				draw_polyline(pts, K.BRASS_HI if i == cur + 1 else Color(K.BRASS, 0.5), maxf(1.0, K.px(2 if i == cur + 1 else 1.5)), true)


# ── 부관 노라 한마디 ──

func _say(s: Control) -> void:
	var line := _nora_line()
	var v := K.vbox(5)
	v.anchor_top = 1.0
	v.anchor_bottom = 1.0
	v.offset_left = K.px(30)
	v.offset_right = K.px(30 + 680)
	v.offset_bottom = -K.px(148)
	v.grow_vertical = Control.GROW_DIRECTION_BEGIN
	s.add_child(v)
	var who := K.hbox(10)
	who.add_child(K.shadowed(K.cap("부관")))
	who.add_child(K.shadowed(K.title("노라", 22, K.BRASS_HI)))
	var ln := Bar.new()
	ln.ratio = 1.0
	ln.col = Color(K.BRASS, 0.7)
	ln.custom_minimum_size = Vector2(K.px(120), 1)
	ln.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(ln)
	# 호감도: 작은 마름모 3개 (본 단계) + 다음 단계 막대
	var seen: int = Game.bond_seen.get("nora", 0)
	for i in 3:
		who.add_child(K.Diamond.make(K.px(6), K.BRASS_HI, i < seen))
	var tb := Bar.new()
	tb.ratio = Game.bond_ratio("nora")
	tb.col = K.BLUE_HI
	tb.custom_minimum_size = Vector2(K.px(60), K.px(3))
	tb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tb.tooltip_text = "호감도 %d" % Game.bond.get("nora", 0)
	tb.mouse_filter = Control.MOUSE_FILTER_PASS
	who.add_child(tb)
	var st := Game.bond_ready("nora")
	if st > 0:
		var b := K.btn_sub("이야기 %s" % ROMAN[st - 1], "i_book", _bond_scene.bind("nora", st), 34, 132)
		who.add_child(b)
	who.add_child(Talk.button(m, "nora", show, 34, 140))
	who.add_child(Talk.gift_button(m, "nora", show, 34, 96))
	v.add_child(who)
	var box := SayBox.new()
	for sd in [["left", 20], ["right", 44], ["top", 13], ["bottom", 14]]:
		box.add_theme_constant_override("margin_" + sd[0], K.pxi(sd[1]))
	_say_lbl = K.label(line, 19, Color.WHITE, null, true)
	box.add_child(_say_lbl)
	v.add_child(box)


class SayBox extends MarginContainer:
	func _draw() -> void:
		K.hgrad(self, Rect2(Vector2.ZERO, size), [0.0, 0.55, 1.0], [Color(0.035, 0.05, 0.094, 0.9), Color(0.035, 0.05, 0.094, 0.62), Color(0.035, 0.05, 0.094, 0.0)])
		draw_rect(Rect2(0, 0, maxf(2.0, K.px(2)), size.y), K.BRASS)


## NPC 이야기 장면 → 본 단계 기록 → 로비로
static func play_bond(main, id: String, st: int, then: Callable) -> void:
	var b: Dictionary = Game.bond_def(id)
	main._play(b.scene + str(st), func(_s, _k):
		Game.bond_seen[id] = st
		main._show_toast("%s의 이야기 %s · %s" % [b.name, ROMAN[st - 1], b.rewards[st - 1]])
		then.call())


func _bond_scene(id: String, st: int) -> void:
	play_bond(m, id, st, show)


func _week_done() -> bool:
	var confirmed: bool = Game.flags.get("picked_%d" % Game.week, false)
	return _week_quests().is_empty() or (confirmed and m._left_quests().is_empty())


## 노라 말투: 깍듯한 존댓말, 문장마다 숫자
func _nora_line() -> String:
	var quests := _week_quests()
	var confirmed: bool = Game.flags.get("picked_%d" % Game.week, false)
	if Game.bond_ready("nora") > 0:
		return "단장님, 5분만 시간 내 주시겠어요? 드릴 말씀이 하나 있습니다."
	if quests.is_empty():
		return "지금 큰 의뢰는 0건입니다. 위탁 의뢰를 돌려 금화를 모아 두시죠."
	if not confirmed:
		var need: int = SDefs.WEEK_PICKS - Game.picks.size()
		if Game.picks.is_empty():
			return "게시판에 의뢰가 %d건 붙었습니다. 이번엔 %d건만 고르실 수 있어요." % [quests.size(), SDefs.WEEK_PICKS]
		return "%d건 더 고르시면 됩니다. 마감은 웃는 얼굴로 기다릴게요." % need
	var left: Array = m._left_quests()
	if left.is_empty():
		return "이번 일정 끝났습니다. 장부 정리하시죠."
	return "준비 끝났습니다. '%s'부터 출발하시죠. 남은 의뢰 %d건입니다." % [SDefs.QUESTS[left[0]].name, left.size()]


# ── 아래 메뉴 ──

func _dock(s: Control) -> void:
	var h := K.hbox(8)
	h.anchor_top = 1.0
	h.anchor_bottom = 1.0
	h.offset_left = K.px(30)
	h.offset_bottom = -K.px(26)
	h.grow_vertical = Control.GROW_DIRECTION_BEGIN
	s.add_child(h)
	var idle := Game.jobs.filter(func(j): return j.crew.is_empty()).size()
	var items := [
		["i_people", "동료", 0, m.mates.show.bind("")],
		["i_scroll", "위탁 의뢰", idle if not Game.roster.is_empty() else 0, town.show_jobs],
		["i_scope", "스카우트", Game.applicants.size(), town.show_scout],
		["i_people", "모험가 명부", 0, town.show_roster],
		["i_hammer", "재건 공사", 1 if Game.build + 1 < G.STAGES.size() and Game.can_pay(Game.stage_cost(Game.build + 1)) else 0, town.show_build],
		["i_book", "연대기", 0, m._show_book],
		["i_town", "마을로", 0, town.show_town],
	]
	for i in items.size():
		var it: Array = items[i]
		h.add_child(K.tile(it[0], it[1], ROMAN[i], it[2], it[3]))
	_slide_in(h, Vector2(0, K.px(30)))


## 등장: 살짝 밀려 들어오며 나타난다
func _slide_in(c: Control, from: Vector2) -> void:
	c.modulate.a = 0.0
	await m.get_tree().process_frame
	if not is_instance_valid(c):
		return
	var to := c.position
	c.position = to + from
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, 0.28)
	tw.tween_property(c, "position", to, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
