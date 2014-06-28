private ["_part_out","_part_in","_qty_out","_qty_in","_qty","_buy_o_sell","_textPartIn","_textPartOut","_needed","_started","_finished","_animState","_isMedic","_total_parts_out","_abort","_removed","_tradeCounter","_next_highest_bar","_third_highest_bar","_next_highest_conv","_third_highest_conv","_third_parts_out_raw","_third_parts_out","_remainder","_next_parts_out_raw","_next_parts_out","_activatingPlayer","_traderID","_total_trades"];

if(DZE_ActionInProgress) exitWith { cutText ["Trade already in progress." , "PLAIN DOWN"]; };
DZE_ActionInProgress = true;

// Test cannot lock while another player is nearby
//_playerNear = {isPlayer _x} count (player nearEntities ["CAManBase", 12]) > 1;
//if(_playerNear) exitWith { DZE_ActionInProgress = false; cutText ["Cannot trade while another player is nearby." , "PLAIN DOWN"];  };


_finish_trade = {
	{player removeAction _x} forEach s_player_parts;s_player_parts = [];
	s_player_parts_crtl = -1;
	DZE_ActionInProgress = false;
	dayzTradeResult = nil;
};

_name = _this select 0;
_textPart = _this select 1;
_price = _this select 2;
_traderID = _this select 3;
_activatingPlayer = player;
_player_headShots = _activatingPlayer getVariable ["headShots",0];

_qty = {_x == _name} count magazines player;

_removed = 0;
_tradeCounter = 0;

_total_trades = _qty;
if (_total_trades < 1) exitWith {
	cutText [format["You do not have a %1", _textPart], "PLAIN DOWN"];
	call _finish_trade;
};

_abort = false;

// perform number of total trades
for "_x" from 1 to _total_trades do {
	_tradeCounter = _tradeCounter + 1;

	// cutText ["Starting trade, stand still to complete.", "PLAIN DOWN"];
	if(_total_trades == 1) then { 
		cutText [format["Starting trade, stand still to complete trade.",_tradeCounter,_total_trades] , "PLAIN DOWN"];
	} else {
		cutText [format["Starting trade, stand still to complete trade %1 of %2.",_tradeCounter,_total_trades] , "PLAIN DOWN"];
	};
	player playActionNow "Medic";

	r_interrupt = false;
	_animState = animationState player;
	r_doLoop = true;
	_started = false;
	_finished = false;
	
	while {r_doLoop} do {
		_animState = animationState player;
		_isMedic = ["medic",_animState] call fnc_inString;
		if (_isMedic) then {
			_started = true;
		};
		if (_started and !_isMedic) then {
			r_doLoop = false;
			_finished = true;
		};
		if (r_interrupt) then {
			r_doLoop = false;
		};
		sleep 0.1;
	};
	r_doLoop = false;

	if (!_finished) exitWith { 
		r_interrupt = false;
		if (vehicle player == player) then {
			[objNull, player, rSwitchMove,""] call RE;
			player playActionNow "stop";
		};
		cutText ["Cancelled Trade." , "PLAIN DOWN"];
	};

	if (_finished) then {
		_removed = [_activatingPlayer,_name,1] call BIS_fnc_invRemove;
		if (_removed > 0) then {
			_player_headShots = _activatingPlayer getVariable ["headShots",0];
			/*PVDZE_obj_Trade = [_activatingPlayer,_traderID,1];
			publicVariableServer  "PVDZE_obj_Trade";
			waitUntil {!isNil "dayzTradeResult"};
			if(dayzTradeResult == "PASS") then {*/
				_activatingPlayer setVariable["headShots",(_player_headShots + _price),true];
				cutText [format[("Traded %1 for %2 %3"),_textPart,_price,"Coins"], "PLAIN DOWN"];
				PVDZE_plr_Save = [_activatingPlayer,(magazines _activatingPlayer),true,true] ;
publicVariableServer "PVDZE_plr_Save";
			//} else {
			//	cutText ["Something went wrong with hive", "PLAIN DOWN"];
			//	_abort = true;
			//	player addMagazine _name;
			//};
		} else {
			cutText [format["Something went wrong. Could not remove %1 from inventory", _name], "PLAIN DOWN"];
			_abort = true;
		};
	};
	sleep 1;

	if(_abort) exitWith {};
};
DZE_ActionInProgress = false;

_cid =	player getVariable ["CharacterID","0"];
_headShotsZupa = player getVariable ["headShots",0];
_key = format["CHILD:999:UPDATE `character_data` SET `HeadshotsZ` = %1 WHERE `CharacterID` = %2:[0]:",_headShotsZupa,_cid];
_result = _key call server_hiveReadWrite;