# ApprovalRejectionService
Allows administrators to configure required fields before an Approval can be rejected.

## Requirements
Requires the following custom metadata type to be defined and configured:

1. API Name: Approval_Rejection_Setting__mdt
2. Fields:
    * Approval_Process_Name__c (Text 80) [The API name of the approval process]
    * Error_Message__c	Text(255) [Validation error message to display]
    * Is_Active__c	Checkbox [When checked, this setting will be enforced]
    * Object_Type__c	Metadata Relationship(Entity Definition) [Used to help select the field required]
    * Required_Field__c	 Metadata Relationship(Field Definition) [The field required to be non-null]

## Usage

This service can be invoked from a trigger on the sObject subject to the approval process.

<code>
ApprovalRejectionService rejectionService = new ApprovalRejectionService();
rejectionService.ValidateRecords(trigger.new);
</code>
