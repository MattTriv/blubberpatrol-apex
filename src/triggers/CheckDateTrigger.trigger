trigger CheckDateTrigger on Weight__c (before insert) {
	// Salesforce doesn't let you have unique Date fields, so we enforce uniqeness here.
	// There is no case where you would ever have two weight values for the same day.
    
    Weight__c[] days = Trigger.new;
    for (Weight__c day :days) {
    	integer i = [Select Count() From Weight__c Where Date__c=:day.Date__c];
    	if (i>0) day.addError('A recod already exists for the day that you entered.');
    }
}