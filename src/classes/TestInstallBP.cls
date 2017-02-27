@isTest private class TestInstallBP {
	static testMethod void installTest() {
		InstallBP postinstall = new InstallBP();
		//Set the second paramater to null to test a new installation.
		//The third paramater specifies Push, or not, and should always be false for an unmanaged package (I think).
		//Test.testInstall(postinstall, new Version(1, 0), false);
		Test.testInstall(postinstall, null, false);
	}
}