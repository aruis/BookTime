import Foundation
import XCTest
@testable import BookTime

final class TimerSessionLogicTests: XCTestCase {
    func testAddedMinutesStaysZeroBeforeFullMinute() {
        let beginDate = Date(timeIntervalSince1970: 1_710_000_000)
        let now = beginDate.addingTimeInterval(59)

        let elapsedMinutes = TimerSessionLogic.elapsedMinutes(since: beginDate, now: now)
        let addedMinutes = TimerSessionLogic.addedMinutes(elapsedMinutes: elapsedMinutes, persistedSessionMinutes: 0)

        XCTAssertEqual(elapsedMinutes, 0)
        XCTAssertEqual(addedMinutes, 0)
    }

    func testAddedMinutesBecomesOneAfterFullMinute() {
        let beginDate = Date(timeIntervalSince1970: 1_710_000_000)
        let now = beginDate.addingTimeInterval(61)

        let elapsedMinutes = TimerSessionLogic.elapsedMinutes(since: beginDate, now: now)
        let addedMinutes = TimerSessionLogic.addedMinutes(elapsedMinutes: elapsedMinutes, persistedSessionMinutes: 0)

        XCTAssertEqual(elapsedMinutes, 1)
        XCTAssertEqual(addedMinutes, 1)
    }

    func testPendingMinutesUsesPersistedSessionMinutesInsteadOfTodayTotal() {
        let beginDate = Date(timeIntervalSince1970: 1_710_000_000)
        let now = beginDate.addingTimeInterval(125)

        let pendingMinutes = TimerSessionLogic.pendingMinutes(
            since: beginDate,
            now: now,
            persistedSessionMinutes: 1
        )

        XCTAssertEqual(pendingMinutes, 1)
    }

    func testCrossingMidnightTriggersDayChange() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

        let beforeMidnight = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 15,
            hour: 23,
            minute: 59,
            second: 30
        ))!
        let afterMidnight = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 16,
            hour: 0,
            minute: 0,
            second: 30
        ))!

        let activeLogDay = TimerSessionLogic.activeLogDay(for: beforeMidnight, calendar: calendar)

        XCTAssertTrue(TimerSessionLogic.didDayChange(activeLogDay: activeLogDay, now: afterMidnight, calendar: calendar))
        XCTAssertEqual(TimerSessionLogic.activeLogDay(for: afterMidnight, calendar: calendar), calendar.startOfDay(for: afterMidnight))
    }

    func testGoalHitDependsOnCurrentDayReadMinutes() {
        XCTAssertTrue(TimerSessionLogic.isGoalHit(targetMinutesPerDay: 45, readMinutes: 45))
        XCTAssertFalse(TimerSessionLogic.isGoalHit(targetMinutesPerDay: 45, readMinutes: 0))
        XCTAssertFalse(TimerSessionLogic.isGoalHit(targetMinutesPerDay: 0, readMinutes: 120))
    }
}
