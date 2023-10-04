function Test-IntendationDepth
{
    <#
        .SYNOPSIS
            Testing intendation depth of Powershell scripts.
        .DESCRIPTION
            Code complexity increases by number of intendations in code.
        .PARAMETER ScriptBlockAst
            ScriptBlockAst to analyze
        .EXAMPLE
            Test-IntendationDepth -ScriptBlockAst $ScriptBlockAst
        .NOTES
            You can set 'MaxAllowedIntendation' variable to define your own limit.
        .LINK
            https://blog.devgenius.io/sonarqube-cognitive-complexity-265640dbad3e
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



        $allLines = $ScriptblockAst.Extent.Text.Split("`n")
        $allAsts = $ScriptblockAst.FindAll($AllAstsPredicate,$true)
    }
    process{

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


        $asts = $ScriptblockAst.FindAll($ScriptBlockPredicate,$true) |
            Where-Object {$null -ne $_.ParamBlock} |
            Select-Object -First 1

        foreach($ast in $asts)
        {
            $start = 0
            $tokens = [Management.Automation.PSParser]::Tokenize($ast, [ref]$null)
            foreach($token in $tokens) {
                if($token.Type -eq "GroupStart" -and $token.Content.Contains("{"))
                {
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
                    if($intendationDepth -lt $MaxAllowedIntendation -and $maxDepthReached)
                    {
                        [System.Management.Automation.Language.Ast]$codeBlock = $allAsts | Where-Object {$_.Extent.StartLineNumber -eq $start } | Select-Object -First 1

                        if($null -eq $codeBlock -and $allLines[$start].ToString().Trim().EndsWith("{")) {
                            [System.Management.Automation.Language.Ast]$codeBlock = $allAsts | Where-Object {$_.Extent.StartLineNumber -eq $start + 1 } | Select-Object -First 1
                        }

                        if($null -ne $codeBlock) {
                            $params = @{}
                            $params.Add("StartLine", $codeBlock.Extent.StartLineNumber)
                            $params.Add("EndLine", $codeBlock.Extent.EndLineNumber)
                            $params.Add("StartColumn", $codeBlock.Extent.StartColumnNumber)
                            $params.Add("EndColumn", $codeBlock.Extent.EndColumnNumber)
                            $params.Add("Correction",  "Refactor code to reduce intendation.")
                            $params.Add("OptionalDescription", "Code intendation should not exceed $MaxAllowedIntendation.")
                            $params.Add("Message", "Maximum intendation exceeded in code. Please reduce intendation by refactoring code.")
                            $params.Add("Extent", $codeBlock.Extent)

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