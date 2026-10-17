extends RefCounted
## 전투 화면 UI 조각: 틀 그림 불러오기, 차례 줄(초상 동그라미), 동료 카드 아래 막대.
## 그림은 tools/ui/ui_svg.py 로 그려 godot/ui 에 둔다

const DIR := "res://ui/"
const CREAM := Color(0.95, 0.90, 0.78)
const GOLD := Color(0.94, 0.80, 0.45)


static func tex(name: String) -> Texture2D:
	var p := DIR + name + ".png"
	return load(p) if ResourceLoader.exists(p) else null


static func sbt(name: String, margin: float, content: float) -> StyleBox:
	var t := tex(name)
	if t == null:
		var f := StyleBoxFlat.new()
		f.bg_color = Color(0.15, 0.12, 0.1)
		f.set_content_margin_all(content)
		return f
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.set_texture_margin_all(margin)
	sb.set_content_margin_all(content)
	return sb


## 게임 전체 테마 (전투·이야기 화면 공용). {theme, bold}
static func make_theme(touch: bool) -> Dictionary:
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
	var bold := FontVariation.new()
	bold.base_font = base
	bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	# 버튼과 판넬은 tools/ui 로 그린 틀
	var m := 9.0 if touch else 12.0
	for st in [["normal", "btn_normal"], ["hover", "btn_hover"], ["pressed", "btn_pressed"], ["disabled", "btn_disabled"]]:
		th.set_stylebox(st[0], "Button", sbt(st[1], 18, m))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", CREAM)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", GOLD)
	th.set_color("font_disabled_color", "Button", Color(0.5, 0.46, 0.42))
	th.set_font("font", "Button", bold)
	th.set_stylebox("panel", "PanelContainer", sbt("panel", 30, 12.0 if touch else 18.0))
	th.set_stylebox("panel", "Panel", sbt("panel", 30, 12))
	th.set_color("font_color", "Label", CREAM)
	th.set_color("default_color", "RichTextLabel", CREAM)
	th.set_font("bold_font", "RichTextLabel", bold)
	return {"theme": th, "bold": bold}


## 막대와 초상 동그라미를 그리는 공통 바탕 (색은 ui_kit 규칙: 남색 · 놋쇠 · 하웰 파랑)
class UIBase extends Control:
	const CREAM := Color("eef0f4")
	const GOLD := Color("f0d596")
	const NAVY := Color(0.04, 0.06, 0.11)
	const BRASS := Color("cfa75c")
	const ALLY := Color("2f5fb8")
	const FOE := Color("b7342b")

	## 막대: 남색 홈 + 채움 + 윗줄 반사광 + 잃은 만큼 하얗게 남는 잔상
	func draw_bar(r: Rect2, ratio: float, ghost: float, col: Color) -> void:
		draw_rect(r.grow(1), Color(0.02, 0.03, 0.06, 0.9))
		draw_rect(r, Color(1, 1, 1, 0.08))
		if ghost > ratio:
			draw_rect(Rect2(r.position, Vector2(r.size.x * ghost, r.size.y)), Color(1.0, 0.95, 0.85, 0.75))
		var fr := Rect2(r.position, Vector2(r.size.x * clampf(ratio, 0.0, 1.0), r.size.y))
		draw_rect(fr, col)
		draw_rect(Rect2(fr.position, Vector2(fr.size.x, maxf(1.0, r.size.y * 0.3))), Color(1, 1, 1, 0.22))


	## 원 안에 텍스처 일부(region, 0~1 비율)를 채워 그린다 (초상 동그라미)
	func draw_face(c: Vector2, r: float, t: Texture2D, region: Rect2, mod := Color.WHITE) -> void:
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for j in 40:
			var a := TAU * j / 40.0
			var d := Vector2(cos(a), sin(a))
			pts.append(c + d * r)
			uvs.append(region.position + (d * 0.5 + Vector2(0.5, 0.5)) * region.size)
		draw_colored_polygon(pts, mod, uvs, t)


## 위쪽 가운데 차례 줄: 지금 차례는 크게 금테, 동료는 파랑, 적은 빨강
class TurnBar extends UIBase:
	var battle = null
	var faces := {}  # uid -> Texture2D (SD 대기)
	var font: Font

	func _draw() -> void:
		if battle == null:
			return
		var items: Array = []
		for i in range(battle.turn_idx, battle.order.size()):
			var u = battle.unit(battle.order[i])
			if u != null and u.alive():
				items.append(u)
		if items.is_empty():
			return
		var r := size.y * 0.34
		var big := r * 1.3
		var step := r * 2.35
		var total := big * 2.0 + step * (items.size() - 1) + r * 0.4
		var x := (size.x - total) / 2.0 + big
		var cy := size.y * 0.46
		# 바탕 띠: 남색 + 아래 놋쇠 줄
		var band := Rect2(x - big - r * 0.6, cy - r * 1.05, total + r * 0.8, r * 2.1)
		draw_rect(band, Color(NAVY, 0.72))
		draw_line(Vector2(band.position.x, band.end.y), Vector2(band.end.x, band.end.y), Color(BRASS, 0.5), 1.0)
		for i in items.size():
			var u = items[i]
			var cur := i == 0
			var rr := big if cur else r
			var c := Vector2(x, cy)
			var team := ALLY if u.side == "ally" else FOE
			draw_circle(c, rr + 3.0, NAVY)
			draw_circle(c, rr, team.darkened(0.45))
			var t: Texture2D = faces.get(u.uid)
			if t != null:
				# SD 512 캔버스의 머리 부분
				var reg := Rect2(0.2, 0.03, 0.6, 0.6)
				if u.key == "wolf":
					reg = Rect2(0.0, 0.25, 0.6, 0.6)
				elif u.key == "boar":
					reg = Rect2(0.0, 0.32, 0.55, 0.55)
				draw_face(c, rr - 1.0, t, reg)
			else:
				draw_string(font, c + Vector2(-rr, rr * 0.35), u.name.substr(0, 1), HORIZONTAL_ALIGNMENT_CENTER, rr * 2.0, int(rr), Color.WHITE)
			draw_arc(c, rr, 0.0, TAU, 48, GOLD if cur else team.lightened(0.25), 4.0 if cur else 2.5, true)
			if cur:
				# 지금 차례: 아래 놋쇠 마름모
				var dc := Vector2(c.x, c.y + rr + 10.0)
				draw_colored_polygon(PackedVector2Array([dc + Vector2(0, -6), dc + Vector2(6, 0), dc + Vector2(0, 6), dc + Vector2(-6, 0)]), GOLD)
			x += (big + r * 1.15) if cur else step


## 동료 카드 아래: 이름, HP, 결의, 상태 아이콘
class CardBars extends UIBase:
	var battle = null
	var u = null
	var font: Font
	var bold: Font
	var st_icons := {}
	var compact := false

	func _draw() -> void:
		if u == null or battle == null:
			return
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color(NAVY, 0.92))
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x * 0.75, 0), Vector2(size.x * 0.75, 2), Vector2(0, 2)]),
			PackedColorArray([BRASS, Color(BRASS, 0), Color(BRASS, 0), BRASS]))
		var fs := 15 if compact else 22
		var pad := 8.0 if compact else 12.0
		var y := pad + fs
		draw_string_outline(bold, Vector2(pad, y), u.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs + 2, 4, Color(0, 0, 0, 0.6))
		draw_string(bold, Vector2(pad, y), u.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs + 2, GOLD)
		var sub: String = u.role if u.role != "" else "적"
		draw_string(font, Vector2(pad, y), sub, HORIZONTAL_ALIGNMENT_RIGHT, size.x - pad * 2.0, fs - 4, Color("9ba4b5"))
		var bw := size.x - pad * 2.0
		var bh := 8.0 if compact else 12.0
		var by := y + (6.0 if compact else 10.0)
		var hp_col := Color("6fcf6a") if u.side == "ally" else Color("e0574a")
		draw_bar(Rect2(pad, by, bw, bh), float(u.hp) / u.max_hp, 0.0, hp_col)
		var hp_txt := "HP %d / %d" % [u.hp, u.max_hp]
		draw_string_outline(font, Vector2(pad, by + bh + fs - 2), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 4, 2, Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(pad, by + bh + fs - 2), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 4, CREAM)
		var info := "방어 %d · 속도 %d" % [battle.eff_def(u), u.spd]
		draw_string(font, Vector2(pad, by + bh + fs - 2), info, HORIZONTAL_ALIGNMENT_RIGHT, bw, fs - 5, Color("9ba4b5"))
		var ry := by + bh + fs + (4.0 if compact else 8.0)
		if u.side == "ally" and ry + 6 < h:
			draw_bar(Rect2(pad, ry, bw, 5.0 if compact else 6.0), u.resolve / 100.0, 0.0, Color("4c7fd8") if u.resolve < 100 else GOLD)
		# 상태 아이콘 (오른쪽 위)
		var sx := size.x - pad
		for k in u.st.keys():
			if u.st[k] <= 0 or not st_icons.has(k):
				continue
			var s := 20.0 if compact else 28.0
			sx -= s + 2.0
			draw_texture_rect(st_icons[k], Rect2(sx, -s - 4.0, s, s), false)
