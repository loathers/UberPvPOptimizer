/*	Original script written by Zekaonar
*	Updated by Crowther
*	Rewritten by UberFerret		*/
script "UberPvPOptimizer.ash"
notify "UberFerret";
import <zlib.ash>;



/********
void loadPvPProperties()
{
	float [string] pvpGear;
	file_to_map("pvpGearProperties", pvpGear);
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

		if (map_to_file( pvpGear , "pvpGearProperties" ))
		   print( "Weight and properties saved." );
		else
		   print( "There was a problem saving your properties." );
	}
	else
	{
		print("Your custom weights and settings were loaded successfully.");
	}
}

// Booleans for each pvp mini
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

//other variables
string currentLetter;
string nextLetter;
familiar bestFamiliar = $familiar[none];
boolean dualWield = false;
item primaryWeapon;			//mainhand
item secondaryWeapon;		//offhand
item tertiaryWeapon;		//hand
item bestOffhand;
item [string] [int] gear;

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
		class cl = class_modifier( i );
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
   
void main() 
{
	loadPvPProperties();
	print("wat");
}