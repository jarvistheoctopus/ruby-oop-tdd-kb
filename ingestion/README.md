# Ingestion source directory

Default source directory for course videos is now:

- `/mnt/10PinesCourses`

Scripts that use this default:

- `scripts/transcribe_all_courses.sh`
- `scripts/transcribe_supervisor.sh`
- `scripts/ingest_diseno_s01e01_full.sh`

You can still override the default for batch/supervisor scripts with:

- `TRANSCRIBE_SOURCE_BASE=/some/other/path`

## Persistent mount (system)

To keep `/mnt/10PinesCourses` available across reboots, add an `/etc/fstab` entry for the shared folder and run `mount -a`.
