import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import styles from '@salesforce/resourceUrl/LITCOmniscriptStyles';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import getReport from '@salesforce/apex/LITCReportingController.getReport'; 
import getApplication from '@salesforce/apex/LITCReportingController.getApplication'; 

export default class LitcLineItemVarianceTotals extends LightningElement {
    @api recordId;
    @track appId;
    @track rows;

    stylePath = styles;

    constructor() {
        super();
        Promise.all([
          loadStyle(this, `${this.stylePath}`),
        ]).catch(error => {
              console.log(error)
        });
    }

    connectedCallback() {
        console.log(this.recordId);

        Promise.all([
            getReport({ recordId: this.recordId }),
            getApplication({ recordId: this.recordId })
        ])
            .then(([reportData, appData]) => {
                console.log('Report', reportData);
                console.log('App', appData);

                this.appId = reportData.Application_for_Federal_Assistance__c;

                const categories = [
                    { name: 'Personnel', fields: ['Personnel_Dollar_Federal_Total__c', 'Personnel_Dollar_Match_Total__c', 'Personnel_Total_Formula__c'] },
                    { name: 'Fringe Benefits', fields: ['Fringe_Dollar_Federal_Total__c', 'Fringe_Dollar_Match_Total__c', 'Fringe_benefits_Total_Formula__c'] },
                    { name: 'Travel', fields: ['Travel_Federal_Total__c', 'Travel_Match_Total__c', 'Travel_Total_Formula__c'] },
                    { name: 'Equipment', fields: ['Equipment_Federal_Total__c', 'Equipment_Match_Total__c', 'Equipment_Total_Formula__c'] },
                    { name: 'Supplies', fields: ['Supplies_Federal_Total__c', 'Supplies_Match_Total__c', 'Supplies_Total_Formula__c'] },
                    { name: 'Contractual', fields: ['Contractual_Federal_Total__c', 'Contractual_Match_Total__c', 'Contractual_Total_formula__c'] },
                    { name: 'Other Expenses', fields: ['Other_expenses_Federal_Total__c', 'Other_Expenses_Match_Total__c', 'Other_Expenses_Total_Formula__c'] },
                    { name: 'Indirect Expenses', fields: ['Indirect_Expenses_Federal_Total__c', null, null] },
                    { name: 'Total Expenses', fields: ['Total_Federal_Expenses__c', 'Total_Match_Expenses__c', 'Total_Expenses__c'] }
                ];

                this.rows = categories.map((category, index) => {
                    const federalField = category.fields[0];
                    const matchField = category.fields[1];
                    const totalField = category.fields[2];

                    // Calculate variance 
                    const federalVariance = federalField ? (reportData[federalField] || 0) - (appData[federalField] || 0) : 0;
                    const matchVariance = matchField ? (reportData[matchField] || 0) - (appData[matchField] || 0) : 0;
                    const totalVariance = totalField ? (reportData[totalField] || 0) - (appData[totalField] || 0) : 0;

                    // Calculate percentages 
                    const federalTotal = appData.Total_Federal_Expenses__c || 1; 
                    const matchTotal = appData.Total_Match_Expenses__c || 1;
                    const totalExpenses = appData.Total_Expenses__c || 1;

                    const federalPercent = federalField ? ((federalVariance / federalTotal) * 100).toFixed(2) : '0.00';
                    const matchPercent = matchField ? ((matchVariance / matchTotal) * 100).toFixed(2) : '0.00';
                    const totalPercent = totalField ? ((totalVariance / totalExpenses) * 100).toFixed(2) : '0.00';

                    return {
                        expenseCategory: category.name,
                        federalDollar: federalVariance.toFixed(2),
                        federalPercent: federalPercent,
                        matchDollar: matchVariance.toFixed(2),
                        matchPercent: matchPercent,
                        totalDollar: totalVariance.toFixed(2),
                        totalPercent: totalPercent, 
                        rowClass: index === categories.length - 1 ? 'blue' : ''
                    };
                });

                console.log(JSON.stringify(this.rows));
            })
            .catch(err => {
                console.error('Error processing data:', err);
            });
    }   
}