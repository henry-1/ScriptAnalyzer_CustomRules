
function Test-CommandNamingConvention {
    <#
        .SYNOPSIS
            Test-CommandNamingConvention
        .DESCRIPTION
            Microsoft recommends usage of verb-noun convention for naming of cmdlets, commands and functions.
        .PARAMETER ScriptblockAst
            AST of the script to be examined.
        .INPUTS
            [System.Management.Automation.Language.ScriptBlockAst]
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .LINK
            https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3
    #>
    [cmdletbinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
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
                [System.Management.Automation.Language.CommandAst]$CommandAst,
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

            [int]$startLineNumber =  $CommandAst.Extent.StartLineNumber
            [int]$endLineNumber = $CommandAst.Extent.EndLineNumber
            [int]$startColumnNumber = $CommandAst.Extent.StartColumnNumber
            [int]$endColumnNumber = $CommandAst.Extent.EndColumnNumber
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
                "Extent"               = $CommandAst.Extent
                "RuleName"             = $RuleName
                "Severity"             = $Severity
                "RuleSuppressionID"    = $RuleSuppressionID
                "SuggestedCorrections" = $suggestedCorrections
            }
        }

        # Find function block
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

            if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                $ReturnValue = $true;
            }
            return $ReturnValue
        }

        # crate a list of approved verbs
        $standardVerbs = @{}
        Get-Verb |
            ForEach-Object { $standardVerbs."$($_.Verb)" = $_ }

        # add some other words to the list which are commonly used by Microsoft like foreach, where, sort, ...
        Get-Command |
            Where-Object {$_.CommandType -eq "Cmdlet" -and ($_.Source -eq "Microsoft.PowerShell.Core" -or $_.Source -eq "Microsoft.PowerShell.Utility")} |
            ForEach-Object {
                if(-not $standardVerbs.ContainsKey($_.Verb))
                {
                    $obj = New-Object -TypeName PSCustomObject
                    $obj | Add-Member -MemberType NoteProperty -Name Verb -Value $_.Verb
                    $obj | Add-Member -MemberType NoteProperty -Name Alias -Value [string]::Empty]
                    $obj | Add-Member -MemberType NoteProperty -Name Group -Value $_.Source
                    $obj | Add-Member -MemberType NoteProperty -Name Description -Value [string]::Empty]
                    $standardVerbs.Add($obj.Verb, $obj)
                }
            }
    }

    process{
        $result = @()
        $commandAsts = $ScriptblockAst.FindAll( $CommandPredicate, $true)
        foreach($ast in $commandAsts)
        {
            $commandName = $ast.CommandElements[0].Value
            $verb, $noun, $rest = $commandName -split '-'

            # Test approved verbs
            if ((-not [string]::IsNullOrEmpty($verb)) -and (-not $standardVerbs.$verb)) {
                $params = @{
                    CommandAst = $ast
                    Description = "$commandName uses a non-standard verb, $Verb."
                    Correction = "Please change it.  Use Get-Verb to see all approved verbs"
                    Message = "Usage of non-approved verb."
                    RuleName = "Test-CommandNamingConvention"
                    Severity = "Warning"
                    RuleSuppressionID = "Test-CommandNamingConvention"
                }
                $result += Get-PSScriptAnalyzerError @params
            }

            # Test invalid command characters
            if ($commandName.IndexOfAny("#,(){}[]&/\`$^;:`"'<>|?@``*%+=~ ".ToCharArray()) -ne -1)
            {
                $params = @{
                    CommandAst = $ast
                    Description = "$commandName uses invalid characters."
                    Correction = "Please rename $CommandName."
                    Message = "Usage of invalid characters in command."
                    RuleName = "Test-CommandNamingConvention"
                    Severity = "Warning"
                    RuleSuppressionID = "Test-CommandNamingConvention"
                }
                $result += Get-PSScriptAnalyzerError @params
            }

            # Test if command contains more parts than verb and noun
            if ($rest) {
                $params = @{
                    CommandAst = $ast
                    Description = "$commandName contains more parts than verb and noun."
                    Correction = "Please rename $CommandName."
                    Message = "Command contains more parts than verb and noun."
                    RuleName = "Test-CommandNamingConvention"
                    Severity = "Warning"
                    RuleSuppressionID = "Test-CommandNamingConvention"
                }
                $result += Get-PSScriptAnalyzerError @params
            }
        }
        if($result.Count -gt 0)
        {
            $result
        }
    }
}

Export-ModuleMember -Function ("Test-CommandNamingConvention")