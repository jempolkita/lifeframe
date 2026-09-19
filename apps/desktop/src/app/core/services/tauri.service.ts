import { Injectable, signal, computed } from '@angular/core';
import { invoke } from '@tauri-apps/api/core';
import { Photo, Album, Person, SyncManifest } from '../api/model/models';

export interface ServerStatus {
  is_running: boolean;
  port: number;
  local_ip: string;
  storage_path: string;
  total_photos: number;
}

export interface FolderNode {
  label: string;
  path: string;
  photo_count: number;
  is_library_root: boolean;
  children: FolderNode[];
}

@Injectable({
  providedIn: 'root',
})
export class TauriService {
  // ── Reactive Signals ──────────────────────────────────────────────────────
  readonly serverStatus = signal<ServerStatus | null>(null);
  readonly photos = signal<Photo[]>([]);
  readonly albums = signal<Album[]>([]);
  readonly people = signal<Person[]>([]);
  readonly selectedPhoto = signal<Photo | null>(null);
  readonly selectedAlbum = signal<string | null>(null);
  readonly searchQuery = signal<string>('');
  readonly sortBy = signal<string>('name');
  readonly sortOrder = signal<'asc' | 'desc'>('asc');
  readonly isScanning = signal<boolean>(false);

  /** Paths of all registered library root folders. */
  readonly libraryPaths = signal<string[]>([]);

  /** Hierarchical folder tree built from library roots + indexed albums. */
  readonly folderTree = signal<FolderNode[]>([]);

  // ── Computed Signals ──────────────────────────────────────────────────────
  readonly filteredPhotos = computed(() => {
    const all = this.photos();
    const selectedFolder = this.selectedAlbum();
    const query = this.searchQuery().toLowerCase().trim();
    const sort = this.sortBy();
    const order = this.sortOrder();

    const filtered = all.filter((photo) => {
      let matchAlbum = true;
      if (selectedFolder && selectedFolder !== 'all') {
        const normSelected = selectedFolder.replace(/\\/g, '/').toLowerCase().trim();
        const normRelPath = photo.relative_path.replace(/\\/g, '/').toLowerCase().trim();
        const libPath = (photo.library_path || '').replace(/\\/g, '/').toLowerCase().trim();

        // Construct full normalized photo path
        const fullPhotoPath = libPath
          ? libPath.endsWith('/')
            ? `${libPath}${normRelPath}`
            : `${libPath}/${normRelPath}`
          : normRelPath;

        // Match by album ID
        const matchId = photo.album_id === selectedFolder;

        // Match full path (selected folder is exact photo location or an ancestor folder)
        const matchFullPath =
          fullPhotoPath === normSelected ||
          fullPhotoPath.startsWith(normSelected.endsWith('/') ? normSelected : `${normSelected}/`);

        // Match relative path (for dev mock mode or relative album paths)
        const matchRel =
          normRelPath === normSelected ||
          normRelPath.startsWith(normSelected.endsWith('/') ? normSelected : `${normSelected}/`);

        matchAlbum = matchId || matchFullPath || matchRel;
      }

      const matchQuery =
        !query ||
        photo.filename.toLowerCase().includes(query) ||
        photo.relative_path.toLowerCase().includes(query) ||
        (photo.tags && photo.tags.some((t) => t.toLowerCase().includes(query)));
      return matchAlbum && matchQuery;
    });

    return [...filtered].sort((a: Photo, b: Photo) => {
      let comparison = 0;
      if (sort === 'name') {
        comparison = a.filename.localeCompare(b.filename);
      } else if (sort === 'date') {
        const dateA = a.date_taken ? new Date(a.date_taken).getTime() : 0;
        const dateB = b.date_taken ? new Date(b.date_taken).getTime() : 0;
        comparison = dateA - dateB;
      } else if (sort === 'size') {
        comparison = (a.size_bytes || 0) - (b.size_bytes || 0);
      }
      return order === 'desc' ? -comparison : comparison;
    });
  });

  readonly isTauriAvailable = signal<boolean>(this.checkTauriAvailable());

  constructor() {
    this.init();
  }

  private checkTauriAvailable(): boolean {
    return typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;
  }

  async init(): Promise<void> {
    if (this.isTauriAvailable()) {
      await this.refreshServerStatus();
      await Promise.all([
        this.refreshData(),
        this.refreshLibraryPaths(),
        this.refreshFolderTree(),
      ]);
    } else {
      // Running in browser dev mode: provide sample mock data for rapid UI iteration
      this.loadMockData();
    }
  }

  async refreshServerStatus(): Promise<void> {
    if (!this.isTauriAvailable()) return;
    try {
      const status = await invoke<ServerStatus>('get_server_status');
      this.serverStatus.set(status);
    } catch (err) {
      console.warn('Could not fetch server status:', err);
    }
  }

  async startServer(port?: number): Promise<void> {
    if (!this.isTauriAvailable()) return;
    try {
      const status = await invoke<ServerStatus>('start_server', { port });
      this.serverStatus.set(status);
    } catch (err) {
      console.error('Failed to start server:', err);
    }
  }

  async stopServer(): Promise<void> {
    if (!this.isTauriAvailable()) return;
    try {
      const status = await invoke<ServerStatus>('stop_server');
      this.serverStatus.set(status);
    } catch (err) {
      console.error('Failed to stop server:', err);
    }
  }

  async selectFolder(): Promise<string | null> {
    if (!this.isTauriAvailable()) return null;
    try {
      const selected = await invoke<string | null>('select_folder');
      return selected;
    } catch (err) {
      console.error('Failed to select folder:', err);
      return null;
    }
  }

  // ── Library / Collection Management ──────────────────────────────────────

  /** Fetches and updates the library paths signal. */
  async refreshLibraryPaths(): Promise<void> {
    if (!this.isTauriAvailable()) return;
    try {
      const paths = await invoke<string[]>('get_library_paths');
      this.libraryPaths.set(paths);
    } catch (err) {
      console.warn('Could not fetch library paths:', err);
    }
  }

  /** Fetches and updates the folder tree signal. */
  async refreshFolderTree(): Promise<void> {
    if (!this.isTauriAvailable()) return;
    try {
      const tree = await invoke<FolderNode[]>('get_folder_tree');
      this.folderTree.set(tree);
    } catch (err) {
      console.warn('Could not fetch folder tree:', err);
    }
  }

  /**
   * Opens a native directory picker, adds the selected folder to the library,
   * then refreshes the library paths and folder tree.
   * Returns the updated list of library paths.
   */
  async addLibraryPath(): Promise<string[]> {
    if (!this.isTauriAvailable()) return this.libraryPaths();
    try {
      const paths = await invoke<string[]>('add_library_path');
      this.libraryPaths.set(paths);
      await this.refreshFolderTree();
      return paths;
    } catch (err) {
      console.error('Failed to add library path:', err);
      return this.libraryPaths();
    }
  }

  /**
   * Removes a path from the library, then refreshes the library paths and
   * folder tree.
   */
  async removeLibraryPath(path: string): Promise<string[]> {
    if (!this.isTauriAvailable()) return this.libraryPaths();
    try {
      const paths = await invoke<string[]>('remove_library_path', { path });
      this.libraryPaths.set(paths);
      await this.refreshFolderTree();
      return paths;
    } catch (err) {
      console.error('Failed to remove library path:', err);
      return this.libraryPaths();
    }
  }

  // ── Scan ─────────────────────────────────────────────────────────────────

  /** Scans all registered library folders and refreshes data. */
  async scanFolder(): Promise<number | null> {
    if (!this.isTauriAvailable()) return 0;
    this.isScanning.set(true);
    try {
      const count = await invoke<number>('scan_folder');
      await Promise.all([
        this.refreshData(),
        this.refreshServerStatus(),
        this.refreshFolderTree(),
      ]);
      return count;
    } catch (err) {
      console.error('Failed to scan folder:', err);
      return 0;
    } finally {
      this.isScanning.set(false);
    }
  }

  async refreshData(): Promise<void> {
    if (!this.isTauriAvailable()) return;
    try {
      const [photos, albums, people] = await Promise.all([
        invoke<Photo[]>('get_photos'),
        invoke<Album[]>('get_albums'),
        invoke<Person[]>('get_people'),
      ]);
      this.photos.set(photos);
      this.albums.set(albums);
      this.people.set(people);
    } catch (err) {
      console.warn('Failed to refresh data from Tauri:', err);
    }
  }

  selectPhoto(photo: Photo | null): void {
    this.selectedPhoto.set(photo);
  }

  selectAlbum(albumId: string | null): void {
    this.selectedAlbum.set(albumId);
  }

  setSearchQuery(query: string): void {
    this.searchQuery.set(query);
  }

  setSort(sortBy: string): void {
    this.sortBy.set(sortBy);
  }

  setSortOrder(order: 'asc' | 'desc'): void {
    this.sortOrder.set(order);
  }

  private loadMockData(): void {
    this.serverStatus.set({
      is_running: true,
      port: 8080,
      local_ip: '192.168.1.100',
      storage_path: '/Users/demo/Pictures/Lifeframe',
      total_photos: 4,
    });

    // Mock library paths and tree for browser development
    this.libraryPaths.set([
      '/Users/demo/Pictures/Vacation 2026',
      '/Users/demo/Pictures/Family',
    ]);

    this.folderTree.set([
      {
        label: 'Vacation 2026',
        path: '/Users/demo/Pictures/Vacation 2026',
        photo_count: 2,
        is_library_root: true,
        children: [
          {
            label: 'Beach Day',
            path: '/Users/demo/Pictures/Vacation 2026/Beach Day',
            photo_count: 2,
            is_library_root: false,
            children: [],
          },
        ],
      },
      {
        label: 'Family',
        path: '/Users/demo/Pictures/Family',
        photo_count: 2,
        is_library_root: true,
        children: [],
      },
    ]);

    const mockAlbums: Album[] = [
      { id: 'album-1', name: 'Vacation 2026', relative_path: 'Vacation 2026', photo_count: 2 },
      { id: 'album-2', name: 'Family & Friends', relative_path: 'Family & Friends', photo_count: 2 },
    ];

    const mockPhotos: Photo[] = [
      {
        id: 'p-1',
        filename: 'DSC_0042.JPG',
        relative_path: 'Vacation 2026/Beach Day/DSC_0042.JPG',
        library_path: '/Users/demo/Pictures/Vacation 2026',
        size_bytes: 4280120,
        hash_sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        mime_type: 'image/jpeg',
        width: 4000,
        height: 3000,
        rating: 5,
        date_taken: '2026-07-14T10:32:00Z',
        date_modified: '2026-07-14T10:32:00Z',
        album_id: 'album-1',
        tags: ['Beach', 'Sunset', 'Holiday'],
        faces: [
          {
            id: 'face-1',
            person_id: 'person-1',
            person_name: 'Sarah',
            confidence: 0.96,
            is_confirmed: true,
            box: { x: 0.35, y: 0.25, width: 0.15, height: 0.2 },
          },
        ],
        gps: { latitude: -8.4095, longitude: 115.1889, altitude: 25.0 },
        exif: {
          make: 'Sony',
          model: 'ILCE-7M4',
          lens: 'FE 24-70mm F2.8 GM II',
          focal_length: 35.0,
          f_number: 2.8,
          iso: 100,
          exposure_time: '1/500s',
        },
      },
      {
        id: 'p-2',
        filename: 'DSC_0043.JPG',
        relative_path: 'Vacation 2026/Beach Day/DSC_0043.JPG',
        library_path: '/Users/demo/Pictures/Vacation 2026',
        size_bytes: 3891400,
        hash_sha256: 'a1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef0',
        mime_type: 'image/jpeg',
        width: 4000,
        height: 3000,
        rating: 4,
        date_taken: '2026-07-14T11:05:12Z',
        date_modified: '2026-07-14T11:05:12Z',
        album_id: 'album-1',
        tags: ['Mountain', 'Landscape'],
        faces: [],
        gps: { latitude: -8.412, longitude: 115.195, altitude: 110.0 },
        exif: {
          make: 'Sony',
          model: 'ILCE-7M4',
          lens: 'FE 24-70mm F2.8 GM II',
          focal_length: 24.0,
          f_number: 8.0,
          iso: 100,
          exposure_time: '1/250s',
        },
      },
      {
        id: 'p-3',
        filename: 'IMG_20260801_141200.jpg',
        relative_path: 'Family & Friends/IMG_20260801_141200.jpg',
        library_path: '/Users/demo/Pictures/Family',
        size_bytes: 2512000,
        hash_sha256: '123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0',
        mime_type: 'image/jpeg',
        width: 3840,
        height: 2160,
        rating: 4,
        date_taken: '2026-08-01T14:12:00Z',
        date_modified: '2026-08-01T14:12:00Z',
        album_id: 'album-2',
        tags: ['Birthday', 'Celebration'],
        faces: [
          {
            id: 'face-2',
            person_id: 'person-2',
            person_name: 'David',
            confidence: 0.94,
            is_confirmed: true,
            box: { x: 0.45, y: 0.3, width: 0.18, height: 0.22 },
          },
        ],
        exif: {
          make: 'Google',
          model: 'Pixel 8 Pro',
          focal_length: 6.9,
          f_number: 1.68,
          iso: 54,
          exposure_time: '1/120s',
        },
      },
      {
        id: 'p-4',
        filename: 'IMG_20260801_141522.jpg',
        relative_path: 'Family & Friends/IMG_20260801_141522.jpg',
        library_path: '/Users/demo/Pictures/Family',
        size_bytes: 2715000,
        hash_sha256: 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210',
        mime_type: 'image/jpeg',
        width: 3840,
        height: 2160,
        rating: 3,
        date_taken: '2026-08-01T14:15:22Z',
        date_modified: '2026-08-01T14:15:22Z',
        album_id: 'album-2',
        tags: ['Cake', 'Party'],
        faces: [],
        exif: {
          make: 'Google',
          model: 'Pixel 8 Pro',
          focal_length: 6.9,
          f_number: 1.68,
          iso: 78,
          exposure_time: '1/60s',
        },
      },
    ];

    const mockPeople: Person[] = [
      { id: 'person-1', name: 'Sarah', photo_count: 1 },
      { id: 'person-2', name: 'David', photo_count: 1 },
    ];

    this.albums.set(mockAlbums);
    this.photos.set(mockPhotos);
    this.people.set(mockPeople);
    this.selectedPhoto.set(mockPhotos[0]);
  }
}
