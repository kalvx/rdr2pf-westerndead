
function esc(v){return String(v??"").replace(/[&<>"']/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"}[m]));}
function filterTable(inputId, tableId){
 const q=document.getElementById(inputId).value.toLowerCase();
 document.querySelectorAll(`#${tableId} tbody tr`).forEach(r=>r.style.display=r.innerText.toLowerCase().includes(q)?"":"none");
}


// RDR2PF_COMPENDIUM_SEARCH
(function(){
 const input=document.getElementById('frontierSearch'); if(!input)return;
 const pages=[
  ...[
  {
    "title": "Home",
    "section": "Main",
    "url": "../index.html"
  },
  {
    "title": "Frontier Search",
    "section": "Main",
    "url": "../database/search.html"
  },
  {
    "title": "News & Changelog",
    "section": "Main",
    "url": "../changelog.html"
  },
  {
    "title": "Introduction",
    "section": "Getting Started",
    "url": "../player/getting-started.html"
  },
  {
    "title": "Beginner Guide",
    "section": "Getting Started",
    "url": "../player/beginner-guide.html"
  },
  {
    "title": "Survival Basics",
    "section": "Getting Started",
    "url": "../player/survival-basics.html"
  },
  {
    "title": "Controls",
    "section": "Getting Started",
    "url": "../player/controls.html"
  },
  {
    "title": "FAQ",
    "section": "Getting Started",
    "url": "../player/faq.html"
  },
  {
    "title": "Character Progression",
    "section": "Character",
    "url": "../player/progression.html"
  },
  {
    "title": "Living Mastery",
    "section": "Character",
    "url": "../player/mastery.html"
  },
  {
    "title": "Jobs & Professions",
    "section": "Character",
    "url": "../player/jobs.html"
  },
  {
    "title": "Statistics",
    "section": "Character",
    "url": "../player/statistics.html"
  },
  {
    "title": "Titles",
    "section": "Character",
    "url": "../player/titles.html"
  },
  {
    "title": "Achievements",
    "section": "Character",
    "url": "../player/achievements.html"
  },
  {
    "title": "Reputation",
    "section": "Character",
    "url": "../player/reputation.html"
  },
  {
    "title": "World Guide",
    "section": "The Frontier",
    "url": "../world/index.html"
  },
  {
    "title": "Territories",
    "section": "The Frontier",
    "url": "../world/territories.html"
  },
  {
    "title": "Towns & Settlements",
    "section": "The Frontier",
    "url": "../world/towns.html"
  },
  {
    "title": "Locations",
    "section": "The Frontier",
    "url": "../world/locations.html"
  },
  {
    "title": "Merchants",
    "section": "The Frontier",
    "url": "../world/merchants.html"
  },
  {
    "title": "Travel",
    "section": "The Frontier",
    "url": "../world/travel.html"
  },
  {
    "title": "Safe Zones",
    "section": "The Frontier",
    "url": "../world/safe-zones.html"
  },
  {
    "title": "Camps",
    "section": "The Frontier",
    "url": "../world/camps.html"
  },
  {
    "title": "Factions",
    "section": "The Frontier",
    "url": "../admin/factions.html"
  },
  {
    "title": "Encounters",
    "section": "The Frontier",
    "url": "../admin/encounters.html"
  },
  {
    "title": "The Infected",
    "section": "Western Dead",
    "url": "../western-dead/index.html"
  },
  {
    "title": "Infected Types",
    "section": "Western Dead",
    "url": "../western-dead/infected-types.html"
  },
  {
    "title": "Infection Mechanics",
    "section": "Western Dead",
    "url": "../western-dead/infection.html"
  },
  {
    "title": "Hordes & Events",
    "section": "Western Dead",
    "url": "../western-dead/hordes.html"
  },
  {
    "title": "Survival Strategies",
    "section": "Western Dead",
    "url": "../western-dead/strategies.html"
  },
  {
    "title": "Profession Index",
    "section": "Professions",
    "url": "../professions/index.html"
  },
  {
    "title": "Cooking",
    "section": "Professions",
    "url": "../professions/cooking.html"
  },
  {
    "title": "Crafting",
    "section": "Professions",
    "url": "../professions/crafting.html"
  },
  {
    "title": "Hunting",
    "section": "Professions",
    "url": "../professions/hunting.html"
  },
  {
    "title": "Fishing",
    "section": "Professions",
    "url": "../professions/fishing.html"
  },
  {
    "title": "Farming",
    "section": "Professions",
    "url": "../professions/farming.html"
  },
  {
    "title": "Mining",
    "section": "Professions",
    "url": "../professions/mining.html"
  },
  {
    "title": "Lumberjack",
    "section": "Professions",
    "url": "../professions/lumberjack.html"
  },
  {
    "title": "Moonshiner",
    "section": "Professions",
    "url": "../professions/moonshiner.html"
  },
  {
    "title": "Trader",
    "section": "Professions",
    "url": "../professions/trader.html"
  },
  {
    "title": "Herbalist",
    "section": "Professions",
    "url": "../professions/herbalist.html"
  },
  {
    "title": "Database Home",
    "section": "Game Database",
    "url": "../database/index.html"
  },
  {
    "title": "Every Item A–Z",
    "section": "Game Database",
    "url": "../database/items.html"
  },
  {
    "title": "Recipes",
    "section": "Game Database",
    "url": "../database/recipes.html"
  },
  {
    "title": "Consumables",
    "section": "Game Database",
    "url": "../database/consumables.html"
  },
  {
    "title": "Food",
    "section": "Game Database",
    "url": "../database/food.html"
  },
  {
    "title": "Drinks",
    "section": "Game Database",
    "url": "../database/drinks.html"
  },
  {
    "title": "Herbs",
    "section": "Game Database",
    "url": "../database/herbs.html"
  },
  {
    "title": "Seeds",
    "section": "Game Database",
    "url": "../database/seeds.html"
  },
  {
    "title": "Plants",
    "section": "Game Database",
    "url": "../database/plants.html"
  },
  {
    "title": "Fish",
    "section": "Game Database",
    "url": "../database/fish.html"
  },
  {
    "title": "Animals",
    "section": "Game Database",
    "url": "../database/animals.html"
  },
  {
    "title": "Medicines",
    "section": "Game Database",
    "url": "../database/medicines.html"
  },
  {
    "title": "Materials",
    "section": "Game Database",
    "url": "../database/materials.html"
  },
  {
    "title": "Weapons",
    "section": "Game Database",
    "url": "../database/weapons.html"
  },
  {
    "title": "Ammunition",
    "section": "Game Database",
    "url": "../database/ammunition.html"
  },
  {
    "title": "Clothing",
    "section": "Game Database",
    "url": "../database/clothing.html"
  },
  {
    "title": "Valuables",
    "section": "Game Database",
    "url": "../database/valuables.html"
  },
  {
    "title": "Tools",
    "section": "Game Database",
    "url": "../database/tools.html"
  },
  {
    "title": "Equipment",
    "section": "Game Database",
    "url": "../database/equipment.html"
  },
  {
    "title": "Camp Items",
    "section": "Game Database",
    "url": "../database/camp-items.html"
  },
  {
    "title": "Farming Items",
    "section": "Game Database",
    "url": "../database/farming-items.html"
  },
  {
    "title": "Moonshine",
    "section": "Game Database",
    "url": "../database/moonshine.html"
  },
  {
    "title": "Economy Guide",
    "section": "Economy",
    "url": "../economy/index.html"
  },
  {
    "title": "Currency",
    "section": "Economy",
    "url": "../economy/currency.html"
  },
  {
    "title": "Trading",
    "section": "Economy",
    "url": "../economy/trading.html"
  },
  {
    "title": "Stores",
    "section": "Economy",
    "url": "../economy/stores.html"
  },
  {
    "title": "Banking",
    "section": "Economy",
    "url": "../economy/banking.html"
  },
  {
    "title": "Values & Prices",
    "section": "Economy",
    "url": "../economy/values.html"
  },
  {
    "title": "Admin Home",
    "section": "Administration",
    "url": "../admin/index.html"
  },
  {
    "title": "Item Database",
    "section": "Administration",
    "url": "../admin/items.html"
  },
  {
    "title": "Item Registry",
    "section": "Administration",
    "url": "../admin/item-registry.html"
  },
  {
    "title": "Item & Crafting Validation",
    "section": "Administration",
    "url": "../admin/item-validation.html"
  },
  {
    "title": "Server Commands",
    "section": "Administration",
    "url": "../admin/commands.html"
  },
  {
    "title": "Bind Command Reference",
    "section": "Administration",
    "url": "../admin/binds.html"
  },
  {
    "title": "Coordinates",
    "section": "Administration",
    "url": "../admin/coordinates.html"
  },
  {
    "title": "Resources",
    "section": "Administration",
    "url": "../admin/resources.html"
  },
  {
    "title": "SQL Database",
    "section": "Administration",
    "url": "../admin/sql.html"
  },
  {
    "title": "Known Bugs",
    "section": "Administration",
    "url": "../admin/bugs.html"
  },
  {
    "title": "Testing Log",
    "section": "Administration",
    "url": "../admin/testing-log.html"
  },
  {
    "title": "Development Log",
    "section": "Administration",
    "url": "../admin/devlog.html"
  },
  {
    "title": "Roadmap",
    "section": "Administration",
    "url": "../admin/roadmap.html"
  }
]
 ];

 const results=document.getElementById('searchResults'), summary=document.getElementById('searchSummary');
 function render(){const q=input.value.trim().toLowerCase();results.innerHTML='';if(!q){summary.textContent='Search the full Compendium index.';return;}const matches=pages.filter(x=>(x.title+' '+x.section+' '+x.url).toLowerCase().includes(q));summary.textContent=matches.length+' result'+(matches.length===1?'':'s')+' for “'+input.value.trim()+'”.';matches.slice(0,80).forEach(x=>{const a=document.createElement('a');a.className='search-result';a.href=x.url;a.innerHTML='<strong>'+esc(x.title)+'</strong><div class="sub">'+esc(x.section)+'</div>';results.appendChild(a);});}
 input.addEventListener('input',render);const q=new URLSearchParams(location.search).get('q');if(q){input.value=q;render();input.focus();}
})();
