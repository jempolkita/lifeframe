import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DialogModule } from 'primeng/dialog';
import { ButtonModule } from 'primeng/button';
import { TooltipModule } from 'primeng/tooltip';
import { TagModule } from 'primeng/tag';
import { TauriService } from '../../core/services/tauri.service';

@Component({
  selector: 'app-settings-dialog',
  standalone: true,
  imports: [CommonModule, DialogModule, ButtonModule, TooltipModule, TagModule],
  template: `
    <p-dialog
      [(visible)]="visible"
      [modal]="true"
      [draggable]="false"
      [resizable]="false"
      [style]="{ width: '580px' }"
      header="Settings"
      styleClass="lifeframe-settings-dialog"
    >
      <!-- ── Collections / Libraries ── -->
      <div class="flex flex-col gap-6 py-2">
        <section>
          <div class="flex items-center justify-between mb-3">
            <div>
              <h3 class="text-sm font-semibold text-slate-800 dark:text-slate-100">
                Collections &amp; Libraries
              </h3>
              <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                Select the folders that Lifeframe should manage as your photo collections.
              </p>
            </div>
            <p-button
              icon="pi pi-folder-plus"
              label="Add Folder"
              size="small"
              severity="primary"
              [loading]="isAdding()"
              (onClick)="addLibrary()"
              styleClass="text-xs"
            />
          </div>

          <!-- Library list -->
          @if (tauri.libraryPaths().length === 0) {
            <div class="flex flex-col items-center justify-center py-10 rounded-lg border-2 border-dashed border-slate-200 dark:border-slate-700 gap-3">
              <i class="pi pi-folder-open text-3xl text-slate-300 dark:text-slate-600"></i>
              <p class="text-sm text-slate-400 dark:text-slate-500 text-center">
                No libraries added yet.<br>Click <strong>Add Folder</strong> to get started.
              </p>
            </div>
          } @else {
            <ul class="flex flex-col gap-2">
              @for (path of tauri.libraryPaths(); track path) {
                <li class="flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 group">
                  <div class="flex items-center gap-2.5 min-w-0">
                    <i class="pi pi-folder text-sky-500 text-sm shrink-0"></i>
                    <span
                      class="text-xs font-mono text-slate-700 dark:text-slate-200 truncate"
                      [pTooltip]="path"
                      tooltipPosition="top"
                    >{{ path }}</span>
                  </div>
                  <p-button
                    icon="pi pi-trash"
                    [text]="true"
                    [rounded]="true"
                    size="small"
                    severity="danger"
                    pTooltip="Remove library"
                    [loading]="removingPath === path"
                    (onClick)="removeLibrary(path)"
                    styleClass="opacity-0 group-hover:opacity-100 transition-opacity"
                  />
                </li>
              }
            </ul>
          }
        </section>

        <!-- Scan hint -->
        @if (tauri.libraryPaths().length > 0) {
          <div class="flex items-start gap-2 px-3 py-2.5 rounded-lg bg-sky-50 dark:bg-sky-950/30 border border-sky-200 dark:border-sky-800">
            <i class="pi pi-info-circle text-sky-500 text-sm mt-0.5 shrink-0"></i>
            <p class="text-xs text-sky-700 dark:text-sky-300 leading-relaxed">
              After adding or removing libraries, use <strong>Refresh Library</strong> in the sidebar to re-scan and update your photo collection.
            </p>
          </div>
        }
      </div>

      <ng-template pTemplate="footer">
        <div class="flex justify-end pt-2">
          <p-button
            label="Close"
            severity="secondary"
            size="small"
            (onClick)="close()"
          />
        </div>
      </ng-template>
    </p-dialog>
  `,
})
export class SettingsDialogComponent {
  readonly tauri = inject(TauriService);

  visible = false;
  isAdding = signal(false);
  removingPath: string | null = null;

  open(): void {
    this.visible = true;
  }

  close(): void {
    this.visible = false;
  }

  async addLibrary(): Promise<void> {
    this.isAdding.set(true);
    try {
      await this.tauri.addLibraryPath();
    } finally {
      this.isAdding.set(false);
    }
  }

  async removeLibrary(path: string): Promise<void> {
    this.removingPath = path;
    try {
      await this.tauri.removeLibraryPath(path);
    } finally {
      this.removingPath = null;
    }
  }
}
