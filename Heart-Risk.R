#---------------------------1. Exportar los datos de MYSQL----------------------#
library(tidyverse)
library(DBI)
library(ggplot2)
connect_own<-function() {
  
  options(mysql = list(
    "host" = "localhost", 
    "port" = 3306,
    "user" = "adonai",
    "password" = "huevos123"
    
  ))
  
  
  db <- RMySQL::dbConnect(RMySQL::MySQL(), dbname = "Curso_R",
                          host = options()$mysql$host, 
                          port = options()$mysql$port, user = options()$mysql$user, 
                          password = options()$mysql$password)  
  
  
  
  return(db)
}

con_own <- connect_own()
table <- dbReadTable(con_own, "Tabla_Proyecto_5")
data <- data.frame(table)

#-----------2.Convertir la variable "Clases" a una variable Boleana------------#

data["class_binomial"] <- ifelse(data$class==0, 0, 1)
str(data)
data <- data %>% mutate(sex = factor(sex, labels = c("Female", "Male"))) #Preguntar a Roberto

#------------------3.Identificando las variables RELEVANTES---------------------#

chisq.test(data$sex, data$class_binomial)
t.test(data$age, data$class_binomial)
t.test(data$thalach, data$class_binomial)

#----------------4.EXploracion de asociaciones graficamente---------------------#

data["hd"] <- ifelse(data$class_binomial==1, "Disease", "No Disease")
ggplot(data, aes(x=hd, y=age) ) + geom_boxplot()
ggplot(data, aes(x=hd, y=sex, fill=sex) ) + geom_bar(stat="identity")
ggplot(data, aes(x=hd, y=thalach) ) + geom_boxplot()

#-------------------------5.Crear Modelo Multivariable-------------------------#

model <- glm(formula = class_binomial ~ age + thalach + sex,
             data = data, family = "binomial")
summary(model)

#-------------------6.Extrar informacion util del modelo-----------------------#

require(broom)

data_model <- model%>% tidy()

column_new <- exp(cbind(OR = coef(model), confint(model)))
columns_news <- as_tibble(column_new)
data_model %>% add_column(columns_news)
#------------------7.Probabilidades predictivas del modelo---------------------#

pred_probs <- predict(model, data, type = "response")

pred_bool <- ifelse(pred_probs > 0.5, 1, 0)

library(Metrics)
accuracy(pred_bool, data$class_binomial)*100
