# Mercante Infernale — iPhone / GitHub / Codemagic

Progetto iPhone nativo SwiftUI, preparato per il flusso:

**GitHub → Codemagic → IPA → App Store Connect / TestFlight**

## Contenuto

- Progetto Xcode: `MercanteInfernale.xcodeproj`
- Scheme condiviso: `MercanteInfernale`
- Configurazione Codemagic: `codemagic.yaml`
- App icon completa, con ritratto stilizzato
- 63 carte compattate in un solo atlas grafico (`CardsAtlas`) per ridurre drasticamente il numero di file GitHub
- Multiplayer locale iPhone tramite MultipeerConnectivity
- 1 Mercante + 2–7 giocatori (3–8 partecipanti totali)

## Bundle ID già impostato

`com.mif.infernale.iphone`

Prima del primo upload devi creare/registrare questo stesso Bundle ID nel tuo Apple Developer account e creare l'app corrispondente in App Store Connect. Se preferisci un altro Bundle ID, cambialo sia nel progetto Xcode sia in `codemagic.yaml` (`BUNDLE_ID`).

## Caricamento su GitHub senza Mac

1. Crea un repository GitHub vuoto.
2. Estrai questo ZIP sul PC.
3. Nel repository GitHub scegli **Add file → Upload files**.
4. Trascina **tutto il contenuto estratto**, non lo ZIP stesso.
5. Fai Commit.

Questa versione contiene meno di 100 file, quindi evita il problema della precedente versione con un imageset separato per ogni carta.

## Codemagic

1. Aggiungi il repository GitHub a Codemagic.
2. Codemagic deve trovare `codemagic.yaml` nella root.
3. In Codemagic crea/usa il gruppo di variabili `appstore_credentials` con:
   - `APP_STORE_CONNECT_PRIVATE_KEY`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_ISSUER_ID`
4. In **Code signing identities** assicurati che siano disponibili un certificato **Apple Distribution** e un provisioning profile **App Store** compatibili con `com.mif.infernale.iphone`.
5. Avvia il workflow **Mercante Infernale - TestFlight**.

Il workflow crea l'IPA e, se le credenziali App Store Connect sono corrette, lo carica automaticamente su App Store Connect. Dopo l'elaborazione Apple, il build comparirà in TestFlight.

## Nota

Il progetto non richiede `index.html`: è un'app iOS nativa SwiftUI.
