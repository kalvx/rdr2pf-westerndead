window.WIKI_DATA = {
  "items": [
    {
      "name": "Lumber Axe",
      "console_id": "hatchet",
      "category": "Tool",
      "status": "Tested",
      "purpose": "Required inventory tool for the lumberjack resource.",
      "notes": "Confirmed in the current lumberjack config: Config.Axe = hatchet."
    },
    {
      "name": "Pickaxe",
      "console_id": "pickaxe",
      "category": "Tool",
      "status": "Tested",
      "purpose": "Mining tool.",
      "notes": "Confirmed working."
    },
    {
      "name": "Knife",
      "console_id": "WEAPON_MELEE_KNIFE",
      "category": "Weapon",
      "status": "Tested",
      "purpose": "Melee weapon and skinning tool.",
      "notes": "Purchased and used successfully."
    },
    {
      "name": "Bolt Action Rifle",
      "console_id": "WEAPON_RIFLE_BOLTACTION",
      "category": "Weapon",
      "status": "Tested",
      "purpose": "Long-range rifle.",
      "notes": "Purchased, equipped, and fired."
    },
    {
      "name": "Normal Rifle Ammo",
      "console_id": "ammoriflenormal",
      "category": "Ammunition",
      "status": "Tested",
      "purpose": "Normal rifle rounds for the Bolt Action Rifle.",
      "notes": "Item limit observed as 10."
    }
  ],
  "masteries": [
    {
      "title": "Cook",
      "tracked": "Meals cooked and meal quality.",
      "effect": "Food becomes more effective and lasts longer, allowing longer travel without needing another meal."
    },
    {
      "title": "Hunter",
      "tracked": "Animals killed, skinned, and harvested.",
      "effect": "Improved hunting rewards and future tracking or harvesting perks."
    },
    {
      "title": "Peddler",
      "tracked": "Pelts, wagons, and goods sold or transported.",
      "effect": "Future trading and merchant benefits."
    },
    {
      "title": "Exterminator",
      "tracked": "Infected killed and outbreaks contained.",
      "effect": "Future infected-related rewards and recognition."
    },
    {
      "title": "Crook",
      "tracked": "Theft, burglary, stolen property, and lockpicking.",
      "effect": "Crime-focused perks balanced by distrust."
    },
    {
      "title": "Murderer",
      "tracked": "Excessive innocent NPC and player kills.",
      "effect": "Primarily a reputation consequence; the frontier recognizes the character as dangerous."
    }
  ],
  "commands": [
    {
      "name": "Open Admin Menu",
      "command": "adminMenu",
      "where": "F8 console",
      "notes": "Use /adminMenu in chat. Page Down is configured as the menu key."
    },
    {
      "name": "Restart Admin",
      "command": "restart vorp_admin",
      "where": "Server console",
      "notes": ""
    },
    {
      "name": "Restart Stables",
      "command": "restart vorp_stables",
      "where": "Server console",
      "notes": ""
    },
    {
      "name": "Restart Hunting",
      "command": "restart vorp_hunting",
      "where": "Server console",
      "notes": ""
    },
    {
      "name": "Correct Server Profile",
      "command": "+set serverProfile default",
      "where": "FXServer startup",
      "notes": "Use the corrected BAT so txAdmin loads."
    },
    {
      "name": "txAdmin Portal",
      "command": "http://localhost:40120",
      "where": "Web browser",
      "notes": "Available when launched through the txAdmin profile."
    }
  ],
  "coordinates": [
    {
      "name": "Central Heartlands",
      "coords": "432 642 116",
      "status": "Tested"
    },
    {
      "name": "Heartland Overflow",
      "coords": "702 365 111",
      "status": "Reference"
    },
    {
      "name": "Emerald Ranch",
      "coords": "1417 320 89",
      "status": "Reference"
    },
    {
      "name": "Horseshoe Overlook",
      "coords": "-140 640 113",
      "status": "Reference"
    },
    {
      "name": "Valentine",
      "coords": "-283 804 119",
      "status": "Reference"
    },
    {
      "name": "Rhodes Gunsmith",
      "coords": "1323.70 -1323.60 77.89",
      "status": "Tested"
    },
    {
      "name": "Saint Denis Gunsmith",
      "coords": "2716.87 -1285.44 49.63",
      "status": "Tested"
    }
  ],
  "bugs": [
    {
      "name": "Waypoint teleport / mixed server launch",
      "status": "Resolved",
      "notes": "Plain FXServer startup bypassed txAdmin. BAT corrected to use serverProfile default."
    },
    {
      "name": "Invisible or missing horse",
      "status": "Resolved / Monitor",
      "notes": "OneSync enabled and horse model converted with GetHashKey. Correct launch path matters."
    },
    {
      "name": "Random login location",
      "status": "Resolved / Monitor",
      "notes": "Coordinate saving added and interval reduced to 10 seconds."
    },
    {
      "name": "Bow reload",
      "status": "Known Issue",
      "notes": "Arrows can load, but reloading is sometimes inconsistent."
    },
    {
      "name": "Animal skinning",
      "status": "Investigating",
      "notes": "Some animals work. Bison, Whitetail Buck, and some Wild Turkey cases have failed despite config entries."
    }
  ]
};

/* RDR2PF_PAUSE_MENU_BUGS_20260714 */
WIKI_DATA.bugs = WIKI_DATA.bugs || [];

[
    {
        name: "Inventory money drop callback",
        status: "Investigating",
        notes: "Dropping money can trigger a DropItemMoney callback error. Reproduced with decimal and whole-dollar amounts. A failed callback may leave the inventory NUI unusable until reconnect."
    },
    {
        name: "Weapon visibility after resource restart",
        status: "Monitoring",
        notes: "Restarting vorp_core or related resources may temporarily remove equipped bow and gun models from the character's back. Reconnecting restored the weapons."
    },
    {
        name: "Custom menu blocked by stuck NUI",
        status: "Investigating",
        notes: "When another NUI such as inventory becomes stuck, custom pause-menu interactions may fail. The Open Rockstar Menu fallback remains available as an emergency recovery path."
    },
    {
        name: "One-time ten dollar balance adjustment",
        status: "Monitoring",
        notes: "After one reconnect, a saved $4200.00 balance appeared as $4210.00. A later reconnect remained at $4210.00, so this does not currently appear to repeat every login."
    }
].forEach(function (bug) {
    if (!WIKI_DATA.bugs.some(function (existing) {
        return existing.name === bug.name;
    })) {
        WIKI_DATA.bugs.push(bug);
    }
});

/* RDR2PF_FACTIONS_DATA_20260718 */
WIKI_DATA.factions = WIKI_DATA.factions || [];
WIKI_DATA.encounters = WIKI_DATA.encounters || [];

WIKI_DATA.factions.push({
    name: "Los Cuervos",
    threat: "High",
    population: 18,
    weapon: "WEAPON_UNARMED",
    coordinates: {
        mainCamp: "-5450.00 -3650.00 -15.00",
        surface: "-5415.88 -3643.23 -22.17",
        bunker: "-5395.77 -3666.90 -25.01"
    },
    pedModels: [
        { model: "G_M_M_UniBanditos_01", count: 7 },
        { model: "G_M_M_UniCriminals_01", count: 4 },
        { model: "G_M_M_UniCriminals_02", count: 2 },
        { model: "G_M_M_UniDuster_01", count: 3 },
        { model: "A_M_M_Rancher_01", count: 1 },
        { model: "G_M_M_UniMountainMen_01", count: 1 }
    ]
});

WIKI_DATA.encounters.push(
    {
        name: "Los Cuervos Complex",
        type: "Faction Camp",
        threat: "High",
        count: 18,
        coords: "-5450.00 -3650.00 -15.00",
        status: "Active"
    },
    {
        name: "Zombie Horde Alpha",
        type: "Zombie Horde",
        threat: "High",
        count: 20,
        coords: "2464.84 112.36 72.54",
        status: "Active Test"
    }
);

[
    { name: "Los Cuervos — Main Camp", coords: "-5450.00 -3650.00 -15.00", status: "Active" },
    { name: "Los Cuervos — Surface Position", coords: "-5415.88 -3643.23 -22.17", status: "Active" },
    { name: "Los Cuervos — Bunker Position", coords: "-5395.77 -3666.90 -25.01", status: "Active" },
    { name: "Zombie Horde Alpha", coords: "2464.84 112.36 72.54", status: "Active Test" }
].forEach(function (entry) {
    if (!WIKI_DATA.coordinates.some(function (existing) { return existing.name === entry.name; })) {
        WIKI_DATA.coordinates.push(entry);
    }
});
/* RDR2PF_AUGUST_2026_COMPENDIUM */
WIKI_DATA.coordinates = WIKI_DATA.coordinates || [];
if (!WIKI_DATA.coordinates.some(x => x.name === "Kamassa River Prospecting Reach")) WIKI_DATA.coordinates.push({name:"Kamassa River Prospecting Reach",coords:"2330.23, 1256.85, 83.47",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Upper Montana River Prospecting Reach")) WIKI_DATA.coordinates.push({name:"Upper Montana River Prospecting Reach",coords:"-1536.90, -1055.01, 65.58",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Lower Montana River Prospecting Reach")) WIKI_DATA.coordinates.push({name:"Lower Montana River Prospecting Reach",coords:"-1529.96, -2204.98, 41.25",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "San Luis River Prospecting Reach \u2014 East")) WIKI_DATA.coordinates.push({name:"San Luis River Prospecting Reach \u2014 East",coords:"-3546.98, -3893.04, -22.97",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "San Luis River Prospecting Reach \u2014 West")) WIKI_DATA.coordinates.push({name:"San Luis River Prospecting Reach \u2014 West",coords:"-3996.84, -3915.49, -24.92",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Dakota River Prospecting Reach \u2014 West")) WIKI_DATA.coordinates.push({name:"Dakota River Prospecting Reach \u2014 West",coords:"-698.91, 140.28, 41.16",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Dakota River Prospecting Reach \u2014 East")) WIKI_DATA.coordinates.push({name:"Dakota River Prospecting Reach \u2014 East",coords:"-496.75, 169.58, 41.47",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Armadillo")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Armadillo",coords:"-3624.46, -2596.84, -13.79",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Tumbleweed")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Tumbleweed",coords:"-5521.65, -2952.39, -1.60",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Blackwater")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Blackwater",coords:"-836.44, -1384.64, 43.62",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Rhodes")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Rhodes",coords:"1394.90, -1329.97, 77.76",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Saint Denis")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Saint Denis",coords:"2618.62, -1262.87, 52.55",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Strawberry")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Strawberry",coords:"-1758.81, -397.06, 155.97",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Valentine")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Valentine",coords:"-336.24, 758.34, 116.79",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Annesburg")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Annesburg",coords:"2968.39, 1405.99, 44.14",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Van Horn Trading Post")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Van Horn Trading Post",coords:"2951.38, 578.30, 44.55",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Wayfarer Post \u2014 Grizzlies / Wapiti")) WIKI_DATA.coordinates.push({name:"Wayfarer Post \u2014 Grizzlies / Wapiti",coords:"452.43, 2239.34, 248.13",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Blackwater")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Blackwater",coords:"-875.0, -1328.0, 44.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Strawberry")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Strawberry",coords:"-1801.0, -373.0, 162.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Valentine")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Valentine",coords:"-283.0, 806.0, 119.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Rhodes")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Rhodes",coords:"1232.0, -1299.0, 76.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Saint Denis")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Saint Denis",coords:"2634.0, -1225.0, 53.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Annesburg")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Annesburg",coords:"2935.0, 1282.0, 44.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Van Horn")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Van Horn",coords:"2983.0, 571.0, 44.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Armadillo")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Armadillo",coords:"-3665.0, -2612.0, -14.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Infected Center \u2014 Tumbleweed")) WIKI_DATA.coordinates.push({name:"Infected Center \u2014 Tumbleweed",coords:"-5515.0, -2930.0, -2.0",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Van Horn Assay Office")) WIKI_DATA.coordinates.push({name:"Van Horn Assay Office",coords:"2936.05, 560.65, 43.93",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Van Horn Dog Trainer")) WIKI_DATA.coordinates.push({name:"Van Horn Dog Trainer",coords:"2942.60, 477.38, 47.95",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Valentine Wayfarer Permit NPC")) WIKI_DATA.coordinates.push({name:"Valentine Wayfarer Permit NPC",coords:"-353.76, 775.63, 116.12",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Valentine Corral Fight Start")) WIKI_DATA.coordinates.push({name:"Valentine Corral Fight Start",coords:"-367.16, 787.98, 116.16",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Valentine Replenishable Water Barrel")) WIKI_DATA.coordinates.push({name:"Valentine Replenishable Water Barrel",coords:"-366.39, 799.26, 115.21",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Blackwater Auction House")) WIKI_DATA.coordinates.push({name:"Blackwater Auction House",coords:"-798.90, -1205.30, 43.29",status:"Active"});
if (!WIKI_DATA.coordinates.some(x => x.name === "Blackwater Gunslinger Shootout")) WIKI_DATA.coordinates.push({name:"Blackwater Gunslinger Shootout",coords:"-852.40, -1186.42, 43.50",status:"Active"});
WIKI_DATA.bugs = WIKI_DATA.bugs || [];
if (!WIKI_DATA.bugs.some(x => x.name === "Gold panning ambient hand movement")) WIKI_DATA.bugs.push({name:"Gold panning ambient hand movement",status:"Known Cosmetic Issue",notes:"The crouch-inspect scenario can occasionally scratch/swat, moving the attached pan with the hand. Weapon holstering is fixed; pan offset was lowered; direct animation replacement remains future polish."});
if (!WIKI_DATA.bugs.some(x => x.name === "Gold panning weapon clipping")) WIKI_DATA.bugs.push({name:"Gold panning weapon clipping",status:"Resolved",notes:"Panning now clears active tasks, forces WEAPON_UNARMED, waits briefly, then starts the panning scenario before attaching the pan."});
if (!WIKI_DATA.bugs.some(x => x.name === "Prospecting and infected music overlap")) WIKI_DATA.bugs.push({name:"Prospecting and infected music overlap",status:"Resolved",notes:"Outbreak music is local to the active infected-town radius and takes priority over prospecting music."});
if (!WIKI_DATA.bugs.some(x => x.name === "Gold Rush test command format crash")) WIKI_DATA.bugs.push({name:"Gold Rush test command format crash",status:"Resolved",notes:"The test command announcement path was repaired after the obsolete percentage-format call caused a nil format error."});
if (!WIKI_DATA.bugs.some(x => x.name === "Gold Dust carry-weight pressure")) WIKI_DATA.bugs.push({name:"Gold Dust carry-weight pressure",status:"Resolved",notes:"Gold Dust carry behavior was adjusted so prospecting is not blocked by an impractical dust-weight burden; assay conversion is now 250 dust per Gold Bar."});
if (!WIKI_DATA.bugs.some(x => x.name === "Wayfarer permit verification")) WIKI_DATA.bugs.push({name:"Wayfarer permit verification",status:"Resolved",notes:"Valentine permit NPC includes a Verify Wayfarer Permit action to refresh travel-post access."});
if (!WIKI_DATA.bugs.some(x => x.name === "Inventory persistence after live resource changes")) WIKI_DATA.bugs.push({name:"Inventory persistence after live resource changes",status:"Monitor",notes:"Some inventory/UI states may require a full reconnect after live resource restarts; use normal save-and-exit flow before maintenance when possible."});
