# TODO

- [ ] Skript gegen ein Test-vCenter ausführen (bisher nur Syntax, PSScriptAnalyzer und Lauf gegen gemockte PowerCLI-Cmdlets)
- [ ] Prüfen, ob `-Entity 'Datacenters'` (Root-Folder) im echten vCenter aufgelöst wird
- [ ] Prüfen, ob alle Rechte-IDs (v. a. `Cryptographer.*`, `VApp.Export`) im Ziel-vCenter existieren – `Get-VIPrivilege` bricht sonst ab
- [ ] Optional: Schalter zum Entfernen nicht mehr benötigter Rechte (z. B. alte `ModifyUsedBy*`) – nur explizit
- [x] Rechteliste mit der Citrix-Doku (CVAD 2607 LTSR) abgeglichen
- [x] `-Entity` als Pflichtparameter
- [x] LICENSE (MIT)
- [x] Umbenannt in `New-CitrixVIUser.ps1` (zugelassenes PowerShell-Verb)
