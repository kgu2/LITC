import { LightningElement, api } from 'lwc';
import saveFile from '@salesforce/apex/LWCUploadController.saveFile';

export default class SignatureCapture extends LightningElement {
    @api recordId; // Record ID to associate the file with
    isModalOpen = false; // Modal visibility
    canvas;
    ctx;
    isDrawing = false;

    manual;



    @api openModal() {
        this.isModalOpen = true;

        setTimeout(() => {
            this.initializeCanvas();
        }, 0);
    }

    closeModal() {
        this.isModalOpen = false;
    }

    initializeCanvas() {
        this.canvas = this.template.querySelector('.signature-pad');
        if (this.canvas) {
            this.ctx = this.canvas.getContext('2d');
            this.canvas.width = 400; // Fixed canvas width
            this.canvas.height = 200; // Fixed canvas height
            this.ctx.strokeStyle = 'black';
            this.ctx.lineWidth = 2;
        }
    }

    startDrawing(event) {
        if (!this.ctx) return;
        this.isDrawing = true;
        const rect = this.canvas.getBoundingClientRect();
        const scaleX = this.canvas.width / rect.width;
        const scaleY = this.canvas.height / rect.height;
    
        this.ctx.beginPath();
        this.ctx.moveTo((event.clientX - rect.left) * scaleX, (event.clientY - rect.top) * scaleY);
    }
    
    draw(event) {
        if (!this.isDrawing || !this.ctx) return;
        const rect = this.canvas.getBoundingClientRect();
        const scaleX = this.canvas.width / rect.width;
        const scaleY = this.canvas.height / rect.height;
    
        this.ctx.lineTo((event.clientX - rect.left) * scaleX, (event.clientY - rect.top) * scaleY);
        this.ctx.stroke();
    }
    
    stopDrawing() {
        if (!this.ctx) return;
        this.isDrawing = false;
        this.ctx.closePath();
    }

    clearSignature() {
        if (this.ctx) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    }

    changeType(){ 
        this.manual = !this.manual;

        if(!this.manual){ 
            setTimeout(() => {
                this.initializeCanvas();
            }, 0);
        }
    }

    async saveSignature() {
        try {
            const dataUrl = this.canvas.toDataURL('image/png');
            const base64Data = dataUrl.split(',')[1];

            await saveFile({ recordId: this.recordId, base64Data, fileName: 'Signature.png' }).catch(error=>{console.log(error)})
            this.dispatchEvent(new CustomEvent('success', { detail: 'Signature saved successfully!' }));
            this.closeModal(); // Close the modal after saving
        } catch (error) {
            this.dispatchEvent(new CustomEvent('error', { detail: error.body.message }));
        }
    }


    get label(){ 
        return this.manual ? 'Draw signature' : 'Type signature';
    }
}