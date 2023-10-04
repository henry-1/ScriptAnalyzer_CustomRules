

function Test-UnusableFunction {
    <#
        .SYNOPSIS
            Test-UnusableFunction checks for cmdlets wich make your script unusable in automation.
        .DESCRIPTION
            Using cmdlets wich require user interaction make Powershell scripts unusable in batch and automation jobs.
        .PARAMETER ScriptblockAst
            AST of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.ScriptBlockAst]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .LINK
            https://techcommunity.microsoft.com/t5/microsoft-entra-azure-ad-blog/important-azure-ad-graph-retirement-and-powershell-module/ba-p/3848270
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
                "RuleName"             = "Test-UnusableFunction"
                "Severity"             = "Warning"
                "RuleSuppressionID"    = "Test-UnusableFunction"
                "SuggestedCorrections" = $suggestedCorrections
            }
        }

        # Find command block
        [ScriptBlock]$CommandPredicate = {
            <#
                .SYNOPSIS
                    Get Prarameter from script
                .PARAMETER Ast
                    AST from script code
            #>
            param
            (
                [System.Management.Automation.Language.Ast]$Ast
            )
            [bool]$ReturnValue = $false

            if ($Ast -is [System.Management.Automation.Language.CommandAst])
            {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

        $unusableCommands = @("Write-Host", "Read-Host")
    }

    process{
        $ScriptblockAst.FindAll( $CommandPredicate, $true) | ForEach-Object {
            if($unusableCommands.Contains($_.CommandElements[0].Value))
            {
                $commandElement = $_
                $command = $commandElement.CommandElements[0]
                if($command -eq "Write-Host") {
                    $msg = "Write-Host makes your scripts unsuable inside of other scripts. If you need to add tracing, consider Write-Verbose and Write-Debug"
                }
                if($command -eq "Read-Host") {
                    $msg = "Read-Host makes your scripts unsuable inside of other scripts, because it means part of your script cannot be controlled by parameters.  If you need to prompt for a value, you should create a mandatory parameter."
                }

                $params = {}
                $params.Add("StartLine", $commandElement.Extent.StartLineNumber)
                $params.Add("EndLine", $commandElement.Extent.EndLineNumber)
                $params.Add("StartColumn", $commandElement.Extent.StartColumnNumber)
                $params.Add("EndColumn", $codeBlock.Extent.EndColumnNumber)
                $params.Add("Correction",  "Command $($commandElement.Value) makes your script unusable.")
                $params.Add("OptionalDescription", 'Rewrite your script.')
                $params.Add("Message", $msg)
                $params.Add("Extent", $commandElement.Extent)

                Get-PSScriptAnalyzerError @params
            }
        }

        [Management.Automation.PSParser]::Tokenize($ScriptblockAst.Extent.Text,[ref]$null) |
            Where-Object {$_.Type -eq "Type" -and ($_.Content -eq "[Console]" -or $_.Content -eq "[System.Console]")} |
            ForEach-Object {
                $token = $_

                $params.Add("StartLine", $token.StartLine)
                $params.Add("EndLine", $token.EndLine)
                $params.Add("StartColumn", $token.StartColumn)
                $params.Add("EndColumn", $token.EndColumn)
                $params.Add("Correction",  "Usage of $($token.Content) makes your script unusable.")
                $params.Add("OptionalDescription", 'Rewrite your script.')
                $params.Add("Message", "Your script uses $($token.Content), wich makes it only usable in Powershell.exe.")
                $params.Add("Extent", $commandElement.Extent)

                Get-PSScriptAnalyzerError @params
            }
    }
}

Export-ModuleMember -Function ("Test-UnusableFunction")
