// Nota: questo file è per un futuro Widget Extension target.
// Attualmente il widget viene mostrato come preview in-app.
// Per abilitare il widget sulla Home Screen di iOS, è necessario:
// 1. Aggiungere un Widget Extension target in Xcode
// 2. Configurare un App Group condiviso
// 3. Spostare questo file e SpeedTrackerWidgetBundle.swift nel target extension

import WidgetKit
import SwiftUI

// Il modello TelemetryWidgetEntry e SpeedTelemetryWidgetView sono definiti
// in SpeedTracker/Views/Components/SpeedTrackerWidgets.swift per il main target.
// In un widget extension, si userebbero versioni con TimelineEntry conformance.
