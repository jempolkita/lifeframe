import { Component, inject, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TreeModule, TreeNodeSelectEvent } from 'primeng/tree';
import { TreeNode } from 'primeng/api';
import { ButtonModule } from 'primeng/button';
import { TooltipModule } from 'primeng/tooltip';
import { TauriService, FolderNode } from '../../core/services/tauri.service';

@Component({
  selector: 'app-folder-tree',
  standalone: true,
  imports: [CommonModule, TreeModule, ButtonModule, TooltipModule],
  template: `
    <div class="h-full flex flex-col bg-slate-100/60 dark:bg-slate-900/50 border-r border-slate-200 dark:border-slate-800 select-none transition-colors duration-200">
      <!-- Sidebar Header -->
      <div class="p-3 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between">
        <span class="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">Library</span>
        <div class="flex items-center gap-1">
          <p-button
            icon="pi pi-refresh"
            [rounded]="true"
            [text]="true"
            size="small"
            pTooltip="Scan & Refresh Library"
            [loading]="tauri.isScanning()"
            (onClick)="scanAndRefresh()"
          />
        </div>
      </div>

      <!-- Dynamic Tree or Empty State -->
      <div class="flex-1 overflow-y-auto p-2">
        @if (tauri.libraryPaths().length === 0) {
          <!-- No libraries registered yet -->
          <div class="flex flex-col items-center justify-center h-full gap-3 py-10 text-center px-4">
            <div class="w-12 h-12 rounded-xl bg-slate-200 dark:bg-slate-800 flex items-center justify-center">
              <i class="pi pi-folder-open text-xl text-slate-400 dark:text-slate-500"></i>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-600 dark:text-slate-300 leading-snug">No Libraries Added</p>
              <p class="text-[11px] text-slate-400 dark:text-slate-500 mt-1 leading-snug">
                Open Settings to add your photo folders.
              </p>
            </div>
          </div>
        } @else {
          <!-- All Photos shortcut -->
          <div
            class="flex items-center justify-between px-2 py-1.5 rounded-md mb-1 cursor-pointer transition-colors"
            [class.bg-sky-100]="tauri.selectedAlbum() === null"
            [class.dark:bg-sky-900]="tauri.selectedAlbum() === null"
            [class.hover:bg-slate-200]="tauri.selectedAlbum() !== null"
            [class.dark:hover:bg-slate-800]="tauri.selectedAlbum() !== null"
            (click)="selectAll()"
          >
            <div class="flex items-center gap-2">
              <i class="pi pi-images text-xs text-sky-500 dark:text-sky-400"></i>
              <span class="text-slate-700 dark:text-slate-200 text-xs font-medium">All Photos</span>
            </div>
            <span class="text-[10px] px-1.5 py-0.5 rounded-full bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-400 font-mono">
              {{ tauri.photos().length }}
            </span>
          </div>

          <!-- Library Roots -->
          <p-tree
            [value]="treeNodes()"
            selectionMode="single"
            [(selection)]="selectedNode"
            (onNodeSelect)="onNodeSelect($event)"
            class="w-full bg-transparent border-none !p-0 text-sm"
          >
            <ng-template let-node pTemplate="default">
              <div class="flex items-center justify-between w-full pr-2 py-0.5">
                <div class="flex items-center gap-2">
                  <!-- <i [class]="node.icon + ' text-xs ' + (node.data?.is_library_root ? 'text-indigo-500 dark:text-indigo-400' : 'text-sky-500 dark:text-sky-400')"></i> -->
                  <span class="text-slate-700 dark:text-slate-200 text-xs font-medium">{{ node.label }}</span>
                </div>
                @if (node.data?.photo_count !== undefined && node.data.photo_count > 0) {
                  <span class="text-[10px] mx-2 px-1.5 py-0.5 rounded-full bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-400 font-mono">
                    {{ node.data.photo_count }}
                  </span>
                }
              </div>
            </ng-template>
          </p-tree>
        }
      </div>

      <!-- Footer: Scan button -->
      <div class="p-3 border-t border-slate-200 dark:border-slate-800 bg-slate-100/50 dark:bg-slate-900/30">
        <p-button
          label="Scan Libraries"
          icon="pi pi-search"
          severity="secondary"
          size="small"
          [loading]="tauri.isScanning()"
          [disabled]="tauri.libraryPaths().length === 0"
          (onClick)="scanAndRefresh()"
          styleClass="w-full text-xs justify-center"
        />
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
export class FolderTreeComponent {
  readonly tauri = inject(TauriService);
  selectedNode: TreeNode | null = null;

  /** Maps FolderNode[] from backend into PrimeNG TreeNode[] recursively. */
  readonly treeNodes = computed<TreeNode[]>(() => {
    return this.tauri.folderTree().map((root) => this.mapFolderNode(root));
  });

  private mapFolderNode(node: FolderNode): TreeNode {
    return {
      key: node.path,
      label: node.label,
      icon: node.is_library_root ? 'pi pi-database' : 'pi pi-folder',
      expanded: node.is_library_root, // auto-expand library roots
      data: {
        photo_count: node.photo_count,
        path: node.path,
        is_library_root: node.is_library_root,
      },
      children: node.children.map((child) => this.mapFolderNode(child)),
    };
  }

  onNodeSelect(event: TreeNodeSelectEvent): void {
    const node = event.node;
    if (!node?.data) return;

    // Filter to the selected library root or subfolder path
    const folderPath = node.data.path ? node.data.path.replace(/\\/g, '/') : (node.label || '');
    this.tauri.selectAlbum(folderPath);
  }

  selectAll(): void {
    this.selectedNode = null;
    this.tauri.selectAlbum(null);
  }

  async scanAndRefresh(): Promise<void> {
    await this.tauri.scanFolder();
  }
}
