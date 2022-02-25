install.packages("tidygeocoder")
library(readxl)
library(writexl)
library(data.table)
library(ggplot2)
library(class)
library(dplyr)
library(tidyquant)
library(zoo)
library(Metrics)
library(e1071)
library(dplyr)
library(tidygeocoder)
library(tidyverse)
library(stringr)
library(sqldf)

############################## Account payable Excel File  #######################################

#Sheet 1: Vendor Master
setwd("C:/Users/Qing Rui/Desktop/BAC_x_Deloitte_Business_Analytics_Hackathon/Case Study Data")
s1= read_excel("Accounts Payable Data.xlsx", sheet="Vendor Master")
summary(s1)
View(s1)
s1.1=unique(s1) #All data points are unique
s1.2 <- str_split_fixed(s1$Address,",",2) ## split the address into street and postal code
View(s1.2)
s1.2 <- as.data.frame(s1.2)
s1$Street = s1.2$V1 
s1$`Postal Code` =s1.2$V2
coordinates <- s1 %>%  geocode(`Postal Code`) ## retrieve coords for postal code
View(coordinates)
coordinates<-na.omit(coordinates)  ##drop NAs
coordinates1 <- coordinates %>% geocode(Country) ## retrieve coords for country (subsequently unnecessary as tableau can self retrieve for country)
coordinates$countrylat <- coordinates1$lat...15
coordinates$countrylong <- coordinates1$long...16
View(coordinates)
write_xlsx(coordinates,"C:/Users/Qing Rui/Desktop/BAC_x_Deloitte_Business_Analytics_Hackathon/Coordinates.xlsx") ## export to Excel file




# Sheet 2: invoice
s2= read_excel("Accounts Payable Data.xlsx", sheet="Invoice")
summary(s2)
View(s2)
sum(duplicated(s2)) # 814 duplicated entries
s2.1=unique(s2)
View(s2.1)
summary(s2.1) # new unique df with  non-duplicated entries
unique(s2$`Line of the payable list# Amount payable (accounting currency)#`)
#group acc provider and check if annomalies present in sum paid
annom1= aggregate(s2.1$`Line of the payable list# Amount payable (accounting currency)#`, by=list(AccProv=s2.1$`Account provider`), FUN=sum) 
annom1= annom1[order(-annom1$x),] #sort transaction according from highest to lowest
sum(annom1$x) # sum of unique transaction values is $29,914,931 (Total flow transactions)
count(annom1) # 233 unique vendors/accounts

#Obtain new data table with duplicated data
dups2=subset(s2,duplicated(s2$`Line of the payable list# Amount payable (accounting currency)#`))
view(dups2)
annom2= aggregate(dups2$`Line of the payable list# Amount payable (accounting currency)#`, by=list(AccProv=dups2$`Account provider`), FUN=sum) 
annom2= annom2[order(-annom2$x),]
sum(annom2$x) # sum of unique transaction values is $6,079,815 (Total flow transactions)
count(annom2) # 125 unique vendors/accounts

#merge annomalies and duplicated flow transaction sum
annom3=merge(annom1, annom2, by=("AccProv"), all=TRUE) #merge duplicated flow transaction with unique flow transaction to see which vendors have unique transactions and which dont have
annom3=annom3[order(-annom3$`x.y`),]
colnames(annom3)=c('Vendor', 'Unique_Transaction_Sum', ' Duplicated_Transaction_Sum')
annom3$Perc_overpaid=((annom3$` Duplicated_Transaction_Sum`/annom3$Unique_Transaction_Sum)*100) #obtain percentage overpaid of data points/vendor
write_xlsx(annom3,"C:/Users/Qing Rui/Desktop/BAC_x_Deloitte_Business_Analytics_Hackathon/annom3.xlsx")
head(annom3) #Top 6 results by duplicated payment

#Sort data table by percentage overpaid
annom4=annom3
annom4=annom4[order(-annom4$Perc_overpaid),]
head(annom4) #Top 6 results by percentage overpayment


#Sheet 3: Payment
s3= read_excel("Accounts Payable Data.xlsx", sheet="Payment")
summary(s3)
View(s3)
sum(duplicated(s3)) # 1215 duplicated entries
s3.1=unique(s3)
summary(s3.1) # new unique df with  non-duplicated entries





############################## Credit Card Data File  #######################################


df <- fread("Credit Card Data.csv")

summary(df)

## Checking & extracting duplicated Rows
duplicated.data.frame(df)
dup<- df[duplicated(df)]
dup

## Summarizing duplicated data by vendors

dup2 <- aggregate(dup$`Expense Amount`, by=list(Category=dup$`Vendor Name`), FUN=sum)
dup2 <-dup2[order(-dup2$x),]
top6<- head(dup2) # Top 6 companies with highest duplicated transactions. To further investigate

ggplot(data = top6, aes(x= reorder(Category, -x), y=`x`)) + 
  geom_bar(stat="identity") + 
  labs(title = "Value of Duplicated Transactions Top 6 Firms", y="Value", x="Vendor") +  
  theme(text = element_text(size=8), plot.title=element_text(face="bold")) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10))
sum(dup2$x)

## Summarizing duplicated data by employees

dup3 <- aggregate(dup$`Expense Amount`, by=list(Category=dup$`Employee Number`), FUN=sum)
dup3 <-dup3[order(-dup3$x),]
employee<- head(dup3)

ggplot(data = employee, aes(x= reorder(Category, -x), y=`x`)) + 
  geom_bar(stat="identity") + 
  labs(title = "Value of Duplicated Transactions Top 6 Employees", y="Value", x="Employee No.") +  
  theme(text = element_text(size=8), plot.title=element_text(face="bold")) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10))

## Unsubmitted credit card transaction
dup4 <- dup[dup$Status == "UNSUBMITTED",]
dup4 <- aggregate(dup$`Expense Amount`, by=list(Category=dup$`Vendor Name`), FUN=sum)
dup4 <-dup4[order(-dup4$x),]
unsubmitted_claims<- head(dup4)

ggplot(data = employee, aes(x= reorder(Category, -x), y=`x`)) + 
  geom_bar(stat="identity") + 
  labs(title = "Value of Duplicated Transactions Top 6 Employees", y="Value", x="Employee No.") +  
  theme(text = element_text(size=8), plot.title=element_text(face="bold")) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10))




############################## Payroll Data File  #######################################


master = data.table(read_excel("Payroll Data.xlsx", sheet="Employee Master", na = c("-","NA","NULL","")))
payslips = data.table(read_excel("Payroll Data.xlsx", sheet="Payslips", na = c("-","NA","NULL","")))
vendor = data.table(read_excel("Accounts Payable Data.xlsx", sheet="Vendor Master", na = c("-","NA","NULL","")))
pmt = data.table(read_excel("Accounts Payable Data.xlsx", sheet="Payment", na = c("-","NA","NULL","")))

#Remove spaces of headers for easier analysis
names(master) <- gsub(" ", "_", names(master))
names(payslips) <- gsub(" ", "_", names(payslips))
names(vendor) <- gsub(" ", "_", names(vendor))
names(pmt) <- gsub(" ", "_", names(pmt))

View(master)
View(payslips)


sum(is.na(master))
sum(is.na(payslips))


#================================================================================================================
#Ghost Employee Fraud ================================================================================

sum(duplicated(master$Bank_Acct))
#2 duplicated employees

which(duplicated(master$Bank_Acct))
which(duplicated(master$Mobile_Phone,incomparables = NA)) #Same results as bank acct
which(duplicated(master$Home_Phone,incomparables = NA))

#To identify Same Bank Acct Employees
master[Bank_Acct %in% master[duplicated(master$Bank_Acct),Bank_Acct],]
#Employee 20186 = 20186A --> could have promoted or something then never change.
#later will check if being paid
ghostemp = master[Bank_Acct %in% master[duplicated(master$Bank_Acct),Bank_Acct],Employee_Master]
#Employee 0038776 = 0454690 --> possible ghost employee

#To identify 
susghost <- payslips[Employee_ID %in% ghostemp,]

#Cost of Ghost Employee
totalcost = setorder(susghost[,.(TotalCost=sum(Amount)), by= .(Employee_ID,Date)], Employee_ID,Date)
cumucost = totalcost[,.(Cumulated = sum(TotalCost)), by = Employee_ID]

#Cost of Ghost Employee Fraud
#IF 38776 is the Ghost Employee, cost will be the total paid since nobody is actually filling that role:
#$121,208

#IF 454690 is the Ghost Employee, cost will be the total paid since nobody is actually filling that role:
# $763.05

#3 instances 38776 and 454690 paid together on the same month.
#However, both payment schemes are different for different roles. It may be for different work done
# but i feel the standard pracice even for different work done should be paid to same employee.


#Visualisation of Ghost Employee Cost
ggplot(data=totalcost,aes(y = TotalCost, x= Date, group = Employee_ID, color = Employee_ID)) + 
  geom_line() +
  labs(y="$ Amount", x = "Employee ID", title = "Cost to Lumbago for Ghost Employee" )

ggplot(data=cumucost,aes(y = Cumulated, x= Employee_ID)) + 
  geom_col() +
  labs(y="$ Amount", x = "Employee ID", title = "Cost to Lumbago for Ghost Employee" )



#HOME PHONE ================================================


#Just to verify if mobile duplicates same as identified in bank account
mobdup = master[Mobile_Phone %in% master[duplicated(master$Mobile_Phone, incomparables = NA),Mobile_Phone],]
mobdupid = master[Mobile_Phone %in% master[duplicated(master$Mobile_Phone, incomparables = NA),Mobile_Phone],Employee_Master]
phonesus = payslips[Employee_ID %in% mobdupid,]


#HOME DUPLICATES
homeghost = setorder(master[Home_Phone %in% master[duplicated(master$Home_Phone, incomparables = c(NA,8999)),Home_Phone],.(Employee_Master,Home_Phone)],Home_Phone)

#using home phone seems like more duplicates, while one person can have multiple 
#bank accounts, one most likely only have 1 phone number but those number 8999 ignored
#because doesnt seem like legit number. 



susghost1 <- payslips[Employee_ID %in% x[1:2, Employee_Master],] #possible since paid on same date
susghost2 <- payslips[Employee_ID %in% x[3:4, Employee_Master],] #possible
susghost3 <- payslips[Employee_ID %in% x[5:6, Employee_Master],] #possible
susghost4 <- payslips[Employee_ID %in% x[7:8, Employee_Master],] #possible
susghost5 <- payslips[Employee_ID %in% x[9:10, Employee_Master],] #possible
susghost6 <- payslips[Employee_ID %in% x[11:12, Employee_Master],] #possible
susghost7 <- payslips[Employee_ID %in% x[13:14, Employee_Master],] #possible
susghost8 <- payslips[Employee_ID %in% x[15:16, Employee_Master],] #possible

homeghostsal = payslips[Employee_ID %in% homeghost[,Employee_Master],][Relevant_Income=="Yes"]


ggplot(data=homeghostsal,aes(y = sum(Amount) , x= Employee_ID, group = Employee_ID, fill = Employee_ID)) + 
  geom_col() +
  labs(y="$ Amount", x = "Employee ID", title = "Cost to Lumbago for Possible Ghost Employees" )




#Therefore, Employee 38776 and 454690 is likely a ghost employee fraud while
#The rest identified under home phone will require further investigation.






#====================================================================================================
#Advance Fraud================================================================================

unique(payslips[,Payment_Sub_Type])

advance = setorder(payslips[Employee_ID == "0059766",],Date)
#can't seem to find any advance, only advance deduction i dont get. 


# ====================================================================================================
#Pay Rate Alteration Fraud
unique(master[,Employment_Type])

#Total Salary
ppersontot = setorder(payslips[,.(MonthlyAmt =sum(Amount,na.rm=TRUE)),by = .(Employee_ID,Date)], Employee_ID,Date)

#To see if any changes from one pay to another
ppersontot = ppersontot[, change := ifelse(Employee_ID == shift(Employee_ID, 1L, type="lag"),(MonthlyAmt-shift(MonthlyAmt, 1L, type="lag")),NA)]
erratictot = ppersontot[change != 0|NA,]
netnotzerotot = erratictot[, .(NetChange= sum(MonthlyAmt, na.rm=TRUE)), by = Employee_ID]

combinedtot = setorder(master[netnotzerotot, on=.(Employee_Master=Employee_ID)], -NetChange)
combinedtotloss = combinedtot[,.(totloss = sum(NetChange)),]

#BASIC SALARY ONLY
ppersonbas = setorder(payslips[Payment_Sub_Type == "Ordinary",.(MonthlyAmt =sum(Amount,na.rm=TRUE)),by = .(Employee_ID,Date)], Employee_ID,Date)

#To see if any changes from one pay to another
ppersonbas = ppersonbas[, change := ifelse(Employee_ID == shift(Employee_ID, 1L, type="lag"),(MonthlyAmt-shift(MonthlyAmt, 1L, type="lag")),NA)]
erraticbas = ppersonbas[change != 0|NA,]
netnotzerobas = erraticbas[, .(NetChange= sum(MonthlyAmt, na.rm=TRUE)), by = Employee_ID]

combinedbas = setorder(master[netnotzerobas, on=.(Employee_Master=Employee_ID)], -NetChange)

combinedloss = combinedbas[,.(basloss = sum(NetChange)),]

#================================================================================
#Pension Allocation Fraud

#Brackets setting
b1 = 0 # < 7100
b2 = 0.05 # 7100 < 30000
b3 = 1500 # 7100
income = payslips[Payment_Type != "Pension",.(MonthlyAmt =sum(Amount,na.rm=TRUE)),by = .(Employee_ID,Date)]
income[, pension := ifelse(MonthlyAmt < 7100, 0, ifelse( MonthlyAmt <30000, round(0.05*MonthlyAmt,2), 1500))]

pentbl = payslips[Payment_Type == "Pension",.(givenpen =sum(Amount,na.rm=TRUE)),by = .(Employee_ID,Date)]


verify= income[pentbl, on= .(Employee_ID=Employee_ID,Date=Date)]
incorrectpension = verify[pension != givenpen,][,diff := givenpen-pension]
overdrawn = incorrectpension[diff > 0,]
#all rounding error 0.01 only

#========================================================================================================
# False Vendors====================================================================================

empbanklist = master[!is.na(Bank_Acct),Bank_Acct]

susvendors = vendor[Supplier_receiving_bank_account %in% empbanklist ,]

susvenbank = susvendors[,Ven_ID]

suspmt = pmt[Vendor_ID %in% susvenbank,]

fakeveneff= suspmt[,.(losses =sum(Total_Amount, na.rm=TRUE)), by = .(Vendor_ID,Payment_Date)]
totlossperemp = fakeveneff[, .(total_loss = sum(losses)), by = Vendor_ID]


#Identify Fake Employee
empven = susvendors[Ven_ID %in% c("F0086", "NBSZ"),Supplier_receiving_bank_account]
empven = master[Bank_Acct %in% empven, Employee_Master]

#Highlighted Employees
#290323 & 321638


#Total Losses made by potential fraudulent activity:
# 
# F0086 = $2,340,342
# 
# NBSZ = $1,744,018


#Visualisation of Employee receiving money from Lumbago Bank as a fake vendor
ggplot(data=fakeveneff,aes(x = Payment_Date, y= losses, group= Vendor_ID, color = Vendor_ID) ) + 
  geom_line() +
  labs(y="$ Amount", x = "Month", title = "Employee as Fake Vendor Over the Months" )

#Visualisation of Total Amount Received From Potential Fraud

ggplot(data=fakeveneff,aes(y = Payment_Date, x= Vendor_ID)) + 
  geom_col() +
  labs(y="$ Amount", x = "Vendor ID", title = "Cost to Lumbago for Fake Vendor" )

#==========






