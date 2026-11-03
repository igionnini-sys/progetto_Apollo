# Fase 5 — storia e missioni

## Avvio e contenuto

**Aggiornamento del 24 ottobre 2026 — partenza domestica locale:** se è presente e attivo `local/home_departure.json`, il viaggio inizia dal cortile della casa indicata dall'utente. Il cancello si apre automaticamente; dopo l'uscita si segue Via Trento fino alla rotta narrativa esistente. Civico, posizione e sostituzione dell'impronta restano nel file locale. Sul PC di sviluppo il viaggio comprende 35 segmenti; superati 58 controlli fisici e narrativi con `tests/story_test.gd -- --with-home`. La sosta scolastica e i suoi limiti non cambiano. I dati e le distanze pubbliche descritti sotto si riferiscono alla versione senza configurazione personale.

Dal menu scegliere **Storia e missioni → Missione Scuola → Si parte!**. Leggere le tre battute con **Avanti**; l'ultima conferma fa partire la guida. Mouse, Tab/frecce e Invio oppure il focus UI del controller comandano gli stessi pulsanti.

Il racconto percorre circa **669 m su 26 segmenti OSM** dalla partenza pubblica di Via Trento a una sosta narrativa su Via Brandizzo. Durante la guida sono disponibili tre stelle facoltative. Al semaforo rosso occorre arrestarsi vicino al punto guida per un secondo; il verde consente di proseguire. Non sono previsti tempo limite o penalità irreversibili. Se si supera il punto, si può tornare indietro o ricominciare.

L'arresto finale apre un epilogo con vista animata del plesso scolastico: il tratto conclusivo a piedi viene raccontato, senza simulare la camminata. Terminati i dialoghi, si ricevono il messaggio “MISSIONE COMPIUTA!”, il conteggio delle stelle e la medaglia **Compagni di viaggio**. Si sblocca **Il Parcheggio Perfetto**: stesso percorso, due soste intermedie e una finale, oltre alla sosta al semaforo, con medaglia **Pilota gentile**. Non viene valutata l'orientazione precisa del mezzo: è una sfida introduttiva per bambini.

Dalla Fase 6 medaglie, sblocco e record delle stelle vengono salvati su disco in `user://`. Le stelle della missione si azzerano rigiocando, mentre il record conserva il massimo ottenuto; non sono necessarie per completare la storia. Le stelle dei parchi appartengono alla raccolta separata, anch'essa persistente. La posizione e la tappa corrente non sono salvate.

## Limite geografico della versione racconto

Il punto di partenza non identifica l'abitazione privata. La sosta finale è un obiettivo illustrativo su un nodo di Via Trieste, a circa 30 m in linea d'aria dal punto mappa scolastico; **non è un posto auto censito né un ingresso carrabile verificato**. Il passaggio narrativo a piedi non certifica un percorso pedonale o un cancello utilizzabile oggi.

Il [Comune, avviso del 9 settembre 2022](https://www.comune.volpiano.to.it/it-it/novita/avvisi/2022/viabilita/modifiche-alla-viabilita-negli-orari-di-entrata-e-uscita-scolastica-251675-1-20c1a67f082208876179e82838539976), descrive divieti scolastici su Via Trieste fra Via Brandizzo e Via Fiume e sul piazzale della sala polivalente, nelle fasce 8–9, 12–13 e 16–17, con deroghe. Il documento aiuta a delimitare la ricerca, ma non basta a certificare accessi e sosta attuali. Resta aperta la verifica della Fase 2 prima del tragitto definitivo dalla partenza privata.

`data/map/story_route.json` conserva `preview=true` e `school_vehicle_access_verified=false`. `python tools/build_story_route.py` rigenera il percorso dal grafo pubblico, usando archi accessibili e senza modificare i dati OSM. Il percorso è Via Trento → Via Pasubio → Via Novara a destra → sottopasso → tutta Via Trieste (SP3) fino alla scuola primaria; Via Trieste ora è percorribile nel grafo. Il semaforo è una regola di gioco sul nodo OSM **921141638** (incrocio con Via Fiume), non un impianto censito. Arresto richiesto, colori e tempi sono regole di gioco, non riproduzioni dell'impianto reale.

## Personaggi configurabili

Nonno e nipotina sono moduli seduti separati con viso, capelli, abiti e cinture diagonali e addominali. La cabina è stata adattata per renderli visibili. Il controller del veicolo conserva la stessa interfaccia `animate()` e non dipende dalla geometria dei personaggi.

Impostazioni predefinite in `data/characters/family.json`. Per personalizzare senza modificare i dati distribuiti creare facoltativamente `local/family.json`:

```json
{
  "grandfather": {"name": "Nonno", "skin": "efd0ad", "hair": "d7d9d1", "shirt": "688c9d"},
  "granddaughter": {"name": "Nipotina", "skin": "efd0ad", "hair": "795b48", "shirt": "d58f9f"}
}
```

Sono accettati anche aggiornamenti parziali. Nomi vuoti e colori invalidi mantengono i valori predefiniti; i nomi sono limitati a 24 caratteri. Riavviare il gioco o caricare un altro ambiente per applicare la configurazione. Le forme restano cartoon generiche: non vengono dedotti tratti personali da fotografie non fornite.

## Moduli e gerarchia

```text
Main — scripts/gameplay/main.gd
├── VolpianoOSM — scripts/environment/volpiano_world.gd
│   └── Semaforo narrativo — scripts/environment/story_traffic_light.gd
├── Apollo / Visual — scripts/vehicles/apollo_visual.gd
│   ├── Nonno — scripts/characters/seated_passenger.gd
│   └── Nipotina — scripts/characters/seated_passenger.gd
├── ProvaGuida — scripts/gameplay/story_mission.gd in modalità storia
│   └── Tre stelle — scripts/gameplay/story_star.gd
├── Dialoghi — scripts/gameplay/dialogue_player.gd
├── Camera narrativa temporanea
└── HUD — scripts/ui/hud.gd
```

`family_profile.gd` carica e valida la configurazione; `data/dialogue/school.json` contiene battute italiane, interlocutori ed eventi. La macchina degli stati distingue menu, introduzione, guida, epilogo e completamento. Il mezzo non può muoversi durante i dialoghi; riavviare ricrea stelle e soste, ripristina il rosso e cancella gli eventi già mostrati nel viaggio.

## Verifica riproducibile

```powershell
python tests/story_data_test.py
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script tests/story_test.gd
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --path . --script tests/story_capture.gd
```

Tre test Python verificano continuità e accessibilità del percorso, origine OSM del semaforo e coerenza dei dialoghi. Il test Godot esegue **49 controlli**, percorrendo fisicamente i 26 segmenti e impostando la direzione alle giunzioni; verifica anche cinture, configurazione, pausa, semaforo, raccolta, epilogo, reset e sblocco. Per la sfida bonus prepara direttamente le soste: non è un secondo giro guidato automaticamente.

`story_capture.gd` cattura rapidamente menu, introduzione e selezione storie. Per catturare anche arrivo e completamento usare `story_test.gd` con renderer reale e `-- --visual-only`: questa modalità sposta il veicolo lungo i segmenti e non sostituisce il test fisico headless. Immagini in `build/verifica/fase5-*.png` esaminate con OpenGL Compatibility su RTX 4080. Non costituiscono un benchmark o una prova con controller fisico.
