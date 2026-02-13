public with sharing class SLFRF_ComplianceController {
    public SLFRF_ComplianceController(ApexPages.StandardController stdController) {
    }

    //SUBRECIPIENTS

    @AuraEnabled(cacheable=true)
    public static List<Recipient_Profile__c> getSubrecipientsSLFRFPag(String recordId, Integer useless, Integer blockSize, Integer offset, String filters){
        try {
            String query = 'SELECT Id, Name, SLFRF__c, Duns__c,Recipient_Profile_ID__c,Recipient_Type__c, POC_Email_Address__c, DUNS_4__c, EIN__c,Unique_Entity_Identifier__c,';
            query += ' Address__c,Address_2__c,Address_3__c,City__c,State_Abbreviated__c,Zip__c, Registered_in_Sam_gov__c,Zip_4__c, Federal_Funds_80_or_More_of_Revenue__c,';
            query += ' Derives_25_Million_or_More_from_Federal__c,Total_Compensation_for_Officers_Public__c,Officer_Name__c,Officer_Total_Comp__c,Officer_2_Name__c,Country_Abbr__c,';
            query += ' Officer_2_Total_Comp__c,Officer_3_Name__c,Officer_3_Total_Comp__c,Officer_4_Name__c,Officer_4_Total_Comp__c,Officer_5_Name__c,Officer_5_Total_Comp__c, Entity_Type_2__c,';
            query += ' SLT_Compliance_Report__c, SLT_Compliance_Report__r.Report_Period__c, Missing_UEI_Justification__c';
            query += ' FROM Recipient_Profile__c WHERE SLFRF__c = true ';
            if(filters != null && filters != ''){query += filters;}   
            if(blockSize != null && blockSize>0) query += ' LIMIT ' + blockSize;
            if(offset != null) query += + ' OFFSET ' + offset;
            List<Recipient_Profile__c> subRecipients = Database.query(query);
            return subRecipients;
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());}
    }

    
    @AuraEnabled(cacheable=true)
    public static Integer getSubrecipientSLFRFTotal(String recordId, String filters){
        try{
            String query = 'SELECT count() FROM Recipient_Profile__c WHERE SLFRF__c = true';
            if(filters != null && filters != ''){query += filters;}   
            Integer count = Database.countQuery(query);
            return count;
        }catch(Exception e){ throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled
    public static List<Recipient_Profile__c> validateSubrecipientsUEI(String recordId) {
        List<Recipient_Profile__c> invalidSubrecips = new List<Recipient_Profile__c>();
        String regEx = '^(?=.*[0-9])(?=.*[a-zA-Z])([a-zA-Z0-9]+)';
        Pattern myReg = Pattern.compile(regEx);
        
        List<Recipient_Profile__c> recipientProfiles = [SELECT Id, Unique_Entity_Identifier__c, Missing_UEI_Justification__c, 
            Name, Recipient_Profile_Id__c, SLT_Compliance_Report__r.Report_Period__c, EIN__c, Entity_Type_2__c 
            FROM Recipient_Profile__c WHERE SLFRF__c = true];
        
        Set<Id> profileIds = new Set<Id>();
        
        for (Recipient_Profile__c sub : recipientProfiles) {
            profileIds.add(sub.Id);
        }
        
        Map<Id, List<Sub_Award__c>> subAwardsByProfileId = new Map<Id, List<Sub_Award__c>>();
        
        for (Sub_Award__c subAward : [SELECT Id, Name, Award_Amount__c, Recipient_Profile__c 
                                    FROM Sub_Award__c 
                                    WHERE Recipient_Profile__c IN :profileIds]) {
            if (!subAwardsByProfileId.containsKey(subAward.Recipient_Profile__c)) {
                subAwardsByProfileId.put(subAward.Recipient_Profile__c, new List<Sub_Award__c>());
            }
            subAwardsByProfileId.get(subAward.Recipient_Profile__c).add(subAward);
        }
        
        for (Recipient_Profile__c sub : recipientProfiles) {
            if (String.isBlank(sub.Entity_Type_2__c) || 
                (!String.isBlank(sub.Unique_Entity_Identifier__c) && !myReg.matcher(sub.Unique_Entity_Identifier__c).matches()) ||
                (sub.EIN__c != null && sub.EIN__c == '000000000') ||
                // (subAwardsByProfileId.containsKey(sub.Id) && hasNonZeroAwardAmount(subAwardsByProfileId.get(sub.Id)))
                (String.isBlank(sub.Unique_Entity_Identifier__c) && String.isBlank(sub.Missing_UEI_Justification__c) && hasNonZeroAwardAmount(subAwardsByProfileId.get(sub.Id)) && (sub.Entity_Type_2__c != null && sub.Entity_Type_2__c.contains('Subrecipient')))
                ) {
                invalidSubrecips.add(sub);
            }
        }
        
        return invalidSubrecips;
    }


    public static Boolean hasNonZeroAwardAmount(List<Sub_Award__c> subAwards) {
        if(subAwards != null){ 
            for (Sub_Award__c award : subAwards) {
                if (award.Award_Amount__c != 0) return true;
            }
        }
        return false;
    }
    


    
    @AuraEnabled
    public static Recipient_Profile__c getMySubrecipient(String recordId){
        try {
            Recipient_Profile__c subrecipient = [SELECT Registered_in_Sam_gov__c, Derives_25_Million_or_More_from_Federal__c, Federal_Funds_80_or_More_of_Revenue__c, Total_Compensation_for_Officers_Public__c, 
            Unique_Entity_Identifier__c, Missing_UEI_Justification__c, Provide_UEI_by_12_24__c, Entity_Type_2__c, State_Abbreviated__c FROM Recipient_Profile__c where Id =: recordId];
            return subrecipient;

        } catch (Exception e) { throw new AuraHandledException(e.getMessage());
        }
    }


    //SUBAWARDS
    @AuraEnabled(cacheable=true)
    public static List<Sub_Award__c> getMySubAwards(String recordId, Integer useless, Integer blockSize, Integer offset, String filters){
        try {
            String query = 'SELECT Id, Name, Award_No__c, RP_Entity_Type__c, Award_Type__c, Personnel_Estimated_Expended__c, Contract_Estimated_Expended__c,';
            query += ' Award_Amount__c, Award_Date__c, Primary_Sector__c, If_Other__c, Period_of_Performance_Start__c, Period_of_Performance_End__c,';
            query += ' Place_of_Performance_Address_1__c, Place_of_Performance_Address_2__c, Place_of_Performance_Address_3__c,';
            query += ' Place_of_Performance_City__c, Place_of_Performance_Congressional_Dist__c, Place_of_Performance_Country__c,';
            query += ' State_Abbreviated__c, Place_of_Performance_Zip__c, Place_of_Performance_Zip_4__c,';
            query += ' Purpose_of_Funds__c, Description__c, Sub_Recipient_Name_Matched__c, Recipient__c, Project_Name__c, Project_ID_Formula__c,  ';
            query += ' SLT_Compliance_Report__c, Report_Period_Subaward__c,Edited_Subaward_Amount_Explanation__c, ';
            query += ' Recipient_Profile_UEI__c, Recipient_Profile_TIN__c ';
            query += ' from Sub_Award__c where Prime_Recipient_Lookup__c = \'' + recordId + '\'';
            if(filters != null && filters != ''){query += filters;}   
            if(blockSize != null && blockSize>0) query += ' LIMIT ' + blockSize;
            if(offset != null) query += + ' OFFSET ' + offset;
            List<Sub_Award__c> awards = Database.query(query);
            return awards;
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static Integer getSubawardsTotal(String recordId, String filters){
        try {
            //Integer count = [SELECT count() FROM Sub_Award__c WHERE Prime_Recipient_Lookup__c =: recordId];
            String query = 'SELECT count() FROM Sub_Award__c WHERE Prime_Recipient_Lookup__c = \'' + recordId + '\'';
            if(filters != null && filters != ''){query += filters;}   
            Integer count = Database.countQuery(query);
            return count;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Sub_Award__c> getSubawardsQuarterlyTotal(String projectId, Integer useless, String reportPeriod){
        try {
            List<Sub_Award__c> subawards = new List<Sub_Award__c>();
            if(reportPeriod != null){ 
                for (Sub_Award__c subaward : [SELECT Id, Name, Award_Amount__c, Award_No__c, Report_Period_Subaward__c, Award_Type__c, Contract_Estimated_Expended__c, Personnel_Estimated_Expended__c
                     FROM Sub_Award__c 
                     WHERE Project__c =: projectId AND Report_Period_Subaward__c =: reportPeriod]){
                    subawards.add(subaward);
                }
            } else{ 
                for (Sub_Award__c subaward : [SELECT Id, Name, Award_Amount__c, Award_No__c, Q2_24_Previous_Award_Amount__c, Award_Type__c, Contract_Estimated_Expended__c, Personnel_Estimated_Expended__c FROM Sub_Award__c WHERE Project__c =: projectId]){
                    subawards.add(subaward);
                }
            }

            return subawards;

        } catch (Exception e) { throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled
    public static Sub_Award__c getMySubAward(String recordId){
        try {
            return [SELECT Id, Name, Project__c, Primary_Sector__c, Award_No__c,Edited_Subaward_Amount_Explanation__c, If_Other__c, 
                    Recipient_Profile__c, Award_Amount__c , Award_Type__c, Personnel_Cost_Estimates__c, Contract_Estimated_Expended__c, State_Abbreviated__c, RP_Entity_Type__c
                    FROM Sub_Award__c where Id =: recordId];
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled
    public static Boolean getNonZeroSubawardsFromSubrecipients(String recordId){
        List<Sub_Award__c> subawards = new List<Sub_Award__c>();
        try {
            for (Sub_Award__c sub : [SELECT Id, Name, Recipient_Profile__c, Award_Amount__c FROM Sub_Award__c WHERE Recipient_Profile__c =: recordId AND Award_Amount__c != 0 LIMIT 1]){ 
                subawards.add(sub);
            } 
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    
        return subawards.size() == 0;
    }

    //v2 from slt_compliancecontroller
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getAwardNoAwardAmountMap(String recordId, Integer useless){
        try {
            Map<String, Decimal> myMap = new Map<String, Decimal>();
            List<Sub_Award__c> mySubawards = [SELECT Id, Name, Award_Amount__c, Award_No__c FROM Sub_Award__c where Prime_Recipient_Lookup__c =: recordId];
            for(Sub_Award__c sub: mySubawards){
                myMap.put(sub.Award_No__c.toLowerCase(), sub.Award_Amount__c);
            }
            return myMap;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }

    


    //PROJECTS

    @AuraEnabled
    public static List<String> getProjDependentNames(String recordId){
        //returns a list of names of the subawards/expenditures related to the project
        try {
            System.debug(recordId);
            List<String> retList = new List<String>();
            List<Sub_Award__c> subawards = [SELECT Id, Award_No__c FROM Sub_Award__c WHERE Project__c =: recordId];
            String substr = 'You have ' + subawards.size() + ' subaward(s) attached to this project:';
            retList.add(substr);
            for(Sub_Award__c sub: subawards){
                retList.add(sub.Award_No__c);
            }
            List<Expenditure__c> expenditures = [SELECT Expenditure_Amount__c, Sub_Award_Expenditure_Type__c,Quarterly_Obligation_Amt_Aggregates__c 
                                                 FROM Expenditure__c 
                                                 WHERE Project__c =: recordId OR Sub_Award__c IN :subawards];
            String expstr = 'You have ' + expenditures.size() + ' expenditure(s) attached to this project. These expenditures are for the following types and obligation/expenditure amounts:';
            retList.add(expstr);
            for(Expenditure__c exp : expenditures){
                String expS = exp.Sub_Award_Expenditure_Type__c;
                if(exp.Sub_Award_Expenditure_Type__c.contains('Payments')){
                    expS += ' : $' + (exp.Quarterly_Obligation_Amt_Aggregates__c==null? '0' : String.valueOf(exp.Quarterly_Obligation_Amt_Aggregates__c));
                }else{
                    expS += ' : $' + (exp.Expenditure_Amount__c==null? '0': String.valueOf(exp.Expenditure_Amount__c));
                }
                retList.add(expS);
            }
            return retList;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getProjectTotal(String recordId, String filters){
        try {
            String query = 'SELECT count() FROM Project__c WHERE Recipient__c = \'' + recordId + '\'';
            query += ' AND (State_Local_and_Tribal_Application__r.RecordType.Name = \'CRF\' OR SLT_Compliance_Report__r.RecordType.Name = \'SLFRF Compliance Report\')';
            if(filters != null && filters != ''){query += filters;}   
            Integer count = Database.countQuery(query);
            return count;
        } catch (Exception e) {  throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Double> getProjectOverview(String recordId, Integer useless){ 
        try{
            System.debug(recordId);
            List<AggregateResult> totals = [
                SELECT count(Id), SUM(Total_Expenditures__c), SUM(Total_Obligations__c), SUM(Adopted_Budget__c) 
                FROM Project__c 
                WHERE Recipient__c =: recordId 
                AND (State_Local_and_Tribal_Application__r.RecordType.Name = 'CRF' OR SLT_Compliance_Report__r.RecordType.Name = 'SLFRF Compliance Report')
            ];
            Map<String, Double> totalMap = new Map<String, Double>();
            System.debug(totals);
            totalMap.put('count', Double.valueOf(totals[0].get('expr0')));
            totalMap.put('totExp', Double.valueOf(totals[0].get('expr1')));
            totalMap.put('totObl', Double.valueOf(totals[0].get('expr2')));
            totalMap.put('totAb', Double.valueOf(totals[0].get('expr3')));
            return totalMap;
        } catch(Exception e){  throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean projectsNotEC6(String recipId, Integer useless){
        try{
            List<Project__c> projects = [SELECT Project_Expenditure_Category__c FROM Project__c WHERE Recipient__c =: recipId AND (State_Local_and_Tribal_Application__r.RecordType.Name = 'CRF' OR SLT_Compliance_Report__r.RecordType.Name = 'SLFRF Compliance Report')];
            for(Project__c proj : projects){
                if(proj.Project_Expenditure_Category__c!='6-Revenue Replacement'){
                    return true;
                }
            }
            return false;
        }catch(Exception e){ throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjectsSearchable(String recordId, Integer useless, Integer blockSize, Integer offset, String filters){
        try {
            String query = 'SELECT Id, Name, Project_Identification_Number__c, Adopted_Budget__c, Project_Expenditure_Category__c,';
            query += ' Sum_Aggregate_Expenditures_Less_50000__c,ERA_Sum_Expenditures__c, Sum_Expenditures_Greater_50__c, Sum_Aggregate_Obligations_Less_50000__c,';
            query += ' Sum_Obligations_Subawards__c, Sub_Category__c, Subaward_Complete__c, Expenditure_Complete__c,Project_Complete__c, Total_Obligations__c,';
            query += ' Total_Expenditures__c,Project_Description__c,Evidence_Based_Total_Spend__c, Structure_Objectives_of_Asst_Programs__c,Recipient_Approach_Description__c,'; 
            query += ' SLT_Compliance_Report__c, SLT_Compliance_Report__r.Report_Period__c, Davis_Bacon_Certification__c, Labor_Agreement_Certification__c, Sum_Expenditures__c,';
            query += ' Q1_2024_Obligations__c, Q1_2024_Expenditures__c, Q2_2024_Obligations__c, Q2_2024_Expenditures__c, Q3_2024_Obligations__c, Q3_2024_Expenditures__c,';
            query += ' Small_Businesses_Served__c, Number_Non_Profits_Served__c, Industry_Experienced_8_Percent_Loss__c, Individuals_Served__c,School_ID_or_District_ID__c,';
            query += ' Payroll_Public_Health_Safety__c,Number_of_FTEs_Rehired__c, Is_project_designed_to_exceed_100_mbps__c, Number_of_Workers_K_12__c, Location_Detail__c,';
            query += ' National_Pollutant_Discharge_Number__c,Public_Water_System_PWS_ID_number__c, Median_Household_Income_Service_Area__c, Lowest_Quintile_Income__c,';
            query += ' Is_project_designed_to_meet_100_mbps__c, Project_not_met_100_mbps_explanation__c, Number_of_Subawards__c, Number_of_Expenditures__c,';
            query += ' Sum_Obligations__c,Completion_Status__c, Expenditure_Count__c, Do_you_have_Broadband_Location_File__c,';
            query += ' Project_Lock__c, Total_Period_Expenditures__c, Total_Period_Obligations__c, Project_Fully_Exp_Obligated__c, Cancellation_Reason__c,';
            query += ' Does_Project_Include_Capital_Expenditure__c, Total_Cost_Capital_Expenditure__c, Type_of_Capital_Expenditure__c, Type_of_Capital_Expenditure_Other__c, Capital_Expenditure_Justification__c,';
            query += ' Program_Income_Earned__c, Program_Income_Expended__c, Primary_Project_Demographics__c, Primary_Project_Demographics_Explanation__c, Secondary_Project_Demographics__c,';
            query += ' Secondary_Proj_Demographics_Explanation__c, Tertiary_Project_Demographics__c, Tertiary_Proj_Demographics_Explanation__c';
            query += ' from Project__c where Recipient__c = \'' + recordId + '\'';
            query += ' AND (State_Local_and_Tribal_Application__r.RecordType.Name = \'CRF\' OR SLT_Compliance_Report__r.RecordType.Name = \'SLFRF Compliance Report\')';

            if(filters != null && filters != ''){query += filters;}   
            if(blockSize != null && blockSize>0) query += ' LIMIT ' + blockSize;
            if(offset != null) query += + ' OFFSET ' + offset;

            List<Project__c> projects = Database.query(query);
           
            return projects;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled
    public static Project__c getProject(String projectId){
        try {            
            Project__c project = [SELECT Id, Name,Project_Identification_Number__c, 
            Sub_Category__c, QCT_Indicator__c, Evidence_Based_Program_Eval__c, Total_Obligations__c, Total_Expenditures__c,
            Davis_Bacon_Certification__c,Labor_Agreement_Certification__c, Is_project_designed_to_meet_100_mbps__c, 
            Completion_Status__c, Does_Project_Include_Capital_Expenditure__c,Sum_Obligations_Subawards__c,ERA_Sum_Expenditures__c,
            Do_you_have_Broadband_Location_File__c, Total_Cost_Capital_Expenditure__c, Type_of_Capital_Expenditure__c, Type_of_Capital_Expenditure_Other__c, 
            Technology_Type_Planned_Other__c, Technology_Type_Actual_Other__c, SLT_Compliance_Report__c, SLT_Compliance_Report__r.Report_Period__c, Is_project_designed_provide_hh_service__c,
            Planned_Funded_Locations_Served__c, Actual_Funded_Locations_Served__c,Planned_Funded_Locations_25_3_Below__c,Planned_Funded_Locations_Between_25_100__c,
            Planned_Funded_Locations_Minimum_100_100__c,Actual_Funded_Locations_Minimum_100_100__c,Planned_Funded_Locations_Minimum_100_20__c,Actual_Funded_Locations_Minimum_100_20__c,
            Planned_Funded_Locations_Residential__c, Actual_Funded_Locations_Residential__c,Planned_Funded_Locations_Business__c,Actual_Funded_Locations_Business__c,
            Planned_Funded_Locations_Community__c,Actual_Funded_Locations_Community__c,
            Project_Expenditure_Category__c,SLFRF9B_Cost_Overrun_YN__c, SLFRF9F_Oversee_Fed_Agy__c,
            SLFRF8C_Type_of_Declaration__c, SLFRF8E_Funds_Provided_for_Disaster_Loss__c, SLFRF9B2_Relevant_Prog__c, SLFRF10F_Delivering_Needs_Based_Services__c, SLFRF9E_Surface_Project_Type__c,
            Project_Lock__c, Project_Fully_Exp_Obligated__c, SLFRF10D_Environmental_Review_YN__c, 
            Program_Income_Earned__c, Program_Income_Expended__c, Admin_Estimated_Expended__c, Project_Start_Date__c
             FROM Project__c where Id =: projectId];
            return project;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled
    public static Project__c getProjectBasedOnSubaward(String subawardId) {
        Sub_Award__c subaward = [SELECT Id, Name, Project__c FROM Sub_Award__c where Id =: subawardId];
        return [SELECT Id, Name FROM Project__c where Id =: subaward.Project__c];
    }
    

    //EXPENDITURES

    //for project overview
    @AuraEnabled(cacheable=true)
    public static List<Expenditure__c> getExpendituresQuarterlyTotal(String projectId, Integer useless, String reportPeriod){
        try {
            System.debug('projectid = ' + projectId + ' report period = ' + reportPeriod);
            List<Expenditure__c> expenditures = new List<Expenditure__c>();
            if(reportPeriod != null){ 
                for (Expenditure__c expenditure : [SELECT Id, Name, Sub_Award_Lookup__c, Expenditure_Amount__c, Report_Period_Exp__c,
                Obligation_Amount__c, Sub_Award_Type__c, Sub_Award_Expenditure_Type__c, Sub_Award_Type_Aggregates_SLFRF__c, 
                Quarterly_Expenditure_Amt_Aggregates__c, Quarterly_Obligation_Amt_Aggregates__c 
                FROM Expenditure__c WHERE Project__c =: projectId AND Report_Period_Exp__c =: reportPeriod]){ 
                    expenditures.add(expenditure);   
                }
            } else{ 
                for (Expenditure__c expenditure : [SELECT Id, Name, Sub_Award_Lookup__c, Expenditure_Amount__c, 
                                    Obligation_Amount__c, Sub_Award_Type__c, Sub_Award_Expenditure_Type__c, Sub_Award_Type_Aggregates_SLFRF__c, 
                                    Quarterly_Expenditure_Amt_Aggregates__c, Quarterly_Obligation_Amt_Aggregates__c 
                                    FROM Expenditure__c 
                                    WHERE Project__c =: projectId])
                { 
                    expenditures.add(expenditure);   
                }
            }

            return expenditures;

        } catch (Exception e) { throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled(cacheable=true)
    public static Integer getExpGTCount(String recordId, String filters){
        try{
            String query = 'SELECT count() FROM Expenditure__c WHERE Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Expenditures > $50,000\'';
            if(filters != null && filters != ''){query += filters;}   
            Integer count = Database.countQuery(query);
            return count;
        }catch(Exception e){   throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Expenditure__c> getExpendituresQuarterly50000More(String recordId, Integer useless, Integer blockSize, Integer offset, String filters){
        try {
            String query = 'SELECT Id, Name, Project_Name__c,Project_ID_Formula__c, Sub_Award_Name__c, Sub_Award_Type__c,Sub_Recipient_Name__c, Expenditure_Amount__c, Expenditure_Category__c, Expenditure_Category_SLFRF__c,';
            query += ' Expenditure_End__c, Complying_With_Terms_of_Grant__c, Expenditure_Start__c, If_Non_Compliant_Provide_Explanation__c,Loan_Maturity_Date__c,';
            query += ' Project__c, Sub_Award__c, Sub_Award_Number__c, Sub_Award_Lookup__c, Obligation_Amount__c, Report_Period_Exp__c';
            query += ' FROM Expenditure__c WHERE Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Expenditures > $50,000\'';

            if(filters != null && filters != ''){query += filters;}   
            if(blockSize != null && blockSize>0) query += ' LIMIT ' + blockSize;
            if(offset != null) query += + ' OFFSET ' + offset;
     
            List<Expenditure__c> expenditures = Database.query(query);

            return expenditures;

        } catch (Exception e) { throw new AuraHandledException(e.getMessage());}
    }
    @AuraEnabled(cacheable=true)
    public static Integer getExpLTCount(String recordId, String filters){
        try{
            String query = 'SELECT count() FROM Expenditure__c WHERE Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Aggregate Expenditures < $50,000\'';
            if(filters != null && filters != ''){query += filters;}   
            Integer count = Database.countQuery(query);
            return count;
        }catch(Exception e){throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled(cacheable=true)
    public static List<Expenditure__c> getExpendituresQuarterly50000Less(String recordId, Integer useless, Integer blockSize, Integer offset, String filters){
        try {
            String query = 'SELECT Id, Name, Project_Name__c,Project_ID_Formula__c, Project__c, Expenditure_Category__c, Sub_Award_Type_Aggregates_SLFRF__c, Expenditure_Category_SLFRF__c,';
            query += ' Quarterly_Expenditure_Amt_Aggregates__c, Quarterly_Obligation_Amt_Aggregates__c, Cumulative_Expenditure__c, Cumulative_Obligation__c, Report_Period_Exp__c';
            query += ' FROM Expenditure__c where Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Aggregate Expenditures < $50,000\'';

            if(filters != null && filters != ''){query += filters;}   
            if(blockSize != null && blockSize>0) query += ' LIMIT ' + blockSize;
            if(offset != null) query += + ' OFFSET ' + offset;

            List<Expenditure__c> expenditures = Database.query(query);

            return expenditures;

        } catch (Exception e) {            throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled(cacheable=true)
    public static Integer getExpIndCount(String recordId, String filters){
        try{
            String query = 'SELECT count() FROM Expenditure__c WHERE Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Payments to Individuals < $50,000\'';
            if(filters != null && filters != ''){query += filters;}   
            Integer count = Database.countQuery(query);
            return count;
        }catch(Exception e){  throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Expenditure__c> getExpendituresQuarterlyIndividual(String recordId, Integer useless, Integer blockSize, Integer offset, String filters){
        try {
            String query = 'SELECT Id, Name, Project_Name__c,Project_ID_Formula__c, Project__c, Expenditure_Category__c,Expenditure_Category_SLFRF__c,';
            query += ' Quarterly_Expenditure_Amt_Aggregates__c, Quarterly_Obligation_Amt_Aggregates__c, Cumulative_Expenditure__c, Cumulative_Obligation__c, Report_Period_Exp__c';
            query += ' FROM Expenditure__c where Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Payments to Individuals < $50,000\'';

            if(filters != null && filters != ''){query += filters;}   
            if(blockSize != null && blockSize>0) query += ' LIMIT ' + blockSize;
            if(offset != null) query += + ' OFFSET ' + offset;

            List<Expenditure__c> expenditures = Database.query(query);
           
            return expenditures;

        } catch (Exception e) {   throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Double getExpGTSumExp(String recordId, String filters){
        try{
            Double sum = 0;
            String query = 'SELECT SUM(Expenditure_Amount__c)amt FROM Expenditure__c WHERE Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Expenditures > $50,000\'';
            if(filters != null && filters != ''){query += filters;}   
            List<AggregateResult> results = Database.query(query);
            sum = (Decimal) results[0].get('amt');
            return sum;
        }catch(Exception e){   throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Double> getExpLTSum(String recordId, String filters){
        try{
            Double sumExp = 0;
            Double sumObl = 0;
            Map<String, Double> myMap = new Map<String, Double>();

            String query = 'SELECT SUM(Quarterly_Expenditure_Amt_Aggregates__c)exp, SUM(Quarterly_Obligation_Amt_Aggregates__c)obl  FROM Expenditure__c WHERE Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Aggregate Expenditures < $50,000\'';
            if(filters != null && filters != ''){query += filters;}   
          
            List<AggregateResult> results = Database.query(query);
            sumExp = (Decimal) results[0].get('exp');
            sumObl = (Decimal) results[0].get('obl');
            myMap.put('exp', sumExp);
            myMap.put('obl', sumObl);
            return myMap;
        }catch(Exception e){ throw new AuraHandledException(e.getMessage());}
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Double> getExpIndSum(String recordId, String filters){
        try{
            Double sumExp = 0;
            Double sumObl= 0;
            Map<String, Double> myMap = new Map<String, Double>();

            String query = 'SELECT SUM(Quarterly_Expenditure_Amt_Aggregates__c)exp, SUM(Quarterly_Obligation_Amt_Aggregates__c)obl  FROM Expenditure__c WHERE Recipient__c = \'' + recordId + '\'';
            query += ' AND Sub_Award_Expenditure_Type__c = \'Payments to Individuals < $50,000\'';
            if(filters != null && filters != ''){query += filters;}   

            List<AggregateResult> results = Database.query(query);
            sumExp = (Decimal) results[0].get('exp');
            sumObl = (Decimal) results[0].get('obl');
     
            myMap.put('exp', sumExp);
            myMap.put('obl', sumObl);
            return myMap;
        }catch(Exception e){ throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Double> getCurrentPeriodValidation(String projectId, String reportPeriod, Integer useless){
        try{
            List<Expenditure__c> exp = SLFRF_ComplianceController.getExpendituresQuarterlyTotal(projectId, 1, reportPeriod);
            List<Sub_Award__c> sub = SLFRF_ComplianceController.getSubawardsQuarterlyTotal(projectId, 1, reportPeriod);
            List<Sub_Award__c> subEdited = [SELECT ID, NAME, Q2_24_Previous_Award_Amount__c, Award_Amount__c, Award_Type__c,Personnel_Estimated_Expended__c, Contract_Estimated_Expended__c FROM Sub_Award__c WHERE Project__c =: projectId AND Q2_24_Previous_Award_Amount__c != null];
            
            Double expTotal = 0;
            Double oblTotal = 0;
            System.debug('number of exp found = ' + exp.size());
            for(Expenditure__c expTemp : exp){ 
                if(expTemp.Sub_Award_Expenditure_Type__c == 'Expenditures > $50,000'){ 
                    expTotal += expTemp.Expenditure_Amount__c;
                } else{ 
                    expTotal += expTemp.Quarterly_Expenditure_Amt_Aggregates__c;
                    oblTotal += expTemp.Quarterly_Obligation_Amt_Aggregates__c;
                }
            }
            for(Sub_Award__c subTemp : sub){ 
                // oblTotal += subTemp.Award_Amount__c;
                // Q224 new req - take into account estimated amounts

                if(subTemp.Award_Type__c.contains('Direct Payment') && subTemp.Personnel_Estimated_Expended__c != null){ 
                    oblTotal += subTemp.Personnel_Estimated_Expended__c;
                } else if (subTemp.Award_Type__c.contains('Contract') && subTemp.Contract_Estimated_Expended__c != null){ 
                    oblTotal += subTemp.Contract_Estimated_Expended__c;
                } else{ 
                    oblTotal += subTemp.Award_Amount__c;
                }

            }
            for(Sub_Award__c subTemp : subEdited){ 
                Double currentAmount = subTemp.Award_Amount__c;
                if(subTemp.Award_Type__c.contains('Direct Payment') && subTemp.Personnel_Estimated_Expended__c != null){ 
                    currentAmount = subTemp.Personnel_Estimated_Expended__c;
                } else if (subTemp.Award_Type__c.contains('Contract') && subTemp.Contract_Estimated_Expended__c != null){ 
                    currentAmount = subTemp.Contract_Estimated_Expended__c;
                } else{ 
                    currentAmount = subTemp.Award_Amount__c;
                }
            
                oblTotal += (currentAmount - subTemp.Q2_24_Previous_Award_Amount__c);
            }
        
            Map<String, Double> myMap = new Map<String, Double>{
                'exp' => expTotal,
                'obl' => oblTotal
            };
            return myMap;
        }catch(Exception e){   throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled
    public static Expenditure__c getMyExpenditure(String recordId){
        try {
            return [SELECT Id, Name, Sub_Award_Expenditure_Type__c, Report_Period_Exp__c FROM Expenditure__c where Id =: recordId];
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }

    //SLT COMPLIANCE REPORT

    @AuraEnabled
    public static SLT_Compliance_Report__c importFromQuarterlyReport(String recipientId, String recordId){
        Id slfrfRecordType = Schema.SObjectType.SLT_Compliance_Report__c.getRecordTypeInfosByName().get('SLFRF Compliance Report').getRecordTypeId();
        SLT_Compliance_Report__c prevReport = [
            SELECT Id, Name, 
            Jurisdiction_Electing_Standard_Allowance__c, Base_Year_Revenue_2022__c, Growth_Adjustment_Used_2022__c, 
            Base_Year_Fiscal_Year_End_Date__c, Are_you_Reporting_Actual_General_Revenue__c, 
            Act_Gen_Rev_12_31_2020_Previous_12_mths__c, Est_Revenue_Loss_due_to_Covid_19__c, 
            FRF_Not_Used_for_Pension_Fund__c, Revenue_Replacement_Funds_Explanation__c, Actual_General_Revenue_2021__c, 
            Estimated_Revenue_Lost_2021__c, Fiscal_Recovery_Funds_2021__c, Rev_Replacement_Explanation_2021__c, 
            Actual_General_Revenue_2022__c, Estimated_Revenue_Lost_2022__c, Fiscal_Recovery_Funds_2022__c, 
            Rev_Replacement_Explanation_2022__c, Rev_Lost_Covid_No_Year__c, FRF_Funds_No_Year__c,  
            Rev_Replacement_Explanation_No_Year__c, 
            Do_you_have_Revenue_Covered_Changes__c, Is_Revenue_Covered_Changes_Less_Minimus__c, 
            Reduction_in_Net_Tax_Revenue__c, Revenue_Increasing_Covered_Changes__c, 
            Baseline_Revenue__c, Actual_Tax_Revenue__c, Net_Reduction_in_Total_Spending__c
            FROM SLT_Compliance_Report__c 
            WHERE Recipient__c =: recipientId 
            AND RecordTypeId =: slfrfRecordType AND Report_Type__c =: 'Quarterly Report' AND Id !=: recordId Order By CreatedDate DESC LIMIT 1];

        SLT_Compliance_Report__c report = [
            SELECT Id, Name, 
            Jurisdiction_Electing_Standard_Allowance__c, Base_Year_Revenue_2022__c, Growth_Adjustment_Used_2022__c, 
            Base_Year_Fiscal_Year_End_Date__c, Are_you_Reporting_Actual_General_Revenue__c, 
            Act_Gen_Rev_12_31_2020_Previous_12_mths__c, Est_Revenue_Loss_due_to_Covid_19__c, 
            FRF_Not_Used_for_Pension_Fund__c, Revenue_Replacement_Funds_Explanation__c, Actual_General_Revenue_2021__c, 
            Estimated_Revenue_Lost_2021__c, Fiscal_Recovery_Funds_2021__c, Rev_Replacement_Explanation_2021__c, 
            Actual_General_Revenue_2022__c, Estimated_Revenue_Lost_2022__c, Fiscal_Recovery_Funds_2022__c, 
            Rev_Replacement_Explanation_2022__c, Rev_Lost_Covid_No_Year__c, FRF_Funds_No_Year__c,  
            Rev_Replacement_Explanation_No_Year__c, 
            Do_you_have_Revenue_Covered_Changes__c, Is_Revenue_Covered_Changes_Less_Minimus__c, 
            Reduction_in_Net_Tax_Revenue__c, Revenue_Increasing_Covered_Changes__c, 
            Baseline_Revenue__c, Actual_Tax_Revenue__c, Net_Reduction_in_Total_Spending__c
            FROM SLT_Compliance_Report__c WHERE Id =: recordId];
        
        // Revenue Replacement
        if(report.Jurisdiction_Electing_Standard_Allowance__c == null && prevReport.Jurisdiction_Electing_Standard_Allowance__c != null) report.Jurisdiction_Electing_Standard_Allowance__c = prevReport.Jurisdiction_Electing_Standard_Allowance__c;
        if(report.Base_Year_Revenue_2022__c == null && prevReport.Base_Year_Revenue_2022__c != null) report.Base_Year_Revenue_2022__c = prevReport.Base_Year_Revenue_2022__c;
        if(report.Growth_Adjustment_Used_2022__c == null && prevReport.Growth_Adjustment_Used_2022__c != null) report.Growth_Adjustment_Used_2022__c = prevReport.Growth_Adjustment_Used_2022__c;
        if(report.Base_Year_Fiscal_Year_End_Date__c == null && prevReport.Base_Year_Fiscal_Year_End_Date__c != null) report.Base_Year_Fiscal_Year_End_Date__c = prevReport.Base_Year_Fiscal_Year_End_Date__c;
        if(report.Are_you_Reporting_Actual_General_Revenue__c == null && prevReport.Are_you_Reporting_Actual_General_Revenue__c != null) report.Are_you_Reporting_Actual_General_Revenue__c = prevReport.Are_you_Reporting_Actual_General_Revenue__c;
        if(report.Act_Gen_Rev_12_31_2020_Previous_12_mths__c == null && prevReport.Act_Gen_Rev_12_31_2020_Previous_12_mths__c != null) report.Act_Gen_Rev_12_31_2020_Previous_12_mths__c = prevReport.Act_Gen_Rev_12_31_2020_Previous_12_mths__c;
        if(report.Est_Revenue_Loss_due_to_Covid_19__c == null && prevReport.Est_Revenue_Loss_due_to_Covid_19__c != null) report.Est_Revenue_Loss_due_to_Covid_19__c = prevReport.Est_Revenue_Loss_due_to_Covid_19__c;
        if(report.FRF_Not_Used_for_Pension_Fund__c == null && prevReport.FRF_Not_Used_for_Pension_Fund__c != null) report.FRF_Not_Used_for_Pension_Fund__c = prevReport.FRF_Not_Used_for_Pension_Fund__c;
        if(report.Revenue_Replacement_Funds_Explanation__c == null && prevReport.Revenue_Replacement_Funds_Explanation__c != null) report.Revenue_Replacement_Funds_Explanation__c = prevReport.Revenue_Replacement_Funds_Explanation__c;
        if(report.Actual_General_Revenue_2021__c == null && prevReport.Actual_General_Revenue_2021__c != null) report.Actual_General_Revenue_2021__c = prevReport.Actual_General_Revenue_2021__c;
        if(report.Estimated_Revenue_Lost_2021__c == null && prevReport.Estimated_Revenue_Lost_2021__c != null) report.Estimated_Revenue_Lost_2021__c = prevReport.Estimated_Revenue_Lost_2021__c;
        if(report.Fiscal_Recovery_Funds_2021__c == null && prevReport.Fiscal_Recovery_Funds_2021__c != null) report.Fiscal_Recovery_Funds_2021__c = prevReport.Fiscal_Recovery_Funds_2021__c;
        if(report.Rev_Replacement_Explanation_2021__c == null && prevReport.Rev_Replacement_Explanation_2021__c != null) report.Rev_Replacement_Explanation_2021__c = prevReport.Rev_Replacement_Explanation_2021__c;
        if(report.Actual_General_Revenue_2022__c == null && prevReport.Actual_General_Revenue_2022__c != null) report.Actual_General_Revenue_2022__c = prevReport.Actual_General_Revenue_2022__c;
        if(report.Estimated_Revenue_Lost_2022__c == null && prevReport.Estimated_Revenue_Lost_2022__c != null) report.Estimated_Revenue_Lost_2022__c = prevReport.Estimated_Revenue_Lost_2022__c;
        if(report.Fiscal_Recovery_Funds_2022__c == null && prevReport.Fiscal_Recovery_Funds_2022__c != null) report.Fiscal_Recovery_Funds_2022__c = prevReport.Fiscal_Recovery_Funds_2022__c;
        if(report.Rev_Replacement_Explanation_2022__c == null && prevReport.Rev_Replacement_Explanation_2022__c != null) report.Rev_Replacement_Explanation_2022__c = prevReport.Rev_Replacement_Explanation_2022__c;
        if(report.Rev_Lost_Covid_No_Year__c == null && prevReport.Rev_Lost_Covid_No_Year__c != null) report.Rev_Lost_Covid_No_Year__c = prevReport.Rev_Lost_Covid_No_Year__c;
        if(report.FRF_Funds_No_Year__c == null && prevReport.FRF_Funds_No_Year__c != null) report.FRF_Funds_No_Year__c = prevReport.FRF_Funds_No_Year__c;
        if(report.Rev_Replacement_Explanation_No_Year__c == null && prevReport.Rev_Replacement_Explanation_No_Year__c != null) report.Rev_Replacement_Explanation_No_Year__c = prevReport.Rev_Replacement_Explanation_No_Year__c;

        // Tax Offset
        if(report.Do_you_have_Revenue_Covered_Changes__c == null && prevReport.Do_you_have_Revenue_Covered_Changes__c != null) report.Do_you_have_Revenue_Covered_Changes__c = prevReport.Do_you_have_Revenue_Covered_Changes__c;
        if(report.Is_Revenue_Covered_Changes_Less_Minimus__c == null && prevReport.Is_Revenue_Covered_Changes_Less_Minimus__c != null) report.Is_Revenue_Covered_Changes_Less_Minimus__c = prevReport.Is_Revenue_Covered_Changes_Less_Minimus__c;
        if(report.Reduction_in_Net_Tax_Revenue__c == null && prevReport.Reduction_in_Net_Tax_Revenue__c != null) report.Reduction_in_Net_Tax_Revenue__c = prevReport.Reduction_in_Net_Tax_Revenue__c;
        if(report.Revenue_Increasing_Covered_Changes__c == null && prevReport.Revenue_Increasing_Covered_Changes__c != null) report.Revenue_Increasing_Covered_Changes__c = prevReport.Revenue_Increasing_Covered_Changes__c;
        if(report.Baseline_Revenue__c == null && prevReport.Baseline_Revenue__c != null) report.Baseline_Revenue__c = prevReport.Baseline_Revenue__c;
        if(report.Actual_Tax_Revenue__c == null && prevReport.Actual_Tax_Revenue__c != null) report.Actual_Tax_Revenue__c = prevReport.Actual_Tax_Revenue__c;
        if(report.Net_Reduction_in_Total_Spending__c == null && prevReport.Net_Reduction_in_Total_Spending__c != null) report.Net_Reduction_in_Total_Spending__c = prevReport.Net_Reduction_in_Total_Spending__c;

        update report;
        return prevReport;
    }

    @AuraEnabled
    public static list< String > submitReport(String recordId){
        List<String> errors = new List<String>();
        Boolean noSubmissionsYet = true;
        SLT_Compliance_Report__c report = [SELECT Id, Name, Report_Period__c, Recipient_Name__c, CFDA_No__c,
        FAIN__c, Submission_Deadline__c, Program_Name__c, Submission_Date__c, Report_Type__c, Status__c 
        FROM SLT_Compliance_Report__c where Id =: recordId LIMIT 1];

        if (report.Status__c != 'Submitted' && report.Report_Type__c == 'NEU Distribution Update') {
            System.debug('In Open if');
            report.Status__c = 'Open';
            report.Submission_Date__c = Datetime.now();

            Database.SaveResult sr = Database.update( report, false );             
            if( !sr.isSuccess() )
            {
                for(Database.Error err : sr.getErrors()) {
                    errors.add( err.getMessage() );
                }
            }
            else {
                update report;
            }    
        }

        if( report.Status__c != 'Submitted' && noSubmissionsYet && report.Report_Type__c != 'NEU Distribution Update'){
            System.debug('In Submitted if');
            report.Status__c = 'Submitted';
            report.Submission_Date__c = Datetime.now();

            Database.SaveResult sr = Database.update( report, false );             
            if( !sr.isSuccess() )
            {
                for(Database.Error err : sr.getErrors()) {
                    errors.add( err.getMessage() );
                }
            }
            else {
                update report;
            }    
        } 
        return errors;

    }

    @AuraEnabled(cacheable=true)
    public static String getSltId(String subAwardNo, String recordId){
        
        try {

            Sub_Award__c subAward = [
                SELECT Id, Name
                FROM Sub_Award__c
                WHERE Award_No__c = :subAwardNo 
                and Prime_Recipient_Lookup__c = :recordId 
                LIMIT 1
            ];
      return subAward.Id;
            
        } catch (Exception e) {return '';}
    }

    //DELETION
    @AuraEnabled
    public static void deleteProjectsRelatedRecords(String projectId){
        //deletes a project's subawards and expenditures
        //grab all subawards
        List<String> subawardIds = new List<String>();
        List<String> expenditureIds = new List<String>();
        try {
            //grab all subawards and delete
            for(Sub_Award__c subaward : [SELECT Id FROM Sub_Award__c WHERE Project__c = :projectId]){
                subawardIds.add(subaward.Id);
            }
            deleteSubawards(subawardIds);
            //grab any remaining expenditures that might be linked to the project
            for(Expenditure__c expenditure : [SELECT Id FROM Expenditure__c WHERE Project__c = :projectId]){
                expenditureIds.add(expenditure.Id);
            }
            deleteExpenditures(expenditureIds);
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled
    public static void deleteSubawards(List<String> ids){
        System.debug('Deleting Subawards ' + ids);
        
        //delete linked expenditures
        List<String> expenditureIds = new List<String>();
        for(Expenditure__c expenditure : [SELECT Id FROM Expenditure__c WHERE Sub_Award__c IN :ids]){
            expenditureIds.add(expenditure.Id);
        }
        try{
            deleteExpenditures(expenditureIds);
            System.debug('Returned from Deleting Expenditures');
            List<Sub_Award__c> subawards = [SELECT Id FROM Sub_Award__c WHERE Id in :ids]; 
            
            delete subawards;
        }catch(DmlException de){
            throw de;
        }catch(Exception e){ throw new AuraHandledException('From Subawards: ' + e.getMessage()); }
    }

    @AuraEnabled
    public static void deleteSubawardHelper(String ids, String reportId){
        List<String> splitIds = ids.split(',');
        List<String> validIds = new List<String>();
        for(Sub_Award__c s : [SELECT Id, SLT_Compliance_Report__c FROM Sub_Award__c WHERE Id IN :splitIds AND SLT_Compliance_Report__c=:reportId]){
            System.debug(s);
            System.debug(s.Id);
            validIds.add(s.Id);
        }
        try{
            deleteSubawards(validIds);
        }catch(DmlException de){
            Integer numErrors = de.getNumDml();
            String errorMessage = '';
            String fieldNames = '';
            for(Integer i=0; i<numErrors; i++){
                System.debug('Type: ' + de.getDmlType(i));
                System.debug(i + ': ' + de.getDmlId(i));
                Id id = de.getDmlId(i);
                fieldNames = fieldNames + de.getDmlFieldNames(i);
                errorMessage = errorMessage + ' ' + i + ':'  + ' '+ id.getSobjectType().getDescribe().getName() + de.getDmlStatusCode(i) + + de.getDmlFieldNames(i);
            }
            errorMessage = errorMessage + '|' + fieldNames;
            System.debug(errorMessage);
            throw new AuraHandledException(errorMessage);
        }catch(Exception e){  throw new AuraHandledException('From SubawardHelper: ' + e.getMessage());  }
    }

    @AuraEnabled
    public static void deleteExpenditures(List<String> ids){
        System.debug('Deleting Expenditures ' + ids);
        try {
            List<Expenditure__c> expenditures = [SELECT Id FROM Expenditure__c WHERE Id IN :ids];
            delete expenditures;
        } catch(DmlException de){
            throw de;
        }catch (Exception e) { throw new AuraHandledException('From Expenditures: ' + e.getMessage()); }
    }

    @AuraEnabled
    public static void deleteExpenditureHelper(String ids){
        List<String> splitIds = ids.split(',');
        try{
            deleteExpenditures(splitIds);
        }catch(DmlException de){
            Integer numErrors = de.getNumDml();
            String errorMessage = '';
            String fieldNames = '';
            for(Integer i=0; i<numErrors; i++){
                System.debug('Type: ' + de.getDmlType(i));
                System.debug(i + ': ' + de.getDmlId(i));
                Id id = de.getDmlId(i);
                fieldNames = fieldNames + de.getDmlFieldNames(i);
                errorMessage = errorMessage + ' ' + i + ':'  + ' '+ id.getSobjectType().getDescribe().getName() + de.getDmlStatusCode(i) + + de.getDmlFieldNames(i);
            }
            errorMessage = errorMessage + '|' + fieldNames;
            System.debug(errorMessage);
            throw new AuraHandledException(errorMessage);
        }catch(Exception e){ throw new AuraHandledException('From ExpenditureHelper: ' + e.getMessage()); }
    }

    @AuraEnabled
    public static void deleteSubrecipientHelper(String ids){
        List<String> splitIds = ids.split(',');
        try{
            deleteSubrecipients(splitIds);
        }catch(DmlException de){
            Integer numErrors = de.getNumDml();
            String errorMessage = '';
            String fieldNames = '';
            for(Integer i=0; i<numErrors; i++){
                System.debug('Type: ' + de.getDmlType(i));
                System.debug(i + ': ' + de.getDmlId(i));
                Id id = de.getDmlId(i);
                fieldNames = fieldNames + de.getDmlFieldNames(i);
                errorMessage = errorMessage + ' ' + i + ':'  + ' '+ id.getSobjectType().getDescribe().getName() + de.getDmlStatusCode(i) + + de.getDmlFieldNames(i);
            }
            errorMessage = errorMessage + '|' + fieldNames;
            System.debug(errorMessage);
            throw new AuraHandledException(errorMessage);
        }
        catch(Exception e){  throw new AuraHandledException('From SubrecipientHelper: ' +  e.getMessage());  }
    }

    private static void deleteSubrecipients(List<String> ids){
        List<String> subawardIds = new List<String>();
        for(Sub_Award__c subaward : [SELECT Id FROM Sub_Award__c WHERE Recipient_Profile__c IN :ids]){
            subawardIds.add(subaward.Id);
        }
        try{
            deleteSubawards(subawardIds);
            System.debug('Returned from Deleting subawards');
            List<Recipient_Profile__c> subrecipients = [SELECT Id FROM Recipient_Profile__c WHERE Id in :ids]; 
            
            delete subrecipients;
        }catch(DmlException de){
            throw de;
        }catch(Exception e){throw new AuraHandledException('From Subrecipients: ' + e.getMessage());}
    }

    //TAX OFFSET
    @AuraEnabled(cacheable=true)
    public static List<SLFRF_Tax_Offset__c> getSLFRFTaxOffsets(String recordId, String recordType, String fiscalYear, Integer useless){
        try {
            List<SLFRF_Tax_Offset__c> taxOffsets = new List<SLFRF_Tax_Offset__c>();

            if(fiscalYear != ''){ 
                for(SLFRF_Tax_Offset__c taxOffset : [SELECT Id, Name, Revenue_Reducing_Covered_Change__c, Amount_FRF_Funds_Spent__c, Fiscal_Year__c,
                Amount_Reduction_Exceeds_FRF_Spent__c, Amount_Reduction_Spending__c,Description_of_Spending_Cut__c, Reporting_Unit_Name__c, 
                Revenue_Increasing_Covered_Change__c 
                FROM SLFRF_Tax_Offset__c WHERE Recipient__c =: recordId AND recordTypeId =: recordType AND Fiscal_Year__c LIKE : fiscalYear]) { 
                    taxOffsets.add(taxOffset);
                }
            } else{ 
                for(SLFRF_Tax_Offset__c taxOffset : [SELECT Id, Name, Revenue_Reducing_Covered_Change__c, Amount_FRF_Funds_Spent__c, Fiscal_Year__c,
                Amount_Reduction_Exceeds_FRF_Spent__c, Amount_Reduction_Spending__c,Description_of_Spending_Cut__c, Reporting_Unit_Name__c,
                 Revenue_Increasing_Covered_Change__c 
                 FROM SLFRF_Tax_Offset__c WHERE Recipient__c =: recordId AND recordTypeId =: recordType]) { 
                    taxOffsets.add(taxOffset);
                }
            }
            return taxOffsets;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage()); }
    }

    //LOCATION DATA
    @AuraEnabled(cacheable=true)
    public static List<Broadband_Location__c> getLocationData(String projectId, Integer useless, Integer blockSize, Integer offset, String filters){
        try {
            String query = 'SELECT Id, Name, Project_Name__c, Fabric_ID_Number__c, Provider_ID__c, Longitude__c, Latitude__c, Location_Type__c, Community_Anchor_Location_Type__c, Technology_Type_at_Location__c, Technology_Type_Other__c, Housing_Units_at_Location__c, Speed_Pre_Investment__c, Max_Download_Speed_Offered__c, Max_Upload_Speed_Offered__c, Max_Download_Speed_Delivered__c, Max_Upload_Speed_Delivered__c, Latency_Delivered_at_Location__c';
            query += ' FROM Broadband_Location__c WHERE Project__c = \'' + projectId + '\'';

            if(filters != null && filters != ''){query += filters;}   
            if(blockSize != null && blockSize>0) query += ' LIMIT ' + blockSize;
            if(offset != null) query += + ' OFFSET ' + offset;
            List<Broadband_Location__c> locations = Database.query(query);
            return locations;

        } catch (Exception e) { throw new AuraHandledException(e.getMessage());}
    }

    @AuraEnabled(cacheable=true)
    public static Integer getLocationCount(String recordId, String filters){
        try{
            String query = 'SELECT count() FROM Broadband_Location__c WHERE Project__c = \'' + recordId + '\'';
            if(filters != null && filters != ''){query += filters;}   
            Integer count = Database.countQuery(query);
            return count;
        }catch(Exception e){   throw new AuraHandledException(e.getMessage());}
    }


    //OTHER
    @AuraEnabled
    public static Boolean handleFileUploadValidation(String recordId, String prefix, Integer numberofFiles){
        System.debug('handling project validation >>>> Ben');
        Boolean val = false;
        Integer count = 0; 
        List<ContentVersion> contentVersions = SLFRF_PDF_ComplianceController.fetchFilesV2(recordId);
        if(contentVersions.size() != 0){ 
            for(ContentVersion cv : contentVersions) {
                //if(cv.File_Prefix__c != null && cv.File_Prefix__c.contains(prefix)) {
                if(cv.File_Prefix__c != null && cv.File_Prefix__c == prefix) {
                    count++;
                }
            }
            return count == numberofFiles;
        }
        return val;
    }

    /*This function searches the originalRecordId for documents with the passed in filePrefix.  
      It then creates a content document link to the recoredToPointToId record
      originalRecordId = record with documents you wish to point to.
      recordtoPointToId = record you want to create content document links on
      filePrefix = file prefix that identifies the required content documents.  If you leave this blank
      it will return all of the documents in the originalRecordId BS*/
      @AuraEnabled
      public static Boolean handleMoveFiles(String originalRecordId, String recordToPointToId, String filePrefix){
          //originalRecordId = recipiend id.  filePrefix = randomFilePrefix created when project record was created
          //recordToPointToId = id of object record that needs links to the contentdocuments.
          List<ContentVersion> existingDocsAtDestination = SLFRF_PDF_ComplianceController.fetchFilesV3(recordToPointToId); 
          Map<Id, ContentVersion> mapOfExistingDoc = new Map<Id, ContentVersion>();//Make a map of existing files at destination.
          for(ContentVersion dcv : existingDocsAtDestination){
            mapOfExistingDoc.put(dcv.ContentDocumentId, dcv);
          }
          List<ContentVersion> contentVersions = SLFRF_PDF_ComplianceController.fetchFilesV3(originalRecordId, filePrefix);
          List<ContentDocumentLink> linksToAdd = new List<ContentDocumentLink>();

          for(ContentVersion cv : contentVersions){
            if(!mapOfExistingDoc.keySet().contains(cv.contentDocumentId)){
              ContentDocumentLink cdl = new ContentDocumentLink();
              cdl.ContentDocumentId = cv.contentDocumentId;
              cdl.LinkedEntityId = recordToPointToId;
              cdl.ShareType = 'I';
              cdl.Visibility = 'AllUsers';
              linksToAdd.add(cdl);
            }
          }
         //database.insert(linksToAdd,false);
          insert(linksToAdd);
          
          return linksToAdd.size() > 0;
  
      }

    //   /*this function updates a specific  field given the object name, id and name of the field*/
    // @AuraEnabled(cacheable=true)
    // public static string updateField(String objName, String objId, String fieldToSet, String input){
    //     String Query = 'SELECT Id, Name, ' + fieldToSet + ' FROM ' + objName + ' WHERE id =: objId';
    //     System.debug('querry = ' + Query);
    //     boolean updateRecord = false;
    //     List<sObject> sobjList = Database.query(Query);
    //     String oldValue = '';
    //     if((String)sobjList[0]?.get(fieldToSet) !=null){
    //         System.debug('field = ' + (string)sobjList[0].get(fieldToSet));
    //         // (String)sobjList[0].get(fieldToSet) = input;
    //         oldValue = (String)sobjList[0].put( fieldToSet, input);
    //         updateRecord = true;
    //         //update sobjList[0];
    //     }
    //     if(updateRecord){
    //         update sobjList[0];
    //     }

    //     return oldValue;
    // }
    
    public static void updateStatusClosed(String reportPeriod) {
        Id slfrfRecordType = Schema.SObjectType.SLT_Compliance_Report__c.getRecordTypeInfosByName().get('SLFRF Compliance Report').getRecordTypeId();
        List<SLT_Compliance_Report__c> reports = [SELECT Id FROM SLT_Compliance_Report__c WHERE (Status__c = 'Draft' OR Status__c = 'In Progress') AND Report_period__c =: reportPeriod AND Report_Type__c = 'Quarterly Report' AND RecordTypeId =: slfrfRecordType];
        for (SLT_Compliance_Report__c rep : reports) {
            rep.Status__c = 'Administratively Closed';
        }
        Database.update(reports, false);
        System.debug(reports.size());
    }

    @AuraEnabled
    public static void handleFileUploadRecoveryPlan(String recordId){ 
        SLT_Compliance_Report__c app = [SELECT Id, Name, SLT_Compliance_Report_ID__c FROM SLT_Compliance_Report__c WHERE Id = :recordId LIMIT 1];
        List<ContentVersion> contentVersions = SLFRF_PDF_ComplianceController.fetchFilesV2(recordId);
        for(ContentVersion cv: contentVersions){ 
            cv.Title = app.SLT_Compliance_Report_ID__c + '-' + cv.Title;
        }

        // Update the ContentVersion record
        update contentVersions;
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjectsForBroadband(String recordId){ 
        try {
            List<Project__c> projects = [SELECT Id, Name, Recipient__c, Do_you_have_Broadband_Location_File__c, Sub_Category__c FROM Project__c 
            WHERE Recipient__c =: recordId 
            AND (State_Local_and_Tribal_Application__r.RecordType.Name = 'CRF' 
            OR SLT_Compliance_Report__r.RecordType.Name = 'SLFRF Compliance Report')
            AND Do_you_have_Broadband_Location_File__c = 'Yes'];
            return projects;

        } catch (Exception e) { throw new AuraHandledException(e.getMessage());}
    }


    @AuraEnabled(cacheable=true)
    public static List<SObject> customLookupSearch(String objectName, String searchTerm, String recordId) {
        if(objectName == 'Project__c'){
            if(searchTerm == null || searchTerm == ''){
                List<Project__c> projects = [SELECT Id, Name, Project_Identification_Number__c FROM Project__c WHERE Recipient__c =: recordId AND (State_Local_and_Tribal_Application__r.RecordType.Name =: 'CRF' OR SLT_Compliance_Report__r.RecordType.Name =: 'SLFRF Compliance Report') LIMIT 5];
                return projects;
            }
            else {
                List<Project__c> projects = [SELECT Id, Name, Project_Identification_Number__c FROM Project__c WHERE Recipient__c =: recordId AND (State_Local_and_Tribal_Application__r.RecordType.Name =: 'CRF' OR SLT_Compliance_Report__r.RecordType.Name =: 'SLFRF Compliance Report') AND Name LIKE :('%'+searchTerm+'%') LIMIT 5];
                return projects;
            }
        }
        else{
            Id subrecipientRecordTypeId = Schema.SObjectType.Recipient_Profile__c.getRecordTypeInfosByName().get('Sub Recipient').getRecordTypeId();
            if(searchTerm == null || searchTerm == ''){
                List<Recipient_Profile__c> subrecipients = [SELECT Id, Name, Duns__c,EIN__c, Unique_Entity_Identifier__c FROM Recipient_Profile__c WHERE SLFRF__C=true LIMIT 5];
                return subrecipients;
            }
            else {
                List<Recipient_Profile__c> subrecipients = [SELECT Id, Name, Duns__c,EIN__c, Unique_Entity_Identifier__c FROM Recipient_Profile__c WHERE Name LIKE :('%'+searchTerm+'%') AND SLFRF__C=true LIMIT 5];
                return subrecipients;
            }
        }

        // if(objectName == 'Project__c'){
        //     if(searchTerm == null || searchTerm == ''){
        //         List<Project__c> projects = [SELECT Id, Name, Project_Identification_Number__c FROM Project__c WHERE Recipient__c =: recordId AND (State_Local_and_Tribal_Application__r.RecordType.Name =: 'CRF' OR SLT_Compliance_Report__r.RecordType.Name =: 'SLFRF Compliance Report') LIMIT 5];
        //         return projects;
        //     }
        //     else {
        //         List<Project__c> projects = [SELECT Id, Name, Project_Identification_Number__c FROM Project__c WHERE Recipient__c =: recordId AND (State_Local_and_Tribal_Application__r.RecordType.Name =: 'CRF' OR SLT_Compliance_Report__r.RecordType.Name =: 'SLFRF Compliance Report') AND Name LIKE :('%'+searchTerm+'%') LIMIT 5];
        //         return projects;
        //     }
        // }
        // else{
        //     Id subrecipientRecordTypeId = Schema.SObjectType.Recipient_Profile__c.getRecordTypeInfosByName().get('Sub Recipient').getRecordTypeId();
        //     if(searchTerm == null || searchTerm == ''){
        //         List<Recipient_Profile__c> subrecipients = [SELECT Id, Name, Duns__c,EIN__c, Unique_Entity_Identifier__c FROM Recipient_Profile__c WHERE Prime_Recipient_Lookup__c =: recordId AND RecordTypeId =: subrecipientRecordTypeId AND SLFRF__C=true LIMIT 5];
        //         return subrecipients;
        //     }
        //     else {
        //         List<Recipient_Profile__c> subrecipients = [SELECT Id, Name, Duns__c,EIN__c, Unique_Entity_Identifier__c FROM Recipient_Profile__c WHERE Prime_Recipient_Lookup__c =: recordId AND RecordTypeId =: subrecipientRecordTypeId AND Name LIKE :('%'+searchTerm+'%') AND SLFRF__C=true LIMIT 5];
        //         return subrecipients;
        //     }
        // }
    }
}