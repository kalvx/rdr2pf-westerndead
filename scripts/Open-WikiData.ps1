$file = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) "data\wiki-data.js"
notepad.exe $file
