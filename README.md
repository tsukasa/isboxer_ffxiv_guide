# FINAL FANTASY XIV, ISBoxer and You
_"A somewhat informative guide"_<br />

---

This guide handles the basic topics to get FINAL FANTASY XIV and XIVLauncher with Dalamud to work. The instructions here represent tsukasa's own views/best practices and are by no means the be-all and end-all.

---

## Part I: XIVLauncher as a Launcher Replacement

[XIVLauncher][xivlauncher_github] is a popular third-party open-source launcher replacement for FINAL FANTASY XIV that comes with many improvements over Square-Enix's original game launcher such as a "remember password" feature, an account list, support for both non-Steam and Steam versions and a convenient way to store patches (in case you reinstall the game, so you will not have to download 60+GB of patches again).

From a multiboxing perspective, using [XIVLauncher][xivlauncher_github] has many advantages. Not having to retype the password every time, and not having to switch launchers because you have a Steam-bound account mixed in, is a great boon.

### I.I Adding XIVLauncher as a launcher for FINAL FANTASY XIV in Inner Space

Inner Space allows multiple profiles per game. A typical example for this is Blizzard's Diablo III that can either be started through the Battle.net Launcher or directly. Starting the game through Battle.net automatically logs-in the player in the game client, while starting the game client directly requires the user to perform the log-in manually.

Thanks to this flexibility, we are easily able to add another profile to FINAL FANTASY XIV's game configuration to easily switch between Square-Enix's launcher and XIVLauncher while keeping it all organized within the game configuration of FINAL FANTASY XIV.

Make sure Inner Space is started before proceeding and that FINAL FANTASY XIV has at least its Default profile in Inner Space. Also make sure you have installed the latest version of [XIVLauncher][xivlauncher_github].

Right-click the Inner Space tray icon, select `Configuration` and switch to the `Game Configuration` tab. In the dropdown at the top, select FINAL FANTASY XIV from the list:

![Inner Space - Game Configuration 01](images/inner_space_game_config_01.png)

Click the "New Profile" button to add a new profile for FINAL FANTASY XIV's game configuration. You will be able to select which profile to use on a per-character basis in ISBoxer Toolkit.

In theory you could edit the already existing Default profile for the game, however it is better to keep the original profile intact in case you ever want to go back to a vanilla configuration.

You will find yourself in what could be perceived as a somewhat daunting dialogue:

![Inner Space - Game Configuration 02](images/inner_space_game_config_02.png)

Change the "New FINAL FANTASY XIV Profile" to something more descriptive like "FINAL FANTASY XIV XIVLauncher Profile". This is the title that later identifies your XIVLauncher profile in Inner Space and therefore ISBoxer Toolkit, so choose a name that you can make sense of.

Proceed to set `Main executable filename` from "NULL" to "XIVLauncher.exe".

Now open a file manager like Windows Explorer and navigate to `%LOCALAPPDATA%\XIVLauncher`. This should resolve to a path like `C:\Users\YourUsername\AppData\Local\XIVLauncher`. Copy the path from the address bar of your file manager, and set it as the `Main executable path` in the dialogue.

> __❗ Note:__ We cannot use environment variables like `%LOCALAPPDATA%` in Inner Space's Game Configuration directly, so we need to manually resolve the path first. Do not simply copy & paste the `%LOCALAPPDATA%\XIVLauncher` into the `Main executable path` - this will _not_ work!

Make sure the `Inner Space Loader aggressiveness` is set to `Default` or `Standard`. In the past a value of `Minimum` was required, however due to changing software behaviour this has adverse effects today (causing Inner Space to "lose" the game's process). It is therefore possible that on older setups that seemingly no longer work correctly, you might need to manually revert to `Default` or `Standard`.

Your configuration should look something like this:

![Inner Space - Game Configuration 03](images/inner_space_game_config_03.png)

You can safely ignore the other values in the dialogue.

Click the `Apply` button in the lower right corner and close the profile with the `Close Profile` button in the middle afterwards.

You should be back in the dialogue that allows you to select profiles for FINAL FANTASY XIV. If you click on the list below the `New Profile` button, your newly created profile `FINAL FANTASY XIV XIVLauncher Profile` should now be listed.

Click the `Reload` button on the lower left to make sure the changes propagate properly in Inner Space, otherwise you might see a wrong name in ISBoxer Toolkit later on.

### I.II Un-sandboxing Steam for Steam-bound FINAL FANTASY XIV Accounts

This section is only necessary if you have a mix of regular service accounts and __exactly one__ Steam-connected account.

If you use __no__ Steam-connected service account or __multiple__ Steam-connected service accounts, you can should this section.

Inner Space, by default, sandboxes Steam processes to allow multiboxing with multiple Steam accounts. This is a nice feature, however slightly annoying in a FINAL FANTASY XIV multiboxing setup where you have 4 accounts but only one of them is connected to Steam, causing errors because of the sandboxing.

This section will selectively un-sandbox XIVLauncher from Inner Space's Steam virtualization so you can have your regular Steam session running on your desktop and have it authenticate against the XIVLauncher version running within Inner Space.

> __❗ Note:__ If you are using __multiple__ Steam-connected FINAL FANTASY XIV accounts and are still reading this, you should really skip this section. Un-sandboxing is only a viable way when using __exactly__ one Steam account.

First, you need to download the [unsteam.iss][unsteam_iss_script] script. Copy the script to your ISBoxer's `Script` directory.

Now right-click the Inner Space tray icon, select `Configuration`, switch to the `Game Configuration` tab and select FINAL FANTASY XIV from the list of games. From the list of profiles, select your "FINAL FANTASY XIV XIVLauncher Profile" that you created during I.I.

![Inner Space - Game Configuration 03](images/inner_space_game_config_04.png)

In the "Startup" dialogue, click the `Insert` button. This generates a "New Entry" in the action list on the left. Click the "New Entry" and edit its name on the right.

Set the name to "Remove Steam Redirects" and set the "Command to execute at this step of the sequence" to `waitscript unsteam`.

![Inner Space - Game Configuration 03](images/inner_space_game_config_05.png)

Once you have made the edits, click the `Finished` button. This should take you back to the previous dialogue. Click the `Apply` button in the lower right, the `Close Profile` button in the middle and then the `Reload` button in the lower left.

Your XIVLauncher profile should now be un-steamed, causing the virtualization/sandboxing of Steam to be lifted for this specific profile in Inner Space. You can later check this by opening the Inner Space console for a session and look for the "[UnSteam]" log entries.

### I.III ISBoxer Toolkit: Configuring your Characters

With Inner Space now having a XIVLauncher profile for FINAL FANTASY XIV, we can move on to configuring our characters in ISBoxer Toolkit to actually make use of the launcher.

Start ISBoxer Toolkit, navigate to ISBoxer - Characters - YOUR CHARACTER and change the `Game Profile` to your newly created "FINAL FANTASY XIV XIVLauncher Profile". Repeat this for all relevant characters.

![Inner Space - Game Configuration 03](images/isboxer_toolkit_01.png)

Once you are done, save the profile (File - Save) and export it to Inner Space (File - Export All to Inner Space).

### I.IV XIVLauncher Configuration

In the previous steps we have added XIVLauncher as a game profile for FINAL FANTASY XIV in Inner Space and configured our characters to use XIVLauncher instead of Square-Enix's regular launcher.

At this point the configuration uses the same XIVLauncher data directory as your regular XIVLauncher, meaning there is no distinction between a regular XIVLauncher session outside of Inner Space and a XIVLauncher session in Inner Space.

> __❗ Note:__ This means that every configuration change you make in a XIVLauncher session started through Inner Space will also affect your "regular" XIVLauncher. An example how to fan out XIVLauncher's data directories on a per-character basis to sidestep this behaviour is included in a later section of this guide.

Start your first character via ISBoxer. XIVLauncher should start. If that is not the case, please review the earlier steps and ensure all paths are correct.

Once XIVLauncher has fully loaded, please open settings via the icon on the main screen:

![XIVLauncher Main Window](images/xivlauncher_01.png)

Make sure you are using DirectX 11:

![XIVLauncher Settings 01](images/xivlauncher_02.png)

DirectX 9 [is no longer supported in FINAL FANTASY XIV][ffxiv_dx9_eol_lodestone] and while the game still allows you to play in DirectX 9, Inner Space might not work correctly.

Make sure to disable Dalamud injection, as this causes the spawned game client process to be "missed" by Inner Space:

![XIVLauncher Settings 02](images/xivlauncher_03.png)

> __❗ Note:__  The goal of this section is to use XIVLauncher as an alternate launcher, if you are interested in using Dalamud with Inner Space, please see the next chapter.

Once you have finished configuring XIVLauncher, confirm the settings and perform a login with XIVLauncher.

If you are using Steam, please make sure to tick the "Use Steam service account" checkbox in the main window and have your Steam client running in the background.

The game should launch and Inner Space should apply ISBoxer's window layout for your character set.

If that is not the case, please review the previous steps.

## II. Dalamud and You


---

[xivlauncher_github]: https://github.com/goatcorp/FFXIVQuickLauncher
[unsteam_iss_script]: /scripts/unsteam.iss
[ffxiv_dx9_eol_lodestone]: https://eu.finalfantasyxiv.com/lodestone/news/detail/46f28ce6bd697e3fd08e0e70c3c7646e5f5a3385
[tsukasa_batch_files]: https://static.tsukasa.io/mbx/....zip