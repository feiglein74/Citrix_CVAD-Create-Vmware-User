<#
.Synopsis
    Rolle in VWMARE für Citrix Virtual Apps and Desktops anlegen
.DESCRIPTION
    Dieses Commandlet legt eine Benutzerdefinierte Rolle in VMWARE vCenter Server an, 
    um der Citrix Instanz nicht zwingend Administratoren-Rechte zu geben.
.EXAMPLE
    Beispiel für die Verwendung dieses Cmdlets
.EXAMPLE
    Ein weiteres Beispiel für die Verwendung dieses Cmdlets
#>

[CmdletBinding()]
Param
(
    # VIServer Name oder IP
    
    [Parameter(Mandatory=$true)]
    $viServer,

    # Credentials für die Anmeldung am VIServer
    $Creds,
    $cvRole = "citrix"
)



$cvRoleIds = @(
'System.Anonymous',
'System.Read',
'System.View',
'VirtualMachine.Interact.PowerOff',
'VirtualMachine.Interact.PowerOn',
'VirtualMachine.Interact.Reset',
'VirtualMachine.Interact.Suspend',
'Datastore.AllocateSpace',
'Datastore.Browse',
'Datastore.FileManagement',
'Network.Assign',
'Resource.AssignVMToPool',
'VirtualMachine.Config.AddExistingDisk',
'VirtualMachine.Config.AddNewDisk',
'VirtualMachine.Config.AdvancedConfig',
'VirtualMachine.Config.RemoveDisk',
'VirtualMachine.Config.CPUCount',
'VirtualMachine.Config.Memory',
'VirtualMachine.Config.Settings',
'VirtualMachine.Interact.PowerOff',
'VirtualMachine.Interact.PowerOn',
'VirtualMachine.Interact.Reset',
'VirtualMachine.Interact.Suspend',
'VirtualMachine.Inventory.CreateFromExisting',
'VirtualMachine.Inventory.Create',
'VirtualMachine.Inventory.Delete',
'VirtualMachine.Provisioning.Clone',
'VirtualMachine.State.CreateSnapshot',
'Datastore.AllocateSpace',
'Datastore.Browse',
'Datastore.FileManagement',
'Network.Assign',
'Resource.AssignVMToPool',
'VirtualMachine.Config.AddExistingDisk',
'VirtualMachine.Config.AddNewDisk',
'VirtualMachine.Config.AdvancedConfig',
'VirtualMachine.Config.RemoveDisk',
'VirtualMachine.Interact.PowerOff',
'VirtualMachine.Interact.PowerOn',
'VirtualMachine.Interact.Reset',
'VirtualMachine.Inventory.CreateFromExisting',
'VirtualMachine.Inventory.Create',
'VirtualMachine.Inventory.Delete',
'VirtualMachine.Provisioning.Clone',
'Datastore.Browse',
'Datastore.FileManagement',
'VirtualMachine.Config.RemoveDisk',
'VirtualMachine.Interact.PowerOff',
'VirtualMachine.Inventory.Delete',
'Global.ManageCustomFields',
'Global.SetCustomField',
'VirtualMachine.Config.AddRemoveDevice',
'VirtualMachine.Config.CPUCount',
'VirtualMachine.Config.Memory',
'VirtualMachine.Config.Settings',
'VirtualMachine.Provisioning.CloneTemplate',
'VirtualMachine.Provisioning.DeployTemplate'
)



if (-not $creds) {$creds = Get-Credential}

Write-Verbose "Connect-VIServer -server $viserver -force -Credential $creds"
$connection = Connect-VIServer -server $viserver -force -Credential $creds

$vmVersion = ($global:DefaultVIServer).version.split(".")[0]

if ($vmVersion -eq 8) {
    $cvRoleIdsVersion8 = @('InventoryService.Tagging.AttachTag',
    'InventoryService.Tagging.ModifyUsedByForCategory',
    'InventoryService.Tagging.DeleteCategory',
    'InventoryService.Tagging.EditTag',
    'InventoryService.Tagging.ModifyUsedByForTag',
    'InventoryService.Tagging.CreateTag',
    'InventoryService.Tagging.DeleteTag',
    'InventoryService.Tagging.ObjectAttachable',
    'StorageProfile.Update',
    'StorageProfile.View',
    'InventoryService.Tagging.EditCategory',
    'InventoryService.Tagging.CreateCategory'
    )

    $cvRoleIds = $cvRoleIds + $cvRoleIdsVersion8

}

if ($vmVersion -eq 7) {

}

if ($vmVersion -eq 6) {

}

if (-not (Get-VIRole -name $cvRole)) {
    New-VIRole -name $cvRole -Privilege (Get-VIPrivilege -Server $viserver -id $cvRoleIds) -Server $viserver 
}

$response = Set-VIRole -Role $cvRole -AddPrivilege (Get-VIPrivilege -Server $viserver -id $cvRoleIds) -Server $viserver 

Disconnect-VIServer -server $viserver -Confirm:$false