# Fase 3 — riferimenti della cittadina cartoon

## Casa di Apollo — riferimento dell'utente

L'utente ha indicato la casa e il cancello di partenza e fornito una schermata Street View di luglio 2025, precisando successivamente l'incrocio. L'indicazione dell'utente è il riferimento per l'identità dell'abitazione: il civico sovrimpresso da Street View riguarda la panoramica e non sostituisce tale indicazione.

Modello esterno procedurale con intonaco arancione, persiane brune, scala, balcone con parapetti misti, abbaino, pilastri in mattoni, cancellata grigia a due ante e palma a ventaglio. Sagoma, altezze e distanze non sono un rilievo metrico. La posizione esatta del varco rispetto all'incrocio è ancora stimata; riferimento personale e associazione alla mappa sono conservati esclusivamente in `local/home_departure.json`. Nessuna foto usata come texture.

Il modello locale sostituisce il volume generico selezionato e riserva lo spazio del cortile da recinzioni e vegetazione automatiche. Apollo parte dietro il cancello e lo apre avvicinandosi; ante e strutture hanno collisioni. Il raccordo del cortile è dichiarato privato, calcolato solo in memoria, e non viene spacciato per un arco OSM. Il resto della rotta segue archi diretti esistenti. Configurazione domestica disattivata nei parchi e nei test pubblici senza `--with-home`.

Verifiche: sette controlli dedicati a raccordo, senso unico, collisioni delle ante, apertura, uscita e reset; percorso di esplorazione completo, storia e città con configurazione locale. Catture reali in `build/verifica/casa-apollo-*.png`, riproducibili con `tests/home_capture.gd -- --with-home`.

## Via Trieste e scuola — foto del 3 novembre 2026

Dieci schermate Street View (giugno 2026) mostrano Via Trieste dal suo inizio con "SP3" sull'asfalto fino all'angolo con Via Fiume e al parcheggio della scuola. Modellati: carreggiata a due corsie con mezzeria tratteggiata, marciapiedi rosati, recinzioni e cancelli diversi, siepi, lampioni a braccio, attraversamenti con fasce arancioni e cartelli blu, guard-rail sul fosso, rete alta del capannone, piazzale della scuola con auto di traverso e transenne. Le facciate sono interpretazioni per tono e altezza, non associate edificio per edificio. I capannoni a volta in mattoni rossi non sono modellati; l'ultimo tratto (Via Trieste, da Via Fiume alla scuola) segue la geometria OSM. Nessuna foto è usata come texture.

## Sottopasso di Via Novara — foto del 3 novembre 2026

Dodici schermate Street View (marzo e giugno 2026) mostrano l'imbocco da Via Pasubio, la rotatoria con Via Tolmino e il sottopasso: trincea di cemento con muri alti e rampe curve, balaustra metallica sul lato pedonale, scarpata e steccato della ferrovia sull'altro, ponte con limite di altezza 3,60 m e semaforo, mezzeria bianca con croci. Il mondo è piatto: la trincea è resa con muri solidi, non con un terreno scavato. La posizione del ponte (339, 256) e la sua direzione sono stimate dalla vista aerea; il parcheggio all'imbocco è un'interpretazione delle foto. L'isola della rotatoria e le palazzine sullo sfondo non sono modellate. Nessuna foto è usata come texture.

## Via Pasubio — foto del 3 novembre 2026

Sei schermate Street View (novembre 2020 e giugno 2026) mostrano Via Pasubio come via stretta a senso unico verso Via Novara, senza marciapiedi. Larghezza stimata 4,6 m. Modellati: fabbricati a fasce di mattoni su intonaco chiaro, palazzina gialla con inferriate verdi, case salmone e una casa azzurra verso il fondo; recinzioni bianche su muretto, cancelli di ferro con pilastri, siepi d'edera, reti verdi, dissuasori giallo-neri, lampioni sottili, scritte a terra e segnale di divieto di fermata. Le associazioni foto/edificio dedotte dall'ordine lungo la via sono provvisorie. Nessuna foto è usata come texture; arredi senza collisioni.

## Seconda revisione del 24 ottobre 2026 — foto di Via Trento

L'utente ha fornito otto schermate di Google Street View, con sei viste distinte: due all'altezza indicata come 38 Via Trento (luglio 2025), due presso 17 Via Trento (novembre 2020), una presso 9 Via Trento (novembre 2020) e una presso 14 Via Trento ripetuta tre volte (luglio 2025). Ora queste immagini sono state osservate direttamente nella conversazione; il precedente limite di accesso al browser non impedisce di usarle come riferimento visivo.

Elementi modellati: autobloccanti rosati, bordi bianchi della carreggiata, crepe leggere nell'asfalto, chiusini e caditoie, zoccoli in blocchi di pietra, persiane scure e tapparelle chiare a diverse aperture, balconi lunghi con ringhiere metalliche, tende domestiche, muretti e cancelli, lampioni sottili a braccio, auto ferme sul margine. Il ponticello mantiene la posizione del way OSM **889238377**, con due parapetti verdi. La coppia di segnali dosso/30 riprende la schermata di luglio 2025; è decorativa, senza nuove regole di missione.

Il catalogo `trento_reference.json` separa le otto interpretazioni locali degli edifici dai dati OSM importati. Le associazioni delle singole facciate alle impronte sono **provvisorie**, dedotte dall'ordine visibile attorno al ponte: i civici mostrati da Street View non provano il punto esatto di ogni edificio. Altezze, colori e dettagli sono stime visive. La grammatica di facciata è estesa agli edifici entro 24 m dall'asse principale di Via Trento; non si estende alle altre vie. Larghezza stimata della carreggiata 6,6 m, marciapiede 1,15 m per lato. Le impronte e il grafo OSM restano invariati. Non sono stati modellati interni, persone o targhe, né distribuite le schermate come texture.

Le ringhiere e i cancelli sono dettagli visivi; i campioni di posizionamento evitano strade e impronte. Le tre nuove auto hanno collisioni e lasciano libero l'asse stradale; il test dedicato percorre con fisica reale il tratto fra la palazzina e l'estremità nord di Via Trento. La quota del ponte e il terreno restano sul piano semplificato: non è ancora ricostruito il canale sottostante.

Verifiche: `tests/trento_reference_test.gd` (6 controlli, incluso tragitto fisico), città e percorso missione. Catture reali Vulkan/OpenGL in `build/verifica/trento-foto-*.png`, riproducibili con `tests/trento_capture.gd`. La somiglianza è una prima interpretazione delle foto, non un rilievo metrico o una corrispondenza completa edificio per edificio.

## Prima revisione del 24 ottobre 2026 — prima delle foto

Questa revisione supera le scelte cartoon descritte nelle sezioni storiche sotto. Google Street View è stato richiesto come riferimento, ma il collegamento Browser non ha trovato alcun browser disponibile (`No browser is available`, elenco vuoto). **Le panoramiche non sono state visualizzate** e la revisione non è una ricostruzione fotografica certificata di Volpiano. Non sono state aggiunte immagini Google agli asset.

- Via Trento: inclusi tutti e cinque gli archi OSM con questo nome nell'estratto esistente, con almeno 65 m di margine nel diorama cittadino. Conservati tracciato, scala metrica, partenza e percorso missione. La copertura resta quella dell'estratto OSM, non l'intero territorio comunale.
- Il clipping conserva la parte interna dei segmenti che attraversano il bordo, anche se entrambi gli estremi sono esterni. I diorami dei parchi mantengono la loro estensione locale.
- Aspetto stradale separato dall'accessibilità: una strada asfaltata resta tale anche se il grafo di guida la esclude; Via Trieste conserva la carreggiata senza attivare l'accesso scolastico. L'importatore conserva tipo di strada, larghezza e lato del marciapiede. Dove mancano i tag, larghezze e marciapiedi sono stime: 7 m per assi principali, 6 m per le altre carreggiate, 1 m per lato di marciapiede. Nessuna misura è stata ricavata da Street View. I ponti restano sul piano semplificato.
- Altezze `building:levels` e coperture piane note conservate; gli edifici senza piani dichiarati usano un'altezza stimata di 6,2 m, rimesse 2,7 m, capannoni 5,5 m. Intonaci crema, grigi e sabbia, coppi bruni, ingressi rettangolari, cornici semplificate. Nessuna pretesa di corrispondenza edificio per edificio.
- Vetrine generate solo su impronte con classificazione commerciale OSM; rimossi cantonali e dentelli sistematici, portali ad arco generici e filari automatici di dissuasori. Arredi rimanenti ancora illustrativi. Dettagli delle facciate concentrati entro 55 m dalla rotta e da Via Trento.
- Cielo, nebbia e illuminazione di Volpiano meno saturi; atmosfera del circuito conservata. Catture Vulkan in `build/verifica/stile-*-dopo.png`, incluse vista completa di Via Trento e viste stradali a sud. Le immagini `prima` documentano l'aspetto precedente.

Verifiche: test dati OSM, test della mappa con tutti i segmenti di Via Trento renderizzati, clipping dei segmenti passanti, percorso principale con guida fisica, città, missione narrativa e parchi. Le verifiche automatiche non sostituiscono il confronto con fotografie o la prova manuale dell'intera Via Trento.

Verificati il 17 ottobre 2026. Le fotografie sono state consultate come riferimento; non sono incluse negli asset del gioco. Le geometrie sono originali e procedurali. La ricostruzione è illustrativa: altezze, finestre, colori, balconi e arredi non sono un rilievo architettonico.

## Monumenti ed edificio scolastico

| Elemento | Posizione | Riferimento di aspetto e identità |
| --- | --- | --- |
| Chiesa dei Santi Pietro e Paolo | Impronta OSM way **417795500**; facciata sul bordo occidentale dell'impronta | [Scheda e fotografia del Comune](https://www.comune.volpiano.to.it/it-it/vivere-il-comune/cosa-vedere/chiesa-dei-ss-pietro-e-paolo-sec-xviii-6546-1-e97d075f8df542807dc69388bf3a773c). Interpretazione con facciata a salienti, rosone, portali e pinnacoli. Dimensioni verticali approssimate. |
| Municipio | Impronta OSM way **897476177**, affaccio meridionale su Piazza Vittorio Emanuele II | [Scheda e fotografia del Comune](https://comune.volpiano.to.it/it-it/vivere-il-comune/cosa-vedere/palazzo-comunale-ex-casa-famiglia-gedda-23575-1-79bf58d4751da43d74fc4f39a15a51b6). Persiane verdi, balcone centrale, iscrizione e bandiera semplificati. Il pin comunale e l'indirizzo nella mappa non coincidono precisamente con l'impronta: si conserva la geometria OSM. |
| Plesso di Via Trieste | Impronta OSM way **215468999**, `building=school`; punto mappa scolastico **45.1993144, 7.781281**, vicino al fronte occidentale | [Istituto Comprensivo](https://www.icvolpiano.edu.it/luogo/scuola-primaria-guglielmo-da-volpiano/), relativo [collegamento mappa](https://www.google.com/maps/dir/'45.1993144,7.781281'/@45.1993144,7.781281,15z?hl=it), [documento comunale del plesso condiviso](https://www.comune.volpiano.to.it/it-it/download/relazione-tecnica-illustrativa-42933-2-1209-58ec93f0ca352f412d7fb9ea9a6b658b). L'associazione dell'impronta al plesso deriva dall'incrocio di questi dati. Modello basso con finestre e insegna per primaria e infanzia; facciate e copertura sono segnaposto stilizzati. Il pin non certifica un cancello o un ingresso carrabile. |

I monumenti restano nelle posizioni reali, fuori dal tragitto dorato dove necessario. Non sono nuove destinazioni missione. Il plesso è compreso interamente nel diorama, senza spostarlo per farlo rientrare nei limiti precedenti.

## Strade e arredi

Secondo estratto Overpass: **2026-10-17T05:34:25Z**, stessa bounding box della Fase 2. `DETAIL_QUERY` in `tools/import_osm.py` richiede attraversamenti, semafori, alberi, panchine e scuole; i dati sono salvati in `local/volpiano.details.osm.json`. I 312 punti di dettaglio importati comprendono 225 alberi, 84 attraversamenti e 3 impianti semaforici nell'intero estratto. Viene visualizzata solo la porzione interna al diorama e compatibile con la geometria stradale semplificata.

L'importatore conserva solo ID, tipo e coordinate dei punti. Rigenerare offline con `python tools/import_osm.py`; aggiornare via rete con `python tools/import_osm.py --download-details`. Non sono necessari download all'avvio del gioco.

- Attraversamenti nelle posizioni dei nodi OSM, orientati secondo il segmento stradale più vicino. La scelta è approssimata agli incroci complessi.
- Due impianti semaforici nel diorama, prossimi ai nodi OSM; il palo viene spostato sul bordo libero più vicino. Mostrano ambra fissa come segnaposto, senza sfida o precedenze attive.
- Alberi OSM mantenuti solo se non ricadono su strade o edifici nella semplificazione. Altri alberi sono decorativi.
- Lampioni, panchine, fioriere, cestini e auto ferme aggiunti lungo il percorso sono **arredi illustrativi**, non oggetti censiti. Il posizionamento evita carreggiate e impronte edilizie. Le auto hanno collisioni; le piccole decorazioni non bloccano il mezzo.
- Le targhe stradali riportano nomi OSM; posizione del palo e aspetto sono illustrativi. Non sono stati inventati esercizi commerciali su proprietà reali.
- Tetti in terracotta, falde sulle impronte quadrangolari compatibili, persiane e balconi richiamano l'architettura piemontese. Non vengono ricostruite abitazioni private da fotografie.

Dettagli ripetuti raggruppati in **32 MultiMesh**, con 158.541 istanze nel diorama pubblico corrente; edifici e monumenti sono nodi separati. Questa organizzazione riduce le chiamate di disegno dei dettagli, ma non equivale a un benchmark o alla certificazione di 60 FPS a 1080p.

Restano aperti: accesso scolastico e ordinanza della Fase 2, quote dei ponti, ulteriori punti riconoscibili, verifica manuale di guida e benchmark hardware. Parchi, minigiochi e collezionabili appartengono alla Fase 4.
