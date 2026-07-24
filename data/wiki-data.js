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