library(BradleyTerry2)

rm(list = ls())
setwd("~/Library/Mobile Documents/com~apple~CloudDocs/Website/tommasorigon.github.io/post/beerpong")
tournament <- read.csv("risultati.csv", sep = ";", stringsAsFactors = TRUE)
# tournament <- tournament[-16, ]
# tournament[, c(3,4)] <- tournament[, c(3,4)]
str(tournament)

fit <- BTm(
  outcome = cbind(win1, win2),
  player1 = player1, player2 = player2, formula = ~player,
  id = "player", data = tournament, br = TRUE, refcat = "Tommy-Piase"
)
summary(fit)
BTabilities(fit)

lambdas <- BTabilities(fit)[, 1]
lambda_exp <- 100 * exp(lambdas)
round(sort(lambda_exp), 3)


#table(apply(tournament, 1, function(x) x[c(1,2)][which(x[c(3,4)] > 0)]))
round(plogis(outer(lambdas, lambdas, "-")), 2)

probs <- reshape2::melt(plogis(outer(lambdas, lambdas, "-")))
write.csv(probs, "probs.csv")

library("qvcalc")
fit_qv <- qvcalc(BTabilities(fit))
knitr::kable(fit_qv$qvframe, digits = 3)
plot(fit_qv, ylab = "Ability score")

