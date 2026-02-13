import { LightningElement, api, wire, track } from 'lwc';
import pubsub from 'omnistudio/pubsub';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import omniscriptBaseAction from 'omnistudio/omniscriptBaseAction'


// required fields
// handle conditional fields later...currently conditional fields for clinic model are not handled
const formSF424Fields = {
    // conditional blocks currently not handled
    Block_Applicant_Information: ['Do_you_have_a_UEI__c'],  
    Block_Organization_Unit: ['First_Name__c', 'Last_Name__c', 'Telephone_Number__c', 'Email__c'],
    Block_Type_Of_Applicant: ['Type_of_Applicant_1__c'],
    Block_Project_Info: [], // validation handled thru lwc
    Block_Estimated_Funding: ['Is_Applicant_Delinquent_on_Federal_Debt__c'],
    Block_Authorized_Representative: ['Auth_Rep_First_Name__c', 'Auth_Rep_Last_Name__c', 'Auth_Rep_Title__c', 'Auth_Rep_Number__c', 'Auth_Rep_Email__c'],
};

const form13424Fields = {
    Block_Clinic_Information: ['Clinic_Name__c', 'Clinic_Public_telephone_number__c', 'Clinic_Street__c', 'Clinic_City__c', 'Clinic_State__c', 'Clinic_Zip_Code__c','Clinic_Services_and_Delivery_Model__c'],
    Block_Background: ['Organization_Overview__c', 'Type_of_Services_Provided__c', 'Experience__c'],
    Block_Taxpayer_Access: ['Language_Access__c', 'Reasonable_Accommodations__c', 'Geographic_Area_and_Target_Audience__c', 'Partners_and_Networks__c', 'Publicity_and_Outreach_Methods__c'],
    Block_Taxpayer_Services: ['Taxpayer_Education__c', 'Advocacy__c'],
    Block_Staffing: ['QTE_Identified_Hired__c', 'TCO_Last_name__c', 'TCO_First_name__c', 'TCO_Telephone_number__c', 'TCO_Email_address__c', 'TCO_Title__c', 'Student_s_Per_Semester_Type__c'],
    Block_Volunteers: ['Other_Volunteer_Recruitment__c', 'Volunteer_Recruitment_and_Retention__c'],
    Block_Clinic_Operations: ['Dates_of_Operation__c', 'After_Hours_or_Weekend_Service__c', 'Time_Tracking__c'],
    Block_Training_Resources: ['In_house_Training__c', 'External_Training__c', 'Research_Materials_and_Software__c'],
    Block_Financial_Responsibility: ['Experience_Managing_Grants__c', 'Accounting_Procedures__c', 'Free_Tax_Preparation__c', 'Tracking_Grant_Expenditures__c', 'Audits_or_Financial_Reviews__c', 'Financial_Statement_Information__c', 'Financial_Statement_Type__c', 'Legal_Services_Corporation_Funding__c', 'Year_end_Date_of_Financials__c'],
    Block_Program_Information: ['Program_Evaluation__c', 'Program_Improvement__c', 'Program_Numerical_Goals_Narrative__c', 'Educational_Activates_to_Low_Income__c', 'Low_Income_ESL_TP_Service_Providers__c'],
    Block_Civil_Rights: ['Civil_Rights_Review_Activity__c', 'Data_Compilation_and_Maintenance__c', 'Public_Display_of_Civil_Rights_Poster__c','Active_Lawsuits_or_Complaints__c', 'Federal_Financial_Assistance__c'],
} 

const form13424ContinuationFields = {
    Block_Taxpayer_Access: ['Any_Major_Changes_Geographic_Target__c', 'Any_Major_Changes_Partners_Network__c', 'Any_Major_Changes_Publicity_Outreach__c'],
    Block_Taxpayer_Services: ['Any_Major_Changes_Tax_Education__c', 'Any_Major_Changes_Tax_Advocacy__c'],
    Block_Staffing: ['Any_Major_Changes_Other_Staff__c', 'Any_Major_Changes_Students__c'],
    Block_Volunteers: ['Any_Major_Changes_Other_Vol_Rcrmnt__c', 'Any_Major_Changes_Vol_Rcrmnt_Rt__c'],
    Block_Clinic_Operations: ['Any_Major_Changes_Dates_Days_and_Hours__c', 'Any_Major_Changes_Time__c', 'Any_Major_Changes_Complaint_Procedures__c'],
    Block_Training_Resources: ['Any_Major_Changes_Training_Resource__c', 'Any_Major_Changes_In_house_Training__c', 'Any_Major_Changes_External_Training__c', 'Any_Major_Changes_Research_Materials__c'],
    Block_Financial_Responsibility: ['Any_Major_Changes_Financial_Experience__c', 'Any_Major_Changes_Accounting_Procedure__c', 'Any_Major_Changes_Free_Tax_Preparation__c', 'Any_Major_Changes_Tracking_Grant__c', 'Any_Major_Changes_Audits_Fin_Reviews__c'],
    Block_Program_Information: ['Any_Major_Changes_Program_Evaluation__c', 'Any_Major_Changes_Improvement__c'],
} 

// const formLegacy13424Fields = {
//     Block_Applicant_Information: ['Legal_name_of_sponsoring_organization__c', 'Last_Name__c', 'First_Name__c','Title__c','Phone_number__c','Email_address__c','Street__c','City__c','State__c','ZIP_4_code__c'],
//     Block_Clinic_Information: ['Name_of_clinic__c', 'Public_telephone_number__c', 'Clinic_Street__c','Clinic_City__c','Clinic_State__c', 'Clinic_ZIP_4_code__c',]
// }

const formLegacy13424Fields = {
    Block_Applicant_Information: [
        'Legal_name_of_sponsoring_organization__c', 'Last_Name__c', 'First_Name__c', 'Title__c', 'Phone_number__c', 
        'Email_address__c', 'Street__c', 'City__c', 'State__c', 'ZIP_4_code__c'
    ],
    Block_Clinic_Information: ['Name_of_clinic__c', 'Public_telephone_number__c', 
        'Clinic_Street__c','Clinic_City__c','Clinic_State__c', 'Clinic_ZIP_4_code__c',
        'Clinic_Mailing_Street__c', 'Clinic_Mailing_City__c', 'Clinic_Mailing_State__c', 'Clinic_Mailing_Zip_4_code__c', 
        'Clinic_Director_Last_Name__c', 'Clinic_Director_First_Name__c', 'Clinic_Director_Telephone_number__c', 'Clinic_Director_Email_address__c', 
        'QTE_Last_name__c', 'QTE_First_name__c', 'QTE_Telephone_number__c', 'QTE_Email_address__c', 
        'QBA_Last_name__c', 'QBA_First_name__c', 'QBA_Telephone_number__c', 'QBA_Email_address__c', 
        'TCO_Last_name__c', 'TCO_First_name__c', 'TCO_Title__c', 'TCO_Telephone_number__c', 'TCO_Email_address__c'
    ]
}

const formLegacy13424MFields = {
    Background_Information: [
        'Applicant_Experience__c', 'Applicant_Affliations__c', 'Applicant_Supervising_Experience__c','Applicant_Networking_Experience__c',
        'Accounting_Procedures_and_Support_Staff__c','Exp_Tracking_and_Verifying_Method__c','VITA_Site__c','Audits_and_Controls_Plans__c',
        'Financial_Statement__c','QBA_Name_and_Qualifications__c'
    ],
    Block_Program_Performance_Plan: [
        'Qualified_Tax_Expert_QTE__c','Clinic_Director__c','Clinic_Staff__c','Student_s_Per_Semester_Type__c',
        'Clinic_Staff_Authorized_to_Represent__c','Time_Tracking__c', 'Geographic_Area_and_Target_Audience__c','Representation_Services_Type__c',
        'Consulation_Service_to_be_provided__c','Educational_Activities_to_be_provided__c', 'Service_Delivery_Tracking_Plans__c','Publicity_and_Outreach_Methods__c',
        'Clinic_Operation_Hours__c','Nominal_Fee__c', 'In_house_Training__c','Continuing_Professional_Education_CPE__c','Tax_Library_and_Research_Resources__c',
        'Strategy_for_Monitoring_Program_Results__c','Indicate_Measure_Client_Satisfaction__c','Educa_Activ_to_Low_Income_First_Year__c', 'Low_Income_ESL_to_be_reached_First_Year__c',
    ],
    Block_Civil_Rights_Review: [
        'Active_Lawsuits_or_Complaints__c','Federal_Financial_Assistance__c','Civil_Rights_Review_Activity__c',
        'Reasonable_Accommodations__c','Data_Compilation_and_Maintenance__c','Public_Display_of_Civil_Rights_Poster__c'
    ]
}

export default class litcCustomEventListener extends omniscriptBaseAction {

    @api version;


    connectedCallback() {
        pubsub.register('omniscript_action', {
            data: this.handleOmniActionData.bind(this),
        });
        pubsub.register('omniscript_datajson', {
            data: this.handleJsonDataChange.bind(this),
        });
    }

    handleJsonDataChange(data){ 
        if(data.OmniScript === 'Form_SF424_English'){ 
            this.handleValidationsSF424(data.omniJsonData);
        }

        if(data.OmniScript === 'Form_New13424_English' && this.isNew){ 
            this.handleValidationsForm13424(data.omniJsonData);
        }

        if(data.OmniScript === 'Form_Continuation13424_English' && this.isNew){ 
            // this line should be commented out 9/22/25, should not handle new validations on a continuation application
            this.handleValidationsForm13424(data.omniJsonData);

            // 2.4.25 continuation is commented out - will open up next year, currently same form as new
            // continuation form uncommented 9/18/25
            this.handleValidationsFormContinuation13424(data.omniJsonData);
        }

        if((data.OmniScript === 'Form_Old13424_English') && this.isLegacy){ 
            this.handleValidationsLegacyForm13424(data.omniJsonData);
        }
        if((data.OmniScript === 'Form_Old13424M_English') && this.isLegacy){ 
            this.handleValidationsLegacyForm13424M(data.omniJsonData);
        }

    }

    handleOmniActionData(data) {
        // console.log(JSON.stringify(data));

        // 13424
        if(data.ActionTargetName === 'LITCSubmitForm13424' || data.ActionTargetName === 'LITCSubmitFormLegacy13424'){ 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Saved',
                variant: 'success',
                mode: 'dismissable'
            }));
        }

        // SF424
        if(data.ActionTargetName === 'LITCSubmitFormSF424'){ 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Saved',
                variant: 'success',
                mode: 'dismissable'
            }));
        }

    }

    handleValidationsSF424(data){ 
        // process validations for status icons,

        // default for applicant_info is set to true, conditioal blocks are not handled.
        const validationResults = {Block_Applicant_Information: true, Block_Organization_Unit: false, Block_Type_Of_Applicant: false, Block_Project_Info : false, Block_Authorized_Representative: false, Block_Estimated_Funding: false};
        for (const [blockName, fields] of Object.entries(formSF424Fields)) {
            const blockData = data[blockName];
            if(blockData) {
                validationResults[blockName] = fields.every(field => 
                    blockData.hasOwnProperty(field) && blockData[field] != null
                )
            }
        }

        // gets all fields when omnsicript changes
        const allFields = Object.values(data).reduce((acc, block) => {
            return { ...acc, ...block };
          }, {});
          

        this.dispatchEvent(new CustomEvent('getresultssf', { detail: {results: validationResults, data: allFields}}));
    }
    
    handleValidationsForm13424(data){ 
        // process validations for status icons
        const validationResults = {Block_Clinic_Information: false, Block_Background: false, Block_Taxpayer_Access : false, Block_Taxpayer_Services: false, Block_Staffing: false, Block_Volunteers: false, Block_Clinic_Operations: false, Block_Training_Resources: false, Block_Financial_Responsibility: false, Block_Program_Information: false, Block_Civil_Rights: false  };

        for (const [blockName, fields] of Object.entries(form13424Fields)) {
            const blockData = data[blockName];
            if(blockData) {
                validationResults[blockName] = fields.every(field => 
                    blockData.hasOwnProperty(field) && blockData[field] != null
                )
            }
        }
        
        // gets all fields when omnsicript changes        
        const allFields = Object.entries(data).reduce((acc, [key, value]) => {
            if (typeof value === 'object' && value !== null) {
                return { ...acc, ...value };
            } else {
                return { ...acc, [key]: value };
            }
        }, {});
        
        this.dispatchEvent(new CustomEvent('getresults13424', { detail: {results: validationResults, data: allFields}}));
    }

    handleValidationsLegacyForm13424(data){ 

        const validationResults = {Block_Applicant_Information: false, Block_Clinic_Information: false, Block_Civil_Rights_Review: false  };

        for (const [blockName, fields] of Object.entries(formLegacy13424Fields)) {
            const blockData = data[blockName];
            console.log(JSON.stringify(blockData));
            if(blockData) {
                validationResults[blockName] = fields.every(field => 
                    blockData.hasOwnProperty(field) && blockData[field] != null
                )
            }
        }
          
        const allFields = Object.entries(data).reduce((acc, [key, value]) => {
            if (typeof value === 'object' && value !== null) {
                return { ...acc, ...value };
            } else {
                return { ...acc, [key]: value };
            }
        }, {});
        
        this.dispatchEvent(new CustomEvent('getresultslegacy13424', { detail: {results: validationResults, data: allFields}}));
    }

    handleValidationsLegacyForm13424M(data){ 
        console.log(JSON.stringify(data));
        const validationResults = {Background_Information: false, Block_Program_Performance_Plan: false, Block_Civil_Rights_Review: false };

        for (const [blockName, fields] of Object.entries(formLegacy13424MFields)) {
            const blockData = data[blockName];
            if(blockData) {
                validationResults[blockName] = fields.every(field => 
                    blockData.hasOwnProperty(field) && blockData[field] != null
                )
            }
        }

        console.log(JSON.stringify(validationResults));
          
        const allFields = Object.entries(data).reduce((acc, [key, value]) => {
            if (typeof value === 'object' && value !== null) {
                return { ...acc, ...value };
            } else {
                return { ...acc, [key]: value };
            }
        }, {});
        
        this.dispatchEvent(new CustomEvent('getresultslegacy13424m', { detail: {results: validationResults, data: allFields}}));
    }



    handleValidationsFormContinuation13424(data){ 
        // required if major changes = yes
        const validationResults = {Block_Taxpayer_Access : false, Block_Taxpayer_Services: false, Block_Staffing: false, Block_Volunteers: false, Block_Clinic_Operations: false, Block_Training_Resources: false, Block_Financial_Responsibility: false, Block_Program_Information: false };
        
        if(data.Any_Major_Changes_to_your_program_plan__c === 'Yes'){ 
            for (const [blockName, fields] of Object.entries(form13424ContinuationFields)) {
                const blockData = data[blockName];
                if(blockData) {
                    validationResults[blockName] = fields.every(field => 
                        blockData.hasOwnProperty(field) && blockData[field] != null
                    )
                }
            }
        } else{ 
            validationResults = {};
        }

        const allFields = Object.entries(data).reduce((acc, [key, value]) => {
            if (typeof value === 'object' && value !== null) {
                return { ...acc, ...value };
            } else {
                return { ...acc, [key]: value };
            }
        }, {});

        this.dispatchEvent(new CustomEvent('getresults13424', { detail: {results: validationResults, data: allFields}}));
    }



    get isLegacy(){ 
        return this.version === 'Legacy';
    }
    get isNew(){ 
        return !this.isLegacy;
    }

}