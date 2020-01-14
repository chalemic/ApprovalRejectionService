/*
  ApprovalRejectionService: Service class that retrieves Approval Process settings and will examine provided records to ensure
  required fields are populated before the request for approval can be rejected.
*/
public class ApprovalRejectionService{
  private Map<String, List<Approval_Rejection_Setting__mdt>> SettingsByApproval;

  // Creates a new instance of the ApprovalRejectionService class.
  public ApprovalRejectionService(){
    this.PopulateSettings();
  }

  public List<SObject> ValidateRecords(List<SObject> recordsToCheck){
    Set<Id> recordIds = new Map<Id, SObject>(recordsToCheck).keySet();
    Map<Id, SObject> recordsWithApprovalSteps = new Map<Id, SObject>([
                                                                                        SELECT (SELECT ID, ProcessDefinition.DeveloperName, Status FROM ProcessInstances ORDER BY CreatedDate DESC LIMIT 1) 
                                                                                        FROM Case
                                                                                        WHERE Id IN :recordIds]);
    for(SObject recordToCheck : recordsToCheck){
      // Is this record currently in an Approval Process?
      if(recordsWithApprovalSteps.containsKey(recordToCheck.Id) &&
          recordsWithApprovalSteps.get(recordToCheck.Id).getSObjects('ProcessInstances') <> null &&
          !recordsWithApprovalSteps.get(recordToCheck.Id).getSObjects('ProcessInstances').isEmpty()){
        ProcessInstance currentApproval = (ProcessInstance)recordsWithApprovalSteps.get(recordToCheck.Id).getSObjects('ProcessInstances')[0];

        // Is the record's current Approval Process in our settings and is it Rejected?
        if(this.SettingsByApproval.containsKey(currentApproval.ProcessDefinition.DeveloperName) &&
          currentApproval.Status == 'Rejected'){
            List<Approval_Rejection_Setting__mdt> settings = this.SettingsByApproval.get(currentApproval.ProcessDefinition.DeveloperName);
            String errorMessage = '';
            Boolean hasError = false;

            // Look through all required fields. If any aren't populated, add their error message to the record.
            for(Approval_Rejection_Setting__mdt setting : settings){
              if(recordToCheck.get(setting.Required_Field__r.QualifiedApiName) == null){ 
                errorMessage += setting.Error_Message__c;
                hasError = true;
              }
            }
	
           if(hasError){
            	recordToCheck.addError(errorMessage);
           }
        }
      }
    }

    return recordsToCheck;
  }

  /*
    PopulateSettings: Used to populate a map of Approval Rejection Settings keyed by Approval Process Name.
  */
  private void PopulateSettings(){
    if(this.SettingsByApproval != null){
      return;
    }

    this.SettingsByApproval = new Map<String, List<Approval_Rejection_Setting__mdt>>();
    for(Approval_Rejection_Setting__mdt setting : [SELECT Approval_Process_Name__c, Error_Message__c, Object_Type__c, Required_Field__r.QualifiedApiName
                                                                                      FROM Approval_Rejection_Setting__mdt
                                                                                      WHERE Is_Active__c = TRUE]){
      List<Approval_Rejection_Setting__mdt> settings = this.SettingsByApproval.get(setting.Approval_Process_Name__c);
      if(settings == null){
        settings = new List<Approval_Rejection_Setting__mdt>();
      }                                

      settings.add(setting);                                              
      this.SettingsByApproval.put(setting.Approval_Process_Name__c, settings);
    }
  }
}
