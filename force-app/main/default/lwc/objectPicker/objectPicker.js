import { LightningElement, wire } from 'lwc';
import getObjectList from '@salesforce/apex/BulkUpdaterController.getObjectList';

export default class ObjectPicker extends LightningElement {
    objectOptions = [];
    selectedObject = '';

    @wire(getObjectList)
    wiredObjects({ error, data }) {
        if (data) {
            this.objectOptions = data.map(objName => ({
                label: objName,
                value: objName
            }));
        }
    }

    handleChange(event) {
        this.selectedObject = event.detail.value;
        this.dispatchEvent(new CustomEvent('objectselect', {
            detail: { objectApiName: this.selectedObject }
        }));
    }
}