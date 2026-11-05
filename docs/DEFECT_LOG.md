# SpendTrack Defect Log

## Review summary

No confirmed defects were identified during the available testing and source review.

| Defect ID | Defect description | Steps to reproduce | Expected result | Actual result | Severity | Status (Open/Fixed/Verified) |
| --- | --- | --- | --- | --- | --- | --- |
| — | No confirmed defects identified. | Not applicable. | The application behaves as specified by the available automated checks. | `flutter analyze` completed with no issues; `flutter test` passed all 67 tests. | None | Verified |

## Testing limitations

- Verification was limited to the available Flutter analyzer and automated unit/widget test suite in this environment.
- No manual exploratory testing on a physical Android device or emulator was performed for this log.
- Automated tests cannot establish the absence of defects in untested scenarios or device-specific behavior.
- Git history and source review provide context but are not substitutes for reproducing and confirming a defect.


## Physical Device Testing – 5 November 2026

The release APK was installed and tested on a physical Android phone.

### Manual Test Results

| Test case | Steps performed | Result | Status |
|---|---|---|---|
| APK installation | Installed and opened the release APK on a physical Android phone | App installed and launched successfully | Passed |
| Form validation | Attempted to save an expense with invalid or missing input | Validation message displayed correctly | Passed |
| Long text handling | Entered a very long expense title and note | App handled the input without crashing | Passed |
| Duplicate-save protection | Tapped the Save button repeatedly in quick succession | Only one expense was saved | Passed |
| Screen rotation | Rotated the phone between portrait and landscape orientations | App continued working properly | Passed |
| Offline functionality | Used the app without an internet connection | App continued working properly | Passed |

### Defect Summary

No defects were observed during the above manual physical-device tests.

**Note:** These results cover the listed manual tests only. They do not establish that every possible device or usage scenario is defect-free.
