# Experimental / legacy scripts

These are the 14.1/16.0 experiments, the older XDA-prebuilt repack and the first
12.1 source build that `91` supersedes. They are **not turnkey** and are not part of
the supported three-recovery build.

| Script | What it was |
|---|---|
| `10-build-14.1.sh`, `11-rebuild.sh` | TWRP 14.1 full build + incremental rebuild; userspace does not boot |
| `50-build-hybrid.sh` | stock A16 platform + TWRP 14.1 recovery; logo hang |
| `60-repack-ofox-touch.sh` | replace the XDA OrangeFox touch module and repack; prebuilt fallback |
| `70-build-ofox16.sh`, `75-repack-ofox16-slim.sh` | OrangeFox 16.0 build/slim repack |
| `76-build-hybrid-tests.sh`, `77-build-fontkept-A.sh`, `78-build-full-A.sh` | 16.0/14.1 hybrid and size experiments |
| `80-build-ofox14.sh`, `82-…`, `83-…`, `84-…` | OrangeFox 14.1 build and hybrid experiments |
| `85-build-ofox12.sh` | early 12.1 source build |
| `prepare-ofox16-size.sh`, `compare-ofox14-r12.sh` | size/recovery comparisons |
| `ofox-touch.sh`, `ofox-touch2.sh` | early phone-side touch module experiments (kept outside this folder) |
| `90-build-ofox12-source.sh` | first working 12.1 source build; `91` is the current builder |

Read `../experimental/BUILD-14.1-16.0.md` for the detailed history. Paths in these
scripts refer to earlier trees (`/root/twrp`, `/root/ofox`, etc.), so do not run them
expecting the current layout.
