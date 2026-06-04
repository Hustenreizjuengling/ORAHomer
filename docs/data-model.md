# ORAHomer — Datenmodell

Alle Tabellen tragen den Präfix `HOM_`, werden ausschließlich über ihr DML-Paket
beschrieben und enden mit den Audit-Spalten `created_at / created_by / updated_at /
updated_by` (vom DML-Paket gestempelt, wenn `NULL` übergeben wird).

## Tabellen

### `HOM_LOG`
Zentrales Log, ausschließlich von `PCK_HOM_LOG` (autonome Transaktion) geschrieben.

| Spalte | Typ | Zweck |
|---|---|---|
| `log_id` | number (identity, PK) | |
| `log_level` | varchar2(10) | ERROR / WARN / INFO / DEBUG |
| `package_name`, `routine_name` | varchar2(128) | Herkunft |
| `message` | clob | Meldung |

### `HOM_CONFIG`
Typisierter Key/Value-Speicher (Einstellungen). Genau eine `value_*`-Spalte je Zeile,
gesteuert über `data_type`. Zugriff über `PCK_HOM_CONFIG_DML` (typisierte Getter/Setter).

Seed-Schlüssel: `HOME_TITLE`, `HOME_SUBTITLE`, `DEFAULT_APP_VISIBLE` (Opt-out-Schalter),
`SHOW_UNCATEGORISED`.

### `HOM_CATEGORIES`
Kategorien zur Gruppierung der Kacheln.

| Spalte | Typ | Zweck |
|---|---|---|
| `category_id` | number (identity, PK) | |
| `name` | varchar2(100), unique | Gruppen-/Badge-Label |
| `icon_css` | varchar2(100) | optionale Font-APEX-Klasse |
| `display_seq` | number | Sortierung der Kategorien |
| `is_active` | varchar2(1) Y/N | N blendet Kategorie + Kacheln aus |

### `HOM_ICONS`
Wiederverwendbare Icon-Bibliothek (hochgeladene Bilder als BLOB). Ein Bild kann beliebig
vielen Apps/Links zugewiesen werden.

| Spalte | Typ | Zweck |
|---|---|---|
| `icon_id` | number (identity, PK) | |
| `name` | varchar2(100), unique | Label in Auswahllisten |
| `file_name` | varchar2(255) | Originaldateiname |
| `mime_type` | varchar2(100) | z. B. image/png, image/svg+xml |
| `icon_blob` | blob | Bilddaten (Kachel-Media) |

### `HOM_APP_CONFIG`
Pro-App-Overrides. **PK = APEX-`application_id`.** Eine *fehlende* Zeile bedeutet „Standard"
(sichtbar, Auto-Icon, keine Kategorie) — daher ist die Startseite Opt-out.

| Spalte | Typ | Zweck |
|---|---|---|
| `application_id` | number (PK) | = `APEX_APPLICATIONS.application_id` |
| `category_id` | number → `HOM_CATEGORIES` | Gruppierung |
| `display_name` | varchar2(255) | überschreibt den App-Namen |
| `icon_id` | number → `HOM_ICONS` | ersetzt das erkannte App-Icon |
| `is_visible` | varchar2(1) Y/N | N versteckt die App |
| `display_seq` | number | Sortierung in der Kategorie |

### `HOM_LINKS`
Externe Link-Kacheln.

| Spalte | Typ | Zweck |
|---|---|---|
| `link_id` | number (identity, PK) | |
| `title` | varchar2(255) | Kacheltitel |
| `url` | varchar2(4000) | Ziel-URL |
| `description` | varchar2(400) | Untertitel |
| `category_id` | number → `HOM_CATEGORIES` | Gruppierung |
| `icon_id` | number → `HOM_ICONS` | Icon (sonst generierter Badge) |
| `open_in_new_tab` | varchar2(1) Y/N | Ziel `_blank` |
| `is_visible` | varchar2(1) Y/N | N versteckt den Link |
| `display_seq` | number | Sortierung in der Kategorie |

## Views

### `HOM_TILES_V`
Der Homepage-Feed: `APEX_APPLICATIONS` (⟕ `HOM_APP_CONFIG`) **∪** `HOM_LINKS`, angereichert
mit aufgelöstem `icon_blob` / `icon_mime` (über `PCK_HOM_API`) und Kategorie-Label/-Reihenfolge.
Sichtbarkeit, Kategorie-Aktivität und „Sonstige anzeigen" werden hier gefiltert. Schließt die
Homepage-App selbst (`nv('APP_ID')`) aus.

### `HOM_APP_CONFIG_V`
Admin-Liste: jede Workspace-App mit ihrer (optionalen) Konfiguration — effektiver Name,
Kategorie-/Icon-Name, effektive Sichtbarkeit, `is_customised`-Flag.

## Pakete

| Paket | Rolle |
|---|---|
| `PCK_HOM_LOG` | zentrales Logging + einziger Writer von `HOM_LOG` |
| `PCK_HOM_CONFIG_DML` | typisierter Key/Value-Zugriff auf `HOM_CONFIG` |
| `PCK_HOM_CATEGORIES_DML` | DML für `HOM_CATEGORIES` |
| `PCK_HOM_ICONS_DML` | DML für `HOM_ICONS` |
| `PCK_HOM_APP_CONFIG_DML` | DML für `HOM_APP_CONFIG` (+ `set_visibility`, `reset`) |
| `PCK_HOM_LINKS_DML` | DML für `HOM_LINKS` |
| `PCK_HOM_API` | Icon-Auflösung (`tile_icon_blob/mime`, `svg_badge`, `app_icon_blob`) + `app_url` |

## Installationsreihenfolge

Tabellen (`hom_log`, `hom_config`, `hom_categories`, `hom_icons`, `hom_app_config`,
`hom_links`) → Pakete (`log`, `config_dml`, `categories_dml`, `icons_dml`, `app_config_dml`,
`links_dml`, `api`) → Views → `init_defaults`. Genau diese Reihenfolge steht in
`sql/install.sql` (jede Referenz nutzt nur zuvor erstellte Objekte).
