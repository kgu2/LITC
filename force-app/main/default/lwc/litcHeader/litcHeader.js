import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import utilities from 'c/utilities';

export default class LitcHeader extends utilities {
    @api currentPage = 'overview';
    @track showHelpPopover;

    navigateFooter(){ 
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
            }
        })
    }

    renderedCallback() {
        const overviewLink = this.template.querySelector('.nav-links a[data-name="overview"]');
        if (overviewLink) {
            overviewLink.classList.add('active-link');
        }
    }

    handleNav(event){ 
        this.currentPage = event.target.dataset.name;

        const links = this.template.querySelectorAll('.nav-links a');
        links.forEach(link => link.classList.remove('active-link'));
        event.target.classList.add('active-link');

        this.dispatchEvent(new CustomEvent('getpage', { detail: event.target.dataset.name}));
    }

    @api
    selectLink(event){ 
        const links = this.template.querySelectorAll('.nav-links a');
        links.forEach(link => link.classList.remove('active-link'));
        const overviewLink = this.template.querySelector(`.nav-links a[data-name="${event}"]`);
        if (overviewLink) {
            overviewLink.classList.add('active-link');
        }
    }

    handleHelpClick(){ 
        this.showHelpPopover = true;
    }
    closePopover(){ 
        this.showHelpPopover = false;
    }
}