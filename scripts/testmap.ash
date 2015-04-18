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
   
void main() 
{
	loadPvPProperties();
	print("wat");
}