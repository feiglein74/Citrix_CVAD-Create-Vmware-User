# Citrix_CreateVIServerUser

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