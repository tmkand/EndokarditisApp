## EndokarditisApp
##
## Eine Shiny-Webapplikation zur Erfassung von Symptomen bei ambulant entlassenen Patienten nach Endokarditis
##
## Copyright (C) 2022 by Lukas Herold, Timm Kandaouroff und Lucie Kretzler

library(shiny)
library(DT)
library(plyr)
library(shinymanager)
source("sql.R")
library(RMySQL)


# Vorab-Initialisierung der "leeren" Globalvariablen
patient <<- NULL
benutzer <<- NULL


ui <- navbarPage(
  "EndokarditisApp", id = "tabs",
  windowTitle = "EndokarditisApp",
  
  tabPanel("Start",
           fluidPage(
             uiOutput("welcomeMessage")
           )       
  ),
  
  tabPanel("Tagebuch",
           sidebarLayout(
             sidebarPanel(
               uiOutput("datumsBereich"),
               textOutput("tagebuchGespeichert", container = tags$small),
             ),
             mainPanel(
               NULL,
               uiOutput("tagebuchEintrag")
             )
           )
  ),
  
  tabPanel("Verlauf",
           fluidPage(
             DTOutput("alleEintraege"),
             br(),
             helpText("Änderungen in den Tagebucheinträgen werden erst nach maximal 30 Sekunden sichtbar!"),
           )
  ),
  
  tabPanel("Arztangaben", fluidPage(
    uiOutput("arztangaben")
  )),
  
  tabPanel("Arztkontakt", fluidPage(
    uiOutput("arztkontakt")
  )),
  
)


ui <- secure_app(ui, language = "de") 
# In der Produktivversion Unterstützung anderer Sprachen

## Helfer-Funktionen

sqlSysDate <<- function() {
  format(Sys.Date(), "'%Y-%m-%d'")
}

myDate <<- function(datum) {
  format(as.Date(datum), "%d.%m.%Y")
}


# Generiert ein Text-String, welches den Verfügbarkeitszeitraum für die App ausgibt
appVerfuegbarkeit <<- function() {
  paste(
    "Die Tagebuchfunktion steht zur Verfügung für die Daten vom ",
    myDate(patient$beginn),
    "bis zum ",
    myDate(patient$ende),
    ". Ab dem ",
    format(as.Date(patient$ende) + 90, "%d.%m.%Y"),
    "werden sämtliche Patienten-bezogenen Daten sowie Ihre Benutzerkennung gelöscht."
  )
}

# Generiert ein Text-String mit Anrede, Vor- und Nachnamen des Patienten
getPatientNameWithSalutation <<- function() {
  anrede = switch (patient$geschlecht,
                   "1" = "Herr",
                   "2" = "Frau",
                   "3" = "")
  return(paste(anrede, patient$vorname, patient$nachname))
}


server <- function(input, output, session) {
  
  ## Shiny-Manager Secure-Server Umleitung der Authentifizierungsmethode auf eigene
  ## Methoden mit MySQL-Anbindung
  
  res_auth <- secure_server(
    check_credentials = function(username, password) {
      if (authenticateUser(username, password)) {
        list(
          result = TRUE,
          user_info = list(
            user = benutzer$benutzername,
            something = benutzer$patienten_id
          )
        )
      } else {
        list(result = FALSE)
      }
    }
  )
  
  ## UI-Renderer
  
  # UI-Renderer Start-Tab
  output$welcomeMessage <- renderUI({
    tagList(
      if (benutzer$ist_arzt == 0) {
        # Begrüßungsnachricht für Patient
        tagList(h3(
          paste("Herzlich Willkommen, ",
                getPatientNameWithSalutation())
        ),
        br(), br())
      } else if (benutzer$ist_arzt == 1) {
        # Begrüßungsnachricht für Arzt
        tagList(
          h3("Herzlich Willkommen."),
          strong("Ihr Patient:"),
          br(),
          getPatientNameWithSalutation(),
        )
      }, br(), br(),
      "Herzlichen Dank für die Nutzung der Endokarditis App.",
      br(),
      br(),
      p("Diese App ermöglicht es Patienten, die sich in häuslicher Weiterbehandlung nach einer Endokarditis befinden, 
        körperliches Wohlbefinden oder Symptome täglich zu dokumentieren. Der weiterbehandelnde Arzt kann diese Einträge
        jederzeit einsehen. Dies erleichtert die Arzt-Patienten-Kommunikation und kann die gemeinsame Absprache bezüglich
        erforderlicher Schritte erleichtern."),
      p("Datensicherheit liegt uns sehr am Herzen. Wir verweisen auf die ausführliche Datenschutzerklärung zu unserer App.
        Als Nutzer haben Sie jederzeit ein Anrecht auf"),
      p("- ausschließliche Erfassung von Daten, die für die Funktionalität der App unabdingbar sind."),
      p("- die Möglichkeit des Widerruf Ihrer Einwilligung in unsere Datenschutzerklärung. Ihre Daten werden dann unwiderruflich gelöscht. (Art. 17 DSGVO) "),
      p("- die Übertragung Ihrer Daten in Form einer verschlüsselten JSON- oder CSV-Datei (Art. 20 DSGVO)."),
      em(appVerfuegbarkeit()), br(), br(),
      p("Ihre Daten sind jederzeit nur für Sie und Ihren Arzt einsehbar und werden mit keinem Dritten geteilt.")
    )
  })
  
  # UI-Renderer Text in der Sidebar des Tagebuchs
  speicherDatum <- function(){ 
    renderText({
    retrieveDiaryEntry(benutzer$patienten_id, input$Datum)
    if ((is.null(entry)) || (nrow(entry) == 0)) {
      return ("Für dieses Datum wurde noch kein Eintrag gespeichert")
    } else {
      sprintf(
        "Dieser Eintrag wurde zuletzt am %s bearbeitet.",
        myDate(entry$zuletzt_geaendert)
      )
    }
  })}
  
  output$tagebuchGespeichert <- speicherDatum()
  
  # UI-Renderer für den DatePicker im Tagebuch
  output$datumsBereich <- renderUI({
    retrievePatient(benutzer$patienten_id)
    maxDate = Sys.Date()
    
    if (maxDate > patient$ende) {
      maxDate = patient$ende
    }
    dateInput(
      "Datum",
      label = "Datum",
      format = "dd.mm.yyyy",
      language = "de",
      weekstart = 1,
      min = patient$beginn,
      max = maxDate,
      value = maxDate
    )
  })
  
  # UI-Renderer für die Tagebucheinträge
  output$tagebuchEintrag <- renderUI({
    retrieveDiaryEntry(benutzer$patienten_id, input$Datum)
    list(
      radioButtons(
        "fieber",
        "Fieber",
        choices = list(
          "Ich habe kein Fieber" = 0,
          "Ich habe Fieber" = 1
        ),
        selected = entry$fieber
      ),
      conditionalPanel(
        condition = "input.fieber == 1",
        numericInput(
          "temp",
          "gemessene Körpertemperatur",
          entry$fieber_temperatur,
          min = 35.0,
          max = 42.0,
          step = 0.1
        )
        
      ),
      checkboxGroupInput(
        "symptome",
        "Sonstige Symptome",
        choices = list(
          "Kopfschmerzen" = 1,
          "allgemein Abgeschlagenheit" = 2,
          "Appetitlosigkeit" = 3,
          "Nachtschweiß" = 4,
          "Muskel- oder Gelenkschmerzen" = 5
        ),
        selected = if (nrow(entry) == 0)
          0
        else
          c(if (entry$kopfschmerzen == 1)
            1
            else
              0,
            if (entry$abgeschlagenheit == 1)
              2
            else
              0,
            if (entry$appetitlosigkeit == 1)
              3
            else
              0,
            if (entry$nachtschweiss == 1)
              4
            else
              0,
            if (entry$muskel_gelenkschmerzen == 1)
              5
            else
              0)
      ),
      
      actionButton("submit", "Eintrag speichern", icon("save")),
      br(),
      br(),
      appVerfuegbarkeit()
    )
  })
  
  # UI-Renderer für die Arztangaben
  output$arztangaben <- renderUI({
    tagList(
      strong("Vorname Patient"),
      br(),
      patient$vorname,
      br(),
      br(),
      strong("Nachname Patient"),
      br(),
      patient$nachname,
      br(),
      br(),
      strong("Geburtsdatum"),
      br(),
      myDate(patient$geburtsdatum),
      br(),
      br(),
      strong("Geschlecht"),
      br(),
      if (patient$geschlecht == 1) {
        "männlich"
      } else if (patient$geschlecht == 2) {
        "weiblich"
      } else {
        "divers / keine Angabe"
      },
      br(),
      br(),
      if (benutzer$ist_arzt == 1) {
        tagList(
          textAreaInput(
            "diagnosen",
            "Diagnosen / Vorgeschichte",
            width = '80%',
            height = 200,
            value = patient$vorgeschichte,
            placeholder = "Bitte Verlauf / relevante Diagnosen aufführen."
          ),
          textAreaInput(
            "kontaktdaten",
            "Diese Kontaktdaten werden Ihrem Patienten angezeigt",
            width = '80%',
            height = 100,
            value = patient$arztkontakt,
            placeholder = "Bitte tragen Sie hier ein, wie der Patient Sie oder einen betreuenden Arzt erreichen kann."
          )
        )
      } else {
        tagList(
          strong("Diagnosen / Vorgeschichte"),
          br(),
          verbatimTextOutput("formatierteVorgeschichte"),
          br(),
          br()
        )
      },
      em(appVerfuegbarkeit()),
      br(),
      br(),
      if (benutzer$ist_arzt == 1) {
        actionButton("arztangabenSpeichern",
                     "Änderungen speichern",
                     icon("save"))
      }
    )
  })
  
  # UI-Renderer für die formatierte Patientengeschichte und den Arztkontakt
  output$formatierteVorgeschichte <-
    renderText(patient$vorgeschichte)
  output$formatierteKontaktdaten <- renderText(patient$arztkontakt)
  output$arztkontakt <- renderUI({
    tagList(
      strong("So erreichen Sie Ihren Arzt:"),
      br(),
      verbatimTextOutput("formatierteKontaktdaten"),
      br(),
      br()
    )
  })
  
  # UI-Renderer für die Zusammenfassung der Tagebucheinträge
  output$alleEintraege <- renderDT({
    zusammenfassung <<- readAllDiaryEntries(benutzer$patienten_id)
    invalidateLater(30000)
    datatable(zusammenfassung,
              options = list(
                order = list(1, 'desc'),
                "searching" = FALSE,
                "columnDefs" = list(list(
                  "targets" = 0, "visible" = FALSE
                )),
                language = list(url = "//cdn.datatables.net/plug-ins/1.10.11/i18n/German.json")
              ))
  })
  
  ## Event-Observer
  
  # Tagebucheintrag abspeichern
  observeEvent(input$submit, {
    
    # Abfangen fehlende Angabe zu Fieber
    if (is.null(input$fieber)) {
      showModal(
        modalDialog(
          strong("Bitte treffen Sie eine Auswahl ob Sie Fieber haben oder nicht."),
          easyClose=TRUE, footer = NULL
        )
      )
      return()
    }
    # Abfangen einer ungültigen Temperatur
    if ((input$fieber == 1) &&
        (!is.na(input$temp)) &&
        ((input$temp < 35.0) || (input$temp > 43.0))) {
      showModal(
        modalDialog(
          strong("Sie haben eine ungütlige Temperatur eingegeben"),
          br(),
          br(),
          p(
            "Temperaturen über 43.0 Grad sind sehr unwahrscheinlich. Möglicherweise liegt ein Defekt Ihres Thermometers vor. Messen Sie gegebenenfalls noch einmal nach."
          ),
          br(),
          p("Lassen Sie sonst das Feld einfach frei."),
          title = "Daten wurden nicht gespeichert.",
          icon = icon("circle-exclamation"),
          easyClose = FALSE
        )
      )
      return()
    }
    
    output$formatierteKontaktdaten <- renderText(patient$arztkontakt)
    
    # Aufruf Datenbank-Funktion 
    saveDiaryEntry(input$Datum, input$fieber, input$temp, input$symptome)
    
    # Bestätigung und ggf. Warnung vor auffälligen Symptomen
    if ((input$fieber == 1) || (length(input$symptome) > 0)) {
      showModal(
        modalDialog(
          strong(
            "Sie haben oder hatten Fieber oder auffällige Symptome.",
            style = "color:red"
          ),
          br(),
          br(),
          strong(
            "Falls noch nicht geschehen, kontaktieren Sie bitte Ihren Arzt"
          ),
          br(),
          br(),
          "Sie erreichen Ihren Arzt unter:",
          verbatimTextOutput("formatierteKontaktdaten"),
          title = "Die Daten wurden gespeichert.",
          easyClose = TRUE,
          footer = NULL
        )
      )
    } else {
      showModal(
        modalDialog(
          p(
            "Falls Sie sich anderweitig unwohl fühlen sollten oder Fragen haben, kontaktieren Sie gegebenenfalls Ihren Arzt"
          ),
          title = "Die Daten wurden gespeichert",
          easyClose = TRUE,
          footer = NULL
        )
      )
    }
      output$tagebuchGespeichert <- speicherDatum()
  })
  
  
  # Arztangaben abspeichern
  observeEvent(input$arztangabenSpeichern, {
    
    # Aufruf Datenbank-Funktion
    saveDoctorsEntry(input$diagnosen, input$kontaktdaten)

    showModal(
      modalDialog(
        title = "Die Änderungen wurden gespeichert.",
        easyClose = TRUE,
        footer = NULL
      )
    )
  })
  
  
  ## UI-Anpassung an Benutzerrechte
  observe({
    if (!is.null(benutzer)) {
      if (benutzer$ist_arzt) {
        hideTab(inputId = "tabs", target = "Tagebuch")
        showTab(inputId = "tabs", target = "Verlauf")
        hideTab(inputId = "tabs", target = "Arztkontakt")
      } else {
        showTab(inputId = "tabs", target = "Tagebuch")
        hideTab(inputId = "tabs", target = "Verlauf")
        showTab(inputId = "tabs", target = "Arztkontakt")
      }
    }
  })
  
}

shinyApp(ui = ui, server = server)
