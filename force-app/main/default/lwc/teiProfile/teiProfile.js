import { LightningElement, track, wire } from 'lwc';
import getContactInfo from '@salesforce/apex/teiPortalController.getContactInfo';

export default class TeiProfile extends LightningElement {
  @track name;
  @track title;
  @track directPhone;
  @track mobilePhone;
  @track email;
  @track address;
  @track useless = 0;

//   sections = [
//     { title: 'Summary', isTeam: false, isConnections: false },
//     { title: 'Interests', isTeam: false, isConnections: false },
//     { title: 'Team', isTeam: true, isConnections: false },
//     { title: 'Connections', isTeam: false, isConnections: true }
//   ];
   @wire(getContactInfo, {contactId: '', 'useless': '$useless'})
    receivedContactInfo({ error, data }) {
        if(data){
            console.log(JSON.stringify(data));
            this.name = data.Name;
            this.title = data.TEI_Connect_Role__c;
            this.directPhone = data.Phone;
            this.mobilePhone = data.MobilePhone;
            this.email = data.Email;
        }else if(error){
            console.error(error);
        }
    }
}