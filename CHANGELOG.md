# 3.5.2

- Berufsränge werden jetzt automatisch aktualisiert, wenn ein Spieler einen Berufsskill steigert – die neuen Werte werden sofort ins eigene Profil übernommen und an andere Addon-Nutzer in der Gilde übermittelt

# 3.5.1

- Bugfix: Guild-chat-Parser für Todesmeldungen entfernt – Tode werden jetzt ausschließlich über Addon-Messages verarbeitet, was doppelte Einträge und Fehlzuordnungen verhindert
- Bugfix: Gildennotiz wird beim Tod nicht mehr automatisch geleert
- Bugfix: Discord-Handle-Anzeige im Chat liest jetzt direkt aus dem Profil-Cache statt aus der Gildennotiz

# 3.5.0

- Neue Gildenansicht: zeigt alle Gildenmitglieder mit Level, Rang, Zone, Rolle, Berufen und Todesfällen auf einen Blick
- Spieler-Profile: jedes Mitglied kann Rolle und Berufe hinterlegen – die Daten werden automatisch mit allen anderen Addon-Nutzern synchronisiert
- Einrichtungsassistent: beim ersten Start führt ein Assistent durch die Eingabe von Rolle, Berufen und Discord-Handle
- Berufsanzeige einheitlich auf Deutsch – unabhängig davon, ob der Spieler einen deutschen oder englischen Client nutzt
- Gildenansicht: Klick auf eine Spaltenüberschrift sortiert die Liste auf- oder absteigend
- Gildenansicht: Offline-Mitglieder können per Schalter ausgeblendet werden
- Gildenansicht: Filtermenü zum Suchen nach Name, Rolle und Beruf
- Gildenansicht: Rechtsklick auf ein Mitglied öffnet das gewohnte WoW-Kontextmenü mit Flüstern, Einladen, Inspizieren usw.
- Bugfix: Einrichtungsassistent wurde bei manchen Spielern fälschlicherweise beim Login angezeigt, obwohl sie bereits in der Gilde waren

# 3.2.3

- Bubble-Ruhestein-Beschämung entfernt: Paladine werden nicht mehr im Gildenchat angezeigt, wenn sie Divine Shield + Ruhestein benutzen
- Cap-Check wird übersprungen, wenn der Spieler bereits auf Max-Level ist

# 3.2.1

- Bugfix: PvP-Todesmeldungen wurden durch einen Operator-Fehler nicht korrekt unterdrückt – wer am Cap im BG gestorben ist, hat trotzdem eine Meldung bekommen.
- Handel mit Nicht-Gildenmitgliedern ist jetzt in Battlegrounds, Raids und Arenen erlaubt

# 3.2.0

- Optionsmenü komplett überarbeitet: Einstellungen sind jetzt übersichtlich in drei Tabs aufgeteilt – Allgemein, Benachrichtigungen und Sound
- Jede Ankündigung hat ihren eigenen Bereich mit separaten Schaltern für die Meldung und den dazugehörigen Ton
- Neue Option: Soundkanal – ihr könnt selbst wählen, über welchen ingame Lautstärkeregler (Master, Effekte, Umgebung, Musik) die Schlingel-Sounds laufen

# 3.1.3

- Bevorzugte Pronomen: Spieler können optional ihre Pronomen hinterlegen; diese werden in Chatnachrichten, Gildennotiz und Tooltip korrekt verwendet
- `/setPronouns <Pronomen>`: Setzt die bevorzugten Pronomen als Freitext – alles nach dem Befehl wird als Pronomen übernommen (z.B. `/setPronouns er/ihm`)
- `/clearPronouns`: Entfernt die gespeicherten Pronomen vollständig
- Verbesserter Discord-Handle-Abfrage: Bei einem PC-Wechsel oder einer Neuinstallation wird die Gildennotiz zuerst abgerufen um eine unnötige Neueingabe durch das Popup zu verhindern

# 3.1.2

- Soundpaket-Auswahl: In den Optionen kann nun zwischen Standard WoW Sounds und Torro Sounds gewählt werden
- Torro Sounds für Todesmeldungen: "Schandenschlingel" und "Tausend Tode" werden zufällig abgespielt
- Torro Sound für Level-Up Meldungen: "Ehrenschlingel"
- Torro Sound für Cap-Meldungen: bestehender Cap-Sound
- Mediendateien in Unterordner aufgeteilt: `media/sounds/` und `media/graphics/`
- Debug-Befehle: `/schlingeldebug levelup` und `/schlingeldebug cap` zum lokalen Testen der Popups hinzugefügt

# 3.1.0

- Level-Up Ankündigungen: Popup für Gildenmitglieder bei Meilensteinen (10, 20, 30, 40, 50, 60) via AddonMessage
- Cap-Ankündigung: eigenes Popup mit speziellem Sound bei Erreichen des Level Caps
- Erreicht ein Spieler das Cap auf einem Meilensteins-Level, wird nur die Cap-Ankündigung abgespielt
- Queue-System: Tod-, Level-Up- und Cap-Popups überlagern sich nicht mehr, sondern werden nacheinander angezeigt
- Neue Optionen: Level-Up Meldungen, Level-Up Ton, Cap-Meldungen, Cap-Ton separat ein-/ausschaltbar

# 3.0.7

- Mailbox im Gildenchat nutzbar; NPC-Mails werden korrekt gefiltert; Tab-Wechsel Bugs behoben; Schaltflächen korrekt gesperrt
- LevelCap Popup warnt vor dem unbeabsichtigten Brechen des Level Caps
- PvP Tode unter dem Level Cap werden weiterhin im Gildenchat gemeldet; am Cap nicht
- Versions-Sync: Versionsnummern aller eingeloggten Gildenmitglieder werden jetzt korrekt übertragen

# 2.3.0

-- Major code cleanup and optimizations

# 2.2.8

-- Fixed invite whitelist

# 2.2.7

- Disable grouping restrictions

# 2.2.6

- Reworking Invite Interface

# 2.2.5

- fix PfundsSchlingel name

# 2.2.4

- Added PfundsSchlingel to allow Invites

# 2.2.3

- Revive Announcement ausgebaut
- Battleground und Raid Check nun per Blizzard API

# 2.2.2

- No death announcements in allowed raids (Molten Core, Onyxias Lair)

# 2.1.8

- Death Announcement improvement and new Deathlog in basic interface Tab

# 2.1.7

- Group Check now ignores online status
- Reduced performance impact
- Correct article for different genders
- Removed Level up announcement for 45 and 55

# 2.1.6

- Fixing Guild Invites. Cleaning up Offi Interface

# 2.1.1, 2.1.2, 2.1.3

- Fix grouping bug

# 2.1.0

- Rollback to old rule handling for one guild

# 2.0.13

- Fix grouping-rule

# 2.0.11, 2.0.12

- Removing guild invites, since a broken loop is causing spam and crashes

# 2.0.10

- Play sound when Target is pvp active
- Display Alert with sound when someone dies
- Fix death counter

# 2.0.9

- Remove guild request messages from players who can't invite people

# 2.0.8

- Adding basic functionality to Offi Interface and improving visuals of both interfaces

# 2.0.6, 2.0.7

- Remove GreenWall from dependencies and check ingame if it is enabled

# 2.0.5

- Fixing false positive on "Alliance" NPCs

# 2.0.4

- Fixing DeathCount initialization and PvP Flag on neutral NPCs

# 2.0.3

- Remove Version hint for non for players without invite permissions

# 2.0.2

- Removed guild request message for players without invite permissions

# 2.0.1

- Fixed Battleground-Check
