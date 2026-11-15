# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import libclip/clipboard
import os
import osproc
import streams
import strutils
import db_connector/db_sqlite

when isMainModule:

  proc main() =

    let paramCount = paramCount()

    proc checkDir(): string =
      let dir = getHomeDir() / ".svclip"
      if not dirExists(dir):
        createDir(dir)
      result = dir

    proc save(name: string) =
      let dir = checkDir()
      let db = open(dir / "clips.db", "", "", "")
      let clipText = getClipboardText();

      db.exec(sql"""
        CREATE TABLE IF NOT EXISTS clips (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          text TEXT NOT NULL,
          created TEXT DEFAULT CURRENT_TIMESTAMP
        )""")

      let rows = db.getAllRows(sql"SELECT id, text, created FROM clips WHERE name = ?", name)
      if rows.len == 0:
        db.exec(sql"INSERT INTO clips (name,text) VALUES (?,?)", name, clipText)
      else:
        db.exec(sql"UPDATE clips SET text = ? WHERE name = ?", clipText, name)

      let path = getHomeDir() / ".svclip" / "latest"
      writeFile(path, name)

      echo "Saved."
      return

    proc load(name: string) =
      let dir = checkDir()
      let db = open(dir / "clips.db", "", "", "")

      db.exec(sql"""
        CREATE TABLE IF NOT EXISTS clips (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          text TEXT NOT NULL,
          created TEXT DEFAULT CURRENT_TIMESTAMP
        )""")

      let one = db.getAllRows(sql"SELECT id, text, name, created FROM clips WHERE name = ? LIMIT 2", name)
      var all = db.getAllRows(sql"SELECT id, text, name, created FROM clips WHERE name LIKE ? LIMIT 2", ("%" & name & "%"))
      if (one.len == 1):
        all = one
      if all.len == 0:
        echo "Not found."
        let foundSimilar = db.getAllRows(sql"SELECT id, text, name, created FROM clips WHERE name LIKE ? LIMIT 10", ("%" & name[0 .. 1] & "%"))
        if foundSimilar.len > 0:
          echo "Similar names:"
          for row in foundSimilar:
            echo row[2]
      elif all.len > 1:
        echo "There are more similar. Would you like one of them?"
        for row in all:
          echo row[2]
      else:
        let first = all[0]
        echo "Found and put to clipboard."
        echo "Id: " & first[0] & "  Name: " & first[2] & "  Size: " & $len(first[1]) & "  Created: " & first[3]
        if len(first[1]) > 15:
          echo "Text: " & first[1][0 .. 14] & "..."
        else:
          echo "Text: " & first[1]
        discard setClipboardText(first[1])
        let path = getHomeDir() / ".svclip" / "latest"
        writeFile(path, first[2])
      return

    proc loadByNum(id: int) =
      let dir = checkDir()
      let db = open(dir / "clips.db", "", "", "")

      db.exec(sql"""
        CREATE TABLE IF NOT EXISTS clips (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          text TEXT NOT NULL,
          created TEXT DEFAULT CURRENT_TIMESTAMP
        )""")

      let all = db.getAllRows(sql"SELECT id, text, name, created FROM clips WHERE id = ? LIMIT 1", id)
      if (all.len == 1):
        let first = all[0]
        echo "Found and put to clipboard."
        echo "Id: " & first[0] & "  Name: " & first[2] & "  Size: " & $len(first[1]) & "  Created: " & first[3]
        if len(first[1]) > 15:
          echo "Text: " & first[1][0 .. 14] & "..."
        else:
          echo "Text: " & first[1]
        discard setClipboardText(first[1])
        let path = getHomeDir() / ".svclip" / "latest"
        writeFile(path, first[2])
      else:
        echo "Not found."

    proc listAll() =
      let dir = checkDir()
      let db = open(dir / "clips.db", "", "", "")

      db.exec(sql"""
        CREATE TABLE IF NOT EXISTS clips (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          text TEXT NOT NULL,
          created TEXT DEFAULT CURRENT_TIMESTAMP
        )""")

      let all = db.getAllRows(sql"SELECT id, text, name, created FROM clips ORDER BY name")
      for row in all:
        echo row[0], " | ", row[2]
      if len(all) == 0:
        echo "There is no keys."

    proc remove(name: string) =
      let dir = checkDir()
      let db = open(dir / "clips.db", "", "", "")

      let all = db.getAllRows(sql"SELECT id, text, name, created FROM clips WHERE name = ? LIMIT 1", name)
      if all.len == 0:
        echo "There is no key to delete. There is no such a key."
      else:
        db.exec(sql"DELETE FROM clips WHERE name = ?", name)
        removeFile(dir / "latest")
        echo "Key removed."

    proc removeById(id: int) =
      let dir = checkDir()
      let db = open(dir / "clips.db", "", "", "")

      let all = db.getAllRows(sql"SELECT id, text, name, created FROM clips WHERE id = ? LIMIT 1", id)
      if all.len == 0:
        echo "There is no entry to delete. There is no such an Id."
      else:
        db.exec(sql"DELETE FROM clips WHERE id = ?", id)
        removeFile(dir / "latest")
        echo "Entry removed."

    proc resetAll() =
      echo "Are you sure to remove all keys (y/n)? "
      let ok = readLine(stdin)
      if (ok == "y" or ok == "yes"):
        let dir = checkDir()
        let db = open(dir / "clips.db", "", "", "")
        db.exec(sql"DELETE FROM clips")
        removeFile(dir / "latest")
        echo "All key are deleted."
      elif (ok == "n" or ok == "no"):
        echo "Ok. Nothing happened."
      else:
        echo "Ok. Nothing happened. Are you unsure? "

    proc getLatest(): string =
      let path = getHomeDir() / ".svclip" / "latest"
      var latest = ""
      try:
        latest = readFile(path)
      except IOError:
        latest = ""   # missing or unreadable
      return latest

    proc version(): string =
      return "1.0.0"

    proc info() =
      echo "svclip ", version()
      echo "This is a clipboard content manager program."
      echo " × You can save the clipboard content to a key or title"
      echo " × You can load the specific key and copy to clipboard."
      echo " × You can also list the keys, and you can remove one or all."
      echo ""
      echo "Usage:"
      echo "  Save:"
      echo "    svclip s [key]                       - Save Clipboard to key"
      echo "    svclip sl                            - Save Clipboard to latest key"
      echo "  Load:"
      echo "    svclip [search]                      - Search and Copy to Clipboard"
      echo "    svclip id [id]                       - Search by Id and Copy to Clipboard"
      echo "  List:"
      echo "    svclip la                            - List all keys"
      echo "    svclip ll                            - Show latest key"
      echo "  Remove:"
      echo "    svclip r [key]                       - Remove the entry by key name"
      echo "    svclip ri [id]                       - Remove the entry by id"
      echo "    svclip ra                            - Remove all key"
      echo "  Help:"
      echo "    svclip                               - Show this message"

    if paramCount == 2:
      if paramStr(1) == "s":
        save(paramStr(2))
        quit()
      elif paramStr(1) == "r":
        remove(paramStr(2))
        quit()
      elif paramStr(1) == "ri":
        let idString = paramStr(2)
        var id: int
        try:
          id = parseInt(idString)
        except ValueError:
          echo "Not a valid Id"
        removeById(id)
        quit()
      elif paramStr(1) == "id":
        let idString = paramStr(2)
        var id: int
        try:
          id = parseInt(idString)
        except ValueError:
          echo "Not a valid Id"
        loadByNum(id)
        quit()

    elif paramCount == 1:

      if paramStr(1) == "ll":
        let latest = getLatest()
        if latest != "":
          echo latest
        else:
          echo "There is no latest key."
        quit()
      elif paramStr(1) == "la":
        listAll()
        quit()
      elif paramStr(1) == "ra":
        resetAll()
        quit()
      elif paramStr(1) == "sl":
        let latest = getLatest()
        if latest == "":
          echo "There is no latest yet."
          quit()
        save(latest)
        echo "  Name: " & latest
        quit()
      else:
        load(paramStr(1))
        quit()

    info()

  # Call main
  main()
