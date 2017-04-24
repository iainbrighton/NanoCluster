configuration NanoClusterS2DVolume {
<#
    .SYNOPSIS
        Creates a failover cluster
#>
    param (
        ## Name of the failover cluster/node (FQDN) to create the volume on.
        [Parameter(Mandatory)]
        [System.String]
        $ClusterName,

        ## Specifies an array of storage pool friendly names. The volume is created in the storage
        ## pools specified.
        [Parameter(Mandatory)]
        [System.String[]]
        $StoragePoolFriendlyName,

        ## Specifies a friendly name assigned to the volume.
        [Parameter(Mandatory)]
        [System.String]
        $FriendlyName,

        ## Credential used to create the cluster
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        ## Specifies the size of the volume - in bytes - to create. If not specified or a size of
        ## zero bytes is defined, all available space be used.
        [Parameter()]
        [System.UInt64]
        $Size,

        ## Specifies the file system to use for the volume. Defaults to CSVFS_ReFS.
        [Parameter()]
        [ValidateSet('CSVFS_NTFS','CSVFS_ReFS')]
        [System.String]
        $FileSystem = 'CSVFS_ReFS',

        ## Specifies the physical disk redundancy value to use during the creation of a volume on
        ## a Windows Storage subsystem. This value represents how many failed physical disks the
        ## volume can tolerate without data loss.
        [Parameter()]
        [System.UInt16]
        $PhysicalDiskRedundancy = 2,

        ## Specifies the type of provisioning. Specify Fixed for storage spaces that use storage
        ## tiers or a clustered storage pool
        [Parameter()]
        [ValidateSet('Fixed')]
        [System.String]
        $ProvisioningType = 'Fixed',

        ## By default, when you specify Mirror, Storage Spaces creates a two-way mirror, and when
        ## you specify Parity, Storage Spaces creates a single-parity space.
        [Parameter()]
        [ValidateSet('Mirror','Parity')]
        [System.String]
        $ResiliencySettingName = 'Mirror',

        ## Specifies the media type of the storage tier. Use SCM for storage-class memory such as
        ## NVDIMMs.
        [Parameter()]
        [ValidateSet('HDD','SSD','SCM')]
        [System.String]
        $MediaType = 'HDD'

        #[Parameter()]
        #[ValidateSet('Present','Absent')]
        #[System.String] $Ensure = 'Present'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration;

    Script "NanoClusterS2DVolume$($ClusterName.Replace('.',''))" {

        GetScript = {

            if (-not (Get-Module -Name Storage -ListAvailable))
            {
                throw ("Missing PowerShell 'Storage' module.");
            }

            $volume = Get-Volume -FileSystemLabel $using:FriendlyName -CimSession $using:ClusterName -ErrorAction SilentlyContinue;

            return @{ Result = $volume.FileSystemLabel; }

        } #end GetScript

        TestScript = {

            try
            {
                if (-not (Get-Module -Name Storage -ListAvailable))
                {
                    throw ("Missing PowerShell 'Storage' module.");
                }
                elseif (-not ($using:ClusterName).Contains('.'))
                {
                    Write-Warning -Message ("Cluster name should be specified as a FQDN");
                }

                $volume = Get-Volume -FileSystemLabel $using:FriendlyName -CimSession $using:ClusterName -ErrorAction SilentlyContinue;

                if ($null -eq $volume)
                {
                    Write-Verbose -Message ("Volume with friendly name '{0}' not present." -f $using:FriendlyName);
                    return $false;
                }
                else
                {
                    Write-Verbose -Message ("Volume with friendly name '{0}' already present." -f $using:FriendlyName);
                    return $true;
                }
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction Stop;
            }

        } #end TestScript

        SetScript = {

            try
            {
                $newVolumeParams = @{
                    StoragePoolFriendlyName = $using:StoragePoolFriendlyName;
                    FriendlyName = $using:FriendlyName;
                    FileSystem = $using:FileSystem;
                    PhysicalDiskRedundancy = $using:PhysicalDiskRedundancy;
                    ProvisioningType = $using:ProvisioningType;
                    ResiliencySettingName = $using:ResiliencySettingName;
                    MediaType = $using:MediaType;
                    CimSession = $using:ClusterName;
                }

                if ($using:Size -eq 0)
                {
                    $newVolumeParams['UseMaximumSize'] = $true;
                }
                else
                {
                    $newVolumeParams['Size'] = $using:Size;
                }

                New-Volume @newVolumeParams;
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction Stop;
            }

        } #end SetScript

        PsDscRunAsCredential = $Credential;

    } #end Script

} #end configuration
