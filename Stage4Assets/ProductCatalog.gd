extends RefCounted
const P=preload("res://GameProgress.gd")
const TITLES=["Sink","Faucet","Hood","Cooktop"]
const IDS=[
	["sink-01-stainless-m","sink-02-stainless-s","sink-03-g-sink-76","sink-04-raku-suru","sink-05-mu-black"],
	["faucet-01","faucet-02","faucet-03","faucet-04","faucet-05"],
	["hood-01-hottokleen","hood-02-smart-ii-black","hood-03-stylish","hood-04-thin","hood-05-boots-sirocco"],
	["JUASDS17WS","JUAED21WB","JUASHW38R7","JUASW28P1W","JUASG32T1V"]]
const NAMES=[
	["Stainless sink M","Stainless sink S","G sink 76","Raku-suru sink","Mu-black sink"],
	["Pull-out faucet","Angled spout","High curved spout","Pull-out spray","Compact faucet"],
	["Hottokleen · Silver","Smart Hood II · Black","Stylish hood","Thin hood","Boots-type sirocco"],
	["JUASDS17WS","JUAED21WB","JUASHW38R7","JUASW28P1W","JUASG32T1V"]]
const FOLDERS=["Sinks","Faucets","Hoods","Cooktops"]
const TRANSLATIONS={
	"Kitchen parts":["キッチンパーツ","မီးဖိုချောင်ပစ္စည်းများ"],
	"3D Kitchen Preview":["3Dキッチンプレビュー","3D မီးဖိုချောင်ပုံ"],
	"Customer Request":["お客様のご要望","ဖောက်သည်၏တောင်းဆိုချက်"],
	"Ms. Hosokawa":["細川様","မစ္စ ဟိုဆိုကာဝါ"],
	"Reference Plan":["参考図面","ကိုးကားရန်ပုံစံ"],
	"Sink":["シンク","ဘေစင်"],"Faucet":["水栓","ရေပိုက်ခေါင်း"],"Hood":["レンジフード","အငွေ့စုပ်စက်"],"Cooktop":["加熱機器","မီးဖို"],
	"Choose a sink":["シンクを選ぶ","ဘေစင်ရွေးပါ"],"Choose a faucet":["水栓を選ぶ","ရေပိုက်ခေါင်းရွေးပါ"],
	"Choose a hood":["フードを選ぶ","အငွေ့စုပ်စက်ရွေးပါ"],"Choose a cooktop":["加熱機器を選ぶ","မီးဖိုရွေးပါ"],
	"Cancel":["キャンセル","ပယ်ဖျက်မည်"],"Use Selection":["この商品にする","ဤပစ္စည်းကိုသုံးမည်"],"Check Answer":["答え合わせ","အဖြေစစ်မည်"],
	"Home":["ホーム","ပင်မ"],"Menu":["メニュー","မီနူး"],"Front":["正面","ရှေ့"],"Rotate":["回転","လှည့်မည်"],
	"Zoom −":["縮小 −","ချုံ့ −"],"Zoom +":["拡大 +","ချဲ့ +"],"Stage 4":["ステージ4","အဆင့် ၄"],
	"Drag to rotate · Scroll to zoom":["ドラッグで回転・スクロールで拡大縮小","ဆွဲ၍လှည့်ပါ · Scroll ဖြင့်ချဲ့/ချုံ့ပါ"],
	"Stainless sink M":["ステンレスシンク M","စတီးဘေစင် M"],"Stainless sink S":["ステンレスシンク S","စတီးဘေစင် S"],
	"G sink 76":["Gシンク76","G ဘေစင် 76"],"Raku-suru sink":["ラクするーシンク","Raku-suru ဘေစင်"],"Mu-black sink":["ムーブラックシンク","Mu-black ဘေစင်"],
	"Pull-out faucet":["引出し式水栓","ဆွဲထုတ်နိုင်သော ရေပိုက်ခေါင်း"],"Angled spout":["斜め吐水口の水栓","စောင်းတံ ရေပိုက်ခေါင်း"],
	"High curved spout":["ハイアーチ水栓","အမြင့်ကွေး ရေပိုက်ခေါင်း"],"Pull-out spray":["シャワー水栓","ရေဖြန်း ရေပိုက်ခေါင်း"],"Compact faucet":["コンパクト水栓","အသေးစား ရေပိုက်ခေါင်း"],
	"Hottokleen · Silver":["ほっとくリーン・シルバー","Hottokleen · ငွေရောင်"],"Smart Hood II · Black":["スマートフードII・ブラック","Smart Hood II · အနက်ရောင်"],
	"Stylish hood":["スタイリッシュフード","Stylish hood"],"Thin hood":["薄型フード","ပါးလွှာသော hood"],"Boots-type sirocco":["ブーツ型シロッコ","Boots-type sirocco"]}
static var _images: Dictionary={}

static func text(key: String) -> String:
	var language=P.get_language()
	if language=="en" or not TRANSLATIONS.has(key):return key
	return TRANSLATIONS[key][0 if language=="jp" else 1]

static func image(category: int,index: int) -> Texture2D:
	var path="res://Stage4Assets/Products/%s/%s.png"%[FOLDERS[category],IDS[category][index]]
	if not _images.has(path) and ResourceLoader.exists(path):_images[path]=load(path)
	return _images.get(path)

static func caption(category: int,index: int) -> String:return text(NAMES[category][index])
