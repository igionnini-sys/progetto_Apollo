# Piano di sviluppo

Seguire `redme.txt`, mantenendo ogni milestone avviabile e aggiornando `PROJECT_STATUS.md` durante l'implementazione. Non effettuare commit senza richiesta.

| Fase | Obiettivo | Criterio di uscita |
| --- | --- | --- |
| 1 — completata | Apollo guidabile, strada di prova, camera, HUD e comandi | Importazione senza errori, 18 controlli superati, verifica visiva e istruzioni riproducibili |
| 2 — in corso | Pipeline OpenStreetMap e primo percorso a Volpiano | Pipeline e percorso esplorativo implementati; resta da verificare accesso scolastico e partenza privata |
| 3 — implementata sul diorama pubblico | Cittadina cartoon | Facciate, tetti, arredi, segnaletica, chiesa, municipio e plesso scolastico; generazione e catture validate |
| 4 — prima milestone implementata | Parchi reali e attività | Due località documentate, giochi procedurali e “La Stella Perduta”; tre località da verificare |
| 5 — versione racconto implementata | Storia e Missione Scuola | Personaggi configurabili con cinture, dialoghi, guida di 669 m, stelle, semaforo, epilogo scolastico e sfida bonus; tragitto privato definitivo ancora subordinato alla Fase 2 |
| 6 — implementata sul PC di sviluppo | Rifinitura | Ducato L2H2, audio, salvataggio robusto, impostazioni e collezione; rifinitura grafica Forward+ con shader procedurali e interfaccia ridisegnata; tutte le verifiche e benchmark 1080p ripetuti. Restano controller fisico e PC di destinazione |
| 7 | Distribuzione Windows | Esportazione autonoma, icona, crediti e checklist su macchina di destinazione |

## Stato dopo la rifinitura locale della Fase 6

Implementati estratto offline, importatore Python, proiezione locale, grafo diretto, percorso esplorativo, edifici sulle impronte OSM e selezione ambiente nel menu. Vedere `data/map/SOURCES.md`. Per concludere la Fase 2 occorrono verifica dell'ordinanza della strada scolastica, ingresso e sosta consentita, configurazione privata della partenza e prova manuale del percorso completo.

Su richiesta dell'utente si è proseguito con la Fase 3 sul diorama disponibile, mantenendo aperti i punti della Fase 2. Realizzati facciate, tetti, tre luoghi pubblici, vegetazione e arredi, con fonti in `data/map/TOWN_REFERENCES.md`.

La Fase 4 dispone di due gite, Madonna delle Grazie e San Grato, con attività facoltativa e raccolta della partita; fonti in `data/map/PARK_REFERENCES.md`. Prima di estendere il catalogo verificare i perimetri di De Gasperi, Pertini e Riviera.

La Fase 5 offre la Missione Scuola in versione racconto, con personaggi, dialoghi, tre stelle, semaforo e sfida di parcheggio. Il finale a piedi è narrato e l'accesso carrabile rimane escluso; dettagli in `STORY_NOTES.md`. La Fase 6 ha aggiunto Ducato L2H2, salvataggi, impostazioni, audio e collezione, con 175 verifiche automatiche superate e benchmark a 1080p. Restano controller fisico e PC di destinazione; la prossima fase principale è la 7, esportazione Windows. La verifica geografica della Fase 2 rimane necessaria per il tragitto privato definitivo.

Prima di generare il percorso scolastico definitivo, verificare gli accessi stradali all'ingresso. Non dedurre la conformazione dell'abitazione privata e non pubblicare l'indirizzo di partenza. Mantenere configurazione privata esclusa dal versionamento, origine geografica e scala esplicite, estratti offline e attribuzione delle fonti.

Il grafo stradale dovrà rispettare direzioni e accessibilità delle vie, con navigazione su strada. Non rappresentare il circuito di Fase 1 come geografia reale. Verificare separatamente posizioni dei parchi e dei monumenti: non spostarli sul percorso per comodità.
