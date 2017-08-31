# CSV-File
Parse the Metoffice.gov.uk url to get the weather data and store it in .csv format.

BaseURL: http://www.metoffice.gov.uk/climate/uk/summaries/datasets#Yearorder
In this url there were two types of data one is "Year ordered statistics" and other is "Rank ordered statistics".
This is made for "Year ordered statistics".

Here the fetched text files are handled locally , if one need to store the data in Database then, change the code inside

func storeData(parsedString getValue:String, forCountry name:String,  forValue value:String) -> Void {
        // at proper place    
 }
 
 This method is used to create and save the .csv file ; it is also termed as "tab delimited text"
 
 func createCSVFile(finalArray tempArray:[[String]]) -> Void {
        
    }

Hope You Enjoyed the code; Cheers Coders!!!!
