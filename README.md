# Analiza i Klasyfikacja Artykułów Prasowych BBC

Celem projektu jest stworzenie systemu służącego do automatycznej analizy i klasyfikacji artykułów prasowych BBC.

## Podział pracy

* **Mikołaj Paszyłka**
  * Dokumentacja specyfikacji wymagań.

* **Jan Domalewski**
  * Przetwarzanie i oczyszczanie tekstu (stemming, tokenizacja).
  * Stworzenie macierzy TDM oraz TDM_TFIDF.
  * Eksploracyjna analiza danych.
  * Generowanie globalnych chmur słów oraz chmur słów z podziałem na kategorie.

* **Maciej Padamczyk**
  * Pozyskanie danych tekstowych oraz ich wstępne uporządkowanie.
  * Klasyfikacja artykułów ze względu na kategorię przy użyciu modelu SVM.
  * Podział danych na zbiór losowy i zbiór stratyfikowany.
  * Obliczenie metryk efektywności oraz ich wizualizacja dla obu zbiorów.
