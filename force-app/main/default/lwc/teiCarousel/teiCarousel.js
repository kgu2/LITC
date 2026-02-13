import { LightningElement, api, track } from 'lwc';

export default class TeiCarousel extends LightningElement {
  /*** Public API ***/
  @api ariaLabel = 'Featured images';
  @api autoMs = 6000;            // autoplay interval (ms); set 0 to disable
  @api aspectRatio = '16 / 9';   // e.g. '4 / 3'
  @api images = [];              // [{ src, alt, caption }]

  // Boolean @api must initialize to false (per LWC rules)
  @api showArrows = false;
  @api showDots = false;
  @api loop = false;
  @api pauseOnHover = false;

  /*** Derived "default-true" getters ***/
  get hasArrows() { return this.showArrows !== false; }
  get hasDots() { return this.showDots !== false; }
  get hasLoop() { return this.loop !== false; }
  get hasPauseOnHover() { return this.pauseOnHover !== false; }

  /*** Inline style for aspect ratio ***/
  get viewportStyle() { return `--aspect:${this.aspectRatio}`; }

  get trackStyle() {
    return `--index:${this.index}`;
  }

  /*** State ***/
  @track index = 0;
  _timer;
  _touchX = null;

  /*** Lifecycle ***/
  connectedCallback() { this._startAuto(); }
  disconnectedCallback() { this._stopAuto(); }

  /*** Template mapping with active state ***/
  get _images() {
    const len = this.images?.length || 0;
    return (this.images || []).map((img, i) => ({
      ...img,
      containerClass: 'carousel-slide ' + (i === this.index ? 'is-active' : 'is-inactive'),
      slideAria: `Slide ${i + 1} of ${len}`,
      dotClass: 'carousel-dot ' + (i === this.index ? 'is-active' : ''),
      dotAria: `Go to slide ${i + 1}`,
      active: i === this.index
    }));
  }

  /*** Public controls ***/
  @api next = () => {
    const len = this.images?.length || 0;
    if (!len) return;
    const last = len - 1;
    this.index = this.index >= last ? (this.hasLoop ? 0 : last) : this.index + 1;
  };
  @api prev = () => {
    const len = this.images?.length || 0;
    if (!len) return;
    const last = len - 1;
    this.index = this.index <= 0 ? (this.hasLoop ? last : 0) : this.index - 1;
  };
  @api goTo = (evtOrIndex) => {
    const len = this.images?.length || 0;
    if (!len) return;
    const idx = typeof evtOrIndex === 'number'
      ? evtOrIndex
      : Number(evtOrIndex.currentTarget?.dataset?.index);
    if (!Number.isNaN(idx) && idx >= 0 && idx < len) this.index = idx;
  };

  /*** Autoplay ***/
  _startAuto() {
    this._stopAuto();
    if (this.autoMs > 0 && (this.images?.length || 0) > 1) {
      this._timer = window.setInterval(() => this.next(), this.autoMs);
    }
  }
  _stopAuto() {
    if (this._timer) {
      window.clearInterval(this._timer);
      this._timer = undefined;
    }
  }
  _toggleAuto() { this._timer ? this._stopAuto() : this._startAuto(); }

  /*** Interactions ***/
  handleKey = (e) => {
    if (e.key === 'ArrowRight') { e.preventDefault(); this.next(); }
    else if (e.key === 'ArrowLeft') { e.preventDefault(); this.prev(); }
    else if (e.key === ' ' || e.key === 'Spacebar') { e.preventDefault(); this._toggleAuto(); }
  };

  handleHoverIn = () => { if (this.hasPauseOnHover) this._stopAuto(); };
  handleHoverOut = () => { if (this.hasPauseOnHover) this._startAuto(); };

  onTouchStart = (e) => { this._touchX = e.changedTouches[0].clientX; };
  onTouchEnd = (e) => {
    if (this._touchX == null) return;
    const dx = e.changedTouches[0].clientX - this._touchX;
    const threshold = 40;
    if (dx > threshold) this.prev();
    else if (dx < -threshold) this.next();
    this._touchX = null;
  };
}