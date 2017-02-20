@isTest
private class TestBP {
	
	@isTest static void test_method_one() {
		PageReference pageRef = Page.BlubberPatrol;
		Test.setCurrentPage(pageRef);
		BlubberPatrolCharts con = new BlubberPatrolCharts();
		Test.startTest();
		con.selectedRadioVal='dailyChart';
		con.numberOfDailyBars=7;
		con.UpdateStatus();
		string s=con.statusValue;
		System.assertEquals('Ready to make daily chart.', s);
		Test.stopTest();
	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}