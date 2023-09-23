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

Used with SonarQube Community Edition Version 10.2 (build 77647) and Sonar PS Plugin 0.5.2
