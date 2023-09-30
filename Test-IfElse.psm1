function Test-IfElse {
    <#
        .SYNOPSIS
            Testing usage of 'else' blocks.
        .DESCRIPTION
            The use of 'else' blocks increases code complexity and reduces readability. Try to avoid 'else' keyword.
        .PARAMETER ScriptblockAst
            AST of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.ScriptBlockAst]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .LINK
            https://de.wikipedia.org/wiki/Clean_Code
    #>
    [cmdletbinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptblockAst]$ScriptblockAst
    )

    begin{
        [ScriptBlock]$AllAstsPredicate = {
            param
            (
                [System.Management.Automation.Language.Ast]$Ast
            )
            [bool]$ReturnValue = $false

            if ($Ast -is [System.Management.Automation.Language.Ast]) {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

        function Get-PSScriptAnalyzerError
        {
            <#
                .SYNOPSIS
                    Create DiagnosticRecord
                .PARAMETER StartLine
                    StartLine of the finding
                .PARAMETER EndLine
                    EndLine of the finding
                .PARAMETER StartColumn
                    StartColumn of the finding
                .PARAMETER EndColumn
                    EndColumn iof the finding
                .PARAMETER Correction
                    Proposal to fix the finding
                .PARAMETER OptionalDescription
                    Optional description to explain the finding
                .PARAMETER Message
                    Message displayed by PSScriptAnalyzer
                .PARAMETER Extent
                    Powershell AST extent
                .LINK
                    https://github.com/PowerShell/PSScriptAnalyzer

            #>
            param(
                [int]$StartLine,
                [int]$EndLine,
                [int]$StartColumn,
                [int]$EndColumn,
                [string]$Correction,
                [string]$OptionalDescription,
                [string]$Message,
                $Extent
            )

            $objParams = @{
                TypeName = 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent'
                ArgumentList = $StartLine, $EndLine, $StartColumn,
                                $EndColumn, $Correction, $OptionalDescription
            }
            $correctionExtent = New-Object @objParams
            $suggestedCorrections = New-Object System.Collections.ObjectModel.Collection[$($objParams.TypeName)]
            $suggestedCorrections.add($correctionExtent) | Out-Null

            [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                "Message"              = $Message
                "Extent"               = $Extent
                "RuleName"             = "Test-IfElse"
                "Severity"             = "Warning"
                "RuleSuppressionID"    = "Test-IfElse"
                "SuggestedCorrections" = $suggestedCorrections
            }
        }
    }
    process{
        $ScriptblockAst.FindAll($AllAstsPredicate,$true) |
            Where-Object {$null -ne $_.ElseClause} | ForEach-Object {
                $params = @{
                    StartLine = $_.Extent.StartLineNumber
                    EndLine = $_.Extent.EndLineNumber
                    StartColumn = $_.Extent.StartColumnNumber
                    EndColumn = $_.Extent.EndColumnNumber
                    Correction = "Refactor code to avoid 'else'."
                    OptionalDescription = "Refactor code to avoid 'else'."
                    Message = "Refactor code to avoid 'else'."
                    Extent = $_.Extent
                }
                Get-PSScriptAnalyzerError @params
            }
    }
}

Export-ModuleMember -Function ("Test-IfElse")