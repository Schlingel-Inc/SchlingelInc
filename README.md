# Schlingel Inc - WoW Addon

[![CurseForge Downloads](https://img.shields.io/curseforge/dt/1224740?style=for-the-badge&logo=curseforge)](https://www.curseforge.com/wow/addons/schlingel-addon)
[![WoW Version](https://img.shields.io/badge/WoW-Classic%20TBC%202.5.x-blue?style=for-the-badge&logo=battledotnet)](https://worldofwarcraft.blizzard.com/)
[![Discord](https://img.shields.io/badge/Discord-DerHauge-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/KXkyUZW)
[![Ko-fi Pudi](https://img.shields.io/badge/Ko--fi-Pudi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/einfachpudi)
[![Ko-fi Cricksu](https://img.shields.io/badge/Ko--fi-Cricksu-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/cricksu)

Offizielles Addon für die Schlingel Inc WoW Gilde

> **Disclaimer:** Alle Inhalte im `media/` Ordner (Bilder, Sounds, etc.) sind Eigentum des Event-Teams von Schlingel Inc und dürfen ohne ausdrückliche Genehmigung nicht anderweitig verwendet werden.

---

## Hauptfunktionen

### Gildenbeitritt

Spieler können der Gilde direkt über das Addon-Interface beitreten.

**Features:**
- **Einfacher Beitritt:** "Beitrittsanfrage senden" Button im Addon-Interface
- **Automatisiertes Rekrutierungssystem:** Offiziere erhalten Beitrittsanfragen mit allen wichtigen Informationen
- **Anfragedetails:** Name, Level, XP, Zone, Gold werden automatisch übermittelt
- **Ein-Klick-Verwaltung:** Offiziere können Anfragen mit einem Klick annehmen oder ablehnen

> **So trittst du bei:** Logge dich ein, klicke auf das rosa "SI"-Symbol an der Minimap und drücke "Beitrittsanfrage senden".

### Death Tracking & Announcements

Alle Tode werden in der Gilde geteilt und angezeigt.

**Features:**
- **Todeszähler:** Verfolgt die Anzahl deiner Tode pro Charakter
- **Automatische Todesmeldungen im Gildenchat:**
  - Name und Discord Handle (falls vorhanden)
  - Klasse und Level
  - Zone des Todes
  - Todesursache (was dich getötet hat)
  - Letzte Worte (aus dem Chat erfasst)
- **Todes-Popup:** Visuelle Benachrichtigung mit Animation wenn Gildenmitglieder sterben
- **Mini-Deathlog:** Kompaktes, skalierbares Fenster zeigt die letzten 50 Tode
  - Spalten: Name, Klasse, Level
  - Tooltip mit vollständigen Details beim Hover (Discord Handle, Zone, Todesursache, Letzte Worte)
  - Größe anpassbar: 250x120 Minimum bis 500x350 Maximum
  - Speichert Position und Größe automatisch
- **Slash Command:** `/deathset <nummer>` zum manuellen Setzen des Todeszählers

### Levelbenachrichtigungen

Das Addon gratuliert automatisch bei wichtigen Level-Meilensteinen.

**Glückwünsche bei:**
- Level 10, 20, 30, 40, 50, 60, 70

**Features:**
- Automatische Guild Chat Benachrichtigung bei Meilensteinen
- Nachricht: "Spieler hat Level X erreicht! Schlingel! Schlingel! Schlingel!"

### Rules Enforcement

Das Addon erzwingt automatisch die Gilden-Regeln (konfiguriert über Gildeninfo).

**Was wird blockiert:**
- **Briefkasten** - Wird automatisch geschlossen (mit Popup-Meldung)
- **Auktionshaus** - Wird automatisch geschlossen (mit Popup-Meldung)
- **Handel mit Nicht-Gildenmitgliedern** - Wird automatisch abgebrochen (mit Popup-Meldung)
- **Gruppen mit Nicht-Gildenmitgliedern** - Du wirst automatisch aus der Gruppe entfernt (mit Popup-Meldung)
- **Party-Einladungen von Nicht-Gildenmitgliedern** - Werden automatisch abgelehnt

> **Hinweis:** Die Regeln werden aus der Gildeninfo geladen (Format: `Schlingel:1111`). Jede Ziffer aktiviert/deaktiviert eine Regel.

### PvP-Warnsystem

Warnt wenn du PvP-aktivierte NPCs oder Spieler targetierst.

**Features:**
- Warnung bei Targeting von PvP-aktivierten Gegnern
- Spezielle Warnung bei Allianz-NPCs
- Visuelles Popup-Fenster mit rotem "Obacht Schlingel!" Header
- Optionaler Warnton (konfigurierbar in den Einstellungen)
- Wackel-Effekt für bessere Sichtbarkeit
- 10 Sekunden Cooldown pro Spieler um Spam zu vermeiden

### Discord Handle System

Discord Handles werden für die Gilden-Kommunikation gespeichert.

**Features:**
- **Discord Handle Prompt:** Einmalige Abfrage beim ersten Login
- **Account-Wide Storage:** Discord Handle wird account-weit gespeichert (alle Charaktere)
- **Automatische Guild Note:** Handle wird automatisch in die Gildennotiz geschrieben
- **Tooltip Integration:** Discord Handles werden in Spieler-Tooltips angezeigt
- **Format:** `DeinHandle#1234 (Tode: X)`
- **Slash Command:** `/setHandle <handle>` zum Ändern des Discord Handles

> **Einrichtung:** Beim ersten Login erscheint automatisch ein Fenster. Gib einfach deinen Discord Namen ein. Später kannst du ihn mit `/setHandle` ändern.

### Tooltip Erweiterungen

Erweitert Tooltips mit nützlichen Informationen.

**Zeigt an:**
- Discord Handle
- Gildenrang
- Online-Status
- Zusätzliche Charakterinformationen

### Minimap Icon

Zentraler Zugriffspunkt für alle Addon-Funktionen.

**Funktionen:**
- **Linksklick:** Gildenübersicht anzeigen/verstecken
- **Shift+Linksklick:** Death Log anzeigen/verstecken
- **Rechtsklick (Gildenmitglieder):** Offizier Panel öffnen
- **Rechtsklick (Nicht-Mitglieder):** Gildenbeitritts-Prompt öffnen
- **Tooltip zeigt:**
  - Addon Version
  - Verfügbare Funktionen

### Offiziers-Werkzeuge

Spezielle Funktionen für Gildenoffiziere.

**Offizier Panel** (Rechtsklick auf Minimap-Icon):
- **Regeln konfigurieren:** Briefkasten, Auktionshaus, Handel, Gruppierung, Duelle und Level Cap direkt im Spiel ein-/ausschalten
- **Gildeninfo aktualisieren:** Änderungen werden mit einem Klick in die Gildeninfo geschrieben und sofort von allen Mitgliedern geladen
- **Inaktive Mitglieder:** Zeigt Mitglieder die 10+ Tage offline sind, mit Name, Level, Rang und Offline-Dauer sowie direktem Entfernen-Button

**Offizier-Einrichtungsassistent** (automatisch beim ersten Start, oder manuell über das Offizier Panel):
- **Schritt 1:** Auswahl der Ränge, die Beitrittsanfragen erhalten sollen
- **Schritt 2:** Initiale Regelkonfiguration mit direktem Schreiben in die Gildeninfo

### Automatische Optimierungen

Das Addon nimmt beim Start automatisch einige Optimierungen vor.

**Automatische Anpassungen:**
- **Minimap Mail Icon** - Wird ausgeblendet um die Minimap aufgeräumt zu halten
- **Party Invite Sounds** - Group-Einladungssounds werden stummgeschaltet

---

## Installation

### Manuelle Installation

1. Download des Addons
2. Entpacke den Ordner in `World of Warcraft\_classic_\Interface\AddOns\`
3. Starte WoW neu oder `/reload` in-game
4. Minimap-Icon erscheint für schnellen Zugriff auf alle Funktionen

---

## Einstellungen

Das Addon hat einige optionale Einstellungen die du im WoW Options-Menü unter "AddOns" → "Schlingel Inc" findest:

| Option | Beschreibung |
|--------|-------------|
| **PVP Warnung** | Aktiviert/Deaktiviert die PvP-Warnung beim Targeting |
| **PVP Warnung Ton** | Aktiviert/Deaktiviert den Warnton bei PvP-Warnungen |
| **Todesmeldungen** | Aktiviert/Deaktiviert die Todes-Popup-Benachrichtigungen |
| **Todesmeldungen Ton** | Aktiviert/Deaktiviert den Ton bei Todesmeldungen |
| **Version anzeigen** | Zeigt Addon-Versionen im Gildenchat an |

---

## Tipps

- **Death Log:** Linksklick auf Minimap Icon zum Öffnen/Schließen
- **Death Log Größe:** Ziehe an der unteren rechten Ecke um die Größe anzupassen
- **Discord Handle:** Wird automatisch beim ersten Login abgefragt und in der Gildennotiz gespeichert
- **Discord Handle ändern:** `/setHandle <handle>` um den Discord Handle zu ändern
- **Gildenbeitritt:** Rechtsklick auf Minimap-Icon und "Beitrittsanfrage senden" drücken
- **Todeszähler setzen:** `/deathset <nummer>` um den Zähler manuell anzupassen

---

## Technische Details

- **Interface-Version:** 20505 (WoW Classic TBC 2.5.x)
- **Addon-Version:** 3.6.0

**SavedVariables (per Character):**
- `SchlingelOptionsDB` - Einstellungen und UI-Positionen
- `CharacterDeaths` - Todeszähler
- `SchlingelOwnProfile` - Eigenes Profil (Rolle, Berufe)

**SavedVariables (Account-wide):**
- `DiscordHandle` - Discord Handle
- `Pronouns` - Bevorzugte Pronomen
- `SchlingelGuildProfileCache` - Profilcache aller Gildenmitglieder
- `SchlingelGuildDB` - Gilden-Konfiguration (Offiziersränge)

**Addon Message Prefixes:**
- `SchlingelInc` - Guild Communication

**Libraries:**
- LibStub
- LibDataBroker-1.1
- LibDBIcon-1.0

---

## Bekannte Einschränkungen

- **Guild Only:** Alle Features funktionieren nur mit Gildenmitgliedern auf dem gleichen Realm
- **Regel-Konfiguration:** Regeln werden in die Gildeninfo geschrieben und von allen Mitgliedern geladen – Änderungen nur über das Offizier Panel (erfordert Offiziersrechte)
- **Offiziers-Features:** Inaktivitäts-Tracker nur für Ränge: Devschlingel, Pfundschlingel, Großschlingel

---

## Wichtige Hinweise

- Alle Blockaden (Briefkasten, AH, etc.) zeigen Popup-Meldungen zur Information
- Dein Todeszähler wird automatisch in deiner Gildennotiz angezeigt
- Das Addon ist speziell für die Schlingel Inc Gilde entwickelt
- Der Discord Handle wird nur beim ersten Login abgefragt - du kannst ihn jederzeit mit `/setHandle` ändern
- Bei Beitrittsanfragen kann es zu Wartezeiten kommen wenn keine Offiziere online sind

---

## Support & Feedback

Bei Problemen oder Feedback:
- Melde dich bei den Addon-Entwicklern in der Gilde
- Nutze den Probleme-Channel im Discord
- Discord Server: [DerHauge Discord](https://discord.gg/KXkyUZW)

---

## Autoren

- **Cricksu**
- **Pudi**

## Mitwirkende

- **Canasterzaster**

---

## Support the Devs

Wenn dir das Addon gefällt und du uns unterstützen möchtest:

- [Pudi auf Ko-fi](https://ko-fi.com/einfachpudi)
- [Cricksu auf Ko-fi](https://ko-fi.com/cricksu)
