public with sharing class LITCReportingController {
    @AuraEnabled(cacheable=true)
    public static List<LITC_Reporting_Form__c> getReports() {
        List<LITC_Reporting_Form__c> apps = new List<LITC_Reporting_Form__c>();
        for (LITC_Reporting_Form__c app : [SELECT Id, Name, Status__c, Reporting_period__c, Reporting_Period_Full__c, RecordType.Name, Submission_Deadline__c, Grant_Year__c, Name_of_Clinic__c FROM LITC_Reporting_Form__c]){ 
            apps.add(app);
        }
        return apps;
    }

    @AuraEnabled(cacheable=true)
    public static List<LITC_Reporting_Line_Item__c> getLineItemsByType(String reportId, String type) {
        List<LITC_Reporting_Line_Item__c> lineItems = new List<LITC_Reporting_Line_Item__c>();

        for (LITC_Reporting_Line_Item__c item : [
            SELECT 
                Id, Name, Activity_Date__c, Activity_Type__c, Attendees__c, Case_Issue__c, Case_Result__c, 
                Exception_explanation__c, Language__c, Presenter__c, Primary_Audience__c, RecordTypeId, 
                Topics__c, Trial_Location_City__c, Trial_Location_State__c, Venue_Organization__c, 
                Clinician_Staff_Member__c, Description__c, Impediment__c, Efforts_Made_to_Overcome__c, 
                Issue__c, Case_Activity__c, Staff_Member__c, Details__c, Trainee__c, Topic__c, 
                Training_Hours__c, Provider__c

            FROM LITC_Reporting_Line_Item__c WHERE LITC_Reporting_Form__c =: reportId AND RecordType.name =: type]){ 
            lineItems.add(item);
        }
        return lineItems;
    }
    
    @AuraEnabled(cacheable=true)
    public static Contact getCurrentContactInformation() {
        String currentUserId = System.UserInfo.getUserId();
        User u = [Select u.ContactId from User u where u.Id = :currentUserId];
        Id contactb = u.contactID;
        Contact c = [SELECT Name, Email, Title, Phone, LITC_Role_v2__c, Id FROM Contact WHERE Id =: contactb];
        return c;
    }

    @AuraEnabled(cacheable=true)
    public static List<X13424_J_Line_Item_Snapshot__c> getJLineItemsByType(String reportId, String type) {
        List<X13424_J_Line_Item_Snapshot__c> lineItems = new List<X13424_J_Line_Item_Snapshot__c>();

        for (X13424_J_Line_Item_Snapshot__c item : [
            SELECT 
                Id, Description__c, Quantity__c, U_M__c, Cost_per_Unit__c, Total__c, Notes__c,   
                Personnel_Name__c, Position__c, LITC_FTE__c, Total_Allocated_Salary__c, Dollar_Federal__c, Dollar_Match__c,
                Total_Cost__c, Total_Allocated_Cost__c,
                Category__c, Percentage__c, 
                Indirect_Cost_Federal__c, Indirect_Cost_Rate_Type__c, Agency_who_issued_ICRA__c, 
                Matching_Funds_Type__c, Matching_Funds_Amont__c, Disable_Delete__c, 

                
                Total_Formula__c, Dollar_Match_Formula__c, Dollar_Federal_Formula__c, Total_Allocated_Salary_Formula__c,
                LITC_FTE_Formula__c, Total_Allocated_Cost_Formula__c, Total_Cost_Formula__c,

                Percentage_Formula__c,  Indirect_Cost_Federal_Formula__c, RecordType.Name
                 
                
            FROM X13424_J_Line_Item_Snapshot__c WHERE LITC_Reporting_Form__c =: reportId AND RecordType.name =: type]){ 
            lineItems.add(item);
        }
        return lineItems;
    }






    public static void handleBeforeUpdate(List<LITC_Reporting_Form__c> forms, Map<Id, LITC_Reporting_Form__c> oldForms){
        for(LITC_Reporting_Form__c form : forms){ 

            LITC_Reporting_Form__c oldRecord = oldForms.get(form.Id);

            if(form.Review_Status__c == 'Returned' && oldRecord.Review_Status__c != 'Returned' && form.Status__c == 'Submitted'){ 
                form.Status__c = 'In Progress';
            }
            if(oldRecord.Status__c != 'Submitted' && form.Status__c == 'Submitted'){ 
                form.Review_Status__c = 'In Progress';
            }
        }
    }

    public static void handleBeforeUpdateSF425(List<SF425_Form__c> forms, Map<Id, SF425_Form__c> oldForms){
        for(SF425_Form__c form : forms){ 

            SF425_Form__c oldRecord = oldForms.get(form.Id);

            if(form.Review_Status__c == 'Returned' && oldRecord.Review_Status__c != 'Returned' && form.Status__c == 'Submitted'){ 
                form.Status__c = 'In Progress';
            }
            if(oldRecord.Status__c != 'Submitted' && form.Status__c == 'Submitted'){
                validateSF425(form);
                form.Review_Status__c = 'In Progress';
            }
        }
    }
    public static void validateSF425(SF425_Form__c form){
            if(form.Basis_of_accounting__c == null) form.Basis_of_accounting__c.addError('SF425 Required Field Missing: 7. Basis of Accounting');
            if(form.Reporting_Period_End_Date__c == null) form.Reporting_Period_End_Date__c.addError('SF425 Required Field Missing: 9. Reporting Period End Date');
            if(form.Receipts__c == null) form.Receipts__c.addError('SF425 Required Field Missing: 10a. Cash Receipts');
            if(form.Disbursements__c == null) form.Disbursements__c.addError('SF425 Required Field Missing: 10b. Cash Disbursements');
            if(form.Federal_Share_Exp__c == null) form.Federal_Share_Exp__c.addError('SF425 Required Field Missing: e. Federal share of expenditures');
            if(form.Fed_Share_Unliquidated_obl__c == null) form.Fed_Share_Unliquidated_obl__c.addError('SF425 Required Field Missing: f. Federal share of unliquidated obligations');
            if(form.Recipient_share_of_expenditures__c == null) form.Recipient_share_of_expenditures__c.addError('SF425 Required Field Missing: j. Recipient share of expenditure');
            if(form.Total_Federal_program_income_earned__c == null) form.Total_Federal_program_income_earned__c.addError('SF425 Required Field Missing: l. Total Federal program income earned');
            if(form.Addition_Alternative__c == null) form.Addition_Alternative__c.addError('SF425 Required Field Missing: n. Program Income expended in accordance with deduction alternative');
    }

    @AuraEnabled
    public static X13424_J_Line_Item__c getSelectedLineItem(String recordId){ 
        X13424_J_Line_Item__c item = [SELECT Id, Description__c, Quantity__c, U_M__c, Cost_per_Unit__c, Total__c, Notes__c,   
                Personnel_Name__c, Position__c, LITC_FTE__c, Total_Allocated_Salary__c, Dollar_Federal__c, Dollar_Match__c,
                Total_Cost__c, Total_Allocated_Cost__c,
                Category__c, Percentage__c, 
                Indirect_Cost_Federal__c, Indirect_Cost_Rate_Type__c, Agency_who_issued_ICRA__c, 
                Entered_Dollar_Match__c, Entered_Dollar_Federal__c,
                Matching_Funds_Type__c, Matching_Funds_Amont__c FROM X13424_J_Line_Item__c WHERE ID =: recordId];
        return item;
    }

    @AuraEnabled
    public static X13424_J_Line_Item_Snapshot__c getSelectedLineItemSnapshot(String recordId){ 
        X13424_J_Line_Item_Snapshot__c item = [SELECT Id, Description__c, Quantity__c, U_M__c, Cost_per_Unit__c, Total__c, Notes__c,   
                Personnel_Name__c, Position__c, LITC_FTE__c, Total_Allocated_Salary__c, Dollar_Federal__c, Dollar_Match__c,
                Total_Cost__c, Total_Allocated_Cost__c, Total_Allocated_Salary_Formula__c, Total_Allocated_Cost_Formula__c,
                Category__c, Percentage__c, 
                Indirect_Cost_Federal__c, Indirect_Cost_Rate_Type__c, Agency_who_issued_ICRA__c,
                Entered_Dollar_Match__c, Entered_Dollar_Federal__c, 
                Matching_Funds_Type__c, Matching_Funds_Amont__c FROM X13424_J_Line_Item_Snapshot__c WHERE ID =: recordId];
        return item;
    }



    public static void generateLineItems(List<LITC_Reporting_Form__c> forms){
        Set<Id> appIds = new Set<Id>();
        Map<Id, Id> appToReportMap = new Map<Id, Id>();

        for(LITC_Reporting_Form__c form : forms){ 
            appIds.add(form.Application_for_Federal_Assistance__c);
            appToReportMap.put(form.Application_for_Federal_Assistance__c, form.Id);
        }

        String lineItemQuery = 'SELECT Id, RecordType.Name, Application_for_Federal_Assistance__c, ';
        lineItemQuery += String.join(lineItemFields, ', ');
        lineItemQuery += ' FROM X13424_J_Line_Item__c ';
        lineItemQuery += ' WHERE Application_for_Federal_Assistance__c IN :appIds';
        List<X13424_J_Line_Item__c> lineItems = Database.query(lineItemQuery);

        List<X13424_J_Line_Item_Snapshot__c> lineItemSnapshots = new List<X13424_J_Line_Item_Snapshot__c>();

        for(X13424_J_Line_Item__c lineItem : lineItems){
    
            X13424_J_Line_Item_Snapshot__c snapshot= createLineItemSnapshotFromLineItem(lineItem);
            snapshot.LITC_Reporting_Form__c = appToReportMap.get(lineItem.Application_for_Federal_Assistance__c);
            snapshot.Disable_Delete__c = true;
            lineItemSnapshots.add(snapshot);
        }
        insert lineItemSnapshots;

    }

    public static X13424_J_Line_Item_Snapshot__c createLineItemSnapshotFromLineItem(X13424_J_Line_Item__c lineItem){
        X13424_J_Line_Item_Snapshot__c snapshot = new X13424_J_Line_Item_Snapshot__c();
        snapshot.X13424_J_Line_Item__c = lineItem.Id;
        if(lineItemSnapshotRecordTypes.get(lineItem.RecordType.Name) != null){
            snapshot.RecordTypeId = lineItemSnapshotRecordTypes.get(lineItem.RecordType.Name).getRecordTypeId();
        }
      
        for(String field: lineItemFields){
            snapshot.put(field, lineItem.get(field));
        }
        return snapshot;
        //add the application snapshot after this returns
    }

    private static final List<String> lineItemFields = new List<String>{
        'Attributable_to_LITC__c',
        'Agency_who_issued_ICRA__c',
        'Category__c',
        // 'Cost_Base__c',
        'Cost_per_Unit__c',
        'Description__c',
        'Dollar_Federal__c',
        'Dollar_Match__c',
        'Expense_Category__c',
        'Extension_Requested__c',
        'Federal_Expense__c',
        'Fringe_Allocation_Percent__c',
        'Full_Time_Equivalent_Hours__c',
        'ICRA_From_Date__c',
        'ICRA_To_Date__c',
        'Indirect_Cost_Federal__c',
        'Indirect_Cost_Rate__c',
        'Indirect_Cost_Rate_Type__c',
        'LITC_Allocation_Percent__c',
        'LITC_FTE__c',
        // 'LITC_Hours__c',
        'Match_Expense__c',
        'Matching_Funds_Amont__c',
        'Matching_Funds_Type__c',
        // 'Modified_Direct_Cost__c',
        'Name',
        'Notes__c',
        'Pay_Rate__c',
        'Pay_Type__c',
        'Percent_Federal__c',
        'Percent_Match__c',
        'Percentage__c',
        'Personnel_Name__c',
        'Position__c',
        'Primary_Role__c',
        // 'Quantity__c',
        'Total__c',
        'Total_Allocated_Cost__c',
        'Total_Allocated_Salary__c',
        'Total_Cost__c',
        // 'Total_Cost_Supplies_Contr_Other__c',
        // 'Total_Hours__c',
        'Total_Units__c',
        'U_M__c'
    };
    private static Map<String,Schema.RecordTypeInfo> lineItemSnapshotRecordTypes = Schema.SObjectType.X13424_J_Line_Item_Snapshot__c.getRecordTypeInfosByName();



    @AuraEnabled
    public static LITC_Reporting_Form__c getReport(String recordId) {
        LITC_Reporting_Form__c myReport = [
            SELECT ID, Application_for_Federal_Assistance__c,
            Personnel_Dollar_Federal_Total__c, Personnel_Dollar_Match_Total__c, Personnel_Total_Formula__c, 
            Fringe_Dollar_Federal_Total__c, Fringe_Dollar_Match_Total__c, Fringe_benefits_Total_Formula__c,
            Travel_Federal_Total__c, Travel_Match_Total__c, Travel_Total_Formula__c, 
            Equipment_Federal_Total__c, Equipment_Match_Total__c, Equipment_Total_Formula__c, 
            Supplies_Federal_Total__c, Supplies_Match_Total__c, Supplies_Total_Formula__c, 
            Contractual_Federal_Total__c, Contractual_Match_Total__c, Contractual_Total_formula__c, 
            Other_expenses_Federal_Total__c, Other_Expenses_Match_Total__c, Other_Expenses_Total_Formula__c, 
            Indirect_Expenses_Federal_Total__c, 
            Total_Federal_Expenses__c, Total_Match_Expenses__c, Total_Expenses__c
            FROM LITC_Reporting_Form__c WHERE ID =: recordId];
        return myReport;
    }

    @AuraEnabled
    public static Application_for_Federal_Assistance__c getApplication(String recordId) {
        LITC_Reporting_Form__c myReport = [SELECT ID, Application_for_Federal_Assistance__c FROM LITC_Reporting_Form__c WHERE ID =: recordId];

        Application_for_Federal_Assistance__c myApp = [
            SELECT ID, 
            Personnel_Dollar_Federal_Total__c, Personnel_Dollar_Match_Total__c, Personnel_Total_Formula__c, 
            Fringe_Dollar_Federal_Total__c, Fringe_Dollar_Match_Total__c, Fringe_benefits_Total_Formula__c,
            Travel_Federal_Total__c, Travel_Match_Total__c, Travel_Total_Formula__c, 
            Equipment_Federal_Total__c, Equipment_Match_Total__c, Equipment_Total_Formula__c, 
            Supplies_Federal_Total__c, Supplies_Match_Total__c, Supplies_Total_Formula__c, 
            Contractual_Federal_Total__c, Contractual_Match_Total__c, Contractual_Total_formula__c, 
            Other_expenses_Federal_Total__c, Other_Expenses_Match_Total__c, Other_Expenses_Total_Formula__c, 
            Indirect_Expenses_Federal_Total__c, 
            Total_Federal_Expenses__c, Total_Match_Expenses__c, Total_Expenses__c
            FROM Application_for_Federal_Assistance__c WHERE ID =: myReport.Application_for_Federal_Assistance__c];
        return myApp;
    }


}