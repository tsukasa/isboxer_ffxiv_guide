objectdef ffxivUtils
{
    ; * ------------- *
    ; * Configuration *
    ; * ------------- * =======================================================

    ; Inject Dalamud into the game? [Default: TRUE]
    variable bool     injectDalamud             = TRUE

    ; Replace ImGuiScene.dll with a patched copy to fix the input handling when
    ; used with Inner Space? [Default: TRUE]
    variable bool     replaceImGuiSceneDll      = TRUE

    ; Replace Dalamud.Injector.dll with a patched copy to fix the forced
    ; BootEnabledGameFixes. [Default: TRUE]
    variable bool     replaceDalamudInjectorDll = TRUE

    ; How should we inject Dalamud? [Default: 0]
    ; [0] Use the EasyBoot method via LoadDLL
    ; [1] Use Dalamud.Injector.exe with base64-encoded json payload arg
    ; [2] Use Dalamud.Injector.exe with separate named command line args
    variable int      dalamudInjectionMethod    = 0

    ; Language to use for Dalamud. [Default: English]
    variable string   dalamudLanguage           = "English"

    ; Delay in ms between the game starting and injection. [Default: 500]
    variable int      dalamudInjectionDelayMs   = 500



    ; TESTING ONLY: Inject ReShade into the game? [Default: FALSE]
    ; This currently causes issues with the game, so it's disabled by default.
    variable bool     injectReshade             = FALSE

    ; * -------------------------- *
    ; * Internal control variables *
    ; * -------------------------- * ==========================================

    ; EasyBoot repository: https://github.com/LaxLacks/Dalamud
    variable string   dmEasyBootDllName = "Dalamud.EasyBoot.dll"

    variable string   reshadeDllName    = "ReShade64.dll"

    variable int      minBuildVersion   = 6922

    ; * --------------- *
    ; * Internal caches *
    ; * --------------- * =====================================================

    variable string   c_gameVersion
    variable string   c_dalamudGameVersion
    variable string   c_dalamudAssetsVersion

    variable filepath xlAppDataPath
    variable filepath dmPath

    variable jsonvalue    dmStartupInfoJson = "{}"
    variable index:string dmStartupInfoArgs

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
        variable int injectionDelayMs = 100

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

    member:string Base64Encode(string inp)
    {
        variable string BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

        variable uint padCount
        variable mutablestring inputString   = ${inp}
        variable mutablestring resultString  = ""
        variable mutablestring paddingString = ""

        padCount:Set[${inputString.Length} % 3]

        if ${padCount} > 0
        {
            for (; ${padCount} < 3; padCount:Inc)
            {
                paddingString:Concat[=]
                inputString:Concat[\0]
            }
        }

        for (padCount:Set[0]; ${padCount} < ${inputString.Length}; padCount:Inc[3])
        {
            variable uint n0

            variable uint n1
            variable uint n2
            variable uint n3
            variable uint n4

            n0:Set[(${inputString.GetAt[${Math.Calc[${padCount} + 1]}]} << 16) + (${inputString.GetAt[${Math.Calc[${padCount} + 2]}]} << 8) + (${inputString.GetAt[${Math.Calc[${padCount} + 3]}]})]
            n1:Set[(${n0} >> 18) & 63]
            n2:Set[(${n0} >> 12) & 63]
            n3:Set[(${n0} >> 6) & 63]
            n4:Set[(${n0} & 63]

            resultString:Concat[""]
            resultString:Concat[${BASE64_CHARS.Mid[${Math.Calc[${n1} + 1]}, 1]}]
            resultString:Concat[${BASE64_CHARS.Mid[${Math.Calc[${n2} + 1]}, 1]}]
            resultString:Concat[${BASE64_CHARS.Mid[${Math.Calc[${n3} + 1]}, 1]}]
            resultString:Concat[${BASE64_CHARS.Mid[${Math.Calc[${n4} + 1]}, 1]}]
        }

        resultString:Set[${resultString.Left[${Math.Calc[${resultString.Length} - ${paddingString.Length}]}]}]
        resultString:Concat[${paddingString}]

        return ${resultString}
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

    /**
     * Populates the dmStartupInfoJson JSON object with the necessary
     * information for Dalamud to start up.
     */
    method SetDalamudStartupInfo(string xlAppDataPath)
    {
        ; DALAMUD_STARTUP_INFO
        variable jsonvalue joDalamud = "{}"
        variable jsonvalue joTroubleDataPack = "{}"

        variable string DS

        ; On Dalamud's injector, we keep forward slashes.
        ; Backslashes provoke unwanted crashes, for some reason...
        DS:Set[/]

        if ${dalamudInjectionMethod} == 0
        {
            ; When injecting via EasyBoot, we use regular backlashes.
            DS:Set[\\]
        }

        ; Strings
        joDalamud:SetString["AssetDirectory",         "${xlAppDataPath.Replace[/,${DS}]~}${DS}dalamudAssets${DS}${This.GetDalamudAssetsVersion}"]
        joDalamud:SetString["BootLogPath",            "${xlAppDataPath.Replace[/,${DS}]~}${DS}dalamud.boot.log"]
        joDalamud:SetString["ConfigurationPath",      "${xlAppDataPath.Replace[/,${DS}]~}${DS}dalamudConfig.json"]
        joDalamud:SetString["GameVersion",            "${This.GetGameVersion}"]
        joDalamud:SetString["LogPath",                "${xlAppDataPath.Replace[/,${DS}]~}"]
        joDalamud:SetString["PluginDirectory",        "${xlAppDataPath.Replace[/,${DS}]~}${DS}installedPlugins"]
        joDalamud:SetString["WorkingDirectory",       "${dmPath.AbsolutePath.Replace[/,${DS}]~}"]

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
        joDalamud:SetBool["CrashHandlerShow", FALSE]
        joDalamud:SetBool["NoLoadPlugins", FALSE]
        joDalamud:SetBool["NoLoadThirdPartyPlugins", FALSE]

        ; TroubleshootingPackData nested object as string.
        ; Gets populated automatically when using Dalamud's injector.
        if ${dalamudInjectionMethod} == 0
        {
            joTroubleDataPack:SetBool["empty", FALSE]
            joTroubleDataPack:SetString["description", "No troubleshooting data supplied."]
            joDalamud:SetString["TroubleshootingPackData", "${joTroubleDataPack.AsJSON}"]
        }

        ; BootUnhookDlls array of strings
        joDalamud:Set["BootUnhookDlls", "[]"]

        ; BootEnabledGameFixes array of strings
        joDalamud:Set["BootEnabledGameFixes", "[]"]
        joDalamud["BootEnabledGameFixes"]:AddString["prevent_devicechange_crashes"]
        joDalamud["BootEnabledGameFixes"]:AddString["clr_failfast_hijack"]
        joDalamud["BootEnabledGameFixes"]:AddString["prevent_icmphandle_crashes"]
        ; These fixes cause Inner Space to lose its Windows API hooks...
        ;joDalamud["BootEnabledGameFixes"]:AddString["disable_game_openprocess_access_check"]
        ;joDalamud["BootEnabledGameFixes"]:AddString["redirect_openprocess"]
        ;joDalamud["BootEnabledGameFixes"]:AddString["backup_userdata_save"]

        dmStartupInfoJson:SetValue["${joDalamud~}"]
    }

    /**
     * Creates a collection of startup arguments for the Dalamud.Injector.exe
     * based on the dmStartupInfoJson JSON object.
     * Requires that SetDalamudStartupInfo already ran.
     */
    method SetDalamudStartupInfoArgsFromJson()
    {
        dmStartupInfoArgs:Clear

        ; Properties not filled here are populated automatically in the Dalamud.Injector.exe,
        ; making life a bit easier compared to the other two methods.
        dmStartupInfoArgs:Insert["--dalamud-working-directory=${dmStartupInfoJson.Get["WorkingDirectory"]}"]
        dmStartupInfoArgs:Insert["--dalamud-configuration-path=${dmStartupInfoJson.Get["ConfigurationPath"]}"]
        dmStartupInfoArgs:Insert["--dalamud-plugin-directory=${dmStartupInfoJson.Get["PluginDirectory"]}"]
        dmStartupInfoArgs:Insert["--dalamud-dev-plugin-directory=${dmStartupInfoJson.Get["DefaultPluginDirectory"]}"]
        dmStartupInfoArgs:Insert["--dalamud-asset-directory=${dmStartupInfoJson.Get["AssetDirectory"]}"]
        dmStartupInfoArgs:Insert["--dalamud-delay-initialize=${dmStartupInfoJson.Get["DelayInitializeMs"]}"]
        dmStartupInfoArgs:Insert["--dalamud-client-language=${dmStartupInfoJson.Get["Language"]}"]
        dmStartupInfoArgs:Insert["--logname=${dmStartupInfoJson.Get["BootLogPath"]}"]
    }

    method ReplaceFileInDalamudDir(string fileName)
    {
        variable filepath currentDirPath = "${Script.CurrentDirectory~}"
        variable file     sourceFile     = "${Script.CurrentDirectory~}/${fileName}"
        variable file     targetFile     = "${dmPath.AbsolutePath~}/${fileName}"

        if !${currentDirPath.FileExists["${fileName}"]}
        {
            This:Echo["Error: ${fileName} not found in ffxiv-utils directory: ${Script.CurrentDirectory~}"]
            return
        }

        if !${dmPath.FileExists["${fileName}"]}
        {
            This:Echo["Error: Unexpectedly, ${fileName} was not found in Dalamud path: ${dmPath.AbsolutePath~}"]
            This:Echo["Error: Not replacing ${fileName} because something is fundamentally wrong!"]
            return
        }

        This:Echo["Patched ${fileName} size: ${sourceFile.Size} bytes"]
        This:Echo["Target ${fileName} size: ${targetFile.Size} bytes"]

        ; In theory this should not happen, since the file gets restored to its
        ; vanilla state on every launch of XIVLauncher.
        if ${sourceFile.Size} == ${targetFile.Size}
        {
            This:Echo["File sizes match, ${fileName} is likely already replaced. Skipping..."]
            return
        }

        This:Echo["Replacing ${fileName} with patched version..."]
        squelch cp -overwrite "${Script.CurrentDirectory~}/${fileName}" "${dmPath.AbsolutePath~}/${fileName}"

        This:Echo["Patched ${fileName} size: ${sourceFile.Size} bytes"]
        This:Echo["Target ${fileName} size after replacing: ${targetFile.Size} bytes"]

        if ${sourceFile.Size} != ${targetFile.Size}
        {
            This:Echo["Error: ${fileName} size mismatch, replace probably failed!"]
            return
        }

        This:Echo["File sizes match, ${fileName} was replaced in: ${dmPath.AbsolutePath~}"]
    }

    /**
     * Replaces the ImGuiScene.dll in the Dalamud folder with the one from the ffxiv-utils folder.
     * This might lead to issues on setups that use a single Dalamud folder for multiple sessions.
     */
    method ReplaceImGuiSceneDll()
    {
        if !${replaceImGuiSceneDll}
        {
            return
        }

        This:ReplaceFileInDalamudDir["ImGuiScene.dll"]
    }

    /**
     * Replaces the Dalamud.Injector.dll in the Dalamud folder with the one from the ffxiv-utils folder.
     */
    method ReplaceDalamudInjectorDll()
    {
        if !${replaceDalamudInjectorDll}
        {
            return
        }

        This:ReplaceFileInDalamudDir["Dalamud.Injector.dll"]
    }

    /**
     * Injects Dalamud using the EasyBoot.dll library via LoadDLL.
     */
    method InjectDalamudWithEasyBoot()
    {
        This:Echo["Setting DALAMUD_STARTUP_INFO environment variable and injecting EasyBoot..."]

        System:SetEnvironmentVariable["DALAMUD_STARTUP_INFO", "${dmStartupInfoJson.AsJSON~}"]
        squelch cp -overwrite "${Script.CurrentDirectory~}/${dmEasyBootDllName}" "${dmPath.AbsolutePath~}/${dmEasyBootDllName}"

        if !${dmPath.FileExists["${dmEasyBootDllName}"]}
        {
            This:Echo["Error: ${dmEasyBootDllName} not found in Dalamud directory, cannot inject!"]
            return
        }

        System:LoadDLL["${dmPath.AbsolutePath~}/${dmEasyBootDllName}"]
    }

    /**
     * Injects Dalamud using the Dalamud.Injector.exe executable.
     * Either uses a 2 parameter call with a base64-encoded json payload,
     * or a call with named arguments.
     */
    method InjectDalamudWithInjector(int injectorArgType)
    {
        variable string dalamudInjectorExe = "${dmPath.AbsolutePath~}/Dalamud.Injector.exe"

        This:Echo["Calling Dalamud.Injector.exe (Argument Method: ${dalamudInjectionMethod})..."]

        switch ${injectorArgType}
        {
            ; Injection with base64-encoded json payload argument
            case 1
            default
                variable string b64StartupInfo

                b64StartupInfo:Set[${This.Base64Encode["${dmStartupInfoJson.AsJSON~}"]}]

                This:Echo["Built Base64-encoded DalamudStartupInfo: ${b64StartupInfo~}"]
                osexecute "${dalamudInjectorExe}" "${System.ProcessID}" "${b64StartupInfo}"
                break
            ; Injection with exploded named arguments
            case 2
                This:SetDalamudStartupInfoArgsFromJson

                This:Echo["Call Arguments: \"${dalamudInjectorExe}\" inject ${dmStartupInfoArgs.Expand} ${System.ProcessID}"]
                osexecute "${dalamudInjectorExe}" "inject" ${dmStartupInfoArgs.Expand} "${System.ProcessID}"
                break
        }

        This:Echo["Dalamud.Injector.exe called."]
    }

    /**
     * Main method for injecting Dalamud into the game client.
     * Performs all the necessary checks and calls the appropriate injection method.
     */
    method InjectDalamud()
    {
        if ${dmPath.PathExists}
        {
            if !${This.CanRunDalamud}
            {
                This:Echo["Error: Rejecting injection - mismatched versions between Game (${This.GetGameVersion}) and Dalamud (${This.GetDalamudSupportedGameVersion})!"]
                return
            }

            This:ReplaceImGuiSceneDll
            This:ReplaceDalamudInjectorDll

            This:Echo["Building DalamudStartupInfo..."]
            This:SetDalamudStartupInfo["${xlAppDataPath.AbsolutePath~}"]
            This:Echo["DALAMUD_STARTUP_INFO = ${dmStartupInfoJson.AsJSON~}"]

            switch ${dalamudInjectionMethod}
            {
                ; EasyBoot via LoadDLL
                case 0
                default
                    This:InjectDalamudWithEasyBoot
                    break
                ; Dalamud.Injector.exe
                case 1
                case 2
                    This:InjectDalamudWithInjector[${dalamudInjectionMethod}]
                    break
            }
            return
        }
        else
        {
            This:Echo["No Dalamud folder found."]
        }
    }

    /**
     * Attempts to inject ReShade into the game client.
     * Currently causes the client to close.
     */
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

    /**
     * Main method to perform additional tasks after launching the ffxiv game client.
     */
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
