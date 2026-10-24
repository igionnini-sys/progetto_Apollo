# Volpiano — estratto geografico di sviluppo

Scaricato il 17 ottobre 2026 tramite Overpass API. Timestamp banca dati: **2026-10-17T05:27:19Z**. Bounding box: sud 45.185, ovest 7.758, nord 45.211, est 7.788. La query esatta e la conversione riproducibile sono in `tools/import_osm.py`.

**© OpenStreetMap contributors**, [copyright e licenza](https://www.openstreetmap.org/copyright), [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/). `volpiano.json` è una banca dati derivata: mantenere attribuzione e licenza e, in caso di distribuzione pubblica, renderla disponibile secondo ODbL. I dati originali completi rimangono in `local/volpiano.osm.json`; il file distribuibile omette indirizzi, civici e tag personali.

## Conversione e percorso

Origine 45.198 N, 7.773 E; proiezione equirettangolare locale con raggio terrestre 6.371.000 m. X est, Z sud; scala 1 unità Godot = 1 metro. Terreno piano, larghezza stradale convenzionale 6–7 m, bordi pedonali illustrativi. Edifici estrusi dalle impronte OSM con altezza stilizzata variabile, usando i piani mappati quando presenti. Non sono ricostruzioni delle facciate reali. Ponti e livelli non sono ancora modellati in quota; il grafo collega esclusivamente nodi OSM condivisi, senza intersezioni geometriche inventate. Dettagli della Fase 3 e secondo estratto in [TOWN_REFERENCES.md](TOWN_REFERENCES.md).

L'estratto contiene 592 vie, 1958 nodi stradali accessibili e 3525 archi diretti. Il percorso pubblico di esplorazione parte da un nodo di Via Trento e raggiunge Via Brandizzo attraverso Corso Regina Margherita, per circa 455 m. Non rappresenta la partenza privata né l'arrivo scolastico definitivo. Il gioco mostra il diorama entro 160 m dal rettangolo del percorso; l'intero estratto resta disponibile per espansioni.

La ricerca Dijkstra usa segmenti reali e rispetta `oneway=yes`, `oneway=-1`, rotatorie e precedenza dei tag `motorcar`, `motor_vehicle`, `vehicle`, `access`. Esclude accessi privati, destinazione, condizionali e direzioni reversibili. Le vie coinvolte in relazioni di divieto di svolta sono escluse integralmente: scelta conservativa che riduce la connettività, da sostituire con gestione delle singole svolte. Documentazione: [oneway](https://wiki.openstreetmap.org/wiki/Key:oneway), [access](https://wiki.openstreetmap.org/wiki/Key:access), [Overpass](https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide).

La guida mostra punti e tappe sul percorso già calcolato; non ricalcola la rotta fuori percorso. Le esclusioni valgono per la navigazione: non sono barriere fisiche che impediscono al giocatore di imboccare una via.

## Scuola e accesso: verifica ancora aperta

- [Istituto Comprensivo: Guglielmo da Volpiano](https://www.icvolpiano.edu.it/luogo/scuola-primaria-guglielmo-da-volpiano/): conferma Via Trieste 1.
- [Relazione tecnica comunale](https://www.comune.volpiano.to.it/it-it/download/relazione-tecnica-illustrativa-42933-2-1209-58ec93f0ca352f412d7fb9ea9a6b658b): descrive l'ingresso principale su Via Trieste e un'uscita sul lato Via Brandizzo. Documento storico, non prova dell'accessibilità odierna in automobile.
- [Segnalazione comunale 37/2026, 10 febbraio 2026](https://www.comune.volpiano.to.it/it-it/servizi-online/segnalazioni/37-10-02-2026-25777-1-e2af2b00d1923dd61dfcd8c7fedfd5fe): richiama divieti durante ingresso e uscita scolastici. È una segnalazione, non l'ordinanza che ne definisce tratto e orari.

Per prudenza Via Trieste è esclusa dal grafo guidabile. Occorre verificare ordinanza vigente, tratto, orari, ingresso corretto e punto di sosta consentito prima di attivare Missione Scuola. Non è dichiarata conclusa la Fase 2.

Aggiornamento della Fase 5: individuato l'avviso comunale del 2022 che descrive il tratto scolastico soggetto a divieti; non equivale alla verifica definitiva della disciplina attuale. È ora giocabile una **versione racconto** che si ferma su Via Brandizzo e narra il seguito a piedi. Percorso, nuova fonte e limiti in [STORY_NOTES.md](../../STORY_NOTES.md). La missione privata definitiva resta subordinata alla verifica della Fase 2.

## Riproduzione

`python tools/import_osm.py` rigenera il JSON dall'estratto locale senza rete. `python tools/import_osm.py --download` aggiorna l'estratto via rete; verificare nuovamente fonti, percorso e timestamp dopo ogni aggiornamento. Il gioco non usa la rete.

Per personalizzare la partenza creare `local/map_config.json` con `origin: [lat, lon]`, `scale: 1.0` ed eventualmente `spawn_lat_lon: [lat, lon]`, quindi eseguire `python tools/import_osm.py --config local/map_config.json`. Viene prodotto esclusivamente `local/volpiano.private.json`, caricato automaticamente se presente. La partenza viene agganciata al nodo accessibile più vicino entro 30 m: verificare manualmente la scelta. L'arrivo rimane quello esplorativo. Rimuovere il file privato per tornare al percorso pubblico; escludere tutta `local/` da ogni distribuzione.
