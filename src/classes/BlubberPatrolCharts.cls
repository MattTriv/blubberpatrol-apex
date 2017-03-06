public class BlubberPatrolCharts{
    //Methods marked "Old" use the original Google Chart API. "New" methods use the newer Google Visualization API.
    //These are automatic properties. You don't have to put code in the get() and set() methods.
    public integer numberOfDailyBars {get;set;}
    public integer numberOfWeeklyBars {get;set;}
    public integer numberOfMonthlyBars {get;set;}
    public integer numberOfQuarterlyBars {get;set;}
    public integer numberOfYearlyBars {get;set;}
    public String statusValue{get;set;}      
    public String selectedRadioVal{get;set;}
    public String chartURL {get;set;}
    public string chartData {get;set;}
    public string chartOptions {get;set;}
    public string whichAPI {get;set;}
    // The next two properties are for the installation process:
    public string pollerOn {get;set;}
    public string showProgress {get;set;}
    
    @TestVisible 
    public class chartDatapoint {
        //Holds datapoints, and axis labels for the old API in date2.
        public double weight {get;set;}
        public string date1  {get;set;}
        public string date2  {get;set;}
    }

    //Constructor:
    public BlubberPatrolCharts(){
        selectedRadioVal='dailyChart'; //Set the default radio button. There is no "checked" attribute like in HTML.
        numberOfDailyBars=30;
        numberOfWeeklyBars=20;
        numberOFMonthlyBars=12;
        numberOfQuarterlyBars=4;
        numberOfYearlyBars=7;
        whichAPI='oldAPI';
		updateStatus();
        showProgress='display: none;';
        integer n = [Select count() From Weight__c];
        if (n==0) {
            // This is a new install, so show the progress message, switch
            // on the poller, and wait for it to call makeData().
            showProgress='display: block;';
            pollerOn='true';
        } else { 
            // This is a regular launch, so just make the default chart.
            showProgress='display: none;';
            pollerOn='false';
            makeChart();
        }
    }
    
    //The next three methods are "Action Methods" which are triggered by buttons, links, etc. And controls tagged with apex:actionSupport.
	public void updateStatus(){
        if (selectedRadioVal=='dailyChart'){statusValue='Please enter 1 to 60 days.';}
        if (selectedRadioVal=='weeklyChart') {statusValue='Please enter 1 to 52 weeks.';}
        if (selectedRadioVal=='monthlyChart'){statusValue='Please enter 1 to 36 months.';}
        if (selectedRadioVal=='quarterlyChart'){statusValue='Please enter 1 to 36 quarters.';}
        if (selectedRadioVal=='yearlyChart') {statusValue='Please enter 1 to 10 years.';}
	}

    public void makeData() {
        // We need a way to automatically load the sample data into the db during a new installation.
        // Since an unmanaged package cannot use the installHandler interface, this is our workaround.
        // And since DML cannot be used in the constructor, we needed antoher mechanism to trigger it.
        // The actionPoller on the VF page fires 5 seconds after the page loads, and triggers this
        // method when the constructor doesn't find any data. I would prefer 1 second, but 5 is the minimum.
        // Turn the poller off immediately; we never want it to fire more than once:
        pollerOn='false'; 
        // We don't need to check this again, but we just want to be extra vigilant against
        // the possibility of a bug on the VF page creating duplicate data.
        integer n = [Select count() From Weight__c];
        if (n==0) {
            StaticResource sr = [select Body from StaticResource where Name = 'BPData'];
            List<Weight__c> theData = (List<Weight__c>) JSON.deserialize(sr.Body.toString(), List<Weight__c>.class);
            // Now, see if the data needs "freshening." We need to do this because otherwise the "LAST-N" SOQL
            // functions that we use may not return any data. Plus, we want the app to look up-to-date. So, we find
            // the most-recent record in the list, calculate the days between that and today, and increment all the
            // records by that amount. The difference will be zero on days where I upload a new release with a fresh
            // JSON file of data AND somebody installs the package on that day. We don't want to rely upon the JSON
            // file being in chronological order. We could sort the list, and then take element n-1, but it is probably
            // faster to just run through and take the largest date. We can't query that db usng the max() function
            // because of course there is nothing in the db yet.
            Date maxDate = Date.newInstance(1960, 1, 1);
            for (Weight__c w : theData) if (w.Date__c > maxDate) maxDate = w.Date__c;
            integer daysToAdd = maxDate.daysBetween(Date.today());
            if (daysToAdd>0) for (integer i=0;i<theData.size();i++) theData[i].Date__c=theData[i].Date__c.addDays(daysToAdd);
            System.debug(' makeData() added this many days to each record: ' + daysToAdd);
            insert theData;
            showProgress='display: none;';
            makeChart();
        } else {    
            // If data is already present, then the app should work normally. So, no need to bother the user.
            System.debug(' - makeData() did not have to import sample data. This should never happen.');
        }
    }

    public void makeChart(){
        chartURL=''; chartData=''; chartOptions='';
        
        Try{
           if (selectedRadioVal=='dailyChart')
              if (whichAPI == 'oldAPI')
                  makeDailyChartOld(numberOfDailyBars);
              else
                 makeDailyChartNew(numberOfDailyBars);
            if (selectedRadioVal=='weeklyChart')	
                if (whichAPI == 'oldAPI')
                    makeWeeklyChartOld(integer.ValueOf(numberOfWeeklyBars));
                else
                    makeWeeklyChartNew(integer.ValueOf(numberOfWeeklyBars));
            if (selectedRadioVal=='monthlyChart')	
                if (whichAPI == 'oldAPI') 
                    makeMonthlyChartOld(Integer.ValueOf(numberOfMonthlyBars));
                else
                    makeMonthlyChartNew(Integer.ValueOf(numberOfMonthlyBars));
            if (selectedRadioVal=='quarterlyChart')	
                if (whichAPI == 'oldAPI') 
                    makeQuarterlyChartOld(Integer.ValueOf(numberOfQuarterlyBars));
                else
                    makeQuarterlyChartNew(Integer.ValueOf(numberOfQuarterlyBars));
            if (selectedRadioVal=='yearlyChart')
                if (whichAPI == 'oldAPI') 
                    makeYearlyChartOld(Integer.ValueOf(numberOfYearlyBars));
                else
                    makeYearlyChartNew(Integer.ValueOf(numberOfYearlyBars));
        } catch (exception e) {
            statusValue='Something went wrong.';
        }
    }

    private void makeYearlyChartNew(integer years){  
        string s, year;
        decimal x, w;
        List<string> elements = new List<string>();
        // For the old API, we build a string of data & options. We also build a string for the new API, 
        // however, it is a string of array elements, and the syntax is much more tricky. Example:
        //
        // ['Year', 'Weight', {role: 'style'}], ['2015', 152.38, 'color: #1798c1'], ['2016', 148.80, 'color: #1798c1'], ['2017', 149.86, 'color: #1798c1']
        //
        // The first element is column headings. Elements are enclosd with square brackets and delimited by commas.
        // The square brackets will cause JavaScript to evaluate the string as a set of array elements when it passes
        // the string to the API. Because of this, you can't put the string into a variable and then pass it to the
        // API. Your JS can only touch it once. We also have to escape the quotes in Apex to get them into the string:

        chartData='\'Year\', \'Weight\', {role: \'style\'}]';

        //Using LIMIT gets us the first n records, when we want the most-recent instead. Using DESC gets them, but in the 
        //wrong order. In SQL, we could do this with an outer query sorting the results of a subquery, but SOQL doesn't 
        //seem to support that. Instead, we will put our strings in a List, and then step through backwards, building the 
        //chartData string.
          
        for (aggregateResult results: [Select Calendar_Year(Date__c) Year, Avg(Weight__c) AveWeight from Weight__c Where (Weight__c > 0) Group By Calendar_Year(Date__c) Order By Calendar_Year(Date__c) DESC LIMIT :years]) {
            //We need two decimal variables to do rounding:
            s=string.valueOf(results.get('AveWeight'));
            x=Decimal.valueOf(s);
            w=x.setScale(2);
            year=string.valueOf(results.get('Year'));
            elements.add('[\'' + year + '\', ' + w + ', \'color: #1798c1\']'); //Salesforce blue color.)
        }

        for(integer i=elements.size()-1; i>=0; i--) {chartData += ', ' + elements[i];} //Add to chartData in reverse order.

        //Remove the last square bracket. We leave off the first and last brackets because they are added on the VF page:
        if (chartData.endsWith(']')){chartData=chartData.left(chartData.length()-1);} 
        
        setChartOptions('Yearly Weight');
    }

    private void makeYearlyChartOld(integer years){    
        decimal x=0.00; decimal w=0.00;
        string s, year;
        chartDatapoint cd;
        List<chartDatapoint> theData=new List<chartDatapoint>();
        
        //We get the data in DESC order, so need to push onto the arrays. See notes in 'new' method.
        for (aggregateResult results: [Select Calendar_Year(Date__c) Year, Avg(Weight__c) AveWeight from Weight__c Where (Weight__c > 0) Group By Calendar_Year(Date__c) Order By Calendar_Year(Date__c) DESC LIMIT :years]) {
            //We need two decimal variables to do rounding:
            s=string.valueOf(results.get('AveWeight'));
            x=Decimal.valueOf(s);
            w=x.setScale(2);
            year=string.valueOf(results.get('Year'));
            cd=new chartDatapoint();
            cd.weight=w;
            cd.date1=year;
            cd.date2='';
            //Can't push until there is at least one element in the list:            
            if (theData.size()==0) theData.add(cd); else theData.add(0,cd);
        }
        formatChartOld(theData,'Yearly Weight');
        //Undelete the next line when testing the install process. Once the package is installed on a 
        //different org, you can debug from the developer console, and will need an empty db.
        //delete [select id from Weight__c];
    }

    private void makeQuarterlyChartNew(integer quarters){ 
        decimal x=0.00; decimal w=0.00;
        string s, year;
        integer iYear; integer startAt=0;
        boolean skip=false;
        List<Double> data = new List<Double>();
        List<String> labels = new List<String>();

        chartData='\'Quarter\', \'Weight\', {role: \'style\'}]';
        
        //There doesn't seem to be a way to get SOQL to aggregate on quarters. You can do it in reports, but they 
        //probably use more than one query like we do here. We could use the same algorithm that we used for the 
        //monthly chart, however this is likely faster since we are bringing back a lot fewer records. So, we calculate
        //all of the quarters in th db, and then only present the most recent n months specified by the user.
        
        //In the outer loop, we traverse all the years in the db chronologically. SOQL has no DISTINCT function, so we use Group By:
        for (aggregateResult years: [Select Calendar_Year(Date__c) Year, count(ID) from Weight__c Group By Calendar_Year(Date__c) Order By Calendar_Year(Date__c)]) {
            year=string.valueOf(years.get('Year'));
            iYear=Integer.valueOf(year);
            //In the inner loop, we query once for each quarter of the year.
            for (integer i=1; i<5; i++){
                //This next For-Loop will only execute once. Could't figure out how to make it a simple query:
                for (aggregateResult results: [Select Avg(Weight__c) AveWeight from Weight__c Where Calendar_Year(Date__c)=:iYear and Calendar_Quarter(Date__c)=:i]){
                    s=string.valueOf(results.get('AveWeight'));
                    //Some quarters will not have any data, like when you are in January of a new year, the last three quarters will be null.
                    if (s != null){
                        x=Decimal.valueOf(s);
                        w=x.setScale(2);
                        data.add(w);
                        labels.add(i + 'Q' + year.substring(2,4));
                    }
                }
            }
        }

        //If the user specifies more bars than we have data for, print them all. Otherwise, print just the number they specified:
        if (quarters>data.size()){startAt=0;} else {startAt=data.size()-quarters;}
        for (integer i=startAt; i<data.size(); i++) {chartData += ',[\'' + labels[i] + '\', ' + data[i] + ', \'color: #1798c1\']';}
        if (chartData.endsWith(']')){chartData=chartData.left(chartData.length()-1);} 
        setChartOptions('Quarterly Weight');   
    }

    private void makeQuarterlyChartOld(integer quarters){    
        decimal x=0.00; decimal w=0.00;
        string s, year;
        integer iYear; integer startAt=0;
        boolean skip=false;
        List<Double> data = new List<Double>();
        List<String> labels = new List<String>();
        chartDatapoint cd;
        List<chartDatapoint> theData = new List<chartDatapoint>();
        
        //See the comments in makeQuarterlyChartNew().
        
        //First pass.
        for (aggregateResult years: [Select Calendar_Year(Date__c) Year, count(ID) from Weight__c Group By Calendar_Year(Date__c) Order By Calendar_Year(Date__c)]) {
        	year=string.valueOf(years.get('Year'));
            iYear=Integer.valueOf(year);
            for (integer i=1; i<5; i++){
                for (aggregateResult results: [Select Avg(Weight__c) AveWeight from Weight__c Where Calendar_Year(Date__c)=:iYear and Calendar_Quarter(Date__c)=:i]){
                    s=string.valueOf(results.get('AveWeight'));
                    if (s != null){
                		x=Decimal.valueOf(s);
                		w=x.setScale(2);
                        data.add(w);
                        labels.add(i + 'Q' + year.substring(2,4));
                    }
                }
            }
        }
        
        //Second pass.
        if (quarters>data.size()){startAt=0;} else {startAt=data.size()-quarters;}
		for (integer i = startAt; i < data.size(); i++) {
            cd=new chartDatapoint();
            cd.weight=data[i];
            cd.date2=''; //The second x axis is not used on this chart, so fill it up with blanks.
            if (quarters>12){
				//Put a label on every other bar:
                //skip=!skip; //Don't know why this doesn't work.
                if (skip==false) {skip=true;} else {skip=false;}
                if (skip) {
                    cd.date1='';
                } else {
                    cd.date1=labels[i];
                }
            } else {
                cd.date1=labels[i]; //Put a label on every bar.
            }
            theData.add(cd);
        }
        formatChartOld(theData,'Quarterly Weight');
    }
    
    private void makeMonthlyChartNew(integer months){   
        decimal totalWeight=0.0; decimal x=0.0; decimal w=0.0;
        string s, sql, thisMonthYear, lastMonthYear, displayDate;
        integer datapoints=0; integer startAt=0;
        Date tempDate;
        List<Double> data = new List<Double>();
        List<String> labels = new List<String>();

        chartData='\'Month\', \'Weight\', {role: \'style\'}]';
          
        //We have to use Dynamic SOQL here because the colon prevents the months variable from being concatenated:
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_MONTHS:' + months + ') and (Weight__c > 0) Order By Date__c';
        
        //Put the results into a list and aggregate manually:
        List<Weight__c> results = Database.query(sql);
        Weight__c lastRec=results[0];
        lastMonthYear=string.valueOf(lastRec.Date__c.month()) + string.valueOf(lastRec.Date__c.year());
        tempDate=lastRec.Date__c;
        displayDate=monthName(tempDate.month());  
        for (Weight__c rec : results) {
            thisMonthYear=string.valueOf(rec.Date__c.month()) + string.valueOf(rec.Date__c.year());
            if (thisMonthYear<>lastMonthYear){
                //We are on the first day of the next month, so we need to save totals for the previous month.
                x=totalWeight/datapoints;
                w=x.setScale(2);            
                data.add(w);
                labels.add(displayDate);
                lastMonthYear=thisMonthYear;
                datapoints=0;
                totalWeight=0;
            }
            datapoints++;
            totalWeight += rec.Weight__c;
            tempDate=rec.Date__c;
            displayDate=monthName(tempDate.month());   
        }
        x=totalWeight/datapoints;
        w=x.setScale(2);
        data.add(w);
        labels.add(displayDate);

        //If the user specifies more bars than we have data for, print them all. Otherwise, print just the number they specified:
        if (months>data.size()){startAt=0;} else {startAt=data.size()-months;}
        for (integer i=startAt; i<data.size(); i++) {chartData+=',[\''+labels[i]+'\','+data[i]+', \'color: #1798c1\']';}
        if (chartData.endsWith(']')){chartData=chartData.left(chartData.length()-1);} 
        setChartOptions('Monthly Weight'); 
    }

    private void makeMonthlyChartOld(integer months){    
		decimal totalWeight=0.0; decimal x=0.0; decimal w=0.0;
        string s, sql, thisMonthYear, lastMonthYear, displayDate;
        boolean skip=false;
        integer datapoints=0; integer startAt=0; integer skipNo=0;
        Date tempDate;
        List<Double> data = new List<Double>();    //These 3 lists are used in the first pass of data.
        List<String> labels = new List<String>();  //These 3 lists are used in the first pass of data.
        List<String> labels2 = new List<String>(); //These 3 lists are used in the first pass of data.
        chartDatapoint cd;
        List<chartDatapoint> theData = new List<chartDatapoint>();
          
        //We have to use Dynamic SOQL here because the colon prevents the months variable from being concatenated:
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_MONTHS:' + months + ') and (Weight__c > 0) Order By Date__c';
        
        //In the first pass, we put the results into a list and aggregate manually:
		List<Weight__c> results = Database.query(sql);
        Weight__c lastRec=results[0];
        lastMonthYear=string.valueOf(lastRec.Date__c.month()) + string.valueOf(lastRec.Date__c.year());
        tempDate=lastRec.Date__c;
        displayDate=monthName(tempDate.month());       
        for (Weight__c rec : results) {
            thisMonthYear=string.valueOf(rec.Date__c.month()) + string.valueOf(rec.Date__c.year());
            if (thisMonthYear<>lastMonthYear){
                //We are on the first day of the next month, so we need to save totals for the previous month.
              	x=totalWeight/datapoints;
                w=x.setScale(2);            
                data.add(w);
                labels.add(displayDate);
                if (displayDate=='Jan') labels2.add(string.valueOf(tempDate.year())); else labels2.add('');
                lastMonthYear=thisMonthYear;
                datapoints=0;
                totalWeight=0;
        	}
            datapoints++;
            totalWeight += rec.Weight__c;
            tempDate=rec.Date__c;
            displayDate=monthName(tempDate.month());   
		}
        x=totalWeight/datapoints;
        w=x.setScale(2);
        data.add(w);
        labels.add(displayDate);
        if (displayDate=='Jan') labels2.add(string.valueOf(tempDate.year())); else labels2.add('');

        //In the second pass, we figure out which labels to print. If the user specifies more bars than we have data for,
        //print them all. Otherwise, print just the number they specified:
        if (months>data.size()){startAt=0;} else {startAt=data.size()-months;}
        for (integer i=startAt; i<data.size(); i++) {
            cd=new chartDatapoint();
            cd.weight=data[i];
            cd.date2=labels2[i];
            //Apex has no CASE statement. So, we use IFs:
            if (months<=12) cd.date1=labels[i]; //Put a label on every bar.
            if (months>12 && months<=24){
				//Put a label on every other bar:
                if (skip==false) {skip=true;} else {skip=false;}
                if (skip) cd.date1=''; else cd.date1=labels[i];
            }
            if (months>24){
				//Put a label on every third bar:
                if (skipNo<>3) {
                    skipNo++;
                    cd.date1='';
                } else {
                    skipNo=0;
                    cd.date1=labels[i];
                }
            }
            theData.add(cd);            
        }
        formatChartOld(theData,'Monthly Weight');
    }

    private void makeWeeklyChartNew(integer weeks){
        decimal totalWeight=0.0; decimal x=0.0; decimal w=0.0;
        string s, year, sql, weekYear, last, displayDate;
        integer datapoints=0; integer startAt=0; integer weekNo=0;
        DateTime dt=DateTime.newInstance(2017,01,01);
        List<String> data = new List<String>();
        List<String> labels = new List<String>();

        chartData='\'Month\', \'Weight\', {role: \'style\'}]';
        
        //We have to use Dynamic SOQL here because the colon prevents the months variable from being concatenated:
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_WEEKS:' + weeks + ') and (Weight__c > 0) Order By Date__c';
        
        //Put the results into a list and aggregate manually:
        List<Weight__c> results = Database.query(sql);
        //I think the first record will always be a Sunday when we complete data.
        dt=results[0].Date__c;
        displayDate=dt.format('MMM dd yy');
        last=dt.format('w') + dt.format('YYYY');
        for (Weight__c rec : results) {
            dt=rec.Date__c;
            weekYear=dt.format('w') + dt.format('YYYY');
            if (weekYear<>last){
                x=totalWeight/datapoints;
                w=x.setScale(2);            
                data.add(String.valueOf(w));
                labels.add(displayDate);
                displayDate=dt.format('MMM dd yy');
                last=weekYear;
                datapoints=1;
                totalWeight=rec.Weight__c;
            } else {
                datapoints++;
                totalWeight += rec.Weight__c;
            }
        }
        
        x=totalWeight/datapoints;
        w=x.setScale(2);
        data.add(String.valueOf(w));
        labels.add(displayDate);
        
        //If the user specifies more bars than we have data for, print them all. Otherwise, print just the number they specified:
        if (weeks>data.size()){startAt=0;} else {startAt=data.size()-weeks;}
        for (integer i=startAt; i<data.size(); i++) {chartData+=',[\''+labels[i]+'\','+data[i]+', \'color: #1798c1\']';}
        if (chartData.endsWith(']')){chartData=chartData.left(chartData.length()-1);} 
        setChartOptions('Weekly Weight'); 
    }

    private void makeWeeklyChartOld(integer weeks){
		decimal totalWeight=0.0; decimal x=0.0; decimal w=0.0;
        string s, year, chd, chxl, sql, weekYear, last, displayDate;
        boolean skip=false;
        integer datapoints=0; integer startAt=0; integer skipNo=0; integer weekNo=0;
        DateTime dt=DateTime.newInstance(2017,01,01);
        List<double> data = new List<double>();
        List<String> labels = new List<String>();
        chartDatapoint cd;
        List<chartDatapoint> theData = new List<chartDatapoint>();
          
        //We have to use Dynamic SOQL here because the colon prevents the months variable from being concatenated:
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_WEEKS:' + weeks + ') and (Weight__c > 0) Order By Date__c';
        
        //The first pass is to aggregate, and put the data into temporary arrays:
		List<Weight__c> results = Database.query(sql);
        dt=results[0].Date__c;
        displayDate=dt.format('MMM dd yy');
        last=dt.format('w') + dt.format('YYYY');
        for (Weight__c rec : results) {
            dt=rec.Date__c;
            weekYear=dt.format('w') + dt.format('YYYY');
            if (weekYear<>last){
              	x=totalWeight/datapoints;
                w=x.setScale(2);         
                data.add(w);
                labels.add(displayDate); //Every datapoint gets a label for now.
                displayDate=dt.format('MMM dd yy');
                last=weekYear;
                datapoints=1;
                totalWeight=rec.Weight__c;
        	} else {
            	datapoints++;
                totalWeight += rec.Weight__c;
           	}
		}
        
		x=totalWeight/datapoints;
        w=x.setScale(2);
        data.add(w);
        labels.add(displayDate);
        
        //The second pass is to decide which labels to keep, and transfer the data into an array of chartData objects. If
        //the users specifies more bars than we have data for, print them all. Otherwise, print just the number they specified:
        if (weeks>data.size()){startAt=0;} else {startAt=data.size()-weeks;}
        for (Integer i = startAt; i < data.size(); i++) {
            cd = new chartDatapoint();
            cd.weight=data[i];
            cd.date2=''; //The second row of x-axis labels is not used on this chart.
            
            //Apex has no CASE statement. So, we use IFs:
            if (weeks<=8) cd.date1=labels[i]; //Put a label on every bar.
            if (weeks>8 && weeks<=16){
				//Put a label on every other bar:
                if (skip==false) skip=true; else skip=false;
                if (skip) cd.date1=''; else cd.date1=labels[i];
            }
            if (weeks>16 && weeks<=32){
				//Put a label on every third bar:
                if (skipNo<>3) {
                    skipNo++;
                    cd.date1='';
                } else {
                    skipNo=0;
                    cd.date1=labels[i];
                }
            }         
            if (weeks>32){
				//Put a label on every fifth bar:
                if (skipNo<>10) {
                    skipNo++;
                    cd.date1='';
                } else {
                    skipNo=0;
                    cd.date1=labels[i];
                }
            }
            theData.add(cd);  
        }
        formatChartOld(theData,'Weekly Weight');
    }

    private void makeDailyChartNew(integer days){
        string sql;
        Date tempDate;
        
        chartData='\'Day\', \'Weight\', {role: \'style\'}]';
          
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_DAYS:' + days + ') and (Weight__c > 0) Order By Date__c';
        
        //No aggregation needed. And the default scaling is good enough.
        List<Weight__c> results = Database.query(sql);
        for (Weight__c rec : results) {
            tempDate=rec.Date__c;
            chartData += ', [\'' + monthName(tempDate.month()) + ' ' + tempDate.day() + '\', ' + rec.Weight__c + ', \'color: #1798c1\']'; //Salesforce blue color.
        }
        if (chartData.endsWith(']')){chartData=chartData.left(chartData.length()-1);} //Remove the last square bracket since it will be added in the JavaScript.
        setChartOptions('Daily Weight');
    }

    private void makeDailyChartOld(integer days){
        string sql;
        string dayNumber;
        Date tempDate;
        boolean skip=false;
        chartDatapoint cd;
        List<chartDatapoint> theData = new List<chartDatapoint>();
          
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_DAYS:' + days + ') and (Weight__c > 0) Order By Date__c';
        
        //No aggregation needed.
        List<Weight__c> results = Database.query(sql);
        for (Weight__c rec : results) {
            cd = new chartDatapoint();
            cd.weight=rec.Weight__c;
            tempDate=rec.Date__c; //We use a Date instead of a DateTime because the DateTime does weird things with the day number.
            dayNumber=string.valueOf(tempDate.day());
            if (days<=30) cd.date1=dayNumber;
            if (days>30){
                //Put a label on every other bar:
                if (skip==false) {skip=true;} else {skip=false;}
                if (skip) {cd.date1='';} else {cd.date1=dayNumber;}
            }
            if (dayNumber=='1') {cd.date2=(monthName(tempDate.month()));} else {cd.date2='';}
            theData.add(cd);
        }
        formatChartOld(theData, 'Daily Weight');
    }

    private void formatChartOld(List<chartDatapoint> theData, string title){
        string chd='chd=t:', chds;
        string chxl0='chxl=0:', chxl1='|1:|', chxl2='|2:|',  chxl3='|3:';
        double weight=0.0, min=999.0, max=0.0;
        integer stepVal=0;

        for (chartDatapoint cd : theData) {
            chxl0 += '|' + cd.date1; 
            chxl3 += '|' + cd.date2;
            weight=cd.weight;
            if (weight>max) max=weight;
            if ((weight>0) && (weight<min)) min=weight;
            chd += weight + ',';
        }
        if (chd.endsWith(',')) chd=chd.left(chd.length()-1); //Remove the last comma.

        //Round off min & max:
        min=Math.floor(min-1);
        max=Math.ceil(max);

        //Now, make the y & r axis labels. The wider the range, the more numerical distance we need between our labels:
        stepVal=1;
        if ((max-min)>10) {stepVal=2;}
        if ((max-min)>20) {stepVal=3;}
        if ((max-min)>30) {stepVal=4;}
        if ((max-min)>40) {stepVal=5;}
        if ((max-min)>50) {stepVal=6;}
        if ((max-min)>60) {stepVal=7;}
        if ((max-min)>70) {stepVal=8;}
        if ((max-min)>80) {stepVal=9;}
        for(integer i=(integer)min; i<=max; i=i+stepVal) {
            chxl1=chxl1 + String.valueOf(i);
            chxl2=chxl2 + String.valueOf(i);
            if (i<max) {
                chxl1=chxl1 + '|';
                chxl2=chxl2 + '|';
            }
        }

        //Set the scaling for the y-axis. Sometimes this is off by a tiny bit. I think it happens when there are
        //an odd number of y-axis labels such as when using 99 periods. Not sure how to fix it.
        chds = 'chds=' + String.valueOf(min) + ',' + String.valueOf(max); 

        chartURL =  'https://chart.googleapis.com/chart?';
        chartURL += 'cht=bvs&';                            //Specify a bar chart.
        chartURL += 'chs=480x390&';                        //Chart size.
        chartURL += 'chxt=x,y,r,x&';                       //Turn on the x, y, r & lower x axes.
        if (selectedRadioVal=='yearlyChart'){              //We don't use the second row of labels on the yearly chart.
            chartURL += 'chxt=x,y,r&';                     //Turn on the x, y, and r axes.
            chartURL +=  chxl0 + chxl1 + chxl2 + '&';      //Append the axis labels.
            chartURL += 'chm=N*2*,FF0000,0,,12&';          //Show data labels only on the yearly chart.
        } else {
            chartURL += 'chxt=x,y,r,x&';                   //Turn on the x, y, r, and x axes.
            chartURL += chxl0+chxl1+chxl2+chxl3 + '&';     //Append the axis labels.
        }
        chartURL += 'chbh=a&';                             //Tell it to space the bars evenly, and don't crop any.
        chartURL += 'chtt=' + title + '&';                 //Chart title.
        chartURL +=  chds + '&';                           //Scaling for y axis.
        chartURL += 'chco=0000ff&';                        //Make bars blue.
        chartURL +=  chd;                                  //Data values for y plot.
    }

    public void setChartOptions(string title){
        chartOptions  = '\'title\':             \'' + title + '\',';
        chartOptions += '\'titleTextStyle\':    {color: \'black\', fontName: \'Arial\', fontSize: 16, bold: true, italic: false},'; 
        //Make bars narrower on daily chart:
        if (selectedRadioVal=='dailyChart') 
            chartOptions += '\'bar\':           {groupWidth: \'70%\'},';
        else
            chartOptions += '\'bar\':           {groupWidth: \'85%\'},';
        chartOptions += '\'legend\':            {position: \'none\'},';
        chartOptions += '\'width\':             480,';
        chartOptions += '\'height\':            390,';
        chartOptions += '\'chartArea\':         {left: \'10%\', top: \'10%\', width: \'90%\', height: \'75%\'}';  
    }

    @TestVisible 
    private string monthName(integer monthNo) {
        if (monthNo==1) return 'Jan';
        if (monthNo==2) return 'Feb';
        if (monthNo==3) return 'Mar';
        if (monthNo==4) return 'Apr';
        if (monthNo==5) return 'May';
        if (monthNo==6) return 'Jun';
        if (monthNo==7) return 'Jul';
        if (monthNo==8) return 'Aug';
        if (monthNo==9) return 'Sep';
        if (monthNo==10) return 'Oct';
        if (monthNo==11) return 'Nov';
        if (monthNo==12) return 'Dec';
        return '???';
    }
}