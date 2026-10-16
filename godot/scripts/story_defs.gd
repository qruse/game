extends RefCounted
## 1장 체험판 내용: 이야기 장면, 이번 주 의뢰, 연대기 페이지 칸.
## 장면은 짧게 (docs/04-game-flow.md 3.7: 의뢰 시작 8줄, 마무리 5줄, 챕터 큰 사건 15줄 이하)

## 말하는 사람 → 스탠딩 그림. 동료는 표정 6종(neutral smile angry sad surprised embarrassed),
## 주요 NPC는 3종(neutral positive negative), 마을 사람은 1종
const SPEAKERS := {
	"lina": {"name": "리나", "path": "characters/C01_lina/C01_portrait_%s_%s.png", "outfit": "combat"},
	"cecile": {"name": "세실", "path": "characters/C02_cecile/C02_portrait_%s_%s.png", "outfit": "combat"},
	"adelheid": {"name": "아델하이트", "path": "characters/C03_adelheid/C03_portrait_%s_%s.png", "outfit": "combat"},
	"martha": {"name": "마르타", "path": "npcs/N01_martha/N01_portrait_%s.png"},
	"basil": {"name": "공증인 바실", "path": "npcs/N02_basil/N02_portrait_%s.png"},
	"farmer": {"name": "마을 사람", "path": "npcs/N07_villager_m/N07_portrait_neutral.png"},
	"nun": {"name": "늙은 수녀", "path": ""},
}

## 장면: bg(배경), cg(앞쪽 몇 줄에 띄울 CG), cg_lines, lines [말하는 사람, 표정, 대사], summary(건너뛰면 남는 한 줄)
const SCENES := {
	"opening": {
		"bg": "backgrounds/scene/bg_guildhall_ruined.png", "cg": "cg/cg_ch1_inheritance.png", "cg_lines": 3,
		"lines": [
			["", "", "몰락한 은빛 등불 길드. 마지막 길드장이 사라진 지 십 년."],
			["lina", "neutral", "오셨군요. 이 열쇠, 이제 당신 겁니다."],
			["lina", "smile", "오늘부터 당신이 단장입니다."],
			["basil", "neutral", "유언장대로라면 이 폐허는 당신 것입니다. 빚까지 포함해서요."],
			["basil", "negative", "석 달 안에 길드를 되살리지 못하면 건물은 영주님께 넘어갑니다."],
			["cecile", "smile", "금고 털러 왔더니 텅 비었더라고. 재밌어 보여서 눌러앉았어."],
			["adelheid", "neutral", "…시끄러워. 난 책 읽을 자리만 있으면 돼."],
			["lina", "angry", "되살릴 겁니다. 아버지의 이름을 걸고요."],
			["", "", "그렇게 당신은 폐허의 단장이 되었다."],
		],
		"summary": "단장은 폐허가 된 길드와 녹슨 열쇠를 물려받았다.",
	},
	"week1": {
		"bg": "backgrounds/scene/bg_noticeboard.png",
		"lines": [
			["martha", "neutral", "단장, 게시판에 의뢰가 셋이나 붙었어. 길드가 다시 열렸다고 소문이 났나 봐."],
			["martha", "positive", "근데 일손이 셋뿐이잖아? 이번 주엔 둘만 골라."],
			["lina", "neutral", "고르지 않은 일은… 누군가 대신 감당하겠죠."],
		],
		"summary": "이번 주 의뢰는 셋. 그중 둘만 할 수 있다.",
	},
	"bandits_in": {
		"bg": "backgrounds/scene/bg_village_square.png",
		"lines": [
			["farmer", "", "도적들이 밤마다 내려와 곡식을 털어 갑니다."],
			["lina", "angry", "기사의 이름으로 그냥 둘 수 없어요."],
			["cecile", "neutral", "곡식 털이라… 소박한 놈들이네."],
			["farmer", "", "제발 마을을 지켜 주십시오."],
		],
		"summary": "북쪽 마을 사람이 도적을 막아 달라고 부탁했다.",
	},
	"bandits_ok": {
		"bg": "backgrounds/scene/bg_village_square.png",
		"lines": [
			["farmer", "", "고맙습니다! 마을 사람들에게 길드 이야기를 전하겠습니다."],
			["lina", "smile", "기사로서 당연한 일입니다."],
		],
		"summary": "북쪽 마을은 길드에 고마워했다.",
	},
	"bandits_ng": {
		"bg": "backgrounds/scene/bg_village_square.png",
		"lines": [
			["farmer", "", "…다음엔 꼭 부탁드립니다."],
			["lina", "sad", "죄송해요. 더 강해질게요."],
		],
		"summary": "북쪽 마을 사람은 실망한 얼굴로 돌아갔다.",
	},
	"trapper_in": {
		"bg": "backgrounds/scene/bg_forest_road.png",
		"lines": [
			["basil", "neutral", "숲길 상인 마차가 연달아 털렸습니다. 덫사냥꾼 하나가 도적과 내통한다더군요."],
			["cecile", "smile", "냄새나는데? 내가 좋아하는 일이야."],
			["basil", "negative", "보수는 성공했을 때만 드립니다. 서류에 그렇게 적혀 있어요."],
			["adelheid", "neutral", "…서류 좋아하는 사람치고 착한 사람 못 봤어."],
		],
		"summary": "공증인 바실이 숲길의 덫사냥꾼을 조사해 달라고 했다.",
	},
	"trapper_ok": {
		"bg": "backgrounds/scene/bg_forest_road.png",
		"lines": [
			["basil", "positive", "보급대를 불태웠다니… 서류에 잘 적어 두죠. 보수입니다."],
			["cecile", "smile", "수고비도 좀 얹어 주면 좋겠는데."],
		],
		"summary": "바실은 보수를 내주며 처음으로 웃었다.",
	},
	"trapper_ng": {
		"bg": "backgrounds/scene/bg_forest_road.png",
		"lines": [
			["basil", "negative", "덫사냥꾼 하나 잡고 끝이라니요. 보수는 절반입니다."],
			["cecile", "angry", "쩨쩨하긴."],
		],
		"summary": "바실은 보수를 절반만 내줬다.",
	},
	"archive_in": {
		"bg": "backgrounds/scene/bg_room_archive.png",
		"lines": [
			["adelheid", "sad", "…수도원 서고. 내가 쫓겨난 곳이야."],
			["lina", "surprised", "괜찮으시겠어요?"],
			["adelheid", "neutral", "의뢰는 의뢰지. 금서 목록만 맞추면 돼."],
			["cecile", "smile", "금서? 비싸게 팔리겠는데."],
			["adelheid", "angry", "손대면 손목을 얼려 버릴 거야."],
		],
		"summary": "수도원이 서고의 금서 목록을 정리해 달라고 했다.",
	},
	"archive_ok": {
		"bg": "backgrounds/scene/bg_room_archive.png",
		"lines": [
			["adelheid", "embarrassed", "…고마워. 여기 다시 올 줄은 몰랐어."],
			["lina", "smile", "언제든 같이 와요."],
		],
		"summary": "아델하이트는 오랜만에 서고에서 웃었다.",
	},
	"finale_in": {
		"bg": "backgrounds/scene/bg_guildhall_ruined.png",
		"lines": [
			["martha", "negative", "단장! 붉은 수염 패거리가 길드로 쳐들어오고 있어!"],
			["basil", "negative", "영주님께 넘기기도 전에 불타게 생겼군요."],
			["lina", "angry", "길드는 우리가 지킵니다."],
			["cecile", "smile", "집 지키는 싸움이라. 나쁘지 않네."],
			["adelheid", "neutral", "…책 젖으면 다 얼려 버릴 거야."],
		],
		"summary": "붉은 수염 패거리가 길드 회관을 덮쳤다.",
	},
	"finale_ok": {
		"bg": "backgrounds/scene/bg_guildhall_ruined.png",
		"lines": [
			["lina", "smile", "해냈어요, 단장! 길드는 아직 살아 있어요."],
			["martha", "positive", "오늘 밤 술은 내가 쏜다!"],
			["basil", "positive", "…서류에 적어 두죠. '은빛 등불 길드, 첫 승리'."],
			["", "", "그날 밤, 굳게 잠겨 있던 기록실 문틈으로 희미한 등불 빛이 새어 나왔다."],
		],
		"summary": "길드는 붉은 수염을 물리쳤다. 기록실의 봉인이 흔들렸다.",
	},
}

## 이번 주 의뢰. pin: 지도 위 자리(0~1). seal: 의뢰인 세력 인장
## 칸(nodes) 종류: start / talk(판정 선택지) / battle / camp / end
## 선택지: stat, dc, who(정해진 동료, 없으면 파티에서 가장 높은 동료), ok/ng → {line, next, set(페이지 변수), flag}
const QUESTS := {
	"bandits": {
		"name": "북쪽 마을의 도적", "seal": "왕관", "client": "마을 사람", "pin": Vector2(0.66, 0.2),
		"desc": "도적이 밤마다 내려와 곡식을 털어 간다. 마을을 지켜 줄 사람이 필요하다.",
		"intro": "bandits_in", "outro_ok": "bandits_ok", "outro_ng": "bandits_ng",
		"skip": {"news": "북쪽 마을이 도적에게 털렸다. 마을 사람들이 길드를 원망한다.", "flag": "village_raided"},
		"ok_flag": "village_saved",
		"nodes": {
			"start": {"t": "start", "pos": Vector2(0.08, 0.5), "next": "n1"},
			"n1": {
				"t": "talk", "pos": Vector2(0.32, 0.5), "title": "겁먹은 마을",
				"text": "마을 사람들이 문을 걸어 잠갔다.\n도적이 어디서 오는지 아무도 말하지 않는다.",
				"choices": [
					{"label": "도적이 오는 길을 묻는다", "stat": "cha", "dc": 12,
						"ok": {"line": "단장의 말에 마을 사람들이 입을 열었다. 도적은 숲 공터를 지나 온다.", "next": "n2", "set": {"ambush": true}},
						"ng": {"line": "마을 사람들은 끝내 입을 다물었다. 길드는 밤새 마을 어귀를 지켰다.", "next": "n2"}},
					{"label": "검을 뽑아 보인다", "stat": "str", "dc": 13, "who": "lina",
						"ok": {"line": "리나가 검을 뽑자 촌장이 숲 공터를 가리켰다.", "next": "n2", "set": {"ambush": true}},
						"ng": {"line": "겁먹은 마을 사람들은 더 깊이 숨어 버렸다.", "next": "n2"}},
				],
			},
			"n2": {
				"t": "battle", "pos": Vector2(0.62, 0.5), "title": "숲 공터", "battle": 0,
				"text": "도적 패거리가 숲 공터로 내려온다.",
				"ambush_text": "길을 알고 먼저 숨어 기다렸다. 적은 첫 차례에 움직이지 못한다.",
				"win": {"line": "길드는 숲 공터에서 도적 패거리를 쫓아냈다.", "next": "end"},
				"lose": {"line": "길드는 도적에게 밀려 물러났다.", "next": "end", "fail": true},
			},
			"end": {"t": "end", "pos": Vector2(0.9, 0.5)},
		},
	},
	"trapper": {
		"name": "숲의 덫사냥꾼 조사", "seal": "상회", "client": "공증인 바실", "pin": Vector2(0.38, 0.55),
		"desc": "숲길 상인 마차가 털린다. 덫사냥꾼 하나가 도적과 내통한다는 소문.",
		"intro": "trapper_in", "outro_ok": "trapper_ok", "outro_ng": "trapper_ng",
		"skip": {"news": "숲길에서 상인 마차가 또 털렸다. 도적의 보급이 넉넉해졌다.", "flag": "supply_strong"},
		"ok_flag": "supply_cut",
		"nodes": {
			"start": {"t": "start", "pos": Vector2(0.08, 0.5), "next": "n1"},
			"n1": {
				"t": "talk", "pos": Vector2(0.28, 0.5), "title": "수상한 덫사냥꾼",
				"text": "숲길 오두막. 덫사냥꾼이 덫을 손질하며\n우리를 흘끔거린다.",
				"choices": [
					{"label": "도적에 대해 아는 걸 묻는다", "stat": "cha", "dc": 13,
						"ok": {"line": "덫사냥꾼은 술 한 병에 도적 보급대의 뒷길을 털어놓았다.", "next": "n2"},
						"ng": {"line": "덫사냥꾼은 덫을 집어던지고 숲으로 달아났다.", "next": "n2b"}},
					{"label": "리나가 검을 뽑는다", "stat": "str", "dc": 12, "who": "lina",
						"ok": {"line": "리나가 검을 뽑자 사냥꾼은 도적 소굴의 뒷길을 털어놓았다.", "next": "n2"},
						"ng": {"line": "사냥꾼은 리나의 검을 보자마자 숲으로 달아났다.", "next": "n2b"}},
					{"label": "몰래 오두막을 뒤진다", "stat": "dex", "dc": 14, "who": "cecile",
						"ok": {"line": "세실이 오두막에서 도적 보급대의 지도를 슬쩍했다.", "next": "n2"},
						"ng": {"line": "세실이 덫을 밟았다. 사냥꾼은 그 틈에 달아났다.", "next": "n2b"}},
				],
			},
			"n2": {
				"t": "talk", "pos": Vector2(0.48, 0.3), "title": "숨은 뒷길",
				"text": "도적 보급 수레가 지나간 자국이 있다.\n자국을 따라가면 보급대를 앞지를 수 있다.",
				"choices": [
					{"label": "수레 자국을 읽는다", "stat": "int", "dc": 12, "who": "adelheid",
						"ok": {"line": "아델하이트가 자국을 읽어 보급대가 쉬어 가는 공터를 알아냈다.", "next": "n3", "set": {"ambush": true}},
						"ng": {"line": "자국이 흐려 길을 헤맸다. 보급대와 정면으로 마주쳤다.", "next": "n3"}},
				],
			},
			"n3": {
				"t": "battle", "pos": Vector2(0.7, 0.3), "title": "보급대 습격", "battle": 0,
				"text": "도적 보급대가 공터에서 쉬고 있다.",
				"ambush_text": "보급대보다 먼저 공터에 숨었다. 적은 첫 차례에 움직이지 못한다.",
				"win": {"line": "길드는 도적의 보급 수레를 불태웠다.", "next": "end", "flag": "supply_cut"},
				"lose": {"line": "보급대 호위에게 밀려 물러났다.", "next": "end", "fail": true},
			},
			"n2b": {
				"t": "battle", "pos": Vector2(0.55, 0.72), "title": "추격", "battle": 0,
				"text": "달아난 사냥꾼을 쫓다 도적 패거리와 마주쳤다.",
				"win": {"line": "사냥꾼은 붙잡았지만 보급대는 놓쳤다.", "next": "end", "fail": true},
				"lose": {"line": "사냥꾼도 보급대도 놓쳤다.", "next": "end", "fail": true},
			},
			"end": {"t": "end", "pos": Vector2(0.9, 0.5)},
		},
	},
	"archive": {
		"name": "수도원 서고 정리", "seal": "교회", "client": "수도원", "pin": Vector2(0.9, 0.15),
		"desc": "수도원 서고의 금서 목록이 맞지 않는다. 책을 잘 아는 사람이 필요하다.",
		"intro": "archive_in", "outro_ok": "archive_ok", "outro_ng": "archive_ok",
		"skip": {"news": "수도원 서고에서 금서 한 권이 사라졌다는 소문이 돈다. 아델하이트는 아무 말도 하지 않았다.", "flag": "archive_skipped"},
		"ok_flag": "archive_done",
		"nodes": {
			"start": {"t": "start", "pos": Vector2(0.08, 0.5), "next": "n1"},
			"n1": {
				"t": "talk", "pos": Vector2(0.3, 0.5), "title": "닫힌 서고 문",
				"text": "늙은 수녀가 문을 막아선다.\n\"쫓겨난 아이가 왜 돌아왔지?\"",
				"choices": [
					{"label": "길드 의뢰서를 보여 준다", "stat": "cha", "dc": 12, "who": "lina",
						"ok": {"line": "리나가 의뢰서를 내밀자 수녀는 마지못해 문을 열었다.", "next": "n2"},
						"ng": {"line": "수녀는 문을 열어 주었지만 내내 우리를 감시했다.", "next": "n2"}},
					{"label": "서고 봉인의 결함을 짚어 준다", "stat": "int", "dc": 13, "who": "adelheid",
						"ok": {"line": "아델하이트가 봉인의 금 간 자리를 짚자 수녀가 입을 다물었다.", "next": "n2"},
						"ng": {"line": "아델하이트의 말은 수녀의 화만 돋웠다.", "next": "n2"}},
				],
			},
			"n2": {
				"t": "talk", "pos": Vector2(0.52, 0.5), "title": "맞지 않는 목록",
				"text": "목록과 실제 책이 맞지 않는다.\n금서 한 칸이 비어 있다.",
				"choices": [
					{"label": "빠진 책을 찾는다", "stat": "int", "dc": 12, "who": "adelheid",
						"ok": {"line": "빠진 책은 '등불의 서'. 누군가 최근에 가져갔다.", "next": "n3", "flag": "lantern_book"},
						"ng": {"line": "빠진 책이 무엇인지 끝내 알아내지 못했다.", "next": "n3"}},
					{"label": "책장 뒤를 뒤진다", "stat": "dex", "dc": 13, "who": "cecile",
						"ok": {"line": "책장 뒤에서 붉은 수염의 인장이 찍힌 쪽지를 찾았다. 길드를 노린다는 내용이다.", "next": "n3", "flag": "redbeard_note"},
						"ng": {"line": "먼지만 잔뜩 뒤집어썼다.", "next": "n3"}},
				],
			},
			"n3": {
				"t": "camp", "pos": Vector2(0.74, 0.5), "title": "서고의 밤",
				"text": "아델하이트가 오랜만에 서고 책상에서 잠들었다.\n촛불 아래에서 잠깐 쉬어 간다.",
				"line": "그날 밤, 아델하이트는 서고 책상에서 잠들었다.", "next": "end",
			},
			"end": {"t": "end", "pos": Vector2(0.92, 0.5)},
		},
	},
}

const WEEK_QUESTS := ["bandits", "trapper", "archive"]
const WEEK_PICKS := 2
const FINALE_BATTLE := 1

## 칸 종류별 표시
const NODE_KIND := {
	"start": {"name": "출발", "mark": "출"}, "talk": {"name": "판정", "mark": "말"}, "battle": {"name": "전투", "mark": "검"},
	"camp": {"name": "캠프", "mark": "불"}, "end": {"name": "완성", "mark": "끝"},
}
