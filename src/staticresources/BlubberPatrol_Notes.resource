 Resume on: packaging/trying to get debug messages in BP install test code. Then a Lightning version of BP.

To Do - Packaging
1) We can't package data, so use this mechanism to create sample data:
	https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_install_handler.htm
2) Sign up for a second dev org to test deployment. You can have as many dev orgs as you want.
3) We made a package named "BlubberPatrol" in Setup -> Create -> Packages. Need to update it after adding sample-data code?
4) Make a screenshot, and figure out how to add it to GitHub.
5) Announce the app on LinkedIn & Slack. Ask for help with the text inputs being to far from the radiobuttons?
6) Somebody mentioned that you can designate a package as "beta" so make sure to do that on the first one.
7) The Data Loader only seems to be able to export in CSV format, but we need JSON format to import a static resource file during the import process. So, convert the CSV file with this website: http://www.convertcsv.com/csv-to-json.htm


To Do:
* If we extend the BP CRUD controller, we could have the data entry on the same page as the charts.
* Think of a way to add a trigger since we need to practice writing one.
* Replace radiobuttons with pushbuttons for easier layout?
* See if we can stop the radiobutton text from wrapping. It may be possible with white-space:nowrap
* Fix the thing where SOQL gives us n+1 weeks. Just discard the first element.
* Use the Apex message thing instead of our own status field?
* Add exception handling.
* Add protection for SQL injection attacks.
* Save the user's period settings, and default chart type. Store in standard User object by adding custom columns?
* See if date-labels are screwed up on the last & first day of the month.
* We need to URL-encode the chart strings on the old API.
* We might be able to improve efficiency by refactoring the methods that use 2 passes of the data down to 1 pass. They also use parallel arrays for the first pass, so those could be replaced by an array of chartDatapoints just like we use in the second pass.

Architecting:
1) Move logic out of "fat controller" and into "service layer" pattern so that we can make a public API.

Deploying:
1) Put BP into an unmanaged package so that other SFDC users can install it? (Requires 75% code coverage). There is no public URL to see the page.
2) See if we can get another dev org. If not, then see if we can deploy to one of the forthcoming scratch orgs.
3) This Heroku app will allow a user to deploy BP from GitHub to their SFDC org: https://andyinthecloud.com/2013/09/24/deploy-direct-from-github-to-salesforce/
4) In the Android version of BP, I used code to create a minimal amount of data. So, for example, early years only had one datapoint, but since the code averages all the datapoints, it doesn't matter how many there are, and the charts were generated just fine. However, we have a different situation here. A prospective employer might want to do a pairing session with me to review the code. So, for example, if he wants to show me a way to optimize the SOQL query that generates the data for the yearly chart, we will want to have a full dataset so that we could calculate the speed improvement. So, I will use my real data here, exported into a JSON static resource file, and imported by the package installer during the installation process.

Bad Ideas:
1) See if we can write a trigger that will load the chart page after a new weight-value is entered via the CRUD. This is a bad idea because the trigger might be fired with multiple objects, like when using the Data Loader (I think). So, I don't think that the compiler will let you write such a thing.

*** Issue: Setting the Focus ***
We want the last inputText field used to keep the focus after a chart is made. The user may be experimenting with different numbers of bars, so it would be nice if they could type a number, press return, see the chart, type another number, press return, see another chart, etc. Right now, using autofocus only works when the page is intially loaded. VF ignores it after
that. In our origanl plain-HTML layout with inputText fields, the focus always went back to the first inputText no matter what we did with autofocus or the JavaScript focus() function: document.getElementById("someField").focus(); This seems like something VF just can't do.
							
*** Issue: Layout on Dashboard ***
Our panelGrid approach looks fine on a page, but on a dashboard, it gets sqeezed in such that the radio-button labels wrap, and that
throws off the whole design. And you can't do something like put one radio button on the same table row as its inputText because the browser will keep the radios together and put them all in the first row. So, we might not be able to use radios at all, and might perhaps use buttons instead, which will play nice in a grid. Another option is to find out why the dashboard squeezes so much when there is plenty of room.

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