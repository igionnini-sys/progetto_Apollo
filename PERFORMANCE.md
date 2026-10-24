# Verifica grafica

## Modello Ducato realistico del 18 ottobre 2026

Nuova base GLB locale (circa 1,28 MiB), geometria adattata e materiali condivisi tra veicolo e vetrina. Il frontale precedente e i suoi generatori inutilizzati sono stati sostituiti. La vetrina usa luci dedicate e uno sky shader di studio, senza sonde di riflessione aggiornate a ogni frame. `tests/vehicle_capture.gd` salva viste effettive del modello, del fianco, del retro, delle ottiche e dei fari accesi; disponibile anche `--rendering-method gl_compatibility`. Queste catture verificano l'aspetto, non misurano gli FPS. Non è stato eseguito un nuovo benchmark isolato: i dati delle revisioni precedenti non descrivono il carico del nuovo modello.

## Facciate e atmosfera del 18 ottobre 2026

La revisione finale contiene 18 MultiMesh cittadini e 231.954 istanze: portoni, cornici e piccoli piazzali sono concentrati lungo i percorsi. La ricerca delle strade vicine usa un indice spaziale; la sua equivalenza alla ricerca completa è verificata su 80 posizioni, con più raggi e punti ai confini delle celle. Importazione editor, catture Forward+/Vulkan e OpenGL e 65 controlli superati.

Il benchmark intermedio, prima dell'indice e della registrazione completa delle impronte, ha osservato 218,6 FPS nel circuito e 45,9 a Volpiano. Erano aperti anche l'editor Godot 4.7 e un'altra istanza di Apollo/Godot 4.6.1: questa misura **non è confrontabile** con i report precedenti e non dimostra una regressione o una soglia hardware. Dati e nota sul carico concorrente in `build/verifica/performance.json`. Non è disponibile una nuova misura finale con il carico grafico isolato.

## Misura storica: seconda revisione del 18 ottobre 2026

Screening dopo la revisione del modello di Apollo e del dettaglio urbano, con lo stesso metodo e hardware descritti sotto: Godot 4.6.1, Forward+/Vulkan, RTX 4080, Ryzen 7 5700X3D, 1920 × 1080, MSAA 4×, ombre e grafica avanzata attive, VSync e limite FPS disabilitati.

| Ambiente | Frame mediano | Frame p95 | FPS mediani | Generazione scena | Chiamate di disegno |
| --- | ---: | ---: | ---: | ---: | ---: |
| Circuito | 2,65 ms | 3,05 ms | 377,6 | 896,6 ms | 2013 |
| Volpiano | 8,89 ms | 9,69 ms | 112,5 | 2692,7 ms | 1633 |

Apollo ha più geometria e parti; la città contiene 231.541 istanze in 15 MultiMesh, oltre alle bordure raccolte in una mesh. La prima revisione del 18 ottobre misurava 405,5 / 94,9 FPS nel circuito / città, con 231.033 istanze. Sono singole esecuzioni brevi: le differenze non dimostrano un miglioramento generale né certificano hardware minimo. Report di questa seconda revisione conservato in `build/backup/facciate-atmosfera-20261018/build/verifica/`; report della prima in `build/backup/modello-dettagliato-20261018/build/verifica/`. Verificate anche catture OpenGL con gli shader di pneumatici e persiane, senza errori; OpenGL non dispone degli effetti SSAO/SSIL di Forward+.

## Misura precedente del 17 ottobre 2026

Screening locale del 17 ottobre 2026 dopo la rifinitura grafica, con Godot 4.6.1, renderer **Forward+ / Vulkan 1.4**, NVIDIA GeForce RTX 4080 e AMD Ryzen 7 5700X3D. Risoluzione 1920 × 1080, MSAA 4×, ombre e **Grafica avanzata** attive (SSAO, SSIL, glow, ombre morbide), VSync e limite FPS disabilitati. Stato dei test isolato dalle impostazioni dell'utente.

| Ambiente | Frame mediano | Frame p95 | FPS mediani | Generazione scena | Chiamate di disegno |
| --- | ---: | ---: | ---: | ---: | ---: |
| Circuito | 2,14 ms | 2,47 ms | 466,4 | 725,1 ms | 1698 |
| Volpiano | 6,40 ms | 6,71 ms | 156,2 | 1286,1 ms | 1157 |

Misura precedente, Compatibility/OpenGL senza effetti avanzati: circuito 2,82 ms (355 FPS), Volpiano 8,12 ms (123 FPS), 2230 chiamate di disegno a Volpiano. Il miglioramento deriva dall'unificazione di strade, muri e tetti in poche mesh e dal raggruppamento dei dettagli per forma e materiale; la generazione della città è più lunga per via di tetti, verde sparso e collider unico. Nel circuito le chiamate crescono per le quattro suddivisioni d'ombra.

I valori del 17 ottobre sono storici; il report corrente è stato sostituito dalle verifiche successive. Il riferimento Compatibility è conservato in `build/verifica/prima/`. Il metodo di `tests/performance_capture.gd` scarta 90 frame di riscaldamento e misura 240 intervalli di presentazione per ambiente. Il percentile 95 indica che il 95% dei campioni ha richiesto quel tempo o meno; non è un FPS minimo.

Nel circuito il mezzo ruota lentamente; in città viene spostato lungo le tappe esplorative e la camera viene riallineata. Fisica e audio restano attivi, ma non si misura una guida umana. I tempi sono intervalli reali fra frame, non timer GPU isolati.

Il risultato sostiene la fluidità su questo computer nelle viste campionate. Non certifica un computer minimo, una GPU integrata, tutte le visuali o sessioni prolungate. Su hardware più lento: disattivare prima **Grafica avanzata**, poi le ombre, e misurare nuovamente. Sui PC senza Vulkan/D3D12 il motore passa automaticamente a OpenGL 3.3: verificata una cattura con `--rendering-method gl_compatibility`, senza errori di shader.

Per riprodurre:

```powershell
& '.tools/godot/Godot_v4.6.1-stable_win64_console.exe' --path . --script tests/performance_capture.gd
```

Non aggiungere `--headless` o `--fixed-fps`; chiudere altri carichi grafici rilevanti. Il test apre una finestra a 1080p e aggiorna il report locale. Ripetere sul PC di destinazione prima del rilascio Windows della Fase 7.
