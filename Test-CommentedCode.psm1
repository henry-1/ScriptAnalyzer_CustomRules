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

function Get-CommentTokenText{
    param(
        [string]$Comment
    )
    if($Comment.StartsWith("<#") -and $Comment -inotlike "*.SYNOPSIS*")
    {
        $Comment = $Comment.Substring(2, $Comment.Length - 4).Trim()
    }
    while($comment.StartsWith("#"))
    {
        $comment = $comment.Substring(1, $comment.Length - 1).Trim()
    }

    return $Comment
}

function Test-CommentedCode
{
    <#
        .SYNOPSIS
            Testing code which is commented-out in Powershell scripts.
        .DESCRIPTION
            Do not leave commented out code in scripts.
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

    $scriptBlockTokens =  $null
    [System.Management.Automation.Language.Parser]::ParseInput($ScriptblockAst.Extent.Text, [ref]$scriptBlockTokens, [ref]$null) | Out-Null

    $scriptBlockTokens | Where-Object { $_.Kind -eq "Comment"} | ForEach-Object {
        $extent = $_.Extent
        $comment = Get-CommentTokenText -Comment $extent.Text

        $params = @{
            Extent = $extent
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

Export-ModuleMember -Function ("Test-CommentedCode")
