#récupération des données
NAm2 = read.table("NAm2.txt", header = T)

#composantes principales
pca = prcomp(NAm2[,-c(1:8)])
pvar = pca$sdev/sum(pca$sdev)*100
par(mfrow=c(1,2))
plot(1:length(pvar), pvar, type="l", lwd=1.5, col="blue", xlab="composantes",
ylab="pourcentage de variance expliquée")
plot(1:length(pvar), cumsum(pvar), type="l", lwd=1.5, col="blue", xlab="composantes",
      ylab="pourcentage de variance expliquée cumulée")
par(mfrow=c(1,1))

#séparation des données
set.seed(12345)
train = sample(1:nrow(NAm2), 400)
gen = data.frame(Pop=NAm2$Pop, pca$x[,1:300])

require(nnet)
#ajustement
fit.log = multinom(Pop~., data=gen, subset = train)
#prédiction sur l'ensemble de test
pred_probs = predict(fit.log, newdata = gen[-train,], type="probs")
pred_names = attr(pred, 'dimnames')[[2]]
preds = apply(pred, 1, function(x) pred_names[which.max(x)])
mean(gen$Pop[-train]!=preds)
table(gen$Pop[-train], pred_val)
