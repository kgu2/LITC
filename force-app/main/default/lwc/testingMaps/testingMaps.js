import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import GEOJSON from '@salesforce/resourceUrl/tempStates';
import GOOGLE_MAPS from '@salesforce/resourceUrl/tempMap';

export default class testingMaps extends LightningElement {
  map;
  isGoogleMapsInitialized = false;
  @api recordId;

  renderedCallback() {
    console.log('i here')
    if (this.isGoogleMapsInitialized) return;
    this.isGoogleMapsInitialized = true;

  
    // loadScript(this, GOOGLE_MAPS)
    //   .then(() => this.initMap())
    //   .catch(error => {
    //     console.error('Google Maps failed to load', error);
    //   });

      //   loadScript(this, 'https://maps.googleapis.com/maps/api/js?key=AIzaSyBjE09NfSW5HZpwg1CU5_QZ6u76UOSrxZE&libraries=geometry')
      // .then(() => this.initMap());
  
  }

  async initMap() {
    console.log('i initMaps')

    console.log('initMap called');
    console.log('google:', typeof google);
    console.log('google.maps:', google?.maps);

    const mapEl = this.template.querySelector('.map-container');

    console.log('mapEl:', mapEl);

    if (!mapEl) {
      console.error('mapEl not found — template not rendered yet?');
      return;
    }

    mapEl.style.height = '600px';

          console.log('0');

    this.map = new google.maps.Map(mapEl, {
      center: { lat: 39.8283, lng: -98.5795 },
      zoom: 4,
    });

    if (!window.google || !window.google.maps) {
    console.error('Google Maps JS SDK not loaded');
    return;
  }

      console.log('1');

    const response = await fetch(GEOJSON);
    const geojson = await response.json();

    console.log('2');

    this.map.data.addGeoJson(geojson);

    this.map.data.setStyle({
      fillColor: 'blue',
      strokeColor: 'white',
      strokeWeight: 1,
      fillOpacity: 0.2,
    });

     console.log('3');

        console.log('ffnish')
  }
}
