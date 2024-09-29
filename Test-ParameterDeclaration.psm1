
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

[ScriptBlock]$ParamBlockPredicate = {
    param
    (
        [System.Management.Automation.Language.Ast]$Ast
    )
    [bool]$ReturnValue = $false

    if ($Ast -is [System.Management.Automation.Language.ParamBlockAst])
    {
        $ReturnValue = $true;
    }
    return $ReturnValue
}

#endregion functions

function Test-ParameterDeclaration{
    [cmdletbinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptblockAst]$ScriptblockAst
    )

    $ScriptblockAst.FindAll( $ParamBlockPredicate, $true) | ForEach-Object {
        $parameters = $_.Parameters | Where-Object {
            $_.Attributes.Count -eq 0
        }

        foreach($param in $parameters){

            $params = @{
                Extent = $param.Extent
                Description = "Your parameter $($param.name) has no declaration."
                Correction = "Please add parameter declaration."
                Message = "Your parameter $($param.name) has no declaration."
                RuleName = "Test-ParameterDeclaration"
                Severity = "Warning"
                RuleSuppressionID = "Test-ParameterDeclaration"
            }
            Get-PSScriptAnalyzerError @params
        }
    }
}

Export-ModuleMember -Function ("Test-ParameterDeclaration")
