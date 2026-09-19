import { Component, inject, OnDestroy, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { listen, UnlistenFn } from '@tauri-apps/api/event';
import { ProgressBarModule } from 'primeng/progressbar';
import { TauriService } from '../core/services/tauri.service';

interface ScanProgress {
  current: number;
  total: number;
  filename: string;
  percent: number;
}

interface ScanComplete {
  indexed: number;
  removed: number;
}

type StatusMode = 'idle' | 'scanning' | 'done';

@Component({
  selector: 'app-status-bar',
  standalone: true,
  imports: [CommonModule, ProgressBarModule],
  template: `
    <div
      class="h-6 flex items-center px-4 gap-3 border-t transition-colors duration-200 select-none text-[11px] font-mono"
      [class]="barClass()"
    >
      @switch (mode()) {
        @case ('scanning') {
          <!-- Active scan indicator -->
          <span class="w-1.5 h-1.5 rounded-full bg-sky-400 animate-pulse shrink-0"></span>
          <div class="flex-1 flex items-center gap-3 min-w-0">
            <p-progressBar
              [value]="progress().percent"
              [showValue]="false"
              styleClass="h-1 flex-1"
            />
            <span class="text-slate-500 dark:text-slate-400 shrink-0">
              {{ progress().current }} / {{ progress().total }}
            </span>
            <span class="text-slate-400 dark:text-slate-500 truncate min-w-0">
              Indexing: {{ progress().filename }}
            </span>
          </div>
          <span class="text-sky-500 dark:text-sky-400 shrink-0 font-semibold">
            {{ progress().percent }}%
          </span>
        }

        @case ('done') {
          <!-- Completion flash -->
          <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 shrink-0"></span>
          <span class="text-emerald-600 dark:text-emerald-400">
            Scan complete — {{ lastResult().indexed }} photos indexed
            @if (lastResult().removed > 0) {
              , {{ lastResult().removed }} removed
            }
          </span>
        }

        @default {
          <!-- Idle state -->
          <span class="w-1.5 h-1.5 rounded-full bg-slate-300 dark:bg-slate-600 shrink-0"></span>
          @if (tauri.libraryPaths().length > 0) {
            <span class="text-slate-400 dark:text-slate-500">
              {{ tauri.libraryPaths().length }} {{ tauri.libraryPaths().length === 1 ? 'library' : 'libraries' }} registered
              &mdash; {{ tauri.photos().length }} photos indexed
            </span>
          } @else {
            <span class="text-slate-400 dark:text-slate-500">
              No libraries configured — open Settings to add your photo folders
            </span>
          }
        }
      }
    </div>
  `,
})
export class StatusBarComponent implements OnInit, OnDestroy {
  readonly tauri = inject(TauriService);

  readonly mode = signal<StatusMode>('idle');
  readonly progress = signal<ScanProgress>({ current: 0, total: 0, filename: '', percent: 0 });
  readonly lastResult = signal<ScanComplete>({ indexed: 0, removed: 0 });

  readonly barClass = computed(() => {
    const base = 'border-slate-200 dark:border-slate-800 ';
    switch (this.mode()) {
      case 'scanning':
        return base + 'bg-slate-50 dark:bg-slate-900/80';
      case 'done':
        return base + 'bg-emerald-50 dark:bg-emerald-950/20';
      default:
        return base + 'bg-white dark:bg-slate-900 text-slate-400 dark:text-slate-500';
    }
  });

  private unlistenProgress?: UnlistenFn;
  private unlistenComplete?: UnlistenFn;
  private doneTimer?: ReturnType<typeof setTimeout>;

  async ngOnInit(): Promise<void> {
    // Only listen for events when running inside Tauri
    if (this.tauri.isTauriAvailable()) {
      this.unlistenProgress = await listen<ScanProgress>('scan-progress', (event) => {
        this.mode.set('scanning');
        this.progress.set(event.payload);
      });

      this.unlistenComplete = await listen<ScanComplete>('scan-complete', (event) => {
        this.lastResult.set(event.payload);
        this.mode.set('done');
        // Revert to idle after 4 seconds
        clearTimeout(this.doneTimer);
        this.doneTimer = setTimeout(() => this.mode.set('idle'), 4000);
      });
    }
  }

  ngOnDestroy(): void {
    this.unlistenProgress?.();
    this.unlistenComplete?.();
    clearTimeout(this.doneTimer);
  }
}
