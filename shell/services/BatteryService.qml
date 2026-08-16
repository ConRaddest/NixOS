pragma Singleton

import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower

Item {
  id: root

  readonly property var battery: UPower.displayDevice
  readonly property var physicalBattery: findPhysicalBattery()
  readonly property bool available: battery && battery.ready && battery.isPresent
  readonly property string batteryPath: physicalBattery ? `/sys/class/power_supply/${physicalBattery.nativePath}` : ""
  readonly property int chargePercent: batteryPercentage()
  readonly property real batterySizeWh: available ? Number(battery.energyCapacity || 0) : 0
  readonly property int chargeCycles: fileNumber(cycleCountFile)
  readonly property string batteryState: available ? UPowerDeviceState.toString(battery.state) : "Unknown"
  readonly property bool isDischarging: available && UPower.onBattery && battery.state === UPowerDeviceState.Discharging
  readonly property bool isCharging: available && battery.state === UPowerDeviceState.Charging
  readonly property string powerProfile: PowerProfile.toString(PowerProfiles.profile)

  property bool _enforcedPerformance: false

  function forcePerformanceProfile() {
    if (root._enforcedPerformance)
      return;

    if (PowerProfiles.hasPerformanceProfile) {
      if (PowerProfiles.profile !== PowerProfile.Performance) {
        PowerProfiles.profile = PowerProfile.Performance;
      }
      root._enforcedPerformance = true;
    }
  }

  Component.onCompleted: {
    root.forcePerformanceProfile();
  }

  // Handle D-Bus async startup timing
  Connections {
    target: PowerProfiles

    // Fires when the service finishes reading performance support
    function onHasPerformanceProfileChanged() {
      root.forcePerformanceProfile();
    }

    // Fires when D-Bus initializes and reports the default "Balanced" state
    function onProfileChanged() {
      if (!root._enforcedPerformance) {
        root.forcePerformanceProfile();
      }
    }
  }

  readonly property string batteryIcon: {
    if (!available) {
      return "󰁹";
    }
    if (isCharging) {
      if (chargePercent < 10) {
        return "󰢜";
      } else if (chargePercent < 20) {
        return "󰂆";
      } else if (chargePercent < 30) {
        return "󰂇";
      } else if (chargePercent < 40) {
        return "󰂈";
      } else if (chargePercent < 50) {
        return "󰢝";
      } else if (chargePercent < 60) {
        return "󰂉";
      } else if (chargePercent < 70) {
        return "󰢞";
      } else if (chargePercent < 80) {
        return "󰂊";
      } else if (chargePercent < 90) {
        return "󰂋";
      } else {
        return "󰂅";
      }
    } else {
      if (chargePercent < 10) {
        return "󰁺";
      } else if (chargePercent < 20) {
        return "󰁻";
      } else if (chargePercent < 30) {
        return "󰁼";
      } else if (chargePercent < 40) {
        return "󰁽";
      } else if (chargePercent < 50) {
        return "󰁾";
      } else if (chargePercent < 60) {
        return "󰁿";
      } else if (chargePercent < 70) {
        return "󰂀";
      } else if (chargePercent < 80) {
        return "󰂁";
      } else if (chargePercent < 90) {
        return "󰂂";
      } else {
        return "󰁹";
      }
    }
  }

  function findPhysicalBattery() {
    for (const device of UPower.devices.values) {
      if (device.isLaptopBattery && device.nativePath !== "")
        return device;
    }
    return null;
  }

  function batteryPercentage() {
    if (!battery || !battery.isPresent)
      return -1;
    return Math.round(Number(battery.percentage || 0) * 100);
  }

  function fileNumber(file) {
    if (!file.loaded)
      return -1;

    const value = Number(file.text().trim());
    return Number.isFinite(value) ? value : -1;
  }

  function refreshSupplementalInfo() {
    cycleCountFile.reload();
  }

  function setPowerProfile(profile) {
    switch (profile) {
    case "PowerSaver":
      PowerProfiles.profile = PowerProfile.PowerSaver;
      return true;
    case "Balanced":
      PowerProfiles.profile = PowerProfile.Balanced;
      return true;
    case "Performance":
      if (!PowerProfiles.hasPerformanceProfile)
        return false;
      PowerProfiles.profile = PowerProfile.Performance;
      return true;
    default:
      console.warn("Unknown power profile:", profile);
      return false;
    }
  }

  FileView {
    id: cycleCountFile

    path: root.batteryPath === "" ? "" : `${root.batteryPath}/cycle_count`
    preload: true
    watchChanges: true
    printErrors: false
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshSupplementalInfo()
  }

  Connections {
    target: UPower

    function onOnBatteryChanged() {
      root.refreshSupplementalInfo();
    }
  }
}
