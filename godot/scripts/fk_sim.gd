extends SceneTree
## 포 더 킹식 전투 자동 시뮬레이션 (화면 없음). 동료도 자동으로 움직여 승률과 라운드 수를 잰다.
## 실행: godot --headless --path godot -s res://scripts/fk_sim.gd

const Battle = preload("res://scripts/fk_battle.gd")
const Defs = preload("res://scripts/fk_defs.gd")

const PARTIES := [
	["lina", "cecile", "adelheid"],
	["lina", "adelheid", "miriam"],
	["cecile", "adelheid", "miriam"],
]
const N := 300


func _init() -> void:
	for bi in Defs.BATTLES.size():
		print(Defs.BATTLES[bi].name)
		for p in PARTIES:
			var wins := 0
			var rounds := 0
			var downs := 0
			for i in N:
				var b = Battle.new()
				b.setup(bi, p)
				while b.result == "" and b.round_no < 30:
					var u = b.advance()
					if u == null:
						b.end_round()
						continue
					if b.begin_turn(u):
						if u.side == "ally":
							b.auto_act(u)
						else:
							b.enemy_act(u)
					b.end_turn(u)
					b.events.clear()
				if b.result == "win":
					wins += 1
					rounds += b.round_no
				downs += b.downs
			print("  %-28s 승률 %3d%%  승리까지 평균 %.1f라운드  쓰러짐 평균 %.1f회" % [", ".join(PackedStringArray(p)), roundi(wins * 100.0 / N), float(rounds) / maxf(1.0, float(wins)), float(downs) / N])
	quit()
