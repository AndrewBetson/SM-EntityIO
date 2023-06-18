// Copyright Andrew Betson.
// SPDX-License-Identifier: AGPL-3.0-or-later

#include <sourcemod>
#include <sdktools>

#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "[Any] Entity IO",
	description	= "Allows server staff to mess with entity IO.",
	author		= "Andrew \"andrewb\" Betson",
	version		= "1.0.0",
	url			= "https://www.github.com/AndrewBetson/SM-EntityIO/"
};

public void OnPluginStart()
{
	LoadTranslations( "common.phrases" );
	LoadTranslations( "entityio.phrases" );

	RegAdminCmd( "sm_eio_input", Cmd_EIO_Input, ADMFLAG_CONFIG, "Execute an input on an entity by name, classname, or Hammer ID; optionally with an int/float/vector/color parameter." );
	RegAdminCmd( "sm_eio_output", Cmd_EIO_Output, ADMFLAG_CONFIG, "Fire an output on an entity by name, classname, or Hammer ID; optionally with a delay and/or int/float/vector/color parameter." );
}

public Action Cmd_EIO_Input( int nClientIdx, int nNumArgs )
{
	if ( nClientIdx != 0 && ( !IsClientInGame( nClientIdx ) || !IsClientConnected( nClientIdx ) ) )
	{
		return Plugin_Handled;
	}

	char szSearchType[ 9 ];
	GetCmdArg( 1, szSearchType, sizeof( szSearchType ) );

	if ( strcmp( szSearchType, "name", false ) == 0 )
	{
		return DoInputByName( nClientIdx, nNumArgs );
	}
	else if ( strcmp( szSearchType, "class", false ) == 0 )
	{
		return DoInputByClass( nClientIdx, nNumArgs );
	}
	else if ( strcmp( szSearchType, "hammerid", false ) == 0 )
	{
		return DoInputByHammerID( nClientIdx, nNumArgs );
	}

	CPrintToChat( nClientIdx, "%t", "EIO_InputUsage" );
	return Plugin_Handled;
}

public Action Cmd_EIO_Output( int nClientIdx, int nNumArgs )
{
	if ( nClientIdx != 0 && ( !IsClientInGame( nClientIdx ) || !IsClientConnected( nClientIdx ) ) )
	{
		return Plugin_Handled;
	}

	char szSearchType[ 9 ];
	GetCmdArg( 1, szSearchType, sizeof( szSearchType ) );

	if ( strcmp( szSearchType, "name", false ) == 0 )
	{
		return DoOutputByName( nClientIdx, nNumArgs );
	}
	else if ( strcmp( szSearchType, "class", false ) == 0 )
	{
		return DoOutputByClass( nClientIdx, nNumArgs );
	}
	else if ( strcmp( szSearchType, "hammerid", false ) == 0 )
	{
		return DoOutputByHammerID( nClientIdx, nNumArgs );
	}

	CPrintToChat( nClientIdx, "%t", "EIO_OutputUsage" );
	return Plugin_Handled;
}

Action DoInputByName( int nClientIdx, int nNumArgs )
{
	if ( nNumArgs < 3 || nNumArgs > 7 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_InputUsage_ByName" );
		return Plugin_Handled;
	}

	char szEntityName[ 64 ];
	GetCmdArg( 2, szEntityName, sizeof( szEntityName ) );

	int nEntityIdx = -1;

	int nNumEntities = GetEntityCount();
	while ( nNumEntities --> 0 )
	{
		if ( !IsValidEntity( nNumEntities ) )
		{
			continue;
		}

		char szCurrentEntityName[ 64 ];
		GetEntPropString( nNumEntities, Prop_Data, "m_iName", szCurrentEntityName, sizeof( szCurrentEntityName ) );

		if ( strcmp( szEntityName, szCurrentEntityName, false ) == 0 )
		{
			nEntityIdx = nNumEntities;
			break;
		}
	}

	if ( nEntityIdx == -1 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_CouldntFindEntity", szEntityName );
		return Plugin_Handled;
	}

	char szInputName[ 64 ];
	GetCmdArg( 3, szInputName, sizeof( szInputName ) );

	switch ( nNumArgs )
	{
		case 4:
		{
			char szValue[ 64 ];
			GetCmdArg( 4, szValue, sizeof( szValue ) );

			SetGlobalVariant_OneParam( szValue );
		}
		case 6:
		{
			char X[ 8 ], Y[ 8 ], Z[ 8 ];
			GetCmdArg( 4, X, sizeof( X ) );
			GetCmdArg( 5, Y, sizeof( Y ) );
			GetCmdArg( 6, Z, sizeof( Z ) );

			SetGlobalVariant_ThreeParams( X, Y, Z );
		}
		case 7:
		{
			char R[ 4 ], G[ 4 ], B[ 4 ], A[ 4 ];
			GetCmdArg( 4, R, sizeof( R ) );
			GetCmdArg( 5, G, sizeof( G ) );
			GetCmdArg( 6, B, sizeof( G ) );
			GetCmdArg( 7, A, sizeof( A ) );

			SetGlobalVariant_FourParams( R, G, B, A );
		}
	}

	AcceptEntityInput( nEntityIdx, szInputName );

	return Plugin_Handled;
}

Action DoInputByClass( int nClientIdx, int nNumArgs )
{
	if ( nNumArgs < 4 || nNumArgs > 8 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_InputUsage_ByClass" );
		return Plugin_Handled;
	}

	char szClassname[ 64 ];
	GetCmdArg( 2, szClassname, sizeof( szClassname ) );

	char szAllOrFirst[ 8 ];
	GetCmdArg( 3, szAllOrFirst, sizeof( szAllOrFirst ) );

	bool bAll;
	if ( strcmp( szAllOrFirst, "all", false ) == 0 )
	{
		bAll = true;
	}
	else if ( strcmp( szAllOrFirst, "first", false ) == 0 )
	{
		bAll = false;
	}
	else
	{
		CPrintToChat( nClientIdx, "%t", "EIO_InputUsage_ByClass" );
		return Plugin_Handled;
	}

	int nEntityIterator = -1;
	ArrayList hEntities = new ArrayList();
	if ( bAll )
	{
		while ( ( nEntityIterator = FindEntityByClassname( nEntityIterator, szClassname ) ) != -1 )
		{
			hEntities.Push( nEntityIterator );
		}
	}
	else
	{
		nEntityIterator = FindEntityByClassname( nEntityIterator, szClassname );
		if ( nEntityIterator == -1 )
		{
			CPrintToChat( nClientIdx, "%t", "EIO_CouldntFindClass", szClassname );
			return Plugin_Handled;
		}

		hEntities.Push( nEntityIterator );
	}

	if ( hEntities.Length == 0 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_CouldntFindClass", szClassname );
		return Plugin_Handled;
	}

	char szInputName[ 64 ];
	GetCmdArg( 4, szInputName, sizeof( szInputName ) );

	for ( int i = 0; i < hEntities.Length; i++ )
	{
		// We have to set the global variants value for each entity
		// because calling AcceptEntityInput resets it.
		switch ( nNumArgs )
		{
			case 5:
			{
				char szValue[ 64 ];
				GetCmdArg( 5, szValue, sizeof( szValue ) );

				SetGlobalVariant_OneParam( szValue );
			}
			case 7:
			{
				char X[ 8 ], Y[ 8 ], Z[ 8 ];
				GetCmdArg( 5, X, sizeof( X ) );
				GetCmdArg( 6, Y, sizeof( Y ) );
				GetCmdArg( 7, Z, sizeof( Z ) );

				SetGlobalVariant_ThreeParams( X, Y, Z );
			}
			case 8:
			{
				char R[ 4 ], G[ 4 ], B[ 4 ], A[ 4 ];
				GetCmdArg( 5, R, sizeof( R ) );
				GetCmdArg( 6, G, sizeof( G ) );
				GetCmdArg( 7, B, sizeof( B ) );
				GetCmdArg( 8, A, sizeof( A ) );

				SetGlobalVariant_FourParams( R, G, B, A );
			}
		}

		AcceptEntityInput( hEntities.Get( i ), szInputName );
	}

	return Plugin_Handled;
}

Action DoInputByHammerID( int nClientIdx, int nNumArgs )
{
	if ( nNumArgs < 3 || nNumArgs > 7 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_InputUsage_ByHammerID" );
		return Plugin_Handled;
	}

	char szHammerID[ 9 ];
	GetCmdArg( 2, szHammerID, sizeof( szHammerID ) );

	int nHammerID;
	if ( StringToIntEx( szHammerID, nHammerID ) != strlen( szHammerID ) )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_HammerIDMustBeNumber", szHammerID );
		return Plugin_Handled;
	}

	int nEntityIdx = -1;

	int nNumEntities = GetEntityCount();
	while ( nNumEntities --> 0 )
	{
		if ( !IsValidEntity( nNumEntities ) )
		{
			continue;
		}

		if ( GetEntProp( nNumEntities, Prop_Data, "m_iHammerID" ) == nHammerID )
		{
			nEntityIdx = nNumEntities;
			break;
		}
	}

	if ( nEntityIdx == -1 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_CouldntFindHammerID", nHammerID );
		return Plugin_Handled;
	}

	char szInputName[ 64 ];
	GetCmdArg( 3, szInputName, sizeof( szInputName ) );

	switch ( nNumArgs )
	{
		case 4:
		{
			char szValue[ 64 ];
			GetCmdArg( 4, szValue, sizeof( szValue ) );

			SetGlobalVariant_OneParam( szValue );
		}
		case 6:
		{
			char X[ 8 ], Y[ 8 ], Z[ 8 ];
			GetCmdArg( 4, X, sizeof( X ) );
			GetCmdArg( 5, Y, sizeof( Y ) );
			GetCmdArg( 6, Z, sizeof( Z ) );

			SetGlobalVariant_ThreeParams( X, Y, Z );
		}
		case 7:
		{
			char R[ 4 ], G[ 4 ], B[ 4 ], A[ 4 ];
			GetCmdArg( 4, R, sizeof( R ) );
			GetCmdArg( 5, G, sizeof( G ) );
			GetCmdArg( 6, B, sizeof( G ) );
			GetCmdArg( 7, A, sizeof( A ) );

			SetGlobalVariant_FourParams( R, G, B, A );
		}
	}

	AcceptEntityInput( nEntityIdx, szInputName );

	return Plugin_Handled;
}

Action DoOutputByName( int nClientIdx, int nNumArgs )
{
	if ( nNumArgs < 3 || nNumArgs > 8 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_OutputUsage_ByName" );
		return Plugin_Handled;
	}

	char szEntityName[ 64 ];
	GetCmdArg( 2, szEntityName, sizeof( szEntityName ) );

	int nEntityIdx = -1;

	int nNumEntities = GetEntityCount();
	while ( nNumEntities --> 0 )
	{
		if ( !IsValidEntity( nNumEntities ) )
		{
			continue;
		}

		char szCurrentEntityName[ 64 ];
		GetEntPropString( nNumEntities, Prop_Data, "m_iName", szCurrentEntityName, sizeof( szCurrentEntityName ) );

		if ( strcmp( szEntityName, szCurrentEntityName, false ) == 0 )
		{
			nEntityIdx = nNumEntities;
			break;
		}
	}

	if ( nEntityIdx == -1 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_CouldntFindEntity", szEntityName );
		return Plugin_Handled;
	}

	char szOutputName[ 64 ];
	GetCmdArg( 3, szOutputName, sizeof( szOutputName ) );

	float flDelay = 0.0;
	if ( nNumArgs >= 4 )
	{
		char szDelay[ 8 ];
		GetCmdArg( 4, szDelay, sizeof( szDelay ) );

		flDelay = StringToFloat( szDelay );
	}

	switch ( nNumArgs )
	{
		case 5:
		{
			char szValue[ 64 ];
			GetCmdArg( 5, szValue, sizeof( szValue ) );

			SetGlobalVariant_OneParam( szValue );
		}
		case 7:
		{
			char X[ 8 ], Y[ 8 ], Z[ 8 ];
			GetCmdArg( 5, X, sizeof( X ) );
			GetCmdArg( 6, Y, sizeof( Y ) );
			GetCmdArg( 7, Z, sizeof( Z ) );

			SetGlobalVariant_ThreeParams( X, Y, Z );
		}
		case 8:
		{
			char R[ 4 ], G[ 4 ], B[ 4 ], A[ 4 ];
			GetCmdArg( 5, R, sizeof( R ) );
			GetCmdArg( 6, G, sizeof( G ) );
			GetCmdArg( 7, B, sizeof( G ) );
			GetCmdArg( 8, A, sizeof( A ) );

			SetGlobalVariant_FourParams( R, G, B, A );
		}
	}

	FireEntityOutput( nEntityIdx, szOutputName, -1, flDelay );

	return Plugin_Handled;
}

Action DoOutputByClass( int nClientIdx, int nNumArgs )
{
	if ( nNumArgs < 3 || nNumArgs > 9 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_OutputUsage_ByClass" );
		return Plugin_Handled;
	}

	char szClassname[ 64 ];
	GetCmdArg( 2, szClassname, sizeof( szClassname ) );

	char szAllOrFirst[ 8 ];
	GetCmdArg( 3, szAllOrFirst, sizeof( szAllOrFirst ) );

	bool bAll;
	if ( strcmp( szAllOrFirst, "all", false ) == 0 )
	{
		bAll = true;
	}
	else if ( strcmp( szAllOrFirst, "first", false ) == 0 )
	{
		bAll = false;
	}
	else
	{
		CPrintToChat( nClientIdx, "%t", "EIO_OutputUsage_ByClass" );
		return Plugin_Handled;
	}

	int nEntityIterator = -1;
	ArrayList hEntities = new ArrayList();
	if ( bAll )
	{
		while ( ( nEntityIterator = FindEntityByClassname( nEntityIterator, szClassname ) ) != -1 )
		{
			if ( nEntityIterator <= -1 )
			{
				continue;
			}

			hEntities.Push( nEntityIterator );
		}
	}
	else
	{
		nEntityIterator = FindEntityByClassname( nEntityIterator, szClassname );
		if ( nEntityIterator <= -1 )
		{
			CPrintToChat( nClientIdx, "%t", "EIO_CouldntFindClass", szClassname );
			return Plugin_Handled;
		}

		hEntities.Push( nEntityIterator );
	}

	if ( hEntities.Length == 0 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_CouldntFindClass", szClassname );
		return Plugin_Handled;
	}

	char szOutputName[ 64 ];
	GetCmdArg( 4, szOutputName, sizeof( szOutputName ) );

	float flDelay = 0.0;
	if ( nNumArgs >= 5 )
	{
		char szDelay[ 8 ];
		GetCmdArg( 5, szDelay, sizeof( szDelay ) );

		flDelay = StringToFloat( szDelay );
	}

	for ( int i = 0; i < hEntities.Length; i++ )
	{
		switch ( nNumArgs )
		{
			case 6:
			{
				char szValue[ 64 ];
				GetCmdArg( 6, szValue, sizeof( szValue ) );

				SetGlobalVariant_OneParam( szValue );
			}
			case 8:
			{
				char X[ 8 ], Y[ 8 ], Z[ 8 ];
				GetCmdArg( 6, X, sizeof( X ) );
				GetCmdArg( 7, Y, sizeof( Y ) );
				GetCmdArg( 8, Z, sizeof( Z ) );

				SetGlobalVariant_ThreeParams( X, Y, Z );
			}
			case 9:
			{
				char R[ 4 ], G[ 4 ], B[ 4 ], A[ 4 ];
				GetCmdArg( 6, R, sizeof( R ) );
				GetCmdArg( 7, G, sizeof( G ) );
				GetCmdArg( 8, B, sizeof( B ) );
				GetCmdArg( 9, A, sizeof( A ) );

				SetGlobalVariant_FourParams( R, G, B, A );
			}
		}

		FireEntityOutput( hEntities.Get( i ), szOutputName, -1, flDelay );
	}

	return Plugin_Handled;
}

Action DoOutputByHammerID( int nClientIdx, int nNumArgs )
{
	if ( nNumArgs < 3 || nNumArgs > 8 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_OutputUsage_ByHammerID" );
		return Plugin_Handled;
	}

	char szHammerID[ 9 ];
	GetCmdArg( 2, szHammerID, sizeof( szHammerID ) );

	int nHammerID;
	if ( StringToIntEx( szHammerID, nHammerID ) != strlen( szHammerID ) )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_HammerIDMustBeNumber", szHammerID );
		return Plugin_Handled;
	}

	int nEntityIdx = -1;

	int nNumEntities = GetEntityCount();
	while ( nNumEntities --> 0 )
	{
		if ( !IsValidEntity( nNumEntities ) )
		{
			continue;
		}

		if ( GetEntProp( nNumEntities, Prop_Data, "m_iHammerID" ) == nHammerID )
		{
			nEntityIdx = nNumEntities;
			break;
		}
	}

	if ( nEntityIdx == -1 )
	{
		CPrintToChat( nClientIdx, "%t", "EIO_CouldntFindHammerID", szHammerID );
		return Plugin_Handled;
	}

	char szOutputName[ 64 ];
	GetCmdArg( 3, szOutputName, sizeof( szOutputName ) );

	float flDelay = 0.0;
	if ( nNumArgs >= 4 )
	{
		char szDelay[ 8 ];
		GetCmdArg( 4, szDelay, sizeof( szDelay ) );

		flDelay = StringToFloat( szDelay );
	}

	switch ( nNumArgs )
	{
		case 5:
		{
			char szValue[ 64 ];
			GetCmdArg( 5, szValue, sizeof( szValue ) );

			SetGlobalVariant_OneParam( szValue );
		}
		case 7:
		{
			char X[ 8 ], Y[ 8 ], Z[ 8 ];
			GetCmdArg( 5, X, sizeof( X ) );
			GetCmdArg( 6, Y, sizeof( Y ) );
			GetCmdArg( 7, Z, sizeof( Z ) );

			SetGlobalVariant_ThreeParams( X, Y, Z );
		}
		case 8:
		{
			char R[ 4 ], G[ 4 ], B[ 4 ], A[ 4 ];
			GetCmdArg( 5, R, sizeof( R ) );
			GetCmdArg( 6, G, sizeof( G ) );
			GetCmdArg( 7, B, sizeof( G ) );
			GetCmdArg( 8, A, sizeof( A ) );

			SetGlobalVariant_FourParams( R, G, B, A );
		}
	}

	FireEntityOutput( nEntityIdx, szOutputName, -1, flDelay );

	return Plugin_Handled;
}

void SetGlobalVariant_OneParam( const char[] szValue )
{
	if ( StrContains( szValue, "." ) != -1 )
	{
		float flValue;

		// The param could be a string that happens to have
		// a "." in it, so if the converted float was derived
		// from any less than all characters in the param value,
		// treat it as a string.
		if ( StringToFloatEx( szValue, flValue ) != strlen( szValue ) )
		{
			SetVariantString( szValue );
		}
		else
		{
			SetVariantFloat( flValue );
		}
	}
	else
	{
		int nValue;

		// Similar rationale to the float case above.
		if ( StringToIntEx( szValue, nValue ) != strlen( szValue ) )
		{
			SetVariantString( szValue );
		}
		else
		{
			SetVariantInt( nValue );
		}
	}
}

void SetGlobalVariant_ThreeParams( const char[] X, const char[] Y, const char[] Z )
{
	float vValue[ 3 ];

	vValue[ 0 ] = StringToFloat( X );
	vValue[ 1 ] = StringToFloat( Y );
	vValue[ 2 ] = StringToFloat( Z );

	// Don't know what the difference between this and
	// SetVariantPosVector3D is, so I'll just use this I guess...
	SetVariantVector3D( vValue );
}

void SetGlobalVariant_FourParams( const char[] R, const char[] G, const char[] B, const char[] A )
{
	int vValue[ 4 ];

	vValue[ 0 ] = StringToInt( R );
	vValue[ 1 ] = StringToInt( G );
	vValue[ 2 ] = StringToInt( B );
	vValue[ 3 ] = StringToInt( A );

	SetVariantColor( vValue );
}
