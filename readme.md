# Inspired by PSScriptAnalyzer and ScriptCop
- [ScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [ScriptCop](https://github.com/StartAutomating/ScriptCop)
- [SonarQube](https://www.sonarsource.com/)
- [sonar-ps-plugin](https://github.com/gretard/sonar-ps-plugin)
# Usage
```
# Location of scripts to be examined
$scriptPath = "C:\DEV\MyScripts\"

# Location of custom PSScriptAnalyzer rules
$customRulesPath = "C:\DEV\CustomRules\*.psm1"

invoke-scriptAnalyzer -Path $scriptPath -Recurse -CustomRulePath  $customRulesPath -IncludeDefaultRules
```

# Dynamically invoke all tests for a list of scripts to be tested in VSCode
Save the following text to file with the extension ".tests.ps1"
```

#requires -Modules PSScriptAnalyzer
#requires -Modules Pester

$scriptsFolder = "C:\DEV\MyScripts"
$customRulesFolder = "C:\DEV\CustomRules"


Describe "Testing Scripts" {

    function Get-Tests
    {
        param(
            [string]$ScriptPath,
            [string]$CustomRulesFolder
        )
        $scripts = Get-ChildItem $ScriptPath -Filter "*.ps1"
        $powershellRules = Get-ScriptAnalyzerRule
        if(-not [string]::IsNullOrEmpty($customRulesFolder))
        {
            $customRulesFolder = Join-Path $customRulesFolder -ChildPath "*.psm1"
            $powershellRules += Get-ScriptAnalyzerRule -CustomRulePath $customRulesFolder
        }
        $testContext = @{}
        foreach($script in $scripts)
        {
            $testCases = @()
            foreach($rule in $PowershellRules)
            {
                $testCase = @{Script = $script.Name; ScriptPath = $script.FullName; Name = $rule.RuleName; CustomRulesPath = $customRulesFolder}
                $testCases += $testCase
            }
            $testContext.Add($script.FullName, $testCases)
        }

        $testContext
    }

    $testCases = Get-Tests -ScriptPath $scriptsFolder -CustomRulesFolder $customRulesFolder
    foreach($key in $testCases.Keys)
    {
        Context "$key" {
            It '<Name>' -ForEach $testCases[$key] {

                # arrange
                $params = @{
                    Path = $scriptPath
                    IncludeRule = $name
                }
                if(-not [string]::IsNullOrEmpty($customRulesPath))
                {
                    $params.add("CustomRulePath", $customRulesPath)
                }

                # act and assert
                (Invoke-ScriptAnalyzer @params).Count | Should -Be 0
            }
        }
    }
}
```

