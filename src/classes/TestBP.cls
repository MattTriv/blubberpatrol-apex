@IsTest(SeeAllData=true)
private class TestBP {
	
	@isTest static void test_Page() {
		PageReference pageRef = Page.BlubberPatrol;
		Test.setCurrentPage(pageRef);
		BlubberPatrolCharts con = new BlubberPatrolCharts();
		Test.startTest();
		con.selectedRadioVal='dailyChart';
		con.numberOfDailyBars=7;
		con.UpdateStatus();
		string s=con.statusValue;
		System.assertEquals('Please enter 1 to 60 days.', s);
		//Don't know why this doesn't work:
		//con.chartDatapoint cd = new con.chartDatapoint();
		//cd.weight=150;
		Test.stopTest();
	}
	
	@isTest static void test_monthName() {
		string s;
		PageReference pageRef = Page.BlubberPatrol;
		Test.setCurrentPage(pageRef);
		BlubberPatrolCharts con = new BlubberPatrolCharts();
		Test.startTest();
		for (integer i=1; i<=12; i++){s=con.MonthName(i); system.assertNotEquals('???',s);}
		s=con.MonthName(0); system.assertEquals('???',s);
		s=con.MonthName(null); system.assertEquals('???',s);
		Test.stopTest();
	}
	@isTest static void test_makeChartOptions() {
		BlubberPatrolCharts con = new BlubberPatrolCharts();
		string chartOptions;
		con.selectedRadioVal='dailyChart';
		con.setChartOptions('Daily Chart');
		system.assertNotEquals('',con.chartOptions);
		con.selectedRadioVal='yearlyChart';
		con.setChartOptions('Yearly Chart');
		system.assertNotEquals('',con.chartOptions);
	}
	@isTest static void test_makeChart() {
		BlubberPatrolCharts con = new BlubberPatrolCharts();
		con.selectedRadioVal='dailyChart';
		con.whichAPI='oldAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartURL);
		con.selectedRadioVal='weeklyChart';
		con.whichAPI='oldAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartURL);
		con.selectedRadioVal='monthlyChart';
		con.whichAPI='oldAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartURL);
		con.selectedRadioVal='quarterlyChart';
		con.whichAPI='oldAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartURL);
		con.selectedRadioVal='yearlyChart';
		con.whichAPI='oldAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartURL);
		con.selectedRadioVal='dailyChart';
		con.whichAPI='newAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartData);
		con.selectedRadioVal='weeklyChart';
		con.whichAPI='newAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartData);
		con.selectedRadioVal='monthlyChart';
		con.whichAPI='newAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartData);
		con.selectedRadioVal='quarterlyChart';
		con.whichAPI='newAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartData);
		con.selectedRadioVal='yearlyChart';
		con.whichAPI='newAPI';
		con.makeChart();
		system.assertNotEquals('',con.chartData);
	}
}