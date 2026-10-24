# APOLLO — Missione Scuola

Un piccolo viaggio, una grande avventura. Prototipo 3D offline per Windows, con un furgone bianco dettagliato, guida arcade e interfaccia italiana.

La specifica originale è `redme.txt`. Sono implementati il prototipo, la cittadina cartoon, due gite nei parchi e la **versione narrativa della Missione Scuola e la rifinitura locale della Fase 6**, su dati pubblici OpenStreetMap e fonti comunali. La Fase 2 conserva una verifica aperta sull'accesso scolastico definitivo. Lo stato aggiornato del lavoro è in [PROJECT_STATUS.md](PROJECT_STATUS.md).

## Avvio su questo computer

**Casa di Apollo e partenza dal cortile — 24 ottobre 2026:** su questo PC è attiva la configurazione locale della casa mostrata dall'utente. Casa arancione con abbaino, scala esterna, balcone, palma e cancellata a due ante; il cancello si apre automaticamente quando Apollo si avvicina. **Esplora Volpiano** e **Missione Scuola** partono dal cortile; R riposiziona Apollo lì. [Casa e cancello](build/verifica/casa-apollo-cancello.png), [partenza](build/verifica/casa-apollo-partenza.png). Incrocio di riferimento indicato dall'utente; distanze, sagoma e posizione del varco restano una prima stima dalla foto. Il collegamento alla strada usa un raccordo privato in memoria e prosegue sul grafo OSM.

Posizione, civico e impronta da sostituire sono in `local/home_departure.json`, escluso dal versionamento insieme agli altri dati personali locali. Senza questo file si conserva la partenza pubblica. Test dedicato: `--headless --fixed-fps 60 --script tests/home_departure_test.gd`; test completi e catture con la configurazione locale: aggiungere `-- --with-home` ai comandi per `tests/volpiano_test.gd`, `tests/story_test.gd`, `tests/town_test.gd` e `tests/home_capture.gd`. I test senza tale opzione conservano i dati pubblici riproducibili.

**Via Trento dalle foto dell'utente — 24 ottobre 2026:** prima ricostruzione del tratto attorno al ponticello, con parapetti verdi, marciapiedi rosati, muretti e cancelli, zoccoli in pietra, tapparelle, balconi continui, facciate di altezze diverse, lampioni e auto ferme. [Ponte e strada](build/verifica/trento-foto-ponte-nord.png), [palazzina e fronti verso sud](build/verifica/trento-foto-palazzina-sud.png). Le posizioni delle singole facciate sono ancora interpretative; [fonti e limiti](data/map/TOWN_REFERENCES.md#seconda-revisione-del-24-ottobre-2026--foto-di-via-trento). Riavviare il gioco e scegliere **Esplora Volpiano → Si parte!**; il ponticello si trova su Via Trento a sud della partenza.

Revisione del **24 ottobre 2026 — Volpiano e Via Trento**: la mappa comprende tutti i tratti di Via Trento presenti nell'estratto OSM, con un margine di 65 m; i segmenti che attraversano il bordo vengono ritagliati senza sparire. Le strade escluse dalla guida conservano ora la carreggiata asfaltata. Volpiano usa intonaci, coperture e luce meno saturi, ingressi rettangolari, meno ornamenti e vetrine solo sugli edifici classificati commerciali. Rimossi i dissuasori distribuiti automaticamente lungo tutta la rotta. Riavviare il gioco e scegliere **Esplora Volpiano → Si parte!**. [Anteprima della guida](build/verifica/stile-guida-dopo.png), [Via Trento intera](build/verifica/stile-via-trento-intera-dopo.png). Street View non è stato consultabile perché nella sessione non è disponibile un browser: le facciate rimangono procedurali, da confrontare con fotografie. [Dettagli e limiti](data/map/TOWN_REFERENCES.md#revisione-del-24-ottobre-2026).

Revisione del **20 ottobre 2026 — posteriore X250**: ricostruiti portelloni H2 con giunti e nervature, invaso targa nella lamiera, maniglia, stemma rosso FIAT e scritta DUCATO. Fanali con settori rossi/trasparenti e due riflettori per lato; entrambi gli stop e il terzo stop seguono la frenata. [Vista posteriore dritta](build/verifica/apollo-realistico-retro-dritto.png) e [dettaglio](build/verifica/apollo-realistico-retro-dettaglio.png), disponibili anche in OpenGL. Riavviare il gioco per caricare il modello aggiornato. Riferimenti e limiti in [REFERENCES.md](data/vehicles/REFERENCES.md).

Revisione del **18 ottobre 2026**: Apollo usa ora una base 3D dettagliata con carrozzeria e cabina modellate, vernice lucida, plastiche con grana fine, vetri riflettenti, sedili, cruscotto, cerchi e pneumatici con battistrada. Base **2014 Fiat Ducato di razor24, CC BY 4.0**, adattata alle proporzioni L2H2 e con muso X250 ricostruito; [attribuzione e licenza](assets/vehicles/CREDITS.md). Fari con lenti, riflettori e lampadine distinti, tergicristalli e luci di frenata funzionanti. **Apollo da vicino** offre tre viste con illuminazione neutra. Anteprime in `build/verifica/apollo-realistico-*.png`, riproducibili con `--script tests/vehicle_capture.gd`, anche in OpenGL. È un adattamento più realistico, con limiti geometrici rispetto a una scansione o a un modello CAD del 2010.

L'ultima rifinitura ricostruisce l'anteriore X250: fascia bianca attorno alla griglia a quattro lamelle, cofano con aperture vere per i fari, riflettori parabolici orientati in avanti dentro vasche profonde e paraurti con prese e fendinebbia incassati. Vista frontale: `build/verifica/apollo-realistico-frontale.png`; dettaglio: `apollo-realistico-ottiche.png`. Sono disponibili anche catture a luce bassa con fari spenti/accesi.

La città adotta ora una direzione più sobria: cielo azzurro grigio, luce neutra, facciate crema e sabbia, persiane e ingressi rettangolari. Per esplorarla scegliere **Esplora Volpiano → Si parte!**. Catture urbane riproducibili con `--script tests/graphics_capture.gd`.

Il controllo dedicato `--headless --script tests/vehicle_detail_test.gd` verifica normali, orientamento delle superfici, accensione di entrambe le ottiche, rotolamento e sterzo. Le bordure e i dissuasori sono dettagli visivi senza nuove collisioni.

**Facciate e atmosfera:** aggiunti portoni ad arco con pannelli, cornici in pietra, cantonali, dentelli sotto i cornicioni, vetrate con variazioni di tono e tende, insegne circolari e tende inclinate sulle vetrine. Gli ornamenti più ricchi si concentrano entro 55 m dal percorso; piccoli piazzali pavimentati occupano gli spazi disponibili davanti agli edifici. Palette più terracotta, cielo più turchese e luce meno intensa. Dettaglio: `build/verifica/stile-facciate-dopo.png`. Se il gioco è già aperto, chiuderlo e riavviarlo per caricare la revisione.

Fare doppio clic su **`Avvia Apollo.cmd`**, quindi scegliere **Si parte!**. Il motore portatile è già in `.tools/godot/` e non richiede installazione. Il gioco funziona senza rete.

Per la nuova mappa scegliere **Esplora Volpiano**, poi **Si parte!**: seguire i punti dorati da Via Trento a Via Brandizzo e fermarsi sul cerchio verde. Il tragitto è lungo circa 455 metri. Dal menu si può tornare al circuito di prova. Questa è un'esplorazione: il punto di partenza privato e l'accesso scolastico definitivo non sono ancora attivati. Fonti, licenza, limiti e configurazione locale sono in [data/map/SOURCES.md](data/map/SOURCES.md).

La città ora comprende facciate colorate, persiane, balconi, tetti in terracotta, alberi, lampioni, panchine, fioriere, auto parcheggiate, targhe stradali e attraversamenti. Chiesa dei Santi Pietro e Paolo, municipio e plesso di Via Trieste mantengono le rispettive impronte OSM; sono visibili esplorando anche fuori dalla traccia dorata. Le facciate sono interpretazioni cartoon. I due semafori presenti mostrano ambra fissa: nella Missione Scuola un impianto usa invece una logica di gioco rosso/verde. Vedere [riferimenti della Fase 3](data/map/TOWN_REFERENCES.md).

Per la Fase 4 scegliere **Le gite nei parchi → Madonna delle Grazie oppure San Grato → Si parte!**. Il viaggio rapido porta a un breve avvicinamento stradale: seguire i punti e fermarsi sul cerchio con Spazio. Si apre **La Stella Perduta**: leggere l'indizio e scegliere dove cercare. Ogni parco assegna una stella e sblocca l'adesivo **Apollo Esploratore**. La raccolta viene salvata su disco, anche passando da un ambiente all'altro o chiudendo il gioco. Apollo resta fuori dal recinto; l'attività usa una vista del parco, senza guida fra i giochi. Per fonti, posizioni approssimate e tre parchi ancora da verificare, vedere [PARK_REFERENCES.md](data/map/PARK_REFERENCES.md).

Per la Fase 5 scegliere **Storia e missioni → Missione Scuola → Si parte!**. Leggere l'introduzione con **Avanti**, guidare sui punti dorati, raccogliere fino a tre stelle, fermarsi un secondo al rosso e parcheggiare nel cerchio finale. L'epilogo racconta l'ultima parte a piedi e mostra la scuola. Completandolo si sblocca **Il Parcheggio Perfetto**, con tre soste e una seconda medaglia. È una versione racconto con partenza pubblica e sosta illustrativa su Via Brandizzo; non simula ancora il tragitto privato o l'ingresso carrabile definitivo. Personaggi, configurazione locale, dialoghi, fonti e verifiche in [STORY_NOTES.md](STORY_NOTES.md).

In alternativa, aprire Godot 4.6.1 Standard, importare `project.godot` e premere **F6** con `scenes/main/main.tscn` aperta, oppure **F5** per avviare il progetto.

Su un altro computer scaricare [Godot 4.6.1 stabile per Windows](https://godotengine.org/download/archive/4.6.1-stable/), estrarre l'archivio, aprire il motore e importare `project.godot`. `.tools/` è un supporto locale escluso dal versionamento. Il file `.cmd` cerca anche il comando `godot` nel PATH. L'eseguibile autonomo distribuibile appartiene alla Fase 7.

## Fase 6: Apollo, impostazioni e raccolta

Apollo rappresenta un **Fiat Ducato X250 del 2010, 2.2 MultiJet 100 PS / 74 kW, codice 4HV, Euro 4, passo medio e tetto alto (L2H2)**. La base 3D attribuita sopra è adattata a passo 3,45 m e altezza 2,524 m, con frontale ricostruito e collider 2,05 × 2,524 × 5,413 m. Il menu **Apollo da vicino** mostra anteriore, fianco e posteriore; versione, fonti e limiti in [data/vehicles/REFERENCES.md](data/vehicles/REFERENCES.md). La guida rimane arcade e i due occupanti stilizzati.

**Impostazioni**, dal menu o dalla pausa, regola musica, effetti/motore, reattività della camera, modalità tranquilla (36 km/h), movimenti ridotti e ombre. **Salva e torna** conserva i valori; anche la chiusura della finestra li salva. Movimenti ridotti attenua la rotazione della camera, evita la panoramica dell'epilogo e ferma le animazioni dei giochi. I menu restano utilizzabili con mouse, Tab/frecce e Invio o focus del controller; il controller fisico deve ancora essere provato.

Musica leggera, motore con intonazione legata alla velocità, frenata, clacson, uccellini, interazioni e completamento sono sintetizzati localmente. Non sono registrazioni del motore 4HV. **Collezione** mostra record delle stelle dei viaggi, parchi e medaglie. I record non diminuiscono rigiocando; la partita riparte con le stelle della missione a zero.

Salvataggio: `user://apollo_save.json`, normalmente `%APPDATA%/Godot/app_userdata/APOLLO – Missione Scuola/` su Windows. Conserva impostazioni, parchi, stelle dei viaggi, medaglie e missioni sbloccate; non salva la posizione del furgone. Scrittura temporanea e rinomina, copia precedente `.bak`, recupero dei file invalidi e valori controllati. Un documento danneggiato viene conservato in `.corrupt` alla successiva scrittura. Nessun dato personale o coordinata privata viene inserito. I test Godot in `tests/` usano uno stato isolato dai salvataggi dell'utente.

Verifiche della Fase 6:

```powershell
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script tests/phase6_test.gd
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script tests/save_process_test.gd -- --write-fixture
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script tests/save_process_test.gd
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --path . --script tests/phase6_capture.gd
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --path . --script tests/performance_capture.gd
```

Il primo comando verifica 29 condizioni; i due successivi controllano il passaggio dei dati fra processi distinti. Il quarto cattura menu, impostazioni, collezione, furgone e cabina. Il benchmark usa il renderer reale a 1920×1080, MSAA 4×, ombre attive, VSync e limite FPS disabilitati, 90 frame di riscaldamento e 240 misurati per scena. Attraversa le tappe della città spostando il veicolo: è uno screening grafico breve, non una sessione manuale o una certificazione del PC minimo. Risultati in `build/verifica/performance.json`; dettagli in [PERFORMANCE.md](PERFORMANCE.md).

## Come giocare

Seguire il circuito verso sinistra alla partenza, raggiungere gli archi **1 → 2 → 3 → 4**, poi fermarsi sotto l'ultimo arco per un secondo. Non ci sono tempo limite, danni o sconfitte. Si può uscire dalla strada per fare pratica e riposizionare Apollo in qualsiasi momento.

| Azione | Tastiera | Controller (layout Xbox) |
| --- | --- | --- |
| Accelera | W / ↑ | A |
| Frena e passa alla retro | S / ↓ | B |
| Sterza | A, D / ←, → | Stick sinistro / croce direzionale |
| Frena fino all'arresto | Spazio | X |
| Riposiziona alla partenza | R | Y |
| Pausa / continua | Esc | Start |
| Fari | L | RB |
| Clacson | H | LB |
| Cambia visuale | C | Pressione stick destro |
| Distanza telecamera | Pag↑ / Pag↓ | — |

La mappatura viene registrata da `scripts/utilities/controls.gd` all'avvio; non serve aggiungere azioni a mano nell'editor. Nei menu si possono usare mouse, Tab/frecce e Invio; Godot gestisce anche il focus da controller.

## Scelte e struttura

Versione fissata: **Godot 4.6.1 stable**, GDScript, renderer **Forward+ (Vulkan)** con ripiego automatico a **Compatibility/OpenGL 3.3** sui PC senza Vulkan/D3D12 (`rendering_device/fallback_to_opengl3`), viewport 1920×1080 scalato e finestra iniziale 1280×720. Forward+ abilita SSAO, SSIL, ombre morbide e riflessi; con OpenGL questi effetti vengono ignorati senza errori. Per forzare OpenGL: `--rendering-method gl_compatibility`. È una versione stabile specifica e riproducibile; non si dipende automaticamente dall'ultima release. Non servono .NET o pacchetti esterni.

`CharacterBody3D` gestisce gravità e collisioni con `move_and_slide()`. Accelerazione, decelerazione e sterzo sono espliciti: comportamento prevedibile e ripristino immediato, adatti al prototipo per bambini. Velocità massima 54 km/h, retro 18 km/h, sterzo attenuato all'aumentare della velocità. `SpringArm3D` accorcia la telecamera davanti agli ostacoli, escludendo il collider del furgone.

Gerarchia principale generata da `scripts/gameplay/main.gd`:

```text
Main (Node3D, scenes/main/main.tscn)
├── Atmosfera (WorldEnvironment, scripts/environment/atmosphere.gd)
├── Sole (DirectionalLight3D)
├── CircuitoProva (Node3D, scripts/environment/test_world.gd)
├── Apollo (CharacterBody3D, scenes/vehicles/apollo.tscn)
│   ├── CollisionShape3D
│   └── Visual (Node3D, scripts/vehicles/apollo_visual.gd)
├── Node3D (scripts/vehicles/follow_camera.gd)
│   └── SpringArm3D
│       └── Camera3D
├── ProvaGuida (Node, scripts/gameplay/practice_mission.gd)
├── CanvasLayer (scripts/ui/hud.gd)
└── Node (scripts/utilities/audio.gd)
```

Le primitive sono in `scripts/utilities/geometry.gd`; materiali condivisi in `scripts/utilities/materials.gd`, mesh low-poly (chiome, coni, auto, stelle) in `scripts/utilities/meshes.gd` e shader originali in `assets/shaders/` (cielo con Alpi, prato e campi, asfalto, marciapiedi, intonaco, coppi, fogliame al vento, colonna d'arrivo, sfondo sfocato dei menu, vignettatura). La base GLB del Ducato è inclusa in `assets/vehicles/`, con crediti e licenza; gli shader e le altre geometrie sono procedurali. L'impostazione **Grafica avanzata** attiva SSAO, SSIL, ombre morbide e quattro suddivisioni d'ombra; **Movimenti ridotti** ferma anche vento, pulsazioni e sbuffi. Il modello Visual si può sostituire mantenendo `animate(delta, speed, steering, braking, headlights)`; il controller non dipende dalle mesh. Le scene `.tscn` contengono il punto d'ingresso e il veicolo con collider, mentre gli altri nodi sono generati dai rispettivi moduli. Non ci sono risorse mancanti da cercare o importare.

I salvataggi sono gestiti da `scripts/utilities/save_store.gd` nella cartella Godot `user://`. Gli indirizzi privati devono stare in `local/`, esclusa dal versionamento; non inserirli nei dati distribuiti.

La mappa risiede in `data/map/volpiano.json`; `tools/import_osm.py` importa e converte OSM, `scripts/environment/volpiano_world.gd` genera l'ambiente e `scripts/gameplay/route_mission.gd` gestisce le tappe geografiche. `town_style.gd` genera facciate, monumenti e arredi; `town_batch.gd` raggruppa le primitive ripetute con MultiMesh per forma e materiale, con colore per istanza. Strade, marciapiedi, segnaletica, muri e tetti (a padiglione o con falde perimetrali e terrazzo) sono unificati in poche mesh; i muri hanno un unico collider concavo. Le impronte edilizie sono reali, mentre altezze, colori e bordi stradali sono stilizzati. Il percorso segue gli archi diretti OSM; non viene ricalcolato se si esce dalla traccia.

## Verifica riproducibile

Da PowerShell nella cartella del progetto:

```powershell
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --editor --import --quit
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script tests/smoke_test.gd
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --path . --script tests/visual_capture.gd
python tests/map_test.py
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script tests/volpiano_test.gd
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script tests/town_test.gd
python tests/park_data_test.py
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script tests/parks_test.gd
python tests/story_data_test.py
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script tests/story_test.gd
```

Il secondo comando esegue 18 verifiche con fisica reale e input sintetici: terreno, ruote, accelerazione, frenata, retro, sterzo, limite, ostacolo, recupero, reset, inseguimento, collisione telecamera, pausa visibile e fisica, ripresa, completamento e riavvio. Per verificare gli stati missione il test sposta il mezzo sulle tappe: non è una prova automatica di guida dell'intero circuito. Il terzo comando apre temporaneamente una finestra e salva menu e guida in `build/verifica/` con il renderer reale.

I sette test Python verificano proiezione, accessi, sensi unici, restrizioni, continuità del percorso e corrispondenza dei dettagli alla fonte OSM. `volpiano_test.gd` percorre ogni segmento con accelerazione e fisica, orientando automaticamente Apollo all'inizio di ciascun segmento: verifica la percorribilità, non la qualità dello sterzo manuale. Senza `--headless` salva anche le catture `volpiano.png` e `volpiano-menu.png`.

`town_test.gd` controlla generazione cittadina, tre luoghi pubblici, segnaletica, arredi e raggruppamento delle mesh. Eseguirlo senza `--headless` per salvare `fase3-guida.png`, `fase3-panorama.png`, `fase3-chiesa.png`, `fase3-municipio.png` e `fase3-scuola.png` in `build/verifica/`. Le catture non costituiscono un benchmark.

I cinque test `park_data_test.py` verificano catalogo e dati geografici. `parks_test.gd` esegue 29 controlli su entrambe le gite: percorrenza fisica, recinto, arresto, ricerca, ricompense senza duplicati, replay e cambio ambiente. Per catture rapide della Fase 4 usare il motore senza `--headless`, aggiungendo `-- --visual-only`: questa modalità prepara la sosta direttamente e salva le immagini `fase4-*` in `build/verifica/`.

La storia aggiunge tre test Python e 49 controlli Godot, compreso un giro fisico sui 26 segmenti del racconto, con orientamento automatico alle giunzioni. Per le catture rapide della cabina e dei dialoghi eseguire con renderer reale `--script tests/story_capture.gd`. Nomi e colori dei due personaggi si possono configurare con `local/family.json`, come documentato nelle note della storia.

Checklist manuale: completare un giro guidando, controllare il senso di sterzata in retro, provare fari e clacson, riposizionare in movimento, variare telecamera, mettere in pausa e ricominciare. Provare un controller fisico e ripetere il benchmark sul PC di destinazione prima di dichiarare compatibilità hardware completa.

## Problemi e soluzioni

- **Godot non trovato:** aprire `project.godot` dal motore 4.6.1, oppure ripristinare la cartella portatile indicata sopra.
- **Finestra nera / errore OpenGL:** aggiornare i driver video e verificare il supporto OpenGL 3.3; il progetto usa già Compatibility.
- **Apollo non si muove:** premere Si parte!, chiudere la pausa e fare clic sulla finestra di gioco. R ripristina il mezzo.
- **Non si completa il giro:** attraversare le tappe nell'ordine indicato e fermarsi sotto l'arco 4 con Spazio.
- **Clacson non udibile:** verificare volume e dispositivo audio di Windows; l'audio è volutamente delicato.

Vedere [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md), [CHANGELOG.md](CHANGELOG.md) e [ASSET_CREDITS.md](ASSET_CREDITS.md) per fasi, modifiche e licenze.
