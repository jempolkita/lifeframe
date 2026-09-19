import { Injectable, signal, computed, effect } from '@angular/core';

export type ThemeMode = 'system' | 'light' | 'dark';

@Injectable({
  providedIn: 'root',
})
export class ThemeService {
  private readonly storageKey = 'lifeframe_theme_mode';
  private mediaQuery: MediaQueryList | null = null;
  private readonly systemIsDark = signal<boolean>(false);

  readonly themeMode = signal<ThemeMode>(this.getInitialThemeMode());

  readonly isDark = computed<boolean>(() => {
    const mode = this.themeMode();
    if (mode === 'dark') return true;
    if (mode === 'light') return false;
    return this.systemIsDark();
  });

  constructor() {
    if (typeof window !== 'undefined' && typeof window.matchMedia === 'function') {
      try {
        this.mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
        this.systemIsDark.set(this.mediaQuery.matches);
        this.mediaQuery.addEventListener('change', (e: MediaQueryListEvent) => {
          this.systemIsDark.set(e.matches);
        });
      } catch (err) {
        console.warn('Could not initialize mediaQuery listener:', err);
      }
    }

    // Effect only performs DOM and localStorage side effects.
    // NO signal writes happen inside this effect!
    effect(() => {
      const mode = this.themeMode();
      this.saveThemeMode(mode);

      const dark = this.isDark();
      if (typeof document !== 'undefined') {
        const root = document.documentElement;
        if (dark) {
          root.classList.add('dark');
        } else {
          root.classList.remove('dark');
        }
      }
    });
  }

  setTheme(mode: ThemeMode): void {
    this.themeMode.set(mode);
  }

  toggleTheme(): void {
    const current = this.themeMode();
    if (current === 'system') {
      this.themeMode.set('dark');
    } else if (current === 'dark') {
      this.themeMode.set('light');
    } else {
      this.themeMode.set('system');
    }
  }

  private getInitialThemeMode(): ThemeMode {
    if (typeof window === 'undefined') return 'system';
    try {
      const saved = localStorage.getItem(this.storageKey);
      if (saved === 'light' || saved === 'dark' || saved === 'system') {
        return saved;
      }
    } catch {
      // ignore storage access error
    }
    return 'system';
  }

  private saveThemeMode(mode: ThemeMode): void {
    if (typeof window === 'undefined') return;
    try {
      localStorage.setItem(this.storageKey, mode);
    } catch {
      // ignore storage access error
    }
  }
}
