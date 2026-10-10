Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
ScriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)

ExePath = ScriptDir & "\wardhelm_agent.exe"
If Not FSO.FileExists(ExePath) Then
    ExePath = ScriptDir & "\build\wardhelm_agent.exe"
End If

WshShell.CurrentDirectory = ScriptDir
WshShell.Run """" & ExePath & """", 0, False
