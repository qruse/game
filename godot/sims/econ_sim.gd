extends Node
## 경제 시뮬레이션: 3장(10바퀴) 동안 재건 공사를 끝낼 수 있는지 본다 (docs/04-game-flow.md 3.8)
## 실행: godot --headless --path godot res://sims/econ_sim.tscn
## 플레이어 흉내: 지원자를 돈 되는 만큼 뽑고, 위탁 의뢰를 다 채우고, 메인 의뢰 2개(성공 80%),
## 공사 먼저, 남는 돈으로 시설·장비, 장 끝에 빚 몫을 갚는다.

const G = preload("res://scripts/guild_defs.gd")
const P = preload("res://scripts/party_defs.gd")

const RUNS := 300
const PAGES := 10
const CH_END := [3, 6, 10]  # 장이 끝나는 쪽 (그 쪽은 결전)
const FAC_PLAN := ["scout", "dorm", "scout", "board", "training", "dorm", "scout", "records", "kitchen", "armory", "training", "dorm", "scout", "armory", "records", "kitchen", "training", "armory", "kitchen", "records"]


func _ready() -> void:
	var done_at: Array = []
	var gold_by: Array = []
	var build_by: Array = []
	var fac_by: Array = []
	var gear_by: Array = []
	var collect := 0
	var inc := 0.0
	var jobs_inc := 0.0
	var dj := [0.0, 0.0, 0.0, 0.0, 0.0]
	var mats := {"wood": 0.0, "iron": 0.0, "herb": 0.0}
	for i in PAGES:
		gold_by.append(0.0)
		build_by.append(0.0)
		fac_by.append(0.0)
		gear_by.append(0.0)
	for r in RUNS:
		var res := _run()
		done_at.append(res.done)
		collect += res.collect
		inc += res.inc
		jobs_inc += res.jobs
		dj[0] += res.jobs_n
		dj[1] += res.assigned
		dj[2] += res.wins
		dj[3] += res.roster
		dj[4] += res.power
		for k in mats:
			mats[k] += Game.mats.get(k, 0)
		for i in PAGES:
			gold_by[i] += res.gold[i]
			build_by[i] += res.build[i]
			fac_by[i] += res.fac[i]
			gear_by[i] += res.gear[i]
	print("쪽  금화(평균)  공사단계  시설레벨합  장비단계합")
	for i in PAGES:
		print("%2d  %8.0f  %6.2f  %8.1f  %8.1f" % [i + 1, gold_by[i] / RUNS, build_by[i] / RUNS, fac_by[i] / RUNS, gear_by[i] / RUNS])
	done_at.sort()
	var fin := done_at.filter(func(x): return x <= PAGES).size()
	print("총수입 %.0f · 위탁 %.0f · 남은 재료 목재 %.1f 철 %.1f 약초 %.1f" % [inc / RUNS, jobs_inc / RUNS, mats.wood / RUNS, mats.iron / RUNS, mats.herb / RUNS])
	print("쪽당 위탁 %.1f건 · 맡김 %.1f · 성공 %.1f · 명부 %.1f명 · 평균 실력 %.0f" % [dj[0] / RUNS / PAGES, dj[1] / RUNS / PAGES, dj[2] / RUNS / PAGES, dj[3] / RUNS / PAGES, dj[4] / RUNS / PAGES])
	print("완공 비율 %d%% · 완공 쪽 중앙값 %s · 추심 의뢰 평균 %.2f회" % [fin * 100 / RUNS, str(done_at[RUNS / 2]), float(collect) / RUNS])
	get_tree().quit()


func _run() -> Dictionary:
	Game.reset()
	Game.stage = "hub"
	var out := {"gold": [], "build": [], "fac": [], "gear": [], "done": 99, "collect": 0, "inc": 0, "jobs": 0}
	for pg in range(1, PAGES + 1):
		Game.week = pg
		var ch: int = 0 if pg <= CH_END[0] else (1 if pg <= CH_END[1] else 2)
		while Game.can_rank_up():  # 촌장 집에서 승급
			Game.rank += 1
		_hire()
		_assign()
		# 메인 의뢰: 결전 쪽은 결전 하나, 아니면 둘
		if pg in CH_END:
			var fr: Dictionary = G.FINALE_REWARD[ch]
			Game.earn(fr.gold, fr.mats, fr.fame, "결전")
		else:
			for q in 2:
				Game.quest_reward("시험", randf() < 0.8, ch)
		_spend(pg in CH_END)
		if pg in CH_END:
			if Game.debt_due() > 0:
				Game.pay_debt(Game.debt_due())
			if Game.debt_due() > 0:
				out.collect += 1
			Game.flags["chapter%d_done" % (ch + 1)] = true
		var before_jobs: int = Game.week_in
		out["jobs_n"] = out.get("jobs_n", 0) + Game.jobs.size()
		out["assigned"] = out.get("assigned", 0) + Game.jobs.filter(func(j): return not j.crew.is_empty()).size()
		out["roster"] = out.get("roster", 0) + Game.roster.size()
		out["power"] = out.get("power", 0.0) + (Game.roster.map(func(a): return a.power).reduce(func(x, y): return x + y, 0) / maxf(1, Game.roster.size()))
		var e: Dictionary = Game.settle()
		out["wins"] = out.get("wins", 0) + e.lines.filter(func(l): return l.begins_with("수입 · 위탁")).size()
		out.inc += e.income
		out.jobs += e.income - before_jobs
		if Game.build >= G.STAGES.size() - 1 and out.done == 99:
			out.done = pg
		out.gold.append(Game.gold)
		out.build.append(Game.build)
		var fl := 0
		for k in Game.facilities:
			fl += Game.facilities[k]
		out.fac.append(fl)
		var gl := 0
		for k in Game.heroes:
			gl += Game.heroes[k].weapon[0] + Game.heroes[k].armor[0]
		out.gear.append(gl)
		Game.new_week()
	return out


func _hire() -> void:
	var apps: Array = Game.applicants.duplicate()
	apps.sort_custom(func(a, b): return a.power > b.power)
	for a in apps:
		if Game.roster.size() >= Game.roster_cap():
			# 가장 약한 사람보다 훨씬 세면 바꾼다 (명부에서 내보내기는 없으니 건너뜀)
			break
		if Game.gold - G.GRADE_INFO[a.grade].fee >= 50:
			Game.hire(a)


func _assign() -> void:
	var js: Array = Game.jobs.duplicate()
	js.sort_custom(func(a, b): return a.gold > b.gold)
	for j in js:
		var free: Array = Game.roster.filter(func(a): return a.hurt == 0 and not Game.busy(a.id))
		free.sort_custom(func(a, b): return a.power > b.power)
		var crew: Array = []
		for a in free:
			if crew.size() >= 3:
				break
			crew.append(a.id)
			if Game.job_chance(j, crew) >= 0.75:
				break
		if not crew.is_empty() and Game.job_chance(j, crew) >= 0.4:
			j.crew = crew


func _spend(finale: bool) -> void:
	# 장 끝 빚 몫은 남겨 둔다
	var keep: int = Game.debt_due() if finale else 0
	while Game.build + 1 < G.STAGES.size():
		var c := Game.stage_cost(Game.build + 1)
		if Game.gold - c.gold < keep or not Game.can_pay(c):
			break
		Game.do_build()
	# 다음 공사 금화의 절반을 넘게 모았으면 시설·장비를 미룬다
	var next_gold: int = Game.stage_cost(Game.build + 1).gold if Game.build + 1 < G.STAGES.size() else 0
	var budget: int = Game.gold - keep - next_gold / 2
	for id in FAC_PLAN:
		var c2 := Game.fac_next_cost(id)
		if c2.is_empty() or c2.get("gold", 0) > budget or not Game.can_pay(c2):
			continue
		if Game.upgrade(id):
			budget -= c2.get("gold", 0)
	# 장비: 파티 무기·방어구 한 단계씩
	for k in Game.party:
		for kind in ["weapon", "armor"]:
			var t: int = Game.heroes[k][kind][0] + 1
			if t >= P.TIERS.size() or Game.build < P.TIERS[t].build:
				continue
			var c3 := Game.gear_buy_cost(k, kind, t)
			if c3.gold <= budget and Game.can_pay(c3) and Game.buy_gear(k, kind, t):
				budget -= c3.gold
