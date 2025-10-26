import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createContact from '@salesforce/apex/ContactController.createContact';

export default class ContactInsert extends LightningElement {
    @api recordId;

    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    isLoading = false;

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handlePhoneChange(event) {
        this.phone = event.target.value;
    }

    get saveButtonLabel() {
        return this.isLoading ? 'Saving...' : 'Save Contact';
    }

    async handleSave() {
        try {
            // Add loading state
            this.isLoading = true;
            
            const contactData = {
                firstName: this.firstName,
                lastName: this.lastName,
                email: this.email,
                phone: this.phone
            };

            // Call the Apex method to create the contact
            const result = await createContact({ contactData });
            
            // Show success toast
            const toastEvent = new ShowToastEvent({
                title: 'Success',
                message: 'Contact created successfully!',
                variant: 'success'
            });
            this.dispatchEvent(toastEvent);

            // Add animation class for success
            const container = this.template.querySelector('.slds-box');
            if (container) {
                container.classList.add('success-animation');
                setTimeout(() => {
                    container.classList.remove('success-animation');
                }, 500);
            }

            // Reset form fields
            this.firstName = '';
            this.lastName = '';
            this.email = '';
            this.phone = '';

        } catch (error) {
            // Show error toast
            const toastEvent = new ShowToastEvent({
                title: 'Error',
                message: error.body.message || 'An error occurred while creating the contact.',
                variant: 'error'
            });
            this.dispatchEvent(toastEvent);
        } finally {
            // Remove loading state
            this.isLoading = false;
        }
    }

    handleReset() {
        this.firstName = '';
        this.lastName = '';
        this.email = '';
        this.phone = '';
    }
}
