extends RefCounted
# Fixed assessed meshes, independent of UI language.
const NAMES: Array[String]=["カウンター","キッチンボード","フード","腰壁","シンク","水栓","IHクッキングヒーター","引き出し"]
const COUNT: int=8
const CHALLENGE_STEPS: int=2+COUNT
const ACCEPTED: Array=[
 ["カウンター","カウンタートップ","ワークトップ","天板","キッチンカウンター"],
 ["キッチンボード","キッチンパネル","キッチンパネルボード"],
 ["フード","レンジフード","換気扇"],
 ["腰壁","コシカベ","キッチン腰壁"],
 ["シンク","流シ","流シ台","流台"],
 ["水栓","水栓金具","蛇口","混合水栓","スイセン","ジャグチ"],
 ["IH","IHクッキングヒーター","IHコンロ","IHヒーター","電磁調理器"],
 ["引き出し","引出し","引出","抽斗","ヒキダシ"]
]
static func normalize(value: String) -> String:
 var result:=""
 var half:="ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ"
 var full:="ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン"
 var voiced:={"カ":"ガ","キ":"ギ","ク":"グ","ケ":"ゲ","コ":"ゴ","サ":"ザ","シ":"ジ","ス":"ズ","セ":"ゼ","ソ":"ゾ","タ":"ダ","チ":"ヂ","ツ":"ヅ","テ":"デ","ト":"ド","ハ":"バ","ヒ":"ビ","フ":"ブ","ヘ":"ベ","ホ":"ボ","ウ":"ヴ"}
 for character in value.strip_edges():
  var half_index:=half.find(character)
  if half_index>=0:character=full.substr(half_index,1)
  if character in ["ﾞ","゛","゙"] and not result.is_empty():
   var last:=result.right(1)
   if voiced.has(last):result=result.left(result.length()-1)+str(voiced[last])
   continue
  if character in ["ﾟ","゜","゚"] and not result.is_empty():
   var semi:={"ハ":"パ","ヒ":"ピ","フ":"プ","ヘ":"ペ","ホ":"ポ"}
   var last:=result.right(1)
   if semi.has(last):result=result.left(result.length()-1)+str(semi[last])
   continue
  var code:=character.unicode_at(0)
  if code in [9,10,13,32,0x3000]:continue
  if code>=0xFF01 and code<=0xFF5E:code-=0xFEE0
  if code>=0x3041 and code<=0x3096:code+=0x60 # Hiragana to Katakana.
  if code==0xFF70:code=0x30FC
  result+=String.chr(code)
 return result.replace("－","ー").replace("−","ー").to_upper()

static func is_correct(index: int, value: String) -> bool:
 if index<0 or index>=NAMES.size():return false
 var normalized:=normalize(value)
 for answer in ACCEPTED[index]:
  if normalized==normalize(answer):return true
 return false

static func has_hiragana(value: String) -> bool:
 for character in value:
  var code:=character.unicode_at(0)
  if code>=0x3041 and code<=0x3096:return true
 return false

static func conversion_candidates(reading: String) -> Array[String]:
 # Conversion depends on the reading only, never on the numbered question.
 var table:={
  "カウンター":["カウンター"],"カウンタートップ":["カウンタートップ"],
  "ワークトップ":["ワークトップ"],"テンバン":["天板"],
  "キッチンカウンター":["キッチンカウンター"],
  "キッチンボード":["キッチンボード"],"キッチンパネル":["キッチンパネル"],
  "フード":["フード","風土"],"フウド":["風土","フード"],
  "レンジフード":["レンジフード"],"カンキセン":["換気扇"],
  "コシカベ":["腰壁"],"キッチンコシカベ":["キッチン腰壁"],
  "シンク":["シンク","真紅"],"ナガシ":["流し"],"ナガシダイ":["流し台"],"スイセン":["水栓","推薦"],
  "スイセンカナグ":["水栓金具"],"ジャグチ":["蛇口"],"コンゴウスイセン":["混合水栓"],
  "アイエイチ":["IH"],"アイエイチクッキングヒーター":["IHクッキングヒーター"],
  "IHクッキングヒーター":["IHクッキングヒーター"],"IHコンロ":["IHコンロ"],
  "ヒキダシ":["引き出し","引出し"]
 }
 var result: Array[String]=[]
 var key:=normalize(reading)
 if table.has(key):result.assign(table[key])
 return result

static func needs_conversion(value: String) -> bool:
 if not has_hiragana(value):return false
 # Written Japanese may contain okurigana, e.g. 流し台.
 for character in value:
  var code:=character.unicode_at(0)
  if code>=0x3400 and code<=0x9fff:return false
 return true
