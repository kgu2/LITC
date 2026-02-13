import { LightningElement, track, api, wire } from 'lwc';
import { updateRecord, getRecord, getFieldValue} from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import projectOverviewStyles from '@salesforce/resourceUrl/sltPortalChecklistStyles';
import getReports from '@salesforce/apex/SLT_ComplianceController.getComplianceReports';
// import generatePDFSLFRF from '@salesforce/apex/SLFRF_PDF_ComplianceController.createPDF';
import createPDFFileLimit from '@salesforce/apex/SLFRF_PDF_ComplianceController.createPDFFileLimit';
import generateCSV from '@salesforce/apex/SLFRF_PDF_ComplianceController.generateCSV';
// import createCSVSubrecipients from '@salesforce/apex/SLFRF_PDF_ComplianceController.createCSVSubrecipients';
import fetchFiles from '@salesforce/apex/SLFRF_PDF_ComplianceController.fetchFiles'; 
import generatePDFSLFRFInterim from '@salesforce/apex/SLT_ComplianceController.createPDFSLFRFInterim';

const columnsSLFRF = [
    { label: 'Report Name', fieldName: 'Name', type : 'text', wrapText: true, hideDefaultActions: true, sortable: "true"},
    { label: 'Report Type', fieldName: 'reportType', type : 'text', wrapText: true,hideDefaultActions: true, sortable: "true"},
    { label: 'CFDA No', fieldName: 'CFDA_on_award__c', type : 'text', hideDefaultActions: true, sortable: "true"},
    { label: 'Report Period', fieldName: 'Report_Period__c', wrapText: true, type : 'text', hideDefaultActions: true, sortable: "true"},
    { label: 'Deadline', fieldName: 'submissionDeadline', type : 'text', hideDefaultActions: true, sortable: "true"},
    { label: 'Status', fieldName: 'Status__c', type : 'text', hideDefaultActions: true, sortable: "true",
        cellAttributes: { class: { fieldName: 'statusStyle' } }
    },
    
    {label: 'Provide Information', hideDefaultActions: true, type: "button-icon", name: 'provideInfo', typeAttributes: {  
        iconName: { fieldName: 'dynamicIconProvideInfo' },
        variant: 'brand',
        initialWidth: 175,
        class : { fieldName: 'stylingProvideInformation' }
    }},
    {label: 'Download', hideDefaultActions: true, type: "button-icon", initialWidth: 100, typeAttributes: {  
        iconName: 'action:download',
        variant: 'brand',
        class : { fieldName: 'stylingDownload' }
    }},
];

export default class SlfrfQuarterlyChecklist extends NavigationMixin(LightningElement) {
    @track showSLFRFTable = false;
    @track SLFRFrecordsToDisplay = [];
    @track draftReports;
    @track SLFRFComplianceReports;
    @track columnsSLFRF = columnsSLFRF;
    @track projectStylePath = projectOverviewStyles;
    @track isLoading;

    @track pageSizeOptions=[5,10,25];
    @track sortBy;
    @track sortDirection;
    @track showAccordian;

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.projectStylePath}`)
        ]);
    }

    @wire(getReports)
    setReports({error, data}) {
        if (data) {   
            let tempSLFRFReports = [];
            let tempSLFRFReportsDraft = [];

            data.forEach(function(item) {
                let tempRecord = Object.assign({}, item);

                tempRecord.submissionDeadline = tempRecord.Submission_Deadline__c != undefined ? new Date(tempRecord.Submission_Deadline__c).toLocaleDateString("en-US") : undefined;    

                if(tempRecord.Program_Name__c === 'CRF' || !tempRecord.Program_Name__c){
                    tempRecord.reportType = tempRecord.Report_Type__c;
                    if(tempRecord.reportType == 'Neu Report') tempRecord.reportType = 'NEU Agreements and Supporting Documents';
                    if(tempRecord.reportType == 'Quarterly Report') tempRecord.reportType = 'Project and Expenditure Report';
                    if(tempRecord.Streamline_Closeout_Report__c) tempRecord.Name = tempRecord.Name + '-Final'
                    if(tempRecord.reportType){ 
                        tempSLFRFReports.push(tempRecord);
                    }
                }
                
                if(tempRecord.Status__c === 'Submitted'){
                    tempRecord.statusStyle = 'slds-text-color_success';
                    tempRecord.stylingProvideInformation = 'darkblue'
                    tempRecord.dynamicIconProvideInfo = 'action:preview';
                    tempRecord.stylingDownload = 'slds-show gray slds-button';
                }
                else{
                    tempRecord.dynamicIconProvideInfo = 'action:edit';
                    tempRecord.statusStyle = 'slds-text-color_error';
                    tempRecord.stylingProvideInformation = 'lightblue'
                    tempRecord.stylingDownload = 'slds-hide gray slds-button';

                    if((tempRecord.Status__c === 'Draft' || tempRecord.Status__c === 'In Progress') && tempRecord.reportType){ 
                        tempSLFRFReportsDraft.push(tempRecord);
                        console.log(tempRecord)
                    }
                }
    
                // disable previous report period view
                if(tempRecord.reportType === 'Project and Expenditure Report' && !(tempRecord.Report_Period__c == 'Annual March 2024' || tempRecord.Report_Period__c == 'Quarter 3 2024 (July-September)')){ 
                    tempRecord.stylingProvideInformation = 'slds-hide';
                } 

                // always disable access if any one of these values
                if(tempRecord.Status__c === 'Administratively Closed' || tempRecord.Status__c === 'Closed-Submitted' || tempRecord.Status__c === 'Closed-Draft'){ 
                    tempRecord.stylingProvideInformation = 'slds-hide darkblue';
                }

                if(tempRecord.reportType === 'NEU Agreements and Supporting Documents' || tempRecord.reportType == 'Recovery Plan'){
                    tempRecord.stylingDownload = 'slds-hide gray slds-button';
                }
            });

            this.SLFRFComplianceReports = tempSLFRFReports;
            if(tempSLFRFReports.length > 0){
                this.showSLFRFTable = true;
            }
    
            this.SLFRFrecordsToDisplay = this.SLFRFComplianceReports;      
            this.draftReports = tempSLFRFReportsDraft;          
        }
    
        else if (error) {
            console.log(error);
        }

    }

    handlePaginatorChangeSLFRF(event){
        this.SLFRFrecordsToDisplay = event.detail;
    }

    doSortingSLFRF(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortDataSLFRF(this.sortBy, this.sortDirection);
    }

    sortDataSLFRF(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.SLFRFrecordsToDisplay));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';  
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.SLFRFrecordsToDisplay = parseData;
    }   



    handleRowAction(event){
        let button = event.detail.action.class.fieldName;
        let reportType = event.detail.row.reportType;

        console.log(button);
        console.log(reportType)

        if(button === 'stylingProvideInformation'){

            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                  actionName: 'view',
                  recordId : event.detail.row.Id,
                  objectApiName : 'SLT_Compliance_Report__c'
                  }
              });

              if( reportType ==='Project and Expenditure Report' && event.detail.row.Status__c === 'Draft'){ 
                updateRecord({ fields: { Id: event.detail.row.Id, Status__c : 'In Progress'}}).catch(error=>{console.log(error)});
              }
        }
        else if(button === 'stylingDownload' && reportType ==='Interim Report'){
            let id = event.detail.row.Id;
            generatePDFSLFRFInterim({ reportId: id }).then(res=>{
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__webPage',
                    attributes: {
                        url: res           
                    },
                }).then(generatedUrl => {
                    window.open(generatedUrl);
                });
            }).catch(err=>{
                console.log(err);
            })
    
        }
        else if(button === 'stylingDownload' && reportType ==='Project and Expenditure Report'){
            let id = event.detail.row.Id;
            let reportPeriod = event.detail.row.Report_Period__c;
    
            fetchFiles({recordId: id}).then(data=>{ 
                let filesList = JSON.parse(JSON.stringify(data));
                let fileId = '';

                // check if files contain the current period's PDF
                filesList.some(obj => {
                    if(obj.ContentDocument.Title.includes(reportPeriod) && obj.ContentDocument.FileType == 'PDF' && obj.ContentDocument.ContentSize > 25){ 
                        fileId = obj.ContentDocumentId;
                    }
                });

                // checks to see if they have csv files. If they do then download a zip of csv files
                let csfFileIds = '';
                for(let item of filesList) {
                    if(item.ContentDocument.Title.includes(reportPeriod) && (item.ContentDocument.FileType == 'CSV' || item.ContentDocument.FileType == 'EXCEL')){ 
                        csfFileIds += '/' + item.ContentDocumentId;
                    }
                }

                // special condition for Q1 Reports, only grab the pdf on 6/28
                if(reportPeriod == 'Quarter 1 2022 (January-March)'){ 
                    filesList.some(obj => {
                        if(obj.ContentDocument.Title.includes(reportPeriod) && obj.ContentDocument.FileType == 'PDF' && obj.ContentDocument.ContentSize > 25){ 
                            console.log(obj.ContentDocument.CreatedDate);
                            if(obj.ContentDocument.CreatedDate.includes('2022-06-28')){ 
                                fileId = obj.ContentDocumentId;
                            }
                            
                        }
                    });
                }

                // if finds file navigates to that file, otherwise generate one
                if(fileId || csfFileIds){ 
                    let baseUrl = window.location.href;
                    baseUrl = baseUrl.substring(0, baseUrl.indexOf('/s'));
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: baseUrl + '/sfc/servlet.shepherd/document/download/' + fileId + csfFileIds + '?operationContext=S1'
                        }
                    }, false)
                }
                else{ 
                    // error generating pdf -> file limit option
                    this.isLoading = true;
                    createPDFFileLimit({ reportId: id, fileName: 'P&E Report', reportPeriod: reportPeriod }).then(()=>{
                        console.log("GENERATING FILE LIMIT PDF");
                        generateCSV({ reportId: id, type: 'subawards', reportPeriod: reportPeriod}).then(()=>{ 
                            generateCSV({ reportId: id, type: 'subrecipients', reportPeriod: reportPeriod}).then(()=>{ 
                                generateCSV({ reportId: id, type: 'expenditures', reportPeriod: reportPeriod}).then(()=>{ 
                                    this.isLoading = false;
                                    // if csv files were generated bc of file limit then navigate to those csv files
                                    fetchFiles({recordId: id}).then(data=>{ 
                                        let filesList = JSON.parse(JSON.stringify(data));
                                        let fileId = '';

                                        // check if files contain the current period's PDF
                                        filesList.some(obj => {
                                            if(obj.ContentDocument.Title.includes(reportPeriod) && obj.ContentDocument.FileType == 'PDF' && obj.ContentDocument.ContentSize > 25){ 
                                                fileId = obj.ContentDocumentId;
                                            }
                                        });

                                        // checks to see if they have csv files. If they do then download a zip of csv files
                                        let csfFileIds = '';
                                        for(let item of filesList) {
                                            if(item.ContentDocument.Title.includes(reportPeriod) && (item.ContentDocument.FileType == 'CSV' || item.ContentDocument.FileType == 'EXCEL')){ 
                                                csfFileIds += '/' + item.ContentDocumentId;
                                            }
                                        }

                                        // if finds file navigates to that file, otherwise generate one
                                        if(fileId || csfFileIds){ 
                                            let baseUrl = window.location.href;
                                            baseUrl = baseUrl.substring(0, baseUrl.indexOf('/s'));
                                            this[NavigationMixin.Navigate]({
                                                type: 'standard__webPage',
                                                attributes: {
                                                    url: baseUrl + '/sfc/servlet.shepherd/document/download/' + fileId + csfFileIds + '?operationContext=S1'
                                                }
                                            }, false)
                                        }
                                    })
                                    
                                }).catch(error=>{ 
                                    console.log(error);
                                })
                            }).catch(error=>{ 
                                console.log(error);
                            })
                        }).catch(error=>{ 
                            console.log(error);
                        })
                    }).catch(error=>{
                        this.isLoading = false;
                        console.log(error);
                    })
                }

            }).catch(error=>{ 
                console.log(error);
                this.isLoading = false;
            })
        }
       
    }

    toggleAccordian(){
        this.showAccordian = !this.showAccordian;
    }
    goToReport(event){ 
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: 'SLT_Compliance_Report__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
        // this[NavigationMixin.Navigate]({
        //     type: "standard__recordPage",
        //     attributes: {
        //       actionName: 'view',
        //       recordId : event.currentTarget.dataset.id,
        //       objectApiName : 'SLT_Compliance_Report__c'
        //       }
        //   });
    }
    get label(){ 
        return 'The following ' + this.draftReports.length + ' report(s) still require immediate action';
    }
    get draftReportsSize(){ 
        return this.draftReports && this.draftReports.length > 0;
    }

}