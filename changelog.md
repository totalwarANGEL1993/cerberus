Version 1.3.0

- Spectatable Briefings hinzugefügt
  (Briefings können an weitere Spieler gestreamt werden. Diese haben allerdings
  nur lesenden Zugriff.)
- Buy Hero wurde in das "mp" Modul verschoben
  (Load Path hat sich geändert!)

Version 1.1.5

- Load Order angepasst: Es wird zuerst in der Map gesucht
- IsDeadWrapper wurde hinzugefügt
- Klick Spam beim NPC-Händler wird nun nicht mehr möglich
- Wenn ein NPC vom falschen Helden/Spieler angesprochen wird, erscheint
  nun die Hinweismeldung
- Bei aktivem Workplace Modul sind nach Ausbau die Gebäude nicht mehr leer
- Zufallsalgorythmus für Schatztruhen wurde angepasst
- Schatztruhen können nun auch leer sein
- Syncer installiert sich nun automatisch selbst

Version 1.1.3

- Bei der Heldenwahl werden bereits gewählte Helden ausgegraut
- Funktion zum Pushen von Archiven hinzugefügt

Version 1.1.0

Allgemein
- Lib.Version zeigt im LuaDebugger die Cerberus-Version an.
- Doppelladen gefixt
- Ladereihenfolge umgekehrt (einfacheres Testen)

Briefing System
- Funktionsnamen eingekürzt
- Escape wirkt sich nicht mehr auf andere Spieler aus.

Interaction
- Funktionsnamen eingekürzt
- Der letzte NPC und der letzte Held werden für jeden Spieler gespeichert. Die
  alten Globalen entfallen.
  (Kein Desync-Grund, sorgte aber für andere Fehler)
- Interaction.Hero(_PlayerID) - gibt den Skriptnamen des letzten Helden des
  Spielers zurück, der einen NPC angesprochen hat.
- Interaction.Npc(_PlayerID) - gibt den Skriptnamen des letzten NPC zurück,
  der durch einen Helden des Spielers angesprochen wurde.
- Ausverkauft- und erforschttexte für den Händler

