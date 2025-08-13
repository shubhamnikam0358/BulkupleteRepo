import { LightningElement, api, wire, track } from 'lwc';
import deleteRecords from '@salesforce/apex/BulkUpdaterController.deleteRecords';
import queryRecords from '@salesforce/apex/BulkUpdaterController.queryRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RecordTable extends LightningElement {
    @api objectApiName;
    @api fieldName;
    @api filterClause;
    @api selectedRecordIds = [];

    @track records = [];
    columns = [
        { label: 'Id', fieldName: 'Id' },
        { label: 'Name', fieldName: 'Name' }
    ];

    @wire(queryRecords, { objectApiName: '$objectApiName', fieldName: '$fieldName', filterClause: '$filterClause' })
    wiredRecords({ error, data }) {
        if (data) {
            this.records = data;
        } else if (error) {
            console.error('Error loading records', error);
            this.showToast('Error', 'Failed to load records', 'error');
        }
    }

    handleRowSelection(event) {
        this.selectedRecordIds = event.detail.selectedRows.map(row => row.Id);
        this.dispatchEvent(new CustomEvent('recordselect', {
            detail: { recordIds: this.selectedRecordIds }
        }));
    }

    handleDelete() {
        if (!this.selectedRecordIds || this.selectedRecordIds.length === 0) {
            this.showToast('Warning', 'No records selected for deletion.', 'warning');
            return;
        }

        deleteRecords({
            objectApiName: this.objectApiName,
            recordIds: this.selectedRecordIds
        })
        .then(result => {
            this.showToast('Success', result, 'success');
            this.selectedRecordIds = []; // clear selection list
            return this.refreshTable();
        })
        .catch(error => {
            console.error(error);
            this.showToast('Error', 'Failed to delete records', 'error');
        });
    }

    async refreshTable() {
        try {
            const refreshedData = await queryRecords({
                objectApiName: this.objectApiName,
                fieldName: this.fieldName,
                filterClause: this.filterClause
            });
            this.records = refreshedData;
        } catch (err) {
            console.error(err);
            this.showToast('Error', 'Failed to refresh records after deletion', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            })
        );
    }
}