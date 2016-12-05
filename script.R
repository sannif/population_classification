#récupération des données
NAm2 = read.table("NAm2.txt", header = T)

#séparation des données
set.seed(12345)
train = sample(1:nrow(NAm2), 400)

#composantes principales
pca = prcomp(NAm2[train,-c(1:8)])
pvar = pca$sdev/sum(pca$sdev)*100
par(mfrow=c(1,2))
plot(1:length(pvar), pvar, type="l", lwd=1.5, col="blue", xlab="composantes",
     ylab="pourcentage de variance expliquée")
plot(1:length(pvar), cumsum(pvar), type="l", lwd=1.5, col="blue", xlab="composantes",
     ylab="pourcentage de variance expliquée cumulée")
par(mfrow=c(1,1))

ncomp = 300
gen = data.frame(Pop=NAm2$Country[train], pca$x[,1:ncomp])

require(nnet)
#ajustement
fit.log = multinom(Pop~., data=gen, MaxNWts=20000)
#prédiction sur l'ensemble de test
test_data = scale(NAm2[-train,-c(1:8)], pca$center, pca$scale) %*% pca$rotation
test_data = as.data.frame(test_data[,1:ncomp])

names(test_data) = names(gen)[-1]
preds.log = predict(fit.log, newdata = test_data, type="class")
mean(NAm2$Country[-train]!=preds.log)
table(NAm2$Country[-train], preds.log)


#LDA
require(MASS)
fit.lda = lda(Pop~.,data=gen)
preds.lda = predict(fit.lda, newdata = test_data, type="response")$class
lda.error = mean(NAm2$Country[-train] != preds.lda)
table(NAm2$Country[-train], preds.log)

#QDA
require(MASS)
fit.qda = qda(Pop~.,data=gen)
preds.qda = predict(fit.qda, newdata = test_data, type="response")$class
mean(NAm2$Pop[-train] != preds.lda)

# Logistic regularized
require(glmnet)
x = model.matrix(Pop~., data=NAm2[train, -c(1,2,4:8)])[,-1]
#grid = 10^seq (1.6,-2, length =1000)
fit.log_ridge = glmnet(x=x, y=NAm2$Pop[train], alpha = 0, family="multinomial")

