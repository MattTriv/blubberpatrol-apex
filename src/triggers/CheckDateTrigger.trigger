trigger CheckDateTrigger on Weight__c (before insert) {
	// Salesforce doesn't let you have unique Date fields, so we enforce uniqeness here.
	// There is no case where you would ever have two weight values for the same day.
    
	Weight__c[] days = Trigger.new;
	if (days.size() < 101) {
    	for (Weight__c day :days) {
    		integer i = [Select Count() From Weight__c Where Date__c=:day.Date__c];
    		if (i>0) day.addError('A recod already exists for the day that you entered.');
    	}
    } else {
    	// Don't check large bulk import files. Making this work for any more data than this will 
    	// be tricky. So, the user will have to be responsible for having a clean JSON file for now.
    }
}