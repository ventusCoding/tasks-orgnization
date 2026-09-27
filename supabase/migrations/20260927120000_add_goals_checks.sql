-- Goals (T5.4.01): which metrics a scope allows, positive targets, custom periods with both dates
-- and a scope id for every scope except `global`. Mirrors the domain validation in
-- app/lib/features/goals/domain/goal.dart. Additive: app.goals and its sync wiring already exist
-- (20260922000090_create_habits_goals.sql).

alter table app.goals
  add constraint goals_metric_scope check (
    case scope_type
      when 'habit' then metric in ('total_value', 'completions', 'streak_days', 'clean_days', 'money_saved', 'units_avoided')
      when 'series' then metric in ('completions', 'tracked_minutes')
      when 'category' then metric in ('tracked_minutes')
      when 'checklist' then metric in ('items_completed')
      when 'global' then metric in ('completions', 'tracked_minutes', 'items_completed')
      else false
    end
  ),
  add constraint goals_target_positive check (target > 0),
  add constraint goals_custom_period_dates check (period <> 'custom' or (start_date is not null and end_date is not null)),
  add constraint goals_scope_id_presence check ((scope_type = 'global') = (scope_id is null));

comment on constraint goals_metric_scope on app.goals is
  'total_value/completions/streak_days (habits), clean_days/money_saved/units_avoided (quit trackers), '
  'tracked_minutes (series, category), items_completed (checklists).';
