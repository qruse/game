extends Node
## 전투 자동 시뮬레이션 (화면 없음). 동료는 auto_act 로 움직인다.
## 실행: godot --headless --path godot res://sims/battle_sim.tscn
## 성장 단계별(1레벨 맨몸 / 3레벨 + 철 무기) 승률, 라운드, 쓰러짐, 남은 체력, 행동 비율을 찍는다.

const Battle = preload("res://scripts/fk_battle.gd")
const Defs = preload("res://scripts/fk_defs.gd")

const N := 400
const POTIONS := 1  # 들고 가는 회복약 (처음에 2개를 주고, 한 의뢰 전투 두 번에 나눠 쓴다고 보고 1)
const PARTY := ["lina", "cecile", "adelheid"]
const GROWTH := [
	["1레벨 맨몸", 1, 0, 0],
	["2레벨 · 철 무기", 2, 1, 0],
	["3레벨 · 철 무기+1 · 철 갑옷", 3, 1, 1],
]


func _ready() -> void:
	if "--log" in OS.get_cmdline_user_args():
		_one(int(OS.get_cmdline_user_args()[-1]))
		get_tree().quit()
		return
	for bi in Defs.BATTLES.size():
		print("■ %s" % Defs.BATTLES[bi].name)
		for gr in GROWTH:
			Game.reset()
			for k in PARTY:
				Game.heroes[k].lv = gr[1]
				Game.heroes[k].weapon = [gr[2], 1 if gr[1] >= 3 else 0]
				Game.heroes[k].armor = [gr[3], 0]
			_run(bi, gr[0])
	get_tree().quit()


func _run(bi: int, label: String) -> void:
	var wins := 0
	var rounds := 0.0
	var downs := 0.0
	var hp_left := 0.0
	var acts := {}
	var close := 0  # 이겼지만 누가 쓰러졌거나 체력 30% 아래로 끝난 판
	for i in N:
		var b = Battle.new()
		b.setup(bi, PARTY)
		b.fate = 2
		b.potions = POTIONS
		while b.result == "" and b.round_no < 30:
			var u = b.advance()
			if u == null:
				b.end_round()
				continue
			if b.begin_turn(u):
				if u.side == "ally":
					b.auto_act(u)
					for ev in b.events:
						if ev.t == "log" and ev.text.begins_with(u.name + " "):
							var k: String = ev.text.substr(u.name.length() + 1).get_slice(":", 0).get_slice(" ", 0)
							acts[k] = acts.get(k, 0) + 1
							break
				else:
					b.enemy_act(u)
			b.end_turn(u)
			b.events.clear()
		var tot := 0.0
		var mx := 0.0
		for u in b.side_units("ally", true):
			tot += u.hp
			mx += u.max_hp
		if b.result == "win":
			wins += 1
			rounds += b.round_no
			hp_left += tot / mx
			if b.downs > 0 or tot / mx < 0.3:
				close += 1
		downs += b.downs
	var top: Array = acts.keys()
	top.sort_custom(func(a, c): return acts[a] > acts[c])
	var at: Array = []
	for k in top.slice(0, 6):
		at.append("%s %d%%" % [k, roundi(acts[k] * 100.0 / maxf(1, _sum(acts)))])
	print("  %-26s 승률 %3d%% · %.1f라운드 · 쓰러짐 %.2f · 남은 체력 %d%% · 아슬아슬 %d%%" % [label, roundi(wins * 100.0 / N), rounds / maxf(1, wins), downs / N, roundi(hp_left * 100 / maxf(1, wins)), roundi(close * 100.0 / maxf(1, wins))])
	print("    행동: " + ", ".join(PackedStringArray(at)))


func _sum(d: Dictionary) -> int:
	var s := 0
	for k in d:
		s += d[k]
	return s


## 한 판 전체 로그 (1레벨): -- --log <전투 번호>
func _one(bi: int) -> void:
	Game.reset()
	var b = Battle.new()
	b.setup(bi, PARTY)
	b.fate = 2
	var last_round := 0
	while b.result == "" and b.round_no < 30:
		if b.round_no != last_round:
			last_round = b.round_no
			var hp: Array = []
			for u in b.units:
				if not u.removed:
					hp.append("%s %d/%d" % [u.name, u.hp, u.max_hp])
			print("── %d라운드 · 행운 %d · %s" % [b.round_no, b.fate, ", ".join(PackedStringArray(hp))])
		var u = b.advance()
		if u == null:
			b.end_round()
			for ev in b.events:
				if ev.t == "log":
					print(ev.text)
			b.events.clear()
			continue
		if b.begin_turn(u):
			if u.side == "ally":
				b.auto_act(u)
			else:
				b.enemy_act(u)
		b.end_turn(u)
		for ev in b.events:
			if ev.t == "log":
				print(ev.text)
		b.events.clear()
	print("결과 %s" % b.result)