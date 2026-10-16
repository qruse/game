extends Node
## 한 판의 진행 상태 (자동 로드 Game). 전투 장면으로 갔다 돌아와도 남는다.
## 흐름: 오프닝 → 길드 → 이번 주 의뢰(2개 고르기) → 의뢰마다 연대기 페이지 → 주말 소식 → 결전 → 체험판 끝

const LUCK_START := 2  # 페이지를 펼칠 때 받는 행운 주사위
const LUCK_MAX := 3

var week := 1
var party: Array = ["lina", "cecile", "adelheid"]
var picks: Array = []  # 이번 주에 고른 의뢰
var results := {}  # 의뢰 id -> "ok" / "ng"
var flags := {}
var pages: Array = []  # 완성한 연대기 페이지 [{quest, lines}]
var stage := "opening"  # opening / hub / page / news / finale / end
var page := {}  # 진행 중인 페이지 {quest, node, lines, visited, vars, luck}

var battle_req := {}  # 연대기 → 전투 {idx, party, luck, ambush, boss_hp, back}
var battle_res := {}  # 전투 → 연대기 {result, luck}


func reset() -> void:
	week = 1
	party = ["lina", "cecile", "adelheid"]
	picks = []
	results = {}
	flags = {}
	pages = []
	stage = "opening"
	page = {}
	battle_req = {}
	battle_res = {}


## 그림 불러오기: 웹 빌드는 res://art (prepare_web 이 복사), 편집기에서는 ../art/final 도 읽는다
func tex(rel: String) -> Texture2D:
	if rel == "":
		return null
	var res := "res://art/" + rel
	if ResourceLoader.exists(res):
		return load(res)
	var path := ProjectSettings.globalize_path("res://").path_join("../art/final/" + rel)
	if OS.has_feature("web") or not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if img != null else null


## 파티에서 이 능력치가 가장 높은 동료 (who 가 정해져 있으면 그 동료, 없으면 null)
func best(stat: String, who := "") -> Dictionary:
	var Defs = load("res://scripts/fk_defs.gd")
	var pick := ""
	var mod := -99
	for k in party:
		if who != "" and k != who:
			continue
		var m: int = Defs.HEROES[k].mod.get(stat, 0)
		if m > mod:
			mod = m
			pick = k
	if pick == "":
		return {}
	return {"key": pick, "name": Defs.HEROES[pick].name, "mod": mod}


## d20 + mod >= dc 일 확률
static func chance(mod: int, dc: int) -> float:
	return clampf((21.0 - (dc - mod)) / 20.0, 0.05, 0.95)
