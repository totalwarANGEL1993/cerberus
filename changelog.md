Version 1.1.0

Allgemein
- Lib.Version zeigt im LuaDebugger die Cerberus-Version an.
- Doppelladen gefixt
- Ladereihenfolge umgekehrt (einfacheres Testen)

Interaction
- Funktionsnamen eingekürzt
- Der letzte NPC und der letzte Held werden für jeden Spieler gespeichert. Die
  alten Globalen entfallen.
  (Kein Desync-Grund, sorgte aber für andere Fehler)
- Interaction.Hero(_PlayerID) - gibt den Skriptnamen des letzten Helden des
  Spielers zurück, der einen NPC angesprochen hat.
- Interaction.Npc(_PlayerID) - gibt den Skriptnamen des letzten NPC zurück,
  der durch einen Helden des Spielers angesprochen wurde.

