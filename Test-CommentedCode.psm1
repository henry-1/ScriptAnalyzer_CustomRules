
function Test-CommentedCode
{
    <#
        .SYNOPSIS
            Testing code which is commented-out in Powershell scripts.
        .DESCRIPTION
            I
        .PARAMETER ScriptblockAst
            AST of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.ScriptBlockAst]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
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
                    Get-PSScriptAnalyzerError
                .PARAMETER CommandAst
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


    }

    process{
        $ScriptBlockAst.FindAll($FunctionPredicate, $true) | ForEach-Object {
            $functionText = $_.Extent.text
            New-Variable -Force -Name astTokens -Value $null
            New-Variable -Force -Name astErr -Value $null
            New-Variable -Force -Name tokenCount -Value 0

            [System.Management.Automation.Language.Parser]::ParseInput($functionText, [ref]$astTokens, [ref]$astErr) | Out-Null

            $commentTokens = $astTokens | Where-Object { $_.Kind -eq "Comment"}

            $commentTokens | Where-Object {$_.Text.StartsWith("#")} | ForEach-Object {
                $comment = $_.Text.Substring(1, $_.Text.Length - 1).Trim()
                try{
                    $sut = [scriptblock]::Create($comment)
                    $params = @{
                        Extent = $_.Extent
                        Description = "Your comment -> $sut <- is code."
                        Correction = "Please remove the code which was commented out."
                        Message = "Your comment -> $sut <- is code. Please remove the code which was commented out from script."
                        RuleName = "Test-CommentedCode"
                        Severity = "Warning"
                        RuleSuppressionID = "Test-CommentedCode"
                    }
                    Get-PSScriptAnalyzerError @params
                }
                catch{
                    # do nothing, $comment is no code
                }
            }
        }
    }
}

Export-ModuleMember -Function ("Test-CommentedCode")