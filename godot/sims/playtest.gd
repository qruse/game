extends RefCounted
## 처음부터 끝까지 자동 플레이 (화면은 실제로 그리고, 장면은 건너뛰고, 전투는 자동 전투로 계산)
## 실행: godot --path godot --resolution 1600x900 -- --goto=playtest
## 콘솔에 "PT:" 줄로 진행을 찍고, 끝나면 "PT: 끝" 을 찍고 종료한다.

const Battle = preload("res://scripts/fk_battle.gd")
const Defs = preload("res://scripts/story_defs.gd")
const FDefs = preload("res://scripts/fk_defs.gd")


static func say(s: String) -> void:
	print("PT: " + s)


static func run(m) -> void:
	m.autoplay = true
	var tree: SceneTree = m.get_tree()
	Game.reset()
	Game.stage = "hub"
	m.town.show_town()
	await tree.create_timer(0.3).timeout
	# ── 마을: 장비·물건·시설·선물 ──
	Game.gold = 2400
	Game.mats = {"wood": 20, "iron": 12, "herb": 6}
	for id in ["potion", "charm", "meat", "knight_book", "ink", "flowers"]:
		_check("잡화점 %s" % id, Game.buy_item(id))
	_check("무기 철", Game.buy_gear("lina", "weapon", 1))
	_check("무기 강화", Game.plus_gear("lina", "weapon"))
	_check("강화 상한", not Game.plus_gear("lina", "weapon"))
	_check("공사 1", Game.do_build())
	_check("공사 2", Game.do_build())
	_check("주방 1", Game.upgrade("kitchen"))
	_check("주방 2", Game.upgrade("kitchen"))
	_check("기록실 1", Game.upgrade("records"))
	_check("선물 리나", not Game.give_gift("lina", "knight_book").is_empty())
	_check("선물 두 번 막힘", Game.give_gift("lina", "knight_book").is_empty())
	_check("선물 노라", not Game.give_gift("nora", "ink").is_empty())
	_check("선물 마르타", not Game.give_gift("martha", "flowers").is_empty())
	for scr in [func(): m.town.show_place("smithy"), func(): m.town.show_place("store"), func(): m.town.show_place("tavern"),
			func(): m.mates.show("lina", "grow"), func(): m.mates.show("cecile", "bond"), func(): m.desk.show(), func(): m._board()]:
		scr.call()
		await tree.create_timer(0.2).timeout
	say("마을 준비 끝 · 금화 %d · 공사 %d · 물건 %s" % [Game.gold, Game.build, str(Game.items)])
	# ── 쪽마다 의뢰 둘 (1쪽은 앞의 둘, 2쪽은 뒤의 둘) → 마지막 쪽은 결전 ──
	for wk in range(1, Defs.FINALE_WEEK + 1):
		if wk > 1:
			Game.week = wk
			Game.picks = []
			Game.new_week()
			m.town.show_town()
			await tree.create_timer(0.3).timeout
		var quests: Array = Defs.WEEK_QUESTS_BY.get(wk, [])
		if not quests.is_empty():
			Game.picks = quests.slice(0, 2) if wk % 2 == 1 else quests.slice(1, 3)
			Game.flags["picked_%d" % wk] = true
			for qid in Game.picks:
				m._open_page(qid)
				await _page(m, tree)
				say("의뢰 %s · %s · 행운 %d · 물건 %s" % [qid, Game.results.get(qid, "?"), Game.page.luck, str(Game.items)])
		await _weekend(m, tree)
	var fm: Dictionary = m._finale_mods()
	say("결전 준비 " + " / ".join(PackedStringArray(fm.notes)))
	var res := _battle(Defs.FINALE_BATTLE, fm.luck, fm.lunch, fm.boss_hp, fm.ambush)
	say("결전 %s" % res.result)
	Game.stage = "finale"
	m._finale_result(res)
	await tree.create_timer(1.0).timeout
	var lv: Array = []
	for k in Game.heroes:
		lv.append("%s Lv%d 호감도 %d(%d단계)" % [k, Game.heroes[k].lv, Game.bond.get(k, 0), Game.bond_seen.get(k, 0)])
	say("동료 " + ", ".join(PackedStringArray(lv)))
	say("금화 %d · 빚 %d · 공사 %d · 명성 %d · 1장 %s · 추심 %s" % [Game.gold, Game.debt, Game.build, Game.fame, str(Game.flags.get("chapter1_done", false)), str(Game.flags.get("collect_ch2", false))])
	say("화면 %s" % Game.stage)
	say("끝")
	tree.quit()


static func _check(what: String, ok: bool) -> void:
	if not ok:
		say("실패 · " + what)


## 연대기 페이지를 끝까지: 판정은 첫 선택지, 전투는 자동 전투, 야영은 쉰다
static func _page(m, tree: SceneTree) -> void:
	for step in 40:
		await tree.create_timer(0.8).timeout
		var p: Dictionary = Game.page
		if p.done:
			_press_last(m)  # 마무리 → 장면(건너뜀) → 길드
			await tree.create_timer(0.4).timeout
			return
		var n: Dictionary = Defs.QUESTS[p.quest].nodes[p.node]
		match n.t:
			"talk":
				for ch in n.choices:
					var who: Dictionary = Game.best(ch.stat, ch.get("who", ""))
					if not who.is_empty():
						m._choose(ch, who)
						break
				_press_last(m)
			"battle":
				var res := _battle(n.battle, p.luck, p.vars.get("lunch", 0), 0)
				say("  전투 %s (%s)" % [n.title, res.result])
				m._battle_result(res)
				_press_last(m)
			"camp":
				_press_last(m)
			"end":
				pass
	say("실패 · 페이지가 끝나지 않았다 " + str(Game.page.node))


static func _press_last(m) -> void:
	var bs: Array = m.side.find_children("*", "Button", true, false)
	if bs.is_empty():
		say("실패 · 누를 버튼이 없다 (%s)" % Game.page.get("node", ""))
		return
	bs[-1].pressed.emit()


static func _weekend(m, tree: SceneTree) -> void:
	m._weekend()
	await tree.create_timer(0.3).timeout
	var e: Dictionary = Game.ledger[-1]
	say("장부 %d쪽 · 수입 %d · 지출 %d · 줄 %d" % [e.week, e.income, e.spend, e.lines.size()])
	if Game.debt_due() > 0 and Game.gold >= Game.debt_due():
		Game.pay_debt(Game.debt_due())
	m._show_news()
	await tree.create_timer(0.3).timeout


## 자동 전투 (fk_sim 과 같은 방식) + 이야기 모드 조건
static func _battle(idx: int, luck: int, lunch: int, boss_hp: int, ambush := false) -> Dictionary:
	var b = Battle.new()
	b.setup(idx, Game.party)
	b.fate = luck
	b.potions = Game.items.get("potion", 0)
	for u in b.units:
		if u.side == "ally" and lunch > 0:
			u.max_hp += lunch
			u.hp = u.max_hp
		if u.boss and boss_hp != 0:
			u.max_hp = maxi(10, u.max_hp + boss_hp)
			u.hp = u.max_hp
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
	return {"result": b.result if b.result != "" else "lose", "luck": b.fate, "potions": b.potions}
