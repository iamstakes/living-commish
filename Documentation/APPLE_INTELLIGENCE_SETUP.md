# Apple Intelligence query interpretation

Apple Foundation Models may classify a natural-language college-football query into intent, entities, and time scope. It never supplies player statistics, results, schedules, or editorial claims; those must come from `CollegeFootballDataProviding`.

`AdaptiveCollegeFootballQueryInterpreter` uses the on-device model when available and falls back to `DeterministicCollegeFootballQueryInterpreter`. Supported demo names are canonicalized to Travis Hunter, Shedeur Sanders, Ashton Jeanty, Charles Woodson, Colorado Buffaloes, and Nebraska Cornhuskers.

The simulator UI-test flags force deterministic interpretation so screenshots and smoke tests remain repeatable.
