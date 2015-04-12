void load_Properties()
{
	float [string] pvpGear;
	file_to_map("pvpGearProperties", pvpGear);
	if (pvpGear["Exists"] != 1.0)
	{
		pvpGear["Exists"] = 1.0;					// Store a map value to say it exists, allows for checking later.
		pvpGear["showAllItemsf"] = true.to_float();	// When 0.0, only shows items you own or within mall budget
		pvpGear["buyGearf"] = false.to_float();		// Will auto-buy from mall if below threshold price and better than what you have
		pvpGear["maxPricef"] = 1000;				// Max price that will be considered to auto buy gear if you don't have it
		pvpGear["topItemsf"] = 10;					// Number of items to display in the output lists
		pvpGear["displayUnownedBling"] = false.to_float();	// Set to false to prevent the item outputs from showing items worth [bling] or more
		pvpGear["blingf"] = 10000000;				// define amount for value limiter to show 10,000,000 default

		pvpGear["letterMomentWeight"] = 6.0;			// Example: An "S" is worth 3 letters in laconic/verbosity
		pvpGear["nextLetterWeight"] = 0.1;			// Example: allow a future letter to be a tie-breaker
		pvpGear["itemDropWeight"] = (4.0/5.0);		// 4 per 5% drop Example: +8% items is worth 10 letters in laconic/verbosity
		pvpGear["meatDropWeight"] = (3.0/5.0);		// 3 per 5% drop Example: +25% meat is worth 15 letters in laconic/verbosity
		pvpGear["boozeDropWeight"] = (3.0/5.0);		// 3 per 5% drop Example: +20% booze is worth 12 letters in laconic/verbosity
		pvpGear["initiativeWeight"] = (4.0/10.0);	// 4 per 10% initiative Example: +20% initiative is worth 8 letters in laconic/verbosity
		pvpGear["combatWeight"] = (15.0/5.0);		// 4 per 10% combat Example: +20% combat is worth 8 letters in laconic/verbosity
		pvpGear["resistanceWeight"] = 6.0;			// Example: +1 Resistance to all elements equals 6 letters of laconic/verbosity
		pvpGear["powerWeight"] = (5.0/10.0);			// Example: 5 points for -10 points of power towards Lightest Load vs average(110) power in slot.  
		pvpGear["damageWeight"] = 4.0/10.0;			// Example: 4 points for 10 points of damage.
		pvpGear["negativeClassWeight"] = -5;

		if (map_to_file( pvpGear , "pvpGearProperties" ))
		   print( "Properties saved." );
		else
		   print( "There was a problem saving your properties." );
	}
	else
	{
		print("Properties loaded");
	}
}
   
void main() 
{
	load_Properties();
	print("wat");
}