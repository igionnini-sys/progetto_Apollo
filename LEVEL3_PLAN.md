# Livello 3 · Gli attrezzi di Mario — proposta di sviluppo

Stato: **proposta, nessun codice scritto**. Le parti segnate come *ipotesi* sono mie e vanno confermate. L'unica informazione data finora è "livello 3 = attrezzi con Mario"; il resto è costruito sui sistemi già presenti nel livello 1 (portafoglio) e nel livello 2 (Gino).

## 1. Idea in breve

Apollo è il furgone di un elettricista. Mario (*ipotesi*: un artigiano amico del nonno, con un furgone o un'officina) ha bisogno di attrezzi sparsi per Volpiano prima che arrivi la pioggia. Il livello è **cooperativo e rilassato**, il contrario della gara con Gino: si ritirano gli attrezzi in più punti, si trasportano senza farli cadere e si consegnano a Mario.

Perché funziona dopo il livello 2: gli attrezzi che Apollo lanciava come oggetti (forbici, trapano, multimetro, batteria, guanti) diventano qui il carico da proteggere. Tono: gentile, adatto a una bambina, senza punizioni lunghe.

## 2. Meccaniche (*ipotesi*)

- **Tappe di ritiro**: 4 punti sul percorso (per esempio ferramenta, magazzino, cantiere, casa di un amico). A ogni punto ci si ferma sul cerchio, come nelle soste della Missione Scuola, e si carica un attrezzo.
- **Carico stabile**: un indicatore mostra quanto sono ben legati gli attrezzi. Dossi, frenate brusche e curve veloci lo abbassano un po'; a zero cade un attrezzo, che si raccoglie tornando indietro di pochi metri. Nessun fallimento: al massimo si perde tempo.
- **Guida gentile premiata**: la guida dolce ricarica l'indicatore. È coerente con "Guida tranquilla" e con la medaglia "Pilota gentile".
- **Consegna a Mario**: sosta finale precisa nel cerchio davanti all'officina. Stelle in base a attrezzi consegnati, soste precise e nessun attrezzo caduto.
- **Meteo**: nuvole che si scuriscono lungo il percorso, con pioggia leggera solo negli ultimi metri. Pura atmosfera; con "Movimenti ridotti" niente gocce animate.
- **Mario**: personaggio con battute ai ritiri e alla consegna, come Gino. Se è un furgone, modello originale in stile cartoon.

## 3. Zona e percorso (*da decidere con gli screenshot*)

Proposta: partire dal centro di Volpiano e arrivare vicino alla ferramenta lungo la SP39 (nelle tue foto si vede "Ferramenta" a Via Torino/SP39), così il livello riusa il tratto già costruito per la gara ma in senso inverso e con soste. Serve almeno una zona nuova: servono foto di 3 o 4 vie secondarie con ingressi per le soste. Il percorso va generato con uno script come `tools/build_race_route.py`.

## 4. Riuso del codice

| Esistente | Uso nel livello 3 |
|---|---|
| `story_mission.gd` | soste sui cerchi, stelle, dialoghi agli eventi |
| `item_pickup.gd` | forma delle cassette degli attrezzi nei punti di ritiro |
| `vehicle_effects.gd` | stato di carico instabile (rallentamento leggero, mai stordimento) |
| `dialogue_player.gd`, `race.json` | nuove battute di Mario in `data/dialogue/` |
| `save_store.gd` | stelle del livello, nuovi traguardi, record |
| cutscene 3D di `main.gd` | presentazione di Mario |

Nuovi moduli previsti: `tool_mission.gd`, `cargo_stability.gd`, `mario_van.gd` (se Mario è un veicolo), `data/levels/level3_tools.json`, `tools/build_tools_route.py`.

## 5. Fasi

| Fase | Contenuto | Verifica |
|---|---|---|
| L3-0 | Scelta del percorso e delle 4 soste dagli screenshot, script di generazione | Percorso percorribile, soste raggiungibili senza manovre difficili |
| L3-1 | Missione a soste con carico: ritiro e consegna | Test da riga di comando: tappe in ordine, consegna finale |
| L3-2 | Carico stabile: indicatore, caduta e recupero degli attrezzi | Test su dosso/frenata: l'indicatore scende, nessun blocco |
| L3-3 | Mario: modello, presentazione 3D, dialoghi | Cattura del modello e dei dialoghi |
| L3-4 | Meteo leggero e rifiniture audio | Rispetto di "Movimenti ridotti"; benchmark a 1080p |
| L3-5 | Stelle, traguardi, salvataggio, documentazione | Test dei salvataggi e dei dialoghi |

## 6. Cosa mi serve da te

1. **Chi è Mario?** Un furgone come Gino, un artigiano a piedi, un'officina? E che rapporto ha con Apollo e con il nonno?
2. **Gli attrezzi**: ti va bene "ritirare e consegnare" con il carico che può cadere, oppure preferisci un altro tipo di gioco (per esempio riparare qualcosa con Apollo)?
3. **Zona e soste**: screenshot delle vie e dei luoghi per i 4 ritiri e per l'officina.
4. **Difficoltà**: tutta tranquilla (nessuna perdita) o con un po' di tensione?
5. **Cutscene**: lo stesso stile del livello 2 (inquadrature 3D)?

## 7. Rischi

- **Carico che cade**: se è fastidioso, si lascia solo l'indicatore e la caduta diventa solo un effetto.
- **Soste su strade strette**: i cerchi vanno messi dove si può fermare senza ostacoli.
- **Troppo simile alla Missione Scuola**: differenziare con carico, meteo e il personaggio di Mario.
