# CloudKitContract Changelog

Every modification to the `CloudKitContract` folder must be documented here and accompanied by a bump to `ContractInfo.version`.

## 1 — 2026-11-12
- Initial contract scaffolding for `PlantationScanRequest` synchronization between iOS (Farmer) and macOS (Drone Operator).
- Top-level fields:
  - iOS-owned: `schemaVersion`, `farmBoundary`, `farmSize`, `farmCircumference`, `submittedAt`, `farmName`, `farmAddress`, `plantingMonthAndYear`, `soilType`, `fertilizingFrequencyPerYear`, `fertilizersCompositions`, `harvestFrequencyPerMonth`, `averageHarvestWeightKg`, `farmerContactName`, `farmerPhoneNumber`, `farmerHomeAddress`, `fertilizationBudgetPerHa`.
  - macOS-owned: `progressionStatus`, `progressionStatusDetail`, `orthomosaicImage`, `fertilizingZone`, `fertilizerNeedPerZone`, `treeIdentification`, `plannedOperatorVisitDate`, `resultSentAt`.
- Versioned JSON envelopes (`version: "1.0.0"`) for:
  - `fertilizersCompositions`
  - `progressionStatusDetail`
  - `fertilizingZone`
  - `fertilizerNeedPerZone`
  - `treeIdentification`
- Fault-tolerant readers returning `Result<T, FieldError>`.
- Writer enforcing `.changedKeys` save policy and field ownership.
- Schema deploy: REQUIRED.

