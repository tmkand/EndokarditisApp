## Verbindungsmethoden zur MySQL-Datenbank einschließlich Passwort-Überprüfung
## Falls andere Datenbank oder Passwort-Überprüfung gewünscht, müssen die hier aufgeführten Funktionen
## entsprechend ersetzt werden.
## Copyright (C) 2022 Timm M. Kandaouroff

library (RMySQL)
library (bcrypt)

# Zugangsdaten zur MySQL-Datenbank
options(
  mysql = list(
    "host" = "127.0.0.1",
    "port" = 8889,
    "dbName" = "endocarditisapp",
    "user" = "endokarditis",
    "password" = "karsuc-poncav-warbU2"
    # In der Produktivversion Nutzung von White-Box-Cryptography
  )
)


## Falls ein neuer Benutzer angelegt werden soll, kann der Passwort-Hash in der Konsole mit dem Befehl
## bcrypt::hashpw("MeinPasswort", salt = bcrypt::gensalt())
## erzeugt werden, wobei "MeinPasswort" durch das gewünschte Passwort zu ersetzen ist.


authenticateUser <- function(benutzername, passwort) {
  # Authentifiziert Benutzer anhand von übergebenem Benutzernamen und Passwort. Rückgabewert FALSE/TRUE (Authentifizierung Erfolgreich)
  # Benutzer wird in globale Variable "benutzer" geladen, der zugehörige Patient in die globale Variable "patient"
  benutzer <<- NULL
  
  # Abfangen ungültiger Aufrufparameter
  if ((benutzername == "*") || (nchar(benutzername) < 4)) {
    cat(file = stderr(), paste(Sys.time(), " Ungültiger Benutzername"))
    return (FALSE)
  }
  
  # SQL-Abfrage
  tabelle <- "benutzer"
  db <-
    dbConnect(
      MySQL(),
      dbname = options()$mysql$dbName,
      host = options()$mysql$host,
      port = options()$mysql$port,
      user = options()$mysql$user,
      password = options()$mysql$password
    )
  query <-
    sprintf("SELECT * FROM %s WHERE benutzername='%s'",
            tabelle,
            benutzername)
  benutzer <<- dbGetQuery(db, query)
  dbDisconnect(db)
  
  # Authentifizierung und Fehlerbehandlung
  if (nrow(benutzer) > 0) {
    # da "benutzername" primary key ist, kann maximal 1 Benutzer zurückgegeben werden
    tryCatch({
      check = checkpw(passwort, benutzer$passwort_hash) # bcrypt-Funktion vergleicht das eingegebene Passwort mit dem geshashten Passwort der Benutzerdatenbank
      if (!check) {
        benutzer <<- NULL
        return(FALSE)
      } else {
        retrievePatient(benutzer$patienten_id)
        return(TRUE)
      }
    }, error = function(e) {
      return(FALSE)
    }, finally = {
      benutzer$passwort_hash <<-
        NULL # Passwort-Hash wird nicht mehr benötigt
    })
  } 
  return (FALSE)
}


retrievePatient <- function(patientID) {
  # Abrufen des Patientendatensatzes aus der MySQL - Datenbank anhand der Patienten-ID
  
  # Abfangen ungültiger Aufrufparameter
  if (!is.integer(patientID)) {
    stopApp(
      "KRITISCHER FEHLER! Es wurde eine ungültige Patienten-ID an die Funktion retrievePatient übergeben"
    )
    # In der Produktivversion ist ein "weicheres" Abfangen des Fehlers mit Weiterleitung an eine Support-Seite anzustreben
  }
  patient <<- NULL
  
  # SQL-Abfrage
  tabelle <- "patienten"
  db <-
    dbConnect(
      MySQL(),
      dbname = options()$mysql$dbName,
      host = options()$mysql$host,
      port = options()$mysql$port,
      user = options()$mysql$user,
      password = options()$mysql$password
    )
  query <-
    sprintf("SELECT * FROM %s WHERE id='%s'", tabelle, patientID)
  patient <<- dbGetQuery(db, query)
  dbDisconnect(db)
  
  if (nrow(patient) == 0) {
    stopApp(
      "KRITISCHER FEHLER! Es wurde kein Patient für diesen Benutzer gefunden. Bitte kontaktieren Sie den Support"
    )
    # In der Produktivversion ist ein "weicheres" Abfangen des Fehlers mit Weiterleitung an eine Support-Seite anzustreben
  }
}


retrieveDiaryEntry <- function(PatientID, datum) {
  # Abfrage eines einzelnen Tagebucheintrags (Patientenzugriff)
  
  # Abfangen ungültiger Aufrufparameter
  if ((is.null(datum)) || (!is.integer(PatientID))) {
    return
  }
  
  entry <<- NULL
  # SQL-Abfrage
  tabelle <- "tagebuch_eintraege"
  db <-
    dbConnect(
      MySQL(),
      dbname = options()$mysql$dbName,
      host = options()$mysql$host,
      port = options()$mysql$port,
      user = options()$mysql$user,
      password = options()$mysql$password
    )
  query <-
    sprintf(
      "SELECT * FROM %s WHERE patienten_id='%s' AND datum=%s",
      tabelle,
      PatientID,
      format(datum, "'%Y-%m-%d'")
    )
  suppressWarnings({
    entry <<- dbGetQuery(db, query)
  })
  dbDisconnect(db)
  if (nrow(entry) == 0) {
    return (NULL)
  } else if (nrow(entry) > 1) {
    stopApp(
      "Datenbank-Integrität beeinträchtigt. Es befindet sich mehr als ein Eintrag in der Datenbank zu diesem Patienten und diesem Datum. Bitte kontaktieren Sie xxxxxxx"
    )
    # In der Produktivversion ist ein "weicheres" Abfangen des Fehlers mit Weiterleitung an eine Support-Seite anzustreben
  } 
}


readAllDiaryEntries <- function(PatientID) {
  # Abfrage aller Tagebucheinträge eines Patienten für den Arztzugriff
  
  # Abfangen ungültiger Aufrufparameter
  if (!is.integer(PatientID)) {
    stopApp(
      "KRITISCHER FEHLER! Es wurde eine ungültige Patienten-ID an die Funktion retrievePatient übergeben"
    )
    # In der Produktivversion ist ein "weicheres" Abfangen des Fehlers mit Weiterleitung an eine Support-Seite anzustreben
  }
  
  # SQL-Abfrage
  tabelle <- "tagebuch_eintraege"
  db <-
    dbConnect(
      MySQL(),
      dbname = options()$mysql$dbName,
      host = options()$mysql$host,
      port = options()$mysql$port,
      user = options()$mysql$user,
      password = options()$mysql$password
    )
  query <-
    sprintf("SELECT * FROM %s WHERE patienten_id='%s'", tabelle, PatientID)
  suppressWarnings({
    entries <<- dbGetQuery(db, query)
  })
  dbDisconnect(db)
  
  # Zusammenfassung / Umformatierung zur Übergabe an das DataTables-Paket
  zeilen = nrow(entries)
  spaltenNamen <-
    c("Datum",
      "Zuletzt geändert",
      "Fieber",
      "Temperatur",
      "Symptome")
  umformatierung <-
    data.frame(
      Datum = character(zeilen),
      Fieber = character(zeilen),
      Temperatur = numeric(zeilen),
      Symptome = character(zeilen),
      Geaendert = character(zeilen)
    )
  colnames(umformatierung) = spaltenNamen
  if (zeilen == 0) {
    return (umformatierung)
  }
  umformatierung$Datum = entries["datum"]
  umformatierung["Zuletzt geändert"] = entries["zuletzt_geaendert"]
  # Fieber Ja/Nein
  umformatierung$Fieber <-
    mapvalues(entries$fieber, c(0, 1), c("Nein", "JA"))
  # Fieberhoehe
  umformatierung$Temperatur <- entries$fieber_temperatur
  # Symptome als String-Liste
  for (row in 1:zeilen) {
    syAcc = c(character(0))
    if (entries$kopfschmerzen[row] == 1) {
      syAcc = c(syAcc, "Kopfschmerzen")
    }
    if (entries$abgeschlagenheit[row] == 1) {
      syAcc = c(syAcc, "Abgeschlagenheit")
    }
    if (entries$appetitlosigkeit[row] == 1) {
      syAcc = c(syAcc, "Appetitlosigkeit")
    }
    if (entries$nachtschweiss[row] == 1) {
      syAcc = c(syAcc, "Nachtschweiss")
    }
    if (entries$muskel_gelenkschmerzen[row] == 1) {
      syAcc = c(syAcc, "Muskel-/Gelenkschmerzen")
    }
    if (length(syAcc) == 0) {
      syText = "keine"
    } else {
      syText = toString(syAcc)
    }
    umformatierung$Symptome[row] = syText
  }
  return (umformatierung)
}


saveDiaryEntry <- function(datum, fieber, temp, symptome) {
  # Speichern des aktuellen Eintrags im Tagebuch des Patienten
  
  # MySQL - Anfrage
  table <- "tagebuch_eintraege"
  db <-
    dbConnect(
      MySQL(),
      dbname = options()$mysql$dbName,
      host = options()$mysql$host,
      port = options()$mysql$port,
      user = options()$mysql$user,
      password = options()$mysql$password
    )
  data <-
    c(
      benutzer$patienten_id,
      format(datum, "'%Y-%m-%d'"),
      sum(1 * (fieber == 1)),
      temp,
      sum(1 * (symptome == 1)),
      sum(1 * (symptome == 2)),
      sum(1 * (symptome == 3)),
      sum(1 * (symptome == 4)),
      sum(1 * (symptome == 5)),
      sqlSysDate()
    )
  names(data) <-
    c(
      "patienten_id",
      "datum",
      "fieber",
      "fieber_temperatur",
      "kopfschmerzen",
      "abgeschlagenheit",
      "appetitlosigkeit",
      "nachtschweiss",
      "muskel_gelenkschmerzen",
      "zuletzt_geaendert"
    )
  if ((is.na(data["fieber_temperatur"])) || (fieber == 0)) {
    data["fieber_temperatur"] = "NULL"
  }
  query <-
    sprintf(
      "SELECT * FROM %s WHERE patienten_id='%s' AND datum=%s",
      table,
      benutzer$patienten_id,
      format(datum, "'%Y-%m-%d'")
    )
  
  entry <<- dbGetQuery(db, query)
  
  if (nrow(entry) == 0) {
    # Noch kein Eintrag gespeichert -> INSERT
    query <- sprintf(
      "INSERT INTO %s (%s) VALUES (%s)",
      table,
      paste(names(data), collapse = ", "),
      paste(data, collapse = ", ")
    )
  } else {
    # Änderung eines bereits bestehenden Eintrags -> UPDATE
    query <- sprintf(
      "UPDATE %s SET `fieber`='%s',`fieber_temperatur`=%s,`kopfschmerzen`='%s',`abgeschlagenheit`='%s',`appetitlosigkeit`='%s',`nachtschweiss`='%s',`muskel_gelenkschmerzen`='%s', `zuletzt_geaendert`=%s WHERE `id`=%s",
      table,
      sum(1 * (fieber == 1)),
      data["fieber_temperatur"],
      sum(1 * (symptome == 1)),
      sum(1 * (symptome == 2)),
      sum(1 * (symptome == 3)),
      sum(1 * (symptome == 4)),
      sum(1 * (symptome == 5)),
      sqlSysDate(),
      entry$id
    )
  }
  
  dbGetQuery(db, query)
  dbDisconnect(db)
  
}


saveDoctorsEntry <- function(diagnosen, kontaktdaten) {
  table <- "patienten"
  
  db <-
    dbConnect(
      MySQL(),
      dbname = options()$mysql$dbName,
      host = options()$mysql$host,
      port = options()$mysql$port,
      user = options()$mysql$user,
      password = options()$mysql$password
    )
  
  data <-
    c(
      patient$vorname,
      patient$nachname,
      patient$geschlecht,
      patient$vorgeschichte,
      patient$arztkontakt,
      patient$id
    )
  names(data) <-
    c("vorname",
      "nachname",
      "geschlecht",
      "vorgeschichte",
      "arztkontakt",
      "id")
  
  query <- sprintf(
    "UPDATE %s SET `vorgeschichte`='%s', `arztkontakt`='%s' WHERE `id`=%s",
    table,
    diagnosen,
    kontaktdaten,
    patient$id
  )
  
  dbGetQuery(db, query)
  dbDisconnect(db)
}
