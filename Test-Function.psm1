
function Test-Function {
    <#
        .SYNOPSIS
            Testing length of function blocks.
        .DESCRIPTION
            One of the clean code principles is that function should not be too long.
            The test counts only lines of code in 'begin', 'process' and 'end' parts of functions in a script.
            The test excludes lines of comments and empty lines from counting.
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

        function Get-EmptyLineCount {
            <#
                .SYNOPSIS
                    Count empty lines in code
                .PARAMETER Text
                    Code as text
                .EXAMPLE
                    Get-EmptyLineCount -Text $functionBody.$codeBlock.Extent.Text
                .LINK
                    https://de.wikipedia.org/wiki/Clean_Code
            #>

            [cmdletbinding()]
            [OutputType([int])]
            param(
                [Parameter(Mandatory)]
                [string]$Text
            )
            New-Variable -Force -Name astTokens -Value $null
            New-Variable -Force -Name astErr -Value $null
            New-Variable -Force -Name returnValue -Value 0

            [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$astTokens, [ref]$astErr) | Out-Null
            for($i = 0; $i -lt $astTokens.count; $i++)
            {
                if($astTokens[$i].kind -eq 'NewLine' -and $astTokens[$i + 1].kind -eq 'NewLine') {
                    $returnValue += 1
                    $i++
                }
            }
            $returnValue
        }

        function Get-CommentLineCount {
            <#
                .SYNOPSIS
                    Get comment line count
                .PARAMETER Text
                    Text from an AST from script code
                .EXAMPLE
                    Get-CommentLineCount -Text $functionBody.BeginBlock.Extent.Text
                .LINK
                    https://www.powershellgallery.com/packages/ISEScriptingGeek/3.3.1.2/Content/Get-ScriptComments.ps1
            #>
            [cmdletbinding()]
            [OutputType([int])]
            param(
                [Parameter(Mandatory)]
                [string]$Text
            )
            New-Variable -Force -Name astTokens -Value $null
            New-Variable -Force -Name astErr -Value $null
            New-Variable -Force -Name returnValue -Value 0

            [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$astTokens, [ref]$astErr) | Out-Null
            $astTokens.where({$_.kind -eq 'comment'}) | ForEach-Object{
                $returnValue += ($_.Extent.EndLineNumber - $_.Extent.StartLineNumber)
                if($_.Extent.EndLineNumber -eq $_.Extent.StartLineNumber)
                {
                    $returnValue += 1
                }
            }

            $returnValue
        }

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

            $codeBlocks = @("BeginBlock","ProcessBlock","EndBlock")

            if($null -ne $functionBody.ParamBlock)
            {
                $paramBlockLength = $functionBody.ParamBlock.Extent.EndLineNumber - $functionBody.ParamBlock.Extent.StartLineNumber
            }

            foreach($codeBlock in $codeBlocks)
            {
                if($null -ne $functionBody.$codeBlock){
                    $commentLineCount = Get-CommentLineCount -Text $functionBody.$codeBlock.Extent.Text
                    $emptyLineCount = Get-EmptyLineCount -Text $functionBody.$codeBlock.Extent.Text
                    $codeLineCount = $functionBody.$codeBlock.Extent.EndLineNumber - $functionBody.$codeBlock.Extent.StartLineNumber - 1
                    $length += ($codeLineCount - $commentLineCount - $emptyLineCount)
                }
            }

            if($functionBody.EndBlock.Extent.StartLineNumber -eq $functionBody.ParamBlock.Extent.StartLineNumber) {
                $length = $length - $paramBlockLength
            }

            Write-Verbose ("Found Function {0} with {1} lines of code" -f $_.Name, $length)

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
