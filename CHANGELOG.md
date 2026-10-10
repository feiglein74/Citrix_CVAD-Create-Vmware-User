# Changelog

Alle relevanten Änderungen an diesem Projekt werden hier dokumentiert.
Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionierung nach [SemVer](https://semver.org/lang/de/).

## [0.3.0] - 2026-10-10

Rechteliste abgeglichen mit Citrix-Doku "Connection to VMware" (CVAD 2607 LTSR).

### Hinzugefügt
- Rolle `<cvRole>-root` mit `StorageProfile.*` und `InventoryService.Tagging.AttachTag`, zugewiesen auf dem Root-Folder ohne Vererbung (Vorgabe Citrix)
- `VirtualMachine.Config.Rename` (für MCS Pflicht)
- Schalter `-IncludeProvisioning`, `-IncludeImageSharing`, `-IncludeVTPM` für optionale Rechte
- `-WhatIf`/`-Confirm`-Unterstützung
- Warnung, wenn eine bestehende Berechtigung des Benutzers umgestellt wird

### Geändert
- **Breaking:** Skript umbenannt von `Create-CitrixVIServerRole.ps1` in `New-CitrixVIUser.ps1` (zugelassenes PowerShell-Verb)
- **Breaking:** `VirtualMachine.Provisioning.CloneTemplate` und `.DeployTemplate` nur noch mit `-IncludeProvisioning` (laut Citrix nur für Citrix Provisioning nötig)
- Tagging- und StorageProfile-Rechte unabhängig von der vSphere-Version (vorher erst ab 7)
- README: englischer Kopf (Kurzbeschreibung, Badges, What it does, Quickstart), Titel an Repo-Namen angepasst

### Entfernt
- `InventoryService.Tagging.ModifyUsedByForCategory` und `.ModifyUsedByForTag` (nicht in der Citrix-Doku). Bestehende Rollen behalten sie, da das Skript keine Rechte entfernt.

## [0.2.0] - 2026-10-10

### Hinzugefügt
- Parameter `-User`: Rolle wird dem angegebenen Benutzer zugewiesen (`New-VIPermission`, vererbt)
- Pflichtparameter `-Entity`: Name des Inventarobjekts, auf dem die Berechtigung gesetzt wird (Fehler bei keinem oder mehrdeutigem Treffer)
- LICENSE (MIT)
- Bestehende Berechtigung des Benutzers auf dem Objekt wird auf die Rolle umgestellt statt Fehler
- Projektdateien: TODO.md, CHANGELOG.md, DESIGN-PRINCIPLES.md, .gitignore, .gitattributes

### Geändert
- Tagging- und StorageProfile-Rechte werden ab vSphere 7 (statt nur 8) ergänzt
- `$Creds` ist als `PSCredential` typisiert
- Verbindung wird auch im Fehlerfall getrennt (`try/finally`)
- Hilfe mit echten Beispielen, Datei als UTF-8 mit BOM

### Behoben
- Doppelte Einträge in der Rechteliste entfernt
- Fehlermeldung bei noch nicht existierender Rolle unterdrückt; `New-VIRole` und `Set-VIRole` laufen nicht mehr doppelt

## [0.1.0] - Initial

### Hinzugefügt
- `Create-CitrixVIServerRole.ps1`: legt die Rolle für Citrix im vCenter an
