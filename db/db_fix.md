# BOOKS adatbázis javítási terv

Ez a dokumentum a `~/work/sql/dbeaver/book/Scripts` könyvtár 00-21 közötti SQL scriptjeinek átvizsgálása alapján készült.

A jelenlegi SQL-készletet PostgreSQL adatbázishoz tervezték, de ebben az állapotban nem telepíthető megbízhatóan. A legfontosabb problémák:

- a DDL több helyen nem PostgreSQL-kompatibilis;
- több tárolt program nem fordul le vagy hibás változókat használ;
- az integritási szabályok hiányosak;
- nincsenek explicit teljesítményindexek;
- a soft delete, a fizikai törlés és a jogosultsági modell nincs egységesítve;
- a telepítési script fejlesztői resetként működik, nem biztonságos migrációként.

A javítást nem egyetlen nagy SQL-fájlon, hanem több, ellenőrizhető migrációs lépésben kell elvégezni.

## 1. PostgreSQL adattípusok helyreállítása

### Probléma

A scriptek tömegesen használják a `BIGINT UNSIGNED` típust. Ez MySQL-szintaxis, PostgreSQL-ben nem létező adattípus.

Érintett példák:

- `01.book-createschema.sql`
- valamennyi 02-21 közötti karbantartó script
- a függvények paraméterei és visszatérési típusai
- a composite type-ok mezői

### Hatás

A schema script már az első `CREATE TABLE` utasításoknál leáll. A további hibák jelentős része csak következményként jelenik meg, mert az érintett táblák és függvények létre sem jönnek.

### Javítási terv

Egységesen PostgreSQL-kompatibilis típust kell választani.

Javasolt PostgreSQL oldali reprezentáció:

```sql
id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

Az ID értékét a Snowflake-generátor adja. A PostgreSQL-ben tárolt és továbbadott
érték mindenhol `BIGINT` legyen; UUID-alternatíva nincs.

## 2. Snowflake-ID mint kizárólagos ID-stratégia

### Probléma

A rendszer jelenleg többféle ID-stratégiát kever:

- alkalmazás által generált Snowflake-ID-t;
- UUID-t;
- PostgreSQL `oid` értékeket auditmezőként.

A legtöbb tábla bigint ID-t használ, a `docseries` korábban UUID-t használt.

### Hatás

A kapcsolódó táblák nem azonos típusú ID-ket használnak. Például a `docseries.id` UUID, miközben a `docseries_title.series_id` bigint. Ez foreign key létrehozási hibát okoz és az API-szerződéseket is bizonytalanná teszi.

### Javítási terv

A BOOKS adatbázisban kizárólag Snowflake-ID használható üzleti elsődleges
kulcsként. UUID nem maradhat sem primary key-ként, sem foreign key-ként, sem
function/procedure paraméterként vagy visszatérési típusként.

A PostgreSQL oldali típus:

```sql
id bigint NOT NULL PRIMARY KEY
```

Az ID-t Snowflake-generátor állítja elő. A generátor lehet az alkalmazásban
vagy adatbázis-függvényben, de minden táblának ugyanazt a numerikus,
időrendben növekvő Snowflake-ID szerződést kell használnia.

Minden primary key, foreign key, composite type mező, function-paraméter,
procedure `INOUT` paraméter és function `RETURNS` típus `BIGINT` legyen.
UUID-generálásra, `uuid-ossp` vagy `pgcrypto` extensionre nincs szükség.

A Snowflake-generátor szerződését külön rögzíteni kell:

- legyen definiált epoch és timestamp-felbontás;
- a machine/worker ID tartománya legyen korlátozott és konfigurált;
- a sequence-rész párhuzamos generáláskor se adjon azonos ID-t;
- az óra visszaállását kezelni kell, vagy monotonic clock/worker fencing szükséges;
- az ID túlcsordulását és a timestamp-mező maximális élettartamát dokumentálni kell;
- a generátor ugyanazt a bitkiosztást használja minden alkalmazásban és migrációban.

Az adatbázis ne generáljon más formátumú ID-t, mint amit az alkalmazás Snowflake-
generátora előállít. A `BIGINT` csak a tárolási típus; az egyediség és az
információt hordozó időbeli jelentés a Snowflake-generátor felelőssége.

## 3. `country_code` duplikált `id` oszlopának javítása

### Probléma

A `01.book-createschema.sql` fájlban a `country_code` tábla kétszer deklarálja az `id` oszlopot és kétszer a primary key-t.

### Hatás

A tábla létrehozása azonnal hibával leáll. Emiatt a `person` tábla nationality foreign key-je és a hozzá tartozó view sem jön létre.

### Javítási terv

A második `id` deklarációt törölni kell. A táblának pontosan egy primary key-je legyen.

A javítás után tiszta adatbázison újra kell futtatni a schema migrációt, mert a korábbi sikertelen futtatás részleges objektumokat hagyhatott maga után.

## 4. UUID-előfordulások eltávolítása

### Probléma

UUID-előfordulás van a kommentelt alternatív DDL-ben, a `docseries.id`
definícióban, a `language_code` karbantartó programokban és a keyword
karbantartó functionben.

### Hatás

A jelenlegi UUID-részek megsértik az egységes Snowflake-ID szerződést, és a
`docseries` esetében a bigint foreign key-kel is ütköznek.

### Javítási terv

Az összes UUID deklarációt `BIGINT` Snowflake-ID-ra kell cserélni. A
`docseries.id` és a `docseries_title.series_id` azonos `BIGINT` típusú legyen.
Az `uuid_generate_v4()` alapértelmezést el kell távolítani, az ID-t a
Snowflake-generátor adja.

## 5. Hibás function- és procedure-típusok egységesítése

### Probléma

A `language_code.id` Snowflake-ID, mégis a karbantartó procedure és az
ID-visszaadó function UUID-t használ:

- `02.book.language_code_maint.sql:40`
- `02.book.language_code_maint.sql:108`

Hasonló típuskeveredés található a keyword karbantartásban is.

### Hatás

A functionök nem fordulnak le, illetve a procedure-kimenet nem egyezik a
táblából visszaadott Snowflake-ID típusával.

### Javítási terv

Minden karbantartó modulhoz készíteni kell egy egyszerű szerződést:

| Objektum | ID típusa | Procedure INOUT | Function RETURNS |
|---|---|---|---|
| `language_code` | `bigint` Snowflake-ID | `bigint` | `bigint` |
| `country_code` | `bigint` Snowflake-ID | `bigint` | `bigint` |
| `doc` | `bigint` Snowflake-ID | `bigint` | `bigint` |

A `COMMENT ON FUNCTION` és `DROP FUNCTION` signature-okat is `BIGINT` típusra
kell módosítani.

## 6. A `doc_maint` tárolt programok javítása

### Probléma

A `21.book.doc_maint.sql` összetett procedure-jeiben több hibás vagy nem deklarált hivatkozás van:

- `_isbn` nincs deklarálva;
- `_issueseries_id` nincs deklarálva;
- `new_array` nincs deklarálva;
- az author procedure hívása hibás paramétersorrendű;
- a keyword és issue műveletekhez `doc_genre_id` kerül átadásra;
- a text input típus mezőnevei nem egyeznek a feldolgozó kóddal.

### Hatás

A procedure nem fordul le, és a részletes dokumentummentés akkor sem lenne helyes, ha a típusproblémák már javítva lennének.

### Javítási terv

A részletes dokumentummentést külön lépésekre kell bontani:

1. `doc` törzs létrehozása vagy módosítása.
2. Címek mentése.
3. Műfajok mentése.
4. Szerzők mentése.
5. Kulcsszavak mentése.
6. Kiadásokhoz kapcsolás.
7. Azonosító visszaadása.

Minden részlépéshez külön, fordítható tesztet kell készíteni. A text-alapú wrapper először oldja fel a masteradatokat, majd egy belső, típusos procedure-t hívjon.

A részletes procedure-be nem kerülhetnek más domainhez tartozó, nem deklarált változók.

## 7. A `person_select` dátumfeltételének javítása

### Probléma

A `13.book.person_maint.sql` fájlban ez szerepel:

```sql
CASE WHEN (_born IS null) THEN TRUE ELSE _born=_born END
```

Az `_born = _born` mindig igaz, így a születési dátum szűrése nem működik.

### Hatás

A keresés olyan személyeket is visszaad, akiknek a `born` mezője nem egyezik a keresett értékkel. Ez a count-then-maintain logikát is hibás eredményhez vezetheti.

### Javítási terv

A feltétel helyesen:

```sql
CASE WHEN _born IS NULL THEN TRUE ELSE born = _born END
```

Ugyanezt a mintát minden paraméteres select functionben ellenőrizni kell. Célszerű a `CASE` helyett ezt használni:

```sql
(_born IS NULL OR born = _born)
```

## 8. Hibás személytörlés javítása

### Probléma

A `13.book.person_maint.sql` fizikai törlési ágában a személy ID helyett `_nickname_id` szerepel.

### Hatás

A törlés hibás rekordot célozhat, vagy nem töröl semmit. Ez különösen veszélyes, mert a törlés adminisztratív művelet.

### Javítási terv

A törlés azonosítója legyen `_person_id`. Ezzel együtt a fizikai törlés és soft delete jelentését külön kell választani, lásd a 10. pontot.

## 9. Soft delete és hard delete egységesítése

### Probléma

A procedure-kben a `'d'` mód néhol soft delete-ként van kommentelve, de valódi `DELETE` utasítást hajt végre. Más helyeken `deleted = true` történik.

### Hatás

Az alkalmazás nem tudhatja megbízhatóan, hogy a `'d'` művelet visszaállítható-e. A kapcsolódó adatok és auditadatok elveszhetnek.

### Javítási terv

Egységes szerződés:

- `'d'`: soft delete, `deleted = true`;
- `'r'`: fizikai törlés, csak külön adminisztratív jogosultsággal;
- `'u'`: módosítás;
- `'i'`: létrehozás;
- ismeretlen mód: exception.

A fizikai törlést lehetőleg külön admin procedure-be kell szervezni, nem az általános runtime karbantartó procedure részeként.

## 10. Hibás jogosultság-ellenőrzés javítása

### Probléma

Több script ilyen feltételt használ:

```sql
has_schema_privilege(session_user, 'public', 'create')
```

Ez a `public` schema `CREATE` jogosultságát ellenőrzi, nem az adott `book` objektum tulajdonosát vagy adminisztrátori jogosultságát.

### Hatás

A fizikai törlés jogosultsága nem a megfelelő biztonsági határhoz kötődik. A feltétel félreérthető és könnyen hibás hozzáférési modellt eredményez.

### Javítási terv

A runtime `_app` role ne kapjon közvetlen table jogosultságot. Az alkalmazás csak explicit function/procedure interfészeket hívjon.

Adminisztratív törléshez:

- külön migration/admin role;
- explicit `GRANT EXECUTE`;
- szükség esetén `SECURITY DEFINER`;
- rögzített `search_path`;
- auditált művelet.

A `public` schema jogosultságát ne használják adminisztrációs kapcsolóként.

## 11. Hibakezelés javítása

### Probléma

Több összetett procedure ilyen mintát tartalmaz:

```sql
EXCEPTION WHEN OTHERS THEN ROLLBACK;
```

### Hatás

A hiba elnyelődik, így az alkalmazás nem feltétlenül kap hibát. Részleges adatfeldolgozás után a művelet látszólag sikeresnek tűnhet.

### Javítási terv

A hibát tovább kell dobni:

```sql
EXCEPTION WHEN OTHERS THEN
    RAISE;
```

Ha logolás szükséges, előbb rögzíteni kell a `SQLSTATE` és `SQLERRM` értéket, majd újra kell dobni a hibát.

## 12. Tranzakciókezelés áttervezése

### Probléma

Procedure-k belsejében `COMMIT` és `ROLLBACK` szerepel.

### Hatás

Ezek csak meghatározott PostgreSQL hívási helyzetekben használhatók. Ha az alkalmazás Go tranzakción belül hívja a procedure-t, a hívás hibázhat.

### Javítási terv

Az alsó szintű karbantartó functionök és procedure-k ne commitoljanak. A tranzakció határát:

- az alkalmazás;
- vagy egyetlen felső szintű orchestration procedure

kezelje.

Az összetett dokumentummentés atomikusan fusson, de a tranzakció vezérlése ne legyen több egymásba ágyazott modulban.

## 13. Count-then-insert race condition megszüntetése

### Probléma

Sok karbantartó modul ezt a mintát használja:

1. rekordok megszámolása;
2. ha nulla, insert;
3. ha egy, ID visszaadása;
4. ha több, hiba.

### Hatás

Párhuzamos hívások során két session ugyanazt az adatot is beszúrhatja. A count nem véd a konkurens insert ellen.

### Javítási terv

A megoldás:

1. üzleti kulcsra unique vagy partial unique index;
2. `INSERT ... ON CONFLICT`;
3. szükség esetén azonosító visszaadása `RETURNING` segítségével.

Példa:

```sql
INSERT INTO book.genre (genre_name, created, creator)
VALUES (_genre_name, now(), current_user)
ON CONFLICT (genre_name) DO UPDATE
SET genre_name = EXCLUDED.genre_name
RETURNING id;
```

## 14. Kapcsolótáblák egyediségének biztosítása

### Probléma

A kapcsolótáblákban nincs mindenhol olyan összetett unique constraint, amely megakadályozná ugyanannak a kapcsolatnak a többszöri rögzítését.

Érintett példák:

- `doc_genre`;
- `doc_author`;
- `doc_keyword`;
- `doc_title`;
- `issue_doc`;
- `issue_issueseries`;
- `issue_copy`.

### Hatás

Ugyanaz a műfaj, szerző, kulcsszó, cím vagy kiadás többször is kapcsolható ugyanahhoz az objektumhoz.

### Javítási terv

Soft delete esetén részleges unique indexek szükségesek, például:

```sql
CREATE UNIQUE INDEX uq_doc_genre_active
ON book.doc_genre (doc_id, genre_id)
WHERE deleted = false;
```

A szerzőknél a nickname szerepeltetését is bele kell venni az üzleti kulcsbe, ha ugyanaz a személy több szerepben jelenhet meg.

## 15. `CHECK` constraint-ek bevezetése

### Probléma

A schema szinte egyáltalán nem használ deklaratív `CHECK` constraint-eket.

### Hatás

Az adatbázis olyan adatokat is elfogad, amelyeket az üzleti modell valószínűleg nem engedne meg.

### Javítási terv

Legalább az alábbi szabályokat kell adatbázis-szinten rögzíteni:

- szövegmezők ne legyenek csak whitespace karakterek;
- `died >= born`, ha mindkettő megadott;
- évszám ésszerű tartományban legyen;
- ISBN formátuma legyen ellenőrzött;
- title ne legyen üres;
- kapcsolótábla ID-i ne legyenek azonosak vagy NULL-ok az üzleti szabály szerint;
- példánynak kötelezően legyen kiadása és tárolási helye.

## 16. Foreign key indexek létrehozása

### Probléma

A fő láncban 34 foreign key található, de explicit `CREATE INDEX` utasítás nincs.

### Hatás

A kapcsolt lekérdezések, törlések és frissítések nagy adatmennyiségnél lassúak lesznek. A foreign key önmagában nem hoz létre automatikusan indexet a hivatkozó oldalon.

### Javítási terv

Legalább az alábbi oszlopokat kell indexelni:

- `person_nickname.person_id`;
- `book_storage.store_id`;
- `doc_genre.doc_id`, `doc_genre.genre_id`;
- `doc_author.doc_id`, `doc_author.person_id`, `doc_author.author_type_id`;
- `doc_keyword.doc_id`, `doc_keyword.keyword_id`;
- `doc_title.doc_id`;
- `issue_doc.issue_id`, `issue_doc.doc_id`;
- `issue_copy.issue_id`, `issue_copy.storage_id`;
- `issue_issueseries.issue_id`, `issue_issueseries.series_id`.

Soft delete esetén a legtöbb indexet `WHERE deleted = false` feltétellel kell megvizsgálni.

## 17. Unique és soft delete stratégia összehangolása

### Probléma

A normál unique constraint a törölt rekordokra is érvényes marad. Például egy soft deleted `genre` neve nem használható újra.

### Hatás

A törlés után az újra létrehozás hibával leáll, vagy az alkalmazás kénytelen a régi rekordot visszaállítani nem dokumentált módon.

### Javítási terv

Ha a név újra felhasználható:

1. a normál unique constraint helyett partial unique index;
2. `WHERE deleted = false`;
3. az ID-get-or-insert logika a nem törölt rekordokra korlátozva.

Ha a név globálisan történelmi szempontból egyedi, ezt dokumentálni kell, és a jelenlegi működés elfogadhatóvá válik.

## 18. `oid` auditmezők kiváltása

### Probléma

A táblákban `creator oid` és `modifier oid` mezők vannak.

### Hatás

A PostgreSQL role OID belső technikai azonosító. Role-export/import vagy role-törlés után nem stabil üzleti hivatkozás.

### Javítási terv

Lehetséges megoldások:

- `creator_name text NOT NULL` és `modifier_name text`;
- külön alkalmazási felhasználótábla Snowflake-ID primary key-jel;
- PostgreSQL role csak technikai auditként, nem üzleti kapcsolatként.

A runtime és migration role-ok különválasztása mellett az alkalmazási felhasználókat nem célszerű közvetlenül PostgreSQL role-ként modellezni.

## 19. `SELECT *` view-k kiváltása

### Probléma

A `v_*` view-k jellemzően `SELECT *` formájúak.

### Hatás

A tábla oszlopainak változása implicit módon megváltoztatja az interfész eredményét. Ez runtime és API-kompatibilitási hibákat okozhat.

### Javítási terv

A view-k explicit oszloplistát használjanak:

```sql
CREATE VIEW book.v_doc AS
SELECT id, language_id, lang_origin_id, year_origin, note
FROM book.doc
WHERE deleted = false;
```

A view legyen stabil adatbázis-interfész, ne a belső tábla automatikus másolata.

## 20. A DBeaver `@include` kiváltása migrációs futtatással

### Probléma

A `00.run_all.sql` DBeaver-specifikus `@include` direktívákat használ.

### Hatás

A script nem futtatható közvetlenül `psql`-ből vagy Goose-ból. CI/CD környezetben és új gépen nehezen reprodukálható.

### Javítási terv

A javasolt struktúra:

```text
db/
  migrations/
    0001_create_schema.sql
    0002_create_masterdata.sql
    0003_create_people.sql
    0004_create_documents.sql
    0005_create_interfaces.sql
    0006_add_indexes.sql
```

A DBeaver maradhat SQL kliens, de a hivatalos telepítési út legyen Goose vagy egy verziózott `psql` runner.

## 21. A destruktív reset és a migráció szétválasztása

### Probléma

A schema script elején szerepel:

```sql
DROP SCHEMA IF EXISTS book CASCADE;
```

### Hatás

A teljes `book` schema és minden objektuma törlődik. Ez nem biztonságos újrafuttatható telepítéshez vagy fejlesztői adatbázison kívüli környezetben.

### Javítási terv

Külön fájlok legyenek:

- `reset_dev.sql`: destruktív, csak helyi fejlesztéshez;
- `install_schema.sql`: csak létrehozás;
- `migration_*.sql`: verziózott, nem destruktív módosítás;
- `verify.sql`: katalógus-alapú ellenőrzés.

A production migrációkban ne legyen `DROP SCHEMA ... CASCADE`.

## 22. A `CREATE TABLE IF NOT EXISTS` és `DROP TABLE` ellentmondása

### Probléma

Több helyen egymás után szerepel:

```sql
DROP TABLE IF EXISTS ...;
CREATE TABLE IF NOT EXISTS ...;
```

### Hatás

Az `IF NOT EXISTS` megtévesztő, mert az előző `DROP` után a tábla várhatóan nem létezik. A script nem valódi idempotens migration.

### Javítási terv

- reset scriptben használható a `DROP`,
- migrationben ne legyen destruktív reset,
- az objektum létrehozása legyen verziózott és tudatos,
- újrafuttathatóságot migration framework kezelje.

## 23. A tárolt program API egyszerűsítése

### Probléma

Minden entitáshoz külön select, count, maint, get-or-insert és get-by-id program tartozik. Az API-k sok helyen azonos mintát ismételnek, és egyetlen `char` paraméterrel vezérlik a CRUD módot.

### Hatás

- nagy mennyiségű ismétlődő SQL;
- nehezen tesztelhető ágak;
- félreérthető `'d'`, `'r'`, `'x'` módok;
- nehéz jogosultság- és hibakezelés;
- sok lehetőség signature- és paraméterhibára.

### Javítási terv

A tényleges adatbázis-interfészeket domainműveletenként kell kialakítani:

```text
get_document
search_document
create_document
update_document
archive_document
link_author
link_genre
link_keyword
```

Nem szükséges minden egyszerű SELECT-hez procedure. A view-k jók olvasási interfésznek, function/procedure csak ott kell, ahol tranzakciós vagy integritási előnyt ad.

## 24. Biztonsági modell hozzáigazítása az alkalmazás interfészéhez

### Probléma

A view-k és functionök használata jó irány, de a jelenlegi scriptek nem állítanak be explicit PostgreSQL jogosultsági modellt.

### Hatás

A runtime user könnyen közvetlen table hozzáférést kaphat, vagy a SECURITY INVOKER alapértelmezés miatt nem tudja használni az interface-eket.

### Javítási terv

A korábban kialakított bootstrap-modellt kell alkalmazni:

- `book_owner`: NOLOGIN, migration/schema owner;
- `book_app`: LOGIN, runtime;
- `book_app` ne kapjon közvetlen table DML jogot;
- explicit `GRANT SELECT` a stabil view-kre;
- explicit `GRANT EXECUTE` a kijelölt function/procedure-kre;
- default privilege-ek ne adjanak automatikus CRUD-ot;
- szükség esetén `SECURITY DEFINER`, rögzített `search_path` és owner audit.

## 25. Alapadatok betöltési sorrendje

### Probléma

A masterdata, személyek, címek és dokumentumok több külön fájlban vannak. A `00.run_all.sql` nem minden extra initial-data fájlt tartalmaz.

### Hatás

A telepítés részleges adatbázissal fejeződhet be, vagy foreign key hiba keletkezhet, ha egy későbbi adatfügg egy be nem töltött masteradattól.

### Javítási terv

Dokumentált sorrend:

1. extension és schema;
2. törzs- és lookup táblák;
3. masterdata;
4. személyek;
5. művek és címek;
6. kiadások;
7. kapcsolótáblák;
8. view-k és interface functionök;
9. indexek;
10. jogosultságok;
11. katalógus-alapú ellenőrzések.

Minden seed script legyen idempotens, például természetes kulcsra épülő `ON CONFLICT` logikával.

## 26. Tesztelési terv

A javítás nem zárható le pusztán azzal, hogy a DBeaver nem jelez hibát.

Szükséges ellenőrzések:

### Szintaktikai teszt

Tiszta PostgreSQL adatbázison:

```bash
psql --set ON_ERROR_STOP=1 -f migration.sql
```

A teljes lánc első hibánál álljon le.

### Sémateszt

Ellenőrizni kell:

- minden várt tábla létezik;
- minden foreign key valid;
- minden index létrejött;
- nincs UUID/bigint típusütközés;
- nincs függő, létre nem jött view vagy function.

### Tárolt program teszt

Minden function/procedure esetén legalább:

- sikeres insert;
- meglévő rekord kezelése;
- update;
- soft delete;
- admin hard delete;
- hibás paraméter;
- párhuzamos hívás;
- rollback hiba esetén.

### Jogosultsági teszt

A runtime role:

- tudja használni az engedélyezett view-ket;
- tudja hívni az engedélyezett functionöket;
- nem tud közvetlenül táblát olvasni vagy módosítani;
- nem tud `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE` műveletet végezni;
- nem fér hozzá más belső táblákhoz.

## Ajánlott végrehajtási sorrend

1. Döntés az ID-stratégiáról.
2. PostgreSQL-kompatibilis DDL elkészítése.
3. `country_code`, `docseries` és UUID problémák javítása.
4. Foreign key és unique szabályok felülvizsgálata.
5. CHECK constraint-ek hozzáadása.
6. Tárolt programok fordítási hibáinak javítása.
7. `doc_maint` és `person_maint` logikai hibáinak javítása.
8. Soft delete és fizikai törlés egységesítése.
9. `ON CONFLICT` alapú karbantartási műveletek.
10. Indexek létrehozása.
11. View-k explicit oszloplistára alakítása.
12. Goose/psql migrációs struktúra kialakítása.
13. Bootstrap jogosultságok beállítása.
14. Tiszta adatbázison teljes integrációs teszt.
15. Runtime least-privilege teszt.

## Végső értékelés

A modell üzleti alapjai használhatók egy Házikönyvtár alkalmazáshoz: jól felismerhető benne a mű, kiadás, fizikai példány, személy, szerző, cím, műfaj és kulcsszó fogalma.

A jelenlegi megvalósítás azonban még prototípus. A legfontosabb feladat a fordítható, PostgreSQL-kompatibilis és konzisztens alap létrehozása. Csak ezután érdemes teljesítményhangolással vagy további stored procedure-ökkel foglalkozni.
