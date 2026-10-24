# Apollo: riferimento del veicolo

Configurazione confermata dall'utente il 17 ottobre 2026: **Fiat Ducato 2010, 2.2 MultiJet, 100 PS / 74 kW, codice 4HV, Euro 4; passo medio e tetto alto**. Nel progetto è identificata come **L2H2 / MH2**, generazione X250. Questi dati sono indipendenti dal controller arcade: accelerazione e velocità di gioco non simulano le prestazioni del mezzo reale.

## Proporzioni e aspetto

La tabella del manuale Fiat, sezione Dimensioni, pagina stampata 241, riporta per MH2 passo 3450 mm, lunghezza 5413 mm, altezza a vuoto 2524 mm e larghezza carrozzeria 2050 mm. È consultabile nella [copia del manuale Fiat ospitata da CarManualsOnline](https://www.carmanualsonline.info/amp/fiat-ducato-2010-owner-handbook-in-english/25). Sono misure di riferimento con pneumatici standard; specchi e dettagli sporgenti non sono compresi nella larghezza della carrozzeria. Il modello usa queste proporzioni, senza rappresentare un rilievo dell'esemplare personale.

La [presentazione originale Fiat Professional del 2006](https://www.media.stellantis.com/it-it/fiat-professional/press/nuovo-fiat-ducato-2) documenta questa generazione, il 2.2 MultiJet 100 CV Euro 4, il parabrezza inclinato e il paraurti in tre parti. Il modello riprende il frontale precedente al restyling 2014, con fari obliqui, calandra centrale, specchi divisi, porta scorrevole destra, passaruota aperti e portelloni posteriori con fanali verticali.

Per confrontare le forme sono state consultate fotografie di veicoli del 2010 nelle schede [Proxyparts](https://www.proxyparts.fr/vehicules/donnees/8228689/epave-fiat-ducato-2010/) e [Kleyn Vans](https://www.kleynvans.com/en/vehicle/details/278699/FIATDUCATO2.2). Le fotografie di lavoro rimangono in `local/` e non sono distribuite.

Per la successiva ricostruzione del muso è stata consultata anche una [fotografia frontale di un Ducato del 2010](https://www.kleinanzeigen.de/s-anzeige/fiat-ducato-bj-2010/3449056403-216-6417), il 18 ottobre 2026. Ha permesso di correggere altezza della griglia, fascia bianca verniciata, sagoma dei fari, prese d'aria e giunti del paraurti. La copia di riferimento resta in `local/ducato-x250-front-reference.jpg`, esclusa dalla distribuzione. Le geometrie ricostruite sono originali; nessuna fotografia viene usata come texture del mezzo.

Dal 18 ottobre 2026 carrozzeria, cabina e ruote derivano dal modello **2014 Fiat Ducato di razor24, CC BY 4.0**. Sono adattati passo, scala e altezza; le ottiche del restyling e il muso originale sono rimossi e sostituiti da superfici X250, griglia, fari con riflettori e lenti. Materiali PBR originali per vernice, plastiche e pneumatici; sedili, cruscotto e volante della base integrati con i due occupanti. [Crediti, fonte, modifiche e licenza](../../assets/vehicles/CREDITS.md).

Il risultato è più dettagliato del modello procedurale precedente, ma rimane un adattamento: pannelli e tetto derivano da una carrozzeria differente, il frontale è ricostruito da riferimenti e non da CAD. Non è una scansione fotogrammetrica, né una replica certificata del 2010 o dell'esemplare personale. Città e personaggi restano stilizzati.

Vernice bianca prevista dalla specifica del progetto; allestimento, vetri del vano di carico, accessori, cerchi e dettagli personali restano interpretazioni. Le targhe riportano APOLLO e non un identificativo reale. Scritta FIAT ed emblema semplificato sono geometrie originali; nomi e marchi appartengono ai rispettivi titolari, senza affiliazione.

## File e verifica

Per il posteriore, il 20 ottobre 2026 sono state confrontate la [vista dritta](https://www.njuskalo.hr/image-w920x690/dostavna-vozila/fiat-ducato-l2h2-slika-191865205.jpg) e la [vista a tre quarti](https://www.njuskalo.hr/image-w920x690/dostavna-vozila/fiat-ducato-l2h2-slika-191865220.jpg) di un [Ducato L2H2 del 2010](https://www.njuskalo.hr/dostavna-vozila/fiat-ducato-l2h2-oglas-40202427). Le copie di lavoro restano in `local/ducato-x250-rear-reference.jpg` e `local/ducato-x250-rear-quarter-reference.jpg`; non sono texture né asset distribuiti. Il nuovo `scripts/vehicles/ducato_x250_rear.gd` ricostruisce le superfici dei due portelloni, l'invaso targa, la maniglia, i marchi semplificati e le ottiche. Il gancio traino e gli adesivi dell'esemplare fotografato non sono aggiunti al veicolo di gioco. La fedeltà riguarda queste fotografie di confronto, non dettagli personali non documentati.

`tests/vehicle_capture.gd` comprende anche `retro-dritto`, `retro-dettaglio` e `retro-frenata`, con suffisso `-opengl` per Compatibility. `tests/vehicle_detail_test.gd` verifica il gioco effettivo tra i portelloni, il dislivello dell'incavo targa e l'attivazione dei tre stop.

- `apollo.json`: identità e dimensioni dichiarate.
- `assets/vehicles/ducato_base.glb`, `scripts/vehicles/realistic_ducato.gd`: base attribuita e adattamento metrico, con geometria condivisa tra le istanze.
- `scripts/vehicles/ducato_x250_front.gd`, `vehicle_mesh.gd`, `apollo_visual.gd`: frontale ricostruito, ottiche incassate, occupanti e animazioni.
- `scripts/vehicles/vehicle_studio.gd`: vetrina con luci neutre e ambiente di riflessione procedurale, separata dalla luce della città.
- `scenes/vehicles/apollo.tscn`: collider aggiornato a 2,05 × 2,524 × 5,413 m.
- Menu **Apollo da vicino**: viste anteriore, laterale e posteriore in uno spazio dedicato, con il mondo di gioco in pausa.
- `tests/phase6_test.gd`: controlla versione, passo geometrico, collider, altezza effettiva del tetto, normali e occupanti. `tests/vehicle_detail_test.gd` verifica anche aperture della lamiera con raggi, gomme, fari, freni, ruote e sterzo. `tests/vehicle_capture.gd` salva sei viste diurne e due a luce bassa, anche con `--rendering-method gl_compatibility`; `tests/phase6_capture.gd` verifica l'interfaccia e la vetrina.
