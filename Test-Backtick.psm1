
# Backtick (`) operator is also called word-wrap operator.
function Test-Backtick {
    <#
        .SYNOPSIS
            Test-Backtick
        .DESCRIPTION
            Test if there are any Backticks used which should be replaced.
        .PARAMETER ScriptblockAst
            AST of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.ScriptBlockAst]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .LINK
            https://poshcode.gitbook.io/powershell-practice-and-style/style-guide/readability
    #>
    [cmdletbinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptblockAst]$ScriptblockAst
    )
    begin {
        [ScriptBlock]$CommandAstPredicate = {
            param
            (
                [System.Management.Automation.Language.Ast]$Ast
            )
            [bool]$ReturnValue = $false

            if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

        [ScriptBlock]$ExpressionAstPredicate = {
            param
            (
                [System.Management.Automation.Language.Ast]$Ast
            )
            [bool]$ReturnValue = $false

            if ($Ast -is [System.Management.Automation.Language.ExpressionAst]) {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

        [ScriptBlock]$ExpandableStringExpressionPredicate = {
            param
            (
                [System.Management.Automation.Language.Ast]$Ast
            )
            [bool]$ReturnValue = $false

            if ($Ast -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

        function Get-PSScriptAnalyzerError
        {
            <#
                .SYNOPSIS
                    Create DiagnosticRecord
                .DESCRIPTION
                    Create an output that PSScriptAnalyzer expects as finding.
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
                "RuleName"             = "Test-Backtick"
                "Severity"             = "Warning"
                "RuleSuppressionID"    = "Test-Backtick"
                "SuggestedCorrections" = $suggestedCorrections
            }
        }
    }

    process {

        $matchNewLine = "[``][n]"
        $matchTab = "[``][t]"
        $ScriptblockAst.FindAll($ExpressionAstPredicate,$true) |
            Where-Object { $_.Extent.Text.Contains("``") } |
            Where-Object { $_.Extent.Text -match $matchNewLine } |
                ForEach-Object {
                    $params = @{
                        StartLine = $_.Extent.StartLineNumber
                        EndLine = $_.Extent.EndLineNumber
                        StartColumn = $_.Extent.StartColumnNumber
                        EndColumn = $_.Extent.EndColumnNumber
                        Correction = "Use [Environment]::NewLine instead of Backticks."
                        OptionalDescription = "[Environment]::NewLine is independent of the operating system."
                        Message = "Avoid Backticks"
                        Extent = $_.Extent
                    }
                    Get-PSScriptAnalyzerError @params
                }

        $ScriptblockAst.FindAll($CommandAstPredicate,$true) |
            Where-Object { $_.Extent.Text.Contains("``") } |
            Where-Object {$_.Extent.Text -notmatch $matchTab -and $_.Extent.Text -notmatch $matchNewLine} |
            ForEach-Object {
                $params = @{
                    StartLine = $_.Extent.StartLineNumber
                    EndLine = $_.Extent.EndLineNumber
                    StartColumn = $_.Extent.StartColumnNumber
                    EndColumn = $_.Extent.EndColumnNumber
                    Correction = "Use Splatting instead of Backticks."
                    OptionalDescription = "For better readability use Splatting instead of Backticks."
                    Message = "Avoid Backticks"
                    Extent = $_.Extent
                }
                Get-PSScriptAnalyzerError @params
            }

            $ScriptblockAst.FindAll($ExpandableStringExpressionPredicate,$true) |
            Where-Object { $_.Extent.Text.Contains("``") } |
            Where-Object {$_.Extent.Text -notmatch $matchTab -and $_.Extent.Text -notmatch $matchNewLine} |
            ForEach-Object {
                $params = @{
                    StartLine = $_.Extent.StartLineNumber
                    EndLine = $_.Extent.EndLineNumber
                    StartColumn = $_.Extent.StartColumnNumber
                    EndColumn = $_.Extent.EndColumnNumber
                    Correction = "Use Splatting instead of Backticks."
                    OptionalDescription = "For better readability use Splatting instead of Backticks."
                    Message = "Avoid Backticks"
                    Extent = $_.Extent
                }
                Get-PSScriptAnalyzerError @params
            }
    }


    end {}
}

Export-ModuleMember -Function ("Test-Backtick")
