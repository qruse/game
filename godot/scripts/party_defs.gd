extends RefCounted
## 동료 성장 · 장비 · 잡화점 물건 (docs/04-game-flow.md 3.1 대장간·잡화점, 5절 성장, 6절 동료 유대)
## 규칙은 단순하게: 동료마다 레벨 하나, 무기 하나, 방어구 하나.

# ── 레벨 ──
const LV_MAX := 10
const XP_OK := 100  # 의뢰 페이지를 끝낸 파티 동료 (성공)
const XP_NG := 60  # 절반의 성공
const XP_FINALE := 150  # 결전
const LV_HP := 2  # 레벨마다 최대 체력 +2
## 다음 레벨까지 필요한 경험치
static func xp_need(lv: int) -> int:
	return 80 + lv * 40


## 레벨로 오르는 스킬 위력 (짝수 레벨마다 +1)
static func lv_power(lv: int) -> int:
	return lv / 2


# ── 장비: 동료마다 무기 하나, 방어구 하나. 대장간에서 단계를 바꾸고 +강화 ──
## 무기: 단계마다 스킬 위력 +1, 강화마다 위력 +1
## 방어구: 단계마다 방어 +1, 강화마다 최대 체력 +2
const GEAR_KIND := {"weapon": "무기", "armor": "방어구"}
const TIERS := [
	{"name": "낡은", "gold": 0, "iron": 0, "build": 0},
	{"name": "철", "gold": 150, "iron": 1, "build": 0},
	{"name": "강철", "gold": 400, "iron": 3, "build": 2},
	{"name": "명장", "gold": 900, "iron": 5, "build": 4},
]
const SELL_RATE := 0.3  # 새 장비를 사면 쓰던 장비는 이 비율로 대장간에 판다
const PLUS_BASE := 1  # 무기고가 없을 때 강화 상한. 무기고 레벨마다 +1

const GEAR_NAMES := {
	"lina": {"weapon": "롱소드", "armor": "판금 갑옷"},
	"cecile": {"weapon": "쌍단검", "armor": "가죽 갑옷"},
	"adelheid": {"weapon": "지팡이", "armor": "마법사 로브"},
	"miriam": {"weapon": "순례 지팡이", "armor": "순례자 망토"},
}


static func gear_name(hero: String, kind: String, tier: int, plus: int) -> String:
	var s: String = "%s %s" % [TIERS[tier].name, GEAR_NAMES[hero][kind]]
	return s + (" +%d" % plus if plus > 0 else "")


## 강화 비용: +1 → +2 → … 단계가 높을수록 비싸다
static func plus_cost(tier: int, plus: int) -> Dictionary:
	return {"gold": 40 * (plus + 1) * (tier + 1), "iron": plus + 1}


# ── 잡화점 물건 ──
## kind: use(소모품) / gift(선물) / food(식재료)
const ITEMS := {
	"potion": {"name": "회복약", "kind": "use", "gold": 30, "desc": "전투에서 동료 하나 체력 10 회복 (행동 한 번)"},
	"charm": {"name": "행운 부적", "kind": "use", "gold": 60, "desc": "의뢰를 떠날 때 하나 써서 행운 주사위 +1"},
	"knight_book": {"name": "기사 이야기책", "kind": "gift", "gold": 40, "desc": "표지에 금박 기사가 그려진 모험담"},
	"apple": {"name": "사과 바구니", "kind": "gift", "gold": 15, "desc": "빨갛게 잘 익은 하웰 사과"},
	"trinket": {"name": "반짝이 장신구", "kind": "gift", "gold": 50, "desc": "유리알이 박힌 싸구려 목걸이"},
	"tea": {"name": "향 좋은 찻잎", "kind": "gift", "gold": 35, "desc": "남쪽에서 온 말린 찻잎"},
	"candle": {"name": "밀랍 양초", "kind": "gift", "gold": 20, "desc": "오래 타는 밀랍 양초 한 묶음"},
	"ink": {"name": "고급 잉크와 깃펜", "kind": "gift", "gold": 45, "desc": "수도 문방구의 검은 잉크"},
	"flowers": {"name": "들꽃 다발", "kind": "gift", "gold": 15, "desc": "광장 꽃집의 작은 다발"},
	"meat": {"name": "훈제 고기", "kind": "food", "gold": 20, "desc": "마르타에게 납품하거나 주방 도시락에 쓴다"},
	"mushroom": {"name": "버섯 바구니", "kind": "food", "gold": 15, "desc": "마르타에게 납품하거나 주방 도시락에 쓴다"},
	"honey": {"name": "꿀단지", "kind": "food", "gold": 25, "desc": "마르타에게 납품하거나 주방 도시락에 쓴다"},
}
const STORE_ORDER := ["potion", "charm", "knight_book", "apple", "trinket", "tea", "candle", "ink", "flowers", "meat", "mushroom", "honey"]

## 선물: 좋아함 +6 / 보통 +3 / 별로 +1. 한 사람에게 한 주에 한 번
const GIFT_LIKE := 6
const GIFT_OK := 3
const GIFT_MEH := 1
## like / meh 목록 + 반응 [좋아함, 보통, 별로]
const GIFTS := {
	"nora": {"like": ["ink"], "meh": ["trinket"],
		"say": ["수도 문방구 잉크네요! 결재 도장보다 더 아껴 쓸게요.", "감사합니다. 장부에 적어 둘게요.", "…장신구는 장부 정리에 0점이에요."]},
	"martha": {"like": ["flowers"], "meh": [],
		"say": ["어머, 꽃이라니! 카운터에 꽂아 둬야지.", "고맙다, 단장.", "고맙다, 단장."]},
}


static func gift_grade(who: String, item: String) -> int:
	var g: Dictionary = GIFTS.get(who, {})
	if item in g.get("like", []):
		return 0
	if item in g.get("meh", []):
		return 2
	return 1
