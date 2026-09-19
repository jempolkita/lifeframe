export * from './device.service';
import { DeviceService } from './device.service';
export * from './media.service';
import { MediaService } from './media.service';
export * from './people.service';
import { PeopleService } from './people.service';
export * from './sync.service';
import { SyncService } from './sync.service';
export const APIS = [DeviceService, MediaService, PeopleService, SyncService];
