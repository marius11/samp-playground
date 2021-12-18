#include a_samp
#include zcmd
#include sscanf2

#if defined MAX_PLAYERS
	#undef MAX_PLAYERS
	#define MAX_PLAYERS 100
#endif

#define TEXT_DRAW_REFRESH_RATE 100

#define MAX_PLAYER_IP_LENGTH 16

#define WEAPON_INFORMATION_LENGTH 64
#define VEHICLE_INFORMATION_LENGTH 64

#define MAX_WEAPON_NAME 16
#define MAX_WEAPON_SLOTS 12
#define MAX_WEAPON_LIST_LENGTH 256

#define WEAPON_NIGHT_VISION 44
#define WEAPON_THERMAL_GOGGLES 45

forward GetPlayerInfo(playerid);

new Text: LiveInfoTD[MAX_PLAYERS];
new bool: IsLiveInfoOn[MAX_PLAYERS];
new LiveInfoTimer[MAX_PLAYERS];

public OnFilterScriptInit()
{
	print("\nLiveInfo LOADED\nCredits:\n\t- [NoV]HAMM3R\n\t- [NoV]Pops\n");

	// probabily not a good idea to create MAX_PLAYERS amount of textdraws from the start
	new Text: textDraw;

	for (new i = 0; i < MAX_PLAYERS; i++)
	{
        textDraw = TextDrawCreate(139.0000, 373.0000, "Loading information...");
        TextDrawBackgroundColor(textDraw, 255);
        TextDrawFont(textDraw, 1);
        TextDrawLetterSize(textDraw, 0.2200, 0.8999);
        TextDrawColor(textDraw, 0x57B1F6FF);
        TextDrawSetOutline(textDraw, 1);
        TextDrawSetProportional(textDraw, 1);

		LiveInfoTD[i] = textDraw;

        IsLiveInfoOn[i] = false;
        
		// CallLocalFunction("GetPlayerInfo", "i", 0);
    }

	return 1;
}

public OnFilterScriptExit()
{
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		TextDrawDestroy(Text: LiveInfoTD[i]);
		KillTimer(LiveInfoTimer[i]);
		IsLiveInfoOn[i] = false;
	}

	return 1;
}

CMD:arm(playerid, cmdtext[])
{
	new weaponId;

	if (sscanf(cmdtext, "i", weaponId))
	{
		SendClientMessage(playerid, -1, "<> Usage: /arm <weapon id>");
		return 1;
	}

	GivePlayerWeapon(playerid, weaponId, 100);

	return 1;
}

CMD:li(playerid, cmdtext[])
{
	new id;

	if (sscanf(cmdtext, "u", id) || id == INVALID_PLAYER_ID)
	{
		return SendClientMessage(playerid, -1, ">> Usage: /li <id>");
	}

	LiveInfoTimer[id] = SetTimerEx("GetPlayerInfo", TEXT_DRAW_REFRESH_RATE, true, "d", id);

	SendClientMessage(playerid, -1, ">> Use /lioff to hide the info textdraw");
	IsLiveInfoOn[playerid] = true;

	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		TextDrawHideForPlayer(playerid, Text: LiveInfoTD[i]);
	}

	TextDrawShowForPlayer(playerid, Text: LiveInfoTD[id]);

	return 1;
}

CMD:lioff(playerid, cmdtext[])
{
	if (!IsLiveInfoOn[playerid])
	{
		return SendClientMessage(playerid, -1, ">> There is nothing to hide");
	}

	IsLiveInfoOn[playerid] = false;

    for (new i; i < MAX_PLAYERS; i++)
    {
		KillTimer(LiveInfoTimer[i]);
		TextDrawHideForPlayer(playerid, Text: LiveInfoTD[i]);
	}

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    KillTimer(LiveInfoTimer[playerid]);

	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		TextDrawHideForAll(Text: LiveInfoTD[i]);
		IsLiveInfoOn[i] = false;
	}

	return 1;
}

public GetPlayerInfo(playerid)
{
	if (!IsPlayerConnected(playerid))
	{
		return 0;
	}

	new playerName[MAX_PLAYER_NAME], playerIp[MAX_PLAYER_IP_LENGTH], Float: playerHealth, Float: playerArmor;

	GetPlayerName(playerid, playerName, sizeof playerName);
	GetPlayerIp(playerid, playerIp, sizeof playerIp);
	GetPlayerHealth(playerid, playerHealth);
	GetPlayerArmour(playerid, playerArmor);

	new playerInformation[256 + 64];
	format(playerInformation, sizeof playerInformation,
		"%s (ID: %d) [%s]~n~HP/AR: %.0f/%.0f | Money: %d | Score: %d | Ping: %d~n~Weapons: %s~n~",
		playerName, playerid, playerIp, playerHealth, playerArmor, GetPlayerMoney(playerid), GetPlayerScore(playerid),
		GetPlayerPing(playerid), GetPlayerWeaponList(playerid));

	new keyInformation[32];

	new keys, updown, leftright;
	GetPlayerKeys(playerid, keys, updown, leftright);

	if (IsPlayerInAnyVehicle(playerid))
	{
		keyInformation = GetPlayerVehicleKeyInformation(keys);

		new Float: vehicleHealth;
		GetVehicleHealth(GetPlayerVehicleID(playerid), vehicleHealth);

		new vehicleInformation[VEHICLE_INFORMATION_LENGTH];
		format(vehicleInformation, sizeof vehicleInformation, "VHP: %.4f | Keys: %s (%d)", vehicleHealth, keyInformation, keys);
		strcat(playerInformation, vehicleInformation, sizeof playerInformation);
	}
	else
	{
        keyInformation = GetPlayerOnFootKeyInformation(keys);
		new playerWeaponId = GetPlayerWeapon(playerid);

		new weaponName[MAX_WEAPON_NAME];
		weaponName = GetPlayerWeaponNameAbbreviated(playerWeaponId);

		// GetWeaponName bug fix
		// switch (playerWeaponId)
		// {
			// case WEAPON_MOLTOV: weaponName = "Molotovs";
			// case WEAPON_NIGHT_VISION: weaponName = "Night Vision";
			// case WEAPON_THERMAL_GOGGLES: weaponName = "Infrared Vision";
			// default: weaponName = "Fists";
		// }

		new weaponInformation[WEAPON_INFORMATION_LENGTH];
		format(weaponInformation, sizeof weaponInformation, "Using: %s | Keys: %s (%d)", weaponName, keyInformation, keys);
		strcat(playerInformation, weaponInformation, sizeof playerInformation);
	}

	TextDrawSetString(Text: LiveInfoTD[playerid], playerInformation);

	return 1;
}

stock GetPlayerOnFootKeyInformation(keyId)
{
	new keyInformation[32];

	switch (keyId)
	{
		case 1: keyInformation = "Pressing TAB";
		case 2: keyInformation = "Crouch";
		case 4: keyInformation = "Fire";
		case 6: keyInformation = "Crouch Fire";
		case 8: keyInformation = "Sprint";
		case 10: keyInformation = "Crouch Sprint";
		case 12: keyInformation = "Fire Sprint";
		case 16: keyInformation = "Enter Vehicle";
		case 32: keyInformation = "Jump";
		case 34: keyInformation = "Jump Crouch";
		case 36: keyInformation = "Jump Fire";
		case 40: keyInformation = "Jump Sprint";
		case 44: keyInformation = "Fire Sprint Jump";
		case 128: keyInformation = "Aim";
		case 132: keyInformation = "Aim Fire";
		case 136: keyInformation = "Aim Sprint";
		case 140: keyInformation = "Aim Sprint Fire";
		case 160: keyInformation = "Aim Jump";
		case 164: keyInformation = "Aim Fire Jump";
		case 168: keyInformation = "Aim Sprint Jump";
		case 172: keyInformation = "Aim Fire Sprint Jump";
		case 512: keyInformation = "LookBehind";
		case 514: keyInformation = "LookBehind Crouch";
		case 516: keyInformation = "Fire LookBehind";
		case 520: keyInformation = "Sprint LookBehind";
		case 544: keyInformation = "Jump LookBehind";
		case 640: keyInformation = "Aim LookBehind";
		case 644: keyInformation = "Aim Fire LookBehind";
		case 1024: keyInformation = "Walk";
		case 1028: keyInformation = "Fire Walk";
		case 1056: keyInformation = "Jump Walk";
		case 1152: keyInformation = "Aim Walk";
		case 1156: keyInformation = "Aim Fire Walk";
		case 1536: keyInformation = "Walk LookBehind";
		case 1568: keyInformation = "Walk LookBehind Jump";
		default: keyInformation = "None";
	}
	
	return keyInformation;
}

stock GetPlayerVehicleKeyInformation(keyId)
{
	new keyInformation[32];

	switch (keyId)
	{
		case 1: keyInformation = "Secondary Fire";
		case 2: keyInformation = "Horn";
		case 3: keyInformation = "Horn SecondaryFire";
		case 6: keyInformation = "Horn Fire";
		case 8: keyInformation = "Accelerate";
		case 9: keyInformation = "Accelerate SecondaryFire";
		case 10: keyInformation = "Accelerate Horn";
		case 12: keyInformation = "Accelerate Fire";
		case 16: keyInformation = "Exit Vehicle";
		case 32: keyInformation = "Brake";
		case 33: keyInformation = "Brake SecondaryFire";
		case 34: keyInformation = "Brake Horn";
		case 36: keyInformation = "Brake Fire";
		case 40: keyInformation = "Accelerate Brake";
		case 64: keyInformation = "Look Right";
		case 65: keyInformation = "LookRight SecondaryFire";
		case 66: keyInformation = "LookRight Horn";
		case 72: keyInformation = "LookRight Accelerate";
		case 96: keyInformation = "LookRight Brake";
		case 128: keyInformation = "Handbrake";
		case 129: keyInformation = "HandBrake SecondaryFire";
		case 130: keyInformation = "Handbrake Horn";
		case 131: keyInformation = "HandBrake Horn SecondaryFire";
		case 136: keyInformation = "Handbrake Accelerate";
		case 138: keyInformation = "Handbrake Accelerate Horn";
		case 160: keyInformation = "Handbrake Brake";
		case 192: keyInformation = "LookRight Handbrake";
		case 256: keyInformation = "Look Left";
		case 257: keyInformation = "LookLeft SecondaryFire";
		case 258: keyInformation = "LookLeft Horn";
		case 264: keyInformation = "LookLeft Accelerate";
		case 288: keyInformation = "LookLeft Brake";
		case 320: keyInformation = "Look Behind";
		case 321: keyInformation = "LookBehind SecondaryFire";
		case 322: keyInformation = "LookBehind Horn";
		case 328: keyInformation = "LookBehind Accelerate";
		case 352: keyInformation = "LookLeft LookRight Brake";
		case 384: keyInformation = "LookLeft Handbrake";
		case 448: keyInformation = "LookBehind HandBrake";
		case 456: keyInformation = "LookBehind Accelerate Handbrake";
		default: keyInformation = "None";
	}
	
	return keyInformation;
}



stock GetPlayerWeaponList(playerid)
{
	new counter = 0, weaponId, weaponAmmo, weaponName[MAX_WEAPON_NAME], weaponList[MAX_WEAPON_LIST_LENGTH];

	for (new i = 0; i <= MAX_WEAPON_SLOTS; i++)
	{
		GetPlayerWeaponData(playerid, i, weaponId, weaponAmmo);

	    if (weaponId != 0)
		{
			counter++;

			// set ammo for malee weapons and parachute to 1
	        if (weaponId <= WEAPON_CANE || weaponId == WEAPON_PARACHUTE)
			{
			    weaponAmmo = 1;
		    }

   			weaponName = GetPlayerWeaponNameAbbreviated(weaponId);

   			if (counter == 1)
   			{
				format(weaponList, sizeof weaponList, "%s (%d)", weaponName, weaponAmmo);
			}
   			else
   			{
				format(weaponList, sizeof weaponList, "%s, %s (%d)", weaponList, weaponName, weaponAmmo);
			}
		}
	}

	if (counter == 0)
	{
	    weaponList = "Unarmed";
	}
	
	return weaponList;
}

stock GetPlayerWeaponNameAbbreviated(weaponId)
{
	new weaponName[MAX_WEAPON_NAME];

	GetWeaponName(weaponId, weaponName, sizeof weaponName);

	// Credits to [NoV]Pops for the abbreviations
	switch (weaponId)
	{
		case WEAPON_BRASSKNUCKLE: weaponName = "Knkls";
		case WEAPON_GOLFCLUB: weaponName = "Golf";
		case WEAPON_NITESTICK: weaponName = "nStick";
		case WEAPON_KNIFE: weaponName = "Knife";
		case WEAPON_BAT: weaponName = "Bat";
		case WEAPON_SHOVEL: weaponName = "Shovl";
		case WEAPON_POOLSTICK: weaponName = "pStick";
		case WEAPON_KATANA: weaponName = "Katna";
		case WEAPON_CHAINSAW: weaponName = "Chain";
		case WEAPON_DILDO: weaponName = "Dildo";
		case WEAPON_DILDO2: weaponName = "sDildo";
		case WEAPON_VIBRATOR: weaponName = "LVib";
		case WEAPON_VIBRATOR2: weaponName = "SilvVib";
		case WEAPON_FLOWER: weaponName = "Flowr";
		case WEAPON_CANE: weaponName = "Cane";
		case WEAPON_GRENADE: weaponName = "Nade";
		case WEAPON_TEARGAS: weaponName = "TrGas";
		case WEAPON_MOLTOV: weaponName = "Molly";
		case WEAPON_COLT45: weaponName = "9mm";
		case WEAPON_SILENCED: weaponName = "Slcnd";
		case WEAPON_DEAGLE: weaponName = "Eagle";
		case WEAPON_SHOTGUN: weaponName = "Shoty";
		case WEAPON_SAWEDOFF: weaponName = "Sawns";
		case WEAPON_SHOTGSPA: weaponName = "Spas";
		case WEAPON_UZI: weaponName = "UZI";
		case WEAPON_MP5: weaponName = "MP5";
		case WEAPON_AK47: weaponName = "AK47";
		case WEAPON_M4: weaponName = "M4";
		case WEAPON_TEC9: weaponName = "Tec9";
		case WEAPON_RIFLE: weaponName = "Rifle";
		case WEAPON_SNIPER: weaponName = "Snipe";
		case WEAPON_ROCKETLAUNCHER: weaponName = "Rockt";
		case WEAPON_HEATSEEKER: weaponName = "Seekr";
		case WEAPON_FLAMETHROWER: weaponName = "Flame";
		case WEAPON_MINIGUN: weaponName = "Mnign";
		case WEAPON_SATCHEL: weaponName = "Stchl";
		case WEAPON_BOMB: weaponName = "Dtntr";
		case WEAPON_SPRAYCAN: weaponName = "Spray";
		case WEAPON_FIREEXTINGUISHER: weaponName = "Extin";
		case WEAPON_CAMERA: weaponName = "Camra";
		case WEAPON_PARACHUTE: weaponName = "Chute";
		case WEAPON_NIGHT_VISION: weaponName = "Nite visn";
		case WEAPON_THERMAL_GOGGLES: weaponName = "Thrml goggl";
		default: weaponName = "Fists";
	}
	
	return weaponName;
}

