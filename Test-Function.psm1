
function Test-Function {
    <#
        .SYNOPSIS
            Testing length of function blocks.
        .DESCRIPTION
            One of the clean code principles is that function should not be too long.
            The test counts only lines of code in 'begin', 'process' and 'end' parts of functions in a script.
        .PARAMETER ScriptblockAst
            AST of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.ScriptBlockAst]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .NOTES
            You can set 'MaxFunctionContentLength' variable to define your own limit.
        .LINK
            https://de.wikipedia.org/wiki/Clean_Code
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

        # Find function block
        [ScriptBlock]$FunctionPredicate = {
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

            if ($Ast -is [System.Management.Automation.Language.FunctionDefinitionAst])
            {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

        # Define your max size of function blocks.
        New-Variable -Force -Name MaxFunctionContentLength -Value 50
    }

    process{
        $ScriptblockAst.FindAll( $FunctionPredicate, $true) | ForEach-Object {
            $length = 0
            $paramBlockLength = 0
            $functionBody = $_.Body

            if($null -ne $functionBody.ParamBlock)
            {
                $paramBlockLength = $functionBody.ParamBlock.Extent.EndLineNumber - $functionBody.ParamBlock.Extent.StartLineNumber
            }

            if($null -ne $functionBody.BeginBlock){
                $length += ($functionBody.BeginBlock.Extent.EndLineNumber - $functionBody.BeginBlock.Extent.StartLineNumber)
            }

            if($null -ne $functionBody.ProcessBlock){
                $length += ($functionBody.ProcessBlock.Extent.EndLineNumber - $functionBody.ProcessBlock.Extent.StartLineNumber)
            }
            if($null -ne $functionBody.EndBlock){
                $length += ($functionBody.EndBlock.Extent.EndLineNumber - $functionBody.EndBlock.Extent.StartLineNumber)
            }

            $length = $length - $paramBlockLength

            if($length -gt $MaxFunctionContentLength)
            {
                [int]$startLineNumber =  $functionBody.Extent.StartLineNumber
                [int]$endLineNumber = $functionBody.Extent.EndLineNumber
                [int]$startColumnNumber = $functionBody.Extent.StartColumnNumber
                [int]$endColumnNumber = $functionBody.Extent.EndColumnNumber
                [string]$correction = "Function content is too long. Refactor your code."
                [string]$optionalDescription = 'One of the clean code principles is that function sould be short and concise.'
                $objParams = @{}
                $objParams.Add("TypeName", 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent')
                $objParams.Add("ArgumentList", @($startLineNumber, $endLineNumber, $startColumnNumber,$endColumnNumber, $correction, $optionalDescription))

                $correctionExtent = New-Object @objParams
                $suggestedCorrections = New-Object System.Collections.ObjectModel.Collection[$($objParams.TypeName)]
                $suggestedCorrections.add($correctionExtent) | Out-Null
                [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    "Message"              = "Function content is too long. Refactor your code."
                    "Extent"               = $functionBody.Extent
                    "RuleName"             = "Test-Function"
                    "Severity"             = "Warning"
                    "RuleSuppressionID"    = "Test-Function"
                    "SuggestedCorrections" = $suggestedCorrections
                }
            }
        }
    }
}

Export-ModuleMember -Function ("Test-Function")
