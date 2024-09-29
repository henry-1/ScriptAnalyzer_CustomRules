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
function Test-TODO {
    <#
        .SYNOPSIS
            Test-TODO
        .DESCRIPTION
            Test if there are any TODO's left over in your code. Code in production should not have any open TODO's.
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
        $TestToken | Where-Object { $_.Kind -eq "Comment" -and -not($_.Text -like "*.SYNOPSIS*") -and $_.Text -like "*TODO*"} | ForEach-Object {
            $params = @{
                Extent = $_.Extent
                Description = "Your comment -> $($_.Text) <- contains TODO."
                Correction = "Please remove TODOs from production code."
                Message = "Your comment -> $($_.Text) <- contains TODOs. Please remove TODOs from production code."
                RuleName = "Test-TODO"
                Severity = "Warning"
                RuleSuppressionID = "Test-TODO"
            }

            Get-PSScriptAnalyzerError @params
        }
    }
}

Export-ModuleMember -Function ("Test-TODO")
