extends RefCounted
const MESSAGES = [
	{
		"en": "Correct",
		"mm": "မှန်ပါတယ်",
		"jp": "正解",
		"aliases": []
	},
	{
		"en": "Incorrect",
		"mm": "မမှန်သေးပါ",
		"jp": "不正解",
		"aliases": []
	},
	{
		"en": "Your progress",
		"mm": "သင့်တိုးတက်မှု",
		"jp": "進行状況",
		"aliases": []
	},
	{
		"en": "%d of 3 missions complete",
		"mm": "မစ်ရှင် ၃ ခုအနက် %d ခု ပြီးပါပြီ",
		"jp": "3つのミッション中%dつ完了",
		"aliases": []
	},
	{
		"en": "Stage %d of 3",
		"mm": "အဆင့် ၃ ဆင့်အနက် အဆင့် %d",
		"jp": "全3ステージ中 ステージ%d",
		"aliases": []
	},
	{
		"en": "Your kitchen design journey",
		"mm": "မီးဖိုချောင်ဒီဇိုင်း ခရီးစဉ်",
		"jp": "キッチンデザインの旅",
		"aliases": []
	},
	{
		"en": "Three missions. One thoughtful kitchen.",
		"mm": "မစ်ရှင်သုံးခုမှ စိတ်ကြိုက်မီးဖိုချောင်ဆီသို့",
		"jp": "3つのミッションで、理想のキッチンへ。",
		"aliases": []
	},
	{
		"en": "Continue Game",
		"mm": "ဆက်ကစားမည်",
		"jp": "続きから",
		"aliases": []
	},
	{
		"en": "How to Play",
		"mm": "ကစားနည်း",
		"jp": "遊び方",
		"aliases": []
	},
	{
		"en": "Language",
		"mm": "ဘာသာစကား",
		"jp": "言語",
		"aliases": []
	},
	{
		"en": "Draw the connected living, dining and kitchen area.",
		"mm": "ဧည့်ခန်း၊ ထမင်းစားခန်းနှင့် မီးဖိုချောင် ဆက်နေသည့်ဧရိယာကို ဆွဲပါ။",
		"jp": "つながったリビング・ダイニング・キッチンの範囲を描きましょう。",
		"aliases": []
	},
	{
		"en": "Explain the pipe shaft and the limits on moving it.",
		"mm": "PS နှင့် ၎င်းကို ရွှေ့ရန် ကန့်သတ်ချက်များကို ရှင်းပြပါ။",
		"jp": "パイプシャフトと移動の制約を説明しましょう。",
		"aliases": []
	},
	{
		"en": "Choose a kitchen layout and identify five components.",
		"mm": "မီးဖိုချောင်ပုံစံရွေးပြီး အစိတ်အပိုင်းငါးခုကို ခွဲခြားပါ။",
		"jp": "キッチンのタイプを選び、5つの部材を見つけましょう。",
		"aliases": []
	},
	{
		"en": "Mission brief",
		"mm": "မစ်ရှင် အကျဉ်း",
		"jp": "ミッションの概要",
		"aliases": []
	},
	{
		"en": "Parts checklist",
		"mm": "အစိတ်အပိုင်း စာရင်း",
		"jp": "部材チェックリスト",
		"aliases": []
	},
	{
		"en": "Hint",
		"mm": "အရိပ်အမြွက်",
		"jp": "ヒント",
		"aliases": []
	},
	{
		"en": "Pause",
		"mm": "ခဏရပ်",
		"jp": "一時停止",
		"aliases": []
	},
	{
		"en": "Trace only the connected LDK area. Check each wall length and close the outline.",
		"mm": "ဆက်နေသည့် LDK ဧရိယာကိုသာ ဆွဲပါ။ နံရံအလျားတိုင်းကို စစ်ပြီး အနားသတ်ကို ပိတ်ဆက်ပါ။",
		"jp": "つながったLDKだけを描き、壁の長さを確認して輪郭を閉じましょう。",
		"aliases": []
	},
	{
		"en": "Stage 1 complete. Continue when you are ready.",
		"mm": "အဆင့် ၁ ပြီးပါပြီ။ အသင့်ဖြစ်လျှင် ဆက်သွားပါ။",
		"jp": "ステージ1をクリアしました。準備ができたら次へ進みましょう。",
		"aliases": []
	},
	{
		"en": "Stage 1 complete!",
		"mm": "အဆင့် ၁ အောင်မြင်ပါပြီ။",
		"jp": "ステージ1 クリア！",
		"aliases": []
	},
	{
		"en": "The LDK boundary matches the reference plan.",
		"mm": "LDK အနားသတ်သည် နမူနာပုံစံနှင့် ကိုက်ညီပါသည်။",
		"jp": "LDKの輪郭が参考図面と一致しています。",
		"aliases": []
	},
	{
		"en": "Continue to Stage 2",
		"mm": "အဆင့် ၂ သို့ ဆက်သွားမည်",
		"jp": "ステージ2へ進む",
		"aliases": []
	},
	{
		"en": "Continue to Stage 3",
		"mm": "အဆင့် ၃ သို့ ဆက်သွားမည်",
		"jp": "ステージ3へ進む",
		"aliases": []
	},
	{
		"en": "Review drawing",
		"mm": "ပုံကို ပြန်ကြည့်မည်",
		"jp": "図面を確認",
		"aliases": []
	},
	{
		"en": "Closed outline",
		"mm": "အနားသတ် ပိတ်ဆက်ထားသည်",
		"jp": "閉じた輪郭",
		"aliases": []
	},
	{
		"en": "Correct wall dimensions",
		"mm": "နံရံအတိုင်းအတာ မှန်ကန်သည်",
		"jp": "正しい壁の寸法",
		"aliases": []
	},
	{
		"en": "Connected LDK area",
		"mm": "LDK ဧရိယာ ဆက်နေသည်",
		"jp": "つながったLDKの範囲",
		"aliases": []
	},
	{
		"en": "Thank you! I can see the space clearly now.",
		"mm": "ကျေးဇူးတင်ပါတယ်။ အခု ဧရိယာကို ရှင်းရှင်းလင်းလင်း မြင်ရပါပြီ။",
		"jp": "ありがとうございます！空間がよくわかりました。",
		"aliases": []
	},
	{
		"en": "Your answer",
		"mm": "သင့်အဖြေ",
		"jp": "あなたの回答",
		"aliases": []
	},
	{
		"en": "Explain the purpose of PS and what it means for this renovation.",
		"mm": "PS ၏ ရည်ရွယ်ချက်နှင့် ယခုအိမ်ပြင်ဆင်မှုအတွက် ၎င်း၏သက်ရောက်မှုကို ရှင်းပြပါ။",
		"jp": "PSの役割と、今回のリフォームへの影響を説明しましょう。",
		"aliases": []
	},
	{
		"en": "Think about the services inside PS and whether they can be relocated easily.",
		"mm": "PS အတွင်းရှိ ပိုက်များနှင့် ၎င်းတို့ကို အလွယ်တကူ ရွှေ့နိုင်ခြင်းရှိမရှိ စဉ်းစားပါ။",
		"jp": "PS内の配管と、簡単に移動できるかを考えてみましょう。",
		"aliases": []
	},
	{
		"en": "Answer feedback",
		"mm": "အဖြေအပေါ် တုံ့ပြန်ချက်",
		"jp": "回答へのフィードバック",
		"aliases": []
	},
	{
		"en": "Question %d of 2",
		"mm": "မေးခွန်း ၂ ခုအနက် မေးခွန်း %d",
		"jp": "全2問中 第%d問",
		"aliases": []
	},
	{
		"en": "Part %d of 5",
		"mm": "အစိတ်အပိုင်း ၅ ခုအနက် %d ခုမြောက်",
		"jp": "全5部材中 %dつ目",
		"aliases": []
	},
	{
		"en": "Please try another choice.",
		"mm": "အခြားအဖြေကို ပြန်ရွေးပါ။",
		"jp": "別の選択肢を試してください。",
		"aliases": []
	},
	{
		"en": "Challenge progress",
		"mm": "ယခုစိန်ခေါ်မှု၏ တိုးတက်မှု",
		"jp": "チャレンジの進行状況",
		"aliases": []
	},
	{
		"en": "Find the work surface above the base cabinets.",
		"mm": "အောက်ခံဗီရိုများအပေါ်ရှိ အလုပ်လုပ်သည့်မျက်နှာပြင်ကို ရှာပါ။",
		"jp": "下部キャビネットの上の作業面を探しましょう。",
		"aliases": []
	},
	{
		"en": "Look for the storage cabinets above the work surface.",
		"mm": "အလုပ်လုပ်သည့်မျက်နှာပြင်အပေါ်ရှိ သိုလှောင်ဗီရိုများကို ရှာပါ။",
		"jp": "作業面の上の収納キャビネットを探しましょう。",
		"aliases": []
	},
	{
		"en": "Find the extractor above the cooktop.",
		"mm": "မီးဖိုအပေါ်ရှိ အငွေ့စုပ်စက်ကို ရှာပါ။",
		"jp": "コンロの上の換気フードを探しましょう。",
		"aliases": []
	},
	{
		"en": "Look for the low wall in front of the kitchen.",
		"mm": "မီးဖိုချောင်အရှေ့ရှိ နံရံနိမ့်ကို ရှာပါ။",
		"jp": "キッチン手前の低い壁を探しましょう。",
		"aliases": []
	},
	{
		"en": "Find the tall fixture at the side of the kitchen.",
		"mm": "မီးဖိုချောင်ဘေးရှိ အမြင့်ရှိသော ပစ္စည်းကို ရှာပါ။",
		"jp": "キッチン脇の背の高い設備を探しましょう。",
		"aliases": []
	},
	{
		"en": "Training complete!",
		"mm": "သင်တန်း အောင်မြင်စွာ ပြီးဆုံးပါပြီ။",
		"jp": "トレーニング完了！",
		"aliases": []
	},
	{
		"en": "Stage 3 complete!",
		"mm": "အဆင့် ၃ အောင်မြင်ပါပြီ။",
		"jp": "ステージ3 クリア！",
		"aliases": []
	},
	{
		"en": "Your kitchen design journey, one mission at a time.",
		"mm": "မစ်ရှင်တစ်ခုချင်းမှ သင့်မီးဖိုချောင်ဒီဇိုင်း ခရီးစဉ်ဆီသို့",
		"jp": "一つずつ積み重ねる、キッチンデザインの旅。",
		"aliases": []
	},
	{
		"en": "Read the plan and draw the LDK boundary.",
		"mm": "ပုံစံကိုဖတ်ပြီး LDK အနားသတ်ကို ဆွဲပါ။",
		"jp": "図面を読み、LDKの輪郭を描く。",
		"aliases": []
	},
	{
		"en": "Explain PS and its renovation constraints.",
		"mm": "PS နှင့် အိမ်ပြင်ဆင်မှုဆိုင်ရာ ကန့်သတ်ချက်များကို ရှင်းပြပါ။",
		"jp": "PSとリフォームの制約を説明する。",
		"aliases": []
	},
	{
		"en": "Select a kitchen and identify its components.",
		"mm": "မီးဖိုချောင်ကိုရွေးပြီး အစိတ်အပိုင်းများကို ခွဲခြားပါ။",
		"jp": "キッチンを選び、部材を見つける。",
		"aliases": []
	},
	{
		"en": "Not yet completed",
		"mm": "မပြီးသေးပါ",
		"jp": "未完了",
		"aliases": []
	},
	{
		"en": "Thank you for helping me plan my kitchen renovation.",
		"mm": "မီးဖိုချောင်ပြင်ဆင်မှုကို စီစဉ်ပေးသည့်အတွက် ကျေးဇူးတင်ပါတယ်။",
		"jp": "キッチンのリフォーム計画を手伝ってくださり、ありがとうございました。",
		"aliases": []
	},
	{
		"en": "Replay Stage 3",
		"mm": "အဆင့် ၃ ကို ပြန်ကစားမည်",
		"jp": "ステージ3をもう一度",
		"aliases": []
	},
	{
		"en": "Design a kitchen. Build your confidence.",
		"mm": "မီးဖိုချောင်ကို ဒီဇိုင်းဆွဲရင်း ယုံကြည်မှု တိုးပွားပါစေ။",
		"jp": "キッチンをデザインして、自信を育てよう。",
		"aliases": []
	},
	{
		"en": "Read the plan. Understand the space. Make it yours.",
		"mm": "ပုံစံကိုဖတ်ပါ။ ဧရိယာကို နားလည်ပါ။ စိတ်ကြိုက်ဖန်တီးပါ။",
		"jp": "図面を読み、空間を知り、自分らしく。",
		"aliases": []
	},
	{
		"en": "Play Again",
		"mm": "ပြန်ကစားမည်",
		"jp": "もう一度遊ぶ",
		"aliases": []
	},
	{
		"en": "You explained the vertical pipe shaft and why it is difficult to move.",
		"mm": "ဒေါင်လိုက်ပိုက်ခန်းနှင့် ၎င်းကို ရွှေ့ရန်ခက်ခဲသည့်အကြောင်း ရှင်းပြနိုင်ပါပြီ။",
		"jp": "縦方向の配管スペースと、移動が難しい理由を説明できました。",
		"aliases": []
	},
	{
		"en": "Each mission is saved after its answer checks pass. Launch counts only include starts from Level Select.",
		"mm": "အဖြေမှန်စစ်ဆေးပြီးလျှင် မစ်ရှင်တစ်ခုချင်းစီကို သိမ်းဆည်းပါသည်။ ကစားသည့်အကြိမ်ရေတွင် အဆင့်ရွေးချယ်မှုမှ စတင်သည့်အကြိမ်များသာ ပါဝင်သည်။",
		"jp": "各ミッションは正解の確認後に保存されます。起動回数はレベル選択から開始した回数です。",
		"aliases": []
	},
	{
		"en": "Welcome, Designer",
		"mm": "ကြိုဆိုပါတယ် ဒီဇိုင်နာ",
		"jp": "ようこそ、デザイナー",
		"aliases": []
	},
	{
		"en": "Turn kitchen plans into clear design decisions.",
		"mm": "မီးဖိုချောင်ပုံစံမှ ရှင်းလင်းသော ဒီဇိုင်းဆုံးဖြတ်ချက်များဆီသို့။",
		"jp": "図面から、わかりやすいデザインの判断へ。",
		"aliases": []
	},
	{
		"en": "Read plans",
		"mm": "ပုံစံကို ဖတ်ပါ",
		"jp": "図面を読む",
		"aliases": []
	},
	{
		"en": "Explain clearly",
		"mm": "ရှင်းလင်းစွာ ပြောပြပါ",
		"jp": "わかりやすく説明",
		"aliases": []
	},
	{
		"en": "Choose components",
		"mm": "အစိတ်အပိုင်း ရွေးပါ",
		"jp": "部材を選ぶ",
		"aliases": []
	},
	{
		"en": "Choose a mission to build your kitchen design skills.",
		"mm": "မီးဖိုချောင်ဒီဇိုင်း ကျွမ်းကျင်မှုအတွက် မစ်ရှင်တစ်ခု ရွေးပါ။",
		"jp": "ミッションを選んで、キッチンデザインの力を磨きましょう。",
		"aliases": []
	},
	{
		"en": "Your mission",
		"mm": "သင့်မစ်ရှင်",
		"jp": "今回のミッション",
		"aliases": []
	},
	{
		"en": "Welcome",
		"mm": "ကြိုဆိုပါတယ်",
		"jp": "ようこそ",
		"aliases": []
	},
	{
		"en": "Stage %d complete!",
		"mm": "အဆင့် %d အောင်မြင်ပါပြီ။",
		"jp": "ステージ%d クリア！",
		"aliases": []
	},
	{
		"en": "Next Stage",
		"mm": "နောက်အဆင့်",
		"jp": "次のステージ",
		"aliases": []
	},
	{
		"en": "View Results",
		"mm": "ရလဒ် ကြည့်မည်",
		"jp": "結果を見る",
		"aliases": []
	},
	{
		"en": "Review answer",
		"mm": "အဖြေ ပြန်ကြည့်မည်",
		"jp": "回答を確認",
		"aliases": []
	},
	{
		"en": "Start a game first",
		"mm": "အရင် စကစားပါ",
		"jp": "ゲームを開始してください",
		"aliases": []
	},
	{
		"en": "Resume your saved game",
		"mm": "သိမ်းထားသည့်နေရာမှ ဆက်ကစားမည်",
		"jp": "保存した続きから再開",
		"aliases": []
	},
	{
		"en": "Go to Main Menu",
		"mm": "ပင်မမီနူးသို့",
		"jp": "メインメニューへ",
		"aliases": []
	},
	{
		"en": "Level reach",
		"mm": "အဆင့်တိုးတက်မှု",
		"jp": "ステージ到達",
		"aliases": []
	},
	{
		"en": "Plan Q&A",
		"mm": "ပုံစံ မေးခွန်း–အဖြေ",
		"jp": "図面 Q&A",
		"aliases": []
	},
	{
		"en": "Type your answer, then press OK.",
		"mm": "အဖြေရေးပြီး OK ကို နှိပ်ပါ။",
		"jp": "回答を入力して、OKを押してください。",
		"aliases": []
	},
	{
		"en": "How to answer",
		"mm": "ဖြေဆိုနည်း",
		"jp": "回答のしかた",
		"aliases": []
	},
	{
		"en": "Read the reference plan, write your answer in your own words, then press OK.",
		"mm": "ကိုးကားပုံစံကို ကြည့်ပြီး အဖြေကို ကိုယ့်စကားဖြင့် ရေးပါ။ ပြီးလျှင် OK ကို နှိပ်ပါ။",
		"jp": "参考図面を見て、自分の言葉で回答を書き、OKを押してください。",
		"aliases": []
	},
	{"en": "Choose your mission", "mm": "ကစားမည့် မစ်ရှင်ကို ရွေးပါ", "jp": "ミッションを選ぼう", "aliases": []},
	{"en": "Complete kitchen design missions to build your skills.", "mm": "မစ်ရှင်များ ကစားရင်း မီးဖိုချောင်ဒီဇိုင်း ကျွမ်းကျင်မှုကို မြှင့်တင်ပါ။", "jp": "ミッションでキッチンデザインのスキルを磨こう。", "aliases": []},
	{"en": "Your journey", "mm": "သင့်ခရီးစဉ်", "jp": "あなたの進み具合", "aliases": []},
	{"en": "%d / 3 complete", "mm": "၃ ခုမှ %d ခု ပြီးစီး", "jp": "%d / 3 クリア", "aliases": []},
	{"en": "Draw the layout", "mm": "အခန်းပုံစံ ဆွဲမည်", "jp": "間取りを描こう", "aliases": []},
	{"en": "Selected", "mm": "ရွေးထားသည်", "jp": "選択中", "aliases": []},
	{"en": "Select a number on the 3D model and type its name in Japanese.", "mm": "3D ပုံထဲက နံပါတ်ကို ရွေးပြီး အမည်ကို ဂျပန်လို ရေးပါ။", "jp": "3Dモデルの番号を選んで、部材の名前を日本語で入力してください。", "aliases": []},
	{"en": "Not answered", "mm": "မဖြေရသေး", "jp": "未回答", "aliases": []},
	{"en": "Drag to rotate. Scroll to zoom. The numbers stay attached to their parts.", "mm": "ဆွဲပြီး လှည့်ကြည့်ပါ။ Scroll ဖြင့် ချဲ့ကြည့်ပါ။ နံပါတ်များက သက်ဆိုင်ရာပစ္စည်းတွေနဲ့ တွဲနေပါမယ်။", "jp": "ドラッグで回転、スクロールで拡大。番号は各部材についています。", "aliases": []},
	{"en": "%d / 5 names correct", "mm": "၅ ခုမှ %d ခု မှန်ပြီ", "jp": "%d / 5 正解", "aliases": []},
	{"en": "Front view", "mm": "ရှေ့ဘက်", "jp": "正面", "aliases": []},
	{"en": "Rear view", "mm": "နောက်ဘက်", "jp": "背面", "aliases": []},
	{"en": "Number %d", "mm": "နံပါတ် %d", "jp": "番号 %d", "aliases": []},
	{"en": "Drag to rotate · Scroll to zoom", "mm": "ဆွဲ၍လှည့် · Scroll ဖြင့်ချဲ့", "jp": "ドラッグで回転・スクロールで拡大", "aliases": []},
	{"en": "Write in Japanese", "mm": "ဂျပန်လို ရေးပါ", "jp": "日本語で入力", "aliases": []},
	{"en": "Check answers", "mm": "အဖြေများ စစ်မည်", "jp": "回答を確認", "aliases": []},
	{"en": "Please check the red answers. Use Japanese names.", "mm": "အနီရောင်အဖြေများကို ဂျပန်အမည်ဖြင့် ပြန်စစ်ပါ။", "jp": "赤い回答を確認し、日本語の名前で入力してください。", "aliases": []},
	{"en": "Correct answers are saved. Complete the remaining numbers.", "mm": "မှန်သောအဖြေတွေ သိမ်းထားပါပြီ။ ကျန်နံပါတ်တွေကို ဆက်ဖြေပါ။", "jp": "正解は保存されました。残りの番号も答えてください。", "aliases": []},
	{"en": "Type the Japanese names beside the matching numbers.", "mm": "သက်ဆိုင်ရာနံပါတ်ဘေးမှာ ဂျပန်အမည်ကို ရေးပါ။", "jp": "対応する番号の横に日本語の名前を入力してください。", "aliases": []},
	{"en":"Please write the name of each numbered part in Japanese.","mm":"နံပါတ်တပ်ထားတဲ့ ပစ္စည်းတစ်ခုချင်းစီရဲ့ အမည်ကို ဂျပန်လို ရေးပေးပါ။","jp":"番号を付けた各パーツの名前を日本語で教えてもらえますか？","aliases":[]},
	{"en": "Convert", "mm": "ပြောင်းမည်", "jp": "変換", "aliases": []},
	{"en": "Check answer", "mm": "အဖြေစစ်မည်", "jp": "回答を確認", "aliases": []},
	{"en": "Type in hiragana, then choose a conversion.", "mm": "ဟိရဂနာနဲ့ရေးပြီး ပြောင်းလဲရေးသားပုံကို ရွေးပါ။", "jp": "ひらがなで入力して、候補から選んでください。", "aliases": []},
	{"en": "No candidates. Check the full hiragana reading.", "mm": "ပြောင်းလဲရေးသားပုံ မတွေ့ပါ။ ဟိရဂနာစာလုံးပေါင်းကို ပြန်စစ်ပါ။", "jp": "候補がありません。ひらがなの読みを確認してください。", "aliases": []},
	{"en": "Choose a conversion.", "mm": "ပြောင်းလဲရေးသားပုံကို ရွေးပါ။", "jp": "変換候補を選んでください。", "aliases": []},
	{"en": "Hover a number to answer · Drag to rotate · Scroll to zoom", "mm": "နံပါတ်ပေါ်ထောက်၍ ဖြေပါ · ဆွဲ၍လှည့် · Scroll ဖြင့်ချဲ့", "jp": "番号にカーソルを合わせて回答・ドラッグで回転・スクロールで拡大", "aliases": []},
 {"en":"Selected part","mm":"ရွေးထားသော အစိတ်အပိုင်း","jp":"選択したパーツ","aliases":[]},
 {"en":"%d / %d names correct","mm":"%d / %d ခု အမည်မှန်ပြီ","jp":"%d / %d 個正解","aliases":[]},
 {"en":"Click a kitchen part and type its name in Japanese.","mm":"မီးဖိုချောင် အစိတ်အပိုင်းကို နှိပ်ပြီး ဂျပန်အမည်ကို ရေးပါ။","jp":"キッチンのパーツをクリックして、日本語の名前を入力してください。","aliases":[]},
 {"en":"Click a part to answer. Drag to rotate 360°. Scroll to zoom.","mm":"ပစ္စည်းကို နှိပ်၍ ဖြေပါ။ ဆွဲ၍ 360° လှည့်ကြည့်ပါ။ Scroll ဖြင့် ချဲ့ပါ။","jp":"パーツをクリックして回答。ドラッグで360°回転、スクロールで拡大。","aliases":[]},
 {"en":"Click a part to answer · Drag to rotate 360° · Scroll to zoom","mm":"ပစ္စည်းကို နှိပ်၍ဖြေ · ဆွဲ၍ 360° လှည့် · Scroll ဖြင့်ချဲ့","jp":"パーツをクリックして回答・ドラッグで360°回転・スクロールで拡大","aliases":[]},
 {"en":"Rotate left","mm":"ဘယ်ဘက်လှည့်","jp":"左に回転","aliases":[]},
 {"en":"Rotate right","mm":"ညာဘက်လှည့်","jp":"右に回転","aliases":[]}
]
