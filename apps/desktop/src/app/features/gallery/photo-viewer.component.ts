import {
  Component,
  OnDestroy,
  inject,
  signal,
  computed,
  effect,
  HostListener,
  input,
  model,
  output,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { TooltipModule } from 'primeng/tooltip';
import { Photo } from '../../core/api/model/models';
import { SyncService } from '../../core/services/sync.service';

@Component({
  selector: 'app-photo-viewer',
  standalone: true,
  imports: [CommonModule, ButtonModule, TooltipModule],
  template: `
    @if (visible() && photos().length > 0) {
      <!-- Backdrop -->
      <div
        class="fixed inset-0 z-50 flex flex-col bg-black/95 backdrop-blur-sm"
        (click)="onBackdropClick($event)"
      >
        <!-- ── Top toolbar ── -->
        <div class="flex items-center justify-between px-4 py-3 bg-black/60 shrink-0 select-none">
          @let photo = currentPhoto();
          <!-- Left: file info -->
          <div class="flex flex-col min-w-0">
            <span class="text-white text-sm font-medium truncate">
              {{ photo.filename }}
            </span>
            <span class="text-slate-400 text-xs font-mono mt-0.5">
              {{ indexLabel() }}
              @if (photo.width && photo.height) {
                &nbsp;·&nbsp;{{ photo.width }}×{{ photo.height }}
              }
              @if (photo.size_bytes) {
                &nbsp;·&nbsp;{{ formatBytes(photo.size_bytes) }}
              }
              @if (photo.date_taken) {
                &nbsp;·&nbsp;{{ formatDate(photo.date_taken) }}
              }
            </span>
          </div>

          <!-- Right: actions -->
          <div class="flex items-center gap-1 shrink-0">
            @if (photo.gps) {
              <span class="text-[10px] px-2 py-0.5 rounded-full bg-emerald-800/60 text-emerald-300 flex items-center gap-1 mr-2">
                <i class="pi pi-map-marker text-[9px]"></i> GPS
              </span>
            }
            @if (photo.exif?.make) {
              <span class="text-[10px] px-2 py-0.5 rounded-full bg-slate-700/60 text-slate-300 mr-2">
                {{ photo.exif!.make }} {{ photo.exif!.model }}
              </span>
            }
            <p-button
              icon="pi pi-times"
              [text]="true"
              [rounded]="true"
              severity="secondary"
              pTooltip="Close (Esc)"
              (onClick)="close()"
              styleClass="text-white hover:bg-white/10"
            />
          </div>
        </div>

        <!-- ── Image area: Two-Stage Progressive Loading (Task 6.3.1) ── -->
        <div class="flex-1 flex items-center justify-center relative overflow-hidden min-h-0">
          <!-- Prev button -->
          @if (hasPrev()) {
            <button
              class="absolute left-4 z-20 w-11 h-11 rounded-full bg-black/50 hover:bg-black/80 border border-white/10 flex items-center justify-center text-white transition-all hover:scale-110 focus:outline-none"
              pTooltip="Previous (←)"
              (click)="prev(); $event.stopPropagation()"
            >
              <i class="pi pi-chevron-left text-lg"></i>
            </button>
          }

          <!-- Main progressive image display -->
          <div class="flex items-center justify-center w-full h-full px-16 py-4 relative">
            @let mainPhoto = currentPhoto();

            <!-- Stage 1: Instant 720px preview backdrop (0ms perceptual lag) -->
            <img
              [src]="previewUrl()"
              [alt]="mainPhoto.filename"
              class="max-w-full max-h-full object-contain rounded shadow-2xl transition-opacity duration-200 select-none"
              [class.opacity-60]="!fullLoaded()"
              [class.opacity-0]="fullLoaded()"
              draggable="false"
            />

            <!-- Stage 2: Full-resolution original loaded in background with smooth cross-fade -->
            <img
              [src]="fullUrl()"
              [alt]="mainPhoto.filename"
              class="absolute inset-0 m-auto max-w-full max-h-full object-contain rounded shadow-2xl transition-opacity duration-300 select-none"
              [class.opacity-0]="!fullLoaded()"
              [class.opacity-100]="fullLoaded()"
              (load)="fullLoaded.set(true)"
              (error)="onImageError($event)"
              draggable="false"
            />

            <!-- Subtle high-res loading status badge -->
            @if (!fullLoaded()) {
              <div class="absolute bottom-6 left-1/2 -translate-x-1/2 bg-black/70 backdrop-blur-md px-3 py-1 rounded-full text-xs text-slate-300 flex items-center gap-2 border border-white/10 shadow-lg pointer-events-none select-none z-10">
                <i class="pi pi-spin pi-spinner text-[10px] text-sky-400"></i>
                <span class="text-[11px] font-medium">Upgrading to full resolution…</span>
              </div>
            }
          </div>

          <!-- Next button -->
          @if (hasNext()) {
            <button
              class="absolute right-4 z-20 w-11 h-11 rounded-full bg-black/50 hover:bg-black/80 border border-white/10 flex items-center justify-center text-white transition-all hover:scale-110 focus:outline-none"
              pTooltip="Next (→)"
              (click)="next(); $event.stopPropagation()"
            >
              <i class="pi pi-chevron-right text-lg"></i>
            </button>
          }
        </div>

        <!-- ── Bottom strip: thumbnail filmstrip ── -->
        @if (photos().length > 1) {
          <div class="shrink-0 bg-black/60 py-2 px-4 overflow-x-auto">
            <div class="flex gap-2 justify-start items-center h-16">
              @for (photo of photos(); track photo.id; let i = $index) {
                <button
                  class="shrink-0 w-16 h-14 rounded overflow-hidden border-2 transition-all focus:outline-none"
                  [class.border-sky-400]="i === activeIndex()"
                  [class.border-transparent]="i !== activeIndex()"
                  [class.opacity-50]="i !== activeIndex()"
                  [class.hover:opacity-80]="i !== activeIndex()"
                  (click)="goTo(i); $event.stopPropagation()"
                >
                  <img
                    [src]="getThumbUrl(photo)"
                    [alt]="photo.filename"
                    class="w-full h-full object-cover"
                    loading="lazy"
                  />
                </button>
              }
            </div>
          </div>
        }
      </div>
    }
  `,
})
export class PhotoViewerComponent implements OnDestroy {
  private readonly sync = inject(SyncService);

  readonly photos = input<Photo[]>([]);
  readonly activeIndex = model<number>(0);
  readonly visible = model<boolean>(false);

  readonly photoSelect = output<Photo>();

  /** Task 6.3.1: Two-Stage Progressive Loading */
  readonly fullLoaded = signal<boolean>(false);

  readonly currentPhoto = computed(() => this.photos()[this.activeIndex()] ?? null);
  readonly hasPrev = computed(() => this.activeIndex() > 0);
  readonly hasNext = computed(() => this.activeIndex() < this.photos().length - 1);
  readonly indexLabel = computed(() =>
    this.photos().length > 0 ? `${this.activeIndex() + 1} / ${this.photos().length}` : ''
  );

  /** Instant 720px preview thumbnail backdrop (0ms perceptual lag) */
  readonly previewUrl = computed(() => {
    const p = this.currentPhoto();
    if (!p) return '';
    return this.sync.getImageUrl(p.id || p.relative_path, true, 720, 720);
  });

  /** Full-resolution original image */
  readonly fullUrl = computed(() => {
    const p = this.currentPhoto();
    if (!p) return '';
    return this.sync.getImageUrl(p.id || p.relative_path, false);
  });

  constructor() {
    // Reset fullLoaded state whenever active photo changes
    effect(() => {
      this.currentPhoto();
      this.fullLoaded.set(false);
    });
  }

  ngOnDestroy(): void {
    // nothing to clean up
  }

  // ── Keyboard navigation ────────────────────────────────────────────────────

  @HostListener('document:keydown', ['$event'])
  onKeydown(event: KeyboardEvent): void {
    if (!this.visible()) return;
    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault();
        this.prev();
        break;
      case 'ArrowRight':
        event.preventDefault();
        this.next();
        break;
      case 'Escape':
        event.preventDefault();
        this.close();
        break;
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  prev(): void {
    if (this.hasPrev()) {
      this.goTo(this.activeIndex() - 1);
    }
  }

  next(): void {
    if (this.hasNext()) {
      this.goTo(this.activeIndex() + 1);
    }
  }

  goTo(index: number): void {
    this.activeIndex.set(index);
    const photo = this.photos()[index];
    if (photo) {
      this.photoSelect.emit(photo);
    }
  }

  close(): void {
    this.visible.set(false);
  }

  onBackdropClick(event: MouseEvent): void {
    // Close only when clicking the backdrop itself (not the image or controls)
    if (event.target === event.currentTarget) {
      this.close();
    }
  }

  onImageError(event: Event): void {
    this.fullLoaded.set(true);
    const img = event.target as HTMLImageElement;
    img.src =
      'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400"><rect width="600" height="400" fill="%231e293b"/><text x="300" y="200" text-anchor="middle" fill="%2364748b" font-family="monospace" font-size="14">Image not available</text></svg>';
  }

  getThumbUrl(photo: Photo): string {
    return this.sync.getImageUrl(photo.id || photo.relative_path, true, 256, 256);
  }

  formatBytes(bytes: number): string {
    if (!bytes) return '';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  formatDate(dateStr: string): string {
    try {
      return new Date(dateStr).toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
    } catch {
      return dateStr;
    }
  }
}
