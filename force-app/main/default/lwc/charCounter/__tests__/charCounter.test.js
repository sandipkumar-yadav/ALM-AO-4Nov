import { createElement } from 'lwc';
import CharCounter from 'c/charCounter';

const setup = (props = {}) => {
    const el = createElement('c-char-counter', { is: CharCounter });
    Object.assign(el, props);
    document.body.appendChild(el);
    return el;
};

const type = async (el, value) => {
    const ta = el.shadowRoot.querySelector('textarea');
    ta.value = value;
    ta.dispatchEvent(new CustomEvent('input'));
    await Promise.resolve();
};

describe('c-char-counter', () => {
    afterEach(() => {
        while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
    });

    it('renders label and initial count', () => {
        const el = setup({ label: 'Bio', maxLength: 10 });
        expect(el.shadowRoot.querySelector('label').textContent).toBe('Bio');
        expect(el.shadowRoot.querySelector('.count-text').textContent).toBe('0 / 10');
    });

    it('updates count and announces remaining', async () => {
        const el = setup({ maxLength: 10 });
        await type(el, 'abc');
        expect(el.shadowRoot.querySelector('.count-text').textContent).toBe('3 / 10');
        expect(el.shadowRoot.querySelector('[role="status"]').textContent).toBe('7 characters remaining');
    });

    it('shows over-limit state', async () => {
        const el = setup({ maxLength: 2 });
        await type(el, 'abcd');
        expect(el.shadowRoot.querySelector('.count.over')).not.toBeNull();
        expect(el.shadowRoot.querySelector('textarea').getAttribute('aria-invalid')).toBe('true');
        expect(el.shadowRoot.querySelector('[role="status"]').textContent).toBe('2 characters over the limit');
    });
});
