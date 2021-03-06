* Package Description: This is a practice app that I wrote to learn Apex/Visualforce. It consists of a custom object where you can enter your weight each day, and a Visualforce page to make charts of various time periods using the Google Chart & Visualization APIs.

* Since there is no reliable way to check for available space, we need to put a try/catch into makeData() and test it with our full data-set which will throw an error.

* The daily chart needs to start from the last day in the db, not today() and proceed backward. It is losing bars now.

* We are exceeding the SOQL limit when we run tests, but it doesn't prevent us from passing.

* The Data Loader only seems to be able to export in CSV format, but we need JSON format to import a static resource file during the import process. So, convert the CSV file with this website: http://www.convertcsv.com/csv-to-json.htm


To Do:
* Chart methods need to return if there is no data returned by the SOQL query.
* Right now, we only have exception handling in the trigger test method, and in makeChart().
* Add CRUD to the VF page?
* Replace radiobuttons with pushbuttons for easier layout?
* See if we can stop the radiobutton text from wrapping. It may be possible with white-space:nowrap
* Fix the thing where SOQL gives us n+1 weeks. Just discard the the oldest elements until we get the the user's number.
* Add protection for SQL injection attacks.
* Save the user's period settings, and default chart type. Store in standard User object by adding custom columns?
* See if date-labels are screwed up on the last & first day of the month.
* We need to URL-encode the chart strings on the old API.
* Add a splash page to our Weight tab? The option is on the "Edit Tab" page.
* Add our Android icon to the app?


Would Be Nice:
* We might be able to fire the call to makeData() faster than 5 seconds with one of these methods:
	1) By using an apex:actionFunction instead of an actionPoller. See the manual page for example code.  
	2) By using the Apex Scheduler.
	3) By perhaps returning JS from an Apex method like so: return new PageReference('javascript:window.close()');
*We might be able to improve efficiency by refactoring the methods that use 2 passes of the data down to 1 pass. They also use parallel arrays for the first pass, so those could be replaced by an array of chartDatapoints just like we use in the second pass.


Architecting:
1) Move logic out of "fat controller" and into "service layer" pattern so that we can practice making a public API.


Deploying:
1) An unmanaged package requires 75% code coverage. There is no public URL to see the VF page in my org.
2) This Heroku app will allow a user to deploy BP from GitHub to their SFDC org: https://andyinthecloud.com/2013/09/24/deploy-direct-from-github-to-salesforce/
3) In the Android version of BP, I used code to create a minimal amount of data. So, for example, early years only had one datapoint, but since the code averages all the datapoints, it doesn't matter how many there are, and the charts were generated just fine. However, we have a different situation here. A prospective employer might want to do a pairing session with me to review the code. So, for example, if he wants to show me a way to optimize the SOQL query that generates the data for the yearly chart, we will want to have a full dataset so that we could calculate the speed improvement. So, I will use my real data here, exported into a JSON static resource file, and imported by makeData() during the installation process.


Bad Ideas:
1) See if we can write a trigger that will load the chart page after a new weight-value is entered via the CRUD. This is a bad idea because the trigger might be fired with multiple objects, like during an installation, or when using the Data Loader (I think). So, I don't think that the compiler will let you write such a thing.


*** Issue: Setting the Focus ***
We want the last inputText field used to keep the focus after a chart is made. The user may be experimenting with different numbers of bars, so it would be nice if they could type a number, press return, see the chart, type another number, press return, see another chart, etc. Right now, using autofocus only works when the page is intially loaded. VF ignores it after that. In our origanl plain-HTML layout with inputText fields, the focus always went back to the first inputText no matter what we did with autofocus or the JavaScript focus() function: document.getElementById("someField").focus(); This seems like something VF just can't do.

							
*** Issue: Layout on Dashboard ***
Our panelGrid approach looks fine on a page, but on a dashboard, it gets sqeezed horizontally such that the radio-button labels wrap, and that throws off the whole design. And you can't do something like put one radio button on the same table row as its inputText because the browser will keep the radios together and put them all in the first row. So, we might not be able to use radios at all, and might perhaps use buttons instead, which will play nice in a grid. Another option is to find out why the dashboard squeezes so much when there is plenty of room.

============================================= Old Stuff ============================================= 

apex:inputText - Originally, we used apex:inputText instead of the HTML5 apex:input:

<apex:inputText value="{!numberOfDailyBars}" maxlength="2" style="width: 25px; margin-bottom:5px; margin-top:8px;"/><br />
<apex:inputText value="{!numberOfWeeklyBars}" maxlength="3" style="width: 25px; margin-bottom:3px;"/><br />
<apex:inputText value="{!numberOfMonthlyBars}" maxlength="3" style="width: 25px; margin-bottom:3px;"/><br />
<apex:inputText value="{!numberOfQuarterlyBars}" maxlength="3" style="width: 25px; margin-bottom:3px;"/><br />
<apex:inputText value="{!numberOfYearlyBars}" maxlength="3" style="width: 25px; margin-bottom:3px;"/><br />

This worked okay, however it requires validation in JavaScript or Apex like this:
        integer period;
        if (selectedRadioVal == 'dailyChart')
            period=integer.valueOf(numberOfDailyBars);
            if (period < 1) {
                statusValue='Please enter a positive number';
                return null;
            }

The great thing about the HTML5 control is that it handles the validation for you.