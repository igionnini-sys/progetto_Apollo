# Fase 4 — parchi e prima attività facoltativa

Verifica delle fonti: 17 ottobre 2026. Catalogo offline in `parks.json`, fonti selezionate in `park_sources.json`, conversione riproducibile in `tools/import_parks.py`.

## Luoghi attivi

| Parco | Riferimento | Posizionamento e limiti |
| --- | --- | --- |
| Madonna delle Grazie | [Scheda comunale](https://www.comune.volpiano.to.it/it-it/vivere-il-comune/cosa-vedere/area-giochi-piazza-madonna-delle-grazie-23802-1-6c13d3e1a5604c456988a0fedf287c3b), piazza di fronte al civico 27; OSM way **375496621**, `leisure=playground`, accesso `yes` | L'allestimento si trova nel centroide dell'impronta OSM, circa **45.2003872, 7.7819301**. Il rettangolo illustrativo di 8×13 m rientra nel perimetro mappato; non si usa il pin comunale come centro geometrico, perché è vicino a un edificio della piazza. |
| San Grato | [Scheda comunale](https://www.comune.volpiano.to.it/it-it/vivere-il-comune/cosa-vedere/area-giochi-san-grato-23803-1-591faac194ac2357330ae2c7618db30b), Via San Grato 4; il Comune descrive altalene, scivoli e accesso dalla strada | Il centro resta sul pin comunale **45.1918597, 7.7734769**. Non è stato trovato un perimetro OSM associabile con certezza: ingombro, orientamento e disposizione dei giochi sono **approssimati**, adattati allo spazio libero rispetto alle strade e alle impronte edilizie. Non è una ricostruzione esatta del lotto. |

I parchi non sono spostati sulla rotta scolastica. Dal menu si seleziona una gita con viaggio rapido: viene caricato un diorama di 200×200 m nella rispettiva posizione geografica, con strade ed edifici estratti dalla mappa. Un breve avvicinamento percorre un arco stradale OSM accessibile. Non è ancora un itinerario continuo dal centro di Volpiano al parco.

Il cerchio di sosta è un obiettivo di gioco su un nodo stradale, **non un posto auto censito o una verifica della sosta consentita nella realtà**. La ricerca si svolge osservando il parco con una telecamera dedicata; Apollo rimane fermo fuori dal recinto. Non si guida tra i giochi e non è stato aggiunto un personaggio a piedi.

## Luoghi ancora da verificare

- [Alcide De Gasperi](https://www.comune.volpiano.to.it/it-it/vivere-il-comune/cosa-vedere/area-giochi-alcide-de-gasperi-23805-1-5c796ff1a899ae935e623c1076e6db56): la scheda descrive un'area di fronte alla Ghirotti, mentre il pin **45.2049154, 7.7756619** cade sull'impronta scolastica OSM. Non si sovrappone un parco alla scuola per compensare la discrepanza.
- [Sandro Pertini](https://www.comune.volpiano.to.it/it-it/vivere-il-comune/cosa-vedere/area-giochi-sandro-pertini-23804-1-8c6bbad94cd5e527206b7e42c4f83ec8): il pin **45.1944329, 7.7706178** è presso l'incrocio Via Padova/Via Canova; la scheda cita una recinzione, ma manca un'associazione certa al lotto.
- [Riviera](https://www.comune.volpiano.to.it/it-it/vivere-il-comune/cosa-vedere/area-giochi-riviera-27418-1-9fe8f60a0a35d99b1a3da5ca7194714c): il pin **45.2051456, 7.7850319** è vicino a impronte residenziali; un allestimento centrato sul punto si sovrapporrebbe alle case. La scheda segnala inoltre un recinto chiuso. Occorre verificare il perimetro prima di attivare la visita.

Le tre località restano nel catalogo di ricerca, senza pulsanti di visita. I nodi OSM anonimi nelle vicinanze non vengono automaticamente rinominati come questi parchi.

## Fonte OSM e riproduzione

Estratto parchi: **2026-10-17T05:47:51Z**, bounding box 45.18, 7.75, 45.22, 7.80; query `nwr[leisure~"^(park|playground)$"]`, con geometrie dipendenti. Originale in `local/volpiano.parks.osm.json`, escluso dalla distribuzione. Attribuzione **© OpenStreetMap contributors**, [copyright](https://www.openstreetmap.org/copyright), [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/). Il catalogo derivato conserva fonte, timestamp e attribuzione.

`python tools/import_parks.py` rigenera il catalogo senza rete; `--download` aggiorna l'estratto. Rieseguire i test e verificare nuovamente gli ingombri dopo ogni modifica dei dati. Il generatore usa la proiezione pubblica della mappa per calcolare gli avvicinamenti; il gioco riproietta i centri usando origine e scala della configurazione caricata.

## Modello e attività

`scripts/environment/playground.gd` genera altalena e dondolo animati, castello con scivolo, struttura per arrampicarsi, panchina, alberi, pavimentazione colorata e recinto con collisioni. Dotazioni, colori e proporzioni sono illustrativi, senza dichiarare che ogni attrezzatura esista attualmente in entrambi i parchi.

“La Stella Perduta” si apre dopo un secondo di arresto nella zona obiettivo. Tre pulsanti permettono di cercare vicino a scivolo, altalena o panchina, con un indizio e tentativi illimitati. La scelta corretta rivela una stella 3D e l'adesivo “Apollo Esploratore”. Una stella per parco, senza duplicazioni rigiocando. Raccolta e adesivo restano nella **partita corrente**, anche cambiando ambiente; si azzerano chiudendo il gioco. Il salvataggio su disco appartiene alla Fase 6.

Validazione: 5 test Python per catalogo, archi accessibili, perimetro e compatibilità con le impronte edilizie; 29 controlli Godot per guida fisica degli avvicinamenti, recinto, parcheggio, ricerca, premi, replay e menu. Le catture con `--visual-only` preparano direttamente la sosta e verificano la resa grafica; non sostituiscono il collaudo fisico headless.
