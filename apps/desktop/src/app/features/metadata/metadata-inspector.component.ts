import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TagModule } from 'primeng/tag';
import { RatingModule } from 'primeng/rating';
import { ButtonModule } from 'primeng/button';
import { TauriService } from '../../core/services/tauri.service';
import { SyncService } from '../../core/services/sync.service';

@Component({
  selector: 'app-metadata-inspector',
  standalone: true,
  imports: [CommonModule, FormsModule, TagModule, RatingModule, ButtonModule],
  template: `
    <div class="h-full flex flex-col bg-slate-100/60 dark:bg-slate-900/50 border-l border-slate-200 dark:border-slate-800 text-slate-800 dark:text-slate-200 select-none transition-colors duration-200">
      <!-- Panel Header -->
      <div class="p-3 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between">
        <span class="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">Metadata Inspector</span>
        @if (tauri.selectedPhoto(); as photo) {
          <p-button
            icon="pi pi-times"
            [rounded]="true"
            [text]="true"
            size="small"
            (onClick)="close()"
          />
        }
      </div>

      <!-- Content Area -->
      <div class="flex-1 overflow-y-auto p-4">
        @if (tauri.selectedPhoto(); as photo) {
          <div class="flex flex-col gap-4">
            <!-- Thumbnail & Dimension Preview -->
            <div class="rounded-lg overflow-hidden border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 flex flex-col items-center shadow-sm">
              <div class="aspect-video w-full relative bg-slate-100 dark:bg-slate-900 flex items-center justify-center overflow-hidden">
                <img
                  [src]="getImageUrl(photo)"
                  [alt]="photo.filename"
                  class="w-full h-full object-contain"
                  (error)="onImageError($event)"
                />
              </div>
              <div class="p-2 w-full bg-slate-50 dark:bg-slate-900/60 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between text-[11px] font-mono text-slate-500 dark:text-slate-400">
                <span>{{ photo.width || '?' }} × {{ photo.height || '?' }} px</span>
                <span>{{ formatBytes(photo.size_bytes) }}</span>
              </div>
            </div>

            <!-- Basic File Info -->
            <div class="flex flex-col gap-1.5">
              <span class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">File</span>
              <div class="bg-white dark:bg-slate-950/60 p-2.5 rounded-lg border border-slate-200 dark:border-slate-800/80 flex flex-col gap-1 text-xs shadow-sm">
                <div class="flex justify-between">
                  <span class="text-slate-400 dark:text-slate-500">Name:</span>
                  <span class="font-medium text-slate-800 dark:text-slate-200 truncate ml-2" [title]="photo.filename">{{ photo.filename }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-400 dark:text-slate-500">Path:</span>
                  <span class="text-slate-600 dark:text-slate-400 truncate ml-2 font-mono text-[11px]" [title]="photo.relative_path">{{ photo.relative_path }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-400 dark:text-slate-500">MIME:</span>
                  <span class="text-slate-700 dark:text-slate-300 font-mono text-[11px]">{{ photo.mime_type }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-400 dark:text-slate-500">Rating:</span>
                  <p-rating [(ngModel)]="photo.rating" [stars]="5" [readonly]="true" styleClass="text-amber-400 scale-75 origin-right" />
                </div>
              </div>
            </div>

            <!-- Photographic EXIF -->
            @if (photo.exif) {
              <div class="flex flex-col gap-1.5">
                <span class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Camera & Optics</span>
                <div class="bg-white dark:bg-slate-950/60 p-2.5 rounded-lg border border-slate-200 dark:border-slate-800/80 flex flex-col gap-1.5 text-xs shadow-sm">
                  @if (photo.exif.make || photo.exif.model) {
                    <div class="flex justify-between">
                      <span class="text-slate-400 dark:text-slate-500">Camera:</span>
                      <span class="text-slate-800 dark:text-slate-200 font-medium">{{ photo.exif.make }} {{ photo.exif.model }}</span>
                    </div>
                  }
                  @if (photo.exif.lens) {
                    <div class="flex justify-between">
                      <span class="text-slate-400 dark:text-slate-500">Lens:</span>
                      <span class="text-slate-700 dark:text-slate-300 truncate ml-2 text-[11px]">{{ photo.exif.lens }}</span>
                    </div>
                  }
                  <div class="grid grid-cols-2 gap-2 pt-1 border-t border-slate-200 dark:border-slate-800/60 text-[11px] font-mono text-slate-700 dark:text-slate-300">
                    <div><span class="text-slate-400 dark:text-slate-500">Focal:</span> {{ photo.exif.focal_length ? photo.exif.focal_length + 'mm' : '-' }}</div>
                    <div><span class="text-slate-400 dark:text-slate-500">Aperture:</span> {{ photo.exif.f_number ? 'f/' + photo.exif.f_number : '-' }}</div>
                    <div><span class="text-slate-400 dark:text-slate-500">Shutter:</span> {{ photo.exif.exposure_time || '-' }}</div>
                    <div><span class="text-slate-400 dark:text-slate-500">ISO:</span> {{ photo.exif.iso || '-' }}</div>
                  </div>
                </div>
              </div>
            }

            <!-- GPS Location -->
            @if (photo.gps) {
              <div class="flex flex-col gap-1.5">
                <span class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Geolocation</span>
                <div class="bg-white dark:bg-slate-950/60 p-2.5 rounded-lg border border-slate-200 dark:border-slate-800/80 flex flex-col gap-1 text-xs font-mono shadow-sm">
                  <div class="flex justify-between">
                    <span class="text-slate-400 dark:text-slate-500">Latitude:</span>
                    <span class="text-emerald-600 dark:text-emerald-400">{{ photo.gps.latitude.toFixed(6) }}</span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-slate-400 dark:text-slate-500">Longitude:</span>
                    <span class="text-emerald-600 dark:text-emerald-400">{{ photo.gps.longitude.toFixed(6) }}</span>
                  </div>
                  @if (photo.gps.altitude) {
                    <div class="flex justify-between">
                      <span class="text-slate-400 dark:text-slate-500">Altitude:</span>
                      <span class="text-slate-700 dark:text-slate-300">{{ photo.gps.altitude.toFixed(1) }} m</span>
                    </div>
                  }
                </div>
              </div>
            }

            <!-- Detected Faces / YOLO AI -->
            @if (photo.faces && photo.faces.length > 0) {
              <div class="flex flex-col gap-1.5">
                <span class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Face Detections ({{ photo.faces.length }})</span>
                <div class="flex flex-col gap-1.5">
                  @for (face of photo.faces; track face.id) {
                    <div class="bg-white dark:bg-slate-950/60 p-2 rounded border border-indigo-200 dark:border-indigo-900/40 flex items-center justify-between text-xs shadow-sm">
                      <div class="flex items-center gap-2">
                        <i class="pi pi-user text-indigo-500 dark:text-indigo-400 text-xs"></i>
                        <span class="font-medium text-slate-800 dark:text-slate-200">{{ face.person_name || 'Unassigned Person' }}</span>
                      </div>
                      <div class="flex items-center gap-1 text-[10px] font-mono text-indigo-700 dark:text-indigo-300 bg-indigo-50 dark:bg-indigo-950/80 px-1.5 py-0.5 rounded">
                        <span>{{ (face.confidence ? face.confidence * 100 : 95).toFixed(0) }}%</span>
                      </div>
                    </div>
                  }
                </div>
              </div>
            }
          </div>
        } @else {
          <!-- Empty State -->
          <div class="h-full flex flex-col items-center justify-center text-slate-400 dark:text-slate-600 gap-2 py-20">
            <i class="pi pi-info-circle text-3xl"></i>
            <p class="text-xs">Select a photo to view metadata</p>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    :host {
      display: block;
      height: 100%;
    }
  `],
})
export class MetadataInspectorComponent {
  readonly tauri = inject(TauriService);
  readonly sync = inject(SyncService);

  close(): void {
    this.tauri.selectPhoto(null);
  }

  getImageUrl(photo: any): string {
    return this.sync.getImageUrl(photo.id || photo.relative_path, false);
  }

  onImageError(event: Event): void {
    const img = event.target as HTMLImageElement;
    img.src = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="300" height="200" viewBox="0 0 300 200"><rect width="300" height="200" fill="%231e293b"/><text x="150" y="105" fill="%2364748b" font-family="sans-serif" font-size="12" text-anchor="middle">Preview Unavailable</text></svg>';
  }

  formatBytes(bytes: number): string {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }
}
