import { LightningElement, api } from 'lwc';
import updateRecords from '@salesforce/apex/BulkUpdaterController.updateRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FieldUpdater extends LightningElement {
    @api objectApiName;
    @api recordIds;
    fieldName = '';
    fieldValue = '';

    handleFieldChange(event) {
        this.fieldName = event.target.value;
    }

    handleValueChange(event) {
        this.fieldValue = event.target.value;
    }

    update() {
        if (!this.recordIds || this.recordIds.length === 0) {
            this.showToast('Error', 'No records selected', 'error');
            return;
        }

        updateRecords({
            objectApiName: this.objectApiName,
            fieldName: this.fieldName,
            fieldValue: this.fieldValue,
            recordIds: this.recordIds
        })
        .then(result => {
            this.showToast('Success', result, 'success');
        })
        .catch(error => {
            this.showToast('Error', 'Failed to update records: ' + this.parseError(error), 'error');
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }

    parseError(error) {
        return error?.body?.message || error?.message || JSON.stringify(error);
    }
}