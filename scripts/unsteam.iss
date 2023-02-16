; Purpose: Removes the Steam fileredirects

function main()
{
	echo "[\arUn\ax\aysteam\ax] Removing Steam fileredirects."

	squelch fileredirect -remove "Global/Valve_SteamIPC_Class"
	squelch fileredirect -remove "Global/SteamInstanceGlobal"
	if ${InnerSpace.Build}>=6380
	{
		squelch fileredirect -remove "STEAM_DIPC_*"
		squelch fileredirect -remove "SREAM_DIPC_*"
		squelch fileredirect -remove "STEAM_DRM_IPC"
		squelch fileredirect -remove "SteamOverlayRunning_*"
		squelch fileredirect -remove "Steam3Master_*"
	}
	squelch fileredirect -remove "Software/Valve/Steam/"
}
