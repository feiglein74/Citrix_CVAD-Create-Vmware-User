# Design-Prinzipien für Citrix_CVAD-Create-Vmware-User

## Leitprinzipien

### 1. Least-Privilege
Das Citrix-Dienstkonto bekommt nur die Rechte, die Citrix für die Hosting-Verbindung braucht – keine Administratorrolle.

```powershell
# ❌ FALSCH - Dienstkonto bekommt Admin
New-VIPermission -Entity $root -Principal 'CONTOSO\svc-citrix' -Role Admin

# ✅ RICHTIG - eigene Rolle mit definierter Rechteliste
New-VIPermission -Entity $root -Principal 'CONTOSO\svc-citrix' -Role citrix
```

### 2. Vollständigkeit vor Kürze
Ausgaben der PowerCLI-Cmdlets (angelegte Rolle, Berechtigung) werden nicht unterdrückt. Fehler werden vollständig angezeigt.

### 3. Explizit vor Implizit / Transparenz bei Modifikationen
Was das Skript tut, ist per `-Verbose` nachvollziehbar (Rolle angelegt oder ergänzt, Berechtigung neu oder umgestellt).

## Projekt-spezifische Entscheidungen

### Wiederholbar ausführbar (idempotent)
Das Skript kann mehrfach laufen, ohne Fehler und ohne Duplikate.

```powershell
# ❌ FALSCH - zweiter Lauf scheitert, weil Rolle/Berechtigung schon existiert
New-VIRole -Name $cvRole -Privilege $privileges
New-VIPermission -Entity $Entity -Principal $User -Role $cvRole

# ✅ RICHTIG - vorhandene Rolle ergänzen, vorhandene Berechtigung umstellen
if ($role) { Set-VIRole -Role $role -AddPrivilege $privileges } else { New-VIRole ... }
if ($permission) { Set-VIPermission -Permission $permission -Role $role } else { New-VIPermission ... }
```

**Warum?** Neue Citrix- oder vSphere-Versionen brauchen ggf. zusätzliche Rechte. Ein erneuter Lauf ergänzt sie, ohne die Rolle löschen zu müssen.

### Rechte werden nur ergänzt, nie entfernt
`Set-VIRole -AddPrivilege` entfernt keine Rechte, die manuell hinzugefügt wurden. Das Skript überschreibt also keine bewussten Anpassungen im vCenter.

### Rechteliste = Citrix-Doku
Grundlage ist die Citrix-Doku "Connection to VMware" (aktuell CVAD 2607 LTSR). Rechte, die dort nicht stehen,
kommen nicht in die Rolle; Rechte, die nur für bestimmte Funktionen nötig sind, gibt es nur per Schalter.

```powershell
# ❌ FALSCH - alles für alle Fälle, z. B. Cryptographer.* auch ohne vTPM
$cvRoleIds += $cryptoIds

# ✅ RICHTIG - Opt-in, sichtbar im Aufruf
.\New-CitrixVIUser.ps1 ... -IncludeVTPM
```

**Warum?** Least-Privilege. Die Einschränkung ist dokumentiert (README, `Get-Help`) und per Schalter aufhebbar.

### Zwei Rollen statt einer
Citrix verlangt `StorageProfile.*` und `InventoryService.Tagging.AttachTag` auf dem Root-Folder **ohne** Vererbung,
alles andere auf Datacenter-Ebene oder darunter **mit** Vererbung. Eine einzige Rolle auf dem Root-Folder ohne
Vererbung würde die VM-Rechte wirkungslos machen, mit Vererbung gäbe es Rechte auf dem ganzen vCenter.
Daher: `<cvRole>` auf `-Entity` (vererbt) und `<cvRole>-root` auf dem Root-Folder (nicht vererbt).

Ausnahme: Ist `-Entity` der Root-Folder, wird alles in `<cvRole>` zusammengeführt, weil vCenter pro Benutzer
und Objekt nur eine Berechtigung erlaubt.

### Bestehende Berechtigungen werden umgestellt – sichtbar
Hat der Benutzer auf dem Objekt schon eine andere Rolle, wird sie ersetzt und eine Warnung ausgegeben
(alte → neue Rolle, Propagate). Mit `-WhatIf` lässt sich vorher sehen, was passiert.

### Benutzer wird nicht angelegt
Das Konto muss vorher existieren (AD oder vsphere.local). PowerCLI kann keine AD-Konten anlegen, und das Anlegen von Konten gehört nicht in ein Berechtigungsskript.

### `-Entity` ist Pflicht – kein Default
Wo das Konto Rechte bekommt, muss bewusst angegeben werden.

```powershell
# ❌ FALSCH - impliziter Default: Rechte auf dem gesamten vCenter
.\New-CitrixVIUser.ps1 -viServer vc01 -User 'CONTOSO\svc-citrix'

# ✅ RICHTIG - Geltungsbereich explizit
.\New-CitrixVIUser.ps1 -viServer vc01 -User 'CONTOSO\svc-citrix' -Entity 'Cluster-VDI'
```

**Warum?** Ein Default "gesamtes vCenter" widerspricht Least-Privilege und überrascht Admins.
**Test-Kriterium**: "Wird ein Admin überrascht sein, dass das Konto Rechte auf allen Clustern hat?" → Ja → kein Default.

`-Entity` ist ein Name (kein Objekt), weil das Skript die Verbindung selbst aufbaut. Ist der Name mehrdeutig,
bricht das Skript ab und listet alle Treffer – es wird nie stillschweigend der erste genommen.

## Merksatz

> **"Der Default ist die Wahrheit, Einschränkungen sind explizit."**
