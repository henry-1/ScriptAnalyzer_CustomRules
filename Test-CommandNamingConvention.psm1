function Test-CommandAst{
    <#
        .SYNOPSIS
            Test if command adheres naming conventions
        .DESCRIPTION
            Commands should follow verb-noun convention.
        .PARAMETER ast
            Command AST
        .EXAMPLE
            Test-CommandAst -Ast $ast
        .OUTPUTS
            [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
        .LINK
            https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.Language.CommandAst]
        $Ast
    )

    process{
        if($ast.Extent.Text.ToString().StartsWith(". "))
        {
            # do not report dot sourcing like: . "$path\$file"
            return
        }

        if($ast.Parent.Parent.Extent.Text.StartsWith("throw"))
        {
            # do not report an error for throwing an exception
            return
        }


        $commandName = $ast.CommandElements[0].Value
        $verb, $noun, $rest = $commandName -split '-'
        $verbParts = $verb -split '\\'
        $verb = $verbParts[$verbParts.Count - 1]
        # Test approved verbs
        if ((-not [string]::IsNullOrEmpty($verb)) -and (-not $standardVerbs.$verb))
        {
            $params =@{}
            $params.Add("CommandAst", $ast)
            $params.Add("Description", "$commandName uses a non-standard verb, $Verb.")
            $params.Add("Correction", "Please change it. Use Get-Verb to see all approved verbs")
            $params.Add("Message", "Usage of non-approved verb.")
            $params.Add("RuleName", "Test-CommandNamingConvention")
            $params.Add("Severity", "Warning")
            $params.Add("RuleSuppressionID", "Test-CommandNamingConvention")

            Get-PSScriptAnalyzerError @params
        }

        $commandNameParts = $verb -split '\\'
        $commandName = $commandNameParts[$commandNameParts.Count - 1]

        # Test invalid command characters
        if (-not [string]::IsNullOrEmpty($commandName) -and $commandName.IndexOfAny("#,(){}[]&/\`$^;:`"'<>|?@``*%+=~ ".ToCharArray()) -ne -1)
        {
            $params = @{}
            $params.Add("CommandAst", $ast)
            $params.Add("Description", "$commandName uses invalid characters.")
            $params.Add("Correction", "Please rename $CommandName.")
            $params.Add("Message", "Usage of invalid characters in command.")
            $params.Add("RuleName", "Test-CommandNamingConvention")
            $params.Add("Severity", "Warning")
            $params.Add("RuleSuppressionID", "Test-CommandNamingConvention")

            Get-PSScriptAnalyzerError @params
        }

        # Test if command contains more parts than verb and noun
        if ($rest) {
            $params = New-Object -TypeName pscustomobject
            $params = @{}
            $params.Add("CommandAst", $ast)
            $params.Add("Description", "$commandName contains more parts than verb and noun." )
            $params.Add("Correction", "Please rename $CommandName.")
            $params.Add("Message",  "Command contains more parts than verb and noun.")
            $params.Add("RuleName", "Test-CommandNamingConvention")
            $params.Add("Severity", "Warning")
            $params.Add("RuleSuppressionID", "Test-CommandNamingConvention")

            Get-PSScriptAnalyzerError @params
        }
    }

}

function Test-CommandNamingConvention {
    <#
        .SYNOPSIS
            Test Powershell scripts that they adhere to naming conventions.
        .DESCRIPTION
            Microsoft recommends usage of verb-noun convention for naming of cmdlets, commands and functions
            and also suggests a list of 'approved verbs' to be used.
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
            Where-Object {($_.Source -eq "Microsoft.PowerShell.Core" -or $_.Source -eq "Microsoft.PowerShell.Utility") -and $_.CommandType -eq "Cmdlet"} |
            Where-Object {-not $standardVerbs.ContainsKey($_.Verb)} |
            ForEach-Object {
                $obj = New-Object -TypeName PSCustomObject
                $obj | Add-Member -MemberType NoteProperty -Name Verb -Value $_.Verb
                $obj | Add-Member -MemberType NoteProperty -Name Alias -Value ([string]::Empty)
                $obj | Add-Member -MemberType NoteProperty -Name Group -Value $_.Source
                $obj | Add-Member -MemberType NoteProperty -Name Description -Value ([string]::Empty)
                $standardVerbs.Add($obj.Verb, $obj)
            }
    }

    process{



        $commandAsts = $ScriptblockAst.FindAll( $CommandPredicate, $true)
        try{
            $commandAsts | Where-Object {$null -ne $_} | Test-CommandAst
        }
        catch
        {
            throw $_
        }

    }
}

Export-ModuleMember -Function ("Test-CommandNamingConvention")