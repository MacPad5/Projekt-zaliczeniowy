Celem projektu jest stworzenie systemu służącego do automatycznej analizy i klasyfikacji artykułów prasowych BBC.

Podział pracy:
Mikołaj Paszylka - dokumentacja specyfikacji wymagań
Jan Domalewski - pierwsza część kodu - przetwarzanie i oczyszczanie tekstu, steeming, tokenizacja, stworzenie macierzy TDM oraz TDM_TFIDF, eksploracyjna analiza dancyh, globalne chmury słów oraz chmury słów z podziałem na kategorie
Maciej Padamczyk - pozyskanie danych tekstowym oraz ich wstępne uporządkowanie, druga część kodu - klasyfikacja SVM artykułów ze względu na kategorię, podział na zbiór losowy i zbiór stratyfikowany, obliczenie metryk oraz ich wizualizacja dla obu zbiorów
