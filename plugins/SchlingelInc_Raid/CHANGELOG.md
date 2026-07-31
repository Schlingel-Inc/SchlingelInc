## 1.0.2

- Normale Sends (Signup/Cancel/Signal/Sync-Request) laufen nicht mehr über den CTL-Fallback bei client-seitigem Throttle; nur der Relay-Traffic nutzt weiterhin CTL

## 1.0.1

- Bugfix: Stornierte Raids konnten durch verspätete Relays von Mitspielern mit altem Datenstand wiederbelebt werden
- Bugfix: Notizfeld konnte durch veraltete Client-Versionen fehlerhaft wachsen (akkumulierte Zeitstempel). Bereits betroffene Einträge werden einmalig automatisch bereinigt

## 1.0.0

- Raid Sub-Modul angelegt