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
	"nora": {"name": "부관 노라", "path": "npcs/N14_nora/N14_portrait_%s.png"},
	"basil": {"name": "공증인 바실", "path": "npcs/N02_basil/N02_portrait_%s.png"},
	"farmer": {"name": "마을 사람", "path": "npcs/N07_villager_m/N07_portrait_neutral.png"},
	"tobias": {"name": "촌장 토비아스", "path": "npcs/N11_tobias/N11_portrait_%s.png"},
	"wolfram": {"name": "대장장이 볼프람", "path": "npcs/N12_wolfram/N12_portrait_neutral.png"},
	"pip": {"name": "잡화점 주인 핍", "path": "npcs/N13_pip/N13_portrait_neutral.png"},
	"nun": {"name": "늙은 수녀", "path": ""},
}

## 장면: bg(배경), cg(CG), cg_from~cg_lines 번째 줄에 CG를 띄운다 (cg_from 기본 0), lines [말하는 사람, 표정, 대사], summary(건너뛰면 남는 한 줄)
const SCENES := {
	"opening": {
		"bg": "backgrounds/scene/bg_guildhall_ruined.png", "cg": "cg/cg_ch1_inheritance.png", "cg_lines": 3,
		"lines": [
			["", "", "변경의 마을 하웰. 모험가 길드의 간판이 내려간 지 십오 년."],
			["lina", "neutral", "촌장님이 맡기신 열쇠예요. 이제 당신 겁니다."],
			["lina", "smile", "오늘부터 당신이 단장입니다."],
			["basil", "neutral", "재건 서류는 제가 맡았습니다. 이 폐허는 당신 것입니다. 빚까지 포함해서요."],
			["basil", "negative", "상회에서 빌린 재건 자금, 잊지 마시고요. 지붕부터 고치려면 금화가 꽤 듭니다."],
			["cecile", "smile", "금고 털러 왔더니 텅 비었더라고. 재밌어 보여서 눌러앉았어."],
			["adelheid", "neutral", "…시끄러워. 난 책 읽을 자리만 있으면 돼."],
			["lina", "angry", "되살릴 겁니다. 아버지의 이름을 걸고요."],
			["", "", "그렇게 당신은 폐허의 단장이 되었다."],
		],
		"summary": "단장은 촌장에게서 폐허가 된 하웰 모험가 길드의 열쇠를 받았다.",
	},
	"week1": {
		"bg": "backgrounds/scene/bg_noticeboard.png",
		"lines": [
			["nora", "positive", "하웰 토박이 노라입니다. 길드가 다시 연다길래 부관 지원서를 써 왔어요. 서류는 3장입니다."],
			["nora", "neutral", "부관 노라입니다. 게시판에 의뢰가 3건 붙었네요. 일손이 셋뿐이니 이번엔 2건만 고르시죠."],
			["lina", "neutral", "고르지 않은 일은… 누군가 대신 감당하겠죠."],
		],
		"summary": "부관 노라가 길드에 들어왔다. 이번 의뢰는 셋, 그중 둘만 할 수 있다.",
	},
	# ── NPC 3단계 이야기 (docs/04-game-flow.md 6.4절). bg "@guild" = 지금 길드 하우스 ──
	"nora_1": {
		"bg": "@guild",
		"lines": [
			["", "", "해 질 녘 길드 지붕 위. 노라가 마을을 내려다보며 지붕 수를 세고 있다."],
			["nora", "neutral", "하웰 집은 모두 143채예요. 여기서 나고 자라서, 어느 집 굴뚝에 언제 연기가 나는지도 알아요."],
			["nora", "positive", "이 마을이 좋아서 떠난 적이 없어요. 그러니 이 마을 돈 사정도 훤하죠. 다음 쪽 예상 수입, 미리 적어 드릴게요."],
		],
		"summary": "노라는 고향 하웰을 무척 아낀다. 장부에 다음 쪽 예상 수입이 적힌다.",
	},
	"nora_2": {
		"bg": "@guild",
		"lines": [
			["", "", "왕도 재무청의 봉인이 찍힌 편지. 장부 솜씨를 듣고 왕도 서기로 데려가고 싶다는 내용이다."],
			["nora", "neutral", "보수는 지금의 두 배래요. 숫자만 보면 좋은 조건이죠."],
			["nora", "positive", "답장은 벌써 썼어요. '저는 하웰이 좋아서요.' 대신 목수 조합장인 삼촌한테 공사 값을 5% 깎아 달라고 했습니다."],
		],
		"summary": "노라는 왕도의 스카우트를 거절하고 하웰에 남았다. 재건 공사 금화 비용이 5% 줄어든다.",
	},
	"nora_3": {
		"bg": "@guild",
		"lines": [
			["", "", "길드 명부 첫 장. 노라의 이름 옆에는 늘 '임시 부관'이라고 적혀 있었다."],
			["nora", "neutral", "임시라고 적어 둔 건, 이 길드가 다시 설 줄 몰라서였어요."],
			["nora", "positive", "이제 고칩니다. 하웰 모험가 길드 부관, 노라. 위탁 보수 협상도 정식으로 제가 맡죠. 10%는 더 받아 오겠습니다."],
		],
		"summary": "노라는 정식 길드원이 되었다. 위탁 의뢰 보수가 10% 오른다.",
	},
	"martha_1": {
		"bg": "backgrounds/scene/bg_tavern.png",
		"lines": [
			["martha", "neutral", "단장, 너희 길드 몫으로 외상 장부 하나 새로 폈다."],
			["martha", "positive", "그리고 이거. 남은 고기파이야. 굶고 다니다 쓰러지면 외상도 못 받잖아!"],
		],
		"summary": "마르타가 길드 몫 외상 장부를 폈다. 야영 칸에서 행운 주사위가 하나 더 돌아온다.",
	},
	"martha_2": {
		"bg": "backgrounds/scene/bg_tavern.png",
		"lines": [
			["martha", "neutral", "저 구석 자리, 옛날 용사 일행이 하웰에 들렀을 때 앉았던 데야. 에드릭 그 양반, 외상 안 갚고 떠났지."],
			["martha", "negative", "…장부? 아직 있지. 버리려다 매번 다시 넣어 둬."],
			["martha", "positive", "대신 요즘 손님들 소문은 내가 다 듣고 있으니까, 장부 마감할 때마다 한 줄씩 흘려 줄게."],
		],
		"summary": "마르타는 옛 장부를 아직 간직하고 있다. 소식에 선술집 소문이 한 줄 붙는다.",
	},
	"martha_3": {
		"bg": "backgrounds/scene/bg_tavern.png",
		"lines": [
			["martha", "neutral", "가운데 탁자 비워 뒀다. 오늘부터 '하웰 길드 자리'야."],
			["", "", "마르타가 낡은 외상 장부를 길드 사람들 앞에서 찢었다."],
			["martha", "positive", "이제 너희가 이 마을 단골이야. 출발하는 날엔 도시락 챙겨 가!"],
		],
		"summary": "선술집에 하웰 길드 자리가 생겼다. 의뢰를 떠날 때 행운 주사위를 하나 더 들고 간다.",
	},
	# ── 동료 서브 스토리 1·2단계 (docs/04-game-flow.md 6.1절). 3단계부터는 1장 이후 ──
	"lina_1": {
		"bg": "@guild",
		"lines": [
			["", "", "새벽 길드 홀. 리나가 혼자 녹슨 간판을 닦고 있다."],
			["lina", "surprised", "단장님? 일찍 일어나셨네요."],
			["lina", "smile", "이 간판, 다시 걸릴 때 제일 먼저 보고 싶어서요. 그때까진 매일 닦을 거예요."],
		],
		"summary": "리나는 매일 새벽 길드 간판을 닦는다.",
	},
	"lina_2": {
		"bg": "@guild",
		"lines": [
			["lina", "sad", "저, 사실 무서워요. 아버지 이름을 걸었는데 못 지키면 어쩌나 하고요."],
			["lina", "neutral", "그래도 단장님이 판정을 맡겨 주실 때마다, 조금씩 덜 무서워져요."],
			["lina", "smile", "다음에도 맡겨 주세요. 꼭 해낼게요."],
		],
		"summary": "리나는 두려움을 털어놓았다. 리나가 굴리는 판정 +1.",
	},
	"cecile_1": {
		"bg": "@guild",
		"lines": [
			["", "", "금고 앞. 세실이 빈 금고 문을 열었다 닫았다 한다."],
			["cecile", "smile", "아, 단장. 그냥 확인 중이야. 아직 텅 비었네."],
			["cecile", "neutral", "언젠가 이게 꽉 차면, 그때 털지 말지 정할게. 농담이야. …아마도."],
		],
		"summary": "세실은 빈 금고가 찰 날을 기다린다.",
	},
	"cecile_2": {
		"bg": "@guild",
		"lines": [
			["cecile", "neutral", "옛날 패거리에선 아무도 날 믿지 않았어. 나도 아무도 안 믿었고."],
			["cecile", "embarrassed", "근데 단장은 자물쇠 앞에 날 먼저 세우더라. 이상한 사람."],
			["cecile", "smile", "좋아. 그 믿음, 손해 안 보게 해 줄게."],
		],
		"summary": "세실은 단장의 믿음에 답하기로 했다. 세실이 굴리는 판정 +1.",
	},
	"adelheid_1": {
		"bg": "@guild",
		"lines": [
			["", "", "곰팡내 나는 서고. 아델하이트가 무너진 책장 사이에 앉아 있다."],
			["adelheid", "neutral", "…여기 있는 책, 다 읽을 거야. 그러니까 치우지 마."],
			["adelheid", "smile", "대신 의뢰엔 따라가 줄게. 책값은 벌어야 하니까."],
		],
		"summary": "아델하이트는 길드 서고를 자기 자리로 정했다.",
	},
	"adelheid_2": {
		"bg": "@guild",
		"lines": [
			["adelheid", "neutral", "수도원에선 금서를 읽었다고 쫓겨났어. 질문이 많은 건 죄래."],
			["adelheid", "sad", "여기선 아무도 내 책을 뺏지 않더라. 그게… 조금 이상해."],
			["adelheid", "embarrassed", "고맙다는 말은 한 번만 해. 다음 판정, 실수 안 할게."],
		],
		"summary": "아델하이트는 길드에서 자리를 찾았다. 아델하이트가 굴리는 판정 +1.",
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
	"boars_in": {
		"bg": "backgrounds/scene/bg_chief_house.png",
		"lines": [
			["tobias", "negative", "멧돼지 떼가 밤마다 밭을 갈아엎소. 이대로면 겨울 양식이 없어."],
			["cecile", "smile", "멧돼지면 오늘 저녁은 고기네."],
			["lina", "neutral", "마을 밭은 저희가 지킬게요, 촌장님."],
		],
		"summary": "촌장 토비아스가 밭을 망치는 멧돼지 떼를 쫓아 달라고 했다.",
	},
	"boars_ok": {
		"bg": "backgrounds/scene/bg_chief_house.png",
		"lines": [
			["tobias", "positive", "밭이 살았소! 길드 몫으로 곡식을 따로 떼어 두리다."],
			["cecile", "smile", "고기는? 고기도 떼어 줘."],
		],
		"summary": "토비아스는 길드 몫으로 곡식을 떼어 두겠다고 했다.",
	},
	"boars_ng": {
		"bg": "backgrounds/scene/bg_chief_house.png",
		"lines": [
			["tobias", "negative", "몇 마리는 쫓았지만… 밭 절반은 끝났소."],
			["lina", "sad", "다음엔 꼭 지킬게요."],
		],
		"summary": "밭 절반을 잃었다. 토비아스는 말없이 고개를 끄덕였다.",
	},
	"hideout_in": {
		"bg": "backgrounds/scene/bg_noticeboard.png",
		"lines": [
			["basil", "neutral", "붉은 수염의 소굴을 찾았습니다. 협곡 안쪽, 천막촌이더군요."],
			["basil", "negative", "영주님은 병사를 못 보냅니다. 서류상으로는 길드 일이죠."],
			["adelheid", "neutral", "먼저 치러 가자는 거네. 나쁘지 않아."],
			["lina", "angry", "길드를 노리는 놈들이에요. 가요, 단장."],
		],
		"summary": "공증인 바실이 붉은 수염 패거리의 소굴을 정찰해 달라고 했다.",
	},
	"hideout_ok": {
		"bg": "backgrounds/scene/bg_bandit_hideout.png",
		"lines": [
			["cecile", "smile", "천막 몇 개 태웠더니 다들 우왕좌왕하던데."],
			["adelheid", "neutral", "이제 놈들이 언제 올지 알아. 다음은 우리가 기다릴 차례야."],
		],
		"summary": "길드는 붉은 수염의 소굴을 흔들어 놓고 돌아왔다.",
	},
	"hideout_ng": {
		"bg": "backgrounds/scene/bg_bandit_hideout.png",
		"lines": [
			["lina", "sad", "들켜 버렸어요. 놈들도 이제 우리를 알아요."],
			["adelheid", "neutral", "…그래도 소굴 위치는 알아냈어."],
		],
		"summary": "정찰은 들켰다. 그래도 소굴 위치는 알아냈다.",
	},
	"escort_in": {
		"bg": "backgrounds/scene/bg_general_store.png",
		"lines": [
			["pip", "neutral", "옆 마을까지 짐마차를 끌고 가야 하는데, 숲길이 요즘 험해서요."],
			["pip", "neutral", "무사히 다녀오면 회복약 좀 챙겨 드릴게요. 장사꾼 약속입니다."],
			["cecile", "smile", "장사꾼 약속이면 반만 믿어야지."],
		],
		"summary": "잡화점 주인 핍이 숲길 짐마차를 지켜 달라고 했다.",
	},
	"escort_ok": {
		"bg": "backgrounds/scene/bg_general_store.png",
		"lines": [
			["pip", "neutral", "물건 하나 안 깨졌네요! 약속한 회복약입니다."],
			["lina", "smile", "잘 쓸게요, 핍 씨."],
		],
		"summary": "핍은 약속대로 회복약을 챙겨 주었다.",
	},
	"escort_ng": {
		"bg": "backgrounds/scene/bg_general_store.png",
		"lines": [
			["pip", "neutral", "짐 절반은 늑대 밥이 됐지만… 목숨은 건졌으니까요."],
			["cecile", "neutral", "약은? …없구나."],
		],
		"summary": "짐마차는 절반만 도착했다.",
	},
	"finale_in": {
		"bg": "backgrounds/scene/bg_guildhall_ruined.png",
		"lines": [
			["martha", "negative", "단장! 붉은 수염 패거리가 길드로 쳐들어오고 있어!"],
			["basil", "negative", "재건 서류에 도장도 마르기 전에 불타게 생겼군요."],
			["lina", "angry", "길드는 우리가 지킵니다."],
			["cecile", "smile", "집 지키는 싸움이라. 나쁘지 않네."],
			["adelheid", "neutral", "…책 젖으면 다 얼려 버릴 거야."],
		],
		"summary": "붉은 수염 패거리가 길드 회관을 덮쳤다.",
	},
	"finale_ok": {
		"bg": "backgrounds/scene/bg_guildhall_ruined.png", "cg": "cg/cg_ch1_end.png", "cg_from": 3, "cg_lines": 5,
		"lines": [
			["lina", "smile", "해냈어요, 단장! 길드는 아직 살아 있어요."],
			["martha", "positive", "오늘 밤 술은 내가 쏜다!"],
			["basil", "positive", "…서류에 적어 두죠. '하웰 모험가 길드, 첫 승리'."],
			["", "", "그날 밤, 단장은 십오 년 만에 정문에 길드 간판을 다시 걸었다."],
			["", "", "다음 날 아침, 길드 앞에 의뢰인들이 줄을 섰다."],
		],
		"summary": "길드는 붉은 수염을 물리치고 십오 년 만에 간판을 다시 걸었다.",
	},
}

## 이번 주 의뢰. pin: 지도 위 자리(0~1). seal: 의뢰인 세력 인장
## 칸(nodes) 종류: start / talk(판정 선택지) / battle / camp / end
## 선택지: stat, dc, who(정해진 동료, 없으면 파티에서 가장 높은 동료), ok/ng → {line, next, set(페이지 변수), flag}
const QUESTS := {
	"bandits": {
		"name": "북쪽 마을의 도적", "seal": "왕관", "client": "북쪽 마을", "short": "밤마다 내려와 곡식을 털어 가는 도적 떼", "tags": ["토벌", "전투 2회"], "risk": 2, "pin": Vector2(0.66, 0.2),
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
		"name": "숲의 덫사냥꾼 조사", "seal": "상회", "client": "공증인 바실", "short": "도적과 내통한다는 소문의 사냥꾼", "tags": ["정찰", "조사"], "risk": 1, "pin": Vector2(0.38, 0.55),
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
				"t": "battle", "pos": Vector2(0.7, 0.3), "title": "보급대 습격", "battle": 2,
				"text": "도적 보급대가 공터에서 쉬고 있다.",
				"ambush_text": "보급대보다 먼저 공터에 숨었다. 적은 첫 차례에 움직이지 못한다.",
				"win": {"line": "길드는 도적의 보급 수레를 불태웠다.", "next": "end", "flag": "supply_cut"},
				"lose": {"line": "보급대 호위에게 밀려 물러났다.", "next": "end", "fail": true},
			},
			"n2b": {
				"t": "battle", "pos": Vector2(0.55, 0.72), "title": "추격", "battle": 3,
				"text": "달아난 사냥꾼을 쫓다 어두운 숲에서 늑대 떼와 마주쳤다.",
				"win": {"line": "사냥꾼은 붙잡았지만 보급대는 놓쳤다.", "next": "end", "fail": true},
				"lose": {"line": "사냥꾼도 보급대도 놓쳤다.", "next": "end", "fail": true},
			},
			"end": {"t": "end", "pos": Vector2(0.9, 0.5)},
		},
	},
	"archive": {
		"name": "수도원 서고 정리", "seal": "교회", "client": "수도원", "short": "금서 목록이 맞지 않는 서고", "tags": ["조사"], "risk": 1, "pin": Vector2(0.9, 0.15),
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
						"ok": {"line": "빠진 책은 '재앙의 연대기'. 대출 기록 없이 자리만 비어 있다.", "next": "n3", "flag": "lost_book"},
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
	"boars": {
		"name": "하웰 밭의 멧돼지", "seal": "왕관", "client": "촌장 토비아스", "short": "밤마다 밭을 갈아엎는 멧돼지 떼", "tags": ["토벌"], "risk": 2, "pin": Vector2(0.5, 0.75),
		"desc": "멧돼지 떼가 하웰 밭을 갈아엎는다. 이대로면 겨울 양식이 모자란다.",
		"intro": "boars_in", "outro_ok": "boars_ok", "outro_ng": "boars_ng",
		"skip": {"news": "멧돼지 떼가 하웰 밭을 갈아엎었다. 촌장 토비아스가 한숨을 쉬었다.", "flag": "farm_ruined"},
		"ok_flag": "farm_saved",
		"nodes": {
			"start": {"t": "start", "pos": Vector2(0.08, 0.5), "next": "n1"},
			"n1": {
				"t": "talk", "pos": Vector2(0.34, 0.5), "title": "갈아엎은 밭",
				"text": "밭고랑이 엉망이다.\n멧돼지는 해 질 녘에 마을 어귀로 내려온다.",
				"choices": [
					{"label": "발자국으로 길목을 찾는다", "stat": "int", "dc": 12, "who": "adelheid",
						"ok": {"line": "아델하이트가 발자국을 읽어 멧돼지가 지나는 길목을 찾았다.", "next": "n2", "set": {"ambush": true}},
						"ng": {"line": "발자국이 너무 많아 길목을 찾지 못했다.", "next": "n2"}},
					{"label": "썩은 사과로 미끼를 놓는다", "stat": "dex", "dc": 13, "who": "cecile",
						"ok": {"line": "세실이 놓은 미끼에 멧돼지들이 고개를 처박았다.", "next": "n2", "set": {"ambush": true}},
						"ng": {"line": "미끼는 늑대가 먼저 먹어 치웠다.", "next": "n2"}},
				],
			},
			"n2": {
				"t": "battle", "pos": Vector2(0.64, 0.5), "title": "마을 어귀", "battle": 4,
				"text": "해 질 녘, 멧돼지 떼가 마을 어귀로 내려온다.",
				"ambush_text": "길목에서 먼저 기다렸다. 적은 첫 차례에 움직이지 못한다.",
				"win": {"line": "길드는 멧돼지 떼를 숲으로 쫓아 보냈다.", "next": "end"},
				"lose": {"line": "멧돼지 떼에 밀려 밭 절반을 내줬다.", "next": "end", "fail": true},
			},
			"end": {"t": "end", "pos": Vector2(0.9, 0.5)},
		},
	},
	"hideout": {
		"name": "붉은 수염 소굴 정찰", "seal": "왕관", "client": "공증인 바실", "short": "협곡 안쪽 도적 천막촌", "tags": ["정찰", "전투"], "risk": 3, "pin": Vector2(0.8, 0.4),
		"desc": "붉은 수염 패거리의 소굴을 찾았다. 놈들이 길드를 치기 전에 먼저 살핀다.",
		"intro": "hideout_in", "outro_ok": "hideout_ok", "outro_ng": "hideout_ng",
		"skip": {"news": "붉은 수염 패거리가 하웰 길드를 칠 날을 고르고 있다는 소문이 돈다.", "flag": "hideout_skipped"},
		"ok_flag": "hideout_hit",
		"nodes": {
			"start": {"t": "start", "pos": Vector2(0.08, 0.5), "next": "n1"},
			"n1": {
				"t": "talk", "pos": Vector2(0.28, 0.5), "title": "협곡 길",
				"text": "협곡 위 망루에 횃불이 흔들린다.\n정면으로 가면 들킨다.",
				"choices": [
					{"label": "그림자를 따라 몰래 다가간다", "stat": "dex", "dc": 13, "who": "cecile",
						"ok": {"line": "세실이 망루 아래를 지나 천막촌 입구까지 길을 열었다.", "next": "n2", "set": {"ambush": true}},
						"ng": {"line": "자갈이 굴러 떨어졌다. 망루의 종이 울렸다.", "next": "n2"}},
					{"label": "절벽에 밧줄을 걸고 내려간다", "stat": "str", "dc": 13, "who": "lina",
						"ok": {"line": "리나가 밧줄을 붙잡아 일행을 천막촌 뒤로 내려보냈다.", "next": "n2", "set": {"ambush": true}},
						"ng": {"line": "밧줄이 미끄러졌다. 요란하게 떨어진 일행을 도적들이 둘러쌌다.", "next": "n2"}},
				],
			},
			"n2": {
				"t": "battle", "pos": Vector2(0.5, 0.5), "title": "천막촌", "battle": 5,
				"text": "모닥불 둘레에 도적들이 모여 있다.",
				"ambush_text": "들키지 않고 천막촌에 들어섰다. 적은 첫 차례에 움직이지 못한다.",
				"win": {"line": "길드는 천막촌 입구의 도적들을 쓰러뜨렸다.", "next": "n3"},
				"lose": {"line": "도적들에게 밀려 협곡을 빠져나왔다.", "next": "end", "fail": true},
			},
			"n3": {
				"t": "talk", "pos": Vector2(0.72, 0.5), "title": "두목의 천막",
				"text": "붉은 수염은 자리에 없다.\n탁자 위에 지도와 쪽지가 흩어져 있다.",
				"choices": [
					{"label": "지도의 표시를 읽는다", "stat": "int", "dc": 12, "who": "adelheid",
						"ok": {"line": "지도에 길드로 오는 길과 날짜가 적혀 있었다. 습격 길을 알아냈다.", "next": "end", "flag": "raid_plan"},
						"ng": {"line": "암호 같은 표시를 끝내 읽지 못했다.", "next": "end"}},
					{"label": "천막을 뒤진다", "stat": "dex", "dc": 13, "who": "cecile",
						"ok": {"line": "세실이 침상 밑에서 습격 계획이 적힌 쪽지를 찾았다.", "next": "end", "flag": "raid_plan"},
						"ng": {"line": "발소리가 들려 서둘러 천막을 빠져나왔다.", "next": "end"}},
				],
			},
			"end": {"t": "end", "pos": Vector2(0.92, 0.5)},
		},
	},
	"escort": {
		"name": "핍의 짐마차 호위", "seal": "상회", "client": "잡화점 주인 핍", "short": "숲길로 물건을 떼러 가는 짐마차", "tags": ["호위", "전투"], "risk": 1, "pin": Vector2(0.24, 0.32),
		"desc": "잡화점 짐마차가 옆 마을까지 숲길을 지난다. 무사히 다녀오면 회복약을 준다.",
		"intro": "escort_in", "outro_ok": "escort_ok", "outro_ng": "escort_ng",
		"skip": {"news": "핍의 짐마차가 숲길에서 늑대에게 쫓겨 돌아왔다. 잡화점 선반이 한동안 비었다.", "flag": "pip_robbed"},
		"ok_flag": "escort_done",
		"ok_items": {"potion": 2},
		"nodes": {
			"start": {"t": "start", "pos": Vector2(0.08, 0.5), "next": "n1"},
			"n1": {
				"t": "talk", "pos": Vector2(0.28, 0.5), "title": "무너진 다리",
				"text": "개울 다리가 반쯤 무너졌다.\n짐마차 바퀴가 진흙에 빠졌다.",
				"choices": [
					{"label": "짐마차를 밀어 올린다", "stat": "str", "dc": 12, "who": "lina",
						"ok": {"line": "리나가 바퀴를 들어 올려 짐마차가 다리를 건넜다.", "next": "n2"},
						"ng": {"line": "짐 몇 상자를 개울에 버리고서야 다리를 건넜다.", "next": "n2", "set": {"slow": true}}},
					{"label": "얕은 여울을 찾는다", "stat": "int", "dc": 12,
						"ok": {"line": "물살이 느린 여울을 찾아 짐마차를 무사히 건넸다.", "next": "n2"},
						"ng": {"line": "여울을 찾다 해가 졌다. 숲에서 밤을 보내야 한다.", "next": "n2", "set": {"slow": true}}},
				],
			},
			"n2": {
				"t": "camp", "pos": Vector2(0.5, 0.5), "title": "숲길 야영",
				"text": "짐마차 옆에 불을 피웠다.\n멀리서 늑대 울음이 들린다.",
				"line": "짐마차 옆에서 불을 지키며 밤을 보냈다.", "next": "n3",
			},
			"n3": {
				"t": "battle", "pos": Vector2(0.72, 0.5), "title": "늑대 떼", "battle": 3,
				"text": "어두운 숲에서 늑대 떼가 짐마차를 에워쌌다.",
				"win": {"line": "길드는 늑대 떼를 쫓고 짐마차를 옆 마을까지 데려갔다.", "next": "end"},
				"lose": {"line": "늑대 떼에 짐 절반을 내주고 겨우 빠져나왔다.", "next": "end", "fail": true},
			},
			"end": {"t": "end", "pos": Vector2(0.92, 0.5)},
		},
	},
}

## 장부 쪽마다 들어오는 메인 의뢰 (셋 중 둘). 1장은 3쪽: 3쪽은 위탁 의뢰와 결전 준비만
const WEEK_QUESTS_BY := {1: ["bandits", "trapper", "archive"], 2: ["boars", "hideout", "escort"], 3: []}
const WEEK_PICKS := 2
const FINALE_WEEK := 3  # 이 쪽을 마감하면 결전
const FINALE_BATTLE := 1

## 칸 종류별 표시
const NODE_KIND := {
	"start": {"name": "출발", "mark": "출"}, "talk": {"name": "판정", "mark": "말"}, "battle": {"name": "전투", "mark": "검"},
	"camp": {"name": "캠프", "mark": "불"}, "end": {"name": "완성", "mark": "끝"},
}
