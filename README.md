# Citrix_CVAD-Create-Vmware-User

PowerCLI script that creates a least-privilege vCenter role for the Citrix Virtual Apps and Desktops (CVAD)
hosting connection and assigns it to the Citrix service account – instead of giving Citrix vCenter administrator rights.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![PowerCLI](https://img.shields.io/badge/requires-VMware%20PowerCLI-717074)

## What it does

- Creates a custom vCenter role (default name `citrix`) with the privileges Citrix MCS needs:
  VM power operations, clone/deploy from template, snapshots, disks, datastore, network, custom fields
- Adds tagging and storage policy privileges on vSphere 7 and later
- If the role already exists, missing privileges are added (existing ones are never removed)
- Assigns the role to an existing user (AD or vsphere.local) on a datacenter, cluster or folder, with propagation
- Safe to run repeatedly

## Quickstart

```powershell
Install-Module VMware.PowerCLI -Scope CurrentUser
.\Create-CitrixVIServerRole.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'DC01'
```

Use `-Entity 'Datacenters'` (root folder) to grant the role on the whole vCenter. Run `Get-Help .\Create-CitrixVIServerRole.ps1 -Full` for all parameters.

> Detailed documentation is in German.

## Beschreibung (Deutsch)

Ziel ist es, den Benutzer, den Citrix für seine Aktionen in VMWare benutzt, mit dem Prinzip "Least-Privilege" anzulegen.

`Create-CitrixVIServerRole.ps1` legt im vCenter eine Rolle mit den von Citrix benötigten Rechten an
(bzw. ergänzt eine bestehende) und weist sie dem Citrix-Dienstkonto zu.

Voraussetzungen: VMware PowerCLI, ein bereits existierender Benutzer (AD oder vsphere.local).

```powershell
.\Create-CitrixVIServerRole.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'DC01'
```

Pflicht: `-viServer`, `-User`, `-Entity` (Name des Inventarobjekts, z. B. Datacenter oder Cluster;
die Berechtigung wird vererbt). Für das gesamte vCenter: `-Entity 'Datacenters'` (Root-Folder).

Optional: `-cvRole` (Rollenname, Standard `citrix`), `-Creds` (sonst Abfrage per `Get-Credential`).

## Lizenz

MIT, siehe [LICENSE](LICENSE).