# Avanzamento — APOLLO

Aggiornato il 24 ottobre 2026.

**Casa e partenza locale:** attivata su questo PC la partenza dal cortile della casa indicata dall'utente, con facciata arancione, abbaino, scala esterna, balcone, palma e cancello animato con collisioni. Configurazione personale in `local/home_departure.json`, raccordo della partenza solo in memoria; il catalogo OSM pubblico rimane invariato. Incrocio indicato dall'utente, distanza del cancello dall'angolo ancora stimata. Esplorazione, storia e reset usano la partenza domestica, i parchi mantengono gli avvicinamenti. Superati i sette controlli dedicati al cancello, il percorso fisico completo, 58 controlli della storia e 12 della città con configurazione locale. Catture Vulkan/OpenGL in `build/verifica/casa-apollo-*.png`.

**Via Trento dalle foto ricevute:** prima interpretazione locale del tratto del ponticello OSM, con parapetti verdi, autobloccanti rosati, recinzioni e ingressi, palazzine con tapparelle e balconi lunghi, fabbricato rustico, asfalto usurato e tre auto ferme. Profili visivi separati dai dati importati in `data/map/trento_reference.json`; associazioni edificio/foto provvisorie e misure stimate. Impronte e rotta conservate. Verificati città, tragitto principale e tratto fotografico con guida fisica; catture Vulkan/OpenGL in `build/verifica/trento-foto-*.png`. Dettagli e limiti in `data/map/TOWN_REFERENCES.md`.

**24 ottobre 2026 — Volpiano e Via Trento:** estensione del diorama su tutti i tratti importati di Via Trento e clipping dei segmenti al bordo; strade asfaltate separate dai permessi di transito. Palette, ingressi, coperture e luce più sobri, eliminati negozi casuali e dissuasori sistematici. Test OSM, città, percorso fisico, storia e parchi superati. Street View non consultabile perché non c'è un browser disponibile nella sessione: facciate e quote non censite rimangono stime procedurali. Riferimenti aggiornati in `data/map/TOWN_REFERENCES.md` e anteprime in `build/verifica/stile-*-dopo.png`.

## Milestone attuale

**Posteriore X250 ricostruito** (20 ottobre 2026): sostituita la faccia centrale della base con due portelloni H2 separati, nervature, fascia inferiore, incavo targa, maniglia sagomata, stemma rosso e scritta DUCATO. Fanali ricostruiti con sezioni distinte, riflettori e lenti; stop laterali e terzo stop funzionanti, catadiottri originali conservati. **39 controlli superati, zero errori** (10 geometria/animazioni e 29 Fase 6); catture Vulkan e OpenGL esaminate, anche in frenata. Catture posteriori dritte, ravvicinate e in frenata riproducibili con `tests/vehicle_capture.gd`. Backup dei file e delle immagini precedenti in `build/backup/posteriore-x250-20261020/`. Il riferimento è un Ducato 2010 L2H2 fotografato, non un rilievo dell'esemplare personale.

**Anteriore X250 ricostruito** (18 ottobre 2026): fascia centrale bianca attorno alla calandra, griglia più bassa a quattro lamelle sagomate, cofano con aperture reali sulle ottiche, paraurti arrotondato con giunti e prese incassate. Fari più grandi con vasche profonde, parabole rivolte in avanti, flange, maschere cromate e coperture trasparenti. Fonte aggiuntiva e limiti in `data/vehicles/REFERENCES.md`. Superati **37 controlli mirati** (8 geometria/animazioni e 29 Fase 6); catture studio Vulkan e OpenGL esaminate. Nuove viste `build/verifica/apollo-realistico-frontale.png` e `apollo-realistico-ottiche.png`; confronto notturno `apollo-realistico-notte-spenti.png` / `apollo-realistico-notte-accesi.png`. Backup precedente in `build/backup/frontale-x250-20261018/`. Il frontale è ora più coerente con il riferimento, ma rimane modellato da fotografie.

**Apollo più realistico** (18 ottobre 2026): base 3D *2014 Fiat Ducato* di razor24, CC BY 4.0, adattata a passo 3,45 m e tetto H2 a 2,524 m; frontale X250 ricostruito. Cabina, porte, specchi e ruote dettagliati, vernice con clearcoat, plastiche con grana, vetri e battistrada. Fari con lenti e riflettori separati, freni e ruote animati. Vetrina con illuminazione neutra e attribuzione del modello. Anteprime `build/verifica/apollo-realistico-*.png`, riproducibili con `tests/vehicle_capture.gd`; backup `build/backup/ducato-realismo-20261018/`. Crediti in `assets/vehicles/CREDITS.md`. Rimane un adattamento da una carrozzeria successiva e non raggiunge la fedeltà di un modello CAD specifico del 2010; personaggi e città sono stilizzati. I benchmark storici sotto non misurano questo nuovo modello.

Verifiche della prima versione della base dettagliata: **66 controlli superati** (18 guida, 12 città, 29 Fase 6, 7 geometria e animazioni); catture studio Forward+/Vulkan e OpenGL esaminate. Cabina e vetrina controllate con il renderer reale. In OpenGL il pavimento riceve le ombre del furgone senza proiettarle su sé stesso, evitando gli artefatti di auto-ombreggiamento.

**Facciate e atmosfera rifinite** (18 ottobre 2026): 293 fronti decorati lungo i percorsi, portoni ad arco con pannelli e ferramenta, cornici in pietra, cantonali e dentelli. Vetrine in cinque colori con tende inclinate e insegne circolari; vetri con variazioni di tono e tende stilizzate. 135 piccoli piazzali pavimentati nella mappa pubblica, collocati dopo aver registrato tutte le impronte. Cielo e palette più intensi, esposizione e luce riequilibrate. Dettagli riuniti in 18 MultiMesh, 231.954 istanze. Indice spaziale delle strade verificato contro la ricerca completa. Superati 65 controlli; importazione editor e catture Vulkan/OpenGL senza errori. Anteprime `build/verifica/stile-facciate-dopo.png` e `stile-apollo-dettagli-dopo.png`. Backup in `build/backup/facciate-atmosfera-20261018/`. Il benchmark intermedio è avvenuto con altre due istanze Godot aperte e non è confrontabile con i dati precedenti; limiti in `PERFORMANCE.md`.

**Seconda revisione: modello di Apollo e dettaglio urbano** (18 ottobre 2026): superfici raccordate su tetto, cabina, cofano, paraurti e specchietti; fari con riflettori, tergicristalli, pneumatici sagomati con battistrada, cerchi con fori e bulloni. Passo, tetto H2, collider e occupanti conservati. Persiane con lamelle procedurali, bordure in pietra e 127 dissuasori visivi lungo la rotta pubblica. Superati 64 controlli (58 esistenti e 6 proprietà geometriche/animazioni); catture Vulkan e OpenGL, incluso confronto fari spenti/accesi. Screening 1080p: circa 378 FPS nel circuito e 113 a Volpiano su RTX 4080; metodo e limiti in `PERFORMANCE.md`. Anteprima: `build/verifica/stile-apollo-dettagli-dopo.png`. Backup precedente in `build/backup/modello-dettagliato-20261018/`. Il modello resta un'interpretazione cartoon procedurale.

**Prima revisione dello stile su riferimento dell'utente** (18 ottobre 2026): cielo turchese, illuminazione calda, palette terracotta/pesca, muratura discreta, fasce tra i piani, grondaie, pluviali e vetrine con tende a righe. Corretto l'avvolgimento della pista del circuito, che rendeva l'asfalto invisibile dall'alto. Catture reali Forward+ e OpenGL in `build/verifica/stile-*`; backup dei file precedenti in `build/backup/stile-riferimento-20261018/`. Superati 58 controlli esistenti (guida, città, Fase 6). Screening 1080p su RTX 4080: circa 405 FPS nel circuito e 95 a Volpiano; metodo e limiti in `PERFORMANCE.md`. È una prima direzione visiva, non la stessa fedeltà di modellazione del riferimento.

**Rifinitura grafica completata e validata sul PC di sviluppo** (17 ottobre 2026): renderer Forward+ con ripiego OpenGL, atmosfera, shader procedurali, città ricostruita in poche mesh, Apollo, interfaccia. Dettagli in `CHANGELOG.md` e `PERFORMANCE.md`.

**Fase 6 implementata e validata sul PC di sviluppo**: Ducato X250 L2H2 corretto, salvataggi, impostazioni, audio, accessibilità e misure grafiche. Rimangono la prova con controller fisico e il benchmark sull'hardware di destinazione. Le fasi precedenti rimangono disponibili; la Fase 2 conserva aperta la verifica del tragitto privato e della sosta scolastica definitiva. Motore Godot 4.6.1 su Windows.

## Completato
- **Grafica:** Forward+ con fallback automatico a OpenGL 3.3; cielo con nuvole, Alpi innevate e colline, sole del mattino, nebbia per profondità, filmic, glow, SSAO/SSIL e ombre morbide. Shader originali per prato, campagna, asfalto, lastre, intonaco e coppi. Tetti a padiglione o con falde perimetrali, comignoli, persiane colorate, balconi fioriti, alberi low-poly al vento, verde sparso, auto colorate, lampioni accesi, frecce dorate, colonna d'arrivo, arcobaleno sul plesso. Apollo con vernice lucida, vetri, cromature, luci e sbuffi. Interfaccia con pulsanti in rilievo, focus dorato, sfondo sfocato e vignettatura. Impostazione salvata **Grafica avanzata**.
- Identità Apollo confermata dall'utente: **Fiat Ducato 2010, 2.2 MultiJet 100 PS / 74 kW, codice 4HV, Euro 4, passo medio e tetto alto (L2H2)**. Modello a pannelli ricostruito con frontale X250, vetri inclinati, fari obliqui, porta scorrevole, portelloni e ruote; passo geometrico 3,45 m e collider 2,05 × 2,524 × 5,413 m. Fonti e limiti in `data/vehicles/REFERENCES.md`.
- Menu **Apollo da vicino** con tre viste in uno spazio dedicato e dati del veicolo; personaggi e cinture mantenuti nella cabina con rialzo H2.
- Salvataggi `user://apollo_save.json`: raccolta parchi, record stelle dei viaggi, medaglie, missioni sbloccate e impostazioni. File temporaneo, copia `.bak`, recupero da file corrotto, validazione di tipi/identificativi e messaggi sugli errori. Nessuna posizione o coordinata personale salvata.
- Impostazioni dal menu e dalla pausa: musica ed effetti separati, camera, guida tranquilla a 36 km/h, movimenti ridotti e ombre. Collezione con stelle e medaglie permanenti; menu a griglia e navigazione tramite focus.
- Audio originale sintetizzato: musica, motore legato alla velocità, frenata, clacson, uccellini, UI, raccolta e breve melodia di completamento. Non sono registrazioni del 4HV. MSAA 4× e normali dei pannelli verificate.
- Screening grafico a **1920×1080 su RTX 4080 e Ryzen 7 5700X3D**: circa **355 FPS mediani nel circuito e 123 FPS a Volpiano**, p95 3,44 / 9,87 ms. Metodo e limiti in `PERFORMANCE.md`; non certifica una GPU minima.
- Due personaggi seduti modulari con volti, capelli, abiti e cinture diagonali/addominali, visibili in cabina. Nomi e colori configurabili tramite `local/family.json` con valori predefiniti e controllo dei campi invalidi.
- Dialoghi italiani in JSON e sequenze leggibili con Avanti; macchina degli stati fra introduzione, guida, epilogo e completamento. Apollo fermo durante le sequenze.
- Versione racconto della Missione Scuola: **669 m e 26 segmenti OSM**, tre stelle facoltative, semaforo rosso/verde con sosta e parcheggio finale illustrativo su Via Brandizzo.
- Epilogo sull'edificio scolastico con movimento di camera, ultima parte a piedi raccontata, messaggio di successo e medaglia Compagni di viaggio.
- Sfida sbloccabile Il Parcheggio Perfetto, con due soste intermedie e una finale, oltre al semaforo, e medaglia Pilota gentile. Premi e sblocco salvati su disco dalla Fase 6.
- Individuato avviso comunale del 2022 sui divieti scolastici di Via Trieste; mantenuti `preview=true` e accesso carrabile non verificato nei dati narrativi. Fonti e limiti in `STORY_NOTES.md`.
- Catalogo parchi offline con fonti comunali e OSM: **Madonna delle Grazie e San Grato** attivi, **De Gasperi, Pertini e Riviera** ancora da verificare. Precisione e discrepanze documentate in `data/map/PARK_REFERENCES.md`.
- Menu “Le gite nei parchi”, viaggio rapido, diorami georeferenziati e breve avvicinamento su un arco OSM accessibile per ogni gita.
- Modello riutilizzabile di area giochi con altalena e dondolo animati, scivolo, arrampicata, panchina, alberi, pavimentazione e recinto con collisioni.
- Attività dopo il parcheggio: vista del parco, tre nascondigli, indizio e tentativi illimitati. Stella 3D e adesivo “Apollo Esploratore”, una stella distinta per parco e nessun duplicato rigiocando.
- Raccolta conservata anche cambiando ambiente o chiudendo il gioco; salvataggio permanente dalla Fase 6.
- Cittadina cartoon con **693 edifici**, facciate, cornici, persiane, balconi e tetti; altezze stilizzate e piani OSM usati dove disponibili.
- Tre luoghi pubblici georeferenziati: chiesa dei Santi Pietro e Paolo, municipio e plesso di Via Trieste. Fotografie comunali consultate e riferimenti documentati in `data/map/TOWN_REFERENCES.md`.
- Secondo estratto OSM per dettagli urbani; nel diorama **117 alberi, 28 attraversamenti, 2 semafori segnaposto**. Sei lampioni, cinque panchine, fioriere, cestini, sette auto ferme e 29 targhe stradali illustrativi.
- Dettagli ripetuti raggruppati in **32 MultiMesh**, cielo procedurale e foschia leggera. Le auto ferme hanno collisioni; i piccoli arredi rimangono non bloccanti.
- Importatore OSM Python riproducibile e dati offline con attribuzione ODbL, fonte e timestamp documentati in `data/map/SOURCES.md`.
- Proiezione geografica locale metrica, 592 vie nell'estratto e grafo con 1958 nodi e 3525 archi diretti.
- Diorama sul percorso pubblico Via Trento–Corso Regina Margherita–Via Brandizzo, circa 455 m; bordi pedonali indicativi e volumi edilizi sulle impronte reali.
- Menu “Esplora Volpiano”, 16 tappe geografiche, punti guida, direzione e parcheggio finale; ritorno al circuito di prova.
- Configurazione facoltativa di origine, scala e partenza in `local/`; anche i dati derivati da coordinate private restano locali.
- Esclusione conservativa di accessi vietati/condizionali, vie coinvolte in restrizioni di svolta e Via Trieste in attesa della verifica della strada scolastica.
- Letto integralmente `redme.txt`; mantenuto come specifica originale.
- Scelti Godot 4.6.1 stabile, GDScript e renderer Compatibility.
- Creati configurazione, scena principale, scena Apollo e sistemi modulari.
- Implementati modello procedurale, controller arcade e telecamera SpringArm3D.
- Circuito ovale decorato, quattro tappe in ordine e parcheggio finale.
- Menu iniziale, pausa, riavvio e completamento in italiano.
- Mappature tastiera e controller, fari, ruote animate, sterzo e clacson procedurale.
- Esecuzione automatica finale: **18 controlli superati, zero errori**, uscita con codice 0 e senza avvisi di risorse residue.
- Catture reali OpenGL di menu e guida esaminate; regolata la luce del circuito.
- Corretti allineamento del collider, arresto fisico in pausa e rilascio dell'audio alla chiusura.
- Completati README, piano di sviluppo, registro modifiche, crediti e avvio con doppio clic.

## Verifiche eseguite
- Dopo la rifinitura grafica: ripetuti tutti i test (18 + 24 + 11 + 29 + 49 + 29 controlli Godot, 15 test Python, riavvio fra due processi), **zero errori**. Indice del pulsante "Salva e torna" aggiornato in `phase6_test.gd` per la nuova impostazione. Catture Forward+ esaminate per circuito, città, panorama, chiesa, scuola, parco, cabina, vetrina, menu e impostazioni; cattura OpenGL di controllo senza errori. Benchmark 1080p: 466 FPS mediani nel circuito e 156 a Volpiano.
- `tests/phase6_test.gd`: **29 controlli superati**, con primo avvio, scrittura, recupero, schema/tipi invalidi, errore I/O, identità L2H2, passo, collider, normali, impostazioni, loop audio e vetrina. Test di gioco isolati dai dati dell'utente.
- `tests/save_process_test.gd`: scrittura in un processo e riapertura in un secondo; premi e impostazioni mantenuti e sfida già sbloccata caricabile. File di prova separati dal salvataggio reale.
- Catture reali della Fase 6 esaminate: menu, impostazioni, collezione, tre viste del Ducato e cabina. Benchmark separato senza headless o fixed-fps, 90 frame di riscaldamento e 240 campioni per ambiente.
- `tests/story_data_test.py`: **3 test superati** per continuità/accessibilità del percorso, semaforo OSM e dialoghi.
- `tests/story_test.gd`: **49 controlli superati**, con guida fisica dei 26 segmenti, cinture, configurazione parziale, blocco durante i dialoghi, pausa, rosso/verde, raccolta di tre stelle, epilogo, reset e sfida bonus. Nella sfida bonus le soste sono preparate direttamente, senza un secondo giro fisico completo.
- Esecuzione reale OpenGL e catture della Fase 5 esaminate: cabina, menu, semaforo, arrivo e completamento. `story_capture.gd` per le catture rapide; la modalità visiva del test sposta il mezzo lungo i segmenti.
- `tests/park_data_test.py`: **5 test superati**, con riproducibilità del catalogo, archi di accesso, ingombro nel perimetro OSM di Madonna delle Grazie, controllo rispetto alle impronte edilizie e località non verificate escluse dalle gite.
- `tests/parks_test.gd`: **29 controlli superati**, incluse percorrenze fisiche dei due avvicinamenti, recinti, sosta, scelte UI, premi, replay e cambio gita. Catture reali OpenGL di parchi, ricerca, premio e raccolta esaminate; la modalità visiva prepara direttamente la sosta.
- Totale aggiornato: **175 verifiche automatiche superate**, zero errori, fra 15 test Python e 160 controlli Godot; inoltre verificato il riavvio fra due processi. Importazione del progetto e verifica grafica separate.
- `python tests/map_test.py`: **7 test superati** per coordinate, direzioni, accessi, relazioni, continuità della rotta e corrispondenza dei dettagli alla fonte OSM.
- `tests/town_test.gd`: **11 controlli superati** per cittadina, luoghi pubblici, arredi, segnaletica, collisioni delle auto ferme e raggruppamento delle mesh. Esecuzione reale OpenGL con catture di guida, panorama, chiesa, municipio e scuola esaminate.
- `tests/volpiano_test.gd` headless con frame fissi: **24 controlli superati**, inclusa percorrenza fisica dei 16 segmenti, parcheggio, reset e ritorno al circuito. Il test orienta il mezzo all'inizio di ogni segmento; non certifica lo sterzo manuale.
- Catture reali OpenGL della nuova mappa e del menu esaminate in `build/verifica/volpiano.png` e `volpiano-menu.png`; corretta la quota degli edifici e ripetuta la verifica visiva.
- Ripetuti i 18 controlli del circuito: zero errori. Attesa del mixer audio alla chiusura dei test per evitare avvisi di playback residui nelle esecuzioni accelerate.
- Importazione headless del progetto con il motore reale.
- `tests/smoke_test.gd`: guida, terreno, sterzo, retro, frenata, limite, collisioni, reset, telecamera, pausa fisica, tappe e riavvio.
- `tests/visual_capture.gd`: avvio con renderer Compatibility sulla NVIDIA GeForce RTX 4080; immagini di menu e guida salvate in `build/verifica/` ed esaminate visivamente.
- Le tappe sono verificate spostando il veicolo nei punti obiettivo: il test non certifica un giro intero guidato manualmente.

## Da completare
- Fase 2: verificare ingresso scolastico, ordinanza e sosta consentita, poi configurare partenza privata e percorso finale; prova manuale completa.
- Fase 4: verificare i perimetri delle tre località sospese; affinare quello approssimato di San Grato e ampliare attività e collegamenti stradali fra le aree.
- Fase 5: tragitto privato e accesso scolastico definitivi subordinati alla verifica geografica; altre missioni opzionali oltre alla sfida di parcheggio.
- Fase 6: controller fisico e hardware di destinazione ancora da verificare.
- Fase 7: esportazione Windows autonoma, icona, crediti e checklist.
- Prova manuale completa con tastiera e controller fisico; benchmark a 1080p sull'hardware di destinazione, oltre allo screening già eseguito sul PC di sviluppo.

## Problemi noti e limiti
- Grafica: SSAO, SSIL e ombre morbide esistono solo con Forward+; con il ripiego OpenGL l'aspetto è più piatto e più saturo. Le Alpi sono un profilo stilizzato nel cielo, non un rilievo geografico. I tetti seguono l'asse principale dell'impronta: su alcune forme molto irregolari restano coperture piane. Generazione di Volpiano più lenta (circa 1,3 s sul PC di sviluppo). Benchmark ancora da ripetere su una GPU di fascia media.
- Nessun errore funzionale emerso nei controlli automatici finali.
- Il circuito resta fittizio; la cittadina usa impronte e rete OSM con aspetto cartoon procedurale.
- Accesso scolastico definitivo non verificato: individuato anche l'avviso comunale del 2022 che delimita il tratto scolastico vietato su Via Trieste. Resta da verificare disciplina attuale, punto di sosta e ingresso esatto; il racconto non porta il furgone al cancello.
- Altezze, facciate e arredi sono interpretazioni stilizzate; strade con larghezze convenzionali, terreno piano e ponti senza quota. La scuola mantiene una facciata segnaposto e non ha un ingresso carrabile verificato.
- I semafori dell'esplorazione mantengono ambra fissa; nel racconto un impianto ha logica di gioco rosso/verde. Tempi e colori non riproducono la regolazione reale. I monumenti restano nelle posizioni geografiche originali.
- Navigazione su percorso precalcolato, senza ricalcolo fuori traccia. Restrizioni di svolta gestite escludendo intere vie, con perdita di connettività. Il giocatore può imboccare fisicamente anche strade escluse dal grafo.
- Benchmark 1080p eseguito sul solo PC di sviluppo; test con controller fisico e GPU di destinazione ancora da eseguire.
- Personaggi e geometrie rimangono stilizzati. Motore, musica e ambiente sono sintesi originali; nessuna registrazione del Ducato reale. Allestimento e dettagli personali del furgone non sono stati verificati da fotografie dell'esemplare.
- Stelle e premi sono persistenti. L'adesivo rimane una ricompensa UI; posizione e tappa corrente della missione non sono salvate.
- Le gite usano viaggio rapido e avvicinamenti locali, senza un itinerario continuo dal centro città. Gli allestimenti e il cerchio di sosta sono illustrativi: non certificano attrezzature attuali o posteggi reali. La ricerca avviene con una camera, senza personaggio a piedi.
- La Missione Scuola è attiva come versione racconto con partenza pubblica, sosta illustrativa e finale a piedi narrato; il tragitto privato definitivo non è ancora attivo. Tre parchi sono sospesi per incongruenze geografiche e San Grato mantiene un perimetro approssimato.
- Medaglie e sblocco della sfida sono permanenti; le stelle del viaggio si azzerano rigiocando, conservando il record salvato. Le forme dei personaggi rimangono cartoon generiche, personalizzabili con nomi e colori.
- Nessun eseguibile autonomo esportato: l'avvio locale usa il motore portatile già scaricato.

## Prossime azioni
La prossima fase principale è la 7: esportazione Windows autonoma, icona e checklist. Rimangono le prove manuali con controller fisico e PC di destinazione della Fase 6. Conservare i limiti geografici espliciti e concludere la verifica della sosta e dell'accesso scolastico prima del tragitto privato definitivo. Per ampliare i parchi, verificare prima i perimetri sospesi; per ampliare la rete guidabile, migliorare svolte e quote dei ponti.
