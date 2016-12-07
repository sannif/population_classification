#récupération des données
NAm2 = read.table("NAm2.txt", header = T)

#séparation des données
set.seed(12345)
train = sample(1:nrow(NAm2), 400)

#composantes principales
pca = prcomp(NAm2[train,-c(1:8)])
pvar = (pca$sdev**2/sum(pca$sdev**2))*100
screeplot(pca)
par(mfrow=c(1,2))
plot(1:length(pvar), pvar, type="p", col="blue", xlab="composantes",
     ylab="pourcentage de variance expliquée", cex=0.5)
plot(1:length(pvar), cumsum(pvar), type="l", lwd=1.5, col="blue", xlab="composantes",
     ylab="pourcentage de variance cumulée")
par(mfrow=c(1,1))



require(nnet)
#ajustement
cv_error <- function(idx, ncomp, method) {
  nfolds = 40
  err = numeric(10)
  for (k in 0:9) {
    sub = idx[(nfolds*k+1):(nfolds*(k+1))]
    gen = data.frame(Country=NAm2$Country[train], pca$x[,1:ncomp])
    if(method == "logistic") {
      fit = multinom(Country~., data=gen, MaxNWts=20000, subset=-sub, trace=F)
      preds = predict(fit, newdata = gen[sub,], type="class")
    } else if(method=="lda") {
      fit = lda(Country~.,data=gen, subset=-sub)
      preds = predict(fit, newdata = gen[sub,], type="response")$class
    } else {
      return("NA")
    }
    err[k+1] = mean(gen$Country[sub]!=preds)
  }
  mean(err)
}

ncomp = unique(c(seq(20,100,5), seq(100, 400, 20)))
miscl = numeric(length(ncomp))
set.seed(12345)
idx = sample(1:400)
j = 1
for (i in ncomp) {
  cat(j,"/", 32, "\n")
  miscl[j] = cv_error(idx, i, "logistic")
  j = j+1
}
plot(ncomp, miscl, type='o', cex=0.6, col="blue", ylab = "taux erreur",
     xlab="nombre de composantes")
ncomp_opt = ncomp[which.min(miscl)]
gen_log = data.frame(Country=NAm2$Country[train], pca$x[,1:ncomp_opt])
fit.log = multinom(Country~., data=gen_log, MaxNWts=20000, trace=F)
#prédiction sur l'ensemble de test
test_data = scale(NAm2[-train,-c(1:8)], pca$center, pca$scale) %*% pca$rotation
test.log = as.data.frame(test_data[,1:ncomp_opt])
preds.log = predict(fit.log, newdata = test.log, type="class")
mean(NAm2$Country[-train]!=preds.log)
table(NAm2$Country[-train], preds.log)


#LDA
require(MASS)
#ncomp_lda = unique(c(seq(20,100,5), seq(100, 340, 20)))
ncomp_lda = seq(20,340,5)
misc = numeric(length(ncomp_lda))
set.seed(12345)
j=1
for (i in ncomp_lda) {
  cat(j,"/", 65, "\n")
  misc[j] = cv_error(idx, i, "lda")
  j = j+1
}
plot(ncomp_lda, misc, type='o', cex=0.6, col="blue", ylab = "taux erreur",
     xlab="nombre de composantes")
nopt_lda = ncomp_lda[which.min(misc)]
gen_lda = data.frame(Country=NAm2$Country[train], pca$x[,1:nopt_lda])
fit.lda = lda(Country~.,data=gen_lda)
test.lda = as.data.frame(test_data[,1:nopt_lda])
preds.lda = predict(fit.lda, newdata = test.lda, type="response")$class
mean(NAm2$Country[-train] != preds.lda)
table(NAm2$Country[-train], preds.lda)

#knn
require(class)
#validation croisée pour choisir k
nfolds = 40
K = 2:30
err = numeric(length(K))
set.seed(12345)
for (i in K) {
  tmp = 0
  cat(i-1,"/",29, "\n")
  for (k in 0:9) {
    sub = (nfolds*k+1):(nfolds*(k+1))
    fit = knn(train=NAm2[train[-sub], -(1:8)], test=NAm2[train[sub], -(1:8)],
              cl=NAm2$Country[train[-sub]], k=i)
    tmp = tmp + mean(NAm2$Country[train[sub]]!=fit)
  }
  err[i-1] = tmp/10
}
plot(K, err, type='o', col='blue', lwd=1.5)
kopt = K[which.min(err)]
preds.knn = knn(train=NAm2[train,-(1:8)], test = NAm2[-train, -(1:8)],
                cl=NAm2$Country[train], k=kopt)
mean(NAm2$Country[-train] != preds.knn)
table(NAm2$Country[-train], preds.knn)


# Logistic regularized
require(glmnet)
x = model.matrix(Country~., data=NAm2[train, -c(1:3,5:8)])[,-1]
rownames(x) = NULL
set.seed(12345)
ptm <- proc.time()
fit.log_ridge = glmnet(x=x, y=NAm2$Country[train], alpha = 0, family="multinomial",
                       type.multinomial = "grouped")
proc.time() - ptm
plot(fit.log_ridge, xvar = "lambda")

grid = 10^seq (-2,-4, length =25)
set.seed(12345)
ptm <- proc.time()
cv.ridge = cv.glmnet(x=x, y=NAm2$Country[train], alpha=0, family="multinomial",
                     type.measure = "class", type.multinomial = "grouped", lambda = grid)
proc.time() - ptm
plot(cv.ridge$lambda, cv.ridge$cvm, type='l', xlab=expression(lambda),
     ylab = "taux erreur ", lwd = 1.5, col="darkblue")
lopt = cv.ridge$lambda.min
newx = model.matrix(Country~., data=NAm2[-train, -c(1:3,5:8)])[,-1]
rownames(newx) = NULL
preds.ridge = predict.cv.glmnet(cv.ridge, newx=newx, s=lopt, type = "class")
mean(NAm2$Country[-train] != preds.ridge)
table(NAm2$Country[-train], preds.ridge)

#lasso
ptm <- proc.time()
fit.log_lasso = glmnet(x=x, y=NAm2$Country[train], family="multinomial")
proc.time() - ptm
plot(fit.log_lasso, xvar = "lambda")

ptm <- proc.time()
cv.lasso = cv.glmnet(x=x, y=NAm2$Country[train], family="multinomial",
                     type.measure = "class")
proc.time() - ptm
plot(cv.lasso$lambda, cv.lasso$cvm, type='l', xlab=expression(lambda),
     ylab = "taux erreur ", lwd = 1.5, col="darkblue")
plot(cv.lasso$lambda[cv.lasso$cvm<0.3], cv.lasso$cvm[cv.lasso$cvm<0.3], type='l', xlab=expression(lambda),
     ylab = "taux erreur ", lwd = 1.5, col="darkblue")
lopt.lasso = cv.lasso$lambda.min
preds.lasso = predict.cv.glmnet(cv.lasso, newx=newx, s=lopt.lasso, type = "class")
mean(NAm2$Country[-train] != preds.lasso)
table(NAm2$Country[-train], preds.lasso)


require(rpart)
set.seed(12345)
fit.tree = rpart(Country~., data=NAm2[,-c(1:3,5:8)], subset = train, method ="class")
plot(fit.tree)
text(fit.tree, cex=.5, pretty = 0)
preds.tree = predict(fit.tree, newdata = NAm2[-train,-c(1:3,5:8)], type = "class")
mean(NAm2$Country[-train] != preds.tree)
table(NAm2$Country[-train], preds.tree)

prun = prune(fit.tree, cp = fit.tree$cptable[which.min(fit.tree$cptable[,"xerror"]),"CP"])
preds.prune = predict(prun, newdata = NAm2[-train,-c(1:3,5:8)], type = "class")
mean(NAm2$Country[-train] != preds.prune)
table(NAm2$Country[-train], preds.tree)

require(randomForest)
set.seed(12345)
mtry = ncol(NAm2) - 8
ptm <- proc.time()
fit.bag = randomForest(Country~., data=NAm2[,-c(1:3,5:8)], subset = train, mtry=mtry, importance=T)
ptm <- proc.time()
preds.bag = predict(fit.bag, newdata = NAm2[-train,-c(1:3,5:8)], type = "class")
mean(NAm2$Country[-train] != preds.bag)
table(NAm2$Country[-train], preds.bag)
