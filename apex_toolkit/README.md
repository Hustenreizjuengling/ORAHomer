# ORAHomer — APEX-App (APEXLang / APEX 26.1)

Die deklarative Definition der ORAHomer-Startseite als **APEXLang**-Anwendung (`.apx`),
auf demselben Exportformat aufgebaut wie der KMLeon-Toolkit, damit Format/Version exakt zu
APEX 26.1 passen. Liegt im Repo unter `apex_toolkit/`.

## Struktur

```
apex_toolkit/
  .apex/apexlang.json          mmdVersion (muss zur Instanz passen: 26.1.0+3102)
  application.apx              App ORAHOMER (Name, Navigation, Theme, Auth, Sprache de)
  deployments/default.json     App-ID = 1200  (hier, nicht in application.apx)
  page-groups.apx              Seitengruppe "Administration"
  pages/                       p1 Startseite … p10 Einstellungen, p0 Global, p9999 Login
  shared-components/           Navigation (lists.apx), Auth, Theme, Static Files, …
  setup.sql                    Beispieldaten (Kategorien + ein externer Link)
```

## Seiten

- **1 Startseite** — eine `dynamicContent`-Region; `plsqlFunctionBody` gibt
  `pck_hom_api.render_home` zurück: serverseitig gebautes HTML, **nach Kategorien gruppiert**
  (Überschrift je Kategorie, darunter die Kacheln). Jede Kachel ist ein klickbarer
  `<a class="hom-card">` (Icon links, Name + Beschreibung rechts); das Icon ist als
  **Data-URI** eingebettet. Styling über eigene `hom-*`-Klassen + UT-CSS-Variablen mit
  Fallbacks (kein UT-Interna-Override). Reihenfolge ist datengetrieben
  (`HOM_CATEGORIES.display_seq` und Kachel-`display_seq`) — kein On-Page-Filter.
- **2 Apps verwalten** — IR über `HOM_APP_CONFIG_V`; Link-Spalte setzt `P3_APPLICATION_ID`
  und öffnet Seite 3.
- **3 App-Konfiguration** — Items für Kategorie/Icon/Sichtbarkeit/Anzeigename/Reihenfolge.
  `Load`-Process (Before Header) lädt die bestehende Konfiguration; **Speichern** ruft
  `PCK_HOM_APP_CONFIG_DML.save` (DA `executeServerSideCode` + commit) und navigiert per
  `executeJsCode`/`apex.navigation.redirect` zurück; **Zurücksetzen** ruft `…reset`.
- **4/5 Kategorien, 6/7 Links** — jeweils IR + Formular nach demselben Muster (Before-Header-
  Load, DA-Save/Delete über das DML-Paket, `clearCache` beim Anlegen).
- **8/9 Icon-Bibliothek** — `Cards`-Vorschau über `HOM_ICONS` (BLOB-Media; Edit-Link via
  `apex_page.get_url`) + Formular mit `imageUpload`. Speichern liest die Datei aus
  `APEX_APPLICATION_TEMP_FILES` und übergibt den BLOB an `PCK_HOM_ICONS_DML.save`.
- **10 Einstellungen** — `HOM_CONFIG`-Werte (Titel, Opt-out-Schalter, „Sonstige anzeigen")
  über `PCK_HOM_CONFIG_DML`, plus IR über alle Config-Zeilen.

## Wichtige Format-Fakten

- **App-ID** in `deployments/default.json` (`app.id` = 1200), **nicht** in `application.apx`.
- `.apex/apexlang.json` `mmdVersion` = `26.1.0+3102` (muss mit der Instanz übereinstimmen).
- Inhaltsregionen auf `@/standard` nutzen `slot: body`.
- Die Cards-DSL hat **keinen** Link-/Action-Block und **keinen** Per-Row-Wechsel zwischen
  Bild und Font-Icon — deshalb rendern Kacheln immer ein **BLOB-Bild** (hochgeladen,
  Auto-App-Icon oder generierter SVG-Badge), und der Klick steckt im Titel-`htmlExpression`.
- Schreibende DAs nutzen `action: executeServerSideCode` und committen selbst; clientseitige
  Navigation nutzt `action: executeJsCode` mit `settings { jsCode: … }`.

## Installieren

```bash
# aus dem Repo-Root, verbunden als die Schema-Eigentümer-Verbindung des Ziel-Workspace
apex validate -input apex_toolkit
apex import   -input apex_toolkit
```

Voraussetzung: Die Datenbankobjekte sind installiert (`sql/install.sql`). Danach optional
`@apex_toolkit/setup.sql` für Beispieldaten.
