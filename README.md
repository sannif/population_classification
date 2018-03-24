## Classification des populations autochtones d'Amérique selon leur diversité génétique

## Data
Nous disposons d'un jeu de données qui contient 5709 marqueurs génétiques relevés sur 494
individus appartenant à 27 populations autochtones d'Amérique du Nord, d'Amérique centrale et
d'Amérique latine. Ce jeu de données se caractérise essentiellement par le fait qu'il y'ait plus
de variables (5709) que d'observations (494).

![Location of populations](figures/map.png =100x20)


## Objectif
Prédire la population d'origine d'un individu connaissant les 5709 marqueurs.

## Méthodologie
Il s'agit d'un problème de classification multiclasse. D'abord, une analyse en composantes principales est appliquée
afin de réduire le nombre de variables. Ensuite, différentes méthodes de classification sont appliquées sur les données
transformées : régression logistique, LDA, KNN, arbre de décision, random forest. 

## Résultats
Taux d'erreur des différentes méthodes
Méthode | Taux d'erreur |
:---: | :---: |
ACP + logistique | 0.106  |
ACP + LDA | 0.096  |
**Logistique + Ridge | 0.053  **|
Logistique + Lasso | 0.138  |
KNN | 0.149  |
Arbre de classification | 0.489  |
Pruning | 0.52  |
Random forest | 0.32  |
ACP + Random forest | 0.180  |
