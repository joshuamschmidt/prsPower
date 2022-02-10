# functions

simulate_GRADE <- function(n_ind=1000,n_group=100,OR=14.9,base_prevalence=0.06,cuts=c(0.1,0.9)) {
  prs = rnorm(n_ind)
  coeff <- log(OR)/define_prs_range(cuts=cuts) # prs sd units b/t mean top10% and bottom top10%
  intercept <- est_intercept(OR = OR,cuts = cuts,base_prevalence = base_prevalence)
  xb <- intercept + coeff*prs
  p <- 1/(1 + exp(-xb))
  glaucoma <- rbinom(n = n_ind, size = 1, prob = p)
  glaucomaDT <- data.table::data.table(prs=prs,glaucoma)
  glaucomaDT[prs > quantile(prs,probs=c(cuts[2])),label:="top"]
  glaucomaDT[prs < quantile(prs,probs=c(cuts[1])),label:="bottom"]
  glaucomaDT[!label %in% c("top","bottom"),label:="middle"]
  glaucomaDT_N_per_group <- glaucomaDT[,.SD[sample(.N, min(.N,n_group),replace = F)],by = label]
  out <- list()
  out[["full"]] <- glaucomaDT
  out[["sampled"]] <- glaucomaDT_N_per_group
  return(out)
  }

est_intercept <- function(OR=14.9,cuts=c(0.1,0.9),base_prevalence=0.06) {
  prs = rnorm(1e3)
  coeff <- log(OR)/define_prs_range(cuts=cuts) # prs sd units b/t mean top10% and bottom top10%
  intercept_range <- seq(from=-15,to=5,by=0.05)
  ave_prob <- function(prs,coeff,intercept) {
    xb <- intercept + coeff*prs
    p <- 1/(1 + exp(-xb))
    mean(p)
  }
  realised_pr <- sapply(intercept_range, function(x) ave_prob(prs=prs,coeff=coeff,intercept =x))
  diff <- abs(base_prevalence-realised_pr)
  intercept_range[which(diff==min(diff))]
}

define_prs_range <- function(cuts=c(0.1,0.9)) {
  upper_mean <- (dnorm(qnorm(cuts[2]))-dnorm(qnorm(0.99999)))/ (pnorm(qnorm(0.99999)) - pnorm(qnorm(cuts[2])))
  lower_mean <- (dnorm(qnorm(0.00001))-dnorm(qnorm(cuts[1])))/ (pnorm(qnorm(cuts[1])) - pnorm(qnorm(0.00001)))
  upper_mean - lower_mean
}

get_OR <- function(gradeDT,cuts=c(0.1,0.9), labels=c("top","middle")) {
  numerator <- gradeDT[label==labels[1],.N,by=glaucoma][order(glaucoma)]
  numerator <- numerator[2,N]/numerator[1,N]
  denominator <- gradeDT[label==labels[2],.N,by=glaucoma][order(glaucoma)]
  denominator <- denominator[2,N]/denominator[1,N]
  numerator / denominator
}

modCoeff_to_OR <- function(coeff,cuts){
  unit_OR <- exp(coeff)
  sd_units <- define_prs_range(cuts=cuts)
  unit_OR * sd_units
}

# power of model
# bionomial regression of glaucoma status on prs
simFitreg <- function( n_ind=1000,n_group=100,OR=14.9,base_prevalence=0.06,cuts=c(0.1,0.9)){
  data <- simulate_GRADE(n_ind = n_ind, n_group = n_group,
                         OR = OR, base_prevalence = base_prevalence,
                         cuts = cuts)
  mod <- glm(glaucoma ~ prs , family = "binomial",data = data$sampled)
  s.out <- summary(mod)
  s.out$coefficients["prs","Pr(>|z|)"] < 0.05
}

powerEstreg <- function(n_sims=100, n_ind, n_group, OR, base_prevalence, cuts){
  r.out <- replicate(n = n_sims, simFitreg(n_ind = n_ind, n_group = n_group,
                                           OR = OR,base_prevalence = base_prevalence,
                                           cuts = cuts))
  mean(r.out)
}

simFitproportions <- function( n_ind=1000,n_group=100,OR=14.9,base_prevalence=0.06,cuts=c(0.1,0.9)){
  data <- simulate_GRADE(n_ind = n_ind, n_group = n_group,
                         OR = OR, base_prevalence = base_prevalence,
                         cuts = cuts)
  cases_by_label <- data$sampled[glaucoma==1,.N,by=label]
  c_t <- ifelse(length(cases_by_label[label=="top"]$N) ==1,cases_by_label[label=="top"]$N,0)
  c_b <- ifelse(length(cases_by_label[label=="bottom"]$N) ==1,cases_by_label[label=="bottom"]$N,0)
  c_m <- ifelse(length(cases_by_label[label=="middle"]$N) ==1,cases_by_label[label=="middle"]$N,0)
  t_tb <- prop.test(c(c_t,c_b), c(n_group,n_group), p = NULL, alternative = "two.sided",
                    correct = TRUE)
  t_tm <- prop.test(c(c_t,c_m), c(n_group,n_group), p = NULL, alternative = "two.sided",
                    correct = TRUE)
  t_mb <- prop.test(c(c_m,c_b), c(n_group,n_group), p = NULL, alternative = "two.sided",
                    correct = TRUE)
  c(t_tb$p.value*3,t_tm$p.value*3,t_mb$p.value*3) < 0.05

}

powerEstproportions <- function(n_sims=100, n_ind, n_group, OR, base_prevalence, cuts){
  r.out <- replicate(n =n_sims, simFitproportions(n_ind = n_ind, n_group = n_group,
                                                  OR = OR,base_prevalence = base_prevalence,
                                                  cuts = cuts))
  means <- c(mean(r.out[1,] ),mean(r.out[2,]),mean(r.out[3,] ))
  means[which(means %in% NA)] <- 0
  names(means) <- c("top_bottom","top_middle","middle_bottom")
  return(means)
}

simFitprev <- function( n_ind=1000,n_group=100,OR=14.9,base_prevalence=0.06,cuts=c(0.1,0.9)){
  data <- simulate_GRADE(n_ind = n_ind, n_group = n_group,
                         OR = OR, base_prevalence = base_prevalence,
                         cuts = cuts)
  dt <- data.table(label=c("top","middle","bottom"))
  prev <- data$sampled[glaucoma==1,.N,by=label]
  prev <- prev[dt,on=.(label)]
  prev[N %in% NA,N:=0]
  prev[,pr:=N/n_group]
  prev$pr
}

averagePrevelance <- function(n_sims=100, n_ind, n_group, OR, base_prevalence, cuts){
  r.out <- replicate(n = n_sims, simFitprev(n_ind = n_ind, n_group = n_group,
                                                  OR = OR,base_prevalence = base_prevalence,
                                                  cuts = cuts))
  pr <- as.data.table(t(r.out))
  names(pr) <- c("top","middle","bottom")
  pr[,rep:=1:.N]
  return(pr)
}

simFitregLabel <- function( n_ind=1000,n_group=100,OR=14.9,base_prevalence=0.06,cuts=c(0.1,0.9)){
  data <- simulate_GRADE(n_ind = n_ind, n_group = n_group,
                         OR = OR, base_prevalence = base_prevalence,
                         cuts = cuts)
  # top reference coding
  data$sampled[label=="bottom",bottom:=1]
  data$sampled[label!="bottom",bottom:=0]
  data$sampled[label=="middle",middle:=1]
  data$sampled[label!="middle",middle:=0]
  mod <- glm(glaucoma ~ bottom + middle, family = "binomial",data = data$sampled)
  s.out <- summary(mod)
  c(s.out$coefficients[2:3,"Pr(>|z|)"]*2) < 0.05
}

powerEstregLabel <- function(n_sims=100, n_ind, n_group, OR, base_prevalence, cuts){
  r.out <- replicate(n =n_sims, simFitregLabel(n_ind = n_ind, n_group = n_group,
                                                  OR = OR,base_prevalence = base_prevalence,
                                                  cuts = cuts))
  p.signif <- rowMeans(r.out)
  p.signif[which(p.signif %in% NA)] <- 0
  return(p.signif)
}

