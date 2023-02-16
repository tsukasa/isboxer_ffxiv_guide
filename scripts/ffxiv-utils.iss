objectdef ffxivUtils
{
    ; * ------------- *
    ; * Configuration *
    ; * ------------- * =======================================================

    ; Inject Dalamud into the game? [Default: TRUE]
    variable bool     injectDalamud           = TRUE

    ; Replace ImGuiScene.dll with a patched copy to fix the input handling when
    ; used with Inner Space? [Default: TRUE]
    variable bool     replaceImGuiSceneDll    = FALSE

    ; Inject Dalamud via the external injector? [Default: FALSE]
    variable bool     useDalamudInjector      = FALSE

    ; Language to use for Dalamud. [Default: English]
    variable string   dalamudLanguage         = "English"

    ; Delay in ms between the game starting and injection. [Default: 500]
    variable int      dalamudInjectionDelayMs = 500



    ; TESTING ONLY: Inject ReShade into the game? [Default: FALSE]
    ; This currently causes issues with the game, so it's disabled by default.
    variable bool     injectReshade           = FALSE

    ; * -------------------------- *
    ; * Internal control variables *
    ; * -------------------------- * ==========================================

    ; EasyBoot repository: https://github.com/LaxLacks/Dalamud
    variable string   dmEasyBootDllName       = "Dalamud.EasyBoot.dll"

    ; Patched ImGuiScene repository: https://github.com/tsukasa/ImGuiScene
    variable string   imGuiSceneDllName       = "ImGuiScene.dll"

    variable string   reshadeDllName          = "ReShade64.dll"

    variable int      minBuildVersion         = 6922

    ; * --------------- *
    ; * Internal caches *
    ; * --------------- * =====================================================

    variable string   c_gameVersion
    variable string   c_dalamudGameVersion
    variable string   c_dalamudAssetsVersion

    variable filepath xlAppDataPath
    variable filepath dmPath


    ; =========================================================================
    ; Members
    ; =========================================================================

    member:bool CanRunDalamud()
    {
        variable string localGameVersion
        variable string dalamudSupportedGameVer

        localGameVersion:Set[${This.GetGameVersion}]
        dalamudSupportedGameVer:Set[${This.GetDalamudSupportedGameVersion}]

        return ${localGameVersion.Equals[${dalamudSupportedGameVer}]}
    }

    member:string GetDalamudAssetsVersion()
    {
        variable file   assetsVersionFile
        variable string assetsVersion

        if ${c_dalamudAssetsVersion.NotNULLOrEmpty}
        {
            return ${c_dalamudAssetsVersion}
        }

        assetsVersionFile:SetFilename["${xlAppDataPath.AbsolutePath}/dalamudAssets/asset.ver"]
        assetsVersionFile:Open[readonly]

        if ${assetsVersionFile.Open}
        {
            assetsVersion:Set[${assetsVersionFile.Read}]
            assetsVersion:Set[${assetsVersion.Trim}]
            assetsVersionFile:Close
            This:Echo["Dalamud Assets Version: ${assetsVersion~}"]
        }
        else
        {
            This:Echo["Error: Could not determine Dalamud Assets version. Falling back to dev..."]
            assetsVersion:Set["dev"]
        }

        c_dalamudAssetsVersion:Set[${assetsVersion}]
        return ${assetsVersion~}
    }

    member:string GetDalamudSupportedGameVersion()
    {
        variable jsonvalue localVersionJson
        variable string    dalamudGameVersion
        variable string    jsonKeyName = "SupportedGameVer"

        if ${c_dalamudGameVersion.NotNULLOrEmpty}
        {
            return ${c_dalamudGameVersion}
        }

        if ${dmPath.FileExists["version.json"]}
        {
            localVersionJson:ParseFile["${dmPath.AbsolutePath~}/version.json"]

            if ${localVersionJson.Has[${jsonKeyName}]}
            {
                dalamudGameVersion:Set[${localVersionJson.Get[${jsonKeyName}]~}]
                dalamudGameVersion:Set[${dalamudGameVersion.Trim}]
            }
            else
            {
                This:Echo["Error: Dalamud version.json is missing the ${jsonKeyName} key, this script might need an update."]
                dalamudGameVersion:Set["MISSING_${jsonKeyName.Upper}_IN_JSON"]
            }
        }
        else
        {
            This:Echo["Error: version.json not present in Dalamud path \"${dmPath.Path~}\"."]
            dalamudGameVersion:Set["MISSING_DALAMUD_VERSION"]
        }

        c_dalamudGameVersion:Set[${dalamudGameVersion~}]

        return ${dalamudGameVersion~}
    }

    member:string GetGameVersion()
    {
        variable file   gameExecutable
        variable file   gameVersionFile
        variable string gameVersion

        if ${c_gameVersion.NotNULLOrEmpty}
        {
            return ${c_gameVersion}
        }

        gameExecutable:SetFilename[${LavishScript.Executable.AbsolutePath}]
        gameVersionFile:SetFilename[${gameExecutable.Path.Escape}/ffxivgame.ver]

        gameVersionFile:Open[readonly]

        if ${gameVersionFile.Open}
        {
            gameVersion:Set[${gameVersionFile.Read}]
            gameVersion:Set[${gameVersion.Trim}]
            gameVersionFile:Close
        }
        else
        {
            This:Echo["Error: Could not determine Game version from ffxivgame.ver."]
            gameVersion:Set["MISSING_GAME_VERSION"]
        }

        c_gameVersion:Set[${gameVersion~}]

        return ${gameVersion~}
    }

    member:int GetInjectionDelayMs()
    {
        variable int injectionDelayMs=100

        ; Sort out undesirable values like -10 and alike.
        if ${dalamudInjectionDelayMs} >= 0
        {
            injectionDelayMs:Set[${dalamudInjectionDelayMs}]
        }

        return ${injectionDelayMs}
    }

    member:int GetIntForLanguage(string languageName)
    {
        variable int targetLanguageNum

        switch ${languageName}
        {
            case Japanese
                targetLanguageNum:Set[0]
                break
            case English
                targetLanguageNum:Set[1]
                break
            case German
                targetLanguageNum:Set[2]
                break
            case French
                targetLanguageNum:Set[3]
                break
            default
                targetLanguageNum:Set[1]
                This:Echo["Warning: Returning fallback language ${targetLanguageNum}, unknown input language was specified: ${languageName}"]
                This:Echo["Warning: Valid language values are: Japanese, English, German, French"]
                break
        }

        return ${targetLanguageNum}
    }


    ; ========================================================================
    ; Methods
    ; ========================================================================

    method Echo(string message)
    {
        echo [FFXIV Utils][${Time.Time24}] ${message~}
    }

    method ResetDalamudAssetsVersionCache()
    {
        This:Echo["Resetting Dalamud Assets version cache."]
        c_dalamudAssetsVersion:Set[]
    }

    method ResetDalamudSupportedGameVersionCache()
    {
        This:Echo["Resetting Dalamud supported game version cache."]
        c_dalamudGameVersion:Set[]
    }

    method ResetGameVersionCache()
    {
        This:Echo["Resetting Game version cache."]
        c_gameVersion:Set[]
    }

    method SetDalamudStartupInfo(string xlAppDataPath)
    {
        ; DALAMUD_STARTUP_INFO
        variable jsonvalue joDalamud = "{}"
        variable jsonvalue joTroubleDataPack = "{}"

        ; Strings
        joDalamud:SetString["AssetDirectory", "${xlAppDataPath.Replace[/,"\\"]~}\\dalamudAssets\\${This.GetDalamudAssetsVersion}"]
        joDalamud:SetString["BootLogPath", "${xlAppDataPath.Replace[/,"\\"]~}\\dalamud.boot.log"]
        joDalamud:SetString["ConfigurationPath", "${xlAppDataPath.Replace[/,"\\"]~}\\dalamudConfig.json"]
        joDalamud:SetString["DefaultPluginDirectory", "${xlAppDataPath.Replace[/,"\\"]~}\\devPlugins"]
        joDalamud:SetString["GameVersion", "${This.GetGameVersion}"]
        joDalamud:SetString["PluginDirectory", "${xlAppDataPath.Replace[/,"\\"]~}\\installedPlugins"]
        joDalamud:SetString["WorkingDirectory", "${dmPath.AbsolutePath.Replace[/,"\\"]~}"]

        ; Integers
        joDalamud:SetInteger["BootDotnetOpenProcessHookMode", 0]
        joDalamud:SetInteger["BootWaitMessageBox", 0]
        joDalamud:SetInteger["DelayInitializeMs", ${This.GetInjectionDelayMs}]
        joDalamud:SetInteger["Language", ${This.GetIntForLanguage[${dalamudLanguage}]}]

        ; Booleans
        joDalamud:SetBool["BootDisableFallbackConsole", FALSE]
        joDalamud:SetBool["BootEnableEtw", FALSE]
        joDalamud:SetBool["BootShowConsole", FALSE]
        joDalamud:SetBool["BootVehEnabled", TRUE]
        joDalamud:SetBool["BootVehFull", FALSE]
        joDalamud:SetBool["BootWaitDebugger", FALSE]
        joDalamud:SetBool["NoLoadPlugins", FALSE]
        joDalamud:SetBool["NoLoadThirdPartyPlugins", FALSE]

        ; TroubleshootingPackData nested object as string
        joTroubleDataPack:SetBool["empty", TRUE]
        joTroubleDataPack:SetString["description", "No troubleshooting data supplied."]
        joDalamud:SetString["TroubleshootingPackData", "${joTroubleDataPack.AsJSON~}"]

        ; BootUnhookDlls array of strings
        joDalamud:Set["BootUnhookDlls", "[]"]

        ; BootEnabledGameFixes array of strings
        joDalamud:Set["BootEnabledGameFixes", "[]"]
        joDalamud["BootEnabledGameFixes"]:AddString["prevent_devicechange_crashes"]
        joDalamud["BootEnabledGameFixes"]:AddString["disable_game_openprocess_access_check"]
        joDalamud["BootEnabledGameFixes"]:AddString["redirect_openprocess"]
        joDalamud["BootEnabledGameFixes"]:AddString["backup_userdata_save"]
        joDalamud["BootEnabledGameFixes"]:AddString["clr_failfast_hijack"]

        This:Echo["DALAMUD_STARTUP_INFO = ${joDalamud~}"]

        System:SetEnvironmentVariable["DALAMUD_STARTUP_INFO", "${joDalamud.AsJSON~}"]
    }

    method SetAppDataPath()
    {
        variable filepath currentFolder

        ; Default/Fallback path is the "%APPDATA%/XIVLauncher" folder
        xlAppDataPath:Set[${System.EnvironmentVariable["APPDATA"]~}/XIVLauncher]

        ; Support override via --roamingPath whose value gets set
        ; as %ROAMINGPATH% by the batch voodoo. Any other configuration
        ; still requires explicit support to be implemented here!
        if ${System.EnvironmentVariable["ROAMINGPATH"].Length} > 0
        {
            currentFolder:Set[${System.EnvironmentVariable["ROAMINGPATH"]~}]

            if ${currentFolder.PathExists}
            {
                xlAppDataPath:Set[${currentFolder.AbsolutePath~}]
            }
        }

        This:Echo["XIVLauncher AppData Path: ${xlAppDataPath.AbsolutePath~}"]
    }

    method SetDalamudPath()
    {
        variable int      dirEntry       = 0
        variable filelist dmHooksFolders
        variable filepath currentFolder
        variable filepath dmHooksPath    = "${xlAppDataPath.AbsolutePath~}/addon/Hooks"
        variable filepath dmVersion

        if ${xlAppDataPath.FileExists["addon/Hooks"]}
        {
            This:Echo["XIVLauncher AppData found, checking for Dalamud..."]

            dmHooksFolders:GetDirectories["${dmHooksPath.Path~}/\*"]

            while (${dirEntry:Inc} <= ${dmHooksFolders.Files})
            {
                if ${dmHooksFolders.File[${dirEntry}].Filename.NotEqual["dev"]}
                {
                    currentFolder:Set[${dmHooksFolders.File[${dirEntry}].FullPath~}]

                    if ${currentFolder.FileExists["Dalamud.dll"]}
                    {
                        dmVersion:Set[${currentFolder.AbsolutePath~}]
                    }
                }
            }

            if ${dmVersion.PathExists}
            {
                dmPath:Set[${dmVersion.AbsolutePath}]
            }
        }

        This:Echo["Dalamud Path: ${dmPath.AbsolutePath~}"]
    }

    method ReplaceImGuiSceneDll()
    {
        variable filepath currentDirPath = "${Script.CurrentDirectory~}"
        variable file     srcDllFile     = "${Script.CurrentDirectory~}/${imGuiSceneDllName}"
        variable file     trgDllFile     = "${dmPath.AbsolutePath~}/${imGuiSceneDllName}"

        if !${replaceImGuiSceneDll}
        {
            return
        }

        if !${currentDirPath.FileExists["${imGuiSceneDllName}"]}
        {
            This:Echo["Error: ${imGuiSceneDllName} not found in ffxiv-utils directory: ${Script.CurrentDirectory~}"]
            return
        }

        if !${dmPath.FileExists["${imGuiSceneDllName}"]}
        {
            This:Echo["Error: Unexpectedly, ${imGuiSceneDllName} was not found in Dalamud path: ${dmPath.AbsolutePath~}"]
            This:Echo["Error: Not replacing ${imGuiSceneDllName} because something is fundamentally wrong!"]
            return
        }

        This:Echo["Patched ${imGuiSceneDllName} size: ${srcDllFile.Size} bytes"]
        This:Echo["Target ${imGuiSceneDllName} size: ${trgDllFile.Size} bytes"]

        ; In theory this should not happen, since the file gets restored to its
        ; vanilla state on every launch of XIVLauncher.
        if ${srcDllFile.Size} == ${trgDllFile.Size}
        {
            This:Echo["File sizes match, ${imGuiSceneDllName} is likely already patched. Skipping..."]
            return
        }

        This:Echo["Replacing ${imGuiSceneDllName} with patched version..."]
        squelch cp -overwrite "${Script.CurrentDirectory~}/${imGuiSceneDllName}" "${dmPath.AbsolutePath~}/${imGuiSceneDllName}"

        This:Echo["Patched ${imGuiSceneDllName} size: ${srcDllFile.Size} bytes"]
        This:Echo["Target ${imGuiSceneDllName} size after replacing: ${trgDllFile.Size} bytes"]

        if ${srcDllFile.Size} != ${trgDllFile.Size}
        {
            This:Echo["Error: ${imGuiSceneDllName} size mismatch, replace probably failed!"]
            return
        }

        This:Echo["File sizes match, ${imGuiSceneDllName} was replaced in: ${dmPath.AbsolutePath~}"]
    }

    method InjectDalamud()
    {
        if ${dmPath.PathExists}
        {
            This:ReplaceImGuiSceneDll

            if !${This.CanRunDalamud}
            {
                This:Echo["Error: Rejecting injection - mismatched versions between Game (${This.GetGameVersion}) and Dalamud (${This.GetDalamudSupportedGameVersion})!"]
                return
            }

            if ${useDalamudInjector}
            {
                This:Echo["Calling Dalamud Injector..."]
                osexecute "${dmPath.AbsolutePath~}/Dalamud.Injector.exe" "${System.ProcessID}"
                return
            }
            else
            {
                This:Echo["Building DalamudStartupInfo and injecting EasyBoot..."]

                squelch cp -overwrite "${Script.CurrentDirectory~}/${dmEasyBootDllName}" "${dmPath.AbsolutePath~}/${dmEasyBootDllName}"

                if !${dmPath.FileExists["${dmEasyBootDllName}"]}
                {
                    This:Echo["Error: ${dmEasyBootDllName} not found in Dalamud directory, cannot inject!"]
                    return
                }

                This:SetDalamudStartupInfo["${xlAppDataPath.AbsolutePath~}"]
                System:LoadDLL["${dmPath.AbsolutePath~}/${dmEasyBootDllName}"]
                return
            }
        }
        else
        {
            This:Echo["No Dalamud folder found."]
        }
    }

    method InjectReshade()
    {
        variable file     gameExecutable = "${LavishScript.Executable~}"
        variable filepath gameDirectory  = "${gameExecutable.Path~}"

        if ${gameDirectory.FileExists["${reshadeDllName}"]}
        {
            This:Echo["ReShade found, trying to load it..."]
            This:Echo["ReShade LoadDLL[${gameDirectory.AbsolutePath~}${reshadeDllName}]"]
            System:LoadDLL["${gameDirectory.AbsolutePath~}${reshadeDllName}", "+direct"]
        }
        else
        {
            This:Echo["Error: ReShade not found, are you sure \"${gameDirectory.AbsolutePath~}${reshadeDllName}\" exists?"]
        }
    }

    method Go()
    {
        if ${InnerSpace.Build} < ${minBuildVersion}
        {
            This:Echo["Error: Requires at least Inner Space build ${minBuildVersion} or newer to work."]
            return
        }

        if ${LavishScript.Executable.Find["ffxiv"]}
        {
            if ${injectReshade}
            {
                This:InjectReshade
            }

            if ${injectDalamud}
            {
                This:SetAppDataPath
                This:SetDalamudPath

                This:InjectDalamud
            }
        }
    }
}

function main()
{
    variable ffxivUtils FFXIVUtils
    FFXIVUtils:Go
}
