import { LightningElement, track, wire } from 'lwc';
import teiBadge1 from '@salesforce/resourceUrl/teiBadge1';
import teiBadge2 from '@salesforce/resourceUrl/teiBadge2';
import teiCoach from '@salesforce/resourceUrl/teiCoach';

export default class TeiCoachingOverview extends LightningElement {
  teiCoach = teiCoach;
  teiBadge1 = teiBadge1;
  teiBadge2 = teiBadge2;

  get source(){
    return 'https://www.youtube.com/embed/PpmeQj-LFoY';
  }
}