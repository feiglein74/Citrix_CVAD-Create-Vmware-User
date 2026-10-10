# Changelog

Alle relevanten Änderungen an diesem Projekt werden hier dokumentiert.
Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionierung nach [SemVer](https://semver.org/lang/de/).

## [Unreleased]

### Geändert
- README: englischer Kopf (Kurzbeschreibung, Badges, What it does, Quickstart), Titel an Repo-Namen angepasst

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
