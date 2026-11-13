extends RefCounted
# Names are attached to fixed numbered model parts, independent of UI language.
const NAMES: Array[String]=["カウンター","キッチンボード","フード","腰壁","シンク"]
const ACCEPTED: Array=[
 ["カウンター","カウンタートップ","ワークトップ","天板","キッチンカウンター"],
 ["キッチンボード","キッチンパネル","キッチンパネルボード"],
 ["フード","レンジフード","換気扇"],
 ["腰壁","コシカベ","キッチン腰壁"],
 ["シンク","流シ","流シ台","流台"]
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
  if code>=0x3041 and code<=0x3096:code+=0x60 # Hiragana to Katakana.
  if code==0xFF70:code=0x30FC
  result+=String.chr(code)
 return result.replace("－","ー").replace("−","ー")

static func is_correct(index: int, value: String) -> bool:
 if index<0 or index>=NAMES.size():return false
 var normalized:=normalize(value)
 for answer in ACCEPTED[index]:
  if normalized==normalize(answer):return true
 return false
