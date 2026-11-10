extends RefCounted
const MESSAGES = [
	{
		"en": "Kitchen Layout Game",
		"mm": "မီးဖိုချောင် အခန်းဖွဲ့စည်းမှုဂိမ်း",
		"jp": "キッチン間取りゲーム",
		"aliases": []
	},
	{
		"en": "Start Game",
		"mm": "ဂိမ်းစမည်",
		"jp": "ゲーム開始",
		"aliases": []
	},
	{
		"en": "Select Level",
		"mm": "အဆင့်ရွေးမည်",
		"jp": "ステージ選択",
		"aliases": [
			"Select Level",
			"အဆင့်ရွေးမည်",
			"ステージ選択",
			"SELECT A LEVEL"
		]
	},
	{
		"en": "Select a Level",
		"mm": "အဆင့်တစ်ခု ရွေးပါ",
		"jp": "ステージを選択",
		"aliases": []
	},
	{
		"en": "Select Language",
		"mm": "ဘာသာစကား ရွေးပါ",
		"jp": "言語を選択",
		"aliases": []
	},
	{
		"en": "Continue",
		"mm": "ဆက်သွားမည်",
		"jp": "続ける",
		"aliases": []
	},
	{
		"en": "Game Guide",
		"mm": "ကစားနည်းလမ်းညွှန်",
		"jp": "ゲームガイド",
		"aliases": []
	},
	{
		"en": "Settings",
		"mm": "ဆက်တင်များ",
		"jp": "設定",
		"aliases": []
	},
	{
		"en": "Back to Game",
		"mm": "ဂိမ်းသို့ ပြန်မည်",
		"jp": "ゲームに戻る",
		"aliases": []
	},
	{
		"en": "Back to Home",
		"mm": "ပင်မစာမျက်နှာသို့",
		"jp": "ホームに戻る",
		"aliases": []
	},
	{
		"en": "Back to Levels",
		"mm": "အဆင့်စာရင်းသို့",
		"jp": "ステージ一覧に戻る",
		"aliases": []
	},
	{
		"en": "Home",
		"mm": "ပင်မစာမျက်နှာ",
		"jp": "ホーム",
		"aliases": []
	},
	{
		"en": "Play",
		"mm": "ကစားမည်",
		"jp": "プレイ",
		"aliases": []
	},
	{
		"en": "Restart",
		"mm": "ပြန်စမည်",
		"jp": "やり直す",
		"aliases": []
	},
	{
		"en": "Locked",
		"mm": "မဖွင့်ရသေး",
		"jp": "ロック中",
		"aliases": []
	},
	{
		"en": "Unlocked",
		"mm": "ဖွင့်ထားပြီး",
		"jp": "解放済み",
		"aliases": []
	},
	{
		"en": "Coming soon",
		"mm": "မကြာမီ ရရှိမည်",
		"jp": "近日公開",
		"aliases": []
	},
	{
		"en": "Ready",
		"mm": "ကစားနိုင်ပြီ",
		"jp": "プレイ可能",
		"aliases": []
	},
	{
		"en": "Completed",
		"mm": "ပြီးစီးပြီး",
		"jp": "完了",
		"aliases": []
	},
	{
		"en": "Not completed",
		"mm": "မပြီးစီးသေး",
		"jp": "未完了",
		"aliases": []
	},
	{
		"en": "Stage %d",
		"mm": "အဆင့် %d",
		"jp": "ステージ %d",
		"aliases": []
	},
	{
		"en": "Stage %02d",
		"mm": "အဆင့် %02d",
		"jp": "ステージ %02d",
		"aliases": []
	},
	{
		"en": "Levels",
		"mm": "အဆင့်စာရင်း",
		"jp": "ステージ一覧",
		"aliases": []
	},
	{
		"en": "Trainee",
		"mm": "သင်တန်းသား",
		"jp": "研修生",
		"aliases": []
	},
	{
		"en": "Progress through kitchen design missions step by step.",
		"mm": "မီးဖိုချောင်ဒီဇိုင်း မစ်ရှင်များကို တစ်ဆင့်ချင်း ကစားပါ။",
		"jp": "キッチン設計の課題を順番に進めましょう。",
		"aliases": []
	},
	{
		"en": "LDK Boundary Drawing",
		"mm": "LDK နယ်နိမိတ်ဆွဲခြင်း",
		"jp": "LDKの境界を描く",
		"aliases": []
	},
	{
		"en": "Pipe Shaft Q&A",
		"mm": "ပိုက်ရှပ် အမေးအဖြေ",
		"jp": "パイプシャフトの質問",
		"aliases": []
	},
	{
		"en": "S-Class Kitchen Selection",
		"mm": "S-Class ရွေးချယ်ခြင်း",
		"jp": "Sクラスのキッチン選択",
		"aliases": []
	},
	{
		"en": "Open stage",
		"mm": "အဆင့်ဖွင့်မည်",
		"jp": "ステージを開く",
		"aliases": []
	},
	{
		"en": "Choose any available stage to play.",
		"mm": "ဖွင့်ထားသော အဆင့်တစ်ခုကို ရွေးပြီး ကစားပါ။",
		"jp": "プレイ可能なステージを選んでください。",
		"aliases": []
	},
	{
		"en": "Mission Guide",
		"mm": "မစ်ရှင်လမ်းညွှန်",
		"jp": "ミッションガイド",
		"aliases": []
	},
	{
		"en": "How to Play",
		"mm": "ကစားနည်း",
		"jp": "遊び方",
		"aliases": []
	},
	{
		"en": "01  LISTEN TO THE CUSTOMER",
		"mm": "၀၁  ဝယ်ယူသူ၏ တောင်းဆိုချက်ကို နားထောင်ပါ",
		"jp": "01  お客様の要望を聞く",
		"aliases": []
	},
	{
		"en": "Choose Japanese or Myanmar, listen to the customer and review the layout request.",
		"mm": "ဘာသာစကားရွေးပြီး ဝယ်ယူသူပြောသည့် အခန်းဖွဲ့စည်းမှု တောင်းဆိုချက်ကို နားထောင်ပါ။",
		"jp": "言語を選び、お客様の間取りの要望を確認してください。",
		"aliases": []
	},
	{
		"en": "02  DRAW THE REQUESTED PLAN",
		"mm": "၀၂  တောင်းဆိုထားသော ပုံစံကို ဆွဲပါ",
		"jp": "02  指定された図面を描く",
		"aliases": []
	},
	{
		"en": "Use the grid tools to sketch the requested walls and press OK to check your layout.",
		"mm": "ဇယားကွက်ပေါ်တွင် တောင်းဆိုထားသော နံရံများကို ဆွဲပြီး အတည်ပြုမည် ခလုတ်ကို နှိပ်ပါ။",
		"jp": "グリッドに指定の壁を描き、確認ボタンで図面を確認してください。",
		"aliases": []
	},
	{
		"en": "03  ANSWER THE CUSTOMER",
		"mm": "၀၃  ဝယ်ယူသူ၏ မေးခွန်းကို ဖြေပါ",
		"jp": "03  お客様の質問に答える",
		"aliases": []
	},
	{
		"en": "Stages 1, 2, and 3 are available to play.",
		"mm": "အဆင့် ၁၊ ၂ နှင့် ၃ ကို ကစားနိုင်ပါသည်။",
		"jp": "ステージ1・2・3をプレイできます。",
		"aliases": []
	},
	{
		"en": "Progress and language selection are saved on this device.",
		"mm": "တိုးတက်မှုနှင့် ရွေးထားသောဘာသာစကားကို ဤစက်တွင် သိမ်းထားသည်။",
		"jp": "進行状況と言語設定はこの端末に保存されます。",
		"aliases": []
	},
	{
		"en": "View Mission Guide",
		"mm": "မစ်ရှင်လမ်းညွှန် ကြည့်မည်",
		"jp": "ミッションガイドを見る",
		"aliases": []
	},
	{
		"en": "Language",
		"mm": "ဘာသာစကား",
		"jp": "言語",
		"aliases": []
	},
	{
		"en": "Game Volume",
		"mm": "ဂိမ်းအသံ အတိုးအကျယ်",
		"jp": "ゲーム音量",
		"aliases": []
	},
	{
		"en": "Mute all game audio",
		"mm": "ဂိမ်းအသံအားလုံး ပိတ်မည်",
		"jp": "すべてのゲーム音声をミュート",
		"aliases": []
	},
	{
		"en": "Off",
		"mm": "ပိတ်ထား",
		"jp": "オフ",
		"aliases": []
	},
	{
		"en": "On",
		"mm": "ဖွင့်ထား",
		"jp": "オン",
		"aliases": []
	},
	{
		"en": "Display",
		"mm": "မျက်နှာပြင်",
		"jp": "画面",
		"aliases": []
	},
	{
		"en": "Toggle Fullscreen",
		"mm": "မျက်နှာပြင်အပြည့် ပြောင်းမည်",
		"jp": "全画面表示を切り替え",
		"aliases": []
	},
	{
		"en": "Browser fullscreen may require user permission.",
		"mm": "မျက်နှာပြင်အပြည့် ပြသရန် browser ခွင့်ပြုချက် လိုနိုင်သည်။",
		"jp": "全画面表示にはブラウザーの許可が必要な場合があります。",
		"aliases": []
	},
	{
		"en": "Volume and mute settings are saved locally.",
		"mm": "အသံအတိုးအကျယ်နှင့် အသံပိတ်ဆက်တင်များကို ဤစက်တွင် သိမ်းထားသည်။",
		"jp": "音量とミュート設定はこの端末に保存されます。",
		"aliases": []
	},
	{
		"en": "Saved Game Progress",
		"mm": "သိမ်းထားသော ဂိမ်းတိုးတက်မှု",
		"jp": "保存済みの進行状況",
		"aliases": []
	},
	{
		"en": "Reset saved stage progress; all available stages remain playable.",
		"mm": "သိမ်းထားသော တိုးတက်မှုကို ပြန်စမည်။ ဖွင့်ထားသောအဆင့်များကို ဆက်ကစားနိုင်သည်။",
		"jp": "進行状況をリセットします。利用可能なステージは引き続きプレイできます。",
		"aliases": []
	},
	{
		"en": "Reset Level Progress",
		"mm": "အဆင့်တိုးတက်မှုကို ပြန်စမည်",
		"jp": "進行状況をリセット",
		"aliases": []
	},
	{
		"en": "Confirm Reset",
		"mm": "ပြန်စခြင်းကို အတည်ပြုမည်",
		"jp": "リセットを確認",
		"aliases": []
	},
	{
		"en": "Player Profile",
		"mm": "ကစားသူ ကိုယ်ရေးအချက်အလက်",
		"jp": "プレイヤープロフィール",
		"aliases": []
	},
	{
		"en": "Optional local display name. No account or password required.",
		"mm": "ဤစက်ပေါ်ပြမည့် နာမည်ကို ထည့်နိုင်သည်။ အကောင့်နှင့် စကားဝှက် မလိုပါ။",
		"jp": "表示名を設定できます。アカウントやパスワードは不要です。",
		"aliases": []
	},
	{
		"en": "Welcome, %s",
		"mm": "ကြိုဆိုပါသည်၊ %s",
		"jp": "ようこそ、%sさん",
		"aliases": []
	},
	{
		"en": "Your display name and game menu statistics are saved locally on this device.",
		"mm": "ကစားသူနာမည်နှင့် ဂိမ်းစာရင်းမှတ်တမ်းများကို ဤစက်တွင် သိမ်းထားသည်။",
		"jp": "表示名とメニューの利用記録はこの端末に保存されます。",
		"aliases": []
	},
	{
		"en": "Player Card",
		"mm": "ကစားသူကတ်",
		"jp": "プレイヤーカード",
		"aliases": []
	},
	{
		"en": "Display Name",
		"mm": "ပြသမည့် နာမည်",
		"jp": "表示名",
		"aliases": []
	},
	{
		"en": "Save Name",
		"mm": "နာမည်သိမ်းမည်",
		"jp": "名前を保存",
		"aliases": []
	},
	{
		"en": "Privacy",
		"mm": "ကိုယ်ရေးအချက်အလက်",
		"jp": "プライバシー",
		"aliases": []
	},
	{
		"en": "This is a local guest profile, not online sign-in. Clearing the browser's site data or Godot user data can erase it.",
		"mm": "ဤစက်ပေါ်တွင်သာ သိမ်းထားသော ဧည့်သည်ပရိုဖိုင်ဖြစ်သည်။ Browser site data သို့မဟုတ် Godot user data ကို ရှင်းလျှင် ပျောက်နိုင်သည်။",
		"jp": "端末内のゲストプロフィールです。ブラウザーやGodotのデータを消すと削除される場合があります。",
		"aliases": []
	},
	{
		"en": "My Progress",
		"mm": "ကျွန်ုပ်၏ တိုးတက်မှု",
		"jp": "進行状況",
		"aliases": []
	},
	{
		"en": "Achievements",
		"mm": "အောင်မြင်မှုများ",
		"jp": "実績",
		"aliases": []
	},
	{
		"en": "Verified progress and launch history; available stages remain unlocked.",
		"mm": "အတည်ပြုထားသော တိုးတက်မှုနှင့် ကစားမှတ်တမ်း။ ဖွင့်ထားသောအဆင့်များကို ဆက်ကစားနိုင်သည်။",
		"jp": "確認済みの進行状況と起動履歴です。利用可能なステージはそのままです。",
		"aliases": []
	},
	{
		"en": "%s's Learning Journey",
		"mm": "%s ၏ လေ့လာရေးခရီး",
		"jp": "%sさんの学習記録",
		"aliases": []
	},
	{
		"en": "Stages launched from Level Select: %d",
		"mm": "အဆင့်ရွေးချယ်မှုမှ ကစားခဲ့သောအကြိမ်: %d",
		"jp": "ステージ選択からの起動回数：%d",
		"aliases": []
	},
	{
		"en": "Player Overview",
		"mm": "ကစားသူ အကျဉ်းချုပ်",
		"jp": "プレイヤー概要",
		"aliases": []
	},
	{
		"en": "Not yet played",
		"mm": "မကစားရသေး",
		"jp": "未プレイ",
		"aliases": []
	},
	{
		"en": "Last selected: %s",
		"mm": "နောက်ဆုံးရွေးထားသည်: %s",
		"jp": "最後の選択：%s",
		"aliases": []
	},
	{
		"en": "COMPLETED (VERIFIED)",
		"mm": "ပြီးစီးမှု အတည်ပြုပြီး",
		"jp": "完了（確認済み）",
		"aliases": []
	},
	{
		"en": "NOT YET VERIFIED",
		"mm": "အတည်မပြုရသေး",
		"jp": "未確認",
		"aliases": []
	},
	{
		"en": "COMPLETION NOT TRACKED",
		"mm": "ပြီးစီးမှုကို မမှတ်တမ်းတင်သေး",
		"jp": "完了記録なし",
		"aliases": []
	},
	{
		"en": "Level Menu launches: %d",
		"mm": "အဆင့်စာရင်းမှ ကစားခဲ့သည့်အကြိမ်: %d",
		"jp": "ステージ一覧からの起動回数：%d",
		"aliases": []
	},
	{
		"en": "Available to Play",
		"mm": "ကစားနိုင်သောအဆင့်",
		"jp": "プレイ可能",
		"aliases": []
	},
	{
		"en": "About progress",
		"mm": "တိုးတက်မှုအကြောင်း",
		"jp": "進行状況について",
		"aliases": []
	},
	{
		"en": "Stage 1 completion is read from the existing verified save file. Stage 2/3 completion is not stored there, so this screen does not claim they were completed. Launch counts only include starts from Level Select.",
		"mm": "အဆင့် ၁ ပြီးစီးမှုကို သိမ်းထားသော မှတ်တမ်းမှ ဖတ်သည်။ အဆင့် ၂/၃ ပြီးစီးမှုကို မသိမ်းသေးပါ။ ကစားအကြိမ်ရေသည် အဆင့်စာရင်းမှ စတင်ခဲ့ခြင်းကိုသာ ရေတွက်သည်။",
		"jp": "ステージ1は保存済み記録で確認します。ステージ2・3の完了は未記録です。起動回数はステージ一覧からの開始のみです。",
		"aliases": []
	},
	{
		"en": "Clear Menu History",
		"mm": "မီနူးမှတ်တမ်း ရှင်းမည်",
		"jp": "メニュー履歴を消去",
		"aliases": []
	},
	{
		"en": "Confirm Clear History",
		"mm": "မှတ်တမ်းရှင်းခြင်း အတည်ပြုမည်",
		"jp": "履歴の消去を確認",
		"aliases": []
	},
	{
		"en": "Rewards reflect actual menu activity or verified Stage 1 completion.",
		"mm": "ဆုတံဆိပ်များသည် တကယ်ကစားခဲ့မှု သို့မဟုတ် အဆင့် ၁ ပြီးစီးမှုအပေါ် အခြေခံသည်။",
		"jp": "実際の利用記録とステージ1の完了に基づく実績です。",
		"aliases": []
	},
	{
		"en": "%d / 4 BADGES EARNED",
		"mm": "ရရှိသော ဆုတံဆိပ် %d / ၄",
		"jp": "獲得バッジ %d / 4",
		"aliases": []
	},
	{
		"en": "Keep exploring the available stages to earn menu badges.",
		"mm": "ဖွင့်ထားသော အဆင့်များကို ဆက်ကစားပြီး ဆုတံဆိပ်များ ရယူပါ။",
		"jp": "利用可能なステージをプレイしてバッジを獲得しましょう。",
		"aliases": []
	},
	{
		"en": "Achievement Collection",
		"mm": "အောင်မြင်မှု စုဆောင်းမှု",
		"jp": "実績コレクション",
		"aliases": []
	},
	{
		"en": "First Steps",
		"mm": "ပထမခြေလှမ်း",
		"jp": "はじめの一歩",
		"aliases": []
	},
	{
		"en": "Launch any stage from Level Select.",
		"mm": "အဆင့်စာရင်းမှ အဆင့်တစ်ခုကို စတင်ပါ။",
		"jp": "ステージ一覧からいずれかのステージを開始する。",
		"aliases": []
	},
	{
		"en": "Stage Explorer",
		"mm": "အဆင့် စူးစမ်းသူ",
		"jp": "ステージ探検家",
		"aliases": []
	},
	{
		"en": "Launch Stage 1, 2 and 3 at least once each.",
		"mm": "အဆင့် ၁၊ ၂ နှင့် ၃ ကို အနည်းဆုံး တစ်ကြိမ်စီ စတင်ပါ။",
		"jp": "ステージ1・2・3をそれぞれ一度以上開始する。",
		"aliases": []
	},
	{
		"en": "Dedicated Learner",
		"mm": "ကြိုးစားလေ့လာသူ",
		"jp": "熱心な学習者",
		"aliases": []
	},
	{
		"en": "Launch stages 5 times in total from Level Select.",
		"mm": "အဆင့်စာရင်းမှ စုစုပေါင်း ၅ ကြိမ် စတင်ကစားပါ။",
		"jp": "ステージ一覧から合計5回開始する。",
		"aliases": []
	},
	{
		"en": "Drawing Challenge Clear",
		"mm": "ပုံဆွဲစိန်ခေါ်မှု အောင်မြင်",
		"jp": "図面課題クリア",
		"aliases": []
	},
	{
		"en": "Complete and verify Stage 1 drawing.",
		"mm": "အဆင့် ၁ ပုံဆွဲမှုကို ပြီးစီးအောင် အတည်ပြုပါ။",
		"jp": "ステージ1の図面課題をクリアする。",
		"aliases": []
	},
	{
		"en": "Stage 2/3 badges will need completion events in those scenes. They are not invented here.",
		"mm": "အဆင့် ၂/၃ ဆုတံဆိပ်များအတွက် ပြီးစီးမှုမှတ်တမ်း လိုအပ်သေးသည်။",
		"jp": "ステージ2・3の実績には完了記録の追加が必要です。",
		"aliases": []
	},
	{
		"en": "View My Progress",
		"mm": "ကျွန်ုပ်၏တိုးတက်မှု ကြည့်မည်",
		"jp": "進行状況を見る",
		"aliases": []
	},
	{
		"en": "Preview each stage without changing gameplay, answers or customer dialogue.",
		"mm": "ကစားပုံ၊ အဖြေနှင့် စကားပြောများ မပြောင်းဘဲ အဆင့်အကြောင်း ကြည့်နိုင်သည်။",
		"jp": "ゲーム内容や回答を変更せず、各ステージの概要を確認できます。",
		"aliases": []
	},
	{
		"en": "Floor Plan Drawing",
		"mm": "အခန်းပုံစံ ဆွဲခြင်း",
		"jp": "間取り図の作成",
		"aliases": []
	},
	{
		"en": "Listen to the customer, draw the requested LDK boundary and check the measured layout.",
		"mm": "ဝယ်ယူသူကို နားထောင်ပြီး တောင်းဆိုထားသော အခန်းနယ်နိမိတ်ကို ဆွဲကာ အတိုင်းအတာ စစ်ပါ။",
		"jp": "要望を聞き、LDKの境界を描いて寸法を確認します。",
		"aliases": []
	},
	{
		"en": "Explain what PS means and why it matters during renovation. Gemini is used when available, with a local fallback.",
		"mm": "PS ၏ အဓိပ္ပာယ်နှင့် ပြန်လည်ပြင်ဆင်ရာတွင် အရေးပါပုံကို ရှင်းပြပါ။ ရရှိလျှင် Gemini ဖြင့် စစ်ဆေးမည်။",
		"jp": "PSの意味とリフォーム時の注意点を説明します。利用可能な場合はGeminiで確認します。",
		"aliases": []
	},
	{
		"en": "Choose the kitchen layout and configuration, then identify the kitchen parts. Follow the existing in-stage progress flow.",
		"mm": "မီးဖိုချောင်ပုံစံကို ရွေးပြီး အစိတ်အပိုင်းများကို ခွဲခြားပါ။ အဆင့်အတွင်းရှိ လုပ်ငန်းစဉ်အတိုင်း ဆက်ကစားပါ။",
		"jp": "キッチンのレイアウトを選び、各部品を識別して課題を進めます。",
		"aliases": []
	},
	{
		"en": "Mission %02d  •  Available",
		"mm": "မစ်ရှင် %02d  •  ကစားနိုင်ပြီ",
		"jp": "ミッション %02d ・プレイ可能",
		"aliases": []
	},
	{
		"en": "Play Stage %d",
		"mm": "အဆင့် %d ကစားမည်",
		"jp": "ステージ%dをプレイ",
		"aliases": []
	},
	{
		"en": "STAGES 4–6  •  COMING SOON",
		"mm": "အဆင့် ၄–၆  •  မကြာမီ ရရှိမည်",
		"jp": "ステージ4〜6 ・近日公開",
		"aliases": []
	},
	{
		"en": "LEVEL 01  /  CUSTOMER REQUEST",
		"mm": "အဆင့် ၀၁  /  ဝယ်ယူသူ၏ တောင်းဆိုချက်",
		"jp": "ステージ01 ／ お客様の要望",
		"aliases": []
	},
	{
		"en": "Kitchen Layout Design Game",
		"mm": "မီးဖိုချောင် အခန်းဖွဲ့စည်းမှုဂိမ်း",
		"jp": "キッチン間取り設計ゲーム",
		"aliases": []
	},
	{
		"en": "START LEVEL 1",
		"mm": "အဆင့် ၁ စတင်မည်",
		"jp": "ステージ1を開始",
		"aliases": []
	},
	{
		"en": "Press START LEVEL 1 to hear your customer.",
		"mm": "ဝယ်ယူသူအသံ နားထောင်ရန် အဆင့် ၁ စတင်မည် ကို နှိပ်ပါ။",
		"jp": "ステージ1を開始してお客様の声を聞いてください。",
		"aliases": []
	},
	{
		"en": "OK",
		"mm": "အတည်ပြုမည်",
		"jp": "確認",
		"aliases": []
	},
	{
		"en": "Customer Request",
		"mm": "ဝယ်ယူသူ၏ တောင်းဆိုချက်",
		"jp": "お客様の要望",
		"aliases": []
	},
	{
		"en": "Replay from beginning",
		"mm": "အစမှ ပြန်နားထောင်မည်",
		"jp": "最初から再生",
		"aliases": []
	},
	{
		"en": "Pause / Resume",
		"mm": "ခေတ္တရပ် / ဆက်ဖွင့်",
		"jp": "一時停止／再開",
		"aliases": []
	},
	{
		"en": "Reference Plan",
		"mm": "ကိုးကား ပုံစံစာရွက်",
		"jp": "参考図面",
		"aliases": []
	},
	{
		"en": "Reference Plan  ↗",
		"mm": "ကိုးကား ပုံစံစာရွက်  ↗",
		"jp": "参考図面 ↗",
		"aliases": []
	},
	{
		"en": "Layout Drawing Area",
		"mm": "အခန်းပုံစံ ဆွဲရန်နေရာ",
		"jp": "間取り図の作成エリア",
		"aliases": []
	},
	{
		"en": "1 Small Grid = 100 mm (e.g., 1,000 mm = 10 grids) | Click points to draw (straight or angled) | Drag = Move",
		"mm": "ကွက်ငယ် ၁ ကွက် = ၁၀၀ mm (၁၀၀၀ mm = ၁၀ ကွက်) | အမှတ်များနှိပ်၍ ဆွဲပါ | ဆွဲရွှေ့၍ နေရာပြောင်းပါ",
		"jp": "小グリッド1個＝100 mm（1,000 mm＝10個） | 点をクリックして描画 | ドラッグで移動",
		"aliases": []
	},
	{
		"en": "Undo",
		"mm": "နောက်ဆုတ်",
		"jp": "元に戻す",
		"aliases": []
	},
	{
		"en": "Redo",
		"mm": "ပြန်လုပ်",
		"jp": "やり直す",
		"aliases": []
	},
	{
		"en": "Delete Last",
		"mm": "နောက်ဆုံးဖျက်",
		"jp": "最後の線を削除",
		"aliases": []
	},
	{
		"en": "Delete",
		"mm": "ဖျက်မည်",
		"jp": "削除",
		"aliases": []
	},
	{
		"en": "Zoom +",
		"mm": "ချဲ့မည် +",
		"jp": "拡大 +",
		"aliases": []
	},
	{
		"en": "Zoom -",
		"mm": "ချုံ့မည် -",
		"jp": "縮小 -",
		"aliases": []
	},
	{
		"en": "Reset",
		"mm": "ပြန်စမည်",
		"jp": "リセット",
		"aliases": []
	},
	{
		"en": "Clear",
		"mm": "ရှင်းမည်",
		"jp": "消去",
		"aliases": [
			"Clear",
			"ဖျက်မည်",
			"Clear"
		]
	},
	{
		"en": "Close",
		"mm": "ပိတ်မည်",
		"jp": "閉じる",
		"aliases": []
	},
	{
		"en": "Reset Zoom",
		"mm": "ချဲ့နှုန်း ပြန်သတ်မှတ်မည်",
		"jp": "表示倍率をリセット",
		"aliases": []
	},
	{
		"en": "Draw the requested layout, then click OK.",
		"mm": "တောင်းဆိုထားသော ပုံစံကို ဆွဲပြီး အတည်ပြုမည် ကို နှိပ်ပါ။",
		"jp": "指定の間取りを描いて、確認を押してください。",
		"aliases": []
	},
	{
		"en": "Drawing started! Click points on the grid to draw the layout.",
		"mm": "ပုံစဆွဲနိုင်ပြီ။ ဇယားကွက်ပေါ်မှ အမှတ်များကို နှိပ်ပါ။",
		"jp": "描画を開始しました。グリッド上の点をクリックしてください。",
		"aliases": []
	},
	{
		"en": "Canvas cleared. Please draw the layout again.",
		"mm": "ပုံကို ရှင်းပြီးပြီ။ ပြန်ဆွဲပေးပါ။",
		"jp": "図面を消去しました。もう一度描いてください。",
		"aliases": []
	},
	{
		"en": "Please wait for the customer to finish speaking.",
		"mm": "ဝယ်ယူသူ ပြောပြီးသည်အထိ ခဏစောင့်ပါ။",
		"jp": "お客様の話が終わるまでお待ちください。",
		"aliases": []
	},
	{
		"en": "Red highlighted parts on the drawing are incorrect. Click 'Try Again'.",
		"mm": "အနီဖြင့်ပြထားသော အပိုင်းများ မမှန်သေးပါ။ ထပ်ကြိုးစားမည် ကို နှိပ်ပါ။",
		"jp": "赤い部分が正しくありません。「もう一度」を押してください。",
		"aliases": []
	},
	{
		"en": "Try Again",
		"mm": "ထပ်ကြိုးစားမည်",
		"jp": "もう一度",
		"aliases": [
			"Try Again",
			"Try Again",
			"Try Again"
		]
	},
	{
		"en": "Start drawing",
		"mm": "စတင်ဆွဲမည်",
		"jp": "描き始める",
		"aliases": [
			"Start (描き始める)",
			"Start (စတင်ဆွဲမည်)",
			"Start drawing",
			"Start (စတင်ဆွဲမည်)",
			"Start (描き始める)",
			"Start (描き始める)",
			"Start (စတင်ဆွဲမည်)"
		]
	},
	{
		"en": "Stage 2 is starting automatically...",
		"mm": "အဆင့် ၂ ကို အလိုအလျောက် စတင်နေသည်…",
		"jp": "ステージ2を自動的に開始します…",
		"aliases": []
	},
	{
		"en": "Pause and view levels",
		"mm": "ခေတ္တရပ်ပြီး အဆင့်စာရင်းကြည့်မည်",
		"jp": "一時停止してステージ一覧を表示",
		"aliases": []
	},
	{
		"en": "Check Answer",
		"mm": "အဖြေစစ်မည်",
		"jp": "回答を確認",
		"aliases": [
			"Check Answer",
			"အဖြေစစ်မည်",
			"Check Answer"
		]
	},
	{
		"en": "Back to Stage 1",
		"mm": "အဆင့် ၁ သို့ပြန်မည်",
		"jp": "ステージ1に戻る",
		"aliases": [
			"Stage 1 ပြန်သွားမယ်",
			"Back to Stage 1",
			"Stage 1 ပြန်သွားမယ်",
			"Back to Stage 1",
			"Stage 1 ပြန်သွားမယ်"
		]
	},
	{
		"en": "Stage 2 | Customer question",
		"mm": "အဆင့် ၂ | ဝယ်ယူသူ၏ မေးခွန်း",
		"jp": "ステージ2 | お客様の質問",
		"aliases": [
			"Stage 2 | Customer question",
			"Stage 2 | Customer question",
			"Stage 2 | Customer question"
		]
	},
	{
		"en": "DEMO CHECK — AI will be connected later",
		"mm": "စမ်းသပ်စစ်ဆေးမှု — AI ကို နောက်မှ ချိတ်မည်",
		"jp": "デモ確認 ― AIは後で接続予定",
		"aliases": [
			"DEMO CHECK — AI ကို နောက်မှချိတ်မည်",
			"DEMO CHECK — AI will be connected later",
			"DEMO CHECK — AI ကို နောက်မှချိတ်မည်",
			"DEMO CHECK — AI will be connected later",
			"DEMO CHECK — AI ကို နောက်မှချိတ်မည်"
		]
	},
	{
		"en": "Customer Question",
		"mm": "ဝယ်ယူသူ၏ မေးခွန်း",
		"jp": "お客様の質問",
		"aliases": []
	},
	{
		"en": "Answer Area",
		"mm": "အဖြေရေးရန်နေရာ",
		"jp": "回答欄",
		"aliases": []
	},
	{
		"en": "Challenge Progress",
		"mm": "စိန်ခေါ်မှု တိုးတက်မှု",
		"jp": "課題の進行状況",
		"aliases": []
	},
	{
		"en": "Waiting",
		"mm": "စောင့်ဆိုင်းနေသည်",
		"jp": "待機中",
		"aliases": []
	},
	{
		"en": "Replay Stage 2",
		"mm": "အဆင့် ၂ ပြန်ကစားမည်",
		"jp": "ステージ2を再プレイ",
		"aliases": []
	},
	{
		"en": "View Levels",
		"mm": "အဆင့်စာရင်း ကြည့်မည်",
		"jp": "ステージ一覧",
		"aliases": [
			"レベル一覧"
		]
	},
	{
		"en": "Stage 2 Completed",
		"mm": "အဆင့် ၂ ပြီးစီးပြီ",
		"jp": "ステージ2 クリア",
		"aliases": []
	},
	{
		"en": "Customer question task finished.",
		"mm": "ဝယ်ယူသူ၏ မေးခွန်းကို ဖြေဆိုပြီးပြီ။",
		"jp": "お客様の質問への回答が完了しました。",
		"aliases": [
			"Customer မေးခွန်းကို အောင်မြင်စွာ ဖြေဆိုပြီးပါပြီ။"
		]
	},
	{
		"en": "Challenge In Progress",
		"mm": "စိန်ခေါ်မှု ဆောင်ရွက်နေဆဲ",
		"jp": "チャレンジ進行中",
		"aliases": []
	},
	{
		"en": "Revise your explanation and try again.",
		"mm": "သင့်ရှင်းပြချက်ကို ပြန်စဉ်းစားပြီး ထပ်ဖြေပါ။",
		"jp": "説明を見直してもう一度試してください。",
		"aliases": [
			"အဖြေကို ပြန်စဉ်းစားပြီး ထပ်မံဖြေဆိုနိုင်ပါတယ်။"
		]
	},
	{
		"en": "Checking your answer...",
		"mm": "အဖြေ စစ်ဆေးနေသည်…",
		"jp": "AIが回答を確認中…",
		"aliases": []
	},
	{
		"en": "Please wait for the result.",
		"mm": "ရလဒ်ထွက်သည်အထိ ခဏစောင့်ပါ။",
		"jp": "結果が出るまでお待ちください。",
		"aliases": [
			"AI က အဖြေစစ်နေပါတယ်။ ခဏစောင့်ပါ။"
		]
	},
	{
		"en": "Checking",
		"mm": "စစ်ဆေးနေသည်",
		"jp": "確認中",
		"aliases": []
	},
	{
		"en": "AI Connection Error",
		"mm": "AI ချိတ်ဆက်မှု အမှား",
		"jp": "AIとの接続エラー",
		"aliases": []
	},
	{
		"en": "Please try again. This is not a wrong answer.",
		"mm": "ထပ်ကြိုးစားပါ။ အဖြေမှားသည်ဟု မသတ်မှတ်ပါ။",
		"jp": "後ほど再試行してください。誤答扱いにはなりません。",
		"aliases": [
			"AI ချိတ်ဆက်မှု မအောင်မြင်ပါ။ အဖြေမှားတယ်လို့ မသတ်မှတ်ပါ။"
		]
	},
	{
		"en": "Retry",
		"mm": "ထပ်ကြိုးစားမည်",
		"jp": "再試行",
		"aliases": []
	},
	{
		"en": "Answer needed",
		"mm": "အဖြေ ထည့်ရန်လိုသည်",
		"jp": "回答を入力してください",
		"aliases": []
	},
	{
		"en": "Stage 2 — Customer Question",
		"mm": "အဆင့် ၂ — ဝယ်ယူသူ၏ မေးခွန်း",
		"jp": "ステージ2・お客様の質問",
		"aliases": []
	},
	{
		"en": "Explain PS in your own words.",
		"mm": "PS အကြောင်းကို ကိုယ့်စကားဖြင့် ရှင်းပြပါ။",
		"jp": "PSの意味を自分の言葉で説明してください。",
		"aliases": [
			"PS အကြောင်းကို ကိုယ့်စကားနဲ့ ရှင်းပြပါ။"
		]
	},
	{
		"en": "100% COMPLETED",
		"mm": "၁၀၀% ပြီးစီးပြီ",
		"jp": "100% 完了",
		"aliases": []
	},
	{
		"en": "0% · IN PROGRESS",
		"mm": "၀% · ဆောင်ရွက်နေဆဲ",
		"jp": "0% ・進行中",
		"aliases": []
	},
	{
		"en": "AI CHECK · 3 MODELS",
		"mm": "AI စစ်ဆေးမှု · မော်ဒယ် ၃ မျိုး",
		"jp": "AI確認 ・3モデル",
		"aliases": []
	},
	{
		"en": "LOCAL CHECK · OFFLINE",
		"mm": "စက်တွင်း စစ်ဆေးမှု · အင်တာနက်မဲ့",
		"jp": "端末内確認 ・オフライン",
		"aliases": []
	},
	{
		"en": "LOCAL CHECK · APPROXIMATE",
		"mm": "စက်တွင်း ခန့်မှန်းစစ်ဆေးမှု",
		"jp": "端末内の簡易確認",
		"aliases": []
	},
	{
		"en": "Your answer is too long.",
		"mm": "အဖြေစာသား ရှည်လွန်းနေသည်။",
		"jp": "回答が長すぎます。",
		"aliases": [
			"အဖြေစာသား အရမ်းရှည်နေပါတယ်။"
		]
	},
	{
		"en": "AI CHECK · TRYING MODELS",
		"mm": "AI စစ်ဆေးမှု · မော်ဒယ်များ စမ်းနေသည်",
		"jp": "AI確認 ・モデルを試行中",
		"aliases": []
	},
	{
		"en": "AI CHECK · %s",
		"mm": "AI စစ်ဆေးမှု · %s",
		"jp": "AI確認 ・%s",
		"aliases": []
	},
	{
		"en": "AI CHECK · CONNECTION ERROR",
		"mm": "AI စစ်ဆေးမှု · ချိတ်ဆက်မှုအမှား",
		"jp": "AI確認 ・接続エラー",
		"aliases": []
	},
	{
		"en": "Countertop",
		"mm": "အလုပ်လုပ်ရန် မျက်နှာပြင်",
		"jp": "カウンター",
		"aliases": []
	},
	{
		"en": "Kitchen board",
		"mm": "မီးဖိုချောင်ဗီရို",
		"jp": "キッチンボード",
		"aliases": []
	},
	{
		"en": "Range hood",
		"mm": "မီးဖိုချောင် လေစုပ်ခေါင်း",
		"jp": "フード",
		"aliases": []
	},
	{
		"en": "Half wall",
		"mm": "နံရံတစ်ဝက်",
		"jp": "腰壁",
		"aliases": []
	},
	{
		"en": "Other fixtures",
		"mm": "အခြားပစ္စည်းများ",
		"jp": "その他",
		"aliases": []
	},
	{
		"en": "STAGE 3 / PART %s",
		"mm": "အဆင့် ၃ / အစိတ်အပိုင်း %s",
		"jp": "ステージ3 ／ 部品%s",
		"aliases": []
	},
	{
		"en": "S-CLASS KITCHEN TRAINING",
		"mm": "S-Class မီးဖိုချောင် လေ့ကျင့်ခန်း",
		"jp": "Sクラスキッチン研修",
		"aliases": []
	},
	{
		"en": "Select the matching kitchen illustration.",
		"mm": "ကိုက်ညီသော မီးဖိုချောင်ပုံကို ရွေးပါ။",
		"jp": "該当するキッチンの図を選んでください。",
		"aliases": []
	},
	{
		"en": "Identify the kitchen components from the diagram.",
		"mm": "ပုံတွင်ပြထားသော မီးဖိုချောင်အစိတ်အပိုင်းများကို ခွဲခြားပါ။",
		"jp": "図からキッチンの部品を識別してください。",
		"aliases": []
	},
	{
		"en": "Kitchen Selection",
		"mm": "မီးဖိုချောင် ရွေးချယ်ခြင်း",
		"jp": "キッチン選択",
		"aliases": []
	},
	{
		"en": "Kitchen Parts",
		"mm": "မီးဖိုချောင် အစိတ်အပိုင်းများ",
		"jp": "キッチンの部品",
		"aliases": []
	},
	{
		"en": "QUESTION %d / 2",
		"mm": "မေးခွန်း %d / ၂",
		"jp": "質問 %d / 2",
		"aliases": []
	},
	{
		"en": "PARTS  %d / 5",
		"mm": "အစိတ်အပိုင်း %d / ၅",
		"jp": "部品 %d / 5",
		"aliases": []
	},
	{
		"en": "STAGE 3 COMPLETED",
		"mm": "အဆင့် ၃ ပြီးစီးပြီ",
		"jp": "ステージ3 完了",
		"aliases": []
	},
	{
		"en": "Not quite right. Please choose again.",
		"mm": "မမှန်သေးပါ။ ပြန်ရွေးပါ။",
		"jp": "ちょっと違うようです。もう一度選んでください。",
		"aliases": []
	},
	{
		"en": "Select the S-Class kitchen type.",
		"mm": "S-Class မီးဖိုချောင်ပုံစံကို ရွေးပါ။",
		"jp": "S-classのキッチンタイプを選んでください。",
		"aliases": []
	},
	{
		"en": "Select the layout detail.",
		"mm": "အခန်းပုံစံ အသေးစိတ်ကို ရွေးပါ။",
		"jp": "プランレイアウト詳細を選択してください。",
		"aliases": []
	},
	{
		"en": "I-shaped",
		"mm": "I ပုံစံ",
		"jp": "I型",
		"aliases": []
	},
	{
		"en": "L-shaped",
		"mm": "L ပုံစံ",
		"jp": "L型",
		"aliases": []
	},
	{
		"en": "Facing",
		"mm": "မျက်နှာချင်းဆိုင် ပုံစံ",
		"jp": "対面",
		"aliases": []
	},
	{
		"en": "II-shaped",
		"mm": "II ပုံစံ",
		"jp": "II型",
		"aliases": []
	},
	{
		"en": "Island",
		"mm": "ကျွန်းပုံစံ",
		"jp": "アイランド",
		"aliases": []
	},
	{
		"en": "Fully flat",
		"mm": "တစ်ပြေးညီ မျက်နှာပြင်",
		"jp": "フルフラット",
		"aliases": []
	},
	{
		"en": "Load-bearing wall",
		"mm": "ဝန်ထမ်းနံရံ",
		"jp": "耐力壁",
		"aliases": []
	},
	{
		"en": "Floating",
		"mm": "အောက်ခြေလွတ် ပုံစံ",
		"jp": "フロート",
		"aliases": []
	},
	{
		"en": "Round access",
		"mm": "ဝိုင်းပတ်ဝင်နိုင်သော ပုံစံ",
		"jp": "ラウンドアクセス",
		"aliases": []
	},
	{
		"en": "Select an image. A correct choice automatically opens the next question.",
		"mm": "အဖြေမှန်ရွေးလိုက်လျှင် နောက်မေးခွန်းသို့ အလိုအလျောက် ဆက်သွားမည်။",
		"jp": "正しい画像を選ぶと次の質問へ自動で進みます。",
		"aliases": [
			"အဖြေမှန်ရွေးလိုက်တာနဲ့ နောက်မေးခွန်းကို အလိုအလျောက် သွားပါမယ်။"
		]
	},
	{
		"en": "Select: %s",
		"mm": "ရွေးပါ: %s",
		"jp": "選択：%s",
		"aliases": []
	},
	{
		"en": "Click the corresponding area in the kitchen illustration.",
		"mm": "မီးဖိုချောင်ပုံပေါ်ရှိ သက်ဆိုင်ရာနေရာကို နှိပ်ပါ။",
		"jp": "キッチンの図で該当する場所をクリックしてください。",
		"aliases": []
	},
	{
		"en": "Countertop · Kitchen board · Range hood · Half wall · Other fixtures",
		"mm": "အလုပ်လုပ်ရန်မျက်နှာပြင် · ဗီရို · လေစုပ်ခေါင်း · နံရံတစ်ဝက် · အခြားပစ္စည်းများ",
		"jp": "カウンター・キッチンボード・フード・腰壁・その他",
		"aliases": []
	},
	{
		"en": "STAGE 3 COMPLETE!",
		"mm": "အဆင့် ၃ အောင်မြင်ပြီ။",
		"jp": "ステージ3 クリア！",
		"aliases": []
	},
	{
		"en": "Thank you!",
		"mm": "ကျေးဇူးတင်ပါတယ်။",
		"jp": "ありがとうございました！",
		"aliases": [
			"ကျေးဇူးတင်ပါတယ်။"
		]
	},
	{
		"en": "Stage Complete!",
		"mm": "အဆင့် အောင်မြင်ပြီ။",
		"jp": "ステージクリア！",
		"aliases": []
	},
	{
		"en": "Great job. You cleared this stage.",
		"mm": "တော်ပါတယ်။ ဤအဆင့်ကို အောင်မြင်ပြီးပါပြီ။",
		"jp": "よくできました。このステージをクリアしました。",
		"aliases": []
	},
	{
		"en": "Next Stage",
		"mm": "နောက်အဆင့်",
		"jp": "次のステージ",
		"aliases": []
	},
	{
		"en": "Replay",
		"mm": "ပြန်ကစားမည်",
		"jp": "再プレイ",
		"aliases": [
			"もう一度"
		]
	},
	{
		"en": "%s mm wall drawn. Continue drawing.",
		"mm": "%s mm နံရံဆွဲပြီးပြီ။ ဆက်ဆွဲပါ။",
		"jp": "%s mmの壁を描きました。続けて描いてください。",
		"aliases": []
	},
	{
		"en": "Selected wall deleted.",
		"mm": "ရွေးထားသော နံရံကို ဖျက်ပြီးပြီ။",
		"jp": "選択した壁を削除しました。",
		"aliases": []
	},
	{
		"en": "Wall moved.",
		"mm": "နံရံကို ရွှေ့ပြီးပြီ။",
		"jp": "壁を移動しました。",
		"aliases": []
	},
	{
		"en": "Drawing stopped.",
		"mm": "ပုံဆွဲခြင်း ရပ်ထားသည်။",
		"jp": "描画を停止しました。",
		"aliases": []
	},
	{
		"en": "Selection cleared.",
		"mm": "ရွေးချယ်မှု ပယ်ဖျက်ပြီးပြီ။",
		"jp": "選択を解除しました。",
		"aliases": []
	},
	{
		"en": "Wall selected & moving.",
		"mm": "နံရံကို ရွေးပြီး ရွှေ့နေသည်။",
		"jp": "壁を選択して移動中です。",
		"aliases": []
	},
	{
		"en": "Click next point to draw wall.",
		"mm": "နံရံဆွဲရန် နောက်အမှတ်ကို နှိပ်ပါ။",
		"jp": "次の点をクリックして壁を描いてください。",
		"aliases": []
	},
	{
		"en": "%s mm wall drawn. Click next point.",
		"mm": "%s mm နံရံဆွဲပြီးပြီ။ နောက်အမှတ်ကို နှိပ်ပါ။",
		"jp": "%s mmの壁を描きました。次の点をクリックしてください。",
		"aliases": []
	},
	{
		"en": "Loading... %d%%",
		"mm": "ဖွင့်နေသည်… %d%%",
		"jp": "読み込み中… %d%%",
		"aliases": []
	},
	{
		"en": "Select: %s  (%s)",
		"mm": "ရွေးပါ: %s (%s)",
		"jp": "選択：%s（%s）",
		"aliases": []
	},
	{
		"en": "Ms. Hosokawa",
		"mm": "ဟိုဆိုကာဝါစံ",
		"jp": "細川さん（女性）",
		"aliases": [
			"Ms. Hosokawa",
			"ဟိုဆိုကာဝါစံ (Customer)",
			"細川さん（女性）",
			"ဟိုဆိုကာဝါစံ"
		]
	},
	{
		"en": "I am thinking about renovating my kitchen.\nI have a floor plan, but I do not understand it clearly.\nCould you neatly draw the area that I need?\nI would like to know the exact living, dining and kitchen layout.",
		"mm": "မီးဖိုချောင်ကို ပြန်လည်ပြင်ဆင်ဖို့ စဉ်းစားနေပါတယ်။\nပုံစံစာရွက် ရှိပေမယ့် သေချာနားမလည်လို့ပါ။\nလိုအပ်တဲ့ ဧရိယာလေးကို သပ်သပ်ရပ်ရပ် ဆွဲပေးနိုင်မလားရှင်။\nထမင်းစားခန်းနဲ့ မီးဖိုချောင်ရဲ့ အခန်းဖွဲ့စည်းပုံကို အတိအကျ သိချင်ပါတယ်။",
		"jp": "キッチンのリフォームを考えています。\n図面はあったけど、よくわかりません。\n必要なエリアをきれいに描いてもらえますか？\nリビングダイニングとキッチンの間取りを正確に知りたいです。",
		"aliases": []
	},
	{
		"en": "I understand now.\nThank you very much.",
		"mm": "သေချာနားလည်သွားပါပြီ။\nကျေးဇူးအများကြီးတင်ပါတယ်။",
		"jp": "よくわかりました。\nありがとうございます。",
		"aliases": []
	},
	{
		"en": "Something seems a little different.",
		"mm": "နည်းနည်းလေး လွဲနေသလိုပဲနော်、、、",
		"jp": "ちょっと違うような気がしますけど。",
		"aliases": []
	},
	{
		"en": "By the way, what does PS on the floor plan mean?",
		"mm": "စကားမစပ်၊ ပုံစံစာရွက်ထဲက PS ဆိုတာ ဘာကိုဆိုလိုတာလဲရှင်။",
		"jp": "ところで、図面にあるPSって何でしょうか？",
		"aliases": []
	},
	{
		"en": "Type your answer here...",
		"mm": "ဒီနေရာမှာ အဖြေရေးပါ...",
		"jp": "ここに回答を入力してください...",
		"aliases": []
	},
	{
		"en": "Your answer",
		"mm": "သင့်အဖြေ",
		"jp": "あなたの回答",
		"aliases": []
	},
	{
		"en": "Please enter an answer first.",
		"mm": "အရင်ဆုံး အဖြေတစ်ခု ရေးပေးပါ။",
		"jp": "まず回答を入力してください。",
		"aliases": []
	},
	{
		"en": "Demo (AI not connected): ",
		"mm": "စမ်းသပ်စစ်ဆေးမှု (AI မချိတ်ရသေး): ",
		"jp": "DEMO（AI未接続）：",
		"aliases": []
	},
	{
		"en": "I understand very well!",
		"mm": "သေချာနားလည်သွားပါပြီ!",
		"jp": "よくわかりました！",
		"aliases": []
	},
	{
		"en": "I am not quite sure I understand.",
		"mm": "နည်းနည်းနားမလည်ဘူးနော်။",
		"jp": "ちょっとよくわからないわね、、、",
		"aliases": []
	},
	{
		"en": "If the kitchen stays in the same location, which S-Class type would fit?",
		"mm": "လက်ရှိမီးဖိုချောင်နေရာမှာ S-Class တပ်မယ်ဆို ဘယ်ပုံစံဖြစ်မလဲ။",
		"jp": "現在のキッチンと同じ場所に設置するとすれば、S-classではどのタイプになりますか？",
		"aliases": []
	},
	{
		"en": "What would the layout be if the wall behind the current kitchen remains?",
		"mm": "မူလမီးဖိုချောင် နောက်ဘက်နံရံကို ဆက်ထားမယ်ဆို ဘယ်ပုံစံဖြစ်မလဲ။",
		"jp": "現行のキッチンの後ろの壁も残すとすれば、どうなりますか？",
		"aliases": [
			"မူလ Kitchen နောက်ဘက်နံရံကို ဆက်ထားမယ်ဆို ဘယ်ပုံစံဖြစ်မလဲ။"
		]
	},
	{
		"en": "Could you identify the names of the kitchen parts?",
		"mm": "မီးဖိုချောင်အစိတ်အပိုင်းတွေကို ရွေးပြနိုင်မလား။",
		"jp": "それぞれのパーツの名前を教えてもらえますか？",
		"aliases": []
	},
	{
		"en": "Stage %d  •  %s",
		"mm": "အဆင့် %d  •  %s",
		"jp": "ステージ %d ・ %s",
		"aliases": []
	},
	{
		"en": "Sketch Challenge • Draw / Design / Learn",
		"mm": "ပုံဆွဲစိန်ခေါ်မှု • ဆွဲပါ / ဒီဇိုင်းလုပ်ပါ / လေ့လာပါ",
		"jp": "スケッチチャレンジ ・ 描く／設計する／学ぶ",
		"aliases": [
			"SKETCH CHALLENGE  •  DRAW  /  DESIGN  /  LEARN"
		]
	},
	{
		"en": "Kitchen Decoration Game",
		"mm": "မီးဖိုချောင် အလှဆင်ဂိမ်း",
		"jp": "キッチンデコレーションゲーム",
		"aliases": []
	}
]
