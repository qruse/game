extends RefCounted
## NPC 대화 화면 (니케 상담식, docs/04-game-flow.md 6.5절)
## 일반 대화: 그림을 누르면 한 줄. 호감도 대화: 한 주에 한 번, 질문 하나 + 대답 둘 → 반응 + 호감도

const K = preload("res://scripts/ui_kit.gd")
const T = preload("res://scripts/talk_defs.gd")
const SDefs = preload("res://scripts/story_defs.gd")
const G = preload("res://scripts/guild_defs.gd")


## 일반 대화 한 줄 (방금 한 말은 다시 안 한다)
static func idle_line(id: String) -> String:
	var ls: Array = T.TALKS[id].idle
	var key := "idle_" + id
	var last: int = Game.flags.get(key, -1)
	var i := randi() % ls.size()
	if ls.size() > 1 and i == last:
		i = (i + 1) % ls.size()
	Game.flags[key] = i
	return ls[i]


## 이번 주 호감도 대화를 아직 안 했나
static func can_talk(id: String) -> bool:
	return not Game.flags.get("talk_%s_%d" % [id, Game.week], false)


static func portrait(id: String, expr: String) -> Texture2D:
	var path: String = SDefs.SPEAKERS[id].path
	var t: Texture2D = Game.tex(path % expr)
	return t if t != null else Game.tex(path % "neutral")


## 호감도 대화 버튼 (이번 주에 했으면 꺼진다)
static func button(main, id: String, back: Callable, h := 42.0, w := 150.0) -> Button:
	var on := can_talk(id)
	var b := K.btn_sub("호감도 대화" if on else "이번 주 대화 끝", "i_chat", func(): open(main, id, back), h, w)
	b.disabled = not on
	b.tooltip_text = "한 주에 한 번. 대답에 따라 호감도가 %d 또는 %d 오른다" % [T.GOOD, T.OK]
	return b


## 호감도 대화 열기: 어두운 막 + 큰 스탠딩 + 아래 대사 + 오른쪽 대답 둘
static func open(main, id: String, back: Callable) -> void:
	if not can_talk(id):
		return
	var b: Dictionary = G.BONDS[id]
	var list: Array = T.TALKS[id].bond
	var idx: int = int(Game.flags.get("talk_idx_" + id, 0)) % list.size()
	var item: Array = list[idx]
	# 대화 중엔 아래 화면을 숨긴다 (닫으면 back 이 화면을 다시 만든다)
	for c in main.screen.get_children():
		c.visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	main.screen.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(K.SHADE, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	# 스탠딩 (가운데 왼쪽, 무릎 아래는 대사 띠 뒤로)
	var pic := TextureRect.new()
	pic.texture = portrait(id, item[1])
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hh := K.px(1260)
	var tw: float = hh * 2.0 / 3.0
	if pic.texture != null:
		tw = hh * pic.texture.get_width() / pic.texture.get_height()
	pic.anchor_left = 0.36
	pic.anchor_right = 0.36
	pic.anchor_top = 1.0
	pic.anchor_bottom = 1.0
	pic.offset_left = -tw / 2.0
	pic.offset_right = tw / 2.0
	pic.offset_top = -hh + K.px(420)
	pic.offset_bottom = K.px(420)
	root.add_child(pic)
	K.shade(root, "b", 0.95, 0.42)
	# 왼쪽 위: 머리말
	var head := K.vbox(2)
	head.position = Vector2(K.px(30), K.px(26))
	root.add_child(head)
	head.add_child(K.shadowed(K.cap("호감도 대화 · 한 주에 한 번")))
	var hh2 := K.hbox(10)
	hh2.add_child(K.shadowed(K.title(b.name, 30)))
	var seen: int = Game.bond_seen.get(id, 0)
	for i in 3:
		hh2.add_child(K.Diamond.make(K.px(7), K.BRASS_HI, i < seen, i < seen))
	head.add_child(hh2)
	# 아래: 이름 + 대사
	var v := K.vbox(10)
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.anchor_top = 1.0
	v.anchor_bottom = 1.0
	v.offset_left = -K.px(560)
	v.offset_right = K.px(560)
	v.offset_top = -K.px(200)
	v.offset_bottom = -K.px(40)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(v)
	var nh := K.hbox(14)
	nh.add_child(K.title(SDefs.SPEAKERS[id].name, 28, K.BRASS_HI))
	var ln := ColorRect.new()
	ln.color = Color(K.BRASS, 0.6)
	ln.custom_minimum_size = Vector2(K.px(180), 1)
	ln.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nh.add_child(ln)
	v.add_child(nh)
	var text := K.shadowed(K.label(item[0], 22, Color("f2f3f6"), null, true))
	v.add_child(text)
	_type(text)
	# 오른쪽: 대답 둘
	var ch := K.vbox(12)
	ch.anchor_left = 1.0
	ch.anchor_right = 1.0
	ch.anchor_top = 0.5
	ch.anchor_bottom = 0.5
	ch.offset_left = -K.px(30 + 470)
	ch.offset_right = -K.px(30)
	ch.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(ch)
	ch.add_child(K.shadowed(K.cap("대답을 고른다")))
	for a in item[2]:
		var p := K.pick(func(): _answer(main, root, id, a, idx, pic, text, ch, back), 16)
		var ah := K.hbox(12)
		ah.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ah.add_child(K.Diamond.make(K.px(7), K.BRASS_HI))
		var al := K.bold(a[0], 18, Color.WHITE)
		al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ah.add_child(al)
		p.add_child(ah)
		ch.add_child(p)
	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.2)


## 대답을 고르면: 반응 한 줄 + 표정 + 호감도
static func _answer(main, root: Control, id: String, a: Array, idx: int, pic: TextureRect, text: Label, ch: Control, back: Callable) -> void:
	Game.flags["talk_%s_%d" % [id, Game.week]] = true
	Game.flags["talk_idx_" + id] = idx + 1
	var before: int = Game.bond.get(id, 0)
	Game.add_bond(id, T.GOOD if a[1] else T.OK)
	var got: int = Game.bond.get(id, 0) - before
	pic.texture = portrait(id, a[3])
	text.text = a[2]
	_type(text)
	for c in ch.get_children():
		c.queue_free()
	if got > 0:
		var c := K.chip("호감도 +%d" % got, Color(K.BLUE, 0.6), Color.WHITE, 15)
		c.size_flags_horizontal = Control.SIZE_SHRINK_END
		ch.add_child(c)
	else:
		ch.add_child(K.chip("호감도가 다음 이야기 문턱에 닿아 있다", Color(K.BRASS, 0.3), K.BRASS_HI, 14))
	if Game.bond_ready(id) > 0:
		ch.add_child(K.shadowed(K.label("%s의 이야기 %s 를 볼 수 있다" % [G.BONDS[id].name, ["I", "II", "III"][Game.bond_ready(id) - 1]], 15, K.BRASS_HI)))
	var done := K.btn_main("마친다", "", func():
		root.queue_free()
		back.call(), 52)
	ch.add_child(done)


## 글자가 한 자씩 나온다
static func _type(l: Label) -> void:
	l.visible_ratio = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "visible_ratio", 1.0, clampf(l.text.length() / 38.0, 0.2, 1.6))
