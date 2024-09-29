
#region functions
function Get-PSScriptAnalyzerError
{
    <#
        .SYNOPSIS
            Create DiagnosticRecord
        .DESCRIPTION
            Create an output that PSScriptAnalyzer expects as finding.
        .PARAMETER Extent
            Powershell IScriptExtent
        .PARAMETER Description
            Description of the finding
        .PARAMETER Correction
            Proposal to correct the finding
        .PARAMETER Message
            Message displayed by PSScriptAnalyzer
        .PARAMETER RuleName
            PSScriptAnalyzer rule name
        .PARAMETER Severity
            Severity of the finding
        .PARAMETER RuleSuppressionID
            Rule suppression ID
        .LINK
            https://github.com/PowerShell/PSScriptAnalyzer
    #>
    param(
        [parameter( Mandatory )]
        [ValidateNotNull()]
        [System.Management.Automation.Language.IScriptExtent]$Extent,
        [string]$Description = [string]::Empty,
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [string]$Correction,
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [string]$Message = [string]::Empty,
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [string]$RuleName,
        [string]$Severity = "Warning",
        [string]$RuleSuppressionID = "RuleSuppressionID"
    )

    [int]$startLineNumber =  $Extent.StartLineNumber
    [int]$endLineNumber = $Extent.EndLineNumber
    [int]$startColumnNumber = $Extent.StartColumnNumber
    [int]$endColumnNumber = $Extent.EndColumnNumber
    [string]$correction = $Correction
    [string]$optionalDescription = $Description
    $objParams = @{
    TypeName = 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent'
    ArgumentList = $startLineNumber, $endLineNumber, $startColumnNumber,
                    $endColumnNumber, $correction, $optionalDescription
    }
    $correctionExtent = New-Object @objParams
    $suggestedCorrections = New-Object System.Collections.ObjectModel.Collection[$($objParams.TypeName)]
    $suggestedCorrections.add($correctionExtent) | Out-Null

    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
        "Message"              = $Message
        "Extent"               = $Extent
        "RuleName"             = $RuleName
        "Severity"             = $Severity
        "RuleSuppressionID"    = $RuleSuppressionID
        "SuggestedCorrections" = $suggestedCorrections
    }
}

function Get-DeprecatedFunction
{
    <#
        .SYNOPSIS
            Get cmdlet names from deprecated modules AZUREAD, AZUREADPREVIEW and MSONLINE
        .DESCRIPTION
            Create a Hashtable for cmdlets from deprecated Powershell modules AZUREAD, AZUREADPREVIEW and MSONLINE
        .LINK
            https://techcommunity.microsoft.com/t5/microsoft-entra-azure-ad-blog/important-azure-ad-graph-retirement-and-powershell-module/ba-p/3848270
    #>
    [cmdletbinding()]
    [OutputType([hashtable])]
    param()
    #region deprecated functions
    $deprecatedFunctions = @'
[
    {
        "Name":  "Add-MsolAdministrativeUnitMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Add-MsolForeignGroupToRole",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Add-MsolGroupMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Add-MsolRoleMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Add-MsolScopedRoleMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Confirm-MsolDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Confirm-MsolEmailVerifiedDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Connect-MsolService",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Convert-MsolDomainToFederated",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Convert-MsolDomainToStandard",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Convert-MsolFederatedUser",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Disable-MsolDevice",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Enable-MsolDevice",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolAccountSku",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolAdministrativeUnit",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolAdministrativeUnitMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolCompanyAllowedDataLocation",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolCompanyInformation",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolContact",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolDevice",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolDeviceRegistrationServicePolicy",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolDirSyncConfiguration",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolDirSyncFeatures",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolDirSyncProvisioningError",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolDomainFederationSettings",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolDomainVerificationDns",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolFederationProperty",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolGroup",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolGroupMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolHasObjectsWithDirSyncProvisioningErrors",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolPartnerContract",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolPartnerInformation",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolPasswordPolicy",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolRole",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolRoleMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolScopedRoleMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolServicePrincipal",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolServicePrincipalCredential",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolSubscription",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolUser",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolUserByStrongAuthentication",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-MsolUserRole",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolAdministrativeUnit",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolFederatedDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolGroup",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolLicenseOptions",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolServicePrincipal",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolServicePrincipalAddresses",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolServicePrincipalCredential",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolUser",
        "Source":  "MSOnline"
    },
    {
        "Name":  "New-MsolWellKnownGroup",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Redo-MsolProvisionContact",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Redo-MsolProvisionGroup",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Redo-MsolProvisionUser",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolAdministrativeUnit",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolAdministrativeUnitMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolApplicationPassword",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolContact",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolDevice",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolFederatedDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolForeignGroupFromRole",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolGroup",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolGroupMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolRoleMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolScopedRoleMember",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolServicePrincipal",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolServicePrincipalCredential",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Remove-MsolUser",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Reset-MsolStrongAuthenticationMethodByUpn",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Restore-MsolUser",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolADFSContext",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolAdministrativeUnit",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolCompanyAllowedDataLocation",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolCompanyContactInformation",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolCompanyMultiNationalEnabled",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolCompanySecurityComplianceContactInformation",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolCompanySettings",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolDeviceRegistrationServicePolicy",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolDirSyncConfiguration",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolDirSyncEnabled",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolDirSyncFeature",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolDomainAuthentication",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolDomainFederationSettings",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolGroup",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolPartnerInformation",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolPasswordPolicy",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolServicePrincipal",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolUser",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolUserLicense",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolUserPassword",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Set-MsolUserPrincipalName",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Update-MsolFederatedDomain",
        "Source":  "MSOnline"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnectorGroupMembers",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADApplicationOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADDeviceRegisteredOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADDeviceRegisteredUser",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADDirectoryRoleMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADGroupMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADGroupOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADMSAdministrativeUnitMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADMSApplicationOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADMSLifecyclePolicyGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADMSScopedRoleMembership",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADMSServicePrincipalDelegatedPermissionClassification",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADServicePrincipalOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Confirm-AzureADDomain",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Connect-AzureAD",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Disconnect-AzureAD",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Enable-AzureADDirectoryRole",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationExtensionProperty",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationKeyCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationLogo",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationPasswordCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationProxyApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationProxyApplicationConnectorGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnector",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnectorGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnectorGroupMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnectorMemberOf",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADApplicationServiceEndpoint",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADContact",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADContactDirectReport",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADContactManager",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADContactMembership",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADContactThumbnailPhoto",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADContract",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADCurrentSessionInfo",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDeletedApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDevice",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDeviceConfiguration",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDeviceRegisteredOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDeviceRegisteredUser",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDirectoryRole",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDirectoryRoleMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDirectoryRoleTemplate",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDomain",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDomainNameReference",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDomainServiceConfigurationRecord",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADDomainVerificationDnsRecord",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADExtensionProperty",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADGroupAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADGroupMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADGroupOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSAdministrativeUnit",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSAdministrativeUnitMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSApplicationExtensionProperty",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSApplicationOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSAuthorizationPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSConditionalAccessPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSDeletedDirectoryObject",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSDeletedGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSGroupLifecyclePolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSGroupPermissionGrant",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSIdentityProvider",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSLifecyclePolicyGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSNamedLocationPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSPermissionGrantConditionSet",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSPermissionGrantPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSRoleDefinition",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSScopedRoleMembership",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADMSServicePrincipalDelegatedPermissionClassification",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADOAuth2PermissionGrant",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADObjectByObjectId",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServiceAppRoleAssignedTo",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServiceAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServicePrincipal",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServicePrincipalCreatedObject",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServicePrincipalKeyCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServicePrincipalMembership",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServicePrincipalOAuth2PermissionGrant",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServicePrincipalOwnedObject",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServicePrincipalOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADServicePrincipalPasswordCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADSubscribedSku",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADTenantDetail",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADTrustedCertificateAuthority",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUser",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserCreatedObject",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserDirectReport",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserExtension",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserLicenseDetail",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserManager",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserMembership",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserOAuth2PermissionGrant",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserOwnedDevice",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserOwnedObject",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserRegisteredDevice",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-AzureADUserThumbnailPhoto",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Get-CrossCloudVerificationCode",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADApplicationExtensionProperty",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADApplicationKeyCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADApplicationPasswordCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADApplicationProxyApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADApplicationProxyConnectorGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADDevice",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADDomain",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADGroupAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSAdministrativeUnit",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSApplicationExtensionProperty",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSApplicationKey",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSApplicationPassword",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSConditionalAccessPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSGroupLifecyclePolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSIdentityProvider",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSInvitation",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSNamedLocationPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSPermissionGrantConditionSet",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSPermissionGrantPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADMSRoleDefinition",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADServiceAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADServicePrincipal",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADServicePrincipalKeyCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADServicePrincipalPasswordCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADTrustedCertificateAuthority",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADUser",
        "Source":  "AzureAd"
    },
    {
        "Name":  "New-AzureADUserAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADApplicationExtensionProperty",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADApplicationKeyCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADApplicationOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADApplicationPasswordCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADApplicationProxyApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADApplicationProxyApplicationConnectorGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADApplicationProxyConnectorGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADContact",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADContactManager",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADDeletedApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADDevice",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADDeviceRegisteredOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADDeviceRegisteredUser",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADDirectoryRoleMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADDomain",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADGroupAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADGroupMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADGroupOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSAdministrativeUnit",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSAdministrativeUnitMember",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSApplicationExtensionProperty",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSApplicationKey",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSApplicationOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSApplicationPassword",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSApplicationVerifiedPublisher",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSConditionalAccessPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSDeletedDirectoryObject",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSGroupLifecyclePolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSIdentityProvider",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSLifecyclePolicyGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSNamedLocationPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSPermissionGrantConditionSet",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSPermissionGrantPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSRoleDefinition",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSScopedRoleMembership",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADMSServicePrincipalDelegatedPermissionClassification",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADOAuth2PermissionGrant",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADServiceAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADServicePrincipal",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADServicePrincipalKeyCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADServicePrincipalOwner",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADServicePrincipalPasswordCredential",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADTrustedCertificateAuthority",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADUser",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADUserAppRoleAssignment",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADUserExtension",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Remove-AzureADUserManager",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Reset-AzureADMSLifeCycleGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Restore-AzureADDeletedApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Restore-AzureADMSDeletedDirectoryObject",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Revoke-AzureADSignedInUserAllRefreshToken",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Revoke-AzureADUserAllRefreshToken",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Select-AzureADGroupIdsContactIsMemberOf",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Select-AzureADGroupIdsGroupIsMemberOf",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Select-AzureADGroupIdsServicePrincipalIsMemberOf",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Select-AzureADGroupIdsUserIsMemberOf",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADApplicationLogo",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADApplicationProxyApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADApplicationProxyApplicationConnectorGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADApplicationProxyApplicationCustomDomainCertificate",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADApplicationProxyApplicationSingleSignOn",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADApplicationProxyConnector",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADApplicationProxyConnectorGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADDevice",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADDomain",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSAdministrativeUnit",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSApplication",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSApplicationLogo",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSApplicationVerifiedPublisher",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSAuthorizationPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSConditionalAccessPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSGroup",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSGroupLifecyclePolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSIdentityProvider",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSNamedLocationPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSPermissionGrantConditionSet",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSPermissionGrantPolicy",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADMSRoleDefinition",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADServicePrincipal",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADTenantDetail",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADTrustedCertificateAuthority",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADUser",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADUserExtension",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADUserLicense",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADUserManager",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADUserPassword",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Set-AzureADUserThumbnailPhoto",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Update-AzureADSignedInUserPassword",
        "Source":  "AzureAd"
    },
    {
        "Name":  "Add-AzureADAdministrativeUnitMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADApplicationOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADApplicationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADDeviceRegisteredOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADDeviceRegisteredUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADDirectoryRoleMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADGroupMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADGroupOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADMSAdministrativeUnitMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADMSApplicationOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADMScustomSecurityAttributeDefinitionAllowedValues",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADMSFeatureRolloutPolicyDirectoryObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADMSLifecyclePolicyGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADMSPrivilegedResource",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADMSScopedRoleMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADMSServicePrincipalDelegatedPermissionClassification",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADScopedRoleMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADServicePrincipalOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Add-AzureADServicePrincipalPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Close-AzureADMSPrivilegedRoleAssignmentRequest",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Confirm-AzureADDomain",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Connect-AzureAD",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Disconnect-AzureAD",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Enable-AzureADDirectoryRole",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADAdministrativeUnit",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADAdministrativeUnitMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationExtensionProperty",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationKeyCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationLogo",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationPasswordCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationProxyApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationProxyApplicationConnectorGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnector",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnectorGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnectorGroupMembers",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationProxyConnectorMemberOf",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationServiceEndpoint",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationSignInDetailedSummary",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADApplicationSignInSummary",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADAuditDirectoryLogs",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADAuditSignInLogs",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADContact",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADContactDirectReport",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADContactManager",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADContactMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADContactThumbnailPhoto",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADContract",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADCurrentSessionInfo",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDeletedApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDevice",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDeviceConfiguration",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDeviceRegisteredOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDeviceRegisteredUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDirectoryRole",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDirectoryRoleMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDirectoryRoleTemplate",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDirectorySetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDirectorySettingTemplate",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDomain",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDomainNameReference",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDomainServiceConfigurationRecord",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADDomainVerificationDnsRecord",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADExtensionProperty",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADExternalDomainFederation",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADGroupAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADGroupMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADGroupOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSAdministrativeUnit",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSAdministrativeUnitMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSApplicationExtensionProperty",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSApplicationOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSApplicationTemplate",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSAttributeSet",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSAuthorizationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSConditionalAccessPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSCustomSecurityAttributeDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSCustomSecurityAttributeDefinitionAllowedValue",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSDeletedDirectoryObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSDeletedGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSFeatureRolloutPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSGroupLifecyclePolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSGroupPermissionGrant",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSIdentityProvider",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSLifecyclePolicyGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSNamedLocationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSPasswordSingleSignOnCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSPermissionGrantConditionSet",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSPermissionGrantPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSPrivilegedResource",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSPrivilegedRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSPrivilegedRoleAssignmentRequest",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSPrivilegedRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSPrivilegedRoleSetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSScopedRoleMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSServicePrincipal",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSServicePrincipalDelegatedPermissionClassification",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSTrustFrameworkPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADMSUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADOAuth2PermissionGrant",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADObjectByObjectId",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADObjectSetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADPolicyAppliedObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADPrivilegedRole",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADPrivilegedRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADScopedRoleMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServiceAppRoleAssignedTo",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServiceAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipal",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipalCreatedObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipalKeyCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipalMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipalOAuth2PermissionGrant",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipalOwnedObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipalOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipalPasswordCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADServicePrincipalPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADSubscribedSku",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADTenantDetail",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADTrustedCertificateAuthority",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserCreatedObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserDirectReport",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserExtension",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserLicenseDetail",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserManager",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserOAuth2PermissionGrant",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserOwnedDevice",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserOwnedObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserRegisteredDevice",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-AzureADUserThumbnailPhoto",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-CrossCloudVerificationCode",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-RbacApplicationRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Get-RbacApplicationRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADAdministrativeUnit",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADApplicationExtensionProperty",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADApplicationKeyCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADApplicationPasswordCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADApplicationProxyApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADApplicationProxyConnectorGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADDevice",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADDirectorySetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADDomain",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADExternalDomainFederation",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADGroupAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSAdministrativeUnit",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSAdministrativeUnitMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSApplicationExtensionProperty",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSApplicationFromApplicationTemplate",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSApplicationKey",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSApplicationPassword",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSAttributeSet",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSConditionalAccessPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSCustomSecurityAttributeDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSFeatureRolloutPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSGroupLifecyclePolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSIdentityProvider",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSInvitation",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSNamedLocationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSPasswordSingleSignOnCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSPermissionGrantConditionSet",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSPermissionGrantPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSServicePrincipal",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSTrustFrameworkPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADMSUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADObjectSetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADPrivilegedRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADServiceAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADServicePrincipal",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADServicePrincipalKeyCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADServicePrincipalPasswordCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADTrustedCertificateAuthority",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-AzureADUserAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-RbacApplicationRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "New-RbacApplicationRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Open-AzureADMSPrivilegedRoleAssignmentRequest",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADAdministrativeUnit",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADAdministrativeUnitMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplicationExtensionProperty",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplicationKeyCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplicationOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplicationPasswordCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplicationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplicationProxyApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplicationProxyApplicationConnectorGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADApplicationProxyConnectorGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADContact",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADContactManager",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADDeletedApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADDevice",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADDeviceRegisteredOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADDeviceRegisteredUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADDirectoryRoleMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADDirectorySetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADDomain",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADExternalDomainFederation",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADGroupAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADGroupMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADGroupOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSAdministrativeUnit",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSAdministrativeUnitMember",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSApplicationExtensionProperty",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSApplicationKey",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSApplicationOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSApplicationPassword",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSApplicationVerifiedPublisher",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSConditionalAccessPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSDeletedDirectoryObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSFeatureRolloutPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSFeatureRolloutPolicyDirectoryObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSGroupLifecyclePolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSIdentityProvider",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSLifecyclePolicyGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSNamedLocationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSPasswordSingleSignOnCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSPermissionGrantConditionSet",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSPermissionGrantPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSScopedRoleMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSServicePrincipalDelegatedPermissionClassification",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADMSTrustFrameworkPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADOAuth2PermissionGrant",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADObjectSetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADScopedRoleMembership",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADServiceAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADServicePrincipal",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADServicePrincipalKeyCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADServicePrincipalOwner",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADServicePrincipalPasswordCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADServicePrincipalPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADTrustedCertificateAuthority",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADUserAppRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADUserExtension",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-AzureADUserManager",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-RbacApplicationRoleAssignment",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Remove-RbacApplicationRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Reset-AzureADMSLifeCycleGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Restore-AzureADDeletedApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Restore-AzureADMSDeletedDirectoryObject",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Revoke-AzureADSignedInUserAllRefreshToken",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Revoke-AzureADUserAllRefreshToken",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Select-AzureADGroupIdsContactIsMemberOf",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Select-AzureADGroupIdsGroupIsMemberOf",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Select-AzureADGroupIdsServicePrincipalIsMemberOf",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Select-AzureADGroupIdsUserIsMemberOf",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADAdministrativeUnit",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADApplicationLogo",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADApplicationProxyApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADApplicationProxyApplicationConnectorGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADApplicationProxyApplicationCustomDomainCertificate",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADApplicationProxyApplicationSingleSignOn",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADApplicationProxyConnector",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADApplicationProxyConnectorGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADDevice",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADDirectorySetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADDomain",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSAdministrativeUnit",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSApplication",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSApplicationLogo",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSApplicationVerifiedPublisher",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSAttributeSet",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSAuthorizationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSConditionalAccessPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSCustomSecurityAttributeDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSCustomSecurityAttributeDefinitionAllowedValue",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSFeatureRolloutPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSGroup",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSGroupLifecyclePolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSIdentityProvider",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSNamedLocationPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSPasswordSingleSignOnCredential",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSPermissionGrantConditionSet",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSPermissionGrantPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSPrivilegedRoleAssignmentRequest",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSPrivilegedRoleSetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSServicePrincipal",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSTrustFrameworkPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADMSUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADObjectSetting",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADPolicy",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADServicePrincipal",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADTenantDetail",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADTrustedCertificateAuthority",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADUser",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADUserExtension",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADUserLicense",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADUserManager",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADUserPassword",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-AzureADUserThumbnailPhoto",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Set-RbacApplicationRoleDefinition",
        "Source":  "AzureADPreview"
    },
    {
        "Name":  "Update-AzureADSignedInUserPassword",
        "Source":  "AzureADPreview"
    }
]
'@
    #endregion deprecated functions

    $result = @{}
    $json = ConvertFrom-Json $deprecatedFunctions
    foreach($jsonObject in $json)
    {
        if(-not $result.ContainsKey($jsonObject.Name))
        {
            $result.Add($jsonObject.Name, @($jsonObject.Source))
            continue
        }

        $result[$jsonObject.Name] += $jsonObject.Source
    }

    $result
}

#endregion functions

#PSSCRIPTANALYZER SuppressOnce Test-Function
function Test-DeprecatedCmdlet {
    <#
        .SYNOPSIS
            Test-DeprecatedCmdlet
        .DESCRIPTION
            Microsoft has deprected 3 commonly used Powershell modules.
            Test-DeprecatedCmdlet.psm1 integrates with PSScriptAnalyzer to find possible usage of cmdlets from these modules.
        .PARAMETER ScriptblockAst
            Tokens of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.Token[]]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .LINK
            https://techcommunity.microsoft.com/t5/microsoft-entra-azure-ad-blog/important-azure-ad-graph-retirement-and-powershell-module/ba-p/3848270
    #>
    [cmdletbinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Test-Function', '', Justification = 'Required by PSScriptAnalyzer', Scope = 'function')]
    param (
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$TestToken
    )

    begin{
        $deprecatedFunctions = Get-DeprecatedFunction
    }

    process{
        $TestToken | Where-Object {$_.TokenFlags -eq "CommandName" -and $deprecatedFunctions.ContainsKey($_.Value)} |
            ForEach-Object{
                $commandElement = $_

                $msg = "You are using Cmdlet '{0}' which is contained in one of the following modules ({1}) which are deprecated.{2}"  -f
                                    $commandElement.Value, ($deprecatedFunctions[$commandElement.Value] -join ", "), [System.Environment]::NewLine
                $msg += "Please use another module."
                $correction = "Cmdlet {0} is deprecated. Please use another module." -f $commandElement.Value

                $params = @{
                    Extent = $commandElement.Extent
                    Description = 'Microsoft deprecated a list of Powershell modules. Please avoid using cmdlets from these modules.'
                    Correction = $correction
                    Message = $msg
                    RuleName = "Test-DeprecatedCmdlet"
                    Severity = "Warning"
                    RuleSuppressionID = "Test-DeprecatedCmdlet"
                }

                Get-PSScriptAnalyzerError @params
            }
    }
}

Export-ModuleMember -Function ("Test-DeprecatedCmdlet")
