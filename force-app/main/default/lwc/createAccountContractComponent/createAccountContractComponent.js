import { LightningElement, api, track, wire} from 'lwc';
import getAccountClauses from '@salesforce/apex/AccountContractController.getAccountClauses';
import createAccountContract from '@salesforce/apex/AccountContractController.createAccountContract';
import createContractClauseFile from '@salesforce/apex/AccountContractController.createContractClauseFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateAccountContractComponent extends LightningElement {
    @api recordId; // Account Id
    @track contractClauses = [];
    @track isModalOpen = true;
    selectedClauseIds = new Set();
    isProceedDisabled = true;

    @wire(getAccountClauses, {recordId:'$recordId'})
    wiredClauses({error, data}){
        if (data){
            console.log('Data. --> '+JSON.stringify(data));
            this.contractClauses = data.map(clause =>({
                Id: clause.Id,
                Name: clause.Name
            }));
            if(data.length > 0){   
                this.billingCountry = data[0].Billing_Country__c;
            }  
        } else if(error){
            console.error('Error fetching clauses:', error);
        }
    }

    handleCheckboxChange(event){
        const clauseId = event.target.dataset.id;
        if (event.target.checked){
            this.selectedClauseIds.add(clauseId);
        } else{
            this.selectedClauseIds.delete(clauseId);
        }
        this.isProceedDisabled = this.selectedClauseIds.size === 0;
    }

    handleProceed(){
        if (this.selectedClauseIds.size === 0){
            this.showToast('Warning', 'Please select at least one clause.', 'warning');
            return;
        }

        const clauseIds = Array.from(this.selectedClauseIds);
        const clauseNames = this.contractClauses
            .filter(clause => clauseIds.includes(clause.Id))
            .map(clause => clause.Name);

        createAccountContract({ accountId: this.recordId, clauseIds })
            .then(contractId => {
                return createContractClauseFile({ contractId, clauseNames });
            })
            .then(() =>{
                this.showToast('Success', 'Account Contract created successfully!', 'success');
                this.closeModal(); // Close modal after success
            })
            .catch(error =>{
                this.showToast('Error', 'Error creating contract: ' + error.body.message, 'error');
            });
    }

    handleCancel(){
        this.closeModal(); // Close modal on cancel
    }

    closeModal(){
        this.isModalOpen = false; // Hides the modal
        this.dispatchEvent(new CloseActionScreenEvent()); // Closes Quick Action if applicable
    }

    showToast(title, message, variant){
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}