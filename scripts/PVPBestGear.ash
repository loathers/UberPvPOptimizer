script "PVPBestGear.ash"
//notify "Zekaonar";
notify "UberFerret";	//What? I'm nosey
import <zlib.ash>;

// Hacked for season 16 by Crowther
// Hacked for season 18 by Crowther
// Further Modified for 18 and beyond by UberFerret


/*** 

PVPBestGear.ash by Zekaonar. Version #4

This script will help you optimize your gear for the PVP mini-games: Laconic Dresser, Verbosity Demonstration,
Showing Initiative, The Egg Hunt, Meat Lover, Broad Resistance Contest, Lightest Load and Letter of the Moment.  There 
are options to buy cheap mall gear that is better than what you have, and give a comprehensive list of the best gear 
in-game with wiki links to research how to acquire it.  The script will check which mini-games are active and will 
retrieve the letter of the moment on each run.

Features:

* Auto determine current mini-games and letter of the moment
* Configurable weighting to optimize for particular mini-games
* Familiars & familiar-gear considered in calculations
* Buddy Bjorn & Crown of Thrones supported with optimal familiar bonus from enthroning/bjornifying			~incomplete for newer minis
* Dual wielding 1-handers with Double-Fisted Skull Smashing

TODO: set bonuses, hidden synergy and foldables(foldables will appear in lists, but script won't fold for you),
also Disimbodied Hand & Mad Hatrack


*** Gear Weighting ***

Verbosity or Laconic is almost always a minigame, so the basis of all gear valuation will be done in letters 
towards your goal.  1 Letter = 1 point.  For example adding more item drop may cost you more letters.  
More examples given below next to each mini-game weighting.

Notes: 
S is more common than V and so you may have to adjust weighting depending on the letter of the day.
If you are swimming in premium item drop gear, weight it down.  A clanmate had 3 Jek belts, and doesn't 
really need to try hard to win item drop contests.

UberFerret Changes:
* corrected equipping non class items
* corrected limited item equip(wolf whistle) trying to equip twice and thus leaving an empty offhand
* added list value modification function to limit max mall price of displayed items
* Added a max price display so it doesn't tell you that that 90 million meat thing is your best choice. Optional
* future proofed pvp by adding all necessary code for all elements, fill in their name and it is ready to go.
*/

/***** CONFIG *****/
boolean showAllItems = true;			// When false, only shows items you own or within mall budget
boolean buyGear = false;				// Will auto-buy from mall if below threshold price and better than what you have
int maxPrice = 1000;					// Max price that will be considered to auto buy gear if you don't have it
int topItems = 10;						// Number of items to display in the output lists
boolean displayUnownedBling = false;	// Set to false to prevent the item outputs from showing items worth [bling] or more
int bling = 10000000;					// define amount for value limiter to show 10,000,000 default
float letterMomentWeight = 6.0;			// Example: An "S" is worth 3 letters in laconic/verbosity
float nextLetterWeight = 0.1;			// Example: allow a future letter to be a tie-breaker
float itemDropWeight = (4.0/5.0);		// 4 per 5% drop Example: +8% items is worth 10 letters in laconic/verbosity
float meatDropWeight = (3.0/5.0);		// 3 per 5% drop Example: +25% meat is worth 15 letters in laconic/verbosity
float boozeDropWeight = (3.0/5.0);		// 3 per 5% drop Example: +20% booze is worth 12 letters in laconic/verbosity
float initiativeWeight = (4.0/10.0);	// 4 per 10% initiative Example: +20% initiative is worth 8 letters in laconic/verbosity
float combatWeight = (15.0/5.0);		// 4 per 10% combat Example: +20% combat is worth 8 letters in laconic/verbosity
float resistanceWeight = 6.0;			// Example: +1 Resistance to all elements equals 6 letters of laconic/verbosity
float powerWeight = (5.0/10.0);			// Example: 5 points for -10 points of power towards Lightest Load vs average(110) power in slot.  
float damageWeight = 4.0/10.0;			// Example: 4 points for 10 points of damage.
float negativeClassWeight = -5;			// Off class items are given a 0, adjust as you see fit.
/*****************/




boolean laconic = false;
boolean verbosity = false;
boolean egghunt = false;
boolean meatlover = false;
boolean moarbooze = false;
boolean showingInitiative = false;
boolean peaceonearth = false;
boolean broadResistance = false;
boolean coldResistance = false;
boolean hotResistance = false;
boolean sleazeResistance = false;
boolean stenchResistance = false;
boolean spookyResistance = false;
boolean lightestLoad = false;
boolean letterCheck = false;
boolean coldDamage = false;
boolean hotDamage = false;
boolean sleazeDamage = false;
boolean stenchDamage = false;
boolean spookyDamage = false;
string letterToCheck;
string nextLetter;
boolean dualWield = false;
familiar bestFamiliar = $familiar[none];
familiar bjornFam;
familiar throneFam;
item bestWeapon;
item secondWeapon;
item bestOffhand;
item [string] [int] gear;

/**steal veracity's example function**/
class class_modifier( item it )
{
    return to_class( string_modifier( it, "Class" ) );
}

/** Count the letter of the moment in the gear names */
int lettersinname(item gear, string letter) {
	if (gear == $item[none])
		return 0;
	matcher entity = create_matcher("&[^ ;]+;", gear);
	string output = replace_all(entity,"");
	matcher htmltag = create_matcher("\<[^\>]*\>",output);
	output = replace_all(htmltag,"");
	int lettercount=0;
	for i from 0 to length(output)-1 {
		if (char_at(output,i)==letter) lettercount+=1;  
	}
	return lettercount;
}


/** Improved version of length() that deals with HTML entities, tags and counts them like pvp info does */
int nameLength(item i) {
	if (i == $item[none] && laconic)
		return 23;
	else if (i == $item[none] && verbosity)
		return 0;
	else if (laconic) {
		return length(i);
	} else {
		matcher entity = create_matcher("&[^ ;]+;", i);
		string output = replace_all(entity,"X");
		matcher htmltag = create_matcher("\<[^\>]*\>",output);
		output = replace_all(htmltag,"");
		return length(output);
	}
}

/** check if you have the item, or it's in budget (without equipping) */
boolean canGet(item i) {
	return ((can_interact() && buyGear && maxPrice >= historical_price(i) && historical_price(i) != 0) 
		|| available_amount(i)-equipped_amount(i) > 0);
}

boolean isChefStaff(item i) {
	foreach staff in $items[Staff of the Headmaster's Victuals, Staff of the November Jack-O-Lantern, Spooky Putty snake, Staff of Queso Escusado, Staff of the Lunch Lady, Staff of the Woodfire, Staff of the Cozy Fish, Staff of Simmering Hatred, The Necbromancer's Wizard Staff] {
		if (i == staff) 
			return true;		
	}
	return false;
}

boolean canEquip(item i) {
	if (can_equip(i) && (!isChefStaff(i) || my_class() == $class[Avatar of Jarlsberg] || have_skill($skill[Spirit of Rigatoni]))) {
		return true;
	} else {
		return false;
	}
}
		

/** generate a wiki link */
string link(String name) {
	string name2 = replace_string(name, " ", "_");
	name2 = replace_string(name2, "&quot;", "%5C%22"); 
	return '<a href="http://kol.coldfront.net/thekolwiki/index.php/'+name2+'">'+name+'</a>';
}


/** version of numeric modifier that filters out conditional bonuses like zone restrictions: The Sea ***/
float numeric_modifier2(item i, string modifier) {
	if (numeric_modifier(i,modifier) != 0) {
		string mods = string_modifier(i,"Modifiers");
		class cl = class_modifier( i );
		string[int] arr = split_string(mods,",");
		/**check if the item is even for my class if not don't even consider it **/
		if (cl != $class[none] && cl != my_class())
				return negativeClassWeight;
		for j from 0 to Count(arr)-1 by 1 {
			if (arr[j].index_of(modifier) !=-1) {
				if (arr[j].index_of("The Sea") != -1 || arr[j].index_of("Unarmed") != -1 || arr[j].index_of("sporadic") != -1)
					return 0;
				else return numeric_modifier(i,modifier);
			}
		}		
	}
	return 0;
}


/** Version of bjornify that records fam set, and doesn't steal from other locations */
boolean bjornify_familiar2(familiar f) {
	if (f != bestFamiliar && f != throneFam) {
		bjornFam = f;
		bjornify_familiar(f);		
		print_html("Placing " + f + " into Buddy Bjorn.");
		return true;
	}
	return false;
}


/** Version of enthrone that records fam set and doesn't steal from other locations */
boolean enthrone_familiar2(familiar f) {
	if (f != bestFamiliar) {
		throneFam = f;
		enthrone_familiar(f);		
		print_html("Placing " + f + " into Crown of Thrones.");
		return true;
	}
	return false;
}


/** function for calculating the value of a item based off the mini-game weighting */
float valuation(item i) {
	float value = 0;
	if (laconic)
		value = 23 - nameLength(i);
	else if (verbosity)
		value = nameLength(i);
		
	if (letterCheck) {
		value += lettersinname(i,letterToCheck)*letterMomentWeight;
		value += lettersinname(i,nextLetter)*nextLetterWeight;
	}
		
	if (egghunt)
		value += numeric_modifier2(i,"Item Drop")*itemDropWeight;
		
	if (meatlover)
		value += numeric_modifier2(i,"Meat Drop")*meatDropWeight;

	if (moarbooze)
		value += numeric_modifier2(i,"Booze Drop")*boozeDropWeight;

	if (showingInitiative)
		value += numeric_modifier2(i,"Initiative")*initiativeWeight;
		
	if (peaceonearth)
		value += numeric_modifier2(i,"Combat Rate")*combatWeight;
		
	if (broadResistance)
		value += min(numeric_modifier2(i,"Cold Resistance"),min(numeric_modifier2(i,"Hot Resistance"),
			min(numeric_modifier2(i,"Spooky Resistance"),min(numeric_modifier2(i,"Sleaze Resistance"),
			numeric_modifier2(i,"Stench Resistance")))))*resistanceWeight;

	if (coldResistance)
		value += numeric_modifier2(i,"Cold Resistance")*resistanceWeight;

	if (hotResistance)
		value += numeric_modifier2(i,"Hot Resistance")*resistanceWeight;
		
	if (sleazeResistance)
		value += numeric_modifier2(i,"Sleaze Resistance")*resistanceWeight;
		
	if (stenchResistance)
		value += numeric_modifier2(i,"Stench Resistance")*resistanceWeight;
		
	if (spookyResistance)
		value += numeric_modifier2(i,"Spooky Resistance")*resistanceWeight;

	if (coldDamage) {
		value += numeric_modifier2(i,"Cold Damage")*damageWeight+numeric_modifier2(i,"Cold Spell Damage")*damageWeight;
	}
	
	if (hotDamage) {
		value += numeric_modifier2(i,"Hot Damage")*damageWeight+numeric_modifier2(i,"Hot Spell Damage")*damageWeight;
	}
	
	if (sleazeDamage) {
		value += numeric_modifier2(i,"Sleaze Damage")*damageWeight+numeric_modifier2(i,"Sleaze Spell Damage")*damageWeight;
	}
	
	if (stenchDamage) {
		value += numeric_modifier2(i,"Stench Damage")*damageWeight+numeric_modifier2(i,"Stench Spell Damage")*damageWeight;
	}
	
	if (spookyDamage) {
		value += numeric_modifier2(i,"Spooky Damage")*damageWeight+numeric_modifier2(i,"Spooky Spell Damage")*damageWeight;
	}

	if (lightestLoad) {
		switch (i.to_slot()) {
		    case $slot[hat]:
		    case $slot[shirt]:
		    case $slot[pants]:
			value += (110-get_power(i))*powerWeight;
		}
	}
		
	// Throne/Bjorn familiar bonus value handling
	if ((i == $item[Buddy Bjorn] || i == $item[Crown of Thrones]) && my_class() != $class[Avatar of Sneaky Pete]) {
		if (egghunt) {
			if (have_familiar($familiar[Li'l Xenomorph]) || have_familiar($familiar[Feral Kobold]))
				value += 15.0*itemDropWeight;
			else if (have_familiar($familiar[Reassembled Blackbird]) || have_familiar($familiar[Reconstituted Crow])
				|| have_familiar($familiar[Oily Woim])) {
				value += 10.0*itemDropWeight;
			}
		}

		if (meatlover) {
			if (have_familiar($familiar[Hobo Monkey]) || have_familiar($familiar[Knob Goblin Organ Grinder])
				|| have_familiar($familiar[Happy Medium]))
				value += 25.0*meatDropWeight;
			else if (have_familiar($familiar[Leprechaun]) || have_familiar($familiar[Grouper Groupie])) {
				value += 20.0*meatDropWeight;
			}		
		}

		if (showingInitiative) {			
			if (have_familiar($familiar[Cuddlefish]) || have_familiar($familiar[Levitating Potato]))
				value += 20.0*initiativeWeight;				
		}		
		
		if (peaceonearth) {			
			if (have_familiar($familiar[Jumpsuited Hound Dog]))
				value -= 5.0*combatWeight;				
		}		
		
		if (broadResistance || coldResistance || stenchResistance) {
			if (have_familiar($familiar[Bulky Buddy Box]) || have_familiar($familiar[Exotic Parrot])
			|| have_familiar($familiar[Holiday Log]) || have_familiar($familiar[Pet Rock])
			|| have_familiar($familiar[Toothsome Rock]))
				value += 2.0*resistanceWeight;				
		}
	}		
	return value;
}

/** function for calculating the value of a familiar depending on the mini-game, uses default familiar gear, generic familiar gear considered later */
float valuationFamiliar(familiar f, float bonusWeight, item fequip) {
	if (fequip == $item[none])
		fequip = familiar_equipment(f);
	if (fequip == $item[none]) {
		// special case familiar gear
		//print_html("No default gear: " + link(f));
		// pet-rock types have 2 options
		if (f == $familiar[Bulky Buddy Box] || f== $familiar[Holiday Log] || f == $familiar[Pet Rock]
			|| f == $familiar[Toothsome Rock]) {
			 if (valuation($item[pet rock &quot;Groucho&quot; disguise]) > valuation($item[pet rock &quot;Snooty&quot; disguise]))
			 	fequip = $item[pet rock &quot;Groucho&quot; disguise];
			 else 
			 	fequip = $item[pet rock &quot;Snooty&quot; disguise];
		} else if (f == $familiar[Reagnimated Gnome]) {	
			float maxV = 0;
			foreach i in $items[gnomish swimmer's ears, gnomish coal miner's lung, 
				gnomish tennis elbow, gnomish housemaid's kgnee, gnomish athlete's foot] {
				if (valuation(i) > maxV) {
					fequip = i;
					maxV = valuation(i);
				}
			}
		}
	}
	return valuation(fequip);
}


/** version that combines 2 items for 2hand compared to 1hand + offhand or dual 1hand.
Not used atm, 2hand gets -23 penality in Laconic for empty offhand, need to test Verbose */
float valuation(item i, item i2) {
	float value = 0;
	if (laconic)
		value = 23 - nameLength(i) - nameLength(i2);
	else if (verbosity)
		value = nameLength(i) + nameLength(i2);
		
	if (letterCheck)
		value += (lettersinname(i,letterToCheck) + lettersinname(i2,letterToCheck))*letterMomentWeight;
		
	if (egghunt)
		value += (numeric_modifier2(i,"Item Drop")+numeric_modifier2(i2,"Item Drop"))*itemDropWeight;
		
	if (meatlover)
		value += (numeric_modifier2(i,"Meat Drop")+numeric_modifier2(i2,"Meat Drop"))*meatDropWeight;
		
	if (moarbooze)
		value += (numeric_modifier2(i,"Booze Drop")+numeric_modifier2(i2,"Booze Drop"))*boozeDropWeight;
		
	if (showingInitiative)
		value += (numeric_modifier2(i,"Initiative")+numeric_modifier2(i2,"Initiative"))*initiativeWeight;
		

	if (peaceonearth)
		value += (numeric_modifier2(i,"Combat Rate")+numeric_modifier2(i2,"Combat Rate"))*combatWeight;
		

	if (broadResistance) {
		value += min(numeric_modifier2(i,"Cold Resistance"),min(numeric_modifier2(i,"Hot Resistance"),
			min(numeric_modifier2(i,"Spooky Resistance"),min(numeric_modifier2(i,"Sleaze Resistance"),
			numeric_modifier2(i,"Stench Resistance")))))*resistanceWeight
			
			+ min(numeric_modifier2(i2,"Cold Resistance"),min(numeric_modifier2(i2,"Hot Resistance"),
			min(numeric_modifier2(i2,"Spooky Resistance"),min(numeric_modifier2(i2,"Sleaze Resistance"),
			numeric_modifier2(i2,"Stench Resistance")))))*resistanceWeight;
	}	

	if (coldResistance)
		value += numeric_modifier2(i,"Cold Resistance")*resistanceWeight;

	if (hotResistance)
		value += numeric_modifier2(i,"Hot Resistance")*resistanceWeight;
		
	if (sleazeResistance)
		value += numeric_modifier2(i,"Sleaze Resistance")*resistanceWeight;
		
	if (stenchResistance)
		value += numeric_modifier2(i,"Stench Resistance")*resistanceWeight;
		
	if (spookyResistance)
		value += numeric_modifier2(i,"Spooky Resistance")*resistanceWeight;

	if (coldDamage) {
		value += numeric_modifier2(i,"Cold Damage")*damageWeight+numeric_modifier2(i,"Cold Spell Damage")*damageWeight;
	}
	
	if (hotDamage) {
		value += numeric_modifier2(i,"Hot Damage")*damageWeight+numeric_modifier2(i,"Hot Spell Damage")*damageWeight;
	}
	
	if (sleazeDamage) {
		value += numeric_modifier2(i,"Sleaze Damage")*damageWeight+numeric_modifier2(i,"Sleaze Spell Damage")*damageWeight;
	}
	
	if (stenchDamage) {
		value += numeric_modifier2(i,"Stench Damage")*damageWeight+numeric_modifier2(i,"Stench Spell Damage")*damageWeight;
	}
	
	if (spookyDamage) {
		value += numeric_modifier2(i,"Spooky Damage")*damageWeight+numeric_modifier2(i,"Spooky Spell Damage")*damageWeight;
	}


	return value;
}


/** equips gear, but also acquires it from the mall if it is under budget */
boolean gearup(slot s, item i) {
	if(i == $item[none]) 
		return false;
	//print_html(i + " " + available_amount(i) + " " + equipped_amount(i));	
	if ((available_amount(i)-equipped_amount(i)) <= 0 && can_interact() 
			&& buyGear && maxPrice >= historical_price(i) && historical_price(i) != 0)
		buy(1, i, maxPrice);
		
	if (available_amount(i)-equipped_amount(i) > 0) {
	    if(!(get_inventory() contains i)) {
			boolean raidCloset= get_property("autoSatisfyWithCloset").to_boolean() && closet_amount(i)>=1;
			if(raidCloset) {
				take_closet( 1, i );
			}
	    }
	    return equip(s, i);
	}
	else 
	    return false;
}


/** pretty print item details related to the active minigames */
string gearString(item i) {
	string gearString = link(i) + " ";
	if (to_slot(i) == $slot[familiar] && bestFamiliar != $familiar[none]) 
		gearString += round(valuationFamiliar(bestFamiliar,0,i));
	else
		gearString += valuation(i);
	if (laconic || verbosity)
		gearString += ", " + nameLength(i) + " chars";
	if (letterCheck && lettersinname(i,letterToCheck) > 0)
		gearString += ", " + lettersinname(i,letterToCheck) + " letter " + letterToCheck;
	if (egghunt && numeric_modifier2(i,"Item Drop") > 0)
		gearString += ", +" + numeric_modifier2(i,"Item Drop") + "% Item Drop";
	if (meatlover && numeric_modifier2(i,"Meat Drop") > 0)
		gearString += ", +" + numeric_modifier2(i,"Meat Drop") + "% Meat Drop";
	if (moarbooze && numeric_modifier2(i,"Booze Drop") > 0)
		gearString += ", +" + numeric_modifier2(i,"Booze Drop") + "% Booze Drop";
	if (showingInitiative && numeric_modifier2(i,"Initiative") > 0)
		gearString += ", +" + numeric_modifier2(i,"Initiative") + "% Initiative";
	if (peaceonearth && numeric_modifier2(i,"Combat Rate") > 0)
		gearString += ", +" + numeric_modifier2(i,"Combat Rate") + "% Combat";
	if (broadResistance) {	
		int resist = min(numeric_modifier2(i,"Cold Resistance"),min(numeric_modifier2(i,"Hot Resistance"),
			min(numeric_modifier2(i,"Spooky Resistance"),min(numeric_modifier2(i,"Sleaze Resistance"),
			numeric_modifier2(i,"Stench Resistance")))));
			
		if (resist > 0)
			gearString += ", +" + resist + " Elemental Resistance";
	}
	if (coldResistance) {	
		int resist = numeric_modifier2(i,"Cold Resistance");
		if (resist > 0)
			gearString += ", +" + resist + " Elemental Resistance";
	}
	if (hotResistance) {	
		int resist = numeric_modifier2(i,"Hot Resistance");
		if (resist > 0)
			gearString += ", +" + resist + " Elemental Resistance";
	}
	if (sleazeResistance) {	
		int resist = numeric_modifier2(i,"Sleaze Resistance");
		if (resist > 0)
			gearString += ", +" + resist + " Elemental Resistance";
	}
	if (stenchResistance) {	
		int resist = numeric_modifier2(i,"Stench Resistance");
		if (resist > 0)
			gearString += ", +" + resist + " Elemental Resistance";
	}
	if (spookyResistance) {	
		int resist = numeric_modifier2(i,"Spooky Resistance");
		if (resist > 0)
			gearString += ", +" + resist + " Elemental Resistance";
	}	
	if (coldDamage) {
		float damage = numeric_modifier2(i,"Cold Damage")+numeric_modifier2(i,"Cold Spell Damage");
		if (damage > 0)
			gearString += ", +" + damage + " Cold Damage";
	}	
	if (hotDamage) {
		float damage = numeric_modifier2(i,"Hot Damage")+numeric_modifier2(i,"Hot Spell Damage");
		if (damage > 0)
			gearString += ", +" + damage + " Hot Damage";
	}	
	if (sleazeDamage) {
		float damage = numeric_modifier2(i,"Sleaze Damage")+numeric_modifier2(i,"Sleaze Spell Damage");
		if (damage > 0)
			gearString += ", +" + damage + " Sleaze Damage";
	}	
	if (stenchDamage) {
		float damage = numeric_modifier2(i,"Stench Damage")+numeric_modifier2(i,"Stench Spell Damage");
		if (damage > 0)
			gearString += ", +" + damage + " Stench Damage";
	}	
	if (spookyDamage) {
		float damage = numeric_modifier2(i,"Spooky Damage")+numeric_modifier2(i,"Spooky Spell Damage");
		if (damage > 0)
			gearString += ", +" + damage + " Spooky Damage";
	}
	if (lightestLoad && (to_slot(i) == $slot[hat] || to_slot(i) == $slot[pants] || to_slot(i) == $slot[shirt]))
		gearString += ", Power: " + get_power(i);		
	if (available_amount(i) > 0)
		gearString += ", owned by player";
	else if (npc_price(i) > 0)
		gearString += ", for sale by npc for " + npc_price(i);		
	else if (historical_price(i) > 0)
		gearString += ", for sale on mall for " + historical_price(i);
	return gearString;
}


/** pretty print familiar details related to the active minigames */
string familiarString(familiar f) {

	int weight = familiar_weight(f);	
	if (!have_familiar(f))
		weight = 20;
	item fequip = familiar_equipment(f);
	string hasFamEquip = "";
	if (available_amount(fequip) > 0) {
		
		weight += numeric_modifier2(fequip,"Familiar Weight");
	} else {
		hasFamEquip = "(missing)";
	}
	//weight += weight_adjustment();
		
	string gearString = link(f) + " w/ " + link(familiar_equipment(f)) + hasFamEquip + " " + weight + " lbs. " + round(valuationFamiliar(f,0,$item[none]));
	if (laconic || verbosity)
		gearString += ", " + nameLength(familiar_equipment(f)) + " chars";
	if (letterCheck && lettersinname(familiar_equipment(f),letterToCheck) > 0)
		gearString += ", " + lettersinname(familiar_equipment(f),letterToCheck) + " letter " + letterToCheck;
		
	if (have_familiar(f))
		gearString += ", owned by player";
	return gearString;
}


/** loop through gear to find the best one you can get and equip */
void bestGear(string slotString, slot s) {		
	for j from 0 to Count(gear[slotString])-1 by 1 {			
		if (boolean_modifier(gear[slotString][j],"Single Equip") && equipped_amount(gear[slotString][j]) > 0)
			continue;
		
		if (canEquip(gear[slotString][j]) && gearup(s, gear[slotString][j])) {
			print_html("<b>Best Available " + s + ":</b> " + gearString(gear[slotString][j]));
			print_html(string_modifier(gear[slotString][j],"Modifiers"));
			break;		
		}
	}
}



void main() {
	print_html("<b>PVPBestGear.ash by Zekaonar</b>");
	print_html("Gear will be maximized for the following mini-games:");	
	print_html("<ul>");
	
/*** Determine this season's optimization mini-games ***/	
	string page = visit_url("peevpee.php?place=rules");
	//print_html(page);
	if (index_of(page, "Verbosity") != -1) {
		verbosity = true;
		print_html("<li>Verbosity Demonstration</li>");
	}
	if (index_of(page, "It's a Mystery, Also!") != -1) {
		verbosity = true;
		print_html("<li>It's a Mystery, Also!</li>");
	}
	if (index_of(page, "Laconic") != -1) {
		if (verbosity) {
		    verbosity = false;  // Ignore them.
		} else {
		    laconic = true;
		    print_html("<li>Laconic Dresser</li>");
		}
	}
	if (index_of(page, "Showing Initiative") != -1) {
		showingInitiative = true;
		print_html("<li>Showing Initiative</li>");
	}	
	if (index_of(page, "Peace on Earth") != -1) {
		peaceonearth = true;
		combatWeight = -combatWeight;
		print_html("<li>Peace on Earth</li>");
	}	
	if (index_of(page, "Sooooper Sneaky") != -1) {
		peaceonearth = true;
		combatWeight = -combatWeight;
		print_html("<li>Sooooper Sneaky</li>");
	}	
	if (index_of(page, "The Egg Hunt") != -1) {
		egghunt = true;
		print_html("<li>The Egg Hunt</li>");
	}
	if (index_of(page, "Meat Lover") != -1) {
		meatlover = true;
		print_html("<li>Meat Lover</li>");
	}
	if (index_of(page, "Moarrr Booze!") != -1) {
		moarbooze = true;
		print_html("<li>Moarrr Booze!</li>");
	}
	if (index_of(page, "Holiday Spirit(s)!") != -1) {
		moarbooze = true;
		print_html("<li>Moarrr Booze!</li>");
	}
	if (index_of(page, "Broad Resistance Contest") != -1) {
		broadResistance = true;
		print_html("<li>Broad Resistance Contest</li>");
	}	
	if (index_of(page, "All Bundled Up") != -1) {
		coldResistance = true;
		print_html("<li>All Bundled Up</li>");
	}
/*******	Future proofed	
	if (index_of(page, "TBD") != -1) {
		hotResistance = true;
		print_html("<li>TBD</li>");
	}	
	if (index_of(page, "TBD") != -1) {
		sleazeResistance = true;
		print_html("<li>TBD</li>");
	}			
********/
	if (index_of(page, "Hold Your Nose") != -1) {
		stenchResistance = true;
		print_html("<li>Hold Your Nose</li>");
	}	
/*******	Future proofed	
	if (index_of(page, "TBD") != -1) {
		spookyResistance = true;
		print_html("<li>TBD</li>");
	}	
	if (index_of(page, "TBD") != -1) {
		coldDamage = true;
		print_html("<li>TBD</li>");
	}	
******/
	if (index_of(page, "Ready to Melt") != -1) {
		hotDamage = true;
		print_html("<li>Ready to Melt</li>");
	}	
	if (index_of(page, "Innuendo Master") != -1) {
		sleazeDamage = true;
		print_html("<li>Innuendo Master</li>");
	}
/*******	Future proofed		
	if (index_of(page, "TBD") != -1) {
		stenchDamage = true;
		print_html("<li>TBD</li>");
	}	
	if (index_of(page, "TBD") != -1) {
		spookyDamage = true;
		print_html("<li>TBD</li>");
	}	
******/	
	if (index_of(page, "Lightest Load") != -1) {
		lightestLoad = true;
		print_html("<li>Lightest Load</li>");
	}		
	if (index_of(page, "Fashion Show") != -1) {
		lightestLoad = true;
		powerWeight =  -powerWeight;
		print_html("<li>Fashion Show</li>");
	}		
	if (index_of(page, "Spirit of Noel") != -1) {
		letterCheck = true;	
		letterToCheck = "L";
		nextLetter = "L";
		letterMomentWeight = -letterMomentWeight;
		nextLetterWeight = 0;
		print_html("<li>Spirit of Noel</li>");
	}
	if (index_of(page, "Letter of the Moment") != -1) {
		letterCheck = true;	
		int start = index_of(page, "Who has the most <b>");
		letterToCheck = substring(page,start+20,start+21);
//		letterToCheck="X";
		start = index_of(page, "Changing to <b>");
		nextLetter = substring(page,start+15,start+16);
		start = index_of(page, "</b> in ");
		int end = index_of(page," seconds.)");
		string secs = substring(page,start+8,end);		
		print_html("<li>Letter of the Moment: " + letterToCheck + ", next " + nextLetter + " </li>");
	}
	print_html("</ul>");
	
/*** unequip all slots ***/
	foreach i in $slots[hat, back, shirt, weapon, off-hand, pants, acc1, acc2, acc3] 
		equip(i,$item[none]);
	print_html("<br/>");	

/*** Familiar Logic ***/
	familiar [int] fams;
	foreach f in $familiars[] {
		fams[count(fams)] = f;
	}
	sort fams by -valuationFamiliar(value,0,$item[none]);
	
	print_html("<b>Top Familiars:</b>");
	
	for j from 0 to (topItems-1) by 1 {
		print_html((j+1) + ".) " + familiarString(fams[j]) );
	}
	print_html("<br/>");
	if (my_class() != $class[Avatar of Sneaky Pete]) {
		for j from 0 to count(fams)-1 by 1 {
			if (have_familiar(fams[j]) && available_amount(familiar_equipment(fams[j])) > 0) {
				use_familiar(fams[j]);			
				//equip($slot[familiar],familiar_equipment(fams[j]));
				equip($slot[familiar],$item[none]);
				bestFamiliar = fams[j];
				break;
			}				
		}
	} else {
		print_html("Sneaky Pete doesn't use familiars.");
	}		
	print_html("<br/>");

/*** create lists of all items in each slot type ***/
	foreach i in $items[] { // This iterates over all items in the game		
		// if it's gear that you can equip, and you have it or the mall price is under threshold
		string s = to_slot(i);
		int price = npc_price(i);
		if (price == 0) 
			price = historical_price(i);
		if((s != $slot[none] && showAllItems && can_equip(i)) 
			|| (s != $slot[none] && can_equip(i) && canGet(i))) {
			
			string modstring = string_modifier(i,"Modifiers");
			// filter situational items that don't apply to fighting in arena
			if (modstring.index_of("Unarmed") == -1) {
			

			// create a new slot type for 2 hand and 3 hand weapons (not used atm)
				if (s == $slot[weapon] && weapon_hands(i) > 1)
					s = "2h weapon";

				gear[s] [count(gear[s])] = i;
				//length(i)
			}
		}
	}

/*** Top Gear display lists ***/
	foreach i in $slots[hat, back, shirt, weapon, off-hand, pants, acc1, familiar] {
		int itemCount = count(gear[to_string(i)]); 
		print_html("<b>Slot <i>" + i + "</i> items considered: " + itemCount + " printing top items in slot:</b>");

		sort gear[to_string(i)] by -valuation(value);

		if(displayUnownedBling == true)
		{
			for j from 0 to (topItems - 1) by 1 
				print_html((j+1) + ".) " + gearString(gear[to_string(i)][j]) );
			print_html("<br/>");
		}
		else
		{
			int dumbCounter = 0;
			int dumbCounterToo = 0;
			while(dumbCounter <= (topItems-1))
			{
				if(historical_price(gear[to_string(i)][dumbCounterToo])<= bling)
				{
					print_html((dumbCounter+1) + ".) " + gearString(gear[to_string(i)][dumbCounterToo]) );
					dumbCounterToo = dumbCounterToo + 1;
					dumbCounter = dumbCounter + 1;
				}
				else
				{
					dumbCounterToo = dumbCounterToo + 1;
				}
			}
			print_html("<br/>");
		}
	}
	
	
	
/*** DISPLAY BEST GEAR IN SLOTS ***/	
	
	
	
/*** Display best familiar ***/
	print_html("<b>Best Familiar:</b> " + familiarString(bestFamiliar));


	
/*** Display best in slot  ***/	
	bestGear("hat", $slot[hat]);
	
	// Handle Throne
	if (equipped_amount($item[Crown of Thrones]) > 0) {
		if (egghunt) {
			if (have_familiar($familiar[Feral Kobold]) && enthrone_familiar2($familiar[Feral Kobold]));		
			else if (have_familiar($familiar[Li'l Xenomorph]) && enthrone_familiar2($familiar[Li'l Xenomorph]));
			else if (have_familiar($familiar[Oily Woim]) && enthrone_familiar2($familiar[Oily Woim]));
			else if (have_familiar($familiar[Reconstituted Crow]) && enthrone_familiar2($familiar[Reconstituted Crow]));				
			else if (have_familiar($familiar[Reassembled Blackbird]) && enthrone_familiar2($familiar[Reassembled Blackbird]));
		} else if (meatlover) {
			if (have_familiar($familiar[Happy Medium]) && enthrone_familiar2($familiar[Happy Medium]));		
			else if (have_familiar($familiar[Knob Goblin Organ Grinder]) && enthrone_familiar2($familiar[Knob Goblin Organ Grinder]));				
			else if (have_familiar($familiar[Hobo Monkey]) && enthrone_familiar2($familiar[Hobo Monkey]));
			else if (have_familiar($familiar[Grouper Groupie]) && enthrone_familiar2($familiar[Grouper Groupie]));	
			else if (have_familiar($familiar[Leprechaun]) && enthrone_familiar2($familiar[Leprechaun]));				
		} else if (showingInitiative) {		
			if (have_familiar($familiar[Levitating Potato]) && enthrone_familiar2($familiar[Levitating Potato]));			
			else if (have_familiar($familiar[Cuddlefish]) && enthrone_familiar2($familiar[Cuddlefish]));				
		} else if (peaceonearth) {		
			if (have_familiar($familiar[Grimstone Golem]) && enthrone_familiar2($familiar[Grimstone Golem]));			
		} else if (broadResistance) {
			if (have_familiar($familiar[Toothsome Rock]) && enthrone_familiar2($familiar[Toothsome Rock]));		
			else if (have_familiar($familiar[Pet Rock]) && enthrone_familiar2($familiar[Pet Rock]));		
			else if (have_familiar($familiar[Holiday Log]) && enthrone_familiar2($familiar[Holiday Log]));	
			else if (have_familiar($familiar[Exotic Parrot]) && enthrone_familiar2($familiar[Exotic Parrot]));				
			else if (have_familiar($familiar[Bulky Buddy Box]) && enthrone_familiar2($familiar[Bulky Buddy Box]));			
		} else if (coldResistance) {
			if (have_familiar($familiar[Toothsome Rock]) && enthrone_familiar2($familiar[Toothsome Rock]));		
			else if (have_familiar($familiar[Pet Rock]) && enthrone_familiar2($familiar[Pet Rock]));		
			else if (have_familiar($familiar[Holiday Log]) && enthrone_familiar2($familiar[Holiday Log]));	
			else if (have_familiar($familiar[Exotic Parrot]) && enthrone_familiar2($familiar[Exotic Parrot]));				
			else if (have_familiar($familiar[Bulky Buddy Box]) && enthrone_familiar2($familiar[Bulky Buddy Box]));			
		} else if (stenchResistance) {
			if (have_familiar($familiar[Toothsome Rock]) && enthrone_familiar2($familiar[Toothsome Rock]));		
			else if (have_familiar($familiar[Pet Rock]) && enthrone_familiar2($familiar[Pet Rock]));		
			else if (have_familiar($familiar[Holiday Log]) && enthrone_familiar2($familiar[Holiday Log]));	
			else if (have_familiar($familiar[Exotic Parrot]) && enthrone_familiar2($familiar[Exotic Parrot]));				
			else if (have_familiar($familiar[Bulky Buddy Box]) && enthrone_familiar2($familiar[Bulky Buddy Box]));			
		}		
	}	
	
	bestGear("back", $slot[back]);

	// Handle Bjorn
	if (equipped_amount($item[Buddy Bjorn]) > 0) {
		if (egghunt) {
			if (have_familiar($familiar[Li'l Xenomorph]) && bjornify_familiar2($familiar[Li'l Xenomorph]));
			else if (have_familiar($familiar[Feral Kobold]) && bjornify_familiar2($familiar[Feral Kobold]));
			else if (have_familiar($familiar[Reassembled Blackbird]) && bjornify_familiar2($familiar[Reassembled Blackbird]));
			else if (have_familiar($familiar[Reconstituted Crow]) && bjornify_familiar2($familiar[Reconstituted Crow]));
			else if (have_familiar($familiar[Oily Woim]) && bjornify_familiar2($familiar[Oily Woim]));
		} else if (meatlover) {
			if (have_familiar($familiar[Hobo Monkey]) && bjornify_familiar2($familiar[Hobo Monkey]));
			else if (have_familiar($familiar[Knob Goblin Organ Grinder]) && bjornify_familiar2($familiar[Knob Goblin Organ Grinder]));
			else if (have_familiar($familiar[Happy Medium]) && bjornify_familiar2($familiar[Happy Medium]));
			else if (have_familiar($familiar[Leprechaun]) && bjornify_familiar2($familiar[Leprechaun]));
			else if (have_familiar($familiar[Grouper Groupie]) && bjornify_familiar2($familiar[Grouper Groupie]));			
		} else if (showingInitiative) {					
			if (have_familiar($familiar[Cuddlefish]) && bjornify_familiar2($familiar[Cuddlefish]));
			else if (have_familiar($familiar[Levitating Potato]) && bjornify_familiar2($familiar[Levitating Potato]));					
		} else if (peaceonearth) {					
			if (have_familiar($familiar[Grimstone Golem]) && bjornify_familiar2($familiar[Grimstone Golem]));
		} else if (broadResistance) {
			if (have_familiar($familiar[Bulky Buddy Box]) && bjornify_familiar2($familiar[Bulky Buddy Box]));			
			else if (have_familiar($familiar[Exotic Parrot]) && bjornify_familiar2($familiar[Exotic Parrot]));
			else if (have_familiar($familiar[Holiday Log]) && bjornify_familiar2($familiar[Holiday Log]));
			else if (have_familiar($familiar[Pet Rock]) && bjornify_familiar2($familiar[Pet Rock]));
			else if (have_familiar($familiar[Toothsome Rock]) && bjornify_familiar2($familiar[Toothsome Rock]));		
		} else if (coldResistance) {
			if (have_familiar($familiar[Bulky Buddy Box]) && bjornify_familiar2($familiar[Bulky Buddy Box]));			
			else if (have_familiar($familiar[Exotic Parrot]) && bjornify_familiar2($familiar[Exotic Parrot]));
			else if (have_familiar($familiar[Holiday Log]) && bjornify_familiar2($familiar[Holiday Log]));
			else if (have_familiar($familiar[Pet Rock]) && bjornify_familiar2($familiar[Pet Rock]));
			else if (have_familiar($familiar[Toothsome Rock]) && bjornify_familiar2($familiar[Toothsome Rock]));		
		} else if (stenchResistance) {
			if (have_familiar($familiar[Bulky Buddy Box]) && bjornify_familiar2($familiar[Bulky Buddy Box]));			
			else if (have_familiar($familiar[Exotic Parrot]) && bjornify_familiar2($familiar[Exotic Parrot]));
			else if (have_familiar($familiar[Holiday Log]) && bjornify_familiar2($familiar[Holiday Log]));
			else if (have_familiar($familiar[Pet Rock]) && bjornify_familiar2($familiar[Pet Rock]));
			else if (have_familiar($familiar[Toothsome Rock]) && bjornify_familiar2($familiar[Toothsome Rock]));		
		}		
	}


	bestGear("shirt", $slot[shirt]);
		
	// determine the best possible weapon combos
	// 2hand / 3hand 
	// 1hand + offhand
	// 1hand + 1hand (if skill Double-Fisted Skull Smashing)
	if (have_skill($skill[Double-Fisted Skull Smashing])) {
		dualWield = true;
		print_html("<b>Player can dual wield 1-hand weapons.</b>");
	}

	

	int k = 0;
	for j from 0 to Count(gear["weapon"])-1 by 1 {
		if(canGet(gear["weapon"][j])) {
			bestWeapon = gear["weapon"][j];
			k = j;
			break;			
		}
	}
	bestGear("weapon", $slot[weapon]);
	
	if (available_amount(bestWeapon)-equipped_amount(bestWeapon) > 1 || (historical_price(bestWeapon) < maxPrice && historical_price(bestWeapon) > 0))
		secondWeapon = bestWeapon;
	else {
		for j from k+1 to Count(gear["weapon"])-1 by 1 {
			if(canGet(gear["weapon"][j]) && weapon_type(gear["weapon"][j]) == weapon_type(bestWeapon)) {
				secondWeapon = gear["weapon"][j];
				break;			
			}
		}	
	}
	for j from 0 to Count(gear["off-hand"])-1 by 1 {
		if(canGet(gear["off-hand"][j])) {
			bestOffhand = gear["off-hand"][j];
			k = j;
			break;			
		}
	}

	if ((!dualWield 
		|| valuation(bestWeapon,bestOffhand) < valuation(bestWeapon,secondWeapon))) {
		gearup($slot[off-hand],bestOffhand);
		print_html("<b>Best Available off-hand:</b> " + gearString(bestOffhand));
		print_html(string_modifier(bestOffhand,"Modifiers"));				
		
	} else {
		gearup($slot[off-hand],secondWeapon);
		print_html("<b>Best 2nd weapon:</b> " + gearString(secondWeapon));
		print_html(string_modifier(secondWeapon,"Modifiers"));						
	}
	bestGear("pants", $slot[pants]);
	bestGear("acc1", $slot[acc1]);
	bestGear("acc1", $slot[acc2]);
	bestGear("acc1", $slot[acc3]);
	
	
/** Resort familiar gear in context of our best familiar so weight vs stats vs name is counted right */
	//sort gear["familiar"] by -valuationFamiliar(bestFamiliar,0,value);
	//for j from 0 to (topItems-1) by 1 {
	//	print_html((j+1) + ".) " + gearString(gear["familiar"][j]) );
	//}	
	bestGear("familiar", $slot[familiar]);

	page = visit_url("peevpee.php?place=rules");
	page = substring(page,index_of(page, "</head>")+7,length(page));	
	//print_html(page);
	
}
