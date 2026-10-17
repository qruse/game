extends RefCounted
## 길드 운영 데이터: 재건 공사, 시설, 길드 등급, 모험가 인력풀(S~F), 스카우트, 위탁 의뢰.
## 규칙은 docs/04-game-flow.md 3.8절. 숫자는 체험판용 가안이라 밸런스 때 고친다.

const START_GOLD := 300
const MATS := {"wood": "목재", "iron": "철", "herb": "약초"}

## 길드 등급 (명성은 쓰면 줄지 않고 쌓인다)
const RANKS := [
	{"name": "동패", "fame": 0},
	{"name": "은패", "fame": 60},
	{"name": "금패", "fame": 200},
]

## 재건 공사: 단계마다 배경이 바뀌고, 시설 칸과 시설 최고 레벨이 늘어난다
const STAGES := [
	{"name": "폐허 정리", "gold": 0, "mats": {}, "slots": 2, "max_lv": 1, "scout_max": 1,
		"bg": "backgrounds/scene/bg_guildhall_ruined.png", "desc": "무너진 지붕 아래 쓸 만한 방 두 칸만 치웠다."},
	{"name": "지붕과 홀 수리", "gold": 600, "mats": {"wood": 6}, "slots": 4, "max_lv": 2, "scout_max": 3,
		"bg": "backgrounds/scene/bg_guildhall_restored1.png", "desc": "지붕을 다시 얹고 큰 홀을 고친다. 시설 4칸, 최고 2레벨."},
	{"name": "증축과 2층 복구", "gold": 1800, "mats": {"wood": 10, "iron": 6}, "slots": 7, "max_lv": 3, "scout_max": 5,
		"bg": "backgrounds/scene/bg_guildhall_restored2.png", "desc": "2층과 별채를 되살린다. 시설 7칸, 최고 3레벨."},
]

## 시설. cost[레벨-1] = 그 레벨로 올리는 값. fx[레벨-1] = 효과 설명
const FACILITIES := {
	"board": {"name": "의뢰 게시판", "max": 3,
		"fx": ["메인 의뢰와 위탁 의뢰를 받는다", "위탁 의뢰가 1개 더 붙는다", "주마다 메인 의뢰를 1개 더 고를 수 있다 (3장 이후)"],
		"cost": [{}, {"gold": 300, "wood": 3}, {"gold": 700, "wood": 4, "iron": 3}]},
	"scout": {"name": "스카우트실", "max": 5,
		"fx": ["지원자 2명 · 최고 D급", "지원자 3명 · 최고 C급", "지원자 3명 · 최고 B급", "지원자 4명 · 최고 A급", "지원자 4명 · S급이 드물게"],
		"cost": [{}, {"gold": 200, "wood": 2}, {"gold": 400, "wood": 3, "iron": 1}, {"gold": 900, "iron": 5}, {"gold": 1400, "iron": 8}]},
	"dorm": {"name": "숙소", "max": 3,
		"fx": ["모험가 명부 6명 · 동료 정원 4명", "모험가 명부 10명 · 동료 정원 6명", "모험가 명부 14명 · 동료 정원 8명"],
		"cost": [{"gold": 150, "wood": 2}, {"gold": 300, "wood": 3}, {"gold": 600, "wood": 4, "iron": 2}]},
	"records": {"name": "기록실", "max": 3,
		"fx": ["위탁 의뢰 성공률이 숫자로 보인다", "메인 의뢰의 적 구성이 미리 보인다", "한 번 싸운 적의 약점이 표시된다"],
		"cost": [{"gold": 150, "herb": 1}, {"gold": 300, "wood": 2, "herb": 2}, {"gold": 600, "wood": 3, "herb": 4}]},
	"training": {"name": "훈련장", "max": 3,
		"fx": ["파티에 못 간 동료도 경험치 30%", "파티에 못 간 동료도 경험치 50%", "파티에 못 간 동료도 경험치 70%"],
		"cost": [{"gold": 200, "wood": 3}, {"gold": 400, "wood": 3, "iron": 2}, {"gold": 800, "iron": 4}]},
	"armory": {"name": "무기고", "max": 3,
		"fx": ["대장간 강화 상한 +1", "대장간 강화 상한 +2", "대장간 강화 상한 +3"],
		"cost": [{"gold": 200, "iron": 2}, {"gold": 400, "iron": 3}, {"gold": 800, "iron": 5}]},
	"kitchen": {"name": "주방", "max": 3,
		"fx": ["캠프 회복량 +", "의뢰 출발 때 식재료 버프", "캠프 회복량 ++"],
		"cost": [{"gold": 150, "herb": 2}, {"gold": 300, "herb": 3}, {"gold": 600, "herb": 4, "wood": 2}]},
}
const FACILITY_ORDER := ["board", "scout", "dorm", "records", "training", "armory", "kitchen"]
const START_FACILITIES := {"board": 1, "scout": 1}
const ROSTER_CAP := [4, 6, 10, 14]  # 숙소 레벨 0~3

## 모험가 등급
const GRADES := ["F", "D", "C", "B", "A", "S"]
const GRADE_INFO := {
	"F": {"power": [10, 20], "fee": 20, "share": 10, "col": Color(0.49, 0.45, 0.41)},
	"D": {"power": [25, 35], "fee": 40, "share": 15, "col": Color(0.54, 0.35, 0.23)},
	"C": {"power": [40, 50], "fee": 80, "share": 20, "col": Color(0.31, 0.48, 0.29)},
	"B": {"power": [55, 65], "fee": 160, "share": 25, "col": Color(0.24, 0.42, 0.66)},
	"A": {"power": [70, 80], "fee": 320, "share": 30, "col": Color(0.48, 0.29, 0.66)},
	"S": {"power": [85, 95], "fee": 640, "share": 35, "col": Color(0.79, 0.64, 0.36)},
}
## 스카우트실 레벨 → 지원자 수, 나올 수 있는 최고 등급
const SCOUT := [[2, "D"], [3, "C"], [3, "B"], [4, "A"], [4, "S"]]

const CLASSES := {
	"warrior": {"name": "전사", "tags": ["토벌", "호위"]},
	"archer": {"name": "궁수", "tags": ["토벌", "정찰"]},
	"mage": {"name": "마법사", "tags": ["조사", "토벌"]},
	"rogue": {"name": "도적", "tags": ["정찰", "운반"]},
	"guardian": {"name": "수호자", "tags": ["호위", "토벌"]},
	"priest": {"name": "사제", "tags": ["조사", "호위"]},
	"novice": {"name": "견습", "tags": ["운반", "채집"]},
}
const TAGS := ["토벌", "호위", "정찰", "조사", "채집", "운반"]

## 특성: chance(성공률 가감, tag 가 있으면 그 일에만), gold(보상 배율 가감), safe(실패해도 안 다침), fast(승급이 빠름)
const TRAITS := [
	{"name": "백발백중", "tag": "토벌", "chance": 0.15},
	{"name": "겁쟁이", "tag": "토벌", "chance": -0.1},
	{"name": "허세", "tag": "토벌", "chance": -0.05},
	{"name": "길눈이 밝음", "tag": "정찰", "chance": 0.15},
	{"name": "책벌레", "tag": "조사", "chance": 0.15},
	{"name": "약초꾼 집안", "tag": "채집", "chance": 0.2},
	{"name": "튼튼한 등", "tag": "운반", "chance": 0.2},
	{"name": "말주변", "tag": "호위", "chance": 0.1},
	{"name": "철벽", "safe": true},
	{"name": "손버릇", "gold": 0.15},
	{"name": "흥정꾼", "gold": 0.1},
	{"name": "덜렁이", "chance": -0.05},
	{"name": "운이 좋음", "chance": 0.05},
	{"name": "성실함", "fast": true},
	{"name": "술고래", "chance": -0.05, "gold": 0.05},
	{"name": "평범함"},
]

const NAMES := ["브람", "콘라드", "피트", "텁", "미라", "오르반", "세라핀", "한스", "릴리", "도르", "마틸", "에밋", "요르크", "니나",
	"바르톨", "쿠르트", "엘사", "로타르", "지젤", "프리츠", "안젤름", "베르타", "울리히", "카트린", "하랄드", "이다", "모리츠", "레나",
	"게로", "알마", "티보", "율레", "벤노", "클라라", "오토", "마고", "루트", "실케", "디터", "헤드윅"]

## 위탁 의뢰 견본: [이름, 특기]
const JOBS := [
	["늑대 무리 토벌", "토벌"], ["들쥐 떼 소탕", "토벌"], ["고블린 정찰병 처치", "토벌"], ["멧돼지 사냥", "토벌"],
	["상인 마차 호위", "호위"], ["순례자 호위", "호위"], ["세금 마차 호위", "호위"],
	["옛 광산 정찰", "정찰"], ["국경 숲 정찰", "정찰"], ["강 건너 길 살피기", "정찰"],
	["유령 소문 조사", "조사"], ["우물 물맛 조사", "조사"], ["실종된 양치기 찾기", "조사"],
	["약초 채집", "채집"], ["버섯 채집", "채집"], ["꿀벌집 따기", "채집"],
	["곡물 운반", "운반"], ["편지 배달", "운반"], ["목재 실어 나르기", "운반"],
]
## 위탁 의뢰 난도: 필요 실력. 길드 등급이 오를수록 위쪽 칸까지 나온다
const JOB_REQ := [20, 35, 50, 70, 90]
const JOB_MATS := {"토벌": "iron", "호위": "", "정찰": "", "조사": "herb", "채집": "herb", "운반": "wood"}

## 메인 의뢰 보상 (체험판 공통값)
const QUEST_REWARD := {
	"ok": {"gold": 220, "fame": 18, "mats": {"wood": 3, "iron": 1}},
	"ng": {"gold": 90, "fame": 6, "mats": {"wood": 1}},
}

## 마을 장소: 그림(bg_town_harwell, 1920×1080) 위의 자리
const PLACES := {
	"guild": {"name": "하웰 모험가 길드", "at": Vector2(0.27, 0.27)},
	"tavern": {"name": "선술집 「구리 국자」", "at": Vector2(0.13, 0.55)},
	"smithy": {"name": "대장간", "at": Vector2(0.66, 0.45)},
	"store": {"name": "잡화점", "at": Vector2(0.86, 0.6)},
	"chief": {"name": "촌장 집", "at": Vector2(0.86, 0.22)},
	"square": {"name": "우물 광장", "at": Vector2(0.5, 0.66)},
}

## 선술집 소문 (주마다)
const RUMORS := {
	1: ["북쪽 마을 사람들이 밤마다 도적 걱정을 한대.", "숲길 덫사냥꾼, 요즘 씀씀이가 헤퍼졌다더라."],
	2: ["붉은 수염 패거리가 길드를 노린다는 소문이 돌아. 단단히 준비해 둬.", "모험가 지망생들이 스카우트실 앞을 기웃거리더라."],
}


static func cost_text(c: Dictionary) -> String:
	var out: Array = []
	if c.get("gold", 0) > 0:
		out.append("금화 %d" % c.gold)
	for k in MATS:
		if c.get(k, 0) > 0:
			out.append("%s %d" % [MATS[k], c[k]])
	return " · ".join(PackedStringArray(out)) if not out.is_empty() else "무료"
