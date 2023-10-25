
function Test-CommentedCode
{
    <#
        .SYNOPSIS
            Testing code which is commented-out in Powershell scripts.
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

        # Get ScriptBlocks
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
            $astTokens = $astErr =  $null

            [System.Management.Automation.Language.Parser]::ParseInput($functionText, [ref]$astTokens, [ref]$astErr) | Out-Null

            $commentTokens = $astTokens | Where-Object { $_.Kind -eq "Comment"}
            foreach($token in $commentTokens)
            {
                $isCommentedCode = $false
                $comment = [string]::Empty

                if($token.Text.StartsWith("<#") -and $token.Text -inotlike "*.SYNOPSIS*")
                {
                    $comment = $token.Text.Substring(2, $token.Text.Length - 4).Trim()
                }
                if($token.Text.StartsWith("#"))
                {
                    $comment = $token.Text.Substring(1, $token.Text.Length - 1).Trim()
                }
                while($comment.StartsWith("#"))
                {
                    $comment = $comment.Substring(1, $token.Text.Length - 1).Trim()
                }

                if([string]::IsNullOrEmpty($comment))
                {
                    continue
                }

                $ast = [System.Management.Automation.Language.Parser]::ParseInput($comment, [ref]$null, [ref]$null)

                $isCommentedCode = ($null -ne ($ast.FindAll({ $true }, $true) | Where-Object {$null -ne $_.Operator}))
                $isCommentedCode = $isCommentedCode -or ($null -ne ($ast.FindAll({ $true }, $true) | Where-Object {$null -ne $_.Expression}))

                if($isCommentedCode){
                    $params = @{
                        Extent = $token.Extent
                        Description = "Your comment -> $comment <- contains code."
                        Correction = "Unused Code detected. Please remove the code which was commented out."
                        Message = "Your comment -> $comment <- contains code. Please remove the code which was commented out from script."
                        RuleName = "Test-CommentedCode"
                        Severity = "Warning"
                        RuleSuppressionID = "Test-CommentedCode"
                    }
                    Get-PSScriptAnalyzerError @params
                }
            }
        }
    }
}

Export-ModuleMember -Function ("Test-CommentedCode")