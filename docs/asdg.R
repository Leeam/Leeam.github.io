setwd("C:/Users/liamj/Desktop/SummerProj")
data <- read.csv("NHLStuff.csv")

numGames<-dim(data)[1]
#Add a column to Denote a W or L for each team in each game 
winLossList<-c()
expWinLoss<-c()
for  (i in seq(1,numGames,2)){
  if (data$Final[i] > data$Final[i+1]){
    winLossList<-append(winLossList,c("W","L"))
  }
  else{
    winLossList<-append(winLossList,c("L","W"))
  }
  #Add a column for the betting expected wins
  if (data$Open[i]<0 && data$Open[i+1]>0){
    expWinLoss<-append(expWinLoss,c("W","L"))
  }
  else if (data$Open[i]>0 && data$Open[i+1]<0){
    expWinLoss<-append(expWinLoss,c("L","W"))
  }
  else{
    expWinLoss<-append(expWinLoss,c("E","E"))
  }
}

#Create a column for the Even Games Exp Win/Loss, treat them as a CI of sorts
EvenWinLoss<-c()
for  (i in seq(1,numGames,2)){
  if ((data$Open[i]<0 && data$Open[i+1]>0) ||
    (data$Open[i]<0 && data$Open[i+1]<0 && data$Open[i]<data$Open[i+1])){
    EvenWinLoss<-append(EvenWinLoss,c("W","L"))
  }
  else if ((data$Open[i]>0 && data$Open[i+1]<0) ||
    (data$Open[i]<0 && data$Open[i+1]<0 && data$Open[i]>data$Open[i+1])){
    EvenWinLoss<-append(EvenWinLoss,c("L","W"))
  }
  else {
    EvenWinLoss<-append(EvenWinLoss,c("E","E"))
  }
}
data<-cbind(data, expWinLoss, winLossList,EvenWinLoss)

#implied win odds
impliedWinOdds<-c()
for  (i in seq(1,numGames,1)){
  if (data$Open[i]<0){
    impliedWinOdds<-append(impliedWinOdds,abs(data$Open[i])/(abs(data$Open[i])+100))
  }
  else{
    impliedWinOdds<-append(impliedWinOdds,100/(abs(data$Open[i])+100))
  }
}
betOdds<-cbind(data,impliedWinOdds)

#Find the Actual Odds without Vig
actualOdds<-c()
for  (i in seq(1,numGames,2)){
  sum<-betOdds$impliedWinOdds[i]+betOdds$impliedWinOdds[i+1]
  actualOdds<-append(actualOdds,betOdds$impliedWinOdds[i]/sum)
  actualOdds<-append(actualOdds,betOdds$impliedWinOdds[i+1]/sum)
}
#Create the joint dataset
betOdds<-cbind(betOdds,actualOdds)


#Making a dataset of only the regular season
regSeas<-betOdds[1:2624,]

#organizing by team
library(dplyr)
teamNames<-unique(betOdds$Team)
teamNamesFormatted<-c("Pittsburgh","Tampa Bay","Seattle", "Vegas","Rangers","Washington",
                      "Montreal","Toronto","Vancouver","Edmonton", "Chicago","Colorado", 
                      "Winnipeg", "Anaheim", "Ottawa", "Buffalo", "Florida", "Islanders",
                      "Carolina", "Dallas", "Arizona", "Columbus", "Detroit", "Nashville",
                      "Los Angles", "New Jersey", "Philadelphia", "Minnesota", "Boston", 
                      "St.Louis", "Calgary", "San Jose")

winCount<-c()
lossCount<-c()
expEWinCount<-c()
expELossCount<-c()
expEEvenCount<-c()
for (i in teamNames){
  subData=subset(regSeas, Team==i)
  winCount<-append(winCount,count(subData,winLossList=='W')[2,2])
  lossCount<-append(lossCount,count(subData,winLossList=='L')[2,2])
  expEWinCount<-append(expEWinCount,count(subData,EvenWinLoss=='W')[2,2])
  expELossCount<-append(expELossCount,count(subData,EvenWinLoss=='L')[2,2])
  expEEvenCount<-append(expEEvenCount,count(subData,EvenWinLoss=='E')[2,2])
}
teamsWinsLoss<-data.frame(teamNames,winCount,
                          lossCount,expEWinCount,expELossCount,expEEvenCount)
teamsWinsLoss <- replace(teamsWinsLoss, is.na(teamsWinsLoss), 0)

winsWithEvens<-teamsWinsLoss$expEWinCount+1/2*teamsWinsLoss$expEEvenCount
teamsWinsLoss<-data.frame(teamNames,winCount,
                          lossCount,expEWinCount,expELossCount,expEEvenCount,winsWithEvens)

#Testing the colour application
library(colorspace)
cols <- rev(diverge_hcl(32)) # diverge from red to blue
cols <- cols[as.numeric(cut(teamsWinsLoss$winsWithEvens,breaks = 32))]

#add in Final positions for the season 
finalPositions<-c(12,8,30,17,7,13,32,4,18,11,27,2,19,23,
                  26,24,1,20,3,15,31,21,25,16,14,28,29,5,10,9,6,22)

#Colour palletes for the reactable
getCols<-function(valueSet){
  colourScale<-rev(diverge_hcl(32))
  colourScale <- colourScale[as.numeric(cut(valueSet,breaks = 32))]
  return(colourScale)
}
colsWinCount<-getCols(winCount)
diffCol<-getCols(winDifferential)

#Find the projected wins by using the implied win probability
winSums<-c()
for (i in teamNames){
  subData=subset(betOdds, Team==i)
  winSums<-append(winSums,sum(subData$actual))
}
winSums<-round(winSums,1)
impCol<-getCols(winSums)

#image files for the teams
{
  img_df <- c(
    "https://upload.wikimedia.org/wikipedia/en/c/c0/Pittsburgh_Penguins_logo_%282016%29.svg",
    "https://upload.wikimedia.org/wikipedia/en/2/2f/Tampa_Bay_Lightning_Logo_2011.svg",
    "https://upload.wikimedia.org/wikipedia/en/4/48/Seattle_Kraken_official_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/a/ac/Vegas_Golden_Knights_logo.svg",
    "https://upload.wikimedia.org/wikipedia/commons/a/ae/New_York_Rangers.svg",
    "https://upload.wikimedia.org/wikipedia/commons/2/2d/Washington_Capitals.svg",
    "https://upload.wikimedia.org/wikipedia/commons/6/69/Montreal_Canadiens.svg",
    "https://upload.wikimedia.org/wikipedia/en/b/b6/Toronto_Maple_Leafs_2016_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/3/3a/Vancouver_Canucks_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/4/4d/Logo_Edmonton_Oilers.svg",
    "https://upload.wikimedia.org/wikipedia/en/2/29/Chicago_Blackhawks_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/4/45/Colorado_Avalanche_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/9/93/Winnipeg_Jets_Logo_2011.svg",
    "https://upload.wikimedia.org/wikipedia/en/7/72/Anaheim_Ducks.svg",
    "https://upload.wikimedia.org/wikipedia/en/b/b2/Ottawa_Senators_2020-2021_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/9/9e/Buffalo_Sabres_Logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/4/43/Florida_Panthers_2016_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/4/42/Logo_New_York_Islanders.svg",
    "https://upload.wikimedia.org/wikipedia/en/3/32/Carolina_Hurricanes.svg",
    "https://upload.wikimedia.org/wikipedia/en/c/ce/Dallas_Stars_logo_%282013%29.svg",
    "https://upload.wikimedia.org/wikipedia/en/9/9e/Arizona_Coyotes_logo_%282021%29.svg",
    "https://upload.wikimedia.org/wikipedia/en/5/5d/Columbus_Blue_Jackets_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/e/e0/Detroit_Red_Wings_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/9/9c/Nashville_Predators_Logo_%282011%29.svg",
    "https://upload.wikimedia.org/wikipedia/en/6/63/Los_Angeles_Kings_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/9/9f/New_Jersey_Devils_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/d/dc/Philadelphia_Flyers.svg",
    "https://upload.wikimedia.org/wikipedia/en/1/1b/Minnesota_Wild.svg",#
    "https://upload.wikimedia.org/wikipedia/en/1/12/Boston_Bruins.svg",
    "https://upload.wikimedia.org/wikipedia/en/e/ed/St._Louis_Blues_logo.svg",
    "https://upload.wikimedia.org/wikipedia/en/6/61/Calgary_Flames_logo.svg",#
    "https://upload.wikimedia.org/wikipedia/en/3/37/SanJoseSharksLogo.svg"
  )
}
