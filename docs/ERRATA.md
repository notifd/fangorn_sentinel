# ERRATA - Bugs Found Through Actual Testing

This document tracks bugs found in Fangorn Sentinel through systematic validation testing following the huorn testing methodology.

**Methodology**: Write tests with real data, run them, keep only tests that found real bugs.

**Total Bugs Found**: 8

---

## Bug #1: Webhook accepts 1000+ alerts causing DoS

**Test**: `test/fangorn_sentinel_web/controllers/api/v1/webhook_controller_validation_test.exs:19`

**Severity**: 🔴 CRITICAL

**Failure**: Test created 1000-alert payload, webhook accepted all 1000 alerts (took 2.2 seconds to process), no limit enforced.

**Impact**: Attacker can flood system with unlimited alerts, causing:
- Database overflow
- Memory exhaustion
- Processing delays for legitimate alerts

**Root Cause**: No validation on alerts array size in `parse_grafana_webhook/1`

**Fix Needed**: Add max alerts limit (e.g., 100):
```elixir
defp parse_grafana_webhook(%{"alerts" => alerts})
    when is_list(alerts) and length(alerts) <= 100 do
```

---

## Bug #2: Webhook accepts huge title strings (resource exhaustion)

**Test**: `test/fangorn_sentinel_web/controllers/api/v1/webhook_controller_validation_test.exs:38`

**Severity**: 🔴 CRITICAL

**Failure**: Test sent 10MB alert title, webhook accepted it and tried to store in database (crashed with heap overflow).

**Impact**:
- Server memory exhaustion
- Database storage bloat
- DoS attack vector

**Root Cause**: No length validation on title field

**Fix Needed**: Validate title length before processing:
```elixir
|> validate_length(:title, max: 1000)
```

---

## Bug #3: Null bytes cause PostgreSQL encoding error (crashes)

**Test**: `test/fangorn_sentinel_web/controllers/api/v1/webhook_controller_validation_test.exs:57`

**Severity**: 🔴 CRITICAL - Server crash

**Failure**:
```
** (Postgrex.Error) ERROR 22021 (character_not_in_repertoire)
invalid byte sequence for encoding "UTF8": 0x00
```

**Impact**:
- Server crash on webhook with null bytes
- Complete service disruption
- No error recovery

**Root Cause**: PostgreSQL UTF8 encoding doesn't allow null bytes, but we don't sanitize input

**Fix Needed**: Strip null bytes before storing:
```elixir
def sanitize_string(str) when is_binary(str) do
  String.replace(str, <<0>>, "")
end
```

---

## Bug #4: labels as string instead of map causes BadMapError crash

**Test**: `test/fangorn_sentinel_web/controllers/api/v1/webhook_controller_validation_test.exs:137`

**Severity**: 🔴 CRITICAL - Server crash

**Failure**:
```
** (BadMapError) expected a map, got: "not-a-map"
```

**Impact**:
- Server crashes on malformed webhook
- No graceful degradation
- Service disruption

**Root Cause**: `Map.get(alert, "labels", %{})` assumes labels exists and doesn't validate type

**Fix Needed**: Validate types before accessing:
```elixir
labels = Map.get(alert, "labels", %{})
labels = if is_map(labels), do: labels, else: %{}
```

---

## Bug #5: Webhook accepts timestamps 100 years in past

**Test**: `test/fangorn_sentinel_web/controllers/api/v1/webhook_controller_validation_test.exs:83`

**Severity**: 🟠 HIGH - Data integrity

**Failure**: Webhook accepted alert with `startsAt: "1925-01-01"`, stored alert with `fired_at` 36,863 days ago

**Impact**:
- Alerts with impossible timestamps
- Broken sorting (old alerts appear first)
- UI confusion
- Audit trail corruption

**Root Cause**: `parse_timestamp/1` accepts any valid ISO8601, no reasonableness check

**Fix Needed**: Validate timestamp is recent:
```elixir
def validate_timestamp(datetime) do
  days_diff = Date.diff(Date.utc_today(), DateTime.to_date(datetime))
  if days_diff > 7 or days_diff < -1 do
    {:error, :invalid_timestamp}
  else
    {:ok, datetime}
  end
end
```

---

## Bug #6: Webhook accepts timestamps 10 years in future

**Test**: `test/fangorn_sentinel_web/controllers/api/v1/webhook_controller_validation_test.exs:110`

**Severity**: 🟠 HIGH - Data integrity

**Failure**: Webhook accepted alert with timestamp 10 years in future (3650 days), stored successfully

**Impact**:
- Future-dated alerts don't appear in current view
- Confusion about when alert actually fired
- Can't distinguish real vs test data

**Root Cause**: Same as Bug #5 - no timestamp validation

**Fix Needed**: Same as Bug #5

---

## Bug #7: Email validation accepts control characters

**Test**: `test/fangorn_sentinel/accounts/user_validation_test.exs:33`

**Severity**: 🔴 CRITICAL - Security

**Failure**: Email with SOH character (`\u0001`) passed validation

**Impact**:
- Email header injection attack vector
- Can inject BCC/CC headers
- Security vulnerability

**Root Cause**: Regex `~r/^[^\s]+@[^\s]+$/` only blocks whitespace, not control characters

**Fix Needed**: Block all control characters:
```elixir
validate_format(:email, ~r/^[^\s\x00-\x1F\x7F]+@[^\s\x00-\x1F\x7F]+$/)
```

---

## Bug #8: Email validation accepts null byte

**Test**: `test/fangorn_sentinel/accounts/user_validation_test.exs:13`

**Severity**: 🔴 CRITICAL - Security

**Failure**: Email `"test\u0000@example.com"` passed validation

**Impact**:
- Null byte injection attack
- Email header injection
- Can terminate strings early in C libraries
- Security vulnerability

**Root Cause**: Same as Bug #7 - regex doesn't block null bytes

**Fix Needed**: Same as Bug #7

---

## Summary

**Bugs by Severity**:
- 🔴 CRITICAL: 6 (75%) - 4 crashes, 2 security vulnerabilities
- 🟠 HIGH: 2 (25%) - Data integrity issues

**Bugs by Category**:
- Server crashes: 4 (50%)
- Security vulnerabilities: 2 (25%)
- Data integrity: 2 (25%)

**Tests Results**:
- Webhook validation: 7 tests, 6 found bugs (86% hit rate)
- User validation: 9 tests, 2 found bugs (22% hit rate)
- **Total: 16 tests, 8 found real bugs (50% hit rate)**

**Methodology Success**:
This demonstrates the power of validation testing - EVERY bug found was discovered by testing that **invalid input should be rejected**. None of these would be found by "happy path" tests.

**Next Steps**:
1. Fix all CRITICAL bugs (crashes and security)
2. Fix HIGH bugs (data integrity)
3. Update tests with "FAILURES FOUND: N" counts
4. Continue writing more validation tests for other modules

---

**Date**: 2025-12-04
**Testing Methodology**: huorn/docs/TESTING.md
**Tests Written**: 16
**Bugs Found**: 8
