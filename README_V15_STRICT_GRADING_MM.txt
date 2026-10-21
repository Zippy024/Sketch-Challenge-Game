SKETCH CHALLENGE V15 – STRICT STAGE 2 ANSWER CHECKING (Myanmar / Japanese / English)

အဓိကပြင်ဆင်ချက်
- Stage 2 ကို အဖြေမှန်ပေးရန် PS ရဲ့ သဘောတရား ၃ ချက်လုံး ပါရမည်။
  1) PS က building pipe shaft / pipe service space ဖြစ်ခြင်း
  2) ရေပေး/ရေဆင်းပိုက်များ ဖြတ်သန်းသည့် ဒေါင်လိုက် service space ဖြစ်ခြင်း
  3) Renovation လုပ်ချိန် အလွယ်တကူ ရွှေ့မရခြင်း
- Japanese/Myanmar/English ဘာသာစကားမရွေး၊ စကားလုံးတူဖို့မလို၊ သဘောတရားပေါ်မူတည်၍ AI စစ်သည်။
- Pipe Shaft / Pipe Space ဆိုတာသာ ရေးထားလျှင် မပြည့်စုံသဖြင့် မှားမည်။
- Gemini မှာ ၃ ချက်ကို သီးသန့် boolean အဖြစ် စစ်ပြီး Worker မှာ AND ချိတ်ထားသည်။
- Local Checker မှာလည်း ၃ ချက်လုံးပါမှ Correct (keyword-based; approximate)။
- Correct/Incorrect Result များကိုသာ Godot ဆီပို့သည်။ အဖြေမှန်/Hints မဖော်ပြ။
- Gemini 3-model backup and local fallback are preserved. Model names are unchanged from V14.

အစားထိုးရမည့်ဖိုင်များ
  * Stage2.gd  -> Godot project root (res://Stage2.gd)
  * CloudflareWorker/worker.js -> Cloudflare Edit code ထဲမှာ Code Replace & Deploy

အရေးကြီး
- Godot ကို အရင်စမ်းပြီးမှ GitHub Actions နဲ့ Web Deploy လုပ်ပါ။
- Cloudflare Worker ကို မပြင်ရသေးသော် AI က အဖြေတိုတိုကို Correct ပေးနိုင်ပါသေးသည်။
- Godot Stage2.gd ကို မပြင်ရသေးသော် Offline Local Mode မှာ အဖြေတိုတိုကို Correct ပေးနိုင်ပါသေးသည်။
- နှစ်နေရာလုံး Update လုပ်ပါ။ GEMINI_API_KEY Secret ကို ပြန်ထည့်စရာမလိုပါ။

TEST CASES
FALSE: PS means Pipe Shaft.
FALSE: PS は「Pipe Space（パイプスペース）」の略です。
FALSE: PS is a vertical space for water and drainage pipes.
TRUE : PS is a vertical space for water supply and drainage pipes. It cannot easily be relocated during renovation.
TRUE : PS（Pipe Shaft：パイプシャフト）とは、建物内の給水管・排水管などの配管を通すための縦方向のスペースです。リフォームの際には、簡単に動かす事ができません。
TRUE : PS ဆိုတာ ရေပေးပိုက်၊ ရေဆင်းပိုက်တွေ သွားတဲ့ ဒေါင်လိုက်နေရာဖြစ်ပြီး ပြုပြင်မွမ်းမံချိန်မှာ အလွယ်တကူ ရွှေ့လို့မရပါဘူး။

Note: AI classification can still make mistakes. Local checker uses keywords and is only an approximation.
