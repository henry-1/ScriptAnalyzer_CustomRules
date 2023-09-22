# Inspired by PSScriptAnalyzer and ScriptCop
- [ScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [ScriptCop](https://github.com/StartAutomating/ScriptCop)
# Usage
```
# Location of scripts to be examined
$scriptPath = "C:\DEV\MyScripts\"

# Location of custom PSScriptAnalyzer rules
$customRulesPath = "C:\DEV\CustomRules\*.psm1"

invoke-scriptAnalyzer -Path $scriptPath -Recurse -CustomRulePath  $customRulesPath -IncludeDefaultRules
```