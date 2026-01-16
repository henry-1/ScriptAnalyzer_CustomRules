
function Get-PSScriptAnalyzerError
{
    <#
        .SYNOPSIS
            Create DiagnosticRecord
        .DESCRIPTION
            Create an output that PSScriptAnalyzer expects as finding.
        .PARAMETER Extent
            Powershell token extent
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

function Test-CaseSensitivity {
    <#
        .SYNOPSIS
            Test-CaseSensitivity
        .DESCRIPTION
            Test if there are any variables used with different casing in the script.
        .NOTES
            Azure Functions are know to have issues with case sensitivity in PowerShell.
            This rule helps to identify variables that are used with different casing.
        .PARAMETER ScriptblockAst
            AST of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.Token[]]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .LINK
            https://marketplace.visualstudio.com/items?itemName=Gruntfuggly.todo-tree
    #>
    [cmdletbinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]$TestToken
    )

    begin {
    }

    process {
        $tokenList = $TestToken | Where-Object { $_.Kind -eq "Variable" }
        $tokenList |
            Group-Object { $_.Name.ToLowerInvariant() } |
            Where-Object {
                $_.Count -gt 1 -and
                ($_.Group.Name | Select-Object -Unique).Count -gt 1
            } |
            ForEach-Object {
                [PSCustomObject]@{
                    Normalized = $_.Name
                    Variants   = ($_.Group.Name | Select-Object -Unique) -join ', '
                    Count      = $_.Count
                }
            } | ForEach-Object {
                $item = $_
                $tokenList |
                    Where-Object { $_.Name -ieq $item.Normalized } |
                    Select-Object -First 1 |
                    ForEach-Object {
                        $params = @{
                            Extent = $_.Extent
                            Description = "The variable '$($item.Normalized)' is used with different casing: $($item.Variants)"
                            Correction = "Please use consistent casing for the variable '$($item.Normalized)'."
                            Message = "The variable '$($item.Normalized)' is used with different casing: $($item.Variants). Please use consistent casing."
                            RuleName = "Test-CaseSensitivity"
                            Severity = "Warning"
                            RuleSuppressionID = "Test-CaseSensitivity"
                        }
                        Get-PSScriptAnalyzerError @params
                    }
            }
    }
}

Export-ModuleMember -Function ("Test-CaseSensitivity")
