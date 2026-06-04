# ORAHomer

Eine kleine **Oracle-APEX-Anwendung, die als Startseite (App-Launcher) einer APEX-Instanz**
dient. Sie verlinkt **deklarativ alle Apps des Workspace** und lässt sie sich kategorisieren,
mit eigenen Icons versehen, einzeln ausblenden und um **externe Links** ergänzen — ohne die
verlinkten Apps selbst anzufassen.

Aufgebaut nach denselben Konventionen wie das KMLeon-Projekt: Paket-Präfix `PCK_HOM_*`,
**jede Tabelle wird nur über ihr DML-Paket beschrieben**, zentrales Logging, typisierter
Key/Value-Store, Audit-Spalten auf jeder Tabelle, ein File pro Tabelle, und eine
handgepflegte **APEXLang**-App passend zu APEX 26.1.

## Idee

ORAHomer hält **keine Kopie** der App-Liste. Die Startseite liest die Apps live aus dem
APEX-Dictionary (`APEX_APPLICATIONS`, automatisch auf den aktuellen Workspace eingeschränkt)
und mischt sie mit ein paar schlanken Override-Tabellen:

- **Opt-out:** Jede Workspace-App erscheint automatisch, bis du sie ausblendest.
- **Kategorien:** Apps und Links in Gruppen einsortieren.
- **Icons:** Standardmäßig das echte App-Icon (aus den Static Application Files); zusätzlich
  eine **Icon-Bibliothek** zum Hochladen eigener Bilder, die du Apps/Links zuweist. Ohne
  beides wird ein farbiger **Initialen-Badge** generiert.
- **Externe Links:** beliebige URLs als zusätzliche Kacheln.

## Aufbau des Repos

```
sql/
  ddl/tables/   hom_log, hom_config, hom_categories, hom_icons, hom_app_config, hom_links
  packages/     pck_hom_log, _config_dml, _categories_dml, _icons_dml, _app_config_dml, _links_dml, _api
  views/        hom_views.sql  (HOM_TILES_V, HOM_APP_CONFIG_V)
  install.sql / uninstall.sql / update.sql
apex_toolkit/   die APEXLang-Anwendung (App-ID 1200) + setup.sql (Beispieldaten)
docs/           data-model.md
```

## Seiten der App

| Seite | Zweck |
|---|---|
| **1 Startseite** | Kachel-Launcher (Cards) über `HOM_TILES_V`, mit Kategorie- und Such-Filter. Klick öffnet die App bzw. den Link. |
| **2 Apps verwalten** | IR über alle Workspace-Apps; Klick öffnet die Konfiguration. |
| **3 App-Konfiguration** | Kategorie, Icon, Sichtbarkeit, Anzeigename und Reihenfolge je App; „Auf Standard zurücksetzen". |
| **4/5 Kategorien** | Liste + Formular (Anlegen/Bearbeiten/Löschen). |
| **6/7 Externe Links** | Liste + Formular (Anlegen/Bearbeiten/Löschen). |
| **8/9 Icon-Bibliothek** | Vorschau-Kacheln + Upload/Bearbeiten/Löschen eigener Icons. |
| **10 Einstellungen** | Startseiten-Titel, Opt-out-Schalter, „Sonstige anzeigen"; plus Übersicht aller Config-Werte. |

Alle Schreibaktionen laufen als **Dynamic Action → `executeServerSideCode`** über die
`PCK_HOM_*`-DML-Pakete (kein direktes DML in den Seiten).

## Installation

1. **Datenbankseite** — als die Schema-Eigentümer-Verbindung, die mit dem Ziel-Workspace
   verknüpft ist (aus `sql/`):
   ```sql
   @install.sql
   ```
2. **APEX-App** — aus dem Repo-Root, mit derselben Verbindung:
   ```bash
   apex validate -input apex_toolkit
   apex import   -input apex_toolkit
   ```
   Alternativ im App Builder: den Ordner zippen und importieren.
3. **Beispieldaten** (optional):
   ```sql
   @apex_toolkit/setup.sql
   ```

### Als Instanz-Startseite setzen

ORAHomer ist eine normale APEX-App. Damit sie als Landing-Page dient, in der jeweiligen
Umgebung den Einstiegspunkt auf diese App (App-ID **1200**, Alias `HOME`) zeigen lassen —
z. B. per Lesezeichen `f?p=1200`, über einen Reverse-Proxy/Redirect der Instanz-Wurzel, oder
indem die anderen Apps in ihrer Navigationsleiste auf `f?p=1200` verlinken.

## Hinweise zum Format (aus dem APEX-26.1-Export gelernt)

- Die **App-ID steht in `apex_toolkit/deployments/default.json`** (`app.id` = 1200), nicht in
  `application.apx`. APEX reserviert 3000–8999 und 40000–49999 — außerhalb bleiben und
  Kollisionen im Ziel-Workspace vermeiden.
- `.apex/apexlang.json` `mmdVersion` muss zur Instanz passen (`26.1.0+3102`).
- Inhaltsregionen auf `@/standard`-Seiten nutzen `slot: body`.
- App-Icons liegen als Static Application Files (`icons/app-icon-*.png`) und damit in
  `APEX_APPLICATION_STATIC_FILES` — von dort holt ORAHomer das Auto-Icon.

## Verifikation

Es gibt in der Entwicklungsumgebung keine laufende Oracle-/APEX-Instanz; die SQL- und
APEXLang-Artefakte sind geschrieben, aber **nicht zur Laufzeit getestet**. Vor dem Einsatz
auf einer echten Instanz mit `apex validate -input apex_toolkit` prüfen und `@install.sql`
ausführen.

## Lizenz

MIT — siehe [LICENSE](LICENSE).
