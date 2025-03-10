import os
import osproc
import strutils
import strformat
import pkg/colors

proc incrementVersion(version: string): string =
  # Parse version string (expects format like X.Y.Z)
  let parts = version.split('.')
  
  if parts.len < 1:
    return version
  
  var newParts = parts
  # Increment the last component (smallest unit)
  try:
    let lastIdx = newParts.high
    newParts[lastIdx] = $(parseInt(newParts[lastIdx]) + 1)
    result = newParts.join(".")
  except ValueError:
    echo "Error: Invalid version format".red
    result = version

proc findNimbleFile(): string =
  for kind, path in walkDir(getCurrentDir()):
    if kind == pcFile and path.endsWith(".nimble"):
      return path
  return ""

proc extractVersion(content: string): string =
  const versionPrefix = "version"
  
  for line in content.splitLines():
    let trimmedLine = line.strip()
    if trimmedLine.startsWith(versionPrefix):
      let parts = trimmedLine.split('=', 1)
      if parts.len == 2:
        var versionValue = parts[1].strip()
        # Remove quotes if present
        if versionValue.startsWith("\"") and versionValue.endsWith("\""):
          versionValue = versionValue[1..^2]
        return versionValue
  
  return ""

proc updateNimbleFile(nimbleFile: string, oldVersion: string, newVersion: string): bool =
  if nimbleFile.len == 0 or oldVersion == newVersion:
    return false
  
  let content = readFile(nimbleFile)
  var newContent = ""
  var updated = false
  
  for line in content.splitLines():
    var newLine = line
    if line.contains("version") and line.contains(oldVersion):
      newLine = line.replace(oldVersion, newVersion)
      updated = true
    
    newContent.add(newLine)
    newContent.add("\n")
  
  if updated:
    writeFile(nimbleFile, newContent)
    return true
  
  return false

proc main() =
  echo "🔍 Looking for nimble file...".blue
  
  let nimbleFile = findNimbleFile()
  if nimbleFile.len == 0:
    echo "❌ No nimble file found in the current directory!".red
    quit(1)
  
  echo fmt"📄 Found nimble file: {nimbleFile}".green
  
  let content = readFile(nimbleFile)
  let currentVersion = extractVersion(content)
  if currentVersion.len == 0:
    echo "❌ Could not find version in nimble file!".red
    quit(1)
  
  let newVersion = incrementVersion(currentVersion)
  echo fmt"📊 Version: {currentVersion} → {newVersion}".yellow
  
  if not updateNimbleFile(nimbleFile, currentVersion, newVersion):
    echo "❌ Failed to update version in nimble file!".red
    quit(1)
  
  echo "✅ Updated version in nimble file".green
  
  echo "🔧 Running nimble install...".blue
  let (output, exitCode) = execCmdEx("nimble install")
  
  if exitCode != 0:
    echo "❌ Nimble install failed:".red
    echo output.strip()
    quit(1)
  
  echo "✅ Nimble package updated and installed successfully!".green
  echo fmt"📦 Package now at version {newVersion}".cyan

when isMainModule:
  main()