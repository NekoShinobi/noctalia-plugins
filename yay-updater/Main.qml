import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  readonly property int hoursToMillis: 3_600_000

  readonly property int updateIntervalHours: pluginApi?.pluginSettings.updateIntervalHours || pluginApi?.manifest?.metadata.defaultSettings?.updateIntervalHours || 4
  readonly property string terminalCommand: pluginApi?.pluginSettings.terminalCommand || pluginApi?.manifest?.metadata.defaultSettings?.terminalCommand || "foot -e"
  readonly property bool autoRefreshOnOpen: pluginApi?.pluginSettings.autoRefreshOnOpen ?? pluginApi?.manifest?.metadata.defaultSettings?.autoRefreshOnOpen ?? true

  property int updateCount: 0
  property var packageList: []
  property bool isChecking: false
  property string lastCheckTime: ""

  Component.onCompleted: {
    Logger.i("YayUpdater", "Plugin initialized");
    startCheckUpdates();
  }

  //
  // ------ Check for updates ------
  //
  Timer {
    id: timerCheckUpdates

    interval: root.updateIntervalHours * root.hoursToMillis
    running: true
    repeat: true
    onTriggered: root.startCheckUpdates()
  }

  function startCheckUpdates() {
    Logger.i("YayUpdater", "Checking for updates...");
    root.isChecking = true;
    checkUpdatesProc.running = true;
  }

  Process {
    id: checkUpdatesProc
    command: ["sh", "-c", "(checkupdates 2>/dev/null; yay -Qua 2>/dev/null)"]

    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();

        if (output === "") {
          root.updateCount = 0;
          root.packageList = [];
          Logger.i("YayUpdater", "No updates available");
        } else {
          const lines = output.split('\n').filter(line => line.trim() !== "");
          const packages = lines.map(line => {
            const parts = line.split(/\s+/);
            const name = parts[0] || "";
            
            return {
              repository: "unknown",
              name: name,
              fullName: name,
              currentVersion: parts[1] || "",
              newVersion: parts[3] || parts[2] || ""
            };
          });

          // Sort packages alphabetically by name
          packages.sort((a, b) => a.name.localeCompare(b.name));

          root.packageList = packages;
          root.updateCount = root.packageList.length;
          Logger.i("YayUpdater", `Found ${root.updateCount} updates (repos + AUR)`);
        }
        
        root.lastCheckTime = new Date().toLocaleTimeString();
        root.isChecking = false;
      }
    }

    onExited: function (exitCode, exitStatus) {
      if (exitCode !== 0) {
        Logger.e("YayUpdater", `Check updates failed with exit code ${exitCode}`);
        root.isChecking = false;
      }
    }
  }

  //
  // ------ Run system update ------
  //
  function runSystemUpdate() {
    const updateCmd = "yay -Syu";
    const term = root.terminalCommand.trim();
    const fullCmd = (term.indexOf("{}") !== -1)
      ? term.replace("{}", updateCmd)
      : term + " " + updateCmd;

    Logger.i("YayUpdater", `Running update command: ${fullCmd}`);

    systemUpdateProc.command = ["sh", "-c", fullCmd];
    systemUpdateProc.running = true;
  }

  Process {
    id: systemUpdateProc

    onExited: function (exitCode, exitStatus) {
      if (exitCode === 0) {
        Logger.i("YayUpdater", "Update command completed");
        // Refresh the update list after update completes
        Qt.callLater(root.startCheckUpdates);
      } else {
        Logger.w("YayUpdater", `Update command exited with code ${exitCode}`);
      }
    }
  }

  //
  // ------ IPC ------
  //
  IpcHandler {
    target: "plugin:yay-updater"

    function check(): void {
      root.startCheckUpdates();
    }

    function update(): void {
      root.runSystemUpdate();
    }
  }
}
