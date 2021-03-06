<h1 align="center">BlubberPatrol for Apex/Visualforce by Matt Trivisonno</h1>
<p>
<img height="50" width="50" align="left" src="https://github.com/MattTriv/blubberpatrol-apex/blob/master/src/staticresources/BPWaitGIF.resource">
BlubberPatrol is a practice app that I wrote to learn Salesforce Apex &amp; Visualforce. It records the user's weight each day, and then draws charts to show trends of various durations. The user can choose between the original Google Chart API, and the newer Google Visualization API to draw the charts. At the time of this writing, the app is about 900 lines of code, of which 680 are Apex, 100 are Visualforce, 40 are CSS, and 100 are test methods. (Note: I also have an Android version of this app in the Google Play Store that I wrote in Java.) Here's what it looks like:
</p>

<p align="center">
<img src="https://github.com/MattTriv/blubberpatrol-apex/blob/master/src/staticresources/Screenshot.png">
</p>

<p>
When I began this project, I used the Salesforce Developer Console, which is a pretty good tool. However, for some reason it was <i>extremely</i> slow to scroll through log files. So, I switched to Sublime Text 3 with the MavensMate plugin. And that also allowed me to put my files into version control with SourceTree and upload them to GitHub.
</p>

<h3>Installation</h3>
<p align="center"><b><a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t41000002Vcrt">Click here to install BlubberPatrol into your SFDC org</a>.</b></p>

BlubberPatrol consists of two tabs: "Weight" and "Weight Charts." The Weight tab is the standard data-entry for the custom object. However, you don't need to enter any data since the app will install some sample data. So, if you go straight to the Weight Charts tab, you can see the app in action.

I have tested BlubberPatrol in a fresh developer org. I don't know how it will behave in other types of orgs. It runs fine in both Classic mode and Lightning mode. 

<h3>Unmanaged Package Problem</h3>
When I began this project, there was no generally accepted way of having an unmanaged package insert its data automatically. If you implemented the installHandler interface, Salesforce would just ignore it since it is only available to managed packages. So, I had to develop my own approach, and when you install BlubberPatrol, you will see how smoothly it works. It was a pretty tricky problem, and I explain how to do it in a blog post titled: <a href="http://www.trivisonno.com/programming/sfdc-unmanaged-package" target="_blank">How to Insert Sample Data in a Salesforce Unmanaged Package</a>.
