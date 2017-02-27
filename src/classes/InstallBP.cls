global class InstallBP implements InstallHandler {
	global void onInstall(InstallContext context) {
		// If first-run, create some data:
		// system.debug(' context = ' + context);
		if (context.previousVersion() == null) {
			//Load the data from the JSON static resource file, deserialize, and insert:
			StaticResource sr = [select Body from StaticResource where Name = 'BPData'];
			List<Weight__c> theData = (List<Weight__c>) JSON.deserialize(sr.Body.toString(), List<Weight__c>.class);
			//system.debug(' theData = ' + theData);
			insert theData;
			integer i = [Select Count() From Weight__c];
			//system.debug(' Rows added to db = ' + i);
			system.assertEquals(i,theData.size());
		}
	}
}