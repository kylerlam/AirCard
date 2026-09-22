# Card identification and missing-card checks

Development branch: `kyler/dev`.

## Implemented scope

AirCard keeps cards in saved discovery order and enriches their names from the
Mac's existing Wallet cache. Card identity, selection and skin file paths are
stored by the full card ID, separately for each connected iPhone. Repeated
scan events update the same item; identical display names do not merge cards.

The grid contains saved or scanned IDs only. Cache-only entries appear under
**Check missing cards**, not in the flash selection:

- **Scan-confirmed** means the ID has been observed in a pass/cache path in this
  iPhone's logs, including a saved confirmation from an earlier session. The
  scanner message separately reports distinct IDs seen in the current scan.
- **Saved IDs to confirm** includes migrated legacy IDs and manually added IDs
  that have not been scanned on this iPhone in the new version.
- **Payment entries to confirm** come from one matching remote-device cache.
  Matching requires the device model and an exact scan-confirmed card ID.
  Multiple matching devices are reported as ambiguous, rather than guessed.
- **Mac passes to confirm** are membership/ticket metadata from the Mac's local
  Wallet library. Their presence on the connected iPhone is not assumed.

Neither the scanned count nor cache count is presented as the phone's total.
Cache contents can be stale or incomplete. The app does not synchronize the
phone's actual Wallet display order; that original requirement remains deferred
under the subsequently approved, smaller scope.

## Checking a missing card

1. Connect, unlock and trust the iPhone, then choose **Scan Cards**.
2. Open each missing card in the iPhone Wallet app. Payment cards can also be
   opened through the side-button Apple Pay interface after authentication.
   Membership cards may need opening directly inside Wallet.
3. Expand **Check missing cards** to see named cache entries that still need
   scan confirmation. Short ID suffixes distinguish cards with the same name.
4. If scanning stops unexpectedly, inspect **Log**, use **Reconnect**, then
   start scanning again. The app distinguishes connection failure, scanner
   startup failure, unexpected exit and a scan with no detected IDs.
5. **Read Cache** rereads local metadata. It does not force an iCloud refresh.
   Missing or unreadable metadata leaves scanning available and displays a
   diagnostic instead of declaring that the phone has zero cards.

## Persistence and migration

Version-two records use per-device UserDefaults keys. Existing legacy stores
remain untouched and are imported as unconfirmed IDs on first use. An empty
version-two list is authoritative, so clearing cards does not reimport legacy
entries on restart. Saved images retain their file paths; if an original image
file is moved or deleted, choose it again using the unavailable-image notice.

Confirmed IDs may remain saved after a card is removed from the phone. AirCard
does not infer removal from silence in a log or a missing cache entry.

## Validation

`python3 -m unittest discover -s tests -v` covers native log decoding, cache
parsing, malformed/cyclic archives, ambiguous devices, missing metadata, exact
ID matching, duplicate names, pending counts, repeat scanning, legacy migration,
per-device persistence, skin identity across reordering, and clear/relaunch.
All committed fixtures use synthetic identifiers.

`./script/build_and_run.sh --verify` builds the universal macOS app and DMG and
launches the local build. This feature reads local metadata and device logs;
verification does not flash card artwork or modify the phone's Wallet database.
