//@ pragma RespectSystemStyle

import QtQuick
import Quickshell
import qs.services
import "features/bar"
import "features/osd"

ShellRoot {
  Bar {}
  OSD {}
}
