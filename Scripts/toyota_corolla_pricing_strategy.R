# Load libraries
library(dplyr)
library(caret)
library(fastDummies)
library(neuralnet)

# Load data
used_cars <- read.csv("ToyotaCorolla.csv")

toyota <- used_cars[1:1000, c("Price","Age_08_04","KM","Fuel_Type","HP",
                              "Met_Color","Automatic","Doors",
                              "Quarterly_Tax","Weight")]

# Create binary target
avg_price <- mean(toyota$Price)
toyota$CAT.Price <- ifelse(toyota$Price > avg_price, 1, 0)
toyota <- toyota %>% select(-Price)

# Convert categorical to factors
toyota$Fuel_Type <- as.factor(toyota$Fuel_Type)
toyota$Met_Color <- as.factor(toyota$Met_Color)
toyota$Automatic <- as.factor(toyota$Automatic)
toyota$Doors <- as.factor(toyota$Doors)

# Train-test split
set.seed(1998)
trainIndex <- createDataPartition(toyota$CAT.Price, p = 0.7, list = FALSE)
trainData <- toyota[trainIndex, ]
testData  <- toyota[-trainIndex, ]

# GLM 
glm_model <- glm(CAT.Price ~ ., data = trainData, family = binomial)
glm_prob <- predict(glm_model, newdata = testData, type = "response")
testData$glm_class <- ifelse(glm_prob >= 0.5, 1, 0)

conf_mat_glm <- confusionMatrix(as.factor(testData$glm_class),
                                as.factor(testData$CAT.Price))
conf_mat_glm


# NEURAL NETWORK 

# Create dummy variables
nn_train <- dummy_cols(trainData, remove_selected_columns = TRUE, remove_first_dummy = TRUE)
nn_test  <- dummy_cols(testData,  remove_selected_columns = TRUE, remove_first_dummy = TRUE)

# Columns to scale (continuous numeric only)
num_vars <- c("Age_08_04","KM","HP","Quarterly_Tax","Weight")

# Scale using training data mean & sd
train_mean <- sapply(nn_train[, num_vars], mean)
train_sd   <- sapply(nn_train[, num_vars], sd)

nn_train[, num_vars] <- scale(nn_train[, num_vars], center = train_mean, scale = train_sd)
nn_test[, num_vars]  <- scale(nn_test[, num_vars], center = train_mean, scale = train_sd)

# Train NN
nn_model <- neuralnet(CAT.Price ~ ., data = nn_train, hidden = c(5,2), linear.output = FALSE)

# Predict NN
nn_pred <- compute(nn_model, nn_test[, -which(names(nn_test) == "CAT.Price")])
nn_prob <- nn_pred$net.result
nn_test$nn_class <- ifelse(nn_prob >= 0.5, 1, 0)

conf_mat_nn <- confusionMatrix(as.factor(nn_test$nn_class),
                               as.factor(nn_test$CAT.Price))
conf_mat_nn

# Plot NN model
plot(nn_model)
