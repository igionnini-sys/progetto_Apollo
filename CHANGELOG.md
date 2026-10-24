# Registro modifiche

## 24 ottobre 2026 — Casa e cancello di partenza

- Ricostruzione esterna dalla foto fornita dall'utente: intonaco arancione, persiane brune, balcone rialzato, scala con ringhiere, abbaino, pilastri in mattoni, recinzione e palma a ventaglio. Ante con apertura automatica e collisioni mobili.
- Partenza di esplorazione e storia dentro il cortile; reset nella stessa posizione. Collegamento privato in memoria alla Via Trento esistente, poi percorso su archi diretti OSM. Raggio ridotto per completare l'uscita prima di indicare la svolta. Parchi conservati.
- Posizione personale e civico in configurazione locale ignorata da Git. I dati pubblici OSM e i test senza configurazione personale conservano la partenza pubblica. La posizione dell'incrocio deriva dall'indicazione dell'utente; distanze e cancello restano stimati dalla foto.
- Verificati cancello chiuso/aperto con raycast, uscita fisica di Apollo, reset, viaggio completo, missione narrativa e città con partenza domestica. Anteprime riproducibili con `tests/home_capture.gd -- --with-home`.

## 24 ottobre 2026 — Primo tratto di Via Trento dalle foto dell'utente

- Usate le schermate Street View allegate come riferimento visivo per superfici, volumi e dettagli esterni. Otto profili locali separati dal catalogo OSM, con associazioni e misure dichiarate provvisorie.
- Parapetti verdi sul ponticello OSM, recinzioni e cancelli fuori dagli incroci, marciapiedi rosati, bordi bianchi, asfalto con crepe, chiusini e caditoie. Lampioni a braccio e segnali dosso/30 decorativi dalla vista di luglio 2025.
- Palazzine con tapparelle chiare e balconi continui, zoccoli in pietra, casa salmone e fabbricato rustico. Shader originali per pietra e tapparelle. Tre auto ferme con collisori sul margine della carreggiata; passaggio centrale verificato con guida fisica.
- Sei controlli dedicati, test città e percorso principale superati. Catture Vulkan e OpenGL riproducibili con `tests/trento_capture.gd`. Nessuna fotografia inclusa come texture; quota del ponte e terreno ancora semplificati.

## 24 ottobre 2026 — Via Trento completa e Volpiano più sobria

- Inclusi tutti i tratti importati di Via Trento nel diorama, con margine di 65 m. Clipping parametrico al bordo al posto dell'esclusione dei segmenti con estremi esterni; regressioni verificate con test dedicati.
- Dati di aspetto stradale separati dai permessi del grafo: Via Trieste e altre carreggiate escluse dalla rotta non diventano sentieri. Importati tipo stradale, larghezza, lato marciapiede, livelli, classificazione commerciale e copertura piana. Dati rigenerati offline dalla stessa fonte OSM.
- Palette di intonaci e coppi meno satura, ingressi rettangolari e cornici semplici. Rimossi negozi casuali, cantonali, dentelli e dissuasori sistematici; lampioni diurni senza lampadine luminose. Dettagli concentrati sul percorso e su Via Trento, volumi reali mantenuti sul resto della mappa ampliata.
- Luce, cielo, prato e nebbia più neutri a Volpiano. Atmosfera del circuito conservata. Anteprime riproducibili con `tests/graphics_capture.gd`, comprese panoramica di Via Trento e viste nella parte sud precedentemente tagliata.
- Test dati (8), città (12), percorso geografico con guida fisica, storia (49) e parchi superati. Panoramiche Street View non consultabili per assenza di un browser nella sessione; la fedeltà fotografica rimane da verificare. Nessuna immagine Google inclusa.

## 20 ottobre 2026 — Ricostruzione del posteriore X250

- Portelloni lastrati H2 separati geometricamente, con risvolti, giunti, nervature orizzontali e protezioni inferiori. Rimossi pannelli e dettagli posteriori sostituiti della base 2014, preservando fianchi, tetto e paraurti.
- Targa APOLLO da 520 × 110 mm nell'invaso della lamiera, modanatura luci targa, maniglia sagomata, stemma FIAT rosso e scritta DUCATO. Catadiottri del paraurti conservati come elementi passivi.
- Fanali verticali con zone rosse e trasparenti, due riflettori e prismi per lato; due stop laterali e terzo stop collegati alla frenata. Catture dritte, ravvicinate e in frenata, Vulkan e OpenGL. Controlli con raggi su giunto centrale, invaso targa e assenza di sovrapposizioni del fondo; test esistenti di geometria e Fase 6.

## 18 ottobre 2026 — Ricostruzione dell'anteriore X250

- Corrette le proporzioni del muso rispetto alla fotografia frontale: calandra più bassa con quattro lamelle in plastica sagomate, fascia bianca verniciata attorno all'apertura, presa inferiore sottile, emblema ridimensionato e targa da 520 × 110 mm con supporto e viti.
- Nuovo cofano con curvature e nervature leggere, prese d'aria e giunti. Aperture effettive nella lamiera per entrambe le ottiche, ricavate con clipping dei contorni; nessuna lamiera sotto i riflettori. Sede della fascia centrale aperta anche nel paraurti, eliminando sovrapposizioni e artefatti sui bordi.
- Fari più grandi con vasche profonde, maschere cromate, riflettori parabolici rivolti in avanti, flange e lampadine sotto la copertura trasparente. L'emissione interna dei riflettori segue il comando fari. Paraurti con sezioni interpolate, giunti delle tre parti, prese laterali e fendinebbia incassati; materiale meno azzurro.
- Superati 8 controlli di geometria/animazione e 29 della Fase 6. Il nuovo controllo usa raggi contro la mesh per verificare che la lamiera non occluda le sedi dei riflettori. Catture effettive Vulkan/OpenGL, compresa vista frontale e confronto a luce bassa con fari spenti/accesi. Backup in `build/backup/frontale-x250-20261018/`. Rimane una ricostruzione da fotografie, senza geometria CAD del produttore.

## 18 ottobre 2026 — Ducato più realistico

- Sostituita la precedente carrozzeria procedurale con la base *2014 Fiat Ducato* di razor24, CC BY 4.0. Scala, passo e tetto adattati a L2H2; muso del restyling rimosso e frontale X250 ricostruito con superfici continue, paraurti avvolgente, calandra, fendinebbia e tergicristalli.
- Ottiche incassate con guarnizioni, lenti trasparenti, riflettori concavi che seguono la carrozzeria, indicatori e lampadine separate. Fari, freni, rotazione delle ruote e sterzo collegati al controller esistente. Cabina della base con sedili, cruscotto e volante; occupanti conservati.
- Nuovi materiali PBR: vernice con clearcoat e sporco leggero inferiore, plastiche con grana e rugosità distinta, vetri non metallici, cerchi in metallo e battistrada che non richiede UV. Mesh adattate una sola volta e condivise dalle istanze; caricamento tramite ResourceLoader compatibile con il remapping degli export Godot.
- Vetrina con fondale neutro, illuminazione dedicata e riflessi da pannelli fotografici procedurali. Credito dell'autore e collegamento alla fonte nell'interfaccia; licenza e attribuzione incluse in `assets/vehicles/`.
- Catture dedicate con `tests/vehicle_capture.gd`. Test aggiornati per tetto curvo, pneumatico importato e fanali posteriori. Backup iniziale in `build/backup/ducato-realismo-20261018/`. Modello derivato con materiali più realistici, non una scansione o replica CAD del Ducato personale.
- Superati 66 controlli: guida (18), città (12), Fase 6 (29), geometria e animazioni (7). Catture effettive Vulkan e OpenGL esaminate, oltre alla vetrina e alla cabina; corretto l'auto-ombreggiamento del pavimento in OpenGL. Nessun nuovo benchmark FPS isolato.

## 18 ottobre 2026 — Facciate e atmosfera

- Palette più terracotta, cielo turchese più intenso, luce ambientale e solare riequilibrate, esposizione leggermente ridotta e foschia sulla distanza.
- 293 facciate decorate entro 55 m dai percorsi: portoni ad arco estrusi, pannelli, maniglie, cornici con chiavi e blocchi d'angolo, cantonali e dentelli sotto i cornicioni. Persiane alternate a finestre incorniciate per differenziare gli edifici.
- Vetrine in cinque colori, tende inclinate e insegne circolari. Corretto il criterio di scelta del colore: le vetrine verdi sono ora raggiungibili anche con la selezione degli edifici esistente. Nuovo shader opaco delle vetrate con riflessi stilizzati, variazioni di tono e tende, compatibile con Vulkan e OpenGL.
- 135 piazzali pavimentati nella mappa pubblica. Le impronte sono registrate integralmente prima della decorazione; le superfici sono visive e non aggiungono collider. Geometrie ad arco riutilizzate tramite MultiMesh: 18 gruppi e 231.954 istanze complessive.
- Ricerche delle strade vicine indicizzate su celle da 32 m, con ricerca completa per raggi maggiori di 4 m. Un controllo confronta gli esiti su 80 posizioni, compresi i confini delle celle. Superati 65 controlli complessivi (guida, città, Fase 6 e geometria/animazioni di Apollo).
- Catture di facciate, guida e Apollo con entrambi i renderer; importazione editor completata. Benchmark intermedio con due altre istanze di Godot aperte, registrato come non confrontabile. Backup in `build/backup/facciate-atmosfera-20261018/`.

## 18 ottobre 2026 — Apollo e dettaglio urbano

- Ricostruite le superfici di Apollo con normali continue: raccordi del tetto e della cabina, cofano e parabrezza curvi, fianchi inferiori rastremati con passaruota aperti, paraurti e specchietti arrotondati. Conservati Ducato X250 L2H2, quota tetto 2,524 m, passo 3,45 m, collider e due occupanti.
- Calandra con listelli e griglia, prese d'aria, fendinebbia decorativi, tergicristalli, maniglie e nervature. Due ottiche con riflettori e materiale condiviso: entrambe seguono il comando fari.
- Pneumatici torniti con spalle arrotondate e battistrada procedurale; cerchi con bordo, fori e bulloni. Rotazione delle quattro ruote e sterzo anteriore mantenuti. Passaruota raccolti in quattro mesh.
- Persiane a lamelle tramite shader, bordure in pietra con giunti e interruzioni agli incroci, 127 dissuasori verdi lungo il percorso pubblico. Bordure e paletti sono visivi e non aggiungono ostacoli fisici. 231.541 istanze cittadine in 15 MultiMesh.
- Aggiunti sei controlli su coordinate/normali, avvolgimento dei triangoli, verso del battistrada, fari e animazioni. Superati anche guida, città e Fase 6: 64 controlli complessivi. Catture di dettaglio con fari spenti/accesi, Vulkan e OpenGL senza errori di shader.
- Screening grafico 1080p su RTX 4080: 377,6 FPS mediani nel circuito e 112,5 a Volpiano. Report in `build/verifica/performance.json`; dettagli e limiti in `PERFORMANCE.md`. Backup della revisione precedente in `build/backup/modello-dettagliato-20261018/`.

## 18 ottobre 2026 — Stile ispirato al riferimento

- Cielo turchese con nuvole chiare, foschia ciano sulla distanza, sole caldo e ombre morbide; tonemapping ACES e minore bloom. Luce ambientale bilanciata per conservare il contrasto delle facciate.
- Palette terracotta, pesca e crema; muratura procedurale antialias sui colori caldi, attenuata a distanza. Marciapiedi in lastre rettangolari sfalsate, vetri azzurri, fasce tra i piani, grondaie e pluviali.
- Vetrine con cornici verdi, petrolio o rosso scuro e tende a righe sulle facciate rivolte alle strade. Dettagli raggruppati negli stessi 13 MultiMesh della città: 639 vetrine e 231.033 istanze complessive nella mappa pubblica.
- Corretto l'avvolgimento dei triangoli del circuito: asfalto e bordo pedonale ora visibili dall'alto. SSAO/SSIL attivati solo con Forward+, evitando avvisi nel ripiego OpenGL.
- Catture riproducibili tramite `tests/graphics_capture.gd`, salvataggi isolati in memoria. Verificata la resa con Vulkan e OpenGL; superati 18 controlli guida, 11 città e 29 Fase 6. Benchmark 1080p: 405,5 FPS mediani nel circuito e 94,9 a Volpiano su RTX 4080; dati e limiti in `PERFORMANCE.md`.
- Backup locale dei file precedenti in `build/backup/stile-riferimento-20261018/`. Prima revisione della direzione visiva; il livello di dettaglio dei modelli resta inferiore al riferimento.

## 17 ottobre 2026 — Rifinitura grafica

- Renderer passato a **Forward+** con ripiego automatico a OpenGL 3.3. Nuova atmosfera condivisa: cielo procedurale con nuvole, sole del mattino da est-sud-est, Alpi innevate stilizzate a nord-ovest e colline a sud, nebbia per profondità, tonemapping filmico, glow, SSAO e SSIL, ombre morbide a quattro suddivisioni.
- Shader originali senza texture per prato con fiorellini, campagna coltivata oltre il diorama, asfalto con rappezzi, marciapiedi in lastre, intonaco con ombra al piede e coppi in terracotta. Hash di rumore stabile sulle GPU, senza gradini.
- Volpiano ricostruita in poche mesh: strade con giunzioni arrotondate e mezzeria tratteggiata interrotta agli incroci, sentieri pedonali distinti, muri con colori piemontesi per edificio, tetti a padiglione sul lato lungo, falde perimetrali con terrazzo per le impronte irregolari, comignoli. Un solo collider concavo per i muri al posto dei 693 CSG.
- Facciate con persiane colorate per edificio, alcune chiuse, porte, cornici, ringhiere metalliche e vasi fioriti; alberi low-poly di tre tipi (chiome, cipressi, qualche tocco autunnale) con vento leggero; cespugli, ciuffi d'erba e fiori sparsi sul verde libero; auto cartoon colorate con vetri e fari; lampioni accesi; arcobaleno sul plesso di Via Trieste; frecce dorate a terra e colonna di luce sull'arrivo.
- Apollo con vernice lucida e trasparente, vetri riflettenti, cromature, fari e stop luminosi, sbuffi dallo scarico; volti dei personaggi più morbidi. Stelle sfaccettate luminose che fluttuano, semaforo con luci accese, giochi del parco in plastica lucida e colori vivaci.
- Interfaccia ridisegnata: pulsanti in rilievo, azione principale arancione, contorni di focus dorati, pannelli con ombra, titoli in grassetto, interruttori distinti, cursori arancioni, sfondo dei menu sfocato, scheda adattata al contenuto e vignettatura in guida. Vetrina di Apollo su pedana fra i cespugli, con ombre.
- Nuova impostazione salvata **Grafica avanzata**; campo visivo leggermente più ampio in velocità, disattivato con movimenti ridotti.
- Superate tutte le verifiche precedenti (160 controlli Godot, 15 test Python, riavvio fra processi). Benchmark 1080p su RTX 4080: 466 FPS mediani nel circuito e 156 a Volpiano, contro 355 e 123 con il renderer precedente.

## 17 ottobre 2026 — Correzione variante Apollo

- Recepita la correzione dell'utente: **passo medio e tetto alto, L2H2 / MH2**. Rialzati tetto, raccordi sopra la cabina, furgonatura e portelloni; altezza di riferimento 2,524 m e collider aggiornato. Passo 3,45 m e lunghezza 5,413 m.
- Aggiornati dati, interfaccia, riferimenti e verifiche; rigenerate ed esaminate le tre viste del modello con il renderer reale.

## 17 ottobre 2026 — Fase 6, Ducato e rifinitura locale

- Ricostruito Apollo come Fiat Ducato X250 2010 2.2 MultiJet 100 PS / 74 kW, 4HV Euro 4, **passo medio e tetto basso L2H1**, come confermato dall'utente. Proporzioni metriche, frontale, porte, ruote, cabina, collider e tre viste dedicate; fonti in `data/vehicles/REFERENCES.md`.
- Aggiunti salvataggi locali con schema controllato, file temporaneo, copia precedente, recupero da file corrotto e segnalazione degli errori. Premi, sblocco, record delle stelle e impostazioni permanenti, con test isolati dai dati reali.
- Introdotti impostazioni audio/camera, guida tranquilla, movimenti ridotti, ombre e collezione. Riorganizzato il menu per mantenere pulsanti grandi e focus navigabile.
- Aggiunti musica, motore, frenata, ambiente con uccellini, suoni UI e completamento, tutti sintetizzati; MSAA 4× e normali dei pannelli corrette.
- Superati 29 nuovi controlli e ripetute le 146 verifiche precedenti, senza errori; verificato anche il riavvio fra due processi. Catture OpenGL esaminate.
- Misurati 1920×1080 su RTX 4080: circa 355 FPS mediani nel circuito e 123 a Volpiano; screening breve, hardware minimo e controller fisico ancora da verificare. Esportazione autonoma prevista nella Fase 7.

## 17 ottobre 2026 — Fase 5, storia e missioni

- Aggiunti personaggi seduti modulari con volti, capelli, abiti, cinture diagonali/addominali e configurazione locale facoltativa di nomi e colori. Adattata la cabina per renderli visibili.
- Implementati dialoghi italiani da JSON e stati introduzione, guida, epilogo e completamento, con lettura manuale e controllo del veicolo sospeso durante le sequenze.
- Creato percorso narrativo pubblico di 669 m su 26 segmenti OSM, tre stelle facoltative, semaforo rosso/verde con sosta e parcheggio finale.
- Aggiunti epilogo con vista animata della scuola, medaglia Compagni di viaggio e sfida sbloccabile Il Parcheggio Perfetto con medaglia Pilota gentile.
- Mantenuta esplicita la versione racconto: partenza privata e sosta/ingresso reali non ancora verificati; ultima parte a piedi raccontata. Individuato avviso comunale del 2022 sui divieti scolastici di Via Trieste.
- Superati tre nuovi test dei dati e 49 controlli integrati della storia; ripetute le 94 verifiche precedenti. Catture OpenGL esaminate.

## 17 ottobre 2026 — Fase 4, prime gite nei parchi

- Aggiunti catalogo geografico offline e importatore riproducibile per i parchi, con verifica delle schede comunali e dell'estratto OSM.
- Attivate Madonna delle Grazie e San Grato con viaggio rapido e breve avvicinamento su archi stradali reali. De Gasperi, Pertini e Riviera restano da verificare per discrepanze fra pin e geometrie.
- Creato modello riutilizzabile con altalena, scivolo, dondolo, arrampicata, panchina, alberi, pavimentazione colorata e recinto con collisioni; animazioni leggere.
- Aggiunta attività “La Stella Perduta”, vista dedicata del parco, indizi, tentativi illimitati, stella 3D e adesivo “Apollo Esploratore”.
- Raccolta distinta per parco mantenuta nella partita, senza duplicati con replay o cambio ambiente. Salvataggio permanente rinviato alla Fase 6.
- Validati cinque test dei dati e 29 controlli integrati dei parchi; ricontrollati circuito, percorso cittadino e Fase 3. Catture reali OpenGL esaminate.

## 17 ottobre 2026 — Fase 3, cittadina cartoon

- Aggiunte facciate su impronte OSM con colori caldi, cornici, persiane, balconi, porte e tetti in terracotta, con falde per geometrie compatibili.
- Creati chiesa dei Santi Pietro e Paolo e municipio nelle impronte reali, con riferimenti fotografici comunali; incluso il plesso di Via Trieste incrociando impronta scolastica OSM e punto mappa dell'Istituto.
- Importati punti OSM per alberi, attraversamenti e semafori; nel diorama pubblico sono presenti 28 attraversamenti e due impianti semaforici segnaposto.
- Aggiunti arredi illustrativi: lampioni, panchine, fioriere, cestini, sette auto ferme con collisioni e 29 targhe con nomi stradali OSM.
- Raggruppati i dettagli in 32 MultiMesh; aggiunti cielo procedurale e foschia leggera per la mappa cittadina.
- Aggiunti test cittadini, controllo dei punti contro la fonte OSM e cinque catture di verifica. Nessuna missione scolastica attivata, nessun benchmark 1080p dichiarato.

## 17 ottobre 2026 — Fase 2, primo ambiente OSM

- Aggiunti importatore Python riproducibile, estratto offline con attribuzione ODbL e proiezione metrica locale.
- Generati rete stradale, bordi pedonali indicativi e volumi sulle impronte edilizie OSM.
- Aggiunti percorso esplorativo Via Trento–Via Brandizzo, punti dorati, indicatore di direzione e parcheggio.
- Menu con selezione Volpiano/circuito, reset adatto alla nuova estensione e configurazione privata facoltativa esclusa dai dati pubblici.
- Verificati indirizzo scolastico e presenza di una segnalazione sui divieti: accesso finale ancora da accertare, Via Trieste esclusa dalla navigazione.
- Aggiunti sei test Python e test Godot di percorrenza fisica dei segmenti geografici e cambio ambiente.

## 17 ottobre 2026 — Fase 1

- Inizializzato progetto Godot 4.6.1 Compatibility con scene principali modulari.
- Creato Apollo con carrozzeria bianca, cabina, specchi, porta laterale, griglia, ruote, fari, fanali e occupanti segnaposto con cinture.
- Implementati guida arcade, retro, frenata, collisioni, reset manuale e recupero automatico.
- Aggiunta telecamera con inseguimento, distanza regolabile, seconda visuale e SpringArm anticollisione.
- Creato circuito provvisorio decorato con quattro tappe e parcheggio.
- Aggiunti menu e HUD italiani, pausa, riavvio, clacson e suono tappa procedurali.
- Configurati tastiera e controller; aggiunto avvio locale con doppio clic.
- Aggiunti test integrati, cattura visiva e documenti di progetto.
- Validati 18 controlli; corretti pausa fisica, quota del collider e rilascio dei campioni audio alla chiusura.
