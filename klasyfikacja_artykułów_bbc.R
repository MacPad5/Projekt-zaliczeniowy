
#' ---
#' title: "Projekt zaliczeniowy: Klasyfikacja artykułów"
#' author: "Maciej Padamczyk, Mikołaj Paszylka, Jan Domalewski"
#' date:   "7.06.2026"
#' output:
#'   html_document:
#'     df_print: paged
#'     theme: readable      
#'     highlight: kate      
#'     toc: true            
#'     toc_depth: 3
#'     toc_float:
#'       collapsed: false
#'       smooth_scroll: true
#'     code_folding: show    
#'     number_sections: false 
#' ---


knitr::opts_chunk$set(
  message = FALSE,
  warning = FALSE
)


#' # Wymagane pakiety
#  Wymagane pakiety ----

library(tm)
library(tidyverse)
library(tidytext)
library(wordcloud)
library(ggplot2)
library(ggthemes)
library(RColorBrewer)
library(dplyr)
library(e1071)
library(readr)

#' # Dane tekstowe
# Dane tekstowe ----

dane <- read_csv2('Artykuly_final.csv')
corpus <- VCorpus(VectorSource(dane$tekst))

corpus[[1]]

corpus[[1]][[1]]

corpus[[1]][2]

#' # 1. Przetwarzanie i oczyszczanie tekstu
# 1. Przetwarzanie i oczyszczanie tekstu ----

# Normalizacja i usunięcie zbędnych znaków ----

# Zapewnienie kodowania w całym korpusie
corpus <- tm_map(corpus, content_transformer(function(x) iconv(x, to = "UTF-8", sub = "byte")))


# Funkcja do zamiany znaków na spację
toSpace <- content_transformer(function (x, pattern) gsub(pattern, " ", x))


# Usuń zbędne znaki lub pozostałości url, html itp.

# symbol @
corpus <- tm_map(corpus, toSpace, "@")

# symbol @ ze słowem (zazw. nazwa użytkownika)
corpus <- tm_map(corpus, toSpace, "@\\w+")

# linia pionowa
corpus <- tm_map(corpus, toSpace, "\\|")

# tabulatory
corpus <- tm_map(corpus, toSpace, "[ \t]{2,}")

# CAŁY adres URL:
corpus <- tm_map(corpus, toSpace, "(s?)(f|ht)tp(s?)://\\S+\\b")

# http i https
corpus <- tm_map(corpus, toSpace, "http\\w*")

# tylko ukośnik odwrotny (np. po http)
corpus <- tm_map(corpus, toSpace, "/")

# pozostałość po re-tweecie
corpus <- tm_map(corpus, toSpace, "(RT|via)((?:\\b\\W*@\\w+)+)")

# inne pozostałości
corpus <- tm_map(corpus, toSpace, "www")
corpus <- tm_map(corpus, toSpace, "~")
corpus <- tm_map(corpus, toSpace, "â€“")

corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removeNumbers)
corpus <- tm_map(corpus, removeWords, stopwords("english"))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, stripWhitespace)

# usuwanie zbędnych słów
corpus <- tm_map(corpus, removeWords, c("the", "and", "for", "she", "her", "they", "that", "have", "but", "was", "from", "with", "has", "said", 
                                        "will", "are", "not", "his", "would", "had", "also"))

corpus <- tm_map(corpus, stripWhitespace)

#' # Stemming
# Stemming ----

# Kopia korpusu 
corpus_copy <- corpus

# Stemming w korpusie
corpus_stemmed <- tm_map(corpus, stemDocument)

# Sprawdzenie
corpus[[1]][[1]]

# Sprawdzenie
corpus_stemmed[[1]][[1]]

# Uzupełnienie rdzeni słów po stemmingu (opcjonalne)----

# complete_stems <- content_transformer(function(x, dict) {
#  x <- unlist(strsplit(x, " "))                  
#  x <- stemCompletion(x, dictionary = corpus_copy, type="longest") 
#  paste(x, collapse = " ")
# })

# stemCompletion do każdego dokumentu w korpusie
# corpus_completed <- tm_map(corpus_stemmed, complete_stems, dict = corpus_copy)

# usuwanie NA
# corpus_completed <- tm_map(corpus_completed, toSpace, "NA")
# corpus_completed <- tm_map(corpus_completed, stripWhitespace)

# corpus_completed[[1]][[1]]

#' # Tokenizacja
# Tokenizacja ----

#' # 2. Macierz częstości TDM
#  2 Macierz częstości TDM ----

tdm <- TermDocumentMatrix(corpus_stemmed)

tdm

tdm_m <- as.matrix(tdm)



#' # Zliczanie częstości słów
#  Zliczanie częstości słów dla TDM----


# Zlicz same częstości słów w macierzach
v <- sort(rowSums(tdm_m), decreasing = TRUE)
tdm_df <- data.frame(word = names(v), freq = v)
head(tdm_df, 10)



#' # Eksploracyjna analiza danych dla TDM
# Eksploracyjna analiza danych dla TDM ----
# (Exploratory Data Analysis, EDA)


# Chmura słów bez wag TFIDF(globalna)
wordcloud(words = tdm_df$word, freq = tdm_df$freq, min.freq = 500, 
          colors = brewer.pal(8, "Dark2"))


# Wyświetl top 10
print(head(tdm_df, 10))

#' # 3. Macierz częstości TDM z TF-IDF
# 3. Macierz częstości TDM z TF-IDF ----

tdm_tfidf <- TermDocumentMatrix(corpus_stemmed,
                                control = list(weighting = function(x) weightTfIdf(x, normalize = FALSE)))

tdm_tfidf


tdm_tfidf_m <- as.matrix(tdm_tfidf)


#' # Zliczanie częstości słów dla TDM z wykorzystaniem algorytm TFIDF
#  Zliczanie częstości słów dla TDM z wykorzystaniem algorytm TFIDF ----
# (Word Frequency Count)


# Zlicz same częstości słów w macierzach
v_tfidf <- sort(rowSums(tdm_tfidf_m), decreasing = TRUE)
tdm_tfidf_df <- data.frame(word = names(v_tfidf), freq = v_tfidf)
head(tdm_tfidf_df, 10)



#' #  Eksploracyjna analiza danych dla TDM_IDF
#  Eksploracyjna analiza danych dla TDM_IDF ----


# Chmura słów przy użyciu algorytmu TFIDF (globalna)
wordcloud(words = tdm_tfidf_df$word, freq = tdm_tfidf_df$freq, min.freq = 500, 
          colors = brewer.pal(8, "Dark2"))


# Wyświetl top 10
print(head(tdm_tfidf_df, 10))

#' # 4. Chmury słów dla poszczególnych kategorii
# 4. Chmury słow dla poszczególnhych kategorii ---- 

par(mfrow = c(2, 3))

# Pobranie unikalnych kategorii z ramki danych
kategorie <- unique(dane$kategoria)

# Pętla generująca chmurę dla każdej kategorii
for (kat in kategorie) {
  
  # 1. Wybór indeksów dokumentów należących do danej kategorii
  indeksy <- which(dane$kategoria == kat)
  
  # 2. Wyciągnięcie przetworzonych tekstów z gotowego już korpusu
  corpus_kat <- corpus_stemmed[indeksy]
  
  # 3. Utworzenie macierzy TDM z TF-IDF tylko dla tej kategorii
  tdm_kat <- TermDocumentMatrix(corpus_kat,
                                control = list(weighting = function(x) weightTfIdf(x, normalize = FALSE)))
  
  tdm_kat_m <- as.matrix(tdm_kat)
  
  # 4. Zliczanie częstości słów
  v_kat <- sort(rowSums(tdm_kat_m), decreasing = TRUE)
  df_kat <- data.frame(word = names(v_kat), freq = v_kat)
  
  # 5. Rysowanie chmury słów (zabezpieczenie przed błędami braku słów)
  if(nrow(df_kat) > 0) {
    wordcloud(words = df_kat$word, 
              freq = df_kat$freq, 
              min.freq = 2, 
              max.words = 50, # Ograniczamy liczbę słów, bo wykresy będą mniejsze
              random.order = FALSE, 
              colors = brewer.pal(8, "Dark2"),
              scale = c(2.5, 0.5))
    
    # Dodanie tytułu (nazwa kategorii)
    title(main = paste("Kategoria:", kat))
  }
}

# Przywrócenie standardowego, pojedynczego układu wykresów
par(mfrow = c(1, 1))


#' # Zliczanie częstości słów dla poszczególnych kategorii
# (Word Frequency Count per Category)

# Pobranie unikalnych kategorii z ramki danych
kategorie <- unique(dane$kategoria)

# Pętla generująca zliczenia dla każdej kategorii
for (kat in kategorie) {
  
  # 1. Wybór indeksów dokumentów należących do danej kategorii
  indeksy <- which(dane$kategoria == kat)
  
  # 2. Wyciągnięcie przetworzonych tekstów z gotowego już korpusu
  corpus_kat <- corpus_stemmed[indeksy]
  
  # 3. Utworzenie macierzy TDM z TF-IDF tylko dla tej kategorii
  tdm_kat <- TermDocumentMatrix(corpus_kat,
                                control = list(weighting = function(x) weightTfIdf(x, normalize = FALSE)))
  
  tdm_kat_m <- as.matrix(tdm_kat)
  
  # 4. Zliczanie częstości słów
  v_kat <- sort(rowSums(tdm_kat_m), decreasing = TRUE)
  df_kat <- data.frame(word = names(v_kat), freq = v_kat)
  
  # Wyświetlenie nazwy kategorii, aby oddzielić wyniki
  cat("\n===================================\n")
  cat("Kategoria:", kat, "\n")
  cat("===================================\n")
  
  # 5. Wyświetl top 10
  print(head(df_kat, 10))
}


#' # 5. Inżynieria cech w modelu Bag of Words:
#' # Reprezentacja słów i dokumentów w przestrzeni wektorowej
# 5. Inżynieria cech w modelu Bag of Words: ----
# Reprezentacja słów i dokumentów w przestrzeni wektorowej ----

# - podejście TF-IDF


tdm_tfidf

inspect(tdm_tfidf)

#' # 6. Uczenie maszynowe nadzorowane
#' 
# 6. Uczenie maszynowe nadzorowane ----

#' # Klasyfikacja SVM (Support Vector Machines)

# Redukcja wymiarów macierzy - odrzucenie słów występujących rzadziej niż w 1% dokumentów
tdm_tfidf_clean <- removeSparseTerms(tdm_tfidf, 0.99)



dtm_df <- as.data.frame(t(as.matrix(tdm_tfidf_clean)))
dtm_df$kategoria <- factor(dane$kategoria, levels = kategorie)


# Sprawdzenie wymiarów
dim(dtm_df)

# Sprawdzenie kilku kolumn

dtm_df[1:3, 1000:1003]


#' # a) Podział na zbiór treningowy/testowy losowy
# a) Podział na zbiór treningowy/testowy losowy ----

set.seed(123)

idx_train_losowe <- sample(1:nrow(dtm_df), 0.8 * nrow(dtm_df))
trainData <- dtm_df[idx_train_losowe, ]
testData  <- dtm_df[-idx_train_losowe, ]


# Rozdzielenie danych treningowych na macierz cech (X) i etykiety (y)
X_train <- trainData[, colnames(trainData) != "kategoria"]
y_train <- trainData$kategoria

# To samo dla danych testowych
X_test  <- testData[, colnames(testData) != "kategoria"]
y_test  <- testData$kategoria


# Trenowanie modelu SVM (na danych treningowych)
svm_model_losowy <- svm(x = X_train, y = y_train, kernel = "linear", probability = TRUE)


#' # Ocena modelu klasyfikacji, podział losowy
# Ocena modelu klasyfikacji, podział losowy ----

# Predykcja klas na zbiorze testowym
predictions_losowy <- predict(svm_model_losowy, X_test)


# Macierz pomyłek (confusion matrix)
confusion_matrix_l <- table(Predicted = predictions_losowy, Actual = y_test)
print(confusion_matrix_l)

# Obliczenie metryk

# Accuracy
accuracy_l = sum(diag(confusion_matrix_l)) / sum(confusion_matrix_l)
print(accuracy_l)

# Wyciąganie TP, TN, FP, FN z confusion_matrix

tp_l <- diag(confusion_matrix_l) # Poprawnie trafione - wartości na przękątnej
fp_l <- rowSums(confusion_matrix_l) - tp_l # Błędnie przypisane do klasy
fn_l <- colSums(confusion_matrix_l) - tp_l # Ilość nieodczytanych artykułów z danej klasy 
tn_l <- sum(confusion_matrix_l) - (tp_l + fp_l + fn_l) # Poprawnie odrzucone

# Precision 
precision_l <- tp_l / (tp_l + fp_l)

# Recall
recall_l <- tp_l / (tp_l + fn_l) 

# Specifity
specificity_l<- tn_l / (tn_l + fp_l)

# F1 score
f1_score_l <- 2 * (precision_l * recall_l) / (precision_l + recall_l)

# Wyniki metryk

metryki <- data.frame(
  Kategoria   = names(tp_l),
  Precision   = round(precision_l, 4),
  Recall      = round(recall_l, 4),
  Specificity = round(specificity_l, 4),
  F1_Score    = round(f1_score_l, 4)
)

#' # Wizualizacja metryk dla podział losowego
# Wizualizacja metryk dla podziału losowego ----


metryki_df <- metryki %>%
  pivot_longer(cols = c(Precision, Recall, Specificity, F1_Score),
               names_to = "Metryka",
               values_to = "Wartosc")

# Wykres przedstawiający metryki dla poszczególnych modeli
ggplot(metryki_df, aes(x = Kategoria, y = Wartosc, fill = Kategoria)) +
  geom_col(show.legend = FALSE, width = 0.5, color = "black") +
  geom_text(aes(label = round(Wartosc, 2)), vjust = -0.5, size = 2.5) +
  facet_wrap(~ Metryka, scales = "fixed", ncol = 2) +
  ylim(0, 1.1) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Wizualizacja metryk podziału losowego klasyfikacji dla modelu SVM",
       subtitle = "Podział na kategorie tematyczne artykułów BBC",
       x = "Kategoria tekstu",
       y = "Wartość metryki (skala 0 - 1)") +
  theme_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "grey30"),
    strip.text = element_text(face = "bold", size = 11, color = "white"),
    strip.background = element_rect(fill = "steelblue4"), 
    axis.text.x = element_text(angle = 35, hjust = 1, face = "bold"), 
    panel.grid.major.x = element_blank() 
  )

#' # b) Podział na zbiór treningowy/testowy stratyfikowany
# b) Podział na zbiór treningowy/testowy stratyfikowany ----

# Wykorzystanie biblioteki caret, która usprwani losowanie zbioru treningowego
library(caret)

set.seed(123)

idx_train_stratyfikowane <- createDataPartition(dtm_df$kategoria, p = 0.8, list = FALSE)
trainData <- dtm_df[idx_train_stratyfikowane, ]
testData  <- dtm_df[-idx_train_stratyfikowane, ]

# Rozdzielenie danych treningowych na macierz cech (A) i etykiety (B)
A_train <- trainData[, colnames(trainData) != "kategoria"]
B_train <- trainData$kategoria

# To samo dla danych testowych
A_test  <- testData[, colnames(testData) != "kategoria"]
B_test  <- testData$kategoria

svm_model_stratyfikowany <- svm(x = A_train, y = B_train, kernel = "linear", probability = TRUE)

#' # Ocena modelu klasyfikacji, podział stratyfikowany
# Ocena modelu klasyfikacji, podział stratyfikowany ----

# Predykcja klas na zbiorze testowym
predictions_stratyfikowany <- predict(svm_model_stratyfikowany, A_test)

# Macierz pomyłek (confusion matrix)
confusion_matrix_s <- table(Predicted = predictions_stratyfikowany, Actual = B_test)
print(confusion_matrix_s)

# Obliczenie metryk

accuracy_s <- sum(diag(confusion_matrix_s)) / sum(confusion_matrix_s)

# Wyciąganie TP, TN, FP, FN z confusion_matrix

tp_s <- diag(confusion_matrix_s)
fp_s <- rowSums(confusion_matrix_s) - tp_s
fn_s <- colSums(confusion_matrix_s) - tp_s
tn_s <- sum(confusion_matrix_s) - (tp_s + fn_s + fp_s)

# Precision 
precision_s <- tp_s / (tp_s + fp_s)

# Recall
recall_s <- tp_s / (tp_s + fn_s) 

# Specifity
specificity_s <- tn_s / (tn_s + fp_s)

# F1 score
f1_score_s <- 2 * (precision_s * recall_s) / (precision_s + recall_s)

# Wyniki metryk

metryki_s <- data.frame(
  Kategoria   = names(tp_s),
  Precision   = round(precision_s, 4),
  Recall      = round(recall_s, 4),
  Specificity = round(specificity_s, 4),
  F1_Score    = round(f1_score_s, 4)
)

#' # Wizualizacja metryk dla podział stratyfikowanego
# Wizualizacja metryk dla podziału stratyfikowanego ----

metryki_df_s <- metryki_s %>%
  pivot_longer(cols = c(Precision, Recall, Specificity, F1_Score),
               names_to = "Metryka",
               values_to = "Wartosc")

# Wykres przedstawiający metryki dla poszczególnych modeli
ggplot(metryki_df_s, aes(x = Kategoria, y = Wartosc, fill = Kategoria)) +
  geom_col(show.legend = FALSE, width = 0.5, color = "black") +
  geom_text(aes(label = round(Wartosc, 2)), vjust = -0.5, size = 2.5) +
  facet_wrap(~ Metryka, scales = "fixed", ncol = 2) +
  ylim(0, 1.1) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Wizualizacja metryk podziału stratyfikowanego klasyfikacji dla modelu SVM",
       subtitle = "Podział na kategorie tematyczne artykułów BBC",
       x = "Kategoria tekstu",
       y = "Wartość metryki (skala 0 - 1)") +
  theme_light() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "grey30"),
    strip.text = element_text(face = "bold", size = 11, color = "white"),
    strip.background = element_rect(fill = "steelblue4"), 
    axis.text.x = element_text(angle = 35, hjust = 1, face = "bold"), 
    panel.grid.major.x = element_blank() 
  )