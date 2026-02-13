import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class FileDisplay extends NavigationMixin(LightningElement) {
    @api contentDocumentIds;
    // get files(){
    //     debug.log(contentDocumentIds);
    //     return this.contentDocumentIds;
    // }
    @track files =[];
    connectedCallback(){
        console.log('contentDocumentIds', this.contentDocumentIds);
        let temp = this.contentDocumentIds.split(',');
        for(let i in temp){
            console.log(temp[i]);
            this.files.push({
                id:temp[i],
                source: '/' + temp[i]
            });
        }
    }
    downloadFiles(){
        console.log('DOWNLOADING FILES');
        let csfFileIds = '';
        for(let item of this.files) {
            csfFileIds += '/' + item.id;
        }
        console.log('CSFFILEDS')
        console.log(csfFileIds)
        // if finds file navigates to that file, otherwise generate one
        if(csfFileIds){ 
            let baseUrl = window.location.href;
            console.log(baseUrl);
            baseUrl = baseUrl.substring(0, baseUrl.indexOf('/',9));
            console.log(baseUrl);
            console.log(baseUrl + '/sfc/servlet.shepherd/document/download' + csfFileIds + '?operationContext=S1');
            window.open(baseUrl + '/sfc/servlet.shepherd/document/download' + csfFileIds + '?operationContext=S1', "_self");
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__webPage',
            //     attributes: {
            //         url: baseUrl + '/sfc/servlet.shepherd/document/download' + csfFileIds + '?operationContext=S1'
            //     }
            // }, false)
        }
    }

}