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
Used with
- Sonar PS Plugin 0.5.1 (source code - self compiled)
- SonarQube Community Edition Version 10.2 (build 77647) and

# SonarQube Integration
To integrate custom modules with the Sonar PS Plugin you need to compile the code as this process integrates the rules.


1. In 'regenerateRulesDefinition.ps1' look for the following line
```powershell
$powershellRules = Get-ScriptAnalyzerRule
```
2. (optional) Right after that line add the following line to add custom rules to the rules collection recognized by the plugin
```powershell
$powershellRules += Get-ScriptAnalyzerRule -CustomRulePath "C:\DEV\CustomRules\*.psm1"
```
**NOTE**: <br>Every published function in custom rules has to have a **.SYNOPSIS** and within the .SYNOPSIS the **.DESCRIPTION** is required. Otherwise SonarQube fails to start.

3. Build the project
```
mvn install
```
4. Copy the output **sonar-ps-plugin\sonar-ps-plugin\target\sonar-ps-plugin-0.5.1.jar** to the **extentions/plugins** directory of your SonarQube instance.
5. Restart SonarQube.
6. In SonarQube - Administration - Marketplace you need to agree the risk taken to activate custom analyzer.

# Analyze your Powershell code
To be able to run the scan you need to download SonarScanner
https://docs.sonarsource.com/sonarqube/9.9/analyzing-source-code/scanners/sonarscanner/

1. Create a project for your Powershell scripts in SonarQube
2. In your user profile choose Security and create a 'Project Analalysis Token'
3. In your script folder create a 'sonar-project.properties' file
4. Add at least the values for the options as described here: https://docs.sonarsource.com/sonarqube/9.9/analyzing-source-code/analysis-parameters/

- sonar.organization -> name of the org
- sonar.host.url -> URI to your SonarQube instance
- sonar.projectKey -> needs to be the name you gave the token in SonarQube
- sonar.token -> the token you created
5. From within your local scripts folder run the scan which will also transfer the analysis to your SonarQube instance
```
"C:\DEV\SonarScanner\sonar-scanner-5.0.1.3006\bin\sonar-scanner.bat" -X --debug
```
