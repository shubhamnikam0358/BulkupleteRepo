import { LightningElement, api } from 'lwc';

export default class FilterBuilder extends LightningElement {
    @api objectApiName;
    filterValue = '';

    handleChange(event) {
        this.filterValue = event.target.value;
        this.dispatchEvent(new CustomEvent('filterchange', {
            detail: { filterClause: this.filterValue }
        }));
    }
}