extends SceneTree
## 전투 자동 시뮬레이션 (화면 없음). 단순 AI끼리 싸워서 라운드 수와 승률을 잰다.
## 실행: godot --headless --path godot -s res://scripts/sim.gd
## 아군 AI는 운명 주사위와 환경 콤보를 쓰지 않으므로, 사람이 하면 이보다 빨리 끝나야 정상이다.

const Battle = preload("res://scripts/battle.gd")

const MAPS := [
	"res://maps/bt_ch1_forest_ambush.txt",
	"res://maps/bt_ch1_forest_clearing.txt",
	"res://maps/bt_ch1_village_outskirts.txt",
	"res://maps/bt_ch1_bandit_cliff.txt",
]
const PARTIES := [
	["lina", "cecile", "adelheid"],
	["lina", "adelheid", "miriam"],
	["cecile", "adelheid", "miriam"],
]
const N := 200


func _init() -> void:
	for m in MAPS:
		print(m.get_file().get_basename())
		for p in PARTIES:
			var wins := 0
			var rounds := 0
			var downs := 0
			var legend_hits := {}
			for i in N:
				var b = Battle.new()
				b.setup(m, p)
				while b.result == "" and b.round_no < 20:
					b.begin_ally_turn()
					for a in b.side_units("ally"):
						b.auto_act(a)
					if b.result != "":
						break
					b.end_ally_turn()
					b.begin_enemy_turn()
					for e in b.side_units("enemy"):
						b.enemy_act(e)
					b.end_enemy_turn()
					b.end_round()
					b.events.clear()
				if b.result == "win":
					wins += 1
					rounds += b.round_no
				downs += b.downs
				for lg in b.legends:
					if lg["done"]:
						legend_hits[lg["kind"]] = legend_hits.get(lg["kind"], 0) + 1
			var avg := float(rounds) / maxf(1.0, float(wins))
			var lgs: Array = []
			for k in legend_hits.keys():
				lgs.append("%s %d%%" % [k, roundi(legend_hits[k] * 100.0 / N)])
			print("  %-28s 승률 %3d%%  승리까지 평균 %.1f라운드  쓰러짐 평균 %.1f회  전설: %s" % [", ".join(PackedStringArray(p)), roundi(wins * 100.0 / N), avg, float(downs) / N, ", ".join(PackedStringArray(lgs))])
	quit()
