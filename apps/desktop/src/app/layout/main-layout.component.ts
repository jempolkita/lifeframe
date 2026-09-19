import { Component, inject, signal, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { InputTextModule } from 'primeng/inputtext';
import { ButtonModule } from 'primeng/button';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { FolderTreeComponent } from '../features/sidebar/folder-tree.component';
import { PhotoGridComponent } from '../features/gallery/photo-grid.component';
import { MetadataInspectorComponent } from '../features/metadata/metadata-inspector.component';
import { SettingsDialogComponent } from '../features/settings/settings-dialog.component';
import { StatusBarComponent } from './status-bar.component';
import { TauriService } from '../core/services/tauri.service';
import { SyncService } from '../core/services/sync.service';
import { ThemeService } from '../core/services/theme.service';
import { SelectModule } from 'primeng/select';
import { IconField } from 'primeng/iconfield';
import { InputIcon } from 'primeng/inputicon';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    InputTextModule,
    ButtonModule,
    TagModule,
    TooltipModule,
    FolderTreeComponent,
    PhotoGridComponent,
    MetadataInspectorComponent,
    SettingsDialogComponent,
    StatusBarComponent,
    SelectModule,
    IconField,
    InputIcon,
  ],
  template: `
    <div class="h-full w-full flex flex-col bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 font-sans transition-colors duration-200">
      <!-- Main Application Header Bar -->
      <header class="h-14 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between px-4 z-20 select-none transition-colors duration-200">
        <!-- Brand / Logo -->
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-gradient-to-tr from-sky-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-sky-500/20">
            <i class="pi pi-camera text-white text-base"></i>
          </div>
          <div>
            <h1 class="text-sm font-bold tracking-tight text-slate-900 dark:text-white leading-tight">Lifeframe</h1>
            <p class="text-[10px] text-slate-500 dark:text-slate-400 font-mono">Local &amp; LAN Sync</p>
          </div>
        </div>

        <!-- Search & Filter Controls -->
        <div class="flex-1 max-w-2xl mx-4 flex items-center gap-2">
          <!-- Search Bar -->
          <div class="flex-1 min-w-[200px]">
            <p-iconfield iconPosition="left">
              <p-inputicon class="pi pi-search text-xs" />
              <input 
                type="text" 
                pInputText 
                placeholder="Search photos, tags, path..."
                [(ngModel)]="search"
                (ngModelChange)="onSearchChange($event)"
                fluid
                pSize="small"
                class="text-xs"
              />
            </p-iconfield>
          </div>
          
          <!-- Sort Field -->
          <p-select 
            [options]="sortOptions" 
            [(ngModel)]="selectedSort" 
            (ngModelChange)="onSortChange($event)"
            optionLabel="label" 
            optionValue="value"
            placeholder="Sort by" 
            size="small"
            styleClass="text-xs w-32"
          />

          <!-- Order Direction Toggle Button -->
          <p-button
            [icon]="selectedOrder() === 'asc' ? 'pi pi-sort-amount-up-alt' : 'pi pi-sort-amount-down'"
            [pTooltip]="selectedOrder() === 'asc' ? 'Ascending (click to change)' : 'Descending (click to change)'"
            tooltipPosition="bottom"
            severity="secondary"
            [outlined]="true"
            size="small"
            (onClick)="toggleOrder()"
            styleClass="text-xs shrink-0"
          />
        </div>

        <!-- Status & Actions -->
        <div class="flex items-center gap-2">
          <!-- Server Status Pill -->
          @if (tauri.serverStatus()?.is_running) {
            <div class="hidden sm:flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 text-xs font-mono">
              <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <span class="text-slate-700 dark:text-slate-300">{{ tauri.serverStatus()?.local_ip }}:{{ tauri.serverStatus()?.port }}</span>
              <span class="text-[10px] bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-400 px-1 rounded">mDNS</span>
            </div>
          } @else {
            <div class="hidden sm:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-100 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 text-xs text-rose-500 font-mono">
              <span class="w-2 h-2 rounded-full bg-rose-500"></span>
              <span>Offline</span>
            </div>
          }

          <!-- Sync Manifest Button -->
          <p-button
            icon="pi pi-sync"
            label="Sync"
            size="small"
            severity="secondary"
            [loading]="sync.isSyncing()"
            (onClick)="triggerSync()"
            styleClass="text-xs hidden md:inline-flex"
          />

          <!-- Theme Toggle Button -->
          <p-button [icon]="getThemeIcon()" [rounded]="true" [text]="true" severity="secondary" (onClick)="theme.toggleTheme()" [pTooltip]="'Theme: ' + theme.themeMode()" tooltipPosition="bottom"/>

          <!-- Settings Button -->
          <p-button icon="pi pi-cog" [rounded]="true" [text]="true" severity="info" (onClick)="settingsDialog.open()" pTooltip="Settings" tooltipPosition="bottom"/>

          <!-- Toggle Right Inspector Button -->
          <p-button [icon]="'pi pi-sidebar'" [rounded]="true" [text]="true" severity="secondary" (onClick)="showInspector.set(!showInspector())" [pTooltip]="showInspector() ? 'Hide Inspector' : 'Show Inspector'" tooltipPosition="bottom"/>
        </div>
      </header>

      <!-- 3-Panel Layout Container -->
      <div class="flex-1 flex overflow-hidden">
        <!-- Left Panel: Folder / Album Tree (260px) -->
        <app-folder-tree class="w-64 shrink-0" />

        <!-- Center Panel: Photo Grid (Flex 1) -->
        <app-photo-grid class="flex-1 min-w-0" />

        <!-- Right Panel: Metadata & EXIF Inspector (320px) -->
        @if (showInspector()) {
          <app-metadata-inspector class="w-80 shrink-0" />
        }
      </div>

      <!-- Footer: IDE-style status bar with scan progress -->
      <app-status-bar />

      <!-- Settings Dialog (rendered globally so it overlays everything) -->
      <app-settings-dialog #settingsDialog />
    </div>
  `,
  styles: [`
    :host {
      display: flex;
      flex-direction: column;
      height: 100%;
      width: 100%;
    }
  `],
})
export class MainLayoutComponent {
  @ViewChild('settingsDialog') settingsDialog!: SettingsDialogComponent;

  readonly tauri = inject(TauriService);
  readonly sync = inject(SyncService);
  readonly theme = inject(ThemeService);

  readonly showInspector = signal<boolean>(true);
  search = '';

  readonly sortOptions = [
    { label: 'Name', value: 'name' },
    { label: 'Date Taken', value: 'date' },
    { label: 'File Size', value: 'size' },
  ];

  selectedSort = 'name';
  readonly selectedOrder = signal<'asc' | 'desc'>('asc');

  getThemeIcon(): string {
    const mode = this.theme.themeMode();
    if (mode === 'dark') return 'pi pi-moon';
    if (mode === 'light') return 'pi pi-sun';
    return 'pi pi-desktop';
  }

  onSearchChange(value: string): void {
    this.tauri.setSearchQuery(value);
  }

  onSortChange(value: string): void {
    this.tauri.setSort(value);
  }

  toggleOrder(): void {
    const nextOrder = this.selectedOrder() === 'asc' ? 'desc' : 'asc';
    this.selectedOrder.set(nextOrder);
    this.tauri.setSortOrder(nextOrder);
  }

  async triggerSync(): Promise<void> {
    await this.sync.fetchManifest();
    await this.tauri.refreshData();
  }
}
