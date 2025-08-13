import { LightningElement } from 'lwc';

export default class BulkUpdaterApp extends LightningElement {
    selectedObject;
    fieldName = 'Name';
    filterClause = 'Name != null';
    selectedRecordIds = [];

    handleObjectSelect(event) {
        this.selectedObject = event.detail.objectApiName;
    }

    handleFilterApply(event) {
        this.fieldName = event.detail.fieldName;
        this.filterClause = event.detail.filterClause;
    }

    handleRecordSelect(event) {
        this.selectedRecordIds = event.detail.recordIds;
    }
}