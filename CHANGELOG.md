# 4.1.2

- HOTFIX unblock gossip for blocked npcs

# 4.1.1

- Tode werden nun nicht mehr doppelt gezählt. Das Death Modul wurde umfassend refactored.
- Invite Mechanismus schickt nun /who requests um einen Online Indikator für Offiziere zu bieten.

# 4.1.0

- Großschlingel haben jetzt Zugriff auf das Offizier-Panel
- `/deathset` ist jetzt ein Officer-Kommando und wird per Addon-Whisper an den Zielspieler übermittelt
- Fortschritt-Tab: Hover über einen Spieler zeigt jetzt dasselbe Info-Menü wie im Gilden-Panel (Klasse, Rang, Zone, Notiz, Rolle, Discord, Berufe, Tode)
- Pronomen werden jetzt korrekt an andere Spieler übertragen und im Hover-Menü angezeigt
- Todesmeldungen im Raid werden nicht mehr an die Gilde gesendet, nur noch gezählt (verhindert Spam bei Wipes)
- Wenn man selbst in einer Instanz ist, werden Todesmeldungen anderer kompakt und oben rechts am Bildschirmrand angezeigt
- Alle Fenster und Popups (u.a. Tode-, Levelup- und PvP-Meldungen sowie Beitrittsanfrage) sind jetzt verschiebbar und merken sich ihre Position
- Ungenutztes Inaktivitätsfenster entfernt (Funktion wurde vom Inaktiv-Tab im Offizier-Panel abgelöst)
- Bugfix: Ein langes Discord Handle konnte eigene Todes- und Levelup-Meldungen komplett blockieren (Gildenchat-Nachricht überschritt WoWs Zeichenlimit); Discord Handle jetzt auf 50 Zeichen begrenzt, Gildenchat-Ankündigungen werden zusätzlich vor dem Senden auf eine sichere Länge gekürzt
- Letzte Worte werden jetzt als eigene Gildennachricht verschickt, damit sie die Todesmeldung nicht mehr über das Zeichenlimit drücken können
- Neue Option "Kompakte Ansicht" bei den Todesmeldungen: zeigt Todesmeldungen anderer immer im kompakten Format an, nicht nur in Instanzen

# 4.0.9

- Noch mehr Offis hinzugefügt um der Flut an Invite Requests gerecht zu werden.

# 4.0.8

- Gildenansicht: Namensfilter berücksichtigt jetzt auch Discord-Handles.

# 4.0.7

- Tode in Instanzen und Raids werden wieder korrekt angekündigt und gezählt.

# 4.0.6

- Offizier-Panel: Per-Tab-Filterleisten hinzugefügt: Inaktiv filtert nach Name, Fortschritt nach Name / Level (mit </> Umschalter) / Nur Cap / Gold (mit ≤/≥ Umschalter), Discord nach Name und minimaler Charakteranzahl; Anfragen- und Regeln-Tab haben keinen Filter
- Beitrittsanfragen: Einladungen von Spielern die gegen eine aktive Gildenregel verstoßen werden blockiert
- Fortschritt-Broadcast-Regel vollständig entfernt: Kein `progressBroadcastRule` mehr in Regeln, Gildeninfo-Encoding und Debug-Ausgabe
- Fortschritt-Sync auf Anfrage umgestellt: Es wird ein `PROGRESS_REQUEST` in die Gilde gesendet, Antworten kommen gezielt per Whisper als `PROGRESS` zurück
- Lokaler Fortschritts-Cache wird weiter bei relevanten Events aktualisiert (Login, Zonenwechsel, Gildenupdate, XP-Stop-Wechsel, Roster-Update)
- Regelparser bleibt kompatibel zu älteren Gildeninfo-Formaten mit zusätzlichem historischem Progress-Flag

# 4.0.5

- Fortschritt-Tab zeigt die anzahl der erlernten Runen an

# 4.0.4

- Fortschritt-Broadcast (PROGRESS) wieder aktiviert
- Fortschritt-Broadcast nutzt jetzt einen konfigurierbaren Schwellenwert aus `Constants.COOLDOWNS.PROGRESS_BROADCAST` statt eines fest verdrahteten Intervalls
- Fortschritt-Broadcast wird nicht mehr durch XP-Gewinn (`PLAYER_XP_UPDATE`) ausgelöst
- Fortschritt-Broadcast wird nicht mehr durch Goldänderung (`PLAYER_MONEY`) ausgelöst
- Gildenansicht: Neue Spalte `Discord` direkt neben `Rolle` hinzugefügt
- Offizier-Panel: Neuer Tab `Discord` ergänzt, der Charaktere pro Discord-Handle gruppiert anzeigt

# 4.0.3

- Bugfix: Progress messages temporary disabled

# 4.0.2

- Bugfix: Zuverlässigkeit von Addon-Nachrichten verbessert, wenn der Gildenroster kurzzeitig noch nicht vollständig geladen ist
- Bugfix: Todesmeldungen (DEATH) gehen bei Cache-/Roster-Timingproblemen nicht mehr verloren, sondern werden kurz zwischengespeichert und nach GUILD_ROSTER_UPDATE erneut verarbeitet
- Bugfix: Meilenstein- und Cap-Meldungen (LEVELUP / CAP) verwenden jetzt denselben Retry-Mechanismus und werden bei temporär fehlgeschlagener Senderprüfung nachgeliefert
- Bugfix: Milestone-Check korrigiert, damit bei nicht gesetztem Level-Cap (CurrentCap = 0) Level-Up-Meilensteine nicht fälschlich unterdrückt werden
- Intern: Gildencache-Validierung robuster gemacht (Live-Roster-Fallback bei Cache-Miss)

# 4.0.1

- Der XPStop Status wird nun an Offis übertragen, damit diese nachvollziehen können wie sehr man die Levelschande provoziert.

# 4.0.0

- Einrichtungsassistent: Der Berufsschritt erscheint jetzt nicht mehr bei jedem Einloggen – eine einmalige Eingabe genügt. Spieler auf Level 1 ohne Berufe überspringen diesen Schritt automatisch
- Gildenansicht und Todes-Fenster sind jetzt ausschließlich für Gildenmitglieder sichtbar
- Nicht-Gildenmitglieder haben am Minimap-Icon einen eigenen Flow: Linksklick öffnet solange den Einrichtungsassistenten, bis das Profil vollständig ist – danach wird direkt die Beitrittsanfrage geöffnet
- Gilde beigetreten ohne Reload: Das Addon lädt nach dem Annehmen einer Gildeneinladung die Mitgliederliste automatisch nach – die Gildenansicht funktioniert sofort, kein Reload mehr nötig
- Offizier-Panel → Fortschritt: Level- und XP-Daten der Mitglieder bleiben jetzt über Reloads erhalten und müssen nicht erst neu gesammelt werden. Daten werden außerdem während des aktiven Spielens regelmäßig aktualisiert, nicht nur beim Einloggen oder Zonenchange
- Bugfix: Einladungs-Popup hatte ein verschobenes Layout – Icon ragte aus dem Fensterrahmen heraus, Buttons waren falsch positioniert. Alles korrekt ausgerichtet
- Anfragen an offline Offiziere: Systemmeldungen werden jetzt unterdrückt; Absender sieht nur "Anfrage gesendet…" im Chat
- Offizier-Einrichtungsassistent entfernt
- Bugfix: Offizier-Chat-Spam bei eingehenden Beitrittsanfragen – Duplikate erzeugen keine Chatmeldung mehr
- Bugfix: Neu eingeladene Mitglieder erscheinen jetzt sofort im Fortschritt-Tab – Fortschrittsdaten werden beim Gilden-Beitritt mid-Session automatisch gesendet
- Bugfix: Fortschritt-Tab aktualisiert sich jetzt live wenn Mitglieder Daten senden, ohne manuelles Tab-Wechseln
- Bugfix: Ex-Mitglieder werden aus dem Fortschritt-Cache (Session und SavedVariables) entfernt wenn der Roster aktualisiert wird
- Bugfix: Decline/Accept-Broadcasts wurden auch an den ausführenden Offizier selbst gesendet – "Ein Offi hat X abgelehnt" erschien als Selbstmeldung
- Bugfix: Offizier-Status im Panel wurde einmalig beim Öffnen gecacht – Beförderungen und Degradierungen mid-Session wurden ignoriert
- Bugfix: `SetParent(nil)` in InactivityWindow durch trashFrame-Pattern ersetzt (Absturz in bestimmten Classic-Builds)
- Bugfix: `UnitName("player")` wurde zu früh gecacht – letzte-Worte-Tracking war dadurch für die gesamte Session kaputt
- Bugfix: `GuildProfiles:Broadcast` konnte bei nil `UnitName("player")` den Profil-Cache korrumpieren
- Bugfix: `Rules:GetRules` konnte bei leerer Gildeninfo endlos retries auslösen – jetzt maximal 10 Versuche (20 Sekunden)
- Bugfix: `seenDeaths` wurde nie geleert – wird jetzt bei jedem Login/Reload zurückgesetzt

# 3.7.0

- Portierung auf Season of Discovery (Classic 1.x): Interface-Version auf 11508 aktualisiert
- Multi-Edition-Support: Das Addon läuft jetzt sowohl in TBC Classic als auch in Season of Discovery aus einer gemeinsamen Codebasis
- Neues `Compat.lua` erkennt die laufende WoW-Edition zur Ladezeit (`SchlingelInc.IsTBC` / `SchlingelInc.IsClassicEra`)
- Level Cap auf 60 für SoD, bleibt 70 für TBC Classic
- Level-Meilensteine für SoD angepasst (neu: Level 25); für TBC Classic unverändert
- Juwelierkunst aus dem Berufs-Mapping entfernt (nicht in Classic Era / SoD verfügbar)
- SoD: Bestimmte Händler (NPC-IDs 233335 und 233428) werden automatisch gesperrt – Gossip- und Händlerfenster werden geschlossen und ein Hinweis-Popup wird angezeigt
- Offizier-Panel und Offizier-Einrichtungsassistent: Die Sperre für SoD-Händler kann jetzt wie die anderen Gildenregeln ein-/ausgeschaltet und in der Gildeninfo gespeichert werden
- Dev-Tooltip: Spieler mit dem Rang "Devschlingel" sehen im Tooltip die NPC-ID von Kreaturen sowie eine Spieler-ID für Charaktere
- Debug: Neuer Befehl `/schlingeldebug events [start|stop]` – trackt alle gefeuerten WoW-Events im Chat
- Bugfix: `IsActiveBattlefieldArena()` wird in SoD nicht mehr aufgerufen (API existiert nicht in Classic 1.x)
- Bugfix: Offizier-Panel stürzte beim Öffnen ab, weil das Briefkasten-Dropdown keinen globalen Frame-Namen hatte – `UIDropDownMenu_DisableDropDown` benötigt einen benannten Frame
- Bugfix: `SchlingelInc = {}` in `Global.lua` überschrieb die von `Compat.lua` gesetzten Editions-Flags – alle editionsspezifischen Prüfungen (Händlersperre, Arena-Check, Level Cap) waren dadurch wirkungslos

# 3.6.2

- Bugfix: Mail Handler stürzt jetzt nicht mehr nach dem Reload ab.
- Feature: Mail Regel ist im Offi Setup nun ein Dropdown, um fein granulierter den Mailbox Zugang zu regulieren.

# 3.6.1

- Bugfix: Todesmeldungen in Dungeons und Raids werden nicht mehr an die Gilde gemeldet und im Todesfenster angezeigt
- Bugfix: Handelsbeschränkung gilt jetzt nicht mehr innerhalb von Instanzen (Dungeons, Raids, Schlachtfelder, Arenen)
- Bugfix: Offizier-Einrichtungsfenster erscheint beim Betreten oder Verlassen einer Instanz nicht mehr; öffnet sich nur noch beim echten Einloggen oder Reloaden
- Bugfix: Offizier-Einrichtungsfenster hat jetzt einen X-Button zum Schließen
- Bugfix: Beitrittsanfragen über das Addon funktionieren jetzt für Charaktere aller Level, nicht nur Level 1
- Bugfix: Briefkasten war nach dem Einloggen gesperrt obwohl die Regel freigegeben war. Das Addon liest die Regel jetzt erst aus der Gildeninfo bevor es den Briefkasten sperrt

# 3.6.0

- Neues Offizier Panel: Gildenregeln (Briefkasten, Auktionshaus, Handel, Gruppierung, Duelle, Level Cap) direkt im Spiel konfigurieren und in die Gildeninfo schreiben – erreichbar per Rechtsklick auf das Minimap-Icon
- Offizier-Einrichtungsassistent: Führt beim ersten Start durch die Auswahl der Offiziersränge und die initiale Regelkonfiguration – öffnet sich automatisch wenn noch keine Regeln in der Gildeninfo hinterlegt sind
- Minimap Icon Rechtsklick öffnet jetzt das Offizier Panel für alle Gildenmitglieder
- Bugfix: Doppelte Todesmeldungen wenn ein Tod sowohl über den Gildenchat als auch über eine Addon-Nachricht empfangen wurde
- Bugfix: Eigenes Profil wurde nach dem Login nicht im lokalen Profil-Cache gespeichert – GUILD-Addon-Nachrichten kommen beim Absender in WoW Classic nicht zurück
- Bugfix: Profile von bereits eingeloggten Gildenmitgliedern wurden beim eigenen Login nicht empfangen; das Addon fordert beim Start nun aktiv Profile von allen online Mitgliedern an
- Bugfix: Gildencheck im Briefkasten und bei der Gruppenregel lief bisher über einen vollständigen Roster-Scan; beide nutzen jetzt den Gildenmitglieder-Cache
- Gildencache wird jetzt mit höherer Priorität aktualisiert, damit er für alle anderen Module stets aktuell ist
- Mehrfachrollen: Spieler können jetzt mehrere Rollen gleichzeitig auswählen (z.B. Tank und Heal) – die Gildenansicht filtert und sortiert entsprechend

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
