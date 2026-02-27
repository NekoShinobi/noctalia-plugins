import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property bool hovered: false

  // Bar positioning properties
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  property string iconName: pluginApi?.pluginSettings?.iconName || pluginApi?.manifest?.metadata?.defaultSettings?.iconName || "software-update-available"
  property bool hideOnZero: pluginApi?.pluginSettings.hideOnZero || pluginApi?.manifest?.metadata.defaultSettings?.hideOnZero || false
  
  readonly property int updateCount: root.pluginApi?.mainInstance?.updateCount || 0
  readonly property bool isChecking: root.pluginApi?.mainInstance?.isChecking || false
  readonly property bool isVisible: (updateCount > 0) || !hideOnZero
  
  visible: isVisible
  opacity: isVisible ? 1.0 : 0.0

  readonly property real contentWidth: isVertical ? capsuleHeight : layout.implicitWidth + Style.marginS * 2
  readonly property real contentHeight: isVertical ? layout.implicitHeight + Style.marginS * 2 : capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  //
  // ------ Widget ------
  //
  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: root.hovered ? Color.mHover : Style.capsuleColor
    radius: Style.radiusM
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Item {
      id: layout
      anchors.centerIn: parent

      implicitWidth: grid.implicitWidth
      implicitHeight: grid.implicitHeight

      GridLayout {
        id: grid
        columns: root.isVertical ? 1 : 2
        rowSpacing: Style.marginS
        columnSpacing: Style.marginS

        NIcon {
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
          icon: root.isChecking ? "loader" : root.iconName
          color: root.hovered ? Color.mOnHover : (root.updateCount > 0 ? Color.mPrimary : Color.mOnSurface)
          
          RotationAnimation on rotation {
            running: root.isChecking
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
          }
        }

        NText {
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
          text: root.updateCount.toString()
          color: root.hovered ? Color.mOnHover : (root.updateCount > 0 ? Color.mPrimary : Color.mOnSurface)
          pointSize: root.barFontSize
          visible: root.updateCount > 0 || !root.hideOnZero
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen, root);
      }
    }

    onEntered: {
      root.hovered = true;
      buildTooltip();
    }

    onExited: {
      root.hovered = false;
      TooltipService.hide();
    }

    function buildTooltip() {
      const lines = [];
      
      if (root.isChecking) {
        lines.push("Checking for updates...");
      } else if (root.updateCount > 0) {
        lines.push(`${root.updateCount} update${root.updateCount !== 1 ? 's' : ''} available`);
      } else {
        lines.push("System is up to date");
      }
      
      const lastCheck = root.pluginApi?.mainInstance?.lastCheckTime;
      if (lastCheck) {
        lines.push(`Last checked: ${lastCheck}`);
      }
      
      lines.push("\nClick to view details");

      TooltipService.show(lines.join("\n"));
    }
  }
}
