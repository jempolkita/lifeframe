import { Injectable, inject, signal } from '@angular/core';
import { SyncService as ApiSyncService } from '../api/api/sync.service';
import { MediaService as ApiMediaService } from '../api/api/media.service';
import { DeviceService as ApiDeviceService } from '../api/api/device.service';
import { SyncManifest, DeviceStatus } from '../api/model/models';
import { TauriService } from './tauri.service';

@Injectable({
  providedIn: 'root',
})
export class SyncService {
  private readonly tauri = inject(TauriService);
  private readonly apiSync = inject(ApiSyncService, { optional: true });
  private readonly apiMedia = inject(ApiMediaService, { optional: true });
  private readonly apiDevice = inject(ApiDeviceService, { optional: true });

  readonly isSyncing = signal<boolean>(false);
  readonly lastSyncManifest = signal<SyncManifest | null>(null);

  /** Standard multi-tier dimensions matching backend store */
  static readonly TIER_MICRO = 256;
  static readonly TIER_PREVIEW = 720;

  /**
   * Generates a streaming URL to fetch a photo or thumbnail from the Axum HTTP server.
   * Standardizes on multi-tier tiers (256 micro-grid, 720 preview).
   */
  getImageUrl(
    photoIdOrPath: string,
    thumbnail = true,
    maxWidth = SyncService.TIER_MICRO,
    maxHeight = SyncService.TIER_MICRO
  ): string {
    const port = this.tauri.serverStatus()?.port || 8080;
    const baseUrl = `http://127.0.0.1:${port}`;
    const params = new URLSearchParams();
    if (photoIdOrPath.includes('/') || photoIdOrPath.includes('\\') || photoIdOrPath.includes('.')) {
      params.set('path', photoIdOrPath);
    } else {
      params.set('id', photoIdOrPath);
    }
    if (thumbnail) {
      params.set('thumbnail', 'true');
      params.set('max_width', maxWidth.toString());
      params.set('max_height', maxHeight.toString());
    }
    return `${baseUrl}/image?${params.toString()}`;
  }

  /**
   * Preloads a single image into browser HTTP cache using Keep-Alive connection.
   */
  preloadImage(url: string): Promise<void> {
    return new Promise((resolve) => {
      const img = new Image();
      img.onload = () => resolve();
      img.onerror = () => resolve();
      img.src = url;
    });
  }

  /**
   * Task 6.2.3: Fast Transport & Connection Reuse
   * Batches image prefetching with bounded concurrency (default 6 parallel connections)
   * to respect browser per-host connection limits and maintain 60 FPS scrolling.
   */
  async preloadThumbnailsBatch(urls: string[], concurrency = 6): Promise<void> {
    const queue = [...urls];
    const workers = Array.from({ length: Math.min(concurrency, queue.length) }, async () => {
      while (queue.length > 0) {
        const url = queue.shift();
        if (url) {
          await this.preloadImage(url);
        }
      }
    });
    await Promise.all(workers);
  }

  /**
   * Fetches latest sync manifest directly from the local Axum server
   */
  async fetchManifest(since?: string): Promise<SyncManifest | null> {
    if (!this.apiSync) return null;
    this.isSyncing.set(true);
    try {
      return await new Promise<SyncManifest>((resolve, reject) => {
        this.apiSync!.getManifest(since).subscribe({
          next: (manifest) => {
            this.lastSyncManifest.set(manifest);
            resolve(manifest);
          },
          error: (err) => reject(err),
        });
      });
    } catch (err) {
      console.error('Failed to fetch manifest from Axum server:', err);
      return null;
    } finally {
      this.isSyncing.set(false);
    }
  }

  /**
   * Sends device heartbeat/status to Axum
   */
  async reportStatus(status: DeviceStatus): Promise<boolean> {
    if (!this.apiDevice) return false;
    try {
      return await new Promise<boolean>((resolve) => {
        this.apiDevice!.reportDeviceStatus(status).subscribe({
          next: (res) => resolve(res.success),
          error: () => resolve(false),
        });
      });
    } catch {
      return false;
    }
  }
}
