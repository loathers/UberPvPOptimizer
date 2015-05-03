/*	Original script written by Zekaonar
*	Updated by Crowther
*	Rewritten by UberFerret		*/
script "UberPvPOptimizer.ash";
notify "UberFerret";
import <zlib.ash>;

//Declare all the variables
boolean showAllItems;
boolean buyGear;
int maxPrice;
int topItems;
boolean displayUnownedBling;
int bling;

float letterMomentWeight;
float nextLetterWeight;
float itemDropWeight;
float meatDropWeight;
float boozeDropWeight;
float initiativeWeight;
float combatWeight;
float resistanceWeight;
float powerWeight;
float damageWeight;
float negativeClassWeight;
float weaponDmgWeight;
float nakedWeight;

// Booleans for each pvp mini
boolean laconic = false;
boolean verbosity = false;
boolean egghunt = false;
boolean meatlover = false;
boolean weaponDamage = false;
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

//other variables
string currentLetter;
string nextLetter;
boolean dualWield = false;
item primaryWeapon;			//mainhand
item secondaryWeapon;		//offhand
item tertiaryWeapon;		//hand
item bestOffhand;
item [string] [int] gear;


void loadPvPProperties()
{
	float [string] pvpGear;
	file_to_map("pvpGearProperties.txt", pvpGear);
	if (pvpGear["Exists"] != 1.0)
	{
//Set properties
		pvpGear["Exists"] = 1.0;							// Store a map value to say it exists, allows for checking later.
		pvpGear["showAllItems"] = true.to_float();			// When 0.0, only shows items you own or within mall budget
		pvpGear["buyGear"] = false.to_float();				// Will auto-buy from mall if below threshold price and better than what you have
		pvpGear["maxBuyPrice"] = 1000;						// Max price that will be considered to auto buy gear if you don't have it
		pvpGear["topItems"] = 10;							// Number of items to display in the output lists
		pvpGear["limitExpensiveDisplay"] = false.to_float();// Set to false to prevent the item outputs from showing items worth [bling] or more
		pvpGear["defineExpensive"] = 10000000;				// define amount for value limiter to show 10,000,000 default
//Item Weights
		pvpGear["letterMomentWeight"] = 6.0;				// Example: An "S" is worth 3 letters in laconic/verbosity
		pvpGear["nextLetterWeight"] = 0.1;					// Example: allow a future letter to be a tie-breaker
		pvpGear["itemDropWeight"] = (4.0/5.0);				// 4 per 5% drop Example: +8% items is worth 10 letters in laconic/verbosity
		pvpGear["meatDropWeight"] = (3.0/5.0);				// 3 per 5% drop Example: +25% meat is worth 15 letters in laconic/verbosity
		pvpGear["boozeDropWeight"] = (3.0/5.0);				// 3 per 5% drop Example: +20% booze is worth 12 letters in laconic/verbosity
		pvpGear["initiativeWeight"] = (4.0/10.0);			// 4 per 10% initiative Example: +20% initiative is worth 8 letters in laconic/verbosity
		pvpGear["combatWeight"] = (15.0/5.0);				// 4 per 10% combat Example: +20% combat is worth 8 letters in laconic/verbosity
		pvpGear["resistanceWeight"] = 6.0;					// Example: +1 Resistance to all elements equals 6 letters of laconic/verbosity
		pvpGear["powerWeight"] = (5.0/10.0);				// Example: 5 points for -10 points of power towards Lightest Load vs average(110) power in slot.  
		pvpGear["damageWeight"] = 4.0/10.0;					// Example: 4 points for 10 points of damage.
		pvpGear["negativeClassWeight"] = -5;				// Give a negative weight to items that are not for your class.
		pvpGear["weaponDmgWeight"] = (7.0);					// Weight weapon damage very highly
		pvpGear["nakedWeight"] = (5.0);	//WORK IN PROGRESS

		if (map_to_file( pvpGear , "pvpGearProperties.txt" ))
		   print( "Weight and properties saved." );
		else
		   print( "There was a problem saving your properties." );
	}
	else
	{
		print("Your custom weights and settings were loaded successfully.");
	}
	
	/***Load settings ***/
	
	showAllItems = pvpGear["showAllItems"].to_boolean();			// When false, only shows items you own or within mall budget
	buyGear = pvpGear["buyGear"].to_boolean();					// Will auto-buy from mall if below threshold price and better than what you have
	maxPrice = pvpGear["maxBuyPrice"].to_int();					// Max price that will be considered to auto buy gear if you don't have it
	topItems = pvpGear["topItems"].to_int();						// Number of items to display in the output lists
	displayUnownedBling = pvpGear["limitExpensiveDisplay"].to_boolean();	// Set to false to prevent the item outputs from showing items worth [bling] or more
	bling = pvpGear["defineExpensive"].to_int();					// define amount for value limiter to show 10,000,000 default

	letterMomentWeight = pvpGear["letterMomentWeight"];			// Example: An "S" is worth 3 letters in laconic/verbosity
	nextLetterWeight = pvpGear["nextLetterWeight"];			// Example: allow a future letter to be a tie-breaker
	itemDropWeight = pvpGear["itemDropWeight"];		// 4 per 5% drop Example: +8% items is worth 10 letters in laconic/verbosity
	meatDropWeight = pvpGear["meatDropWeight"];		// 3 per 5% drop Example: +25% meat is worth 15 letters in laconic/verbosity
	boozeDropWeight = pvpGear["boozeDropWeight"];		// 3 per 5% drop Example: +20% booze is worth 12 letters in laconic/verbosity
	initiativeWeight = pvpGear["initiativeWeight"];	// 4 per 10% initiative Example: +20% initiative is worth 8 letters in laconic/verbosity
	combatWeight = pvpGear["combatWeight"];		// 4 per 10% combat Example: +20% combat is worth 8 letters in laconic/verbosity
	resistanceWeight = pvpGear["resistanceWeight"];			// Example: +1 Resistance to all elements equals 6 letters of laconic/verbosity
	powerWeight = pvpGear["powerWeight"];			// Example: 5 points for -10 points of power towards Lightest Load vs average(110) power in slot.  
	damageWeight = pvpGear["damageWeight"];			// Example: 4 points for 10 points of damage.
	negativeClassWeight = pvpGear["negativeClassWeight"];			// Off class items are given a 0, adjust as you see fit.
	weaponDmgWeight = pvpGear["weaponDmgWeight"];
	nakedWeight = pvpGear["nakedWeight"];	//WORK IN PROGRESS
	
}

//return the class of an item
class getClass(item i)
{
	return to_class(string_modifier(i, "Class"));
}

//	Letter of the moment count	source:Zekaonar
int letterCount(item gear, string letter)
{
	if (gear == $item[none])
		return 0;
	matcher entity = create_matcher("&[^ ;]+;", gear);
	string output = replace_all(entity,"");
	matcher htmltag = create_matcher("\<[^\>]*\>",output);
	output = replace_all(htmltag,"");
	int lettersCounted=0;
	for i from 0 to length(output)-1 {
		if (char_at(output,i)==letter) lettersCounted+=1;  
	}
	return lettersCounted;
}
//Improved version of length() that deals with HTML entities, tags and counts them like pvp info does  source:Zekaonar
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
// Check if you have an item, or it is in the mall historically for a price within the budget
boolean canAcquire(item i) {		//source:Zekaonar
	return ((can_interact() && buyGear && maxPrice >= historical_price(i) && historical_price(i) != 0) 
		|| available_amount(i)-equipped_amount(i) > 0);
}

//Chefstaves require a skill to equip
boolean isChefStaff(item i) {
	foreach staff in $items[Staff of the Headmaster's Victuals, Staff of the November Jack-O-Lantern, Spooky Putty snake, Staff of Queso Escusado, Staff of the Lunch Lady, Staff of the Woodfire, Staff of the Cozy Fish, Staff of Simmering Hatred, The Necbromancer's Wizard Staff] {
		if (i == staff) 
			return true;		
	}
	return false;
}
//Make sure the item can be equipped
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
		class cl = getClass( i );
		string[int] arr = split_string(mods,",");
		/**check if the item is even for my class if not don't prefer it **/
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
/** function for calculating the value of a item based off the mini-game weighting */
float valuation(item i) {
	float value = 0;
	if (laconic)
		value = 23 - nameLength(i);
	else if (verbosity)
		value = nameLength(i);
		
	if (letterCheck) {
		value += letterCount(i,currentLetter)*letterMomentWeight;
		value += letterCount(i,nextLetter)*nextLetterWeight;
	}
		
	if (egghunt)
		value += numeric_modifier2(i,"Item Drop")*itemDropWeight;
		
	if (meatlover)
		value += numeric_modifier2(i,"Meat Drop")*meatDropWeight;
		
	if (weaponDamage)
		value += numeric_modifier2(i,"Weapon Damage")*weaponDmgWeight;

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
	/******
	*
	*Snipped Bjornify and Enthroning here
	*
	*****/
	return value;
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
		value += (letterCount(i,currentLetter) + letterCount(i2,currentLetter))*letterMomentWeight;
		
	if (egghunt)
		value += (numeric_modifier2(i,"Item Drop")+numeric_modifier2(i2,"Item Drop"))*itemDropWeight;
		
	if (weaponDamage)
		value += (numeric_modifier2(i,"Weapon Damage")+numeric_modifier2(i2,"Weapon Damage"))*weaponDmgWeight;
	
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
	if (laconic || verbosity)
		gearString += ", " + nameLength(i) + " chars";
	if (letterCheck && letterCount(i,currentLetter) > 0)
		gearString += ", " + letterCount(i,currentLetter) + " letter " + currentLetter;
	if (egghunt && numeric_modifier2(i,"Item Drop") > 0)
		gearString += ", +" + numeric_modifier2(i,"Item Drop") + "% Item Drop";
	if (meatlover && numeric_modifier2(i,"Meat Drop") > 0)
		gearString += ", +" + numeric_modifier2(i,"Meat Drop") + "% Meat Drop";
	if (moarbooze && numeric_modifier2(i,"Booze Drop") > 0)
		gearString += ", +" + numeric_modifier2(i,"Booze Drop") + "% Booze Drop";
	if (weaponDamage && numeric_modifier2(i,"Weapon Damage") > 0)
		gearString += ", +" + numeric_modifier2(i,"Weapon Damage") + "% Weapon Damage";
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


/*******
	Snipped familiars
********/


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
	print_html("<b>UberPvPOptimizer.ash by UberFerret, a Fork of PVPBestGear by Zekaonar</b>");
	print_html("Gear will be maximized for the following mini-games:");	
	print_html("<ul>");
	
/**Call Preference/setting load **/
	loadPvPProperties();
	
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
	if (index_of(page, "Maul Power") != -1) {
		weaponDamage = true;
		print_html("<li>Maul Power</li>");
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
	if (index_of(page, "Hibernation Ready") != -1) {
		coldResistance = true;
		print_html("<li>Hibernation Ready</li>");
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
		currentLetter = "L";
		nextLetter = "L";
		letterMomentWeight = -letterMomentWeight;
		nextLetterWeight = 0;
		print_html("<li>Spirit of Noel</li>");
	}
	if (index_of(page, "Letter of the Moment") != -1) {
		letterCheck = true;	
		int start = index_of(page, "Who has the most <b>");
		currentLetter = substring(page,start+20,start+21);
//		currentLetter="X";			//hacky way to force optimizing a letter
		start = index_of(page, "Changing to <b>");
		nextLetter = substring(page,start+15,start+16);
		start = index_of(page, "</b> in ");
		int end = index_of(page," seconds.)");
		string secs = substring(page,start+8,end);		
		print_html("<li>Letter of the Moment: " + currentLetter + ", next " + nextLetter + " </li>");
	}
	print_html("</ul>");
	
/*** unequip all slots ***/
	foreach i in $slots[hat, back, shirt, weapon, off-hand, pants, acc1, acc2, acc3] 
		equip(i,$item[none]);
	print_html("<br/>");	
/*******
	Snipped familiars
********/

/*** create lists of all items in each slot type ***/
	foreach i in $items[] { // This iterates over all items in the game		
		// if it's gear that you can equip, and you have it or the mall price is under threshold
		string s = to_slot(i);
		int price = npc_price(i);
		if (price == 0) 
			price = historical_price(i);
		if((s != $slot[none] && showAllItems && can_equip(i)) 
			|| (s != $slot[none] && can_equip(i) && canAcquire(i))) {
			
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
	foreach i in $slots[hat, back, shirt, weapon, off-hand, pants, acc1] {
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
	
	
/*******
	Snipped familiars
********/

	
/*** Display best in slot  ***/	
	bestGear("hat", $slot[hat]);
//Snipped Crown of Thrones
	bestGear("back", $slot[back]);
//Snipped Buddy Bjorn
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
		if(canAcquire(gear["weapon"][j])) {
			primaryWeapon = gear["weapon"][j];
			k = j;
			break;			
		}
	}
	bestGear("weapon", $slot[weapon]);
	
	if (available_amount(primaryWeapon)-equipped_amount(primaryWeapon) > 1 || (historical_price(primaryWeapon) < maxPrice && historical_price(primaryWeapon) > 0))
		secondaryWeapon = primaryWeapon;
	else {
		for j from k+1 to Count(gear["weapon"])-1 by 1 {
			if(canAcquire(gear["weapon"][j]) && weapon_type(gear["weapon"][j]) == weapon_type(primaryWeapon)) {
				secondaryWeapon = gear["weapon"][j];
				break;			
			}
		}	
	}
	for j from 0 to Count(gear["off-hand"])-1 by 1 {
		if(canAcquire(gear["off-hand"][j])) {
			bestOffhand = gear["off-hand"][j];
			k = j;
			break;			
		}
	}

	if ((!dualWield 
		|| valuation(primaryWeapon,bestOffhand) < valuation(primaryWeapon,secondaryWeapon))) {
		gearup($slot[off-hand],bestOffhand);
		print_html("<b>Best Available off-hand:</b> " + gearString(bestOffhand));
		print_html(string_modifier(bestOffhand,"Modifiers"));				
		
	} else {
		gearup($slot[off-hand],secondaryWeapon);
		print_html("<b>Best 2nd weapon:</b> " + gearString(secondaryWeapon));
		print_html(string_modifier(secondaryWeapon,"Modifiers"));						
	}
	bestGear("pants", $slot[pants]);
	bestGear("acc1", $slot[acc1]);
	bestGear("acc1", $slot[acc2]);
	bestGear("acc1", $slot[acc3]);
	
/*******
	Snipped familiars
********/	

	page = visit_url("peevpee.php?place=rules");
	page = substring(page,index_of(page, "</head>")+7,length(page));	
	//print_html(page);
	
}
