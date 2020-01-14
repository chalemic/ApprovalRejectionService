@isTest
private class ApprovalRejectionServiceTest {
    static String CaseSubject = 'New Program';
    static Id NewProgramRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('New Program').getRecordTypeId();
    /*
    ValidateRecordsIgnoresRecordsNotInApprovalProcesses: Verifies that an object that has not been submtted for approval
    will not have errors added to it by the ApprovalRejectionService.
    */
    @isTest
    static void ValidateRecordsIgnoresRecordsNotInApprovalProcesses(){
        Case testRecord = new Case(Subject = CaseSubject,
                                  RecordTypeId = NewProgramRT);

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(testRecord, false);
        System.assertEquals(true, saveResult.isSuccess());
        testRecord = (Case)new ApprovalRejectionService().ValidateRecords(new List<Case>{testRecord})[0];
        saveResult = Database.update(testRecord, false);
        Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess());
    }

    /*
    ValidateRecordsIgnoresPendingApprovals: Verify that a record in a pending status will not be rejected.
    */
    @isTest
    static void ValidateRecordsIgnoresPendingApprovals(){
        Case testRecord = new Case(Subject = CaseSubject,
                                  RecordTypeId = NewProgramRT);
        insert testRecord;
        
        Test.startTest();
        Approval.ProcessSubmitRequest testReq = new Approval.ProcessSubmitRequest();
        testReq.setObjectId(testRecord.Id);
        Approval.ProcessResult reqResult = Approval.process(testReq);
        Test.stopTest();

        System.assert(reqResult.isSuccess(),'Unable to submit new record for approval');
    }

    /*
    ValidateRecordsIgnoresApprovals: Verify that a record being Approved will not be rejected.
    */
    @isTest
    static void ValidateRecordsIgnoresApprovals(){
        Case testRecord = new Case(Subject = CaseSubject,
                                  RecordTypeId = NewProgramRT);
        insert testRecord;
        testRecord.Is_Athlete__c = true;
        testRecord.Is_International_Student__c = true;
        update testRecord;
        
        Approval.ProcessSubmitRequest testReq = new Approval.ProcessSubmitRequest();
        testReq.setObjectId(testRecord.Id);
        Approval.ProcessResult reqResult = Approval.process(testReq);
        
        Approval.ProcessWorkitemRequest testApp = new Approval.ProcessWorkitemRequest();
        testApp.setComments ('');
        testApp.setAction('Approve');
        testApp.setWorkitemId(reqResult.getNewWorkitemIds()[0]);
    
        Test.startTest();       
        Approval.ProcessResult testAppResult =  Approval.process(testApp);
        Test.stopTest();

        System.assert(testAppResult.isSuccess(),  'Approvals should not be rejected.');
    }

    /*
    ValidateRecordsIgnoresApprovals: Verify that a record being Approved will not be rejected.
    */
    @isTest
    static void ValidateRecordsRejectsDenialsMissingRequiredField(){
        Case testRecord = new Case(Subject = CaseSubject,
                                  RecordTypeId = NewProgramRT);
        insert testRecord;
        Approval.ProcessSubmitRequest testReq = new Approval.ProcessSubmitRequest();
        testReq.setObjectId(testRecord.Id);
        Approval.ProcessResult reqResult = Approval.process(testReq);
        
        Approval.ProcessWorkitemRequest testApp = new Approval.ProcessWorkitemRequest();
        testApp.setAction('Reject');
        testApp.setWorkitemId(reqResult.getNewWorkitemIds()[0]);
    
        Test.startTest();       
        try{
            Approval.ProcessResult testAppResult = Approval.process(testApp);
        }
        catch(DmlException e){
            // Code should throw DMLException because required fields were not populated.
        }
        Test.stopTest();

        testRecord = [SELECT (SELECT ID, ProcessDefinition.DeveloperName, Status FROM ProcessInstances ORDER BY CreatedDate DESC LIMIT 1) 
                            FROM Case
                            WHERE Id = :testRecord.Id];
        string approvalStatus = testRecord.ProcessInstances[0].Status;
        System.assertEquals('Pending', approvalStatus,  'Approval should still be pending due to missing required field.');
    }
}
