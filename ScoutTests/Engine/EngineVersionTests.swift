import Testing
import Foundation
@testable import Scout

/// SemVer 2.0.0 §11 pre-release precedence. `isBehindBundled` (and so
/// `canUpdate`/`showsHandOff` in `EngineSettingsModel`) depends on this
/// ordering being numeric, not lexicographic — `"rc.9" < "rc.10"` is false
/// as strings but must be true as versions.
@Suite("EngineVersion")
struct EngineVersionTests {
    @Test func numericPreReleaseIdentifiersCompareNumerically() {
        #expect(EngineVersion("1.0.0-rc.9")! < EngineVersion("1.0.0-rc.10")!)
    }

    @Test func shorterIdentifierListSortsFirstWhenAllSharedPartsAreEqual() {
        #expect(EngineVersion("1.0.0-alpha")! < EngineVersion("1.0.0-alpha.1")!)
    }

    @Test func numericIdentifierSortsBeforeAlphanumeric() {
        #expect(EngineVersion("1.0.0-alpha.1")! < EngineVersion("1.0.0-alpha.beta")!)
    }

    @Test func alphanumericIdentifiersCompareInASCIIOrder() {
        #expect(EngineVersion("1.0.0-beta.11")! < EngineVersion("1.0.0-rc.1")!)
    }

    @Test func aReleaseSortsAfterAnyPreReleaseOfTheSameCore() {
        #expect(EngineVersion("1.0.0-rc.1")! < EngineVersion("1.0.0")!)
    }

    @Test func identicalPreReleasesAreEqualNotOrdered() {
        let a = EngineVersion("1.0.0-rc.1")!
        let b = EngineVersion("1.0.0-rc.1")!
        #expect(a == b)
        #expect(!(a < b))
        #expect(!(b < a))
    }

    /// Core `major.minor.patch` ordering is numeric, not lexicographic —
    /// `"0.9.0" < "0.10.0"` would be false as a plain string compare.
    @Test func coreVersionsCompareNumericallyNotLexicographically() {
        #expect(EngineVersion("0.9.0")! < EngineVersion("0.10.0")!)
        #expect(EngineVersion("0.10.0")! < EngineVersion("1.0.0")!)
    }

    /// `EngineRelease`/tag strings are `v`-prefixed; `EngineUpgrader.needsUpgrade`
    /// compares a bare installed version against a possibly `v`-prefixed one.
    @Test func aLeadingVPrefixParsesAndComparesEqualToTheBareVersion() {
        #expect(EngineVersion("v0.10.0") == EngineVersion("0.10.0"))
    }

    /// Non-SemVer-shaped strings fail to parse instead of crashing or
    /// silently truncating — `EngineUpgrader` relies on this `nil` to treat
    /// an unparsable manifest version as untrusted (Ruling 58).
    @Test func malformedOrTooShortStringsFailToParse() {
        #expect(EngineVersion("nope") == nil)
        #expect(EngineVersion("1.2") == nil)
    }
}
