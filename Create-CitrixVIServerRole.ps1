<#
.Synopsis
    Rolle in VMware vCenter für Citrix Virtual Apps and Desktops anlegen und einem Benutzer zuweisen
.DESCRIPTION
    Dieses Skript legt eine benutzerdefinierte Rolle in VMware vCenter Server an (bzw. ergänzt
    deren Rechte) und weist sie dem Dienstkonto zu, das Citrix für die Hosting-Verbindung nutzt.
    So muss der Citrix-Instanz nicht zwingend Administratoren-Rechte gegeben werden.

    Der Benutzer selbst muss bereits existieren (z. B. im AD oder in vsphere.local).
.NOTES
    Version: 0.2.0
.EXAMPLE
    .\Create-CitrixVIServerRole.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'DC01'

    Legt die Rolle "citrix" an und weist sie dem Benutzer auf dem Datacenter "DC01" zu,
    vererbt auf alle untergeordneten Objekte.
.EXAMPLE
    .\Create-CitrixVIServerRole.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -cvRole 'Citrix-MCS' -Entity 'Cluster-VDI'

    Weist die Rolle "Citrix-MCS" nur auf dem Cluster "Cluster-VDI" zu.
.EXAMPLE
    .\Create-CitrixVIServerRole.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'Datacenters'

    Weist die Rolle auf dem Root-Folder zu, also auf dem gesamten vCenter.
#>

[CmdletBinding()]
Param
(
    # VIServer Name oder IP
    [Parameter(Mandatory=$true)]
    $viServer,

    # Benutzer, dem die Rolle zugewiesen wird (z. B. DOMAIN\user oder user@vsphere.local)
    [Parameter(Mandatory=$true)]
    [string]$User,

    # Credentials für die Anmeldung am VIServer
    [System.Management.Automation.PSCredential]$Creds,

    # Name der Rolle
    $cvRole = "citrix",

    # Name des Inventarobjekts, auf dem die Berechtigung gesetzt wird (z. B. Datacenter oder Cluster)
    [Parameter(Mandatory=$true)]
    [string]$Entity
)



$cvRoleIds = @(
    'System.Anonymous',
    'System.Read',
    'System.View',
    'Datastore.AllocateSpace',
    'Datastore.Browse',
    'Datastore.FileManagement',
    'Global.ManageCustomFields',
    'Global.SetCustomField',
    'Network.Assign',
    'Resource.AssignVMToPool',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.AddRemoveDevice',
    'VirtualMachine.Config.AdvancedConfig',
    'VirtualMachine.Config.CPUCount',
    'VirtualMachine.Config.Memory',
    'VirtualMachine.Config.RemoveDisk',
    'VirtualMachine.Config.Settings',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Interact.Reset',
    'VirtualMachine.Interact.Suspend',
    'VirtualMachine.Inventory.Create',
    'VirtualMachine.Inventory.CreateFromExisting',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.Provisioning.Clone',
    'VirtualMachine.Provisioning.CloneTemplate',
    'VirtualMachine.Provisioning.DeployTemplate',
    'VirtualMachine.State.CreateSnapshot'
)



if (-not $Creds) {$Creds = Get-Credential}

Write-Verbose "Connect-VIServer -server $viServer -force -Credential $Creds"
$connection = Connect-VIServer -Server $viServer -Force -Credential $Creds -ErrorAction Stop

try {
    $vmVersion = [int]$connection.Version.Split(".")[0]

    if ($vmVersion -ge 7) {
        $cvRoleIds += @(
            'InventoryService.Tagging.AttachTag',
            'InventoryService.Tagging.CreateCategory',
            'InventoryService.Tagging.CreateTag',
            'InventoryService.Tagging.DeleteCategory',
            'InventoryService.Tagging.DeleteTag',
            'InventoryService.Tagging.EditCategory',
            'InventoryService.Tagging.EditTag',
            'InventoryService.Tagging.ModifyUsedByForCategory',
            'InventoryService.Tagging.ModifyUsedByForTag',
            'InventoryService.Tagging.ObjectAttachable',
            'StorageProfile.Update',
            'StorageProfile.View'
        )
    }

    $privileges = Get-VIPrivilege -Server $connection -Id $cvRoleIds

    # Rolle anlegen bzw. fehlende Rechte ergänzen
    $role = Get-VIRole -Server $connection -Name $cvRole -ErrorAction SilentlyContinue
    if (-not $role) {
        Write-Verbose "Lege Rolle '$cvRole' an"
        $role = New-VIRole -Server $connection -Name $cvRole -Privilege $privileges
    }
    else {
        Write-Verbose "Rolle '$cvRole' existiert, ergänze Rechte"
        $role = Set-VIRole -Server $connection -Role $role -AddPrivilege $privileges
    }

    # Rolle dem Benutzer zuweisen
    # Root-Folder explizit einbeziehen, da er nicht zwingend von Get-Inventory geliefert wird
    $entityObject = @(Get-Inventory -Server $connection -Name $Entity -ErrorAction SilentlyContinue) +
        @(Get-Folder -Server $connection -NoRecursion | Where-Object { $_.Name -eq $Entity }) |
        Sort-Object -Property Id -Unique
    $entityObject = @($entityObject)

    if ($entityObject.Count -eq 0) {
        throw "Kein Inventarobjekt mit dem Namen '$Entity' gefunden"
    }
    if ($entityObject.Count -gt 1) {
        $treffer = ($entityObject | ForEach-Object { "$($_.Name) [$($_.GetType().Name), $($_.Id)]" }) -join ', '
        throw "Der Name '$Entity' ist nicht eindeutig ($($entityObject.Count) Treffer): $treffer"
    }
    $entityObject = $entityObject[0]

    $permission = Get-VIPermission -Server $connection -Entity $entityObject -Principal $User -ErrorAction SilentlyContinue |
        Where-Object { $_.EntityId -eq $entityObject.Id }

    if ($permission) {
        Write-Verbose "Berechtigung für '$User' auf '$Entity' existiert, setze Rolle '$cvRole'"
        Set-VIPermission -Permission $permission -Role $role -Propagate:$true
    }
    else {
        Write-Verbose "Weise '$User' die Rolle '$cvRole' auf '$Entity' zu"
        New-VIPermission -Server $connection -Entity $entityObject -Principal $User -Role $role -Propagate:$true
    }
}
finally {
    Disconnect-VIServer -Server $connection -Confirm:$false
}
