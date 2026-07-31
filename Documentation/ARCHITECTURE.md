# College Football Commish architecture
The app keeps the animated host as the persistent stage and treats search, discovery, player galleries, quizzes, rewards, and profile state as presentations around it.

```text
CollegeFootballExperienceRootView
├── CollegeFootballOnboardingState
├── CollegeFootballSearchEnvironment
│   ├── AdaptiveCollegeFootballQueryInterpreter
│   ├── DefaultCollegeFootballSearchPlanner
│   ├── CollegeFootballDataProviding
│   ├── CollegeFootballHostEditorializing
│   └── DefaultCollegeFootballResultComposer
├── CollegeFootballSearchHomeView
├── CollegeFootballPlayerGalleryExperienceView
└── CollegeFootballDailyDropFullScreenView
```

`CollegeFootballOnboardingState` owns the selected program and player. The live roster adapter reads ESPN’s college-football roster response and merges featured Colorado legends into the demo program.

`CollegeFootballSearchEnvironment` orchestrates interpretation, planning, data retrieval, editorial copy, result composition, discovery navigation, sticker collection, and avatar state. Views do not invent facts.

The deterministic demo provider currently supports Colorado, Nebraska, Travis Hunter, Shedeur Sanders, Ashton Jeanty, and Charles Woodson. A production provider can replace the fixture layer without changing the presentation contracts.

The default Xcode scheme runs unit tests only. The `CollegeFootballCommishE2E` scheme contains the slower simulator smoke tests.
