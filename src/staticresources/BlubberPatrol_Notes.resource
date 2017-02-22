 Resume on: chart Ajaxing, update tests, then a v1.0 deployment, and then a Lightening version of BP.

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

Bad Ideas:
1) See if we can write a trigger that will load the chart page after a new weight-value is entered via the CRUD. This is a bad idea because the a trigger might be fired with multiple objects, like when using the Data Loader (I think). So, I don't think that the compiler will let you write such a thing.

*** Issue: Ajax Updates for Charts ***
Updating the old charts without a page load works fine. However, the new charts are a problem. I think that this code: 
var data = google.visualization.arrayToDataTable([[{!chartData}]]);
...gets resolved with fresh data only when the page loads. If you call drawChart() without a page load, it draws the same chart because the new chartData value calculated by the controller hasn't been copied over. To fix it, we have to get chartData updated someplace other than the top of the page. We may also have to refactor makeChart() to not return a PageReference. This is tricky and time-consuming, but we are learning more deeply about JavaScript, Ajax, and how controllers interact with pages.

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