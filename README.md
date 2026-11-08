# SpeedTracker 🏎️💨

Applicazione iOS nativa creata in **Swift** e **SwiftUI** con design **Liquid Glass**, pensata per monitorare e registrare velocità, accelerazione, forza G e tempi su circuito con calcolo stradale e telemetria su mappa color-coded.

Compilabile direttamente su **GitHub Actions** per la generazione dell'`.ipa` installabile tramite **AltStore**.

---

## 📱 Caratteristiche Principali

- **Home Telemetria**:
  - Velocità istantanea grande in km/h via CoreLocation ad alta precisione.
  - Accelerazione istantanea sotto la velocità con commutazione al volo tra **Forza G ($G$)** e **$m/s^2$**.
  - Monitoraggio live del giro, intertempi e record di velocità max.
- **Mappa Live & Creazione Circuiti**:
  - Switch stile mappa tra **Satellite** e **Solo Strade**.
  - **Mini HUD Velocità** sempre visibile anche fuori dalla Home.
  - Creazione circuito guidata:
    - Tipologia **Anello Chiuso** o **Aperto (Punto A -> Punto B)**.
    - Selezione punto di partenza e anteprima live del tracciato stradale mentre ti muovi.
    - Aggiunta **Checkpoint** intermedi per split-time e settori.
    - "Chiudi Anello" o "Imposta Fine" con calcolo automatico della distanza e stima tempo.
- **Archivio & Analisi**:
  - Lista di tutti i circuiti memorizzati con stima tempo, record (best lap) e distanza.
  - Visualizzazione corse effettuate con collegamento interattivo al rispettivo circuito.
  - **Mappa Color-Coded**: il percorso viene disegnato con un gradiente continuo in base alla velocità (verde per i tratti lenti, arancione per le medie, rosso per le velocità massime).
- **Design Liquid Glass**:
  - Materiali nativi Ultra-Thin Glass scuri con riflessi dinamici, gradienti moderni e feedback aptico.

---

## 🚀 Come Compilare e Installare con AltStore

Non è necessario avere Xcode sul tuo Mac. La pipeline GitHub Actions compila l'app e produce il file `.ipa` pronto:

1. **Collega questo repository a GitHub**:
   ```bash
   git remote add origin https://github.com/TUO-USERNAME/speed.git
   git branch -M main
   git push -u origin main
   ```
2. **GitHub Actions**:
   - Vai nella scheda **Actions** del tuo repository su GitHub.
   - Il workflow `Build AltStore IPA` partirà automaticamente a ogni push o avviabile manualmente da `Run workflow`.
3. **Scarica l'IPA**:
   - Al termine della build, scarica l'artifact `SpeedTracker-AltStore-IPA.zip` e aprilo per trovare `SpeedTracker.ipa`.
4. **Installa con AltStore**:
   - Invia il file `.ipa` al tuo iPhone (AirDrop, iCloud Drive o scaricalo direttamente da Safari).
   - Apri l'app **AltStore** sul tuo iPhone.
   - Vai su **My Apps**, tocca il `+` in alto a sinistra e seleziona `SpeedTracker.ipa`.
   - AltStore firmerà e installerà l'app con il tuo Apple ID!

