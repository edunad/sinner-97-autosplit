/*  Sinner97 Autosplitter
    v0.0.1 --- By FailCake (edunad)

    GAME VERSIONS:
    - v1.0.0 = 29802496
*/


state("SinnerPSX", "1.0.0") {}

startup {
    // Settings
    settings.Add("split", true, "Splits");
    settings.Add("split_evidence", true, "On evidence", "split");

    settings.Add("reset", true, "Reset");
    settings.Add("reset_mainmenu", false, "On mainmenu", "reset");

    if (timer.CurrentTimingMethod == TimingMethod.RealTime){ // stolen from dude simulator 3, basically asks the runner to set their livesplit to game time
		var timingMessage = MessageBox.Show (
			"This game uses Time without Loads (Game Time) as the main timing method.\n"+
			"LiveSplit is currently set to show Real Time (RTA).\n"+
			"Would you like to set the timing method to Game Time? This will make verification easier",
			"LiveSplit | Sinner97",
		MessageBoxButtons.YesNo,MessageBoxIcon.Question);

		if (timingMessage == DialogResult.Yes){
			timer.CurrentTimingMethod = TimingMethod.GameTime;
		}
	}
}

init {
    if(modules == null) return;

    vars.gameAssembly = modules.Where(m => m.ModuleName == "UnityPlayer.dll").First();
    if(vars.gameAssembly == null) return;

    vars.gameBase = vars.gameAssembly.BaseAddress;
    vars.gameEvidenceBase = 0x00;
    vars.timerBase = 0x00;
    vars.mainMenuBase = 0x00;

    var mdlSize = vars.gameAssembly.ModuleMemorySize;
    print("[INFO] Sinner97 assembly version: " + mdlSize);
    if (mdlSize == 29802496) {
        vars.gameEvidenceBase = 0x01A97030;
        vars.timerBase = 0x01A97030;
        vars.mainMenuBase = 0x01A93640;

        version = "1.0.0";
    } else {
        version = "UNKNOWN";

        print("[WARNING] Invalid Sinner97 game version");
        return;
    }

    print("[INFO] Sinner97 game version: " + version);

    vars.ptrEvidenceOffset = vars.gameBase + vars.gameEvidenceBase;
    vars.ptrTimerOffset = vars.gameBase + vars.timerBase;
    vars.ptrMainMenuOffset = vars.gameBase + vars.mainMenuBase;

	vars.ingame = new MemoryWatcherList();
    vars.ingame.Add(new MemoryWatcher<int>(new DeepPointer(vars.ptrEvidenceOffset, 0x120, 0, 0x48, 0x60, 0x20, 0x68)) { Name = "evidenceCount" });
    vars.ingame.Add(new MemoryWatcher<float>(new DeepPointer(vars.ptrTimerOffset, 0x120, 0x48, 0x60, 0x18, 0x20)) { Name = "ingameTimer" });
    vars.ingame.Add(new MemoryWatcher<bool>(new DeepPointer(vars.ptrMainMenuOffset, 0x8, 0x8, 0x30, 0xA0, 0x90, 0x28, 0x0 + 0x00A9)) { Name = "isINGAME" });
    vars.ingame.Add(new MemoryWatcher<bool>(new DeepPointer(vars.ptrMainMenuOffset, 0x8, 0x8, 0x30, 0xA0, 0x90, 0x28, 0x0 + 0x00AC)) { Name = "isInCredits" });

}

update {
    if(vars.ingame == null) return;
    vars.ingame.UpdateAll(game);
}

reset {
    return !vars.ingame["isINGAME"].Current && settings["reset_mainmenu"];
}

exit {
	timer.IsGameTimePaused = true; // Pause timer on game crash
}

isLoading {
    return true; // Disable time sync
}

gameTime {
    return TimeSpan.FromSeconds((double)vars.ingame["ingameTimer"].Current);
}

start {
    return vars.ingame["isINGAME"].Current && vars.ingame["isINGAME"].Current != vars.ingame["isINGAME"].Old;
}

split {
    if(timer.CurrentPhase != TimerPhase.Running) return false;

    int currentEvidence = vars.ingame["evidenceCount"].Current;
    int oldEvidence = vars.ingame["evidenceCount"].Old;

    if(settings["split_evidence"]) {
        if(oldEvidence != currentEvidence) {
            print("[Sinner97] SPLIT: " + oldEvidence + " | " + currentEvidence);
            return currentEvidence > 0;
        }
    }

    if(currentEvidence >= 5 && !vars.ingame["isInCredits"].Current) {
        print("[Sinner97] GAME END");
        return true;
    }
}
