#!/usr/bin/env python3
"""Regenerates the recurrence fixture files in fixtures/recurrence/*.json.

Expected values come from independent oracles, never from the Dart engine:
  * python-dateutil (rrule/rruleset) for everything RFC 5545 can express,
  * small brute-force Python loops for Everslot extensions (windows,
    month-day clamping, quotas, after-completion),
  * zoneinfo (system IANA database) for UTC instants: fold=0 gives the RFC 5545
    behaviour (gap -> offset before the gap, overlap -> earlier instant).

Usage: python3 fixtures/recurrence/tool/generate_fixtures.py
Requires python >= 3.9 and python-dateutil >= 2.8.
"""

import calendar
import datetime as dt
import json
import math
import os
from zoneinfo import ZoneInfo

from dateutil import rrule as R

UTC = dt.timezone.utc
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
WD = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU']
WEEKDAYS = [{'day': d} for d in WD[:5]]
FREQ = {'yearly': R.YEARLY, 'monthly': R.MONTHLY, 'weekly': R.WEEKLY, 'daily': R.DAILY,
        'hourly': R.HOURLY, 'minutely': R.MINUTELY}


def P(s):
    return dt.datetime.strptime(s, '%Y-%m-%dT%H:%M')


def D(s):
    return dt.datetime.strptime(s, '%Y-%m-%d')


def key(w, all_day=False):
    return w.strftime('%Y-%m-%d') if all_day else w.strftime('%Y-%m-%dT%H:%M')


def to_utc(naive, zone):
    return naive.replace(tzinfo=ZoneInfo(zone), fold=0).astimezone(UTC)


def utc_str(d):
    return d.strftime('%Y-%m-%dT%H:%MZ')


def local_from_utc(utc_string, zone):
    u = dt.datetime.strptime(utc_string, '%Y%m%dT%H%M%SZ').replace(tzinfo=UTC)
    return u.astimezone(ZoneInfo(zone)).replace(tzinfo=None)


def rule_json(**kw):
    """Builds a rule JSON object in schema order (omitting None)."""
    order = ['type', 'freq', 'interval', 'byWeekday', 'byMonthDay', 'byMonth', 'byYearDay', 'byWeekNo',
             'bySetPos', 'byHour', 'byMinute', 'times', 'window', 'wkst', 'until', 'count', 'countMode',
             'monthDayOverflow', 'exdates', 'rdates', 'afterCompletion', 'quota']
    out = {'v': 1, 'type': kw.pop('type', 'fixed')}
    if out['type'] == 'fixed':
        out['freq'] = kw.pop('freq', 'daily')
        out['interval'] = kw.pop('interval', 1)
    for k in order:
        if k in kw and kw[k] is not None:
            out[k] = kw[k]
    unknown = set(kw) - set(order)
    assert not unknown, unknown
    return out


# ---------------------------------------------------------------------------
# Oracles.

def dateutil_series(rule, start, lo, hi):
    """Wall-clock series (naive datetimes) in [lo, hi] via python-dateutil."""
    kw = {'dtstart': start, 'interval': rule.get('interval', 1), 'bysecond': 0}
    if 'wkst' in rule:
        kw['wkst'] = WD.index(rule['wkst'])
    if 'count' in rule:
        kw['count'] = rule['count']
    if 'until' in rule:
        kw['until'] = P(rule['until'])
    for src, dst in [('byMonth', 'bymonth'), ('byMonthDay', 'bymonthday'), ('byYearDay', 'byyearday'),
                     ('byWeekNo', 'byweekno'), ('bySetPos', 'bysetpos'), ('byHour', 'byhour'),
                     ('byMinute', 'byminute')]:
        if src in rule:
            kw[dst] = rule[src]
    if 'byWeekday' in rule:
        days = []
        for w in rule['byWeekday']:
            wd = R.weekday(WD.index(w['day']))
            days.append(wd(w['n']) if w.get('n') else wd)
        kw['byweekday'] = days
    if 'times' in rule:
        hours = sorted({int(t[:2]) for t in rule['times']})
        minutes = sorted({int(t[3:]) for t in rule['times']})
        assert len(hours) * len(minutes) == len(set(rule['times'])), 'times must be a cross product'
        kw['byhour'] = hours
        kw['byminute'] = minutes
    rs = R.rruleset()
    rs.rrule(R.rrule(FREQ[rule['freq']], **kw))
    day_exdates = set()
    for ex in rule.get('exdates', []):
        if 'T' in ex:
            rs.exdate(P(ex))
        else:
            day_exdates.add(ex)
    for rd in rule.get('rdates', []):
        rs.rdate(P(rd) if 'T' in rd else D(rd).replace(hour=start.hour, minute=start.minute))
    return [w for w in rs.between(lo, hi, inc=True) if w.strftime('%Y-%m-%d') not in day_exdates]


def apply_sets(walls, rule, start, all_day=False):
    """Adds rdates / removes exdates for brute-force oracles (walls: rule output)."""
    walls = set(walls)
    for rd in rule.get('rdates', []):
        walls.add(P(rd) if 'T' in rd else D(rd).replace(hour=0 if all_day else start.hour,
                                                         minute=0 if all_day else start.minute))
    out = []
    for w in sorted(walls):
        if key(w) in rule.get('exdates', []) or w.strftime('%Y-%m-%d') in rule.get('exdates', []):
            continue
        out.append(w)
    return out


def bound(walls, rule):
    """Applies until (inclusive) and count to a sorted rule-generated list."""
    if 'until' in rule:
        walls = [w for w in walls if w <= P(rule['until'])]
    if 'count' in rule and rule.get('countMode', 'occurrences') == 'occurrences':
        walls = walls[:rule['count']]
    return walls


def day_ok(rule, day):
    """Day-level limits (byWeekday plain, byMonth, byMonthDay) for sub-daily oracles."""
    if 'byWeekday' in rule and WD[day.weekday()] not in [w['day'] for w in rule['byWeekday']]:
        return False
    if 'byMonth' in rule and day.month not in rule['byMonth']:
        return False
    if 'byMonthDay' in rule:
        dim = calendar.monthrange(day.year, day.month)[1]
        if day.day not in rule['byMonthDay'] and day.day - dim - 1 not in rule['byMonthDay']:
            return False
    return True


def window_series(rule, start, hi):
    """Brute force for minutely/hourly rules with a window (both anchors)."""
    step = rule['interval'] * (60 if rule['freq'] == 'hourly' else 1)
    ws = int(rule['window']['start'][:2]) * 60 + int(rule['window']['start'][3:])
    end = rule['window']['end']
    we = 1439 if end == '24:00' else int(end[:2]) * 60 + int(end[3:])
    hours = rule.get('byHour')
    walls = []
    if rule['window'].get('anchor', 'window_start') == 'window_start':
        day = start.replace(hour=0, minute=0)
        while day <= hi:
            if day_ok(rule, day):
                t = ws
                while t <= we:
                    w = day + dt.timedelta(minutes=t)
                    if w >= start and (hours is None or w.hour in hours):
                        walls.append(w)
                    t += step
            day += dt.timedelta(days=1)
    else:
        w = start
        while w <= hi:
            tod = w.hour * 60 + w.minute
            if day_ok(rule, w) and ws <= tod <= we and (hours is None or w.hour in hours):
                walls.append(w)
            w += dt.timedelta(minutes=step)
    return walls


def chain_series(rule, start, hi):
    """Brute force for minutely/hourly chains without window (limits only)."""
    step = rule['interval'] * (60 if rule['freq'] == 'hourly' else 1)
    walls = []
    w = start
    while w <= hi:
        if day_ok(rule, w) and ('byHour' not in rule or w.hour in rule['byHour']) and \
                ('byMinute' not in rule or w.minute in rule['byMinute']):
            walls.append(w)
        w += dt.timedelta(minutes=step)
    return walls


def clamp_series(rule, start, hi):
    """Monthly / yearly rules with monthDayOverflow = clamp (no other BYxxx)."""
    walls = []
    interval = rule['interval']
    days = rule.get('byMonthDay', [start.day])
    if rule['freq'] == 'monthly':
        k = 0
        while True:
            idx = start.year * 12 + start.month - 1 + k * interval
            y, m = divmod(idx, 12)
            m += 1
            if dt.datetime(y, m, 1) > hi:
                break
            dim = calendar.monthrange(y, m)[1]
            picked = set()
            for d in days:
                real = d if d > 0 else dim + d + 1
                picked.add(min(max(real, 1), dim))
            for d in sorted(picked):
                w = dt.datetime(y, m, d, start.hour, start.minute)
                if w >= start:
                    walls.append(w)
            k += 1
    else:  # yearly on the anchor's month/day
        y = start.year
        while dt.datetime(y, 1, 1) <= hi:
            dim = calendar.monthrange(y, start.month)[1]
            w = dt.datetime(y, start.month, min(start.day, dim), start.hour, start.minute)
            if w >= start:
                walls.append(w)
            y += interval
    return bound(walls, rule)


# ---------------------------------------------------------------------------
# Case assembly.

ALL = {}


def add(file, name, rule, start, zone, frm, to, *, eval_zone=None, walls=None, oracle='dateutil',
        all_day=False, duration=None, with_utc=False, notes=None, limit=None, keys=None):
    start_dt = P(start)
    exp_zone = zone or eval_zone or 'UTC'
    view_zone = eval_zone or zone or 'UTC'
    lo = P(frm) - dt.timedelta(days=3)
    hi = P(to) + dt.timedelta(days=3)
    if keys is None:
        if walls is None:
            if oracle == 'dateutil':
                walls = dateutil_series(rule, start_dt.replace(hour=0, minute=0) if all_day else start_dt, lo, hi)
            elif oracle == 'window':
                walls = apply_sets(bound(window_series(rule, start_dt, hi), rule), rule, start_dt)
            elif oracle == 'chain':
                walls = apply_sets(bound(chain_series(rule, start_dt, hi), rule), rule, start_dt)
            elif oracle == 'clamp':
                walls = apply_sets(clamp_series(rule, start_dt, hi), rule, start_dt)
            else:
                raise ValueError(oracle)
        dur = duration if duration is not None else (1440 if all_day else 0)
        selected = []
        if all_day:
            days = max(1, math.ceil(dur / 1440))
            seen = set()
            for w in walls:
                d0 = w.replace(hour=0, minute=0)
                if d0 in seen:
                    continue
                seen.add(d0)
                if d0 < P(to) and d0 + dt.timedelta(days=days) > P(frm):
                    selected.append(d0)
        else:
            f = to_utc(P(frm), view_zone)
            u = to_utc(P(to), view_zone)
            for w in walls:
                s = to_utc(w, exp_zone)
                if s < u and (s >= f if dur == 0 else s + dt.timedelta(minutes=dur) > f):
                    selected.append(w)
        if limit is not None:
            selected = selected[:limit]
        keys = [key(w, all_day) for w in selected]
        utcs = [utc_str(to_utc(w, exp_zone)) for w in selected]
    else:
        utcs = None
    anchor = {'start': start, 'zone': zone}
    if all_day:
        anchor['allDay'] = True
    case = {'name': name, 'rule': rule, 'anchor': anchor, 'evalZone': eval_zone,
            'range': {'from': frm, 'to': to}}
    if duration is not None:
        case['durationMinutes'] = duration
    if limit is not None:
        case['limit'] = limit
    case['expectedKeys'] = keys
    if with_utc and utcs is not None:
        case['expectedUtc'] = utcs
    if notes:
        case['notes'] = notes
    ALL.setdefault(file, []).append(case)
    return case


NY = 'America/New_York'


def rfc_until(utc_string, zone=NY):
    return local_from_utc(utc_string, zone).strftime('%Y-%m-%dT%H:%M')


# ---------------------------------------------------------------------------
# RFC 5545 §3.8.5.3 examples (DTSTART;TZID=America/New_York).

def rfc_examples():
    f = 'rfc5545_examples'
    s = '1997-09-02T09:00'
    add(f, 'RFC: daily for 10 occurrences', rule_json(freq='daily', count=10), s, NY, s, '1998-01-01T00:00', with_utc=True)
    add(f, 'RFC: daily until December 24, 1997', rule_json(freq='daily', until=rfc_until('19971224T000000Z')),
        s, NY, s, '1998-01-01T00:00', notes='UNTIL=19971224T000000Z converted to New York wall time')
    add(f, 'RFC: every other day, forever', rule_json(freq='daily', interval=2), s, NY, s, '1997-12-01T00:00')
    add(f, 'RFC: every 10 days, 5 occurrences', rule_json(freq='daily', interval=10, count=5), s, NY, s,
        '1998-01-01T00:00')
    add(f, 'RFC: every day in January for 3 years (yearly)',
        rule_json(freq='yearly', byWeekday=[{'day': d} for d in ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']],
                  byMonth=[1], until=rfc_until('20000131T140000Z')),
        '1998-01-01T09:00', NY, '1998-01-01T00:00', '2001-01-01T00:00')
    add(f, 'RFC: every day in January for 3 years (daily)',
        rule_json(freq='daily', byMonth=[1], until=rfc_until('20000131T140000Z')),
        '1998-01-01T09:00', NY, '1998-01-01T00:00', '2001-01-01T00:00')
    add(f, 'RFC: weekly for 10 occurrences', rule_json(freq='weekly', count=10), s, NY, s, '1998-06-01T00:00',
        with_utc=True)
    add(f, 'RFC: weekly until December 24, 1997', rule_json(freq='weekly', until=rfc_until('19971224T000000Z')),
        s, NY, s, '1998-06-01T00:00')
    add(f, 'RFC: every other week, forever (WKST=SU)', rule_json(freq='weekly', interval=2, wkst='SU'), s, NY, s,
        '1998-03-01T00:00')
    add(f, 'RFC: weekly on Tuesday and Thursday for five weeks (until)',
        rule_json(freq='weekly', byWeekday=[{'day': 'TU'}, {'day': 'TH'}], wkst='SU',
                  until=rfc_until('19971007T000000Z')), s, NY, s, '1998-01-01T00:00')
    add(f, 'RFC: weekly on Tuesday and Thursday for five weeks (count)',
        rule_json(freq='weekly', byWeekday=[{'day': 'TU'}, {'day': 'TH'}], wkst='SU', count=10), s, NY, s,
        '1998-01-01T00:00')
    add(f, 'RFC: every other week on MO, WE, FR until December 24, 1997',
        rule_json(freq='weekly', interval=2, byWeekday=[{'day': 'MO'}, {'day': 'WE'}, {'day': 'FR'}], wkst='SU',
                  until=rfc_until('19971224T000000Z')), '1997-09-01T09:00', NY, '1997-09-01T00:00',
        '1998-01-01T00:00')
    add(f, 'RFC: every other week on TU and TH, for 8 occurrences',
        rule_json(freq='weekly', interval=2, byWeekday=[{'day': 'TU'}, {'day': 'TH'}], wkst='SU', count=8), s, NY,
        s, '1998-01-01T00:00')
    add(f, 'RFC: monthly on the first Friday for 10 occurrences',
        rule_json(freq='monthly', byWeekday=[{'day': 'FR', 'n': 1}], count=10), '1997-09-05T09:00', NY,
        '1997-09-01T00:00', '1998-12-01T00:00', with_utc=True)
    add(f, 'RFC: monthly on the first Friday until December 24, 1997',
        rule_json(freq='monthly', byWeekday=[{'day': 'FR', 'n': 1}], until=rfc_until('19971224T000000Z')),
        '1997-09-05T09:00', NY, '1997-09-01T00:00', '1998-12-01T00:00')
    add(f, 'RFC: every other month on the first and last Sunday, 10 occurrences',
        rule_json(freq='monthly', interval=2, byWeekday=[{'day': 'SU', 'n': 1}, {'day': 'SU', 'n': -1}], count=10),
        '1997-09-07T09:00', NY, '1997-09-01T00:00', '1999-12-01T00:00')
    add(f, 'RFC: monthly on the second-to-last Monday for 6 months',
        rule_json(freq='monthly', byWeekday=[{'day': 'MO', 'n': -2}], count=6), '1997-09-22T09:00', NY,
        '1997-09-01T00:00', '1998-12-01T00:00')
    add(f, 'RFC: monthly on the third-to-the-last day, forever', rule_json(freq='monthly', byMonthDay=[-3]),
        '1997-09-28T09:00', NY, '1997-09-01T00:00', '1998-03-01T00:00')
    add(f, 'RFC: monthly on the 2nd and 15th for 10 occurrences',
        rule_json(freq='monthly', byMonthDay=[2, 15], count=10), s, NY, s, '1999-01-01T00:00')
    add(f, 'RFC: monthly on the first and last day for 10 occurrences',
        rule_json(freq='monthly', byMonthDay=[1, -1], count=10), '1997-09-30T09:00', NY, '1997-09-01T00:00',
        '1999-01-01T00:00')
    add(f, 'RFC: every 18 months on the 10th thru 15th, 10 occurrences',
        rule_json(freq='monthly', interval=18, byMonthDay=[10, 11, 12, 13, 14, 15], count=10),
        '1997-09-10T09:00', NY, '1997-09-01T00:00', '2000-01-01T00:00')
    add(f, 'RFC: every Tuesday, every other month', rule_json(freq='monthly', interval=2, byWeekday=[{'day': 'TU'}]),
        s, NY, s, '1998-04-01T00:00')
    add(f, 'RFC: yearly in June and July for 10 occurrences', rule_json(freq='yearly', byMonth=[6, 7], count=10),
        '1997-06-10T09:00', NY, '1997-01-01T00:00', '2003-01-01T00:00')
    add(f, 'RFC: every other year on January, February and March, 10 occurrences',
        rule_json(freq='yearly', interval=2, byMonth=[1, 2, 3], count=10), '1997-03-10T09:00', NY,
        '1997-01-01T00:00', '2004-01-01T00:00')
    add(f, 'RFC: every third year on the 1st, 100th and 200th day, 10 occurrences',
        rule_json(freq='yearly', interval=3, byYearDay=[1, 100, 200], count=10), '1997-01-01T09:00', NY,
        '1997-01-01T00:00', '2010-01-01T00:00')
    add(f, 'RFC: every 20th Monday of the year, forever', rule_json(freq='yearly', byWeekday=[{'day': 'MO', 'n': 20}]),
        '1997-05-19T09:00', NY, '1997-01-01T00:00', '2000-01-01T00:00')
    add(f, 'RFC: Monday of week number 20, forever',
        rule_json(freq='yearly', byWeekNo=[20], byWeekday=[{'day': 'MO'}]), '1997-05-12T09:00', NY,
        '1997-01-01T00:00', '2000-01-01T00:00')
    add(f, 'RFC: every Thursday in March, forever', rule_json(freq='yearly', byMonth=[3], byWeekday=[{'day': 'TH'}]),
        '1997-03-13T09:00', NY, '1997-01-01T00:00', '2000-01-01T00:00')
    add(f, 'RFC: every Thursday during June, July and August, forever',
        rule_json(freq='yearly', byWeekday=[{'day': 'TH'}], byMonth=[6, 7, 8]), '1997-06-05T09:00', NY,
        '1997-01-01T00:00', '1999-01-01T00:00')
    add(f, 'RFC: every Friday the 13th, forever',
        rule_json(freq='monthly', byWeekday=[{'day': 'FR'}], byMonthDay=[13]), s, NY, s, '2001-01-01T00:00',
        notes='The RFC excludes DTSTART with EXDATE; Everslot never force-includes the anchor.')
    add(f, 'RFC: first Saturday that follows the first Sunday of the month',
        rule_json(freq='monthly', byWeekday=[{'day': 'SA'}], byMonthDay=[7, 8, 9, 10, 11, 12, 13]),
        '1997-09-13T09:00', NY, '1997-09-01T00:00', '1998-07-01T00:00')
    add(f, 'RFC: US presidential election day, every 4 years',
        rule_json(freq='yearly', interval=4, byMonth=[11], byWeekday=[{'day': 'TU'}], byMonthDay=[2, 3, 4, 5, 6, 7, 8]),
        '1996-11-05T09:00', NY, '1996-01-01T00:00', '2010-01-01T00:00')
    add(f, 'RFC: third instance of TU, WE or TH for the next 3 months',
        rule_json(freq='monthly', byWeekday=[{'day': 'TU'}, {'day': 'WE'}, {'day': 'TH'}], bySetPos=[3], count=3),
        '1997-09-04T09:00', NY, '1997-09-01T00:00', '1998-01-01T00:00')
    add(f, 'RFC: second-to-last weekday of the month',
        rule_json(freq='monthly', byWeekday=WEEKDAYS, bySetPos=[-2]), '1997-09-29T09:00', NY,
        '1997-09-01T00:00', '1998-07-01T00:00')
    add(f, 'RFC: every 3 hours from 09:00 to 17:00 on a specific day',
        rule_json(freq='hourly', interval=3, until='1997-09-02T17:00'), s, NY, s, '1997-09-03T00:00',
        notes='The RFC text lists 09:00, 12:00, 15:00; UNTIL is given as local 17:00 here.')
    add(f, 'RFC: every 15 minutes for 6 occurrences', rule_json(freq='minutely', interval=15, count=6), s, NY, s,
        '1997-09-03T00:00')
    add(f, 'RFC: every hour and a half for 4 occurrences', rule_json(freq='minutely', interval=90, count=4), s, NY,
        s, '1997-09-03T00:00')
    add(f, 'RFC: every 20 minutes from 09:00 to 16:40 every day (daily)',
        rule_json(freq='daily', byHour=[9, 10, 11, 12, 13, 14, 15, 16], byMinute=[0, 20, 40]), s, NY, s,
        '1997-09-04T00:00')
    add(f, 'RFC: every 20 minutes from 09:00 to 16:40 every day (minutely)',
        rule_json(freq='minutely', interval=20, byHour=[9, 10, 11, 12, 13, 14, 15, 16]), s, NY, s,
        '1997-09-04T00:00')
    add(f, 'RFC: WKST=MO changes the generated days',
        rule_json(freq='weekly', interval=2, count=4, byWeekday=[{'day': 'TU'}, {'day': 'SU'}], wkst='MO'),
        '1997-08-05T09:00', NY, '1997-08-01T00:00', '1997-10-01T00:00')
    add(f, 'RFC: WKST=SU changes the generated days',
        rule_json(freq='weekly', interval=2, count=4, byWeekday=[{'day': 'TU'}, {'day': 'SU'}], wkst='SU'),
        '1997-08-05T09:00', NY, '1997-08-01T00:00', '1997-10-01T00:00')
    add(f, 'RFC: invalid date (February 30) is ignored',
        rule_json(freq='monthly', byMonthDay=[15, 30], count=5), '2007-01-15T09:00', NY, '2007-01-01T00:00',
        '2008-01-01T00:00')
    add(f, 'RFC: yearly (anchor month and day) for 3 years crossing DST',
        rule_json(freq='yearly', count=3), '1997-09-02T09:00', NY, '1997-01-01T00:00', '2001-01-01T00:00',
        with_utc=True)


# ---------------------------------------------------------------------------
# Calendar rules (daily / weekly / monthly / yearly).

def calendar_rules():
    f = 'calendar_rules'
    P_ = 'Europe/Paris'
    add(f, 'every Monday and Tuesday', rule_json(freq='weekly', byWeekday=[{'day': 'MO'}, {'day': 'TU'}]),
        '2026-09-21T08:00', P_, '2026-09-01T00:00', '2026-10-20T00:00')
    add(f, 'every 2 days', rule_json(freq='daily', interval=2), '2026-09-21T07:30', P_, '2026-09-01T00:00',
        '2026-10-10T00:00')
    add(f, 'every 3 days, range starting mid-series', rule_json(freq='daily', interval=3), '2026-01-01T12:00', P_,
        '2026-06-01T00:00', '2026-06-20T00:00')
    add(f, 'weekdays (daily with weekday limit)', rule_json(freq='daily', byWeekday=WEEKDAYS), '2026-09-21T09:00',
        P_, '2026-09-19T00:00', '2026-10-05T00:00')
    add(f, 'weekends (weekly)', rule_json(freq='weekly', byWeekday=[{'day': 'SA'}, {'day': 'SU'}]),
        '2026-09-26T10:00', P_, '2026-09-20T00:00', '2026-10-20T00:00')
    add(f, 'weekly on the anchor weekday (default)', rule_json(freq='weekly'), '2026-09-23T18:00', P_,
        '2026-09-01T00:00', '2026-11-15T00:00')
    for wkst in ['MO', 'SA', 'SU']:
        add(f, f'every 2 weeks on TU, SA, SU with WKST={wkst}',
            rule_json(freq='weekly', interval=2, byWeekday=[{'day': 'TU'}, {'day': 'SA'}, {'day': 'SU'}], wkst=wkst),
            '2026-09-22T09:00', 'UTC', '2026-09-20T00:00', '2026-11-10T00:00')
    for wkst in ['MO', 'SA', 'SU']:
        add(f, f'every 3 weeks on FR, SA, SU, MO with WKST={wkst}',
            rule_json(freq='weekly', interval=3,
                      byWeekday=[{'day': 'FR'}, {'day': 'SA'}, {'day': 'SU'}, {'day': 'MO'}], wkst=wkst),
            '2026-10-02T20:00', 'UTC', '2026-10-01T00:00', '2026-12-31T00:00')
    add(f, 'monthly on day 31 (skip)', rule_json(freq='monthly', byMonthDay=[31]), '2026-01-31T09:00', P_,
        '2026-01-01T00:00', '2027-01-01T00:00')
    add(f, 'monthly on day 31 (clamp)', rule_json(freq='monthly', byMonthDay=[31], monthDayOverflow='clamp'),
        '2026-01-31T09:00', P_, '2026-01-01T00:00', '2027-01-01T00:00', oracle='clamp')
    add(f, 'monthly from an anchor on the 31st (skip, default day)', rule_json(freq='monthly'),
        '2026-01-31T09:00', P_, '2026-01-01T00:00', '2026-12-01T00:00')
    add(f, 'monthly from an anchor on the 31st (clamp, default day)',
        rule_json(freq='monthly', monthDayOverflow='clamp'), '2026-01-31T09:00', P_, '2026-01-01T00:00',
        '2026-12-01T00:00', oracle='clamp')
    add(f, 'monthly on the 29th and 30th (clamp dedupes February)',
        rule_json(freq='monthly', byMonthDay=[29, 30], monthDayOverflow='clamp'), '2026-01-29T09:00', P_,
        '2026-01-01T00:00', '2026-05-01T00:00', oracle='clamp')
    add(f, 'every 2 months on day 30 (clamp) across a leap February',
        rule_json(freq='monthly', interval=2, byMonthDay=[30], monthDayOverflow='clamp'), '2023-12-30T08:00', P_,
        '2023-12-01T00:00', '2025-01-01T00:00', oracle='clamp')
    add(f, 'yearly on February 29 (skip)', rule_json(freq='yearly'), '2024-02-29T10:00', P_, '2024-01-01T00:00',
        '2033-01-01T00:00')
    add(f, 'yearly on February 29 (clamp to the 28th)', rule_json(freq='yearly', monthDayOverflow='clamp'),
        '2024-02-29T10:00', P_, '2024-01-01T00:00', '2030-01-01T00:00', oracle='clamp')
    add(f, 'every 4 years on February 29 across 2100 (not a leap year)', rule_json(freq='yearly', interval=4),
        '2092-02-29T10:00', 'UTC', '2092-01-01T00:00', '2110-01-01T00:00')
    add(f, 'monthly on the 2nd Tuesday', rule_json(freq='monthly', byWeekday=[{'day': 'TU', 'n': 2}]),
        '2026-01-13T19:00', P_, '2026-01-01T00:00', '2026-12-31T00:00')
    add(f, 'monthly on the last Friday', rule_json(freq='monthly', byWeekday=[{'day': 'FR', 'n': -1}]),
        '2026-01-30T17:00', P_, '2026-01-01T00:00', '2026-12-31T00:00')
    add(f, 'monthly on the 5th Monday (only some months)', rule_json(freq='monthly', byWeekday=[{'day': 'MO', 'n': 5}]),
        '2026-01-01T09:00', 'UTC', '2026-01-01T00:00', '2027-01-01T00:00')
    add(f, 'monthly on the last day', rule_json(freq='monthly', byMonthDay=[-1]), '2026-01-31T23:00', P_,
        '2026-01-01T00:00', '2027-01-01T00:00')
    add(f, 'monthly on the second-to-last day', rule_json(freq='monthly', byMonthDay=[-2]), '2024-01-30T08:00', P_,
        '2024-01-01T00:00', '2024-12-31T00:00')
    add(f, 'monthly on day -31 (only 31-day months)', rule_json(freq='monthly', byMonthDay=[-31]),
        '2026-01-01T08:00', 'UTC', '2026-01-01T00:00', '2027-01-01T00:00')
    add(f, 'monthly on the last weekday, 10 times', rule_json(freq='monthly', byWeekday=WEEKDAYS, bySetPos=[-1],
                                                                count=10),
        '2026-01-01T09:00', P_, '2026-01-01T00:00', '2027-12-31T00:00')
    add(f, 'monthly on the first weekday', rule_json(freq='monthly', byWeekday=WEEKDAYS, bySetPos=[1]),
        '2026-01-01T09:00', P_, '2026-01-01T00:00', '2026-12-31T00:00')
    add(f, 'monthly on the first and last weekend day', rule_json(freq='monthly',
                                                                   byWeekday=[{'day': 'SA'}, {'day': 'SU'}],
                                                                   bySetPos=[1, -1]),
        '2026-03-01T11:00', 'UTC', '2026-03-01T00:00', '2026-09-01T00:00')
    add(f, 'every 3 months on the 15th', rule_json(freq='monthly', interval=3, byMonthDay=[15]), '2026-02-15T12:00',
        P_, '2026-01-01T00:00', '2028-01-01T00:00')
    add(f, 'yearly on the last Sunday of the year', rule_json(freq='yearly', byWeekday=[{'day': 'SU', 'n': -1}]),
        '2026-01-01T10:00', 'UTC', '2026-01-01T00:00', '2031-01-01T00:00')
    add(f, 'yearly Thanksgiving (4th Thursday of November)',
        rule_json(freq='yearly', byMonth=[11], byWeekday=[{'day': 'TH', 'n': 4}]), '2026-11-26T15:00', NY,
        '2026-01-01T00:00', '2032-01-01T00:00')
    add(f, 'yearly in week 1 on Monday (WKST=MO)', rule_json(freq='yearly', byWeekNo=[1], byWeekday=[{'day': 'MO'}]),
        '2024-01-01T09:00', 'UTC', '2024-01-01T00:00', '2031-01-01T00:00')
    add(f, 'yearly in week 1 on Sunday (WKST=SU)',
        rule_json(freq='yearly', byWeekNo=[1], byWeekday=[{'day': 'SU'}], wkst='SU'), '2024-01-01T09:00', 'UTC',
        '2024-01-01T00:00', '2031-01-01T00:00')
    add(f, 'yearly in week 53 on Thursday', rule_json(freq='yearly', byWeekNo=[53], byWeekday=[{'day': 'TH'}]),
        '2015-01-01T09:00', 'UTC', '2015-01-01T00:00', '2033-01-01T00:00')
    add(f, 'yearly in the last week on Friday (-1)', rule_json(freq='yearly', byWeekNo=[-1], byWeekday=[{'day': 'FR'}]),
        '2024-01-01T09:00', 'UTC', '2024-01-01T00:00', '2029-01-01T00:00')
    add(f, 'yearly every day of week 20 (no BYDAY)', rule_json(freq='yearly', byWeekNo=[20]), '2026-01-01T09:00',
        'UTC', '2026-01-01T00:00', '2028-01-01T00:00')
    add(f, 'yearly on the last day of the year (-1)', rule_json(freq='yearly', byYearDay=[-1]), '2023-01-01T21:00',
        'UTC', '2023-01-01T00:00', '2027-01-01T00:00')
    add(f, 'yearly on day 366 (leap years only)', rule_json(freq='yearly', byYearDay=[366]), '2020-01-01T08:00',
        'UTC', '2020-01-01T00:00', '2030-01-01T00:00')
    add(f, 'yearly on day 60 (Feb 29 or Mar 1)', rule_json(freq='yearly', byYearDay=[60]), '2023-01-01T08:00',
        'UTC', '2023-01-01T00:00', '2027-01-01T00:00')
    add(f, 'yearly on the 1st of every month (BYMONTHDAY expands)', rule_json(freq='yearly', byMonthDay=[1]),
        '2026-03-10T09:00', 'UTC', '2026-03-01T00:00', '2027-03-01T00:00')
    add(f, 'daily limited to the 1st and 15th', rule_json(freq='daily', byMonthDay=[1, 15]), '2026-01-01T06:00',
        'UTC', '2026-01-01T00:00', '2026-07-01T00:00')
    add(f, 'weekly limited to December', rule_json(freq='weekly', byWeekday=[{'day': 'WE'}], byMonth=[12]),
        '2026-01-07T12:00', 'UTC', '2026-01-01T00:00', '2028-01-01T00:00')
    add(f, 'daily at 08:00 and 20:00 (times)', rule_json(freq='daily', times=['08:00', '20:00']),
        '2026-09-21T08:00', P_, '2026-09-21T00:00', '2026-09-25T00:00')
    add(f, 'weekly on MO and TH at 07:15, 12:15 and 19:15 (times)',
        rule_json(freq='weekly', byWeekday=[{'day': 'MO'}, {'day': 'TH'}], times=['07:15', '12:15', '19:15']),
        '2026-09-21T07:15', P_, '2026-09-21T00:00', '2026-10-06T00:00')
    add(f, 'daily at 06:00, 06:30, 18:00, 18:30 (byHour x byMinute)',
        rule_json(freq='daily', byHour=[6, 18], byMinute=[0, 30]), '2026-09-21T06:00', P_, '2026-09-21T00:00',
        '2026-09-24T00:00')
    add(f, 'monthly last time slot of the month (setpos over times)',
        rule_json(freq='monthly', byMonthDay=[1, -1], times=['09:00', '17:00'], bySetPos=[-1]), '2026-01-01T09:00',
        'UTC', '2026-01-01T00:00', '2026-07-01T00:00')
    add(f, 'every other year on the anchor date', rule_json(freq='yearly', interval=2), '2026-07-14T21:00', P_,
        '2026-01-01T00:00', '2036-01-01T00:00')
    add(f, 'weekly with count across a year boundary', rule_json(freq='weekly', byWeekday=[{'day': 'WE'}], count=6),
        '2026-12-09T10:00', P_, '2026-12-01T00:00', '2027-03-01T00:00')
    add(f, 'daily all-day', rule_json(freq='daily'), '2026-09-21T00:00', P_, '2026-09-19T00:00',
        '2026-09-25T00:00', all_day=True)
    add(f, 'weekly all-day with exdate', rule_json(freq='weekly', exdates=['2026-10-05']), '2026-09-21T00:00', None,
        '2026-09-01T00:00', '2026-10-31T00:00', eval_zone='Asia/Tokyo', all_day=True)
    add(f, 'monthly last day all-day', rule_json(freq='monthly', byMonthDay=[-1]), '2026-01-31T00:00', P_,
        '2026-01-01T00:00', '2026-07-01T00:00', all_day=True)
    add(f, '3-day all-day blocks overlapping the range start', rule_json(freq='weekly'), '2026-09-19T00:00', P_,
        '2026-09-21T00:00', '2026-10-01T00:00', all_day=True, duration=3 * 1440)
    add(f, 'monthly on the 15th, anchor after the 15th (first is next month)',
        rule_json(freq='monthly', byMonthDay=[15]), '2026-09-20T10:00', P_, '2026-09-01T00:00',
        '2027-01-01T00:00')
    add(f, 'yearly in March and October on the last Sunday (DST days)',
        rule_json(freq='yearly', byMonth=[3, 10], byWeekday=[{'day': 'SU', 'n': -1}]), '2026-01-01T12:00', P_,
        '2026-01-01T00:00', '2029-01-01T00:00', with_utc=True)


# ---------------------------------------------------------------------------
# Sub-daily rules, windows and times.

def subdaily_rules():
    f = 'subdaily_windows'
    P_ = 'Europe/Paris'
    w = lambda s, e, a='window_start': {'start': s, 'end': e, 'anchor': a}
    add(f, 'every 90 minutes 08:00-20:00 on weekdays',
        rule_json(freq='minutely', interval=90, byWeekday=WEEKDAYS, window=w('08:00', '20:00')),
        '2026-09-25T08:00', P_, '2026-09-25T00:00', '2026-09-29T00:00', oracle='window',
        notes='9 per weekday (08:00 ... 20:00), none on the weekend')
    add(f, 'every 70 minutes 08:00-20:00, window_start restarts daily',
        rule_json(freq='minutely', interval=70, window=w('08:00', '20:00')), '2026-09-25T08:00', P_,
        '2026-09-25T00:00', '2026-09-28T00:00', oracle='window')
    add(f, 'every 70 minutes 08:00-20:00, series_start drifts',
        rule_json(freq='minutely', interval=70, window=w('08:00', '20:00', 'series_start')), '2026-09-25T08:00', P_,
        '2026-09-25T00:00', '2026-09-28T00:00', oracle='window')
    add(f, 'every minute for 24 hours (1440 keys)', rule_json(freq='minutely'), '2026-09-21T00:00', 'UTC',
        '2026-09-21T00:00', '2026-09-22T00:00', oracle='chain')
    add(f, 'every minute in a 00:00-24:00 window (1440 keys)',
        rule_json(freq='minutely', window=w('00:00', '24:00')), '2026-09-21T00:00', P_, '2026-09-21T00:00',
        '2026-09-22T00:00', oracle='window')
    add(f, 'every minute 23:50-24:00 across two days', rule_json(freq='minutely', window=w('23:50', '24:00')),
        '2026-09-21T00:00', 'UTC', '2026-09-21T00:00', '2026-09-23T00:00', oracle='window')
    add(f, 'every 45 minutes 09:00-18:00 on weekdays',
        rule_json(freq='minutely', interval=45, byWeekday=WEEKDAYS, window=w('09:00', '18:00')),
        '2026-09-21T09:00', P_, '2026-09-21T00:00', '2026-09-23T00:00', oracle='window')
    add(f, 'window end inclusive when a step lands on it', rule_json(freq='minutely', interval=30,
                                                                      window=w('10:00', '12:00')),
        '2026-09-21T10:00', 'UTC', '2026-09-21T00:00', '2026-09-22T00:00', oracle='window')
    add(f, 'window end not on a step', rule_json(freq='minutely', interval=25, window=w('10:00', '12:00')),
        '2026-09-21T10:00', 'UTC', '2026-09-21T00:00', '2026-09-22T00:00', oracle='window')
    add(f, 'zero-length window (start = end)', rule_json(freq='minutely', interval=15, window=w('12:00', '12:00')),
        '2026-09-21T12:00', 'UTC', '2026-09-21T00:00', '2026-09-24T00:00', oracle='window')
    add(f, 'every hour', rule_json(freq='hourly'), '2026-09-21T08:30', 'UTC', '2026-09-21T00:00',
        '2026-09-22T00:00', oracle='chain')
    add(f, 'every 3 hours', rule_json(freq='hourly', interval=3), '2026-09-21T01:00', 'UTC', '2026-09-21T00:00',
        '2026-09-23T00:00', oracle='chain')
    add(f, 'every 5 hours chain across days', rule_json(freq='hourly', interval=5), '2026-09-21T07:00', P_,
        '2026-09-22T00:00', '2026-09-24T00:00', oracle='chain')
    add(f, 'every 2 hours 22:00-24:00 window', rule_json(freq='hourly', interval=2, window=w('20:00', '24:00')),
        '2026-09-21T20:00', 'UTC', '2026-09-21T00:00', '2026-09-24T00:00', oracle='window')
    add(f, 'every 3 hours 08:00-20:00 (window_start)', rule_json(freq='hourly', interval=3, window=w('08:00', '20:00')),
        '2026-09-21T08:00', P_, '2026-09-21T00:00', '2026-09-23T00:00', oracle='window')
    add(f, 'hourly at :00 and :30 (BYMINUTE expands)', rule_json(freq='hourly', byMinute=[0, 30]),
        '2026-09-21T09:00', 'UTC', '2026-09-21T09:00', '2026-09-21T15:00')
    add(f, 'every 2 hours at :15 and :45 (BYMINUTE expands)', rule_json(freq='hourly', interval=2, byMinute=[15, 45]),
        '2026-09-21T09:40', 'UTC', '2026-09-21T00:00', '2026-09-22T00:00')
    add(f, 'hourly limited to 09, 12, 18', rule_json(freq='hourly', byHour=[9, 12, 18]), '2026-09-21T00:00', 'UTC',
        '2026-09-21T00:00', '2026-09-23T00:00', oracle='chain')
    add(f, 'every 10 minutes limited to 13:xx', rule_json(freq='minutely', interval=10, byHour=[13]),
        '2026-09-21T00:00', 'UTC', '2026-09-21T00:00', '2026-09-23T00:00', oracle='chain')
    add(f, 'every 5 minutes limited to minutes 0 and 30', rule_json(freq='minutely', interval=5, byMinute=[0, 30]),
        '2026-09-21T09:00', 'UTC', '2026-09-21T09:00', '2026-09-21T13:00', oracle='chain')
    add(f, 'every 7 minutes chain across midnight', rule_json(freq='minutely', interval=7), '2026-09-21T23:30', 'UTC',
        '2026-09-21T23:00', '2026-09-22T00:45', oracle='chain')
    add(f, 'every 40 minutes series_start on weekends only',
        rule_json(freq='minutely', interval=40, byWeekday=[{'day': 'SA'}, {'day': 'SU'}],
                  window=w('09:00', '12:00', 'series_start')), '2026-09-25T09:00', 'UTC', '2026-09-25T00:00',
        '2026-09-29T00:00', oracle='window')
    add(f, 'every 2 hours window_start with an hour limit',
        rule_json(freq='hourly', interval=2, byHour=[8, 12, 16], window=w('08:00', '20:00')), '2026-09-21T08:00',
        'UTC', '2026-09-21T00:00', '2026-09-23T00:00', oracle='window')
    add(f, 'every 20 minutes 09:00-16:40 window (RFC equivalent)',
        rule_json(freq='minutely', interval=20, window=w('09:00', '16:40')), '2026-09-21T09:00', NY,
        '2026-09-21T00:00', '2026-09-22T00:00', oracle='window')
    add(f, 'windowed rule with count', rule_json(freq='minutely', interval=60, window=w('09:00', '11:00'), count=7),
        '2026-09-21T09:00', 'UTC', '2026-09-21T00:00', '2026-09-26T00:00', oracle='window')
    add(f, 'windowed rule with until', rule_json(freq='minutely', interval=30, window=w('09:00', '10:00'),
                                                 until='2026-09-23T09:30'),
        '2026-09-21T09:00', 'UTC', '2026-09-21T00:00', '2026-09-26T00:00', oracle='window')
    add(f, 'windowed rule with exdates', rule_json(freq='minutely', interval=30, window=w('09:00', '10:00'),
                                                   exdates=['2026-09-21T09:30', '2026-09-22']),
        '2026-09-21T09:00', 'UTC', '2026-09-21T00:00', '2026-09-24T00:00', oracle='window')
    add(f, 'window starting after the anchor time on day one',
        rule_json(freq='minutely', interval=60, window=w('08:00', '12:00')), '2026-09-21T10:15', 'UTC',
        '2026-09-21T00:00', '2026-09-23T00:00', oracle='window')
    add(f, 'floating every 2 hours evaluated in Tokyo',
        rule_json(freq='hourly', interval=2, window=w('08:00', '18:00')), '2026-09-21T08:00', None,
        '2026-09-21T00:00', '2026-09-22T00:00', eval_zone='Asia/Tokyo', oracle='window', with_utc=True)
    add(f, 'every 30 minutes on the 1st of the month only',
        rule_json(freq='minutely', interval=30, byMonthDay=[1], window=w('09:00', '10:00')), '2026-09-01T09:00',
        'UTC', '2026-09-01T00:00', '2026-11-02T00:00', oracle='window')
    add(f, 'every 15 minutes with limit 5', rule_json(freq='minutely', interval=15), '2026-09-21T09:00', 'UTC',
        '2026-09-21T00:00', '2026-09-22T00:00', oracle='chain', limit=5)
    add(f, '8:00 and 20:00 daily yields two per day', rule_json(freq='daily', times=['08:00', '20:00']),
        '2026-09-21T08:00', 'UTC', '2026-09-21T00:00', '2026-09-28T00:00')
    add(f, 'hourly with 90-minute duration overlapping the range start',
        rule_json(freq='hourly', interval=2), '2026-09-21T00:00', 'UTC', '2026-09-21T09:00', '2026-09-21T14:00',
        oracle='chain', duration=90)
    add(f, 'times not forming a cross product (08:00, 12:30, 19:45)',
        rule_json(freq='daily', times=['08:00', '12:30', '19:45']), '2026-09-21T08:00', 'UTC', '2026-09-21T00:00',
        '2026-09-23T00:00',
        walls=[dt.datetime(2026, 9, d, h, m) for d in (21, 22) for h, m in ((8, 0), (12, 30), (19, 45))])


# ---------------------------------------------------------------------------
# Bounds & sets.

def bounds_rules():
    f = 'bounds_sets'
    P_ = 'Europe/Paris'
    s = '2026-09-21T08:00'
    add(f, 'count 10 with 2 exdates yields 8',
        rule_json(freq='daily', count=10, exdates=['2026-09-23T08:00', '2026-09-27T08:00']), s, P_,
        '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'rdate before the anchor is included', rule_json(freq='weekly', count=3, rdates=['2026-09-10T15:00']), s,
        P_, '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'until exactly equal to an occurrence includes it', rule_json(freq='daily', until='2026-09-25T08:00'), s,
        P_, '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'until one minute before an occurrence excludes it', rule_json(freq='daily', until='2026-09-25T07:59'), s,
        P_, '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'date-only exdate removes every time on that day',
        rule_json(freq='daily', times=['08:00', '20:00'], exdates=['2026-09-22']), s, P_, '2026-09-21T00:00',
        '2026-09-24T00:00')
    add(f, 'rdate equal to a generated occurrence is not duplicated',
        rule_json(freq='daily', count=3, rdates=['2026-09-22T08:00']), s, P_, '2026-09-01T00:00',
        '2026-12-01T00:00')
    add(f, 'date-only rdate uses the anchor time', rule_json(freq='weekly', count=2, rdates=['2026-09-24']), s, P_,
        '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'exdate that matches nothing', rule_json(freq='daily', count=3, exdates=['2026-09-22T09:00']), s, P_,
        '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'rdate after until is still included', rule_json(freq='daily', until='2026-09-23T08:00',
                                                            rdates=['2026-10-01T10:00']),
        s, P_, '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'rdates do not consume the count', rule_json(freq='daily', count=2, rdates=['2026-09-21T12:00',
                                                                                        '2026-09-30T12:00']),
        s, P_, '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'count exhausted before the range', rule_json(freq='daily', count=5), s, P_, '2026-10-01T00:00',
        '2026-11-01T00:00')
    add(f, 'range entirely before the anchor', rule_json(freq='daily'), s, P_, '2026-08-01T00:00',
        '2026-09-01T00:00')
    add(f, 'range straddling the anchor', rule_json(freq='daily'), s, P_, '2026-09-18T00:00', '2026-09-24T00:00')
    add(f, 'until before the range', rule_json(freq='daily', until='2026-09-24T08:00'), s, P_, '2026-10-01T00:00',
        '2026-10-10T00:00')
    add(f, 'exdate removes an rdate with the same key',
        rule_json(freq='weekly', count=2, rdates=['2026-09-24T08:00'], exdates=['2026-09-24T08:00']), s, P_,
        '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'count with interval 3', rule_json(freq='daily', interval=3, count=4), s, P_, '2026-09-01T00:00',
        '2026-12-01T00:00')
    add(f, 'countMode completions does not truncate expansion',
        rule_json(freq='daily', count=3, countMode='completions'), s, P_, '2026-09-21T00:00', '2026-09-27T00:00',
        walls=[P(s) + dt.timedelta(days=i) for i in range(6)])
    add(f, 'duration overlap includes the occurrence started before the range',
        rule_json(freq='daily', times=['22:00']), '2026-09-20T22:00', P_, '2026-09-21T00:00', '2026-09-22T00:00',
        duration=180)
    add(f, 'count across a month with monthly overflow skip',
        rule_json(freq='monthly', byMonthDay=[30], count=4), '2026-01-30T08:00', P_, '2026-01-01T00:00',
        '2027-01-01T00:00')
    add(f, 'exdates on an all-day series (datetime and date forms)',
        rule_json(freq='daily', exdates=['2026-09-22', '2026-09-24T00:00']), '2026-09-21T00:00', P_,
        '2026-09-21T00:00', '2026-09-27T00:00', all_day=True)
    add(f, 'rdate on an all-day series', rule_json(freq='weekly', count=2, rdates=['2026-09-25']),
        '2026-09-21T00:00', P_, '2026-09-01T00:00', '2026-12-01T00:00', all_day=True)
    add(f, 'until on a weekly series with two weekdays',
        rule_json(freq='weekly', byWeekday=[{'day': 'MO'}, {'day': 'FR'}], until='2026-10-09T08:00'), s, P_,
        '2026-09-01T00:00', '2026-12-01T00:00')
    add(f, 'count 1', rule_json(freq='yearly', count=1), s, P_, '2026-01-01T00:00', '2030-01-01T00:00')


# ---------------------------------------------------------------------------
# Time zones & DST.

def dst_rules():
    f = 'dst_zones'
    cases = [
        ('Europe/Paris', 'daily 02:30 on spring-forward day shifts to 03:30', '2026-03-27T02:30', '2026-03-28T00:00',
         '2026-03-31T00:00'),
        ('Europe/Paris', 'daily 02:30 on fall-back day takes the earlier instant', '2026-10-23T02:30',
         '2026-10-24T00:00', '2026-10-27T00:00'),
        ('Europe/Paris', 'daily 08:00 across both transitions', '2026-03-28T08:00', '2026-03-28T00:00',
         '2026-03-31T00:00'),
        ('America/New_York', 'daily 02:30 on spring-forward day', '2026-03-06T02:30', '2026-03-07T00:00',
         '2026-03-10T00:00'),
        ('America/New_York', 'daily 01:30 on fall-back day resolves once (first)', '2026-10-30T01:30',
         '2026-10-31T00:00', '2026-11-03T00:00'),
        ('Australia/Lord_Howe', 'daily 02:15 in the 30-minute gap', '2026-10-01T02:15', '2026-10-03T00:00',
         '2026-10-06T00:00'),
        ('Australia/Lord_Howe', 'daily 01:45 in the 30-minute overlap', '2026-04-01T01:45', '2026-04-04T00:00',
         '2026-04-07T00:00'),
        ('Asia/Tehran', 'daily 00:30 in the 2021 midnight gap', '2021-03-19T00:30', '2021-03-20T00:00',
         '2021-03-24T00:00'),
        ('Asia/Tehran', 'daily 23:30 in the 2021 fall-back overlap', '2021-09-19T23:30', '2021-09-20T00:00',
         '2021-09-24T00:00'),
        ('Asia/Tehran', 'daily 00:30 in 2026 (no DST any more)', '2026-03-19T00:30', '2026-03-20T00:00',
         '2026-03-24T00:00'),
        ('Africa/Tunis', 'daily 02:30 in the 2008 spring-forward gap', '2008-03-28T02:30', '2008-03-29T00:00',
         '2008-04-01T00:00'),
        ('Africa/Tunis', 'daily 02:30 in the 2008 fall-back overlap', '2008-10-24T02:30', '2008-10-25T00:00',
         '2008-10-28T00:00'),
        ('Africa/Tunis', 'daily 09:00 in 2026 (fixed +01:00)', '2026-03-27T09:00', '2026-03-28T00:00',
         '2026-03-31T00:00'),
        ('Pacific/Chatham', 'daily 03:00 in the +12:45 -> +13:45 gap', '2026-09-25T03:00', '2026-09-26T00:00',
         '2026-09-29T00:00'),
        ('Pacific/Chatham', 'daily 03:00 in the April overlap', '2026-04-03T03:00', '2026-04-04T00:00',
         '2026-04-07T00:00'),
    ]
    for zone, name, start, frm, to in cases:
        add(f, f'{zone}: {name}', rule_json(freq='daily'), start, zone, frm, to, with_utc=True)
    add(f, 'Europe/Paris: every 15 minutes through the spring gap', rule_json(freq='minutely', interval=15),
        '2026-03-29T01:00', 'Europe/Paris', '2026-03-29T01:00', '2026-03-29T04:00', oracle='chain', with_utc=True)
    add(f, 'Europe/Paris: hourly through the autumn overlap', rule_json(freq='hourly'), '2026-10-25T00:00',
        'Europe/Paris', '2026-10-25T00:00', '2026-10-25T05:00', oracle='chain', with_utc=True)
    add(f, 'America/New_York: every 30 minutes through the spring gap', rule_json(freq='minutely', interval=30),
        '2026-03-08T01:00', NY, '2026-03-08T01:00', '2026-03-08T04:00', oracle='chain', with_utc=True)
    add(f, 'America/New_York: weekly keeps wall time across DST', rule_json(freq='weekly'), '2026-10-26T09:00', NY,
        '2026-10-26T00:00', '2026-11-17T00:00', with_utc=True)
    add(f, 'Australia/Lord_Howe: every 15 minutes 01:30-03:00 on the gap day',
        rule_json(freq='minutely', interval=15, window={'start': '01:30', 'end': '03:00', 'anchor': 'window_start'}),
        '2026-10-04T01:30', 'Australia/Lord_Howe', '2026-10-04T00:00', '2026-10-05T00:00', oracle='window',
        with_utc=True)
    add(f, 'floating 08:00 resolves at 08:00 in Europe/Paris', rule_json(freq='daily'), '2026-09-21T08:00', None,
        '2026-09-21T00:00', '2026-09-24T00:00', eval_zone='Europe/Paris', with_utc=True)
    add(f, 'floating 08:00 resolves at 08:00 in America/Los_Angeles', rule_json(freq='daily'), '2026-09-21T08:00',
        None, '2026-09-21T00:00', '2026-09-24T00:00', eval_zone='America/Los_Angeles', with_utc=True)
    add(f, 'floating 08:00 after travelling to Pacific/Chatham', rule_json(freq='daily'), '2026-09-21T08:00', None,
        '2026-09-21T00:00', '2026-09-24T00:00', eval_zone='Pacific/Chatham', with_utc=True)
    add(f, 'fixed Europe/Paris 09:00 rule viewed from America/New_York', rule_json(freq='daily'),
        '2026-09-21T09:00', 'Europe/Paris', '2026-09-21T00:00', '2026-09-23T00:00', eval_zone=NY, with_utc=True,
        notes='Range is New York wall time; occurrences keep their Paris keys.')
    add(f, 'fixed Asia/Tokyo 07:00 rule viewed from Europe/Paris', rule_json(freq='weekly', byWeekday=WEEKDAYS),
        '2026-09-21T07:00', 'Asia/Tokyo', '2026-09-21T00:00', '2026-09-28T00:00', eval_zone='Europe/Paris',
        with_utc=True)
    add(f, 'Pacific/Chatham: monthly on the last Sunday at 02:50 (gap in September)',
        rule_json(freq='monthly', byWeekday=[{'day': 'SU', 'n': -1}], times=['02:50']), '2026-07-26T02:50',
        'Pacific/Chatham', '2026-07-01T00:00', '2026-11-01T00:00', with_utc=True)
    add(f, 'Europe/Paris: all-day series over the spring transition', rule_json(freq='daily'), '2026-03-28T00:00',
        'Europe/Paris', '2026-03-28T00:00', '2026-03-31T00:00', all_day=True)


# ---------------------------------------------------------------------------
# Quotas (per-completion slot keys).

def quota_slots(rule, anchor_date, frm, to, week_start):
    """Brute force: period slot keys `<period>#<n>` for periods overlapping [frm, to)."""
    q = rule['quota']
    eligible = [w['day'] for w in rule['byWeekday']] if 'byWeekday' in rule else WD
    until = P(rule['until']).date() if 'until' in rule else None
    ex = {e[:10] for e in rule.get('exdates', [])}
    first_day = frm.date()
    last_day = (to - dt.timedelta(minutes=1)).date()

    def pstart(d):
        if q['per'] == 'day':
            return d
        if q['per'] == 'week':
            return d - dt.timedelta(days=(d.weekday() - WD.index(week_start)) % 7)
        if q['per'] == 'month':
            return d.replace(day=1)
        return d.replace(month=1, day=1)

    def pend(s):
        if q['per'] == 'day':
            return s
        if q['per'] == 'week':
            return s + dt.timedelta(days=6)
        if q['per'] == 'month':
            return s.replace(day=calendar.monthrange(s.year, s.month)[1])
        return s.replace(month=12, day=31)

    def pkey(s):
        return {'day': f'day:{s:%Y-%m-%d}', 'week': f'week:{s:%Y-%m-%d}', 'month': f'month:{s:%Y-%m}',
                'year': f'year:{s:%Y}'}[q['per']]

    keys = []
    s = pstart(max(first_day, anchor_date))
    while s <= last_day and (until is None or s <= until):
        e = pend(s)
        a0 = max(s, anchor_date)
        a1 = e if until is None else min(e, until)
        if a0 <= a1 and a1 >= first_day:
            full = sum(1 for i in range((e - s).days + 1) if WD[(s + dt.timedelta(days=i)).weekday()] in eligible)
            act = 0
            for i in range((a1 - a0).days + 1):
                d = a0 + dt.timedelta(days=i)
                if WD[d.weekday()] in eligible and f'{d:%Y-%m-%d}' not in ex:
                    act += 1
            target = q['times'] * act / full if full else 0
            n = round(target) if abs(target - round(target)) < 1e-9 else math.ceil(target)
            keys += [f'{pkey(s)}#{i}' for i in range(1, n + 1)]
        s = e + dt.timedelta(days=1)
    return keys


def quota_rules():
    f = 'quota'

    def q(name, times, per, start, frm, to, wkst='MO', min_gap=0, **extra):
        rule = rule_json(type='quota', wkst=None if wkst == 'MO' else wkst,
                         quota={'times': times, 'per': per, 'minGapDays': min_gap}, **extra)
        keys = quota_slots(rule, P(start).date(), P(frm), P(to), wkst)
        add(f, name, rule, start, 'Europe/Paris', frm, to, keys=keys)

    q('3 per week starting on a Thursday, week start MO (first target 12/7)', 3, 'week', '2026-09-24T09:00',
      '2026-09-21T00:00', '2026-10-12T00:00')
    q('3 per week starting on a Thursday, week start SA', 3, 'week', '2026-09-24T09:00', '2026-09-19T00:00',
      '2026-10-10T00:00', wkst='SA')
    q('3 per week starting on a Thursday, week start SU', 3, 'week', '2026-09-24T09:00', '2026-09-20T00:00',
      '2026-10-11T00:00', wkst='SU')
    q('3 per week starting on the week start (full first period)', 3, 'week', '2026-09-21T09:00',
      '2026-09-21T00:00', '2026-10-05T00:00')
    q('20 per month starting mid-February 2026 (28 days)', 20, 'month', '2026-02-15T09:00', '2026-02-01T00:00',
      '2026-04-01T00:00')
    q('20 per month starting mid-February 2024 (29 days)', 20, 'month', '2024-02-15T09:00', '2024-02-01T00:00',
      '2024-03-01T00:00')
    q('10 per month starting on April 11 (30 days)', 10, 'month', '2026-04-11T09:00', '2026-04-01T00:00',
      '2026-06-01T00:00')
    q('10 per month starting on January 17 (31 days)', 10, 'month', '2026-01-17T09:00', '2026-01-01T00:00',
      '2026-02-01T00:00')
    q('2 per day', 2, 'day', '2026-09-21T09:00', '2026-09-21T00:00', '2026-09-24T00:00')
    q('100 per year starting in July', 100, 'year', '2026-07-01T09:00', '2026-01-01T00:00', '2027-01-01T00:00')
    q('3 per week on weekdays only, starting Thursday', 3, 'week', '2026-09-24T09:00', '2026-09-21T00:00',
      '2026-10-05T00:00', byWeekday=WEEKDAYS)
    q('3 per week with until on a Tuesday (partial last period)', 3, 'week', '2026-09-21T09:00',
      '2026-09-21T00:00', '2026-10-19T00:00', until='2026-10-06T23:59')
    q('4 per week with an excused day (exdate)', 4, 'week', '2026-09-21T09:00', '2026-09-21T00:00',
      '2026-09-28T00:00', exdates=['2026-09-23'])
    q('1 per week not two days in a row (minGapDays)', 1, 'week', '2026-09-21T09:00', '2026-09-21T00:00',
      '2026-10-05T00:00', min_gap=1)
    q('5 per month, range in the middle of the series', 5, 'month', '2026-01-10T09:00', '2026-06-01T00:00',
      '2026-08-01T00:00')
    q('7 per week starting on Sunday with week start MO', 7, 'week', '2026-09-27T09:00', '2026-09-21T00:00',
      '2026-10-05T00:00')


# ---------------------------------------------------------------------------
# After-completion rules (expected = first due + due after each completion).

def after_completion_rules():
    f = 'after_completion'

    def plus_months(d, months):
        idx = d.year * 12 + d.month - 1 + months
        y, m = divmod(idx, 12)
        m += 1
        return d.replace(year=y, month=m, day=min(d.day, calendar.monthrange(y, m)[1]))

    def due(start, completion, amount, unit, all_day=False):
        c = P(completion)
        s = P(start)
        if unit == 'minute':
            r = c + dt.timedelta(minutes=amount)
        elif unit == 'hour':
            r = c + dt.timedelta(hours=amount)
        elif unit in ('day', 'week'):
            r = (c + dt.timedelta(days=amount * (7 if unit == 'week' else 1))).replace(hour=s.hour, minute=s.minute)
        elif unit == 'month':
            r = plus_months(c, amount).replace(hour=s.hour, minute=s.minute)
        else:
            r = plus_months(c, 12 * amount).replace(hour=s.hour, minute=s.minute)
        return key(r, all_day) if all_day else key(r)

    def a(name, amount, unit, start, completions, zone='Europe/Paris', all_day=False, until=None):
        rule = rule_json(type='after_completion', afterCompletion={'amount': amount, 'unit': unit}, until=until)
        keys = [key(P(start), all_day)] + [due(start, c, amount, unit, all_day) for c in completions]
        if until:
            keys = [k for k in keys if P(k if 'T' in k else k + 'T00:00') <= P(until)]
        case = add(f, name, rule, start, zone, '2000-01-01T00:00', '2100-01-01T00:00', keys=keys, all_day=all_day)
        case['completions'] = completions

    a('2 days after completion (late and early completions)', 2, 'day', '2026-09-21T08:00',
      ['2026-09-24T19:30', '2026-09-25T07:00'])
    a('every 3 hours after the last dose', 3, 'hour', '2026-09-21T08:00', ['2026-09-21T08:10', '2026-09-21T12:45'])
    a('45 minutes after completion', 45, 'minute', '2026-09-21T08:00', ['2026-09-21T08:20'])
    a('1 week after completion keeps the anchor time', 1, 'week', '2026-09-21T18:00', ['2026-09-23T09:00'])
    a('1 month after completion on January 31 clamps', 1, 'month', '2026-01-31T09:00', ['2026-01-31T10:00'])
    a('1 year after completion on February 29 clamps', 1, 'year', '2024-02-29T09:00', ['2024-02-29T10:00'])
    a('3 days after completion, all-day', 3, 'day', '2026-09-21T00:00', ['2026-09-22T15:00'], all_day=True)
    a('2 hours after completion across the Paris spring gap', 2, 'hour', '2026-03-29T00:30',
      ['2026-03-29T00:30'])
    a('1 day after completion stops at until', 1, 'day', '2026-09-21T08:00',
      ['2026-09-21T09:00', '2026-09-29T09:00'], until='2026-09-25T23:59')


def main():
    rfc_examples()
    calendar_rules()
    subdaily_rules()
    bounds_rules()
    dst_rules()
    quota_rules()
    after_completion_rules()
    total = 0
    for name, cases in ALL.items():
        with open(os.path.join(OUT, f'{name}.json'), 'w', encoding='utf-8') as fh:
            json.dump(cases, fh, indent=1, ensure_ascii=False)
            fh.write('\n')
        total += len(cases)
        print(f'{name}: {len(cases)} cases')
    print(f'total: {total}')


if __name__ == '__main__':
    main()
