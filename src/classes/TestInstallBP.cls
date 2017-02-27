@isTest private class TestInstallBP {
	static testMethod void installTest() {
		InstallBP postinstall = new InstallBP();
		Test.testInstall(postinstall, new Version(1, 0), false);
	}
}