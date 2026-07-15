window.WIKI_DATA = {
  "items": [
    {
      "name": "Lumber Axe",
      "console_id": "lumberaxe",
      "category": "Tool",
      "status": "Tested",
      "purpose": "Cuts trees through the lumberjack resource.",
      "notes": "Search under Axe; the server ID is lumberaxe."
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
