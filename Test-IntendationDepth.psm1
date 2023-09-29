function Test-IntendationDepth
{
<#
    .SYNOPSIS
        Testing intendation depth of Powershell scripts.
    .DESCRIPTION
        Code complexity increases by number of intendations of code.
        In SonarQube counting the number of nested code paths is called Coginitive Complexity.
    .PARAMETER ScriptBlockAst
        ScriptBlockAst to analyze
    .EXAMPLE
        Test-IntendationDepth -ScriptBlockAst $ScriptBlockAst
    .LINK
        https://blog.devgenius.io/sonarqube-cognitive-complexity-265640dbad3e
#>
[cmdletbinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptblockAst]$ScriptblockAst
    )

    begin{
        # this is what youwant to be the max intendation for your scripts
        New-Variable -Force -Name MaxAllowedIntendation -Value 6

        # these vars track the state of intendation
        New-Variable -Force -Name intendationDepth      -Value 0
        New-Variable -Force -Name maxIntendationDepth   -Value 0
        New-Variable -Force -Name maxDepthReached       -Value $false
        New-Variable -Force -Name startLine             -Value 0

        [ScriptBlock]$ScriptBlockPredicate = {
            param
            (
                [System.Management.Automation.Language.Ast]$Ast
            )
            [bool]$ReturnValue = $false

            if ($Ast -is [System.Management.Automation.Language.ScriptBlockAst]) {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

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
                "RuleName"             = "Test-IntendationDepth"
                "Severity"             = "Warning"
                "RuleSuppressionID"    = "Test-IntendationDepth"
                "SuggestedCorrections" = $suggestedCorrections
            }
        }

        $allLines = $ScriptblockAst.Extent.Text.Split("`n")
        $allAsts = $ScriptblockAst.FindAll($AllAstsPredicate,$true)
    }
    process{
        $asts = $ScriptblockAst.FindAll($ScriptBlockPredicate,$true) |
            Where-Object {$null -ne $_.ParamBlock} |
            Select-Object -First 1

        foreach($ast in $asts)
        {
            $start = 0
            $tokens = [Management.Automation.PSParser]::Tokenize($ast, [ref]$null)
            foreach($token in $tokens) {
                if($token.Type -eq "GroupStart" -and $token.Content.Contains("{")) {
                    $intendationDepth++
                    if($intendationDepth -gt $maxIntendationDepth) {
                        $maxIntendationDepth = $intendationDepth
                    }
                    if($maxIntendationDepth -ge $MaxAllowedIntendation -and -not $maxDepthReached) {
                        $start = $token.StartLine
                        $maxDepthReached = $true
                        Write-Verbose "MaxAllowedIntendation reached at line $($token.StartLine)"
                    }
                }
                if ($token.Type -eq "GroupEnd" -and $token.Content.Equals("}")) {
                    $intendationDepth--
                    if($intendationDepth -lt $MaxAllowedIntendation -and $maxDepthReached) {

                        [System.Management.Automation.Language.Ast]$codeBlock = $allAsts | Where-Object {$_.Extent.StartLineNumber -eq $start } | Select-Object -First 1

                        if($null -eq $codeBlock -and $allLines[$start].ToString().Trim().EndsWith("{")) {
                            [System.Management.Automation.Language.Ast]$codeBlock = $allAsts | Where-Object {$_.Extent.StartLineNumber -eq $start + 1 } | Select-Object -First 1
                        }

                        if($null -ne $codeBlock) {
                            $params = @{
                                StartLine = $codeBlock.Extent.StartLineNumber
                                EndLine = $codeBlock.Extent.EndLineNumber
                                StartColumn = $codeBlock.Extent.StartColumnNumber
                                EndColumn = $codeBlock.Extent.EndColumnNumber
                                Correction = "Refactor code to reduce intendation."
                                OptionalDescription = "Code intendation should not exceed $MaxAllowedIntendation."
                                Message = "Maximum intendation exceeded in code. Please reduce intendation by refactoring code."
                                Extent = $codeBlock.Extent
                            }
                            Get-PSScriptAnalyzerError @params
                        }

                        Write-Verbose ("max depth of {0} left at line {1}" -f $maxIntendationDepth.ToString(), $token.EndLine.ToString())
                        $maxIntendationDepth = 0
                        $maxDepthReached = $false
                    }
                    if($intendationDepth -eq 0) {
                        $maxIntendationDepth = 0
                    }
                }
            }
        }
    }
}

Export-ModuleMember -Function ("Test-IntendationDepth")