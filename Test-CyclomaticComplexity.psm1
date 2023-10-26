
function Test-CyclomaticComplexity
{
    <#
        .SYNOPSIS
            Testing cyclomatic complexity of functions in Powershell scripts.
        .DESCRIPTION
            I have chosen the easiest way to calculate cyclomatic complexity (CC) by calculating predicate nodes.
            CC < 10      -> Simple Procedure, little risk
            10 < CC < 20 -> More complex, moderate risk
            20 < CC < 50 -> High risk
            CC < 50      -> Very high risk
        .PARAMETER ScriptblockAst
            AST of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.ScriptBlockAst]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .NOTES
            You can set $CCThreshold in the code below to set your own threshold.

            The video mentioned in the link, describes 3 different ways to caluculate CC.
        .LINK
            https://www.youtube.com/watch?v=8J_v6j__q_Y
    #>
    [cmdletbinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Test-Function', '', Justification = 'Required by PSScriptAnalyzer', Scope = 'function')]
    param (
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptblockAst]$ScriptblockAst
    )
    begin{

        function Get-PSScriptAnalyzerError
        {
            <#
                .SYNOPSIS
                    Create DiagnosticRecord
                .DESCRIPTION
                    Create an output that PSScriptAnalyzer expects as finding.
                .PARAMETER FunctionAst
                    Powershell AST
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
                [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionAst,
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

            [int]$startLineNumber =  $FunctionAst.Extent.StartLineNumber
            [int]$endLineNumber = $FunctionAst.Extent.EndLineNumber
            [int]$startColumnNumber = $FunctionAst.Extent.StartColumnNumber
            [int]$endColumnNumber = $FunctionAst.Extent.EndColumnNumber
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
                "Extent"               = $FunctionAst.Extent
                "RuleName"             = $RuleName
                "Severity"             = $Severity
                "RuleSuppressionID"    = $RuleSuppressionID
                "SuggestedCorrections" = $suggestedCorrections
            }
        }

        # Find ScriptBlocks
        [ScriptBlock]$FunctionPredicate = {
            param
            (
                [System.Management.Automation.Language.Ast]$Ast
            )
            [bool]$ReturnValue = $false

            if ($Ast -is [System.Management.Automation.Language.FunctionDefinitionAst])
            {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

        New-Variable -Force -Name CCThreshold -Value 20
    }

    process {
        $ScriptBlockAst.FindAll($FunctionPredicate, $true) |
            ForEach-Object {
                $functionText = $_.Extent.text
                New-Variable -Force -Name astTokens -Value $null
                New-Variable -Force -Name astErr -Value $null
                New-Variable -Force -Name tokenCount -Value 0

                [System.Management.Automation.Language.Parser]::ParseInput($functionText, [ref]$astTokens, [ref]$astErr) | Out-Null
                # tokens with branches
                $tokenCount += ($astTokens | Where-Object {$_.Kind -eq "If"}).Count
                $tokenCount += ($astTokens | Where-Object {$_.Kind -eq "Identifier" -and $_.Text -eq "Case"}).Count

                # tokens with loops
                $tokenCount += ($astTokens | Where-Object {$_.Kind -eq "While"}).Count
                $tokenCount += ($astTokens | Where-Object {$_.Kind -eq "For"}).Count
                $tokenCount += ($astTokens | Where-Object {$_.Kind -eq "ForEach"}).Count
                $tokenCount += ($astTokens | Where-Object {$_.Kind -eq "Generic" -and $_.Text -eq "Foreach-Object"}).Count


                if($tokenCount -gt $CCThreshold)
                {
                    $params = @{
                        FunctionAst = $_
                        Description = "Your code in function $($_.Name) exceeds Cyclomatic Complexity threshold. CC greater than 20 is at high risk and hard to maintain."
                        Correction = "Refactor code in function $($_.Name) to reduce intendation."
                        Message = "Your code in function $($_.Name) exceeds Cyclomatic Complexity threshold."
                        RuleName = "Test-CyclomaticComplexity"
                        Severity = "Warning"
                        RuleSuppressionID = "Test-CyclomaticComplexity"
                    }
                    Get-PSScriptAnalyzerError @params
                }
            }
    }
}

Export-ModuleMember -Function ("Test-CyclomaticComplexity")