public class BlubberPatrolCharts{
    //Methods marked "Old" use the original Google Chart API. "New" methods use the newer Google Visualization API.
    //These are automatic properties. You don't have to put code in the get() and set() methods.
    public boolean printChart {get;set;}
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
    
    //Constructor:
    public BlubberPatrolCharts(){
        selectedRadioVal='dailyChart'; //Set the default radio button. There is no "checked" attribute like in HTML.
        numberOfDailyBars=7;
        numberOfWeeklyBars=20;
        numberOFMonthlyBars=12;
        numberOfQuarterlyBars=4;
        numberOfYearlyBars=7;
        whichAPI='oldAPI';
		updateStatus();
        makeChart();
    }
    
    //The next two methods are "Action Methods" which are triggered by buttons, links, etc. And controls tagged with apex:actionSupport.
	public void updateStatus(){
        if (selectedRadioVal=='dailyChart'){statusValue='Ready to make daily chart.';}
        if (selectedRadioVal=='weeklyChart') {statusValue='Ready to make weekly chart.';}
        if (selectedRadioVal=='monthlyChart'){statusValue='Ready to make monthly chart.';}
        if (selectedRadioVal=='quarterlyChart'){statusValue='Ready to make quarterly chart.';}
        if (selectedRadioVal=='yearlyChart') {statusValue='Reay to make yearly chart';}
	}

    public PageReference makeChart(){
        chartURL=''; chartData=''; chartOptions=''; printChart=false;
        
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

        Return null;
        //This method returns a PageReference, which is a URL, paramaters, etc.
        //By returning null, I think we are telling the browser to stay on the same page.
        //This would send the user to Google:
        //PageReference pageRef = new PageReference('http://www.google.com');
        //return pageRef;
    }

    private void makeYearlyChartNew(integer years){  
        string s, year;
        decimal x, w;
        List<string> elements = new List<string>();

        printChart=true;
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

        for(integer i=elements.size()-1; i>=0; i--) {chartData+=', '+elements[i];} //Add to data string in reverse order.

        //Remove the last square bracket. We leave off the first and last brackets because they are added on the VF page.
        if (chartData.endsWith(']')){chartData=chartData.left(chartData.length()-1);} 

        setChartOptions('Yearly Weight');      
    }

    private void makeYearlyChartOld(integer years){    
        decimal x=0.00; decimal w=0.00;
        string s, year;
        List<double> weights=new List<double>();
        List<string> dates1=new List<string>();
        List<string> dates2=new List<string>();
        
        //We get the data in DESC order, so need to push onto the arrays. See notes in 'new' method.
        for (aggregateResult results: [Select Calendar_Year(Date__c) Year, Avg(Weight__c) AveWeight from Weight__c Where (Weight__c > 0) Group By Calendar_Year(Date__c) Order By Calendar_Year(Date__c) DESC LIMIT :years]) {
            //We need two decimal variables to do rounding:
            s=string.valueOf(results.get('AveWeight'));
            x=Decimal.valueOf(s);
            w=x.setScale(2);
            year=string.valueOf(results.get('Year'));
            if (weights.size()==0) weights.add(w); else weights.add(0,w); //Can't push until there is at least one element in the list.
            if (dates1.size()==0) dates1.add(year); else dates1.add(0,year);
            dates2.add(''); //This is easier than leaving it empty.
        }

        formatChartOld(weights,dates1,dates2,'Yearly Chart');
    }

    private void makeQuarterlyChartNew(integer quarters){ 
        decimal x=0.00; decimal w=0.00;
        string s, year;
        integer iYear; integer startAt=0;
        boolean skip=false;
        List<Double> data = new List<Double>();
        List<String> labels = new List<String>();

        printChart=true;
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
        List<double> weights=new List<double>();
        List<string> dates1=new List<string>();
        List<string> dates2=new List<string>();
        
        //See the comments in makeQuarterlyChartNew().
        
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
        
        if (quarters>data.size()){startAt=0;} else {startAt=data.size()-quarters;}
		for (integer i = startAt; i < data.size(); i++) {
            weights.add(data[i]);
            dates2.add(''); //The second x axis is not used on this cart, so fill it up with blanks.
            if (quarters>12){
				//Put a label on every other bar:
                //skip=!skip; //Don't know why this doesn't work.
                if (skip==false) {skip=true;} else {skip=false;}
                if (skip) {
                    dates1.add('');
                } else {
                    dates1.add(labels[i]);
                }
            } else {
                dates1.add(labels[i]); //Put a label on every bar.
            }
        }
        
        formatChartOld(weights,dates1,dates2,'Quarterly Chart');
    }
    
    private void makeMonthlyChartNew(integer months){   
        decimal totalWeight=0.0; decimal x=0.0; decimal w=0.0;
        string s, sql, monthYear, last, displayDate;
        integer datapoints=0; integer startAt=0;
        DateTime dt=DateTime.newInstance(2017,01,01);
        List<Double> data = new List<Double>();
        List<String> labels = new List<String>();

        printChart=true;
        chartData='\'Month\', \'Weight\', {role: \'style\'}]';
          
        //We have to use Dynamic SOQL here because the colon prevents the months variable from being concatenated:
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_MONTHS:' + months + ') and (Weight__c > 0) Order By Date__c';
        
        //Put the results into a list and aggregate manually:
        List<Weight__c> results = Database.query(sql);
        last=string.valueOf(results[0].Date__c.month()) + string.valueOf(results[0].Date__c.year());
        for (Weight__c rec : results) {
            monthYear=string.valueOf(rec.Date__c.month()) + string.valueOf(rec.Date__c.year());
            dt=rec.Date__c;
            displayDate=dt.format('MMM');
            if (monthYear<>last){
                x=totalWeight/datapoints;
                w=x.setScale(2);            
                data.add(w);
                labels.add(displayDate);
                last=monthYear;
                datapoints=0;
                totalWeight=0;
            } else {
                datapoints++;
                totalWeight += rec.Weight__c;
            }
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
        string s, sql, monthYear, last, displayDate;
        boolean skip=false;
        integer datapoints=0; integer startAt=0; integer skipNo=0;
        DateTime dt=DateTime.newInstance(2017,01,01);
        List<Double> data = new List<Double>();
        List<String> labels = new List<String>();
        List<String> labels2 = new List<String>();
        List<double> weights = new List<double>();
        List<string> dates1 = new List<string>();
        List<string> dates2 = new List<string>();
          
        //We have to use Dynamic SOQL here because the colon prevents the months variable from being concatenated:
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_MONTHS:' + months + ') and (Weight__c > 0) Order By Date__c';
        
        //Put the results into a list and aggregate manually:
		List<Weight__c> results = Database.query(sql);
        last=string.valueOf(results[0].Date__c.month()) + string.valueOf(results[0].Date__c.year());
        for (Weight__c rec : results) {
            monthYear=string.valueOf(rec.Date__c.month()) + string.valueOf(rec.Date__c.year());
            dt=rec.Date__c;
            displayDate=dt.format('MMM');
            if (monthYear<>last){
              	x=totalWeight/datapoints;
                w=x.setScale(2);            
                data.add(w);
                labels.add(displayDate);
                if (displayDate=='Jan') labels2.add(dt.format('YYYY')); else labels2.add('');
                last=monthYear;
                datapoints=0;
                totalWeight=0;
        	} else {
            	datapoints++;
                totalWeight += rec.Weight__c;
           	}
		}
        x=totalWeight/datapoints;
        w=x.setScale(2);
        data.add(w);
        labels.add(displayDate);
        if (displayDate=='Jan') labels2.add(dt.format('YYYY')); else labels2.add('');

        //If the user specifies more bars than we have data for, print them all. Otherwise, print just the number they specified:
        if (months>data.size()){startAt=0;} else {startAt=data.size()-months;}
        for (integer i=startAt; i<data.size(); i++) {
            weights.add(data[i]);
            dates2.add(labels2[i]);
            //Apex has no CASE statement. So, we use IFs:
            if (months<=12) {
                //Put a label on every bar.
                dates1.add(labels[i]);
            }
            if (months>12 && months<=24){
				//Put a label on every other bar:
                if (skip==false) {skip=true;} else {skip=false;}
                if (skip) dates1.add(''); else dates1.add(labels[i]);
            }
            if (months>24){
				//Put a label on every third bar:
                if (skipNo<>3) {
                    skipNo++;
                    dates1.add('');
                } else {
                    skipNo=0;
                    dates1.add(labels[i]);
                }
            }            
        }

        formatChartOld(weights,dates1,dates2,'Monthly Weight');
    }

    private void makeWeeklyChartNew(integer weeks){
        decimal totalWeight=0.0; decimal x=0.0; decimal w=0.0;
        string s, year, sql, weekYear, last, displayDate;
        integer datapoints=0; integer startAt=0; integer weekNo=0;
        DateTime dt=DateTime.newInstance(2017,01,01);
        List<String> data = new List<String>();
        List<String> labels = new List<String>();

        printChart=true;
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
        system.debug('chartData = ' + chartData);
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
        List<double> weights = new List<double>();
        List<string> dates1 = new List<string>();
        List<string> dates2 = new List<string>();
          
        //We have to use Dynamic SOQL here because the colon prevents the months variable from being concatenated:
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_WEEKS:' + weeks + ') and (Weight__c > 0) Order By Date__c';
        
        //Put the results into a list and aggregate manually:
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
        data.add(w);
        labels.add(displayDate);
        
        //If the user specifies more bars than we have data for, print them all. Otherwise, print just the number they specified:
        if (weeks>data.size()){startAt=0;} else {startAt=data.size()-weeks;}
        for (Integer i = startAt; i < data.size(); i++) {
            weights.add(data[i]);
            dates2.add('');
            
            //Apex has no CASE statement. So, we use IFs:
            if (weeks<=8) {
                //Put a label on every bar.
                dates1.add(labels[i]);               
            }
            if (weeks>8 && weeks<=16){
				//Put a label on every other bar:
                if (skip==false) {skip=true;} else {skip=false;}
                if (skip) {dates1.add('');} else {dates1.add(labels[i]);}
            }
            if (weeks>16 && weeks<=32){
				//Put a label on every third bar:
                if (skipNo<>3) {
                    skipNo++;
                    dates1.add('');
                } else {
                    skipNo=0;
                    dates1.add(labels[i]);
                }
            }         
            if (weeks>32){
				//Put a label on every fifth bar:
                if (skipNo<>10) {
                    skipNo++;
                    dates1.add('');
                } else {
                    skipNo=0;
                    dates1.add(labels[i]);
                }
            }  
        }

        formatChartOld(weights,dates1,dates2,'Weekly Weight');
    }

    private void makeDailyChartNew(integer days){
        string sql;
        Date tempDate;
        
        printChart=true;
        chartData='\'Day\', \'Weight\', {role: \'style\'}]';
          
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_DAYS:' + days + ') and (Weight__c > 0) Order By Date__c';
        
        //No aggregation needed. And the default scaling is good enough.
        List<Weight__c> results = Database.query(sql);
        for (Weight__c rec : results) {
            tempDate=rec.Date__c;
            chartData += ', [\'' + monthName(tempDate.month()) + ' ' + tempDate.day() + '\', ' + rec.Weight__c + ', \'color: #1798c1\']'; //Salesforce blue color.
            system.debug(' chartData = ' + chartData);
        }

        if (chartData.endsWith(']')){chartData=chartData.left(chartData.length()-1);} //Remove the last square bracket since it will be added in the JavaScript.

        setChartOptions('Daily Weight');
    }
    
    //All of the other "old" methods use parallel Lists to hold chart data. In makeDailyChartOld() below
    //we use an array of chartData objects instead. We did this as an exercise while learning the
    //language. However, formatChartOld() still needs its data in the old format, so we made an overload
    //method that takes the array of chartData objects.
    public class chartData {
        public double weight {get;set;}
        public string date1  {get;set;}
        public string date2  {get;set;}
    }

    private void makeDailyChartOld(integer days){
        string sql;
        string dayNumber;
        Date tempDate;
        boolean skip=false;
        chartData cd;
        List<chartData> theData = new List<chartData>();
          
        sql='Select Date__c, Weight__c FROM Weight__c Where (Date__c >= LAST_N_DAYS:' + days + ') and (Weight__c > 0) Order By Date__c';
        
        //No aggregation needed.
        List<Weight__c> results = Database.query(sql);
        for (Weight__c rec : results) {
            cd = new chartData();
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

    private void formatChartOld(List<chartData> theData, string title){
        string chd='chd=t:', chds;
        string chxl0='chxl=0:', chxl1='|1:|', chxl2='|2:|',  chxl3='|3:';
        double weight=0.0, min=999.0, max=0.0;
        integer stepVal=0;

        for (chartData cd : theData) {
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

    private void formatChartOld(List<decimal> weights, List<string> dates1, List<string> dates2, string title){
        string chd='chd=t:', chds;
        string chxl0='chxl=0:', chxl1='|1:|', chxl2='|2:|',  chxl3='|3:';
        double min=999.0, max=0.0;
        integer stepVal=0;

        for (string label : dates1) {chxl0 += '|' + label;}
        for (string label : dates2) {chxl3 += '|' + label;} //The second x axis is only used on daily charts.

        for (double weight : weights) {
            if (weight>max) {max=weight;}
            if ((weight>0) && (weight<min)) {min=weight;}
            chd += weight + ',';
        }
        if (chd.endsWith(',')){chd=chd.left(chd.length()-1);} //Remove the last comma.

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

    private void setChartOptions(string title){
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