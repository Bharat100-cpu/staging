import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import executePython from '@salesforce/apex/PythonExecutorController.executePython';

export default class PythonExecutor extends LightningElement {
    @api recordId;

    pythonCode = '';
    executionResult = '';
    isLoading = false;

    handleCodeChange(event) {
        this.pythonCode = event.target.value;
    }

    async handleExecute() {
        if (!this.pythonCode.trim()) {
            this.showToast('Error', 'Please enter Python code to execute', 'error');
            return;
        }

        try {
            this.isLoading = true;
            this.executionResult = '';

            // Call the Apex method to execute Python code
            const result = await executePython({ code: this.pythonCode });
            
            this.executionResult = result;
            
            this.showToast('Success', 'Python code executed successfully', 'success');

        } catch (error) {
            this.showToast('Error', error.body.message || 'Failed to execute Python code', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    handleClear() {
        this.pythonCode = '';
        this.executionResult = '';
    }
}
