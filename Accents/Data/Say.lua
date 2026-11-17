-- Dalorrian's Accents (1.4.0): the everyday chat lines (brb, back, rez, oom, grats, good job, on my way...) for
-- Skyborne and the unlockable accents, which only had a handful, plus four new ones for every accent:
-- on my way, welcome back, good luck and a summon. Lines are added to what an accent already says, never replaced.
local ADDON, ns = ...

local function S(key, t)
  local d = ns.ACCENTS[key]
  if not d or d.whole then return end
  d.say = d.say or {}
  for id, v in pairs(t) do
    local list = d.say[id]
    if type(list) == "string" then list = { list } end
    list = list or {}
    local have = {}
    for _, l in ipairs(list) do have[l:lower()] = true end
    for line in v:gmatch("[^|]+") do
      if not have[line:lower()] then list[#list + 1] = line; have[line:lower()] = true end
    end
    d.say[id] = list
  end
  d._index = nil
end

---------------------------------------------------------------------------
-- the eight races: the four new lines
---------------------------------------------------------------------------
S("orc", { omw = "Me come now!|On my way. Lok'tar!|I march to you!", wb = "You return! Good.|Welcome back, brother.|Throm-Ka, you are back!",
  gl = "Strength and honor!|Fight well!|May your axe strike true!", summon = "Summon me! Dark magic is fine today.|Bring me to you!|I need a summon." })
S("troll", { omw = "I be comin', mon!|On me way, mon.|Hold tight, I be dere soon.", wb = "Ey, ya back, mon!|Welcome back, mon.|Da spirits brought ya back!",
  gl = "Da spirits be wit' ya!|Good luck, mon!|Stay away from da voodoo!", summon = "Gimme a summon, mon.|Can ya summon me, mon?|Pull me through, mon." })
S("tauren", { omw = "I walk to you now.|On my way, friend.|My hooves carry me to you.", wb = "The winds bring you back.|Welcome back, friend.|It is good to see you return.",
  gl = "Walk with the Earth Mother.|May the winds guide you.|Ancestors watch over you.", summon = "Would you summon me, friend?|A summon would spare my hooves.|Please call me to you." })
S("forsaken", { omw = "I am coming. Slowly. Things fall off.|On my way.|I shamble to you now.", wb = "Oh. You came back.|Welcome back. How unfortunate for you.|Back among the living. Sort of.",
  gl = "Try not to die. It is overrated.|Good luck. You will need it.|May death pass you by. For now.", summon = "Summon me. Walking is for the living.|A summon, if you would.|Drag me through the void, please." })
S("human", { omw = "I shall be there shortly.|On my way, good sir.|I ride to you at once!", wb = "Welcome back, friend!|Ah, you have returned!|Splendid, you are back.",
  gl = "Light be with you!|Good fortune to you!|May the Light guide you.", summon = "Might I trouble you for a summon?|A summon, if you please.|Would you kindly summon me?" })
S("dwarf", { omw = "On me way, lad!|I'm comin', hold yer beard!|Be there in two shakes!", wb = "Yer back! About time!|Welcome back, lad!|Look who wandered back in!",
  gl = "Keep yer feet on the ground!|Good luck, lad!|May yer hammer hit true!", summon = "Summon me, me legs are short!|Can I get a summon, lad?|Save me the walk, would ye?" })
S("gnome", { omw = "On my way! Estimated arrival: soon!|Coming, coming!|En route at maximum velocity!", wb = "Welcome back! Statistically likely!|Oh good, you're back!|You're back! Excellent!",
  gl = "Good luck! The odds are acceptable!|May your gadgets not explode!|Good luck! I ran the numbers!", summon = "Summon me, please! Short legs!|Requesting one summon!|A summon would be optimal!" })
S("nightelf", { omw = "I come swiftly.|On my way, friend.|The shadows carry me to you.", wb = "Elune has returned you to us.|Welcome back, friend.|The stars guided you back.",
  gl = "Elune light your path.|May the stars guide you.|Go with Elune's grace.", summon = "Would you summon me, friend?|I ask for a summon.|Call me to your side, please." })

---------------------------------------------------------------------------
-- Skyborne
---------------------------------------------------------------------------
S("skyborne", { afk = "I drift away a moment.|Away on the winds for a bit.", good = "The winds are kind today.|I soar, thank you.", goodjob = "Well flown!|Gracefully done, sky-kin!|A fine flight, that!",
  hungry = "I could eat a sky-feast.|My wings need feeding.", invite = "Room in the flight for one more?|May I join your flight?",
  omw = "I fly to you now!|On the wind, on my way.|Swift as a gale, I come.", wb = "The winds return you to us!|Welcome back, sky-kin.|Fair winds brought you back!",
  gl = "Fair winds to you!|Winds be at your back!|May the skies be kind.", summon = "Would you summon me, sky-kin?|A summon would save my wings.|Call me across the winds, please." })

---------------------------------------------------------------------------
-- the unlockables
---------------------------------------------------------------------------
S("pirate", { afk = "Gone below deck a moment!|Steppin' off the ship, back soon.", good = "Shipshape, matey!|Fine as a fair wind!", goodjob = "Well done, ye sea dog!|That be fine work, matey!|Smartly done!",
  howareyou = "How fare ye, matey?|How be the seas treatin' ye?", hungry = "Me belly's emptier than a looted chest!|I need grub, mateys!", invite = "Room aboard for one more?|Permission to come aboard?",
  rez = "Fish me out of the locker!|Bring me back, matey!|Raise me from the depths!", omw = "Settin' sail for ye now!|On me way, matey!|Full sail, I be comin'!",
  wb = "Welcome back aboard!|Ye be back, matey!|Look what the tide dragged in!", gl = "Fair winds to ye!|May yer plunder be plenty!|Good luck, ye scallywag!",
  summon = "Summon me, I've no ship here!|Haul me over, matey!|Can ye summon an old sea dog?" })
S("goblin", { afk = "On break. Union rules.|Away. Leave a message and a deposit.", good = "Business is booming!|Can't complain, profits are up!", goodjob = "Now that's a return on investment!|Nice work, pal!|Quality job. I'd pay for that. Almost.",
  goodnight = "Closing up shop for the night!|Night! The meter stops now.", howareyou = "How's business, pal?|How ya doin', customer?", hungry = "I could eat. Who's buying?|Lunch break! Not on my dime.",
  invite = "Got a spot? I'll make it worth your while!|Invite me, it's a great deal!", rez = "Rez me, I'll owe ya!|Bring me back, I've got unfinished business!|A rez! Put it on my tab!",
  congrats = "Congrats, pal! Drinks are on you!|Nice! That's worth a bonus!", omw = "On my way, time is money!|Coming! Rocket's warmed up!|Be there before the price goes up!",
  wb = "You're back! The meter was running!|Welcome back, pal!|Back already? Good for business!", gl = "May your profits be high!|Good luck, pal!|Don't spend it all in one place!",
  summon = "Summon me, it saves on fuel!|A summon! Cheaper than a zeppelin!|Summon me, pal, I'll owe ya one!" })
S("kobold", { afk = "Kobold go away little bit!|Kobold hide in tunnel, back soon.", congrats = "Good good! Kobold happy for you!|Yay yay! Big shiny for you!", good = "Kobold good! Candle still lit!|Good good!",
  goodjob = "Good dig! Very good dig!|You do good! Kobold clap!|Nice nice!", goodnight = "Kobold sleep now. Keep candle safe!|Night night! No take candle!", howareyou = "You good? Kobold good!|How you? How candle?",
  hungry = "Kobold hungry! Want snack!|Belly empty! Snack time!", invite = "Kobold come too? Please please?|Take Kobold! Kobold dig good!", oom = "Kobold candle low! Need glowy water!|No more glowy! Kobold drink!",
  rez = "Kobold dead! Light candle again!|Bring Kobold back! Please please!|Kobold go dark! Help!", sorry = "Sorry sorry! Kobold not mean it!|Kobold sorry! No hit Kobold!", welcome = "Is okay! Kobold happy help!|No problem, yes yes!",
  omw = "Kobold coming! Scurry scurry!|Kobold on way! Very fast!|Coming coming!", wb = "You back! Yay yay!|Kobold missed you!|Back back! Good good!",
  gl = "Good luck! Keep candle lit!|Luck luck! Kobold cheer!|No lose candle!", summon = "Summon Kobold? Tunnel very long!|Pull Kobold through, please please!|Kobold legs tired! Summon!" })
S("ogre", { afk = "Me go away. Me come back.|Me gone little bit.", back = "Me back!|Me here again!|Ogre return!", brb = "Me be back. No start without me.|Me go, me come back quick.|Wait for me. Me slow.",
  congrats = "You do good! Me clap!|Good for you! Me proud!", good = "Me good! Me ate!|Me fine. Head hurt little.", goodjob = "Good smash!|You smash good!|Dat was good! Me like!",
  goodnight = "Me sleep now. Big sleep.|Night night. Me tired.", howareyou = "How you? You good?|You okay? Me okay.", invite = "Me come too?|Take me! Me smash for you!",
  oom = "Me out of magic stuff!|No more glowy. Me drink.|Head empty! Need blue drink!", rez = "Me dead. Fix me.|Make me not dead!|Me fall down. Help.", run = "Run! Me run too!|Go go! Too many!",
  sorry = "Me sorry. Me not see.|Oops. Me did dat.", welcome = "Is okay.|Me help. Is fine.", omw = "Me coming! Me slow but me coming!|Me walk to you now.|On way. Ground shake when me run.",
  wb = "You back! Good!|Me missed you. Little bit.|Friend back!", gl = "Good luck! Smash good!|Hit dem hard!|No die!", summon = "Summon me? Me too big to walk.|Pull me there!|Me need summon. Legs tired." })
S("raidboss", { afk = "I withdraw. Do not mistake it for mercy.|My attention is needed elsewhere, mortals.", back = "I HAVE RETURNED!|Your doom walks among you once more.|Did you think me gone, mortals?",
  brb = "Remain here, insects. I shall return.|A brief reprieve. Savor it.|Do not move. I will be back.", good = "I am magnificent, as always.|My power grows. I am well.",
  goodjob = "Adequate, mortal. Most adequate.|You have pleased me. Rare.|Impressive. For an insect.", goodnight = "I retire to my sanctum. Tremble until dawn.|Sleep, mortals. I will be in your nightmares.",
  howareyou = "How fare my future victims?|Speak, mortals. How do you fare?", hungry = "I HUNGER!|Bring me a feast, minions!", idk = "Even I cannot foresee that.|That knowledge is hidden, even from me.",
  invite = "You will invite me. It was not a request.|Grant me entry, mortals.", oom = "My power wanes! A moment, fools!|I must restore my power. Do not look at me.|My mana fades. This changes nothing!",
  rez = "RAISE ME, MINIONS!|This is not the end. Resurrect me!|I demand to be restored!", welcome = "You are welcome. Remember this mercy.|It was nothing, mortal.",
  omw = "I COME FOR YOU!|Your doom approaches!|I am on my way. Prepare yourselves.", wb = "So, you have returned. Brave.|Welcome back to your doom.|You dare return?",
  gl = "You will need more than luck.|Fortune favors no one here. But good luck.|Go. Try not to disappoint me.", summon = "SUMMON ME, FOOLS!|Open a portal, minions. I do not walk.|I require a summon. Now." })
S("bard", { afk = "I step away to tune my lute!|Away a moment, good folk!", back = "Your bard returns!|I am back, and with a new verse!|The music resumes!", brb = "A short interlude, friends!|Back before the next verse!|One moment, the lute needs tuning!",
  congrats = "A song shall be sung of this!|Huzzah! Well earned, friend!|Three cheers and a ballad for you!", good = "Merry as a spring morning!|In fine voice, thank you!", goodjob = "Bravo! Bravo!|That deserves a verse!|Splendidly done, friend!",
  howareyou = "How fares my audience?|How goes your tale today?", hungry = "A bard sings poorly on an empty stomach!|Is there supper? I will sing for it!", invite = "Room for a minstrel in your company?|Take me along, I work for applause!",
  oom = "My voice is spent! A drink!|No more songs until I drink!|The well of magic runs dry, friends!", rez = "Bring your bard back! The song is unfinished!|Revive me, I have verses left!|Alas, I am slain! A little help?",
  omw = "I come with a song in my heart!|On my way, humming as I go!|Your bard approaches!", wb = "Welcome back! We saved you a verse!|The audience returns!|Back at last, friend!",
  gl = "May fortune sing for you!|Good luck! I will write the ballad!|Break a lute string!", summon = "Summon me, my feet are sore from dancing!|A summon for a weary minstrel?|Carry me there by magic, I beg!" })
S("noir", { afk = "Stepping out. Don't wait up.|I'll be gone a while. Keep the light on.", back = "I'm back. The city never noticed I left.|Back on the case.|I walked back in like I owned the place.",
  brb = "Back in five. Don't touch anything.|Sit tight, pal. I'll be back.|Gotta see a guy about a thing.", congrats = "Nice work, kid. Drinks are on me.|You earned it, pal.|Not bad. Not bad at all.",
  good = "Can't complain. Nobody listens anyway.|I've been worse, pal.", goodjob = "Clean work, pal.|You did good, kid.|That's how it's done in this town.", howareyou = "How's tricks, pal?|What's the word on the street?",
  hungry = "I need a sandwich and a miracle.|Haven't eaten since the last case.", invite = "Got room for one more gumshoe?|Deal me in, pal.", rez = "Get me up, pal. I've got a case to close.|I'm down. Wouldn't be the first time.|Bring me back. The night's not over.",
  run = "Beat it! Now!|Time to blow this joint!", wait = "Hold it, pal.|Not so fast.", welcome = "Forget about it.|Don't mention it, pal.",
  omw = "On my way. Keep the motor running.|I'm coming, pal. Sit tight.|Be there in a heartbeat.", wb = "Look who walked back in.|Welcome back, pal.|You came back. They always do.",
  gl = "Watch your back out there.|Good luck, kid. You'll need it.|Stay sharp, pal.", summon = "Summon me, pal. My feet are killing me.|I need a lift across town.|Pull me in. I'll owe you one." })
S("sergeant", { afk = "Stepping away from my post! Back shortly!|Away! Hold the line!", back = "Back at my post!|Sergeant on deck!|I'm back! Fall in!", brb = "Hold position! Back in two!|Nobody move! I'll be back!|Short break! Stay sharp!",
  congrats = "Outstanding, soldier!|You've earned that stripe!|Well earned! Now back to work!", good = "Squared away, soldier!|Fit to fight!", goodjob = "Outstanding work!|That's how it's done!|Good work, soldier!",
  goodnight = "Lights out! Reveille at dawn!|Dismissed for the night!", howareyou = "Sound off! How are you holding up?|Status report, soldier!", hungry = "Chow time! Move it!|I need rations, on the double!",
  idk = "Unknown! I'll find out!|No intel on that!", invite = "Requesting to join your unit!|Permission to fall in!", rez = "Man down! Get me up!|Medic! On the double!|Get me back in the fight!",
  welcome = "Just doing my duty!|Anytime, soldier!", omw = "Moving to your position!|On my way, double time!|Inbound! Hold tight!", wb = "Welcome back, soldier!|Back in formation!|Good to have you back!",
  gl = "Give them everything you've got!|Good luck, soldier!|Make me proud out there!", summon = "Requesting a summon!|Get me to the front! Summon!|Need transport! Summon me!" })
S("epic", { afk = "I must away a while.|I step from the path a moment.", back = "I am returned.|Lo, I have come back.|My road has led me back to you.", brb = "I shall return ere long.|Tarry here, I shall not be long.|Await me, friends.",
  congrats = "Well earned, and well met!|Songs shall be sung of this day!|A worthy deed, my friend!", good = "I am well, by the grace of the stars.|My heart is light today.", goodjob = "A deed worthy of song!|Well done, valiant friend!|Bravely done!",
  howareyou = "How fare you, friend?|What tidings, my companions?", hungry = "I have not broken bread since dawn.|Is there no supper on this road?", invite = "May I join your fellowship?|Have you room for one more traveler?",
  oom = "My strength is spent. I must rest.|The well of my power runs dry.|Grant me a moment to recover.", rez = "Call me back from the shadow!|I have fallen. Raise me, friends!|My tale is not yet ended. Restore me!",
  omw = "I come with all haste!|I ride to you now!|My road leads to you!", wb = "Well met again, friend!|You are returned, and gladly!|The fellowship is whole once more.",
  gl = "May the stars light your path!|Fortune go with you!|Go with courage, friend!", summon = "Would you call me to your side?|A summons, if you have the art.|Bring me to you by your craft, I pray." })
S("grimdark", { afk = "I'm stepping away. Try not to die.|Away. Watch the crows.", back = "I'm back. Who's still alive?|Returned. Somehow.|Back. Nothing got better, I see.", brb = "Back soon. If I live.|Hold here. I won't be long.|Wait. And keep your swords close.",
  congrats = "Well earned. Enjoy it while it lasts.|You lived to earn it. Rare.|Good. Don't let it make you soft.", good = "Still breathing. That's enough.|Well enough, for these times.", goodjob = "Well fought. We live another day.|Good work. It won't save us, but good work.|That was well done.",
  howareyou = "Still alive, are you?|How do you fare in these dark days?", hungry = "I haven't eaten since the siege.|Bread. Salt. Anything.", invite = "Room for another sword?|Take me with you. I've nothing left here.",
  oom = "I'm spent. Give me a moment.|My strength is gone. I need to drink.|No more in me. Wait.", rez = "Bring me back. There's dying left to do.|I'm dead. Fix it, if you can.|Raise me. Winter isn't done with us.",
  welcome = "It was nothing. Remember it anyway.|Think nothing of it.", omw = "On my way. If the road allows.|I ride to you.|Coming. Don't die before I get there.",
  wb = "You came back. Few do.|Welcome back. You're not dead, then.|Back from the dark.", gl = "Good luck. The gods won't help.|Try to live.|May your death be quick, or late.",
  summon = "Summon me. The roads aren't safe.|Bring me through. I've walked enough.|A summon. I'll owe you a debt." })
S("wry", { afk = "Away for a bit. Try to cope.|Stepping out. The world will manage, probably.", back = "I'm back, for what it's worth.|Returned, against all odds.|Back. Nothing exploded, I assume.",
  brb = "Back shortly. Probably.|One moment. These things take as long as they take.|Back in a bit. Don't do anything interesting.", congrats = "Congratulations. Genuinely.|Well done. I mean that, mostly.|Good for you. Really.",
  good = "Can't complain. Well, I could, but who has the time.|Fine, in the general sense.", goodjob = "That went surprisingly well.|Nicely done. Suspiciously so.|Good work, against all expectations.",
  howareyou = "How are we all, broadly speaking?|How's everyone holding up?", hungry = "I could eat. I could usually eat.|Lunch has become a matter of some urgency.", invite = "Is there room for one more? There's usually room for one more.|I'd like to join, if that's allowed.",
  oom = "Out of mana, which is to say out of options.|I appear to have run out. One moment.|No mana. A brief pause for refreshment.", rez = "I seem to be dead. A little help.|I've died, which is inconvenient.|Could someone un-dead me, please?",
  wait = "Hold on a moment.|Wait. Just, wait.", welcome = "Don't mention it. Really, don't.|It was nothing. Almost literally.", omw = "On my way, at a reasonable pace.|Coming. Eventually.|I'm heading over. Brace yourselves.",
  wb = "Welcome back. We barely managed.|Oh good, you're back.|Back, are you? Nothing changed.", gl = "Good luck. You'll probably be fine.|Best of luck. No, really.|Try not to die. It's a lot of paperwork.",
  summon = "A summon would be lovely. Walking is overrated.|Could someone summon me? It's quite far.|Summon me, if it's no trouble. It's some trouble, I know." })
S("wizard", { afk = "I must consult my tomes. Away!|Stepping into my study a moment.", back = "I have returned! Now, where was I?|Back! Did I miss anything arcane?|The wizard returns!", brb = "One moment, I left a cauldron on!|Back shortly, a spell needs stirring!|A brief absence, apprentices!",
  congrats = "Splendid! Most well deserved!|Congratulations, young apprentice!|A fine achievement, by my beard!", good = "Splendid, splendid! A touch forgetful.|Quite well, thank you!", goodjob = "Marvelously done!|A masterful display!|Well cast, well cast!",
  goodnight = "To bed! A wizard needs his rest!|Good night! Mind the enchanted candles!", howareyou = "How fare you, apprentices?|And how are we all this fine day?", hungry = "A wizard cannot conjure on an empty stomach!|Is it supper yet? I have lost track of the century.",
  invite = "Have you room for an old wizard?|I shall join you, if I may!", rez = "Bring me back! I was mid-incantation!|Oh bother, I've died. A little help!|Restore me, I have spells unfinished!",
  welcome = "Think nothing of it, my boy!|A trifle, a mere trifle!", omw = "I come! Now, which way was it?|On my way, by staff and by foot!|I shall be there in a twinkling!",
  wb = "Ah, you've returned! Splendid!|Welcome back! Now, who are you again?|Back at last, my apprentice!", gl = "May your spells hold true!|Good luck! Mind the fireballs!|Fortune and fair magic to you!",
  summon = "A summon, if you please! My knees are four hundred years old.|Summon me, there's a good fellow!|Would someone conjure me over?" })
S("prospector", { afk = "Steppin' away from the claim a spell!|Gone to check the mule!", back = "I'm back, by gum!|Back at the claim!|Ol' prospector's back!", brb = "Be right back, don't touch my gold!|Back in a jiffy!|Hold my pickaxe, I'll be back!",
  congrats = "Well I'll be! Congratulations!|Ya struck it rich, partner!|Hot diggity, good for you!", good = "Fit as a fiddle!|Finer than gold dust!", goodjob = "Mighty fine work!|That's the way to dig!|Good work, partner!",
  goodnight = "Time to hit the bedroll!|Night! Watch the claim for me!", howareyou = "How ya holdin' up, partner?|How's the diggin'?", hungry = "I could eat a whole pot o' beans!|My belly's emptier than a played-out mine!",
  invite = "Got room for an old prospector?|Mind if I tag along, partner?", oom = "Plumb out of magic! Gotta drink!|Dry as a dust mine! Hold up!|Outta juice, partner!", rez = "Dagnabbit, I'm dead! Little help!|Dig me back up, partner!|Bring me back, I ain't found my gold yet!",
  sorry = "Dagnabbit, my mistake!|Sorry, partner!", wait = "Hold yer horses!|Whoa there, partner!", welcome = "Don't mention it, partner!|Weren't nothin'!",
  omw = "On my way, quick as my old legs go!|Comin', partner!|Headin' yer way now!", wb = "Well, look who's back!|Welcome back, partner!|Back at the diggin's!",
  gl = "May ya strike it rich!|Good luck, partner!|Hope ya hit the mother lode!", summon = "Summon me, my mule ran off!|Can ya summon an old-timer?|Save my poor knees, summon me!" })
S("caveman", { afk = "Ugg go. Ugg come back.|Ugg away.", back = "Ugg back!|Ugg here!|Ugg return!", brb = "Ugg be back.|Wait. Ugg come back.|Ugg go quick.", congrats = "Good! Ugg happy for you!|You do big thing! Good!",
  good = "Ugg good.|Ugg fine. Ugg ate.", goodjob = "Good hunt!|You do good!|Good bonk!", goodnight = "Ugg sleep now.|Dark time. Ugg sleep.", howareyou = "You good?|How you?",
  invite = "Ugg come too?|Take Ugg!", oom = "Ugg magic gone! Ugg drink!|No more magic!|Ugg empty!", rez = "Ugg dead. Help Ugg!|Make Ugg not dead!|Ugg fall. Ugg need help.", sorry = "Ugg sorry.|Oops. Ugg did bad.",
  wait = "Wait!|Stop! Wait Ugg!", welcome = "Is good.|Ugg help. Is fine.", omw = "Ugg come!|Ugg walk to you!|Ugg on way!", wb = "You back! Good!|Friend back!|Ugg happy you back!",
  gl = "Good hunt!|No die!|Bonk good!", summon = "Bring Ugg! Ugg legs tired!|Magic pull Ugg?|Ugg need summon!" })
S("robot", { afk = "Entering standby mode.|Unit away. Please hold.", back = "Unit online.|I have returned. Resuming.|Reboot complete.", brb = "Rebooting. Please wait.|Brief pause. Do not power off.|Returning shortly.",
  congrats = "Congratulations. Achievement logged.|Well done, human. Recording success.|Positive outcome detected. Congratulations.", good = "All systems normal.|Operating within normal limits.", goodjob = "Task completed well.|Performance rated excellent.|Good work, human.",
  goodnight = "Entering sleep mode.|Powering down. Good night, humans.", howareyou = "Status report, human?|How are your systems?", hungry = "Fuel level low.|This unit requires fuel.",
  invite = "Requesting group access.|Add this unit to your group.", rez = "Unit offline. Restart required.|Critical failure. Please reboot me.|This unit has stopped. Assist.",
  welcome = "You are welcome, human.|Assistance is my function.", omw = "En route. Arrival soon.|Moving to your location.|On my way. Calculating path.", wb = "Welcome back, human.|User detected. Welcome back.|You have returned. Good.",
  gl = "Good luck. Your odds are acceptable.|May your odds be favorable.|Success probability: reasonable. Good luck.", summon = "Requesting transport.|Summon this unit, please.|Transport required. Legs are slow." })
S("peasant", { afk = "Off to feed the pigs, back soon!|Steppin' away, the turnips need me!", back = "I'm back, sorry to trouble you!|Back from the fields!|Returned, if it please you!", brb = "Back in a moment, beggin' your pardon!|Won't be long!|One moment, the goat's loose!",
  congrats = "Well done, truly! You deserve it more than the likes of me!|Blimey, congratulations!|Good on you!", good = "Can't complain, got a turnip today!|Well enough, thank you kindly!", goodjob = "Right good work, that!|Well done, well done!|That was proper good!",
  goodnight = "Off to me straw bed!|Night! Up with the rooster tomorrow!", howareyou = "How d'you do?|You keepin' well?", hungry = "I've not eaten since yesterday's turnip!|Starvin', I am!",
  invite = "Room for a humble peasant?|Could I come along, if it's no bother?", oom = "I'm all out of magic, beggin' your pardon!|No more in me! Need a drink!|Plum out, I am!", rez = "I've died again! Sorry to be a bother!|Could someone bring me back? If it's no trouble?|Dead, I am! Help!",
  wait = "Wait for me, please!|Hold on a tick!", welcome = "Happy to help, I am!|No trouble at all!", omw = "Comin' as fast as me legs go!|On me way!|Be right there!",
  wb = "Welcome back! We kept the fire going!|Oh, you're back!|Good to see you back!", gl = "May the harvest be kind to you!|Good luck! Mind the dragons!|Luck to you!",
  summon = "Could you summon me? I've no horse!|A summon, if it's no bother!|Me feet are worn through, summon me please!" })
S("cowboy", { afk = "Steppin' off the trail a spell.|Gone to water the horse.", back = "I'm back in the saddle!|Back, partner!|This cowpoke's back!", brb = "Back in two shakes!|Hold my horse, I'll be back!|Be right back, partner!",
  congrats = "Well I'll be! Congratulations, partner!|Yeehaw! Good for you!|Mighty fine, you earned it!", good = "Fine as frog hair!|Can't complain, partner!", goodjob = "Mighty fine work, partner!|That's how the west was won!|Good shootin'!",
  goodnight = "Time to hit the hay!|Night, y'all! Keep the campfire lit!", howareyou = "How y'all doin'?|How ya holdin' up, partner?", hungry = "I could eat a horse! Not mine though!|Chuck wagon better be close!",
  invite = "Got room in the posse?|Mind if I ride along?", oom = "Plumb out of juice, partner!|Outta mana! Gotta wet my whistle!|Dry as a desert! Hold up!", rez = "I bit the dust! Little help!|Get me back in the saddle!|Patch me up, partner!",
  welcome = "Don't mention it, partner!|Happy to oblige!", omw = "Ridin' your way now!|On my way, partner!|Be there quicker than a jackrabbit!", wb = "Welcome back, partner!|Well, look who rode back into town!|Back in the saddle, I see!",
  gl = "Happy trails, partner!|Good luck out there!|Keep your powder dry!", summon = "Summon me, my horse threw a shoe!|Reckon you could summon me?|Save me a long ride, partner!" })
S("surfer", { afk = "Gonna go catch a wave, back soon!|Stepping out, dudes!", back = "I'm back, dudes!|Back in the lineup!|Dude's back!", brb = "Back in a sec, brah!|Hang tight, dudes!|One sec, gotta wax the board!",
  congrats = "Duuude, congrats!|So stoked for you, brah!|Gnarly! You earned it!", good = "Totally stoked, dude!|Living the dream, brah!", goodjob = "Righteous work, dude!|That was gnarly, brah!|Sick job, dudes!",
  goodnight = "Catching some Zs, dudes!|Night, brahs! Dawn patrol tomorrow!", howareyou = "How's it hanging, dude?|What's up, brah?", hungry = "Dude, I'm starving! Tacos?|Need grinds, brah!",
  invite = "Room for one more dude?|Can I paddle out with you?", oom = "Out of juice, dude! Smoothie break!|I'm tapped, brah!|No mana, dudes! Hang on!", rez = "Total wipeout! Little help, dude!|I got worked, brah! Rez?|Pull me out of the water, dude!",
  wait = "Whoa, hang on, dude!|Chill a sec, brah!", welcome = "No worries, brah!|Anytime, dude!", omw = "Paddling over, dude!|On my way, brah!|Coming in hot, dudes!",
  wb = "Dude, you're back!|Welcome back, brah!|Stoked you're back!", gl = "Good vibes, brah!|Shred it, dude!|Stay stoked out there!", summon = "Summon me, dude, it's so far!|Can I get a summon, brah?|Beam me over, dudes!" })
S("butler", { afk = "If you will excuse me a moment.|I shall step out briefly.", back = "I have returned.|At your service once more.|I am back, and the tea is warm.", brb = "I shall return momentarily.|One moment, if you please.|Pray excuse me, I shan't be long.",
  congrats = "My sincere congratulations.|Most well deserved, if I may say so.|Splendid news. Congratulations.", good = "Quite well, thank you for asking.|Very well indeed.", goodjob = "Most excellently done.|A fine piece of work, if I may say.|Impeccably done.",
  goodnight = "I bid you good night. Shall I turn down the bed?|Good night. I shall see to the candles.", howareyou = "I trust you are well?|And how are we this evening?", hungry = "I believe luncheon is overdue.|One does feel rather peckish.",
  invite = "Might I be permitted to join?|If there is room, I should be glad to attend.", oom = "I regret that my mana is exhausted.|One moment, I must take refreshment.|I find myself quite out of mana.", rez = "I regret to report that I have died.|If someone would be so kind as to revive me.|I appear to be deceased. My apologies.",
  omw = "I shall be there directly.|I am on my way at once.|I am en route, with all proper haste.", wb = "Welcome back. I trust your absence was pleasant.|Welcome back. Tea is ready.|How good to have you back.",
  gl = "I wish you every success.|The best of fortune to you.|Do take care.", summon = "Might I trouble you for a summon?|A summon would be most appreciated.|If you would be so kind as to summon me." })
S("grumpy", { afk = "I'm stepping away. Don't touch anything.|Away. My back needs a rest.", back = "I'm back. Don't make a fuss.|Back. Nobody asked, I know.|I'm back, what did you break?", brb = "Back in a minute. My knees.|Hold on, I'll be back.|Be right back. Don't start without me.",
  congrats = "Congratulations. Don't let it go to your head.|Well, good for you.|Hmph. You earned it, I suppose.", good = "Fine. My back hurts, but fine.|I've been worse.", goodjob = "Not bad. Could've been faster.|Good job, I suppose.|Fine work. Don't expect a parade.",
  goodnight = "I'm going to bed. Keep it down.|Night. It's past my bedtime anyway.", howareyou = "How are you. There, I asked.|You all right? Good. Me neither.", hungry = "I'm hungry. Nobody feeds me anymore.|Is it supper yet? It should be supper.",
  invite = "Got room, or do I have to ask twice?|Invite me. I'm not getting younger.", oom = "Out of mana. Figures.|No mana. In my day we had more.|I need to drink. Wait.", rez = "I'm dead. Wonderful.|Rez me. And hurry up about it.|Died again. This game.",
  welcome = "Yeah, yeah. You're welcome.|Don't mention it. Seriously.", omw = "I'm coming, I'm coming.|On my way. Don't rush me.|I'll get there when I get there.", wb = "Oh, you're back.|Welcome back. Took you long enough.|Look who decided to show up.",
  gl = "Good luck. You'll need it.|Try not to mess it up.|Luck. Hmph. In my day we used skill.", summon = "Summon me. I'm not walking all that way.|A summon. My knees can't take it.|Somebody summon me already." })
S("valley", { afk = "Okay I'll be right back, like, one sec!|Gotta go for a bit, bye!", back = "Okay I'm back!|I'm baaack!|Okay, back, what did I miss?", brb = "Be right back, don't do anything fun!|One sec, oh my gosh!|Back in, like, two seconds!",
  congrats = "Oh my gosh, congrats!|Yay, congrats! So happy for you!|That is so amazing, congrats!", good = "I'm, like, so good!|Totally good, thanks!", goodjob = "Oh my gosh, good job!|That was so good!|You guys, amazing job!",
  goodnight = "Night, you guys! Beauty sleep!|Okay, good night! Love you all!", howareyou = "How are you guys?|Oh my gosh, how are you?", hungry = "I'm literally starving!|Okay, I need food, like, now!",
  invite = "Can I come? Please please!|Invite me, you guys!", oom = "I'm, like, totally out of mana!|No mana, oh my gosh!|Wait, I need a drink!", rez = "Oh my gosh, I died!|Can someone rez me? Like, please?|I'm literally dead!",
  wait = "Wait, wait, wait!|Hold on, you guys!", welcome = "Aw, no problem!|Of course, babe!", omw = "Coming, coming!|On my way, you guys!|Okay, I'm literally on my way!",
  wb = "Oh my gosh, you're back!|Yay, welcome back!|You're back! I missed you!", gl = "Good luck, you guys!|You got this, babe!|Good luck! So nervous for you!",
  summon = "Can someone summon me? It's, like, so far!|Summon please! I'm not walking!|Summon me, you guys!" })
S("conspiracy", { afk = "Going dark for a bit. Don't look for me.|Away. If I'm not back, you know why.", back = "I'm back. Was I followed?|Back. Did anyone ask about me?|I'm back. They almost got me.",
  brb = "Back soon. Trust no one.|One sec, checking for bugs.|Be right back. Act natural.", congrats = "Congrats. They didn't want you to have that.|Nice. Suspiciously nice.|You earned it. Or did they let you?",
  good = "Fine. That's what I tell them, anyway.|Good. Too good. Makes you think.", goodjob = "Good job. Almost too good.|Nice work. They'll notice.|Well done. Now cover your tracks.",
  goodnight = "Going to sleep. One eye open.|Night. Unplug everything first.", howareyou = "How are you really? Blink twice.|You good? You'd tell me, right?", hungry = "I'm hungry. I only eat what I grow.|Need food. Nothing processed.",
  invite = "Invite me. I've seen things.|Got room? I know what's really going on.", oom = "Out of mana. Convenient, isn't it?|No mana. They drain it, you know.|I need to drink. Not the tap water.",
  rez = "I'm dead. That's what they wanted.|Rez me. They can't silence me.|Dead. Coincidence? No.", wait = "Wait. Did you hear that?|Hold on. Something's off.", welcome = "No problem. You didn't hear it from me.|Anytime. Stay awake.",
  omw = "On my way. Taking the back roads.|Coming. Don't say where over chat.|I'm heading over. Wasn't followed.", wb = "You're back. What did they ask you?|Welcome back. Glad they let you go.|Back already? Interesting.",
  gl = "Good luck. Trust no one.|Stay awake out there.|Good luck. It's rigged, but good luck.", summon = "Summon me. They're watching the roads.|I need a summon. Flight paths are tracked.|Pull me through. Quietly." })
S("announcer", { afk = "We'll be right back after this short break!|Stepping away from the booth, folks!", back = "AND WE'RE BACK!|Welcome back to the action, folks!|I'm back in the booth!",
  brb = "Stay tuned, folks, we'll be right back!|Don't touch that dial!|A quick timeout, folks!", congrats = "WHAT AN ACHIEVEMENT! Congratulations!|The crowd is on its feet! Congrats!|A well earned victory, folks!",
  good = "Feeling like a champion, folks!|Never better! What a day for it!", goodjob = "WHAT A PLAY!|Textbook execution, folks!|That's a highlight reel moment!",
  goodnight = "That's all for tonight, folks! Good night!|We're signing off! Good night, everybody!", howareyou = "How's everybody feeling out there tonight?|How are we doing, folks?", hungry = "Time for the halftime snack, folks!|I could go for a stadium hot dog!",
  invite = "Put me in, coach!|Room on the roster for one more?", rez = "I'M DOWN! Get the medic out here!|He's down, folks! Somebody help!|Get me back in the game!",
  welcome = "Happy to do it, folks!|That's what teammates are for!", omw = "AND HERE I COME!|On my way, folks, and making great time!|Charging down the field to you!",
  wb = "AND THEY'RE BACK IN THE GAME!|Welcome back, folks!|Look who's back on the field!", gl = "May the best team win!|Good luck out there, champ!|Leave it all on the field!",
  summon = "Requesting a substitution! Summon me in!|Get me on the field! Summon!|Call me up from the bench, folks!" })
