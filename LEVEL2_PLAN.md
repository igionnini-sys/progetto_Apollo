# Livello 2 · La sfida con Gino — piano di sviluppo

Stato: **preparazione iniziata**. Scritta e verificata (`tests/race_logic_test.gd`, 11 controlli) la logica pura: `vehicle_effects.gd`, `race_track.gd`, `rival_driver.gd`, `race_mission.gd`, azione `use_item` (tasto E), scheletro `data/levels/level2_race.json`. Fasi L2-0, L2-1 e L2-2 (versione base) fatte: percorso OSM, modello di Gino (`gino_fiorino.gd`), gara collegata a `main.gd`/HUD con voce di menu "Sfida con Gino" (test `tests/race_test.gd`). L2-3 fatta: strisce turbo sulle rette, partenza lanciata (W negli ultimi 0,9 s), scia (2,2 s dietro Gino = mini-turbo), FOV/linee di velocità/scintille/motore, Gino con frenata in curva, cambio corsia e griglia di partenza affiancata. Strisce ridotte a 3 (una ogni ~320 m). L2-4 fatta con urto "virtuale" lungo il percorso (non fisico), rallentamento del 12% e rimbalzo laterale di 0,45 m. L2-5 fatta (tutti gli 8 oggetti, rigenerazione 8 s). L2-6 fatta: voce "Aiuto in gara" (Più aiuto/Normale/Sfida) nelle impostazioni, adattamento dopo 2 sconfitte (sessione), rubber banding asimmetrico + turbo di rimonta; simulazione `tests/race_balance_test.gd`. L2-7 fatta: presentazione 3D, dialoghi e battute, traguardi, record nel salvataggio e documentazione. Il livello 2 è completo; resta il tuo collaudo a mano e il livello 3. Si basa sul piano generale a livelli (livello 1 portafoglio, livello 2 Gino, livello 3 attrezzi con Mario). Il livello 3 si pianifica dopo che il 2 è giocabile.

## 0. Risposte dell'utente (6/11/2026)

- **Formato**: sprint A→B (non più anello). Partenza in Via Trento (all'altezza di Via Ortigara), arrivo in Via Pinetti, passando per Corso Regina Margherita (SP40/SP39). `race_mission.configure(..., closed=false)` con 1 giro.
- **Cutscene**: stile 2, inquadrature 3D dinamiche ma economiche (camera su binari, nessuna animazione complessa).
- **Nomi**: Gino e Mario sono nomi inventati di veicoli, vanno bene nei file del progetto.
- **L2-0**: `tools/build_race_route.py` genera in `data/levels/level2_race.json` un percorso di 1033 m (39 punti, ~70 s a 15 m/s), con 3 punti di controllo, 4 strisce turbo e 7 cassette. Da rivedere: una curva a 116° a circa 190 m (incrocio Via Trento/Circonvallazione) e una a 52° all'arrivo; larghezza minima OSM 6 m.

## 1. Decisioni già prese

- **Zona**: tra Via Trento e il centro di Volpiano. Il tracciato preciso si sceglie dopo gli screenshot delle vie (vedi §9).
- **Avversario**: Gino, Fiorino rosso del fruttivendolo. Nessun altro veicolo e nessun NPC: in pista ci sono solo Apollo e Gino.
- **Collisioni**: Apollo e Gino si urtano davvero, ma in modo morbido (vedi §5).
- **Oggetti trovati sul percorso**:
  - Apollo, furgone di un elettricista, lancia forbici, multimetri, trapani.
  - Gino lancia frutta.
  - Per lanciare bisogna prima raccogliere l'oggetto per strada.
- **Difficoltà**: una sola, regolabile dalle impostazioni. Adatta a una bambina, ma non noiosa.
- **Guida più divertente**: boost, turbo e feedback più vivaci, descritti in §4. Valgono anche per gli altri livelli.

## 2. Obiettivo di gioco

Battere Gino in gara. L'esperienza deve essere: partenza con conto alla rovescia, sorpassi, oggetti da raccogliere e lanciare, turbo, arrivo ravvicinato. Perdere non punisce: la rivincita è immediata.

Proposta di formato, da confermare con gli screenshot: **circuito ad anello, 2 giri**, circa 600–800 m a giro, quindi 40–50 secondi a giro e 2 minuti scarsi di gara. Un anello permette di riusare gli oggetti, tiene Apollo e Gino sempre vicini e rende facile calcolare le posizioni. Lo sprint A→B resta come alternativa.

## 3. Livello di sfida (facile ma non noioso)

- **Gino**: velocità media circa il 92–95% della massima di Apollo senza turbo. Per vincere con comodo serve usare turbo e oggetti, ma non è necessario guidare perfettamente.
- **Rubber banding morbido**: se Gino è troppo avanti rallenta un po', se è troppo indietro accelera un po'. La distanza massima è circa 40 m, così la gara resta sempre aperta.
- **Colpi**: ogni colpo di Gino costa circa 1,2–1,5 s. Nessun danno e nessuna eliminazione. L'effetto è un'animazione divertente (capriola, schizzo di frutta), mai uno stop lungo.
- **Adattamento automatico**: dopo due sconfitte di fila Gino diventa un po' più lento. Dopo una vittoria larga torna al valore normale. Non viene mostrato al giocatore.
- **Impostazione**: voce "Aiuto in gara" con tre livelli (Più aiuto / Normale / Sfida). Il livello normale è quello descritto sopra. Il default può essere cambiato anche per Gino.
- **Aiuti alla guida**: se Apollo va fuori percorso per più di 25 m, riporta in pista con l'ultimo punto di controllo (la funzione di riposizionamento esiste già).

## 4. Guida più divertente (boost e feedback)

Da realizzare una volta sola e riusare in ogni livello.

- **Strisce turbo** sulla strada: un passaggio dà un turbo di circa 1,5 s con velocità fino a circa 22 m/s.
- **Partenza lanciata**: se si accelera nel momento giusto del "Via!", si ottiene un mini-turbo.
- **Scia**: stando dietro Gino si ottiene un piccolo bonus di velocità e si ricarica un po' di turbo.
- **Oggetti turbo**: la batteria raccolta per strada dà un turbo da usare quando si vuole, con un solo tasto.
- **Feedback**: campo visivo più largo e linee di velocità, suono del motore più acuto, fari e scintille, tremolio leggero. Tutto disattivabile con "Movimenti ridotti".
- **Un solo tasto aggiuntivo**: `use_item` (tastiera e controller). I turbo delle strisce sono automatici, per non complicare il comando a una bambina.
- **Livello 1**: l'idea è riusare le monete, per esempio 10 monete danno un piccolo turbo. Da decidere dopo aver provato.

## 5. Collisioni fra Apollo e Gino

- Gino è un `CharacterBody3D` guidato dall'IA lungo il percorso, con la stessa maschera di collisione di Apollo verso il mondo. Nuovo livello fisico "veicoli da gara" per l'urto reciproco.
- **Urto morbido**: scambio di una piccola quantità di velocità, entrambi rallentano di circa il 15%, rimbalzo laterale limitato. Mai testacoda, mai blocco.
- Dopo un urto Gino ritorna alla sua corsia con una piccola correzione, così non resta incastrato.
- Non ci sono altri veicoli o NPC da evitare.
- **Nota tecnica**: il muro dell'IA è la polilinea del percorso. Gino non deve dipendere dalla fisica per restare in strada.

## 6. Oggetti

**Dove**: sul percorso ci sono due tipi di oggetti a terra.
- **Cassette degli attrezzi** (per Apollo, la forma è una scatola rossa con un fulmine): contengono l'oggetto.
- **Casse di frutta** (per Gino).
- Ogni giocatore raccoglie solo i suoi, per renderli riconoscibili. Si rigenerano dopo alcuni secondi. Circa uno ogni 120–150 m.

**Oggetti di Apollo** (si ottiene un oggetto a caso, pesato a favore di chi è indietro):

| Oggetto | Come funziona | Effetto su Gino |
|---|---|---|
| Forbici | Lanciate dritte in avanti, veloci | Capriola, circa 1,2 s |
| Multimetro | Lento, a ricerca verso Gino davanti | Corto circuito, velocità dimezzata per circa 2 s |
| Trapano | Onda d'urto vicino ad Apollo, raggio circa 12 m | Gino "trema" e perde velocità, anche se è dietro |
| Guanti isolanti | Scudo per circa 5 s | Blocca un colpo di frutta |
| Batteria | Turbo manuale | Nessuno |

**Oggetti di Gino**:

| Oggetto | Come funziona | Effetto su Apollo |
|---|---|---|
| Pomodoro | Lanciato dritto in avanti | Schizzo sul parabrezza e piccola perdita di velocità |
| Arancia | Rimbalza due volte | Come il pomodoro |
| Anguria | Rotola all'indietro | Capriola, circa 1,2 s |

Tutti gli effetti sono buffi e innocui. Nessuna di queste cose danneggia Apollo.

## 7. Moduli e file previsti

Nuovi file in `scripts/gameplay/` (e `scripts/vehicles/` per i veicoli):

- `race_mission.gd`: sottoclasse di `LevelMission`, con conto alla rovescia, punti di controllo in ordine, giri, posizioni e arrivo.
- `rival_driver.gd`: IA di Gino. Segue la polilinea con un profilo di velocità in curva e una corsia laterale variabile. Usa gli oggetti con un piccolo ritardo.
- `gino_fiorino.gd`: modello di Gino (Fiorino rosso con casse di frutta). Geometria originale, nessuna livrea reale.
- `item_system.gd`, `item_pickup.gd`, `projectile.gd`: oggetti e proiettili, condivisi da Apollo e Gino.
- `boost_pad.gd`, `vehicle_effects.gd`: strisce turbo e stati (turbo, scudo, stordimento) applicabili a entrambi i veicoli.
- `tools/build_race_route.py`: genera percorso, punti di controllo, strisce e cassette dal grafo OSM già presente, come `build_story_route.py`.
- `data/levels/level2_race.json`: dati del livello (percorso, giri, posizioni di oggetti e strisce, dialoghi).
- Modifiche a `apollo.gd` (moltiplicatore di velocità, stati, `use_item`), `controls.gd` (nuova azione), `hud.gd` (interfaccia di gara), `audio.gd` (suoni), `save_store.gd` (risultati del livello 2).

## 8. Fasi

Prerequisito: Fase A del piano generale (livelli come dati, con il livello 1 identico a oggi).

| Fase | Contenuto | Verifica |
|---|---|---|
| L2-0 | Scelta del tracciato dagli screenshot, script di generazione, primo anello vuoto | Il percorso è percorribile nella direzione giusta, senza punti stretti |
| L2-1 | Gino: modello e IA che completa 2 giri da solo | Test da riga di comando: Gino arriva entro il tempo atteso, senza uscire di strada |
| L2-2 | Gara base: conto alla rovescia, punti di controllo, giri, posizioni, arrivo, interfaccia | Una gara senza oggetti giocabile e vincibile |
| L2-3 | Boost: strisce, partenza lanciata, scia, feedback visivo e sonoro | Il turbo funziona e rispetta "Movimenti ridotti" |
| L2-4 | Collisioni morbide fra Apollo e Gino | Test di urto: nessun blocco, nessun testacoda |
| L2-5 | Oggetti: cassette e casse, forbici, multimetro, trapano, guanti, batteria, frutta di Gino | Test per ogni effetto e per la rigenerazione |
| L2-6 | Equilibratura: rubber banding, adattamento dopo sconfitte, impostazione "Aiuto in gara" | Simulazioni con guida automatica di Apollo a bassa e alta abilità: la vittoria è facile ma non scontata |
| L2-7 | Storia: dialoghi, battute di Gino, traguardi ("Battuto Gino", "Gara pulita"), salvataggio, documentazione | Test dei salvataggi e dei dialoghi |

Le cutscene fra i livelli (inquadrature 3D con piccola animazione) si inseriscono nella fase A2 e coprono la presentazione di Gino prima della gara.

## 9. Cosa mi serve da te

1. **Screenshot del percorso e delle vie** tra Via Trento e il centro, come hai proposto. Mi interessa: larghezza delle strade, sensi unici, incroci stretti, rotonde, dossi, zone con parcheggi o pali sul bordo.
2. **Conferma del formato**: anello a 2 giri (proposta) oppure sprint A→B.
3. **Cutscene**: stile 1 (slide statiche) o 2 (inquadrature 3D con piccola animazione, mia raccomandazione)?
4. I nomi Gino e Mario vanno bene nei file del progetto, oppure preferisci metterli solo in `local/family.json` come i nomi della famiglia?

## 10. Rischi

- **Strade strette**: la guida a velocità di gara (fino a circa 22 m/s con il turbo) è più impegnativa della guida gentile. Servono limiti dedicati e un percorso largo abbastanza.
- **Fuori pista**: non so ancora se tutti gli edifici hanno collisioni. Se mancano, servono guardrail invisibili lungo il percorso, oltre al riposizionamento automatico.
- **Complessità degli oggetti**: il multimetro a ricerca e le collisioni sono le parti più fragili. In caso di ritardi si parte con oggetti dritti e si aggiunge la ricerca dopo.
- **Prestazioni**: proiettili, scintille e un secondo veicolo dettagliato aumentano il costo. Controllare con il benchmark esistente a 1080p.
