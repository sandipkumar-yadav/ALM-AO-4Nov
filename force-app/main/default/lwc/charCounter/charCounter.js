import { LightningElement, api } from 'lwc';

export default class CharCounter extends LightningElement {
    @api label = 'Notes';
    @api maxLength = 100;

    length = 0;
    announcement = '';

    get isOver() {
        return this.length > this.maxLength;
    }

    get countClass() {
        return this.isOver ? 'count over' : 'count';
    }

    handleInput(event) {
        this.length = event.target.value.length;
        const diff = this.maxLength - this.length;
        this.announcement =
            diff < 0
                ? `${-diff} characters over the limit`
                : `${diff} characters remaining`;
    }
}
