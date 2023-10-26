
New-Variable -Force -Name UseSonarQube   -Value $true

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

[ScriptBlock]$ScriptBlockPredicate = {
    param
    (
        [System.Management.Automation.Language.Ast]$Ast
    )
    [bool]$ReturnValue = $false

    if ($Ast -is [System.Management.Automation.Language.ScriptBlockAst])
    {
        $ReturnValue = $true;
    }
    return $ReturnValue
}

function Get-ErrorProperty
{
    <#
        .SYNOPSIS
            Prepare Hashtable for parameters of DiagnosticRecord
        .PARAMETER RuleName
            Name of the rule rasing this finding.
        .PARAMETER Missing
            Custom object with parameter missing either in parameter block or in synopsis
        .PARAMETER ScriptAst
            Powershell AST
        .PARAMETER FunctionAst
            Powershell AST
        .LINK
            https://github.com/PowerShell/PSScriptAnalyzer
    #>
    [cmdletbinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Script')]
        [Parameter(ParameterSetName = 'Function')]
        [PSCustomObject]$RuleName,
        [Parameter(Mandatory, ParameterSetName = 'Script')]
        [Parameter(ParameterSetName = 'Function')]
        [PSCustomObject]$Missing,
        [Parameter(Mandatory, ParameterSetName = 'Script')]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptAst,
        [Parameter(Mandatory, ParameterSetName = 'Function')]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionAst
    )

    switch($PSCmdlet.ParameterSetName)
    {
        "Script"   { $ast = $ScriptAst;   break }
        "Function" { $ast = $FunctionAst; break }
    }

    $SideIndicator = $Missing.SideIndicator
    $Content = $Missing.Inputobject

    $result = @{
        ScriptAst = $ast
        RuleName = $RuleName
        Severity = "Warning"
        RuleSuppressionID = $RuleName
    }

    switch($SideIndicator)
    {
        "<="{
            $result.Add("Description", "Parameter $Content documentation is missing.")
            $result.Add("Correction", "Please add .PARAMETER $Content documentation to .SYNOPSIS")
            $result.Add("Message", ".SYNOPSIS contains .PARAMETER documentation for non exitent parameter '$Content'")
            return $result
        }
        "=>"{
            $result.Add("Description", "Function Parameter $Content does not exist but is listeded in .SYNOPSIS")
            $result.Add("Correction", "Please remove .PARAMETER $Content documentation from .SYNOPSIS")
            $result.Add("Message", "Function is missing .PARAMETER documentation for parameter '$Content'")
            return $result
        }
    }
}

function Get-PSScriptAnalyzerError
{
    <#
        .SYNOPSIS
            Create DiagnosticRecord for a finding
        .PARAMETER ErrorProperty
            Hashtable for parameters for DiagnosticRecord
        .LINK
            https://github.com/PowerShell/PSScriptAnalyzer
    #>
    [cmdletbinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [parameter( Mandatory )]
        [ValidateNotNull()]
        [hashtable]$ErrorProperty
    )

    [int]$startLineNumber =  $ErrorProperty.ScriptAst.Extent.StartLineNumber
    [int]$endLineNumber = $ErrorProperty.ScriptAst.Extent.EndLineNumber
    [int]$startColumnNumber = $ErrorProperty.ScriptAst.Extent.StartColumnNumber
    [int]$endColumnNumber = $ErrorProperty.ScriptAst.Extent.EndColumnNumber
    [string]$correction = $ErrorProperty.Correction
    [string]$optionalDescription = $ErrorProperty.Description
    $objParams = @{
    TypeName = 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent'
    ArgumentList = $startLineNumber, $endLineNumber, $startColumnNumber,
                    $endColumnNumber, $correction, $optionalDescription
    }
    $correctionExtent = New-Object @objParams
    $suggestedCorrections = New-Object System.Collections.ObjectModel.Collection[$($objParams.TypeName)]
    $suggestedCorrections.add($correctionExtent) | Out-Null

    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
        "Message"              = $ErrorProperty.Message
        "Extent"               = $ErrorProperty.ScriptAst.Extent
        "RuleName"             = $ErrorProperty.RuleName
        "Severity"             = $ErrorProperty.Severity
        "RuleSuppressionID"    = $ErrorProperty.RuleSuppressionID
        "SuggestedCorrections" = $suggestedCorrections
    }
}

function Test-Synopsis
{
    <#
    .SYNOPSIS
        Test scripts and functions for missing Synopsis.
    .DESCRIPTION
        A SYNOPSIS should be defined for every script and function.
        Every function, script and parameter should have a descriptive help defined in .SYNOPSIS.
    .PARAMETER ScriptBlockAst
        ScriptBlockAst to analyze
    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]
    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    .EXAMPLE
        Test-Synopsis -ScriptBlockAst $ScriptBlockAst
    .NOTES
        Notice variable 'UseSonarQube'.
        If set to '$true', Test-Synopsis only inspects functions and ignores script and scriptblock parameters.
        Set 'UseSonarQube' to '$true' when using PSScriptAnalyzer together with SonarQube and the Plugin mentioned below.
        Otherwise it leads to false positives.
    .LINK
        https://learn.microsoft.com/en-us/powershell/scripting/developer/help/writing-comment-based-help-topics?view=powershell-7.3
    .LINK
        https://github.com/gretard/sonar-ps-plugin
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Test-Function', '', Justification = 'Required by PSScriptAnalyzer', Scope = 'function')]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    try
    {
        [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $null

        [System.Management.Automation.Language.ScriptBlockAst[]]$asts = $ScriptBlockAst.FindAll($ScriptBlockPredicate, $true) |
            Where-Object {$null -ne $_.ParamBlock -and $null -ne $_.ParamBlock.Parameters}

        if($UseSonarQube)
        {
            [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $ScriptBlockAst.FindAll($FunctionPredicate, $true) |
                Where-Object {$null -ne $_.Body.ParamBlock -and $null -ne $_.Body.ParamBlock.Parameters}
        }

        foreach($currentAst in $asts)
        {
            $helpContent = $currentAst.GetHelpContent()

            # violation if there is no help at all
            if($null -eq $helpContent) {
                $params = @{
                    ScriptAst = $currentAst
                    Description = "Your code should be documented."
                    Correction = "Code and function parameter(s) should be documented."
                    Message = "Missing <# .SYNOPSIS #>. Code and function parameter(s) should be documented."
                    RuleName = "Test-Synopsis"
                    Severity = "Warning"
                    RuleSuppressionID = "Test-Synopsis"
                }
                Get-PSScriptAnalyzerError -ErrorProperty $params | Write-Output

                continue
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }

}


function Test-ParameterDescription
{
    <#
    .SYNOPSIS
        Test that every parameter documentation has no descriptive explanation.
    .DESCRIPTION
        The rule checks for undocumented parameters and documented parameters which doesn't exist.
    .PARAMETER ScriptBlockAst
        ScriptBlockAst to analyze
    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]
    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    .EXAMPLE
        Test-ParameterDescription -ScriptBlockAst $ScriptBlockAst
    .NOTES
        Notice variable 'UseSonarQube'.
        If set to '$true', Test-ParameterDescription only inspects functions and ignores script and scriptblock parameters.
        Set 'UseSonarQube' to '$true' when using PSScriptAnalyzer together with SonarQube and the Plugin mentioned below.
        Otherwise it leads to false positives.
    .LINK
        https://learn.microsoft.com/en-us/powershell/scripting/developer/help/writing-comment-based-help-topics?view=powershell-7.3
    .LINK
        https://github.com/gretard/sonar-ps-plugin
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Test-Function', '', Justification = 'Required by PSScriptAnalyzer', Scope = 'function')]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    try
    {
        [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $null

        [System.Management.Automation.Language.ScriptBlockAst[]]$asts = $ScriptBlockAst.FindAll($ScriptBlockPredicate, $true) |
            Where-Object {$null -ne $_.ParamBlock -and $null -ne $_.ParamBlock.Parameters}

        if($UseSonarQube)
        {
            [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $ScriptBlockAst.FindAll($FunctionPredicate, $true) |
                Where-Object {$null -ne $_.Body.ParamBlock -and $null -ne $_.Body.ParamBlock.Parameters}
        }

        foreach($currentAst in $asts)
        {
            $helpContent = $currentAst.GetHelpContent()

            # violation if a parameter documentation has no descriptive explanation
            $helpContent | Select-Object -ExpandProperty Parameters | Select-Object -First 1  |     # take the first if not null
                ForEach-Object{
                    foreach($key in $_.Keys)
                    {
                        if([string]::IsNullOrEmpty($_[$key].ToString().Trim()))
                        {
                            $params = @{
                                ScriptAst = $currentAst
                                Description = "The parameter $key should be documented."
                                Correction = "Please add descriptive text to your parameter documentation for .PARAMETER $key"
                                Message = "Missing parameter documentation in for .PARAMETER $key."
                                RuleName = "Test-ParameterDescription"
                                Severity = "Warning"
                                RuleSuppressionID = "Test-ParameterDescription"
                            }
                            Get-PSScriptAnalyzerError -ErrorProperty $params
                        }
                    }
                }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }

}

function Test-ParameterDocumentation
{
    <#
    .SYNOPSIS
        Test Pararameters and Parameter documentation
    .DESCRIPTION
        Every parameter must be documented and
        parameter documentaion should not have entries for none-existing parameters.
    .PARAMETER ScriptBlockAst
        ScriptBlockAst to analyze
    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]
    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    .EXAMPLE
        Test-ParameterDocumentation -ScriptBlockAst $ScriptBlockAst
    .NOTES
        Notice variable 'UseSonarQube'.
        If set to '$true', Test-ParameterDocumentation only inspects functions and ignores script and scriptblock parameters.
        Set 'UseSonarQube' to '$true' when using PSScriptAnalyzer together with SonarQube and the Plugin mentioned below.
        Otherwise it leads to false positives.
    .LINK
        https://learn.microsoft.com/en-us/powershell/scripting/developer/help/writing-comment-based-help-topics?view=powershell-7.3
    .LINK
        https://github.com/gretard/sonar-ps-plugin
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Test-Function', '', Justification = 'Required by PSScriptAnalyzer', Scope = 'function')]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    try
    {
        [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $null

        [System.Management.Automation.Language.ScriptBlockAst[]]$asts = $ScriptBlockAst.FindAll($ScriptBlockPredicate, $true) |
            Where-Object {$null -ne $_.ParamBlock -and $null -ne $_.ParamBlock.Parameters}

        if($UseSonarQube)
        {
            [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $ScriptBlockAst.FindAll($FunctionPredicate, $true) |
                Where-Object {$null -ne $_.Body.ParamBlock -and $null -ne $_.Body.ParamBlock.Parameters}
        }

        foreach($currentAst in $asts)
        {
            $helpContent = $currentAst.GetHelpContent()
            $parameters = $currentAst.ParamBlock.Parameters

            if($UseSonarQube)
            {
                $parameters = $currentAst.Body.ParamBlock.Parameters
            }

            #region function parameter and parameter documentation mismatch
            $parameterBlockParameters = @()
            $helpParameters  = @()

            # create a list of parameter names from function parameter block
            $parameters  | ForEach-Object {
                $parameterBlockParameters += $_.Name.VariablePath.UserPath.ToUpper()
            }

            $helpContent | Select-Object Parameters |                       # get parameter block from help
                Where-Object {$null -ne $_ }  | Select-Object -First 1 |    # take the first if not null
                ForEach-Object { $_.Parameters.Keys } |                     # get the keys from paramter
                ForEach-Object { $helpParameters += $_.ToUpper() }          # add keys to collection


            # compare the lists and write out an error for every mismatch
            $missingParameters = Compare-Object -ReferenceObject $helpParameters -DifferenceObject $parameterBlockParameters
            foreach($missingParameter in $missingParameters)
            {
                $errorProperty = $null
                if($currentAst -is [System.Management.Automation.Language.ScriptBlockAst])
                {
                    $errorProperty = Get-ErrorProperty -Missing $missingParameter -ScriptAst $currentAst -RuleName "Test-ParameterDocumentation"
                }
                if($currentAst -is [System.Management.Automation.Language.FunctionDefinitionAst])
                {
                    $errorProperty = Get-ErrorProperty -Missing $missingParameter -FunctionAst $currentAst -RuleName "Test-ParameterDocumentation"
                }

                if($null -ne $errorProperty)
                {
                    Get-PSScriptAnalyzerError -ErrorProperty $errorProperty
                }
            }

            #endregion function parameter and parameter documentation mismatch
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

function Test-SynopsisEqualsDescription
{
    <#
    .SYNOPSIS
        Test Synopsis and Description.
    .DESCRIPTION
        A SYNOPSIS should not be equal to DESCRIPTION.
    .PARAMETER ScriptBlockAst
        ScriptBlockAst to analyze
    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]
    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    .EXAMPLE
        Test-SynopsisEqualsDescription -ScriptBlockAst $ScriptBlockAst
    .NOTES
        Notice variable 'UseSonarQube'.
        If set to '$true', Test-SynopsisEqualsDescription only inspects functions and ignores script and scriptblock parameters.
        Set 'UseSonarQube' to '$true' when using PSScriptAnalyzer together with SonarQube and the Plugin mentioned below.
        Otherwise it leads to false positives.
    .LINK
        https://learn.microsoft.com/en-us/powershell/scripting/developer/help/writing-comment-based-help-topics?view=powershell-7.3
    .LINK
        https://github.com/gretard/sonar-ps-plugin
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Test-Function', '', Justification = 'Required by PSScriptAnalyzer', Scope = 'function')]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    try
    {
        [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $null

        [System.Management.Automation.Language.ScriptBlockAst[]]$asts = $ScriptBlockAst.FindAll($ScriptBlockPredicate, $true) |
            Where-Object {$null -ne $_.ParamBlock -and $null -ne $_.ParamBlock.Parameters}

        if($UseSonarQube)
        {
            [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $ScriptBlockAst.FindAll($FunctionPredicate, $true) |
                Where-Object {$null -ne $_.Body.ParamBlock -and $null -ne $_.Body.ParamBlock.Parameters}
        }

        foreach($currentAst in $asts)
        {
            $helpContent = $currentAst.GetHelpContent()

            if( -not([string]::IsNullOrEmpty($helpContent.Description )) -and
            $helpContent.Synopsis.Trim().Equals(($helpContent.Description | Out-String -Width 5kb).Trim()))
            {
                $params = @{
                    ScriptAst = $currentAst
                    Description = "SYNOPSIS. is equal to .DESCRIPTION"
                    Correction = "Please use .DESCRIPTION to explain function in more detail."
                    Message = "SYNOPSIS. is equal to .DESCRIPTION."
                    RuleName = "Test-SynopsisEqualsDescription"
                    Severity = "Warning"
                    RuleSuppressionID = "Test-SynopsisEqualsDescription"
                }
                Get-PSScriptAnalyzerError $params
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

function Test-SynopsisMissesLink
{
    <#
    .SYNOPSIS
        Code should be linked to a ressource.
    .DESCRIPTION
        Code is not an island. If there is information related to the code, link it.
    .PARAMETER ScriptBlockAst
        ScriptBlockAst to analyze
    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]
    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    .EXAMPLE
        Test-SynopsisMissesLink -ScriptBlockAst $ScriptBlockAst
    .NOTES
        Notice variable 'UseSonarQube'.
        If set to '$true', Test-SynopsisMissesLink only inspects functions and ignores script and scriptblock parameters.
        Set 'UseSonarQube' to '$true' when using PSScriptAnalyzer together with SonarQube and the Plugin mentioned below.
        Otherwise it leads to false positives.
    .LINK
        https://learn.microsoft.com/en-us/powershell/scripting/developer/help/writing-comment-based-help-topics?view=powershell-7.3
    .LINK
        https://github.com/gretard/sonar-ps-plugin
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Test-Function', '', Justification = 'Required by PSScriptAnalyzer', Scope = 'function')]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    try
    {
        [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $null

        [System.Management.Automation.Language.ScriptBlockAst[]]$asts = $ScriptBlockAst.FindAll($ScriptBlockPredicate, $true) |
            Where-Object {$null -ne $_.ParamBlock -and $null -ne $_.ParamBlock.Parameters}

        if($UseSonarQube)
        {
            [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $ScriptBlockAst.FindAll($FunctionPredicate, $true) |
                Where-Object {$null -ne $_.Body.ParamBlock -and $null -ne $_.Body.ParamBlock.Parameters}
        }

        foreach($currentAst in $asts)
        {
            $helpContent = $currentAst.GetHelpContent()

            $relatedLinks = @(($helpContent.Links | Out-String).Trim())
            if (-not $relatedLinks) {
                $params = @{
                    ScriptAst = $currentAst
                    Description = "SYNOPSIS. does not have any .LINK. PLease add a reference to your code."
                    Correction = "If related content can be found, please reference your code."
                    Message = "SYNOPSIS. does not have any .LINK."
                    RuleName = "Test-SynopsisMissesLink"
                    Severity = "Information"
                    RuleSuppressionID = "Test-SynopsisMissesLink"
                }
                Get-PSScriptAnalyzerError $params
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

function Test-ConciseSynopsis
{
    <#
    .SYNOPSIS
        Synopsis should be short and precise.
    .DESCRIPTION
        If there is more to say use Descrption or Notes.
    .PARAMETER ScriptBlockAst
        ScriptBlockAst to analyze
    .INPUTS
        [System.Management.Automation.Language.ScriptBlockAst]
    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    .EXAMPLE
        Test-ConciseSynopsis -ScriptBlockAst $ScriptBlockAst
    .NOTES
        Notice variable 'UseSonarQube'.
        If set to '$true', Test-ConciseSynopsis only inspects functions and ignores script and scriptblock parameters.
        Set 'UseSonarQube' to '$true' when using PSScriptAnalyzer together with SonarQube and the Plugin mentioned below.
        Otherwise it leads to false positives.
    .LINK
        https://learn.microsoft.com/en-us/powershell/scripting/developer/help/writing-comment-based-help-topics?view=powershell-7.3
    .LINK
        https://github.com/gretard/sonar-ps-plugin
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('Test-Function', '', Justification = 'Required by PSScriptAnalyzer', Scope = 'function')]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    try
    {
        New-Variable -Force -Name synopsisLength -Value 100

        [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $null

        [System.Management.Automation.Language.ScriptBlockAst[]]$asts = $ScriptBlockAst.FindAll($ScriptBlockPredicate, $true) |
            Where-Object {$null -ne $_.ParamBlock -and $null -ne $_.ParamBlock.Parameters}

        if($UseSonarQube)
        {
            [System.Management.Automation.Language.FunctionDefinitionAst[]]$asts = $ScriptBlockAst.FindAll($FunctionPredicate, $true) |
                Where-Object {$null -ne $_.Body.ParamBlock -and $null -ne $_.Body.ParamBlock.Parameters}
        }

        foreach($currentAst in $asts)
        {
            $helpContent = $currentAst.GetHelpContent()

            if($helpContent.Synopsis.Length -gt $synopsisLength) {
                $params = @{
                    ScriptAst = $currentAst
                    Description = "Help should be contain concise."
                    Correction = "SYNOPSIS is longer than {0} Characters. Please use .DESCRIPTION to explain in more detail." -f $synopsisLength
                    Message = "Come to the point of your code in .SYNOPSIS and explain it in more detail in .DESCRIPTION"
                    RuleName = "Test-ConciseSynopsis"
                    Severity = "Warning"
                    RuleSuppressionID = "Test-ConciseSynopsis"
                }
                Get-PSScriptAnalyzerError $params
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}


Export-ModuleMember -Function ("Test-Synopsis", "Test-ParameterDescription", "Test-ParameterDocumentation", "Test-SynopsisEqualsDescription", "Test-SynopsisMissesLink", "Test-ConciseSynopsis")