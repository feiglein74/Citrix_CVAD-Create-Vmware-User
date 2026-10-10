<#
.Synopsis
    Rolle in VMware vCenter für Citrix Virtual Apps and Desktops anlegen und einem Benutzer zuweisen
.DESCRIPTION
    Dieses Skript legt eine benutzerdefinierte Rolle in VMware vCenter Server an (bzw. ergänzt
    deren Rechte) und weist sie dem Dienstkonto zu, das Citrix für die Hosting-Verbindung nutzt.
    So muss der Citrix-Instanz nicht zwingend Administratoren-Rechte gegeben werden.

    Die Rechte entsprechen der Citrix-Doku "Connection to VMware" (CVAD 2607 LTSR):
    - Rolle <cvRole> (auf -Entity, vererbt): Add connections, Power management, MCS-Provisionierung,
      Image update, Delete, Tags und Custom Attributes
    - Rolle <cvRole>-root (auf dem Root-Folder, nicht vererbt): StorageProfile.Update,
      StorageProfile.View, InventoryService.Tagging.AttachTag

    Optionale Rechte nur per Schalter: -IncludeProvisioning, -IncludeImageSharing, -IncludeVTPM.

    Rechte werden nur ergänzt, nie entfernt. Der Benutzer selbst muss bereits existieren
    (z. B. im AD oder in vsphere.local).
.NOTES
    Version: 0.3.0
.LINK
    https://docs.citrix.com/en-us/citrix-virtual-apps-desktops/2607-ltsr/install-configure/connections/connection-vmware-virtualization-environments
.EXAMPLE
    .\New-CitrixVIUser.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'DC01'

    Legt die Rollen "citrix" und "citrix-root" an. "citrix" wird dem Benutzer auf dem Datacenter "DC01"
    zugewiesen (vererbt), "citrix-root" auf dem Root-Folder (nicht vererbt).
.EXAMPLE
    .\New-CitrixVIUser.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'Cluster-VDI' -IncludeProvisioning -IncludeVTPM

    Zusätzlich Rechte für Citrix Provisioning / Machine Profile und für VMs mit vTPM.
.EXAMPLE
    .\New-CitrixVIUser.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'Datacenters'

    Weist die Rolle "citrix" auf dem Root-Folder zu, also auf dem gesamten vCenter. Die Root-Rechte
    werden dann in "citrix" aufgenommen, eine Rolle "citrix-root" wird nicht angelegt.
.EXAMPLE
    .\New-CitrixVIUser.ps1 -viServer vcenter.contoso.local -User 'CONTOSO\svc-citrix' -Entity 'DC01' -WhatIf

    Zeigt nur an, welche Rollen und Berechtigungen angelegt oder geändert würden.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
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

    # Name der Rolle (die Root-Rolle heißt "<cvRole>-root")
    $cvRole = "citrix",

    # Name des Inventarobjekts, auf dem die Berechtigung gesetzt wird (z. B. Datacenter oder Cluster)
    [Parameter(Mandatory=$true)]
    [string]$Entity,

    # Rechte für Citrix Provisioning (Setup-/Export-Devices-Wizard) und MCS-Kataloge mit Machine Profile
    [switch]$IncludeProvisioning,

    # Rechte, um vorbereitete Images zwischen Hosting-Verbindungen zu teilen
    [switch]$IncludeImageSharing,

    # Rechte für MCS-Kataloge mit vTPM (Cryptographic operations)
    [switch]$IncludeVTPM
)



# Rechte auf -Entity (vererbt)
$cvRoleIds = @(
    # Add connections and resources
    'System.Anonymous',
    'System.Read',
    'System.View',
    # Power management, Provision machines (MCS), Image update, Delete provisioned machines
    'Datastore.AllocateSpace',
    'Datastore.Browse',
    'Datastore.FileManagement',
    'Network.Assign',
    'Resource.AssignVMToPool',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.AddRemoveDevice',
    'VirtualMachine.Config.AdvancedConfig',
    'VirtualMachine.Config.CPUCount',
    'VirtualMachine.Config.Memory',
    'VirtualMachine.Config.RemoveDisk',
    'VirtualMachine.Config.Rename',
    'VirtualMachine.Config.Settings',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Interact.Reset',
    'VirtualMachine.Interact.Suspend',
    'VirtualMachine.Inventory.Create',
    'VirtualMachine.Inventory.CreateFromExisting',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.Provisioning.Clone',
    'VirtualMachine.State.CreateSnapshot',
    # Tags and Custom Attributes
    'Global.ManageCustomFields',
    'Global.SetCustomField',
    'InventoryService.Tagging.AttachTag',
    'InventoryService.Tagging.CreateCategory',
    'InventoryService.Tagging.CreateTag',
    'InventoryService.Tagging.DeleteCategory',
    'InventoryService.Tagging.DeleteTag',
    'InventoryService.Tagging.EditCategory',
    'InventoryService.Tagging.EditTag',
    'InventoryService.Tagging.ObjectAttachable'
)

# Rechte auf dem Root-Folder (nicht vererbt), laut Citrix nur dort wirksam
$cvRootRoleIds = @(
    'System.Anonymous',
    'System.Read',
    'System.View',
    'StorageProfile.Update',
    'StorageProfile.View',
    'InventoryService.Tagging.AttachTag'
)

if ($IncludeProvisioning) {
    $cvRoleIds += @(
        'VirtualMachine.Provisioning.CloneTemplate',
        'VirtualMachine.Provisioning.DeployTemplate',
        'VApp.Export'
    )
}

if ($IncludeImageSharing) {
    $cvRoleIds += @(
        'VirtualMachine.Inventory.Register'
    )
}

if ($IncludeVTPM) {
    $cvRoleIds += @(
        'Cryptographer.Access',
        'Cryptographer.AddDisk',
        'Cryptographer.Clone',
        'Cryptographer.Decrypt',
        'Cryptographer.Encrypt',
        'Cryptographer.EncryptNew',
        'Cryptographer.Migrate',
        'Cryptographer.ReadKeyServersInfo'
    )
}



function Set-CitrixRole {
    # Legt die Rolle an oder ergänzt fehlende Rechte (entfernt keine)
    [CmdletBinding(SupportsShouldProcess=$true)]
    param($Connection, [string]$Name, [string[]]$PrivilegeIds)

    $privileges = Get-VIPrivilege -Server $Connection -Id $PrivilegeIds -ErrorAction Stop
    $role = Get-VIRole -Server $Connection -Name $Name -ErrorAction SilentlyContinue
    if (-not $role) {
        if ($PSCmdlet.ShouldProcess($Name, "Rolle anlegen ($($privileges.Count) Rechte)")) {
            return New-VIRole -Server $Connection -Name $Name -Privilege $privileges -Confirm:$false
        }
        # -WhatIf: Platzhalter, damit die folgende Zuweisung angezeigt werden kann
        return [pscustomobject]@{ Name = $Name }
    }
    if ($PSCmdlet.ShouldProcess($Name, "Rechte ergänzen ($($privileges.Count) Rechte angefordert)")) {
        return Set-VIRole -Server $Connection -Role $role -AddPrivilege $privileges -Confirm:$false
    }
    return $role
}

function Set-CitrixPermission {
    # Weist die Rolle auf dem Objekt zu; eine vorhandene Berechtigung des Benutzers wird umgestellt
    [CmdletBinding(SupportsShouldProcess=$true)]
    param($Connection, $EntityObject, [string]$Principal, $Role, [bool]$Propagate)

    $permission = Get-VIPermission -Server $Connection -Entity $EntityObject -Principal $Principal -ErrorAction SilentlyContinue |
        Where-Object { $_.EntityId -eq $EntityObject.Id }
    $target = "$Principal auf '$($EntityObject.Name)'"

    if ($permission) {
        if ($permission.Role -ne $Role.Name -or $permission.Propagate -ne $Propagate) {
            Write-Warning ("Berechtigung für $target wird geändert: " +
                "Rolle '$($permission.Role)' -> '$($Role.Name)', Propagate $($permission.Propagate) -> $Propagate")
        }
        if ($PSCmdlet.ShouldProcess($target, "Berechtigung auf Rolle '$($Role.Name)' setzen (Propagate: $Propagate)")) {
            return Set-VIPermission -Permission $permission -Role $Role -Propagate:$Propagate -Confirm:$false
        }
        return
    }
    if ($PSCmdlet.ShouldProcess($target, "Rolle '$($Role.Name)' zuweisen (Propagate: $Propagate)")) {
        return New-VIPermission -Server $Connection -Entity $EntityObject -Principal $Principal -Role $Role -Propagate:$Propagate -Confirm:$false
    }
}



if (-not $Creds) {$Creds = Get-Credential}

Write-Verbose "Connect-VIServer -server $viServer -force -Credential $Creds"
$connection = Connect-VIServer -Server $viServer -Force -Credential $Creds -ErrorAction Stop

try {
    $rootFolder = Get-Folder -Server $connection -NoRecursion

    # Root-Folder explizit einbeziehen, da er nicht zwingend von Get-Inventory geliefert wird
    $entityObject = @(Get-Inventory -Server $connection -Name $Entity -ErrorAction SilentlyContinue) +
        @($rootFolder | Where-Object { $_.Name -eq $Entity }) |
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

    if ($entityObject.Id -eq $rootFolder.Id) {
        # Pro Benutzer und Objekt gibt es nur eine Berechtigung: Root-Rechte in die Hauptrolle aufnehmen
        Write-Verbose "-Entity ist der Root-Folder: Root-Rechte werden in Rolle '$cvRole' aufgenommen"
        $role = Set-CitrixRole -Connection $connection -Name $cvRole -PrivilegeIds ($cvRoleIds + $cvRootRoleIds | Select-Object -Unique)
        Set-CitrixPermission -Connection $connection -EntityObject $entityObject -Principal $User -Role $role -Propagate $true
    }
    else {
        $role = Set-CitrixRole -Connection $connection -Name $cvRole -PrivilegeIds $cvRoleIds
        $rootRole = Set-CitrixRole -Connection $connection -Name "$cvRole-root" -PrivilegeIds $cvRootRoleIds

        Set-CitrixPermission -Connection $connection -EntityObject $entityObject -Principal $User -Role $role -Propagate $true
        Set-CitrixPermission -Connection $connection -EntityObject $rootFolder -Principal $User -Role $rootRole -Propagate $false
    }
}
finally {
    Disconnect-VIServer -Server $connection -Confirm:$false -WhatIf:$false
}
