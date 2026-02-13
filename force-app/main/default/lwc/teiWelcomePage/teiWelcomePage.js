import { LightningElement, track } from 'lwc';
import teiBackground from '@salesforce/resourceUrl/teiBackground';
import teiLogo from '@salesforce/resourceUrl/teiLogo';

export default class TeiWelcomePage extends LightningElement {
  @track menuOpen = false;
  teiBackground = teiBackground;
  teiLogo = teiLogo;

  get navClass() {
    return `nav ${this.menuOpen ? 'nav--open' : ''}`;
  }

  toggleMenu() {
    this.menuOpen = !this.menuOpen;
  }

  handleLogin() {
    window.location.href = 'https://caia.treasury.gov/idp/SSO.saml2';
  }

  get heroBackgroundImg(){
    return `background-image: url(${teiBackground});`;
  }
}