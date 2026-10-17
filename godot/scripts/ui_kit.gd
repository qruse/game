extends RefCounted
## 디자인 규칙과 공용 부품 (확정 시안: design/mockups/guild_desk_v5.html).
## 하웰 파랑 + 놋쇠 + 남색 판, 의뢰서(봉랍 인장 · 절취선 · 채택 도장), 로마 숫자.
## 크기는 시안(1600×900) px 로 적고 px() 가 화면 크기로 바꾼다.

const UI = preload("res://scripts/fk_ui.gd")

const NAVY := Color(0.051, 0.075, 0.133, 0.86)
const NAVY_2 := Color(0.086, 0.125, 0.212, 0.94)
const HOLE := Color(0.04, 0.055, 0.1)  # 의뢰서 구멍 (판 뒤 색)
const BLUE := Color("2f5fb8")
const BLUE_HI := Color("4c7fd8")
const BLUE_DK := Color("244c98")
const BRASS := Color("cfa75c")
const BRASS_HI := Color("f0d596")
const BRASS_DK := Color("8a6a2e")
const LINE := Color(0.81, 0.655, 0.36, 0.32)
const HAIR := Color(1, 1, 1, 0.07)
const PAPER := Color("efe6d3")
const PAPER_SEL := Color("fbf5e6")
const INK := Color("1e170f")
const INK_2 := Color("5f503c")
const WHITE := Color("eef0f4")
const DIM := Color("9ba4b5")
const WAX := Color("b7342b")
const BAD := Color("ff9b86")
const GOOD := Color("9fdc8f")
const SHADE := Color(0.03, 0.04, 0.08)

static var k := 1.2  # 시안 px → 화면 px (데스크톱 1920 기준)
static var touch := false
static var f_title: Font  # 송명: 화면 제목, 이름
static var f_num: Font  # 함렛: 숫자, 로마 숫자
static var f_body: Font  # Noto 520
static var f_bold: Font  # Noto 700
static var f_cap: Font  # Noto 600 + 자간 (작은 머리말)


static func setup(is_touch: bool, body: Font, bold: Font) -> void:
	touch = is_touch
	k = 0.68 if touch else 1.2
	f_body = body
	f_bold = bold
	f_title = _font("res://fonts/SongMyung-Game.ttf", bold)
	f_num = _font("res://fonts/Hahmlet-Game.ttf", bold)
	var cap := FontVariation.new()
	cap.base_font = (body as FontVariation).base_font if body is FontVariation else body
	cap.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 620}
	cap.spacing_glyph = 2
	f_cap = cap
	var nv := FontVariation.new()
	nv.base_font = f_num
	nv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 650}
	nv.fallbacks = [bold]
	f_num = nv
	var tv := FontVariation.new()
	tv.base_font = f_title
	tv.fallbacks = [bold]
	f_title = tv


## 게임 전체 테마를 새 규칙으로 (기존 화면의 Button · PanelContainer 도 같은 모양이 된다)
static func apply_theme(th: Theme) -> void:
	th.set_stylebox("normal", "Button", sb_flat(NAVY, LINE, 1))
	th.set_stylebox("hover", "Button", sb_flat(NAVY_2, BRASS, 1))
	th.set_stylebox("pressed", "Button", sb_flat(Color(0.03, 0.05, 0.1, 0.95), BRASS_HI, 1))
	th.set_stylebox("disabled", "Button", sb_flat(Color(0.05, 0.07, 0.12, 0.6), Color(1, 1, 1, 0.08), 1))
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb: StyleBoxFlat = th.get_stylebox(st, "Button")
		sb.content_margin_left = px(16)
		sb.content_margin_right = px(16)
		sb.content_margin_top = px(8)
		sb.content_margin_bottom = px(8)
	th.set_color("font_color", "Button", Color("e6e9ef"))
	th.set_color("font_hover_color", "Button", BRASS_HI)
	th.set_color("font_pressed_color", "Button", BRASS_HI)
	th.set_color("font_disabled_color", "Button", Color(0.55, 0.58, 0.64))
	th.set_stylebox("panel", "PanelContainer", sb_panel(20, NAVY, LINE, 22))
	th.set_stylebox("panel", "Panel", sb_panel(20, NAVY, LINE, 12))
	th.set_color("font_color", "Label", WHITE)
	th.set_color("default_color", "RichTextLabel", WHITE)
	var tip := sb_flat(Color(0.04, 0.06, 0.11, 0.96), LINE, 1)
	tip.set_content_margin_all(px(10))
	th.set_stylebox("panel", "TooltipPanel", tip)
	th.set_color("font_color", "TooltipLabel", WHITE)
	var grab := sb_flat(Color(BRASS, 0.5))
	grab.set_corner_radius_all(pxi(3))
	th.set_stylebox("grabber", "VScrollBar", grab)
	th.set_stylebox("grabber_highlight", "VScrollBar", sb_flat(BRASS))
	th.set_stylebox("scroll", "VScrollBar", sb_flat(Color(1, 1, 1, 0.04)))


static func _font(path: String, fallback: Font) -> Font:
	return load(path) if ResourceLoader.exists(path) else fallback


static func px(v: float) -> float:
	return v * k


static func pxi(v: float) -> int:
	return roundi(v * k)


# ── 글자 ──

static func label(text: String, size: float, col := WHITE, font: Font = null, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font != null else f_body)
	# 모바일(960×540)에서 아주 작은 글자는 읽히지 않으니 9px 아래로 내리지 않는다
	l.add_theme_font_size_override("font_size", maxi(pxi(size), 9 if touch else 0))
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func cap(text: String, col := BRASS) -> Label:
	return label(text, 12, col, f_cap)


static func title(text: String, size := 32.0, col := Color.WHITE) -> Label:
	var l := label(text, size, col, f_title)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", pxi(2))
	l.add_theme_constant_override("shadow_outline_size", pxi(6))
	return l


static func num(text: String, size: float, col := WHITE) -> Label:
	return label(text, size, col, f_num)


static func bold(text: String, size: float, col := WHITE) -> Label:
	return label(text, size, col, f_bold)


## 그림자 진한 글자 (그림 위에 바로 놓일 때)
static func shadowed(l: Label) -> Label:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_y", pxi(2))
	l.add_theme_constant_override("shadow_outline_size", pxi(8))
	return l


# ── 판 ──

## 남색 판. cut = 왼쪽 위 깎은 모서리 (시안 px)
static func sb_panel(cut := 20.0, bg := NAVY, border := LINE, pad := 22.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(maxi(1, pxi(1)))
	sb.corner_radius_top_left = pxi(cut)
	sb.corner_detail = 1
	sb.anti_aliasing = true
	sb.set_content_margin_all(px(pad))
	return sb


static func sb_flat(bg: Color, border := Color.TRANSPARENT, bw := 0.0, cut_tl := 0.0, cut_tr := 0.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	if bw > 0:
		sb.set_border_width_all(maxi(1, pxi(bw)))
	sb.corner_radius_top_left = pxi(cut_tl)
	sb.corner_radius_top_right = pxi(cut_tr)
	sb.corner_detail = 1
	return sb


## 남색 카드: 판 + 위쪽 놋쇠 줄. 내용만큼 커진다
static func card(cut := 20.0, pad := 22.0) -> Card:
	var c := Card.new()
	c.sb = sb_panel(cut, NAVY, LINE, pad)
	c.cut = px(cut)
	c.line_w = maxf(2.0, px(2))
	for side in ["left", "top", "right", "bottom"]:
		c.add_theme_constant_override("margin_" + side, pxi(pad))
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	return c


class Card extends MarginContainer:
	var sb: StyleBox
	var cut := 0.0
	var line_w := 2.0
	var accent := true

	func _draw() -> void:
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		if accent:
			var w := (size.x - cut) * 0.7
			var c0 := BRASS
			var c1 := Color(BRASS, 0.0)
			draw_polygon(PackedVector2Array([Vector2(cut, 0), Vector2(cut + w, 0), Vector2(cut + w, line_w), Vector2(cut, line_w)]), PackedColorArray([c0, c1, c1, c0]))


## 가로 그라데이션 사각형 (띠 없이 매끈하게: 꼭짓점 색 보간)
static func hgrad(ci: CanvasItem, r: Rect2, stops: Array, cols: Array) -> void:
	for i in stops.size() - 1:
		var x0: float = r.position.x + r.size.x * stops[i]
		var x1: float = r.position.x + r.size.x * stops[i + 1]
		var pts := PackedVector2Array([Vector2(x0, r.position.y), Vector2(x1, r.position.y), Vector2(x1, r.end.y), Vector2(x0, r.end.y)])
		ci.draw_polygon(pts, PackedColorArray([cols[i], cols[i + 1], cols[i + 1], cols[i]]))


static func vbox(sep := 10.0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", pxi(sep))
	return v


static func hbox(sep := 10.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", pxi(sep))
	return h


static func spacer(w := 0.0, h := 0.0, expand := false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px(w), px(h))
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func icon(name: String, sz: float, col := WHITE) -> TextureRect:
	var t := TextureRect.new()
	t.texture = UI.tex(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px(sz), px(sz))
	t.modulate = col
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


# ── 버튼 ──

## 버튼 바탕: 글자는 안쪽 상자(content)에 직접 넣는다. {button, box}
static func _button(styles: Dictionary, h: float, cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, px(h))
	for st in styles:
		b.add_theme_stylebox_override(st, styles[st])
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(cb)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func _inner(b: Button, sep := 10.0) -> HBoxContainer:
	var h := hbox(sep)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	return h


## 주 버튼: 하웰 파랑 + 놋쇠 테, 오른쪽 위 깎은 모서리. ◆ 제목 · 작은 설명
static func btn_main(text: String, sub: String, cb: Callable, h := 54.0) -> Button:
	var mk := func(bg: Color, border: Color) -> StyleBoxFlat:
		var sb := sb_flat(bg, border, 1, 0, 14)
		sb.shadow_color = Color(0.07, 0.16, 0.36, 0.5)
		sb.shadow_size = pxi(10)
		sb.shadow_offset = Vector2(0, px(6))
		return sb
	var b := _button({
		"normal": mk.call(BLUE, Color(BRASS_HI, 0.7)),
		"hover": mk.call(BLUE_HI, BRASS_HI),
		"pressed": mk.call(BLUE_DK, BRASS_HI),
		"disabled": sb_flat(Color(0.16, 0.2, 0.28, 0.9), Color(1, 1, 1, 0.12), 1, 0, 14),
	}, h, cb)
	var box := _inner(b)
	box.add_child(Diamond.make(px(8), BRASS_HI))
	var l := bold(text, 17, Color.WHITE)
	box.add_child(l)
	if sub != "":
		box.add_child(label(sub, 13, Color("cfdcf6")))
	b.set_meta("box", box)
	b.set_meta("label", l)
	return b


## 보조 버튼: 테두리만, 놋쇠 글자
static func btn_sub(text: String, icon_name: String, cb: Callable, h := 54.0, w := 156.0) -> Button:
	var b := _button({
		"normal": sb_flat(Color(1, 1, 1, 0.03), LINE, 1),
		"hover": sb_flat(Color(1, 1, 1, 0.08), BRASS, 1),
		"pressed": sb_flat(Color(0, 0, 0, 0.2), BRASS, 1),
		"disabled": sb_flat(Color(1, 1, 1, 0.02), Color(1, 1, 1, 0.08), 1),
	}, h, cb)
	b.custom_minimum_size.x = px(w)
	var box := _inner(b, 8)
	if icon_name != "":
		box.add_child(icon(icon_name, 20, BRASS_HI))
	if text != "":
		var l := bold(text, 17, BRASS_HI)
		box.add_child(l)
		b.set_meta("label", l)
	return b


## 줄 버튼 (선택지 등): 내용을 직접 넣는 남색 줄. 글이 길면 줄이 높아진다
static func pick(cb: Callable, pad := 14.0) -> Pick:
	var p := Pick.new()
	p.cb = cb
	for side in ["left", "top", "right", "bottom"]:
		p.add_theme_constant_override("margin_" + side, pxi(pad if side in ["top", "bottom"] else pad + 4))
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return p


class Pick extends MarginContainer:
	var cb: Callable
	var hot := false
	var disabled := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func():
			hot = true
			queue_redraw())
		mouse_exited.connect(func():
			hot = false
			queue_redraw())

	func _gui_input(ev: InputEvent) -> void:
		if disabled:
			return
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			cb.call()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var on := hot and not disabled
		draw_rect(r, Color(0.09, 0.14, 0.25, 0.95) if on else Color(1, 1, 1, 0.035))
		draw_rect(r, BRASS if on else LINE, false, 1.0)
		draw_rect(Rect2(0, 0, 3.0, size.y), BLUE_HI if on else Color(BRASS, 0.55))


## 작은 칩: 색 바탕 + 글자
static func chip(text: String, bg: Color, fg := Color.WHITE, size := 12.0) -> Label:
	var l := label(text, size, fg, f_bold)
	var sb := sb_flat(bg)
	sb.content_margin_left = px(8)
	sb.content_margin_right = px(8)
	sb.content_margin_top = px(1)
	sb.content_margin_bottom = px(2)
	l.add_theme_stylebox_override("normal", sb)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


## 놋쇠 가는 줄 (가로)
static func hr(col := HAIR) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 화면 그늘: dir 쪽(왼쪽 "l" / 아래 "b" / 위 "t")이 진하고 반대로 옅어진다
static func shade(parent: Control, dir: String, alpha: float, reach := 0.6) -> TextureRect:
	var g := TextureRect.new()
	var gt := GradientTexture2D.new()
	match dir:
		"l":
			gt.fill_from = Vector2(0, 0)
			gt.fill_to = Vector2(1, 0)
		"b":
			gt.fill_from = Vector2(0, 1)
			gt.fill_to = Vector2(0, 0)
		"t":
			gt.fill_from = Vector2(0, 0)
			gt.fill_to = Vector2(0, 1)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, reach * 0.45, reach])
	gr.colors = PackedColorArray([Color(SHADE, alpha), Color(SHADE, alpha * 0.6), Color(SHADE, 0.0)])
	gt.gradient = gr
	g.texture = gt
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(g)
	return g


## 행운 주사위 줄: 파란 마름모 (남은 것) / 빈 마름모
static func luck_row(n: int, max_n: int, sz := 9.0) -> HBoxContainer:
	var h := hbox(6)
	for i in max_n:
		h.add_child(Diamond.make(px(sz), BLUE_HI if i < n else Color(BRASS, 0.6), i < n, i < n))
	return h


## 아래 메뉴 칸: 아이콘 + 이름 + 로마 숫자 (+ 붉은 숫자)
static func tile(icon_name: String, text: String, numeral: String, badge_n: int, cb: Callable) -> Button:
	var normal := sb_flat(NAVY, LINE, 1, 12)
	var hover := sb_flat(PAPER, Color.TRANSPARENT, 0, 12)
	hover.border_color = BLUE
	hover.border_width_top = pxi(3)
	var b := _button({"normal": normal, "hover": hover, "pressed": hover, "disabled": normal}, 100, cb)
	b.custom_minimum_size.x = px(112)
	var v := vbox(8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var ic := icon(icon_name, 30, Color("e8ecf3"))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var l := bold(text, 14, Color("dfe3ea"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var nm := num(numeral, 12, Color(BRASS, 0.8))
	nm.position = Vector2(px(112 - 12) - px(14) * numeral.length() * 0.5, px(5))
	b.add_child(nm)
	if badge_n > 0:
		var bd := badge(str(badge_n))
		bd.position = Vector2(px(12), px(6))
		b.add_child(bd)
	# 마우스를 올리면 밝은 종이색 + 파란 아이콘, 살짝 뜬다
	b.mouse_entered.connect(func():
		ic.modulate = BLUE
		l.add_theme_color_override("font_color", INK)
		nm.add_theme_color_override("font_color", INK_2)
		b.create_tween().tween_property(v, "position:y", -px(4), 0.08))
	b.mouse_exited.connect(func():
		ic.modulate = Color("e8ecf3")
		l.add_theme_color_override("font_color", Color("dfe3ea"))
		nm.add_theme_color_override("font_color", Color(BRASS, 0.8))
		b.create_tween().tween_property(v, "position:y", 0.0, 0.1))
	return b


## 붉은 숫자 동그라미
static func badge(text: String) -> Label:
	var l := bold(text, 12, Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = WAX
	sb.set_corner_radius_all(pxi(10))
	sb.content_margin_left = px(6)
	sb.content_margin_right = px(6)
	sb.border_color = Color(0.04, 0.05, 0.09, 0.8)
	sb.set_border_width_all(pxi(2))
	l.add_theme_stylebox_override("normal", sb)
	l.custom_minimum_size = Vector2(px(22), px(22))
	return l


# ── 작은 그림 ──

## 마름모 (◆ 켜짐 / ◇ 꺼짐)
class Diamond extends Control:
	var on := true
	var col := BRASS_HI
	var glow := false

	## sz: 화면 px (px() 를 거친 값)
	static func make(sz: float, c: Color, is_on := true, glow_on := false) -> Diamond:
		var d := Diamond.new()
		d.col = c
		d.on = is_on
		d.glow = glow_on
		d.custom_minimum_size = Vector2(sz, sz) * 1.42
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return d

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		if glow and on:
			for i in 3:
				var g := r * (1.4 + i * 0.35)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -g), c + Vector2(g, 0), c + Vector2(0, g), c + Vector2(-g, 0)]), Color(col, 0.12))
		if on:
			draw_colored_polygon(pts, col)
		else:
			pts.append(pts[0])
			draw_polyline(pts, col, maxf(1.0, r * 0.22), true)


## 봉랍 인장 (crown / dawn / scales / rat)
static func seal(kind: String, sz: float, small := true) -> TextureRect:
	var t := icon("seal_%s%s" % [kind, "_s" if small else ""], sz)
	t.modulate = Color.WHITE
	return t
