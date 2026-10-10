# Citrix_CVAD-Create-Vmware-User

PowerCLI script that creates a least-privilege vCenter role for the Citrix Virtual Apps and Desktops (CVAD)
hosting connection and assigns it to the Citrix service account – instead of giving Citrix vCenter administrator rights.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![PowerCLI](https://img.shields.io/badge/requires-VMware%20PowerCLI-717074)

## What it does

Privileges follow the Citrix documentation
[Connection to VMware](https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/2607-ltsr/install-configure/connections/connection-vmware-virtualization-environments) (CVAD 2607 LTSR):

- Creates the role `citrix` with what MCS needs (power management, provisioning, image update, delete,
  tags and custom attributes) and assigns it on a datacenter, cluster or folder **with** propagation
- Creates the role `citrix-root` (storage policies, attach tag) and assigns it on the vCenter root folder
  **without** propagation, as Citrix requires
- Optional privileges only on request: `-IncludeProvisioning` (Citrix Provisioning, machine profiles),
  `-IncludeImageSharing` (share prepared images), `-IncludeVTPM` (VMs with vTPM)
- Existing roles get missing privileges added – nothing is ever removed
- Safe to run repeatedly, supports `-WhatIf`

## Quickstart

```powershell
Install-Module VMware.PowerCLI -Scope CurrentUser
.\New-CitrixVIUser.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'DC01'
```

Use `-Entity 'Datacenters'` (root folder) to grant the role on the whole vCenter. Run `Get-Help .\New-CitrixVIUser.ps1 -Full` for all parameters.

> Detailed documentation is in German.

## Beschreibung (Deutsch)

Ziel ist es, den Benutzer, den Citrix für seine Aktionen in VMWare benutzt, mit dem Prinzip "Least-Privilege" anzulegen.

`New-CitrixVIUser.ps1` legt im vCenter eine Rolle mit den von Citrix benötigten Rechten an
(bzw. ergänzt eine bestehende) und weist sie dem Citrix-Dienstkonto zu.

Voraussetzungen: VMware PowerCLI, ein bereits existierender Benutzer (AD oder vsphere.local).

```powershell
.\New-CitrixVIUser.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'DC01'
```

Pflicht: `-viServer`, `-User`, `-Entity` (Name des Inventarobjekts, z. B. Datacenter oder Cluster;
die Berechtigung wird vererbt). Für das gesamte vCenter: `-Entity 'Datacenters'` (Root-Folder).

Optional: `-cvRole` (Rollenname, Standard `citrix`), `-Creds` (sonst Abfrage per `Get-Credential`), `-WhatIf`.

### Rollen und Zuweisung

| Rolle | Zugewiesen auf | Vererbt | Inhalt |
|---|---|---|---|
| `<cvRole>` | `-Entity` | ja | Power Management, MCS-Provisionierung, Image Update, Löschen, Tags und Custom Attributes |
| `<cvRole>-root` | Root-Folder des vCenters | nein | `StorageProfile.Update`, `StorageProfile.View`, `InventoryService.Tagging.AttachTag` |

Ist `-Entity` selbst der Root-Folder, landen alle Rechte in `<cvRole>` (pro Benutzer und Objekt gibt es nur eine Berechtigung).
Hat der Benutzer auf einem der Objekte schon eine andere Berechtigung, wird sie umgestellt – mit Warnung.

### Optionale Rechte (Opt-in)

| Schalter | Rechte | Wofür |
|---|---|---|
| `-IncludeProvisioning` | `VirtualMachine.Provisioning.CloneTemplate`, `.DeployTemplate`, `VApp.Export` | Citrix Provisioning (Setup-/Export-Devices-Wizard), MCS-Kataloge mit Machine Profile |
| `-IncludeImageSharing` | `VirtualMachine.Inventory.Register` | Vorbereitete Images zwischen Hosting-Verbindungen teilen |
| `-IncludeVTPM` | `Cryptographer.*` (8 Rechte) | MCS-Kataloge mit vTPM |

## Lizenz

MIT, siehe [LICENSE](LICENSE).