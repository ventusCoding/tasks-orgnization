export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  app: {
    Tables: {
      achievements: {
        Row: {
          code: string
          created_at: string
          deleted_at: string | null
          field_clock: Json
          id: string
          origin_device_id: string | null
          payload: Json | null
          rev: number
          scope_id: string | null
          scope_type: string | null
          server_updated_at: string
          unlocked_at: string
          updated_at: string
          user_id: string
        }
        Insert: {
          code: string
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          id: string
          origin_device_id?: string | null
          payload?: Json | null
          rev: number
          scope_id?: string | null
          scope_type?: string | null
          server_updated_at: string
          unlocked_at: string
          updated_at: string
          user_id: string
        }
        Update: {
          code?: string
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          id?: string
          origin_device_id?: string | null
          payload?: Json | null
          rev?: number
          scope_id?: string | null
          scope_type?: string | null
          server_updated_at?: string
          unlocked_at?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      activity_events: {
        Row: {
          created_at: string
          deleted_at: string | null
          entity_id: string
          entity_type: string
          event_type: string
          field_clock: Json
          id: string
          occurred_at: string
          origin_device_id: string | null
          parent_id: string | null
          payload: Json
          rev: number
          server_updated_at: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at: string
          deleted_at?: string | null
          entity_id: string
          entity_type: string
          event_type: string
          field_clock?: Json
          id: string
          occurred_at: string
          origin_device_id?: string | null
          parent_id?: string | null
          payload?: Json
          rev: number
          server_updated_at: string
          updated_at: string
          user_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          entity_id?: string
          entity_type?: string
          event_type?: string
          field_clock?: Json
          id?: string
          occurred_at?: string
          origin_device_id?: string | null
          parent_id?: string | null
          payload?: Json
          rev?: number
          server_updated_at?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      app_config: {
        Row: {
          key: string
          value: Json
        }
        Insert: {
          key: string
          value: Json
        }
        Update: {
          key?: string
          value?: Json
        }
        Relationships: []
      }
      attachments: {
        Row: {
          bucket: string
          byte_size: number
          caption: string | null
          created_at: string
          deleted_at: string | null
          duration_ms: number | null
          field_clock: Json
          file_name: string
          height: number | null
          id: string
          mime_type: string
          origin_device_id: string | null
          owner_id: string
          owner_type: string
          rev: number
          server_updated_at: string
          sha256: string | null
          sort_key: string
          storage_path: string
          thumb_path: string | null
          updated_at: string
          uploaded_at: string | null
          user_id: string
          width: number | null
        }
        Insert: {
          bucket?: string
          byte_size: number
          caption?: string | null
          created_at: string
          deleted_at?: string | null
          duration_ms?: number | null
          field_clock?: Json
          file_name: string
          height?: number | null
          id: string
          mime_type: string
          origin_device_id?: string | null
          owner_id: string
          owner_type: string
          rev: number
          server_updated_at: string
          sha256?: string | null
          sort_key: string
          storage_path: string
          thumb_path?: string | null
          updated_at: string
          uploaded_at?: string | null
          user_id: string
          width?: number | null
        }
        Update: {
          bucket?: string
          byte_size?: number
          caption?: string | null
          created_at?: string
          deleted_at?: string | null
          duration_ms?: number | null
          field_clock?: Json
          file_name?: string
          height?: number | null
          id?: string
          mime_type?: string
          origin_device_id?: string | null
          owner_id?: string
          owner_type?: string
          rev?: number
          server_updated_at?: string
          sha256?: string | null
          sort_key?: string
          storage_path?: string
          thumb_path?: string | null
          updated_at?: string
          uploaded_at?: string | null
          user_id?: string
          width?: number | null
        }
        Relationships: []
      }
      categories: {
        Row: {
          archived_at: string | null
          color: number
          counts_as_unavailable: boolean
          created_at: string
          deleted_at: string | null
          field_clock: Json
          icon: string | null
          id: string
          name: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
        }
        Insert: {
          archived_at?: string | null
          color: number
          counts_as_unavailable?: boolean
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          icon?: string | null
          id: string
          name: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
        }
        Update: {
          archived_at?: string | null
          color?: number
          counts_as_unavailable?: boolean
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          icon?: string | null
          id?: string
          name?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          sort_key?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      checklist_items: {
        Row: {
          checklist_id: string
          completed_at: string | null
          created_at: string
          deleted_at: string | null
          due_local: string | null
          estimate_minutes: number | null
          field_clock: Json
          follow_up_at: string | null
          id: string
          mirror_of_id: string | null
          note: string | null
          notify_mode: string
          origin_device_id: string | null
          parent_id: string | null
          priority: number
          rev: number
          server_updated_at: string
          sort_key: string
          status: string
          status_changed_at: string | null
          status_note: string | null
          text: string
          time_zone: string | null
          updated_at: string
          user_id: string
          waiting_on: string | null
        }
        Insert: {
          checklist_id: string
          completed_at?: string | null
          created_at: string
          deleted_at?: string | null
          due_local?: string | null
          estimate_minutes?: number | null
          field_clock?: Json
          follow_up_at?: string | null
          id: string
          mirror_of_id?: string | null
          note?: string | null
          notify_mode?: string
          origin_device_id?: string | null
          parent_id?: string | null
          priority?: number
          rev: number
          server_updated_at: string
          sort_key: string
          status?: string
          status_changed_at?: string | null
          status_note?: string | null
          text?: string
          time_zone?: string | null
          updated_at: string
          user_id: string
          waiting_on?: string | null
        }
        Update: {
          checklist_id?: string
          completed_at?: string | null
          created_at?: string
          deleted_at?: string | null
          due_local?: string | null
          estimate_minutes?: number | null
          field_clock?: Json
          follow_up_at?: string | null
          id?: string
          mirror_of_id?: string | null
          note?: string | null
          notify_mode?: string
          origin_device_id?: string | null
          parent_id?: string | null
          priority?: number
          rev?: number
          server_updated_at?: string
          sort_key?: string
          status?: string
          status_changed_at?: string | null
          status_note?: string | null
          text?: string
          time_zone?: string | null
          updated_at?: string
          user_id?: string
          waiting_on?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "checklist_items_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "checklists"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_items_mirror_of_id_fkey"
            columns: ["mirror_of_id"]
            isOneToOne: false
            referencedRelation: "checklist_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checklist_items_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "checklist_items"
            referencedColumns: ["id"]
          },
        ]
      }
      checklist_runs: {
        Row: {
          checklist_id: string
          completed_items: number | null
          created_at: string
          deleted_at: string | null
          ended_at: string | null
          field_clock: Json
          id: string
          occurrence_key: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          snapshot: Json | null
          started_at: string
          total_items: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          checklist_id: string
          completed_items?: number | null
          created_at: string
          deleted_at?: string | null
          ended_at?: string | null
          field_clock?: Json
          id: string
          occurrence_key: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          snapshot?: Json | null
          started_at: string
          total_items?: number | null
          updated_at: string
          user_id: string
        }
        Update: {
          checklist_id?: string
          completed_items?: number | null
          created_at?: string
          deleted_at?: string | null
          ended_at?: string | null
          field_clock?: Json
          id?: string
          occurrence_key?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          snapshot?: Json | null
          started_at?: string
          total_items?: number | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklist_runs_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "checklists"
            referencedColumns: ["id"]
          },
        ]
      }
      checklists: {
        Row: {
          archived_at: string | null
          body: string | null
          category_id: string | null
          color: number | null
          cover_attachment_id: string | null
          created_at: string
          deleted_at: string | null
          due_local: string | null
          field_clock: Json
          id: string
          is_pinned: boolean
          is_template: boolean
          last_reset_key: string | null
          notify_mode: string
          origin_device_id: string | null
          reset_mode: string | null
          reset_rule: Json | null
          rev: number
          server_updated_at: string
          settings: Json
          sort_key: string
          template_id: string | null
          time_zone: string | null
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          archived_at?: string | null
          body?: string | null
          category_id?: string | null
          color?: number | null
          cover_attachment_id?: string | null
          created_at: string
          deleted_at?: string | null
          due_local?: string | null
          field_clock?: Json
          id: string
          is_pinned?: boolean
          is_template?: boolean
          last_reset_key?: string | null
          notify_mode?: string
          origin_device_id?: string | null
          reset_mode?: string | null
          reset_rule?: Json | null
          rev: number
          server_updated_at: string
          settings?: Json
          sort_key: string
          template_id?: string | null
          time_zone?: string | null
          title?: string
          updated_at: string
          user_id: string
        }
        Update: {
          archived_at?: string | null
          body?: string | null
          category_id?: string | null
          color?: number | null
          cover_attachment_id?: string | null
          created_at?: string
          deleted_at?: string | null
          due_local?: string | null
          field_clock?: Json
          id?: string
          is_pinned?: boolean
          is_template?: boolean
          last_reset_key?: string | null
          notify_mode?: string
          origin_device_id?: string | null
          reset_mode?: string | null
          reset_rule?: Json | null
          rev?: number
          server_updated_at?: string
          settings?: Json
          sort_key?: string
          template_id?: string | null
          time_zone?: string | null
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "checklists_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      dashboards: {
        Row: {
          created_at: string
          deleted_at: string | null
          field_clock: Json
          id: string
          layout: Json
          name: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          id: string
          layout: Json
          name: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          id?: string
          layout?: Json
          name?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          sort_key?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      devices: {
        Row: {
          app_build: number | null
          app_version: string | null
          capabilities: Json
          created_at: string
          device_name: string | null
          id: string
          last_nudged_at: string | null
          last_seen_at: string | null
          local_coverage_until: string | null
          local_notifications_enabled: boolean
          local_repeating_rules: string[] | null
          locale: string | null
          model: string | null
          os_version: string | null
          platform: string
          push_enabled: boolean
          push_token: string | null
          push_token_updated_at: string | null
          revoked_at: string | null
          schedule_rev: number | null
          time_zone: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          app_build?: number | null
          app_version?: string | null
          capabilities?: Json
          created_at?: string
          device_name?: string | null
          id: string
          last_nudged_at?: string | null
          last_seen_at?: string | null
          local_coverage_until?: string | null
          local_notifications_enabled?: boolean
          local_repeating_rules?: string[] | null
          locale?: string | null
          model?: string | null
          os_version?: string | null
          platform: string
          push_enabled?: boolean
          push_token?: string | null
          push_token_updated_at?: string | null
          revoked_at?: string | null
          schedule_rev?: number | null
          time_zone?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          app_build?: number | null
          app_version?: string | null
          capabilities?: Json
          created_at?: string
          device_name?: string | null
          id?: string
          last_nudged_at?: string | null
          last_seen_at?: string | null
          local_coverage_until?: string | null
          local_notifications_enabled?: boolean
          local_repeating_rules?: string[] | null
          locale?: string | null
          model?: string | null
          os_version?: string | null
          platform?: string
          push_enabled?: boolean
          push_token?: string | null
          push_token_updated_at?: string | null
          revoked_at?: string | null
          schedule_rev?: number | null
          time_zone?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      entity_tags: {
        Row: {
          created_at: string
          deleted_at: string | null
          entity_id: string
          entity_type: string
          field_clock: Json
          id: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          tag_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at: string
          deleted_at?: string | null
          entity_id: string
          entity_type: string
          field_clock?: Json
          id: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          tag_id: string
          updated_at: string
          user_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          entity_id?: string
          entity_type?: string
          field_clock?: Json
          id?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          tag_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "entity_tags_tag_id_fkey"
            columns: ["tag_id"]
            isOneToOne: false
            referencedRelation: "tags"
            referencedColumns: ["id"]
          },
        ]
      }
      goals: {
        Row: {
          achieved_at: string | null
          created_at: string
          deleted_at: string | null
          end_date: string | null
          field_clock: Json
          id: string
          metric: string
          origin_device_id: string | null
          period: string
          rev: number
          reward: string | null
          scope_id: string | null
          scope_type: string
          server_updated_at: string
          start_date: string | null
          target: number
          title: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          achieved_at?: string | null
          created_at: string
          deleted_at?: string | null
          end_date?: string | null
          field_clock?: Json
          id: string
          metric: string
          origin_device_id?: string | null
          period: string
          rev: number
          reward?: string | null
          scope_id?: string | null
          scope_type: string
          server_updated_at: string
          start_date?: string | null
          target: number
          title?: string | null
          updated_at: string
          user_id: string
        }
        Update: {
          achieved_at?: string | null
          created_at?: string
          deleted_at?: string | null
          end_date?: string | null
          field_clock?: Json
          id?: string
          metric?: string
          origin_device_id?: string | null
          period?: string
          rev?: number
          reward?: string | null
          scope_id?: string | null
          scope_type?: string
          server_updated_at?: string
          start_date?: string | null
          target?: number
          title?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      habit_logs: {
        Row: {
          coping: string | null
          created_at: string
          deleted_at: string | null
          duration_seconds: number | null
          field_clock: Json
          habit_id: string
          id: string
          intensity: number | null
          kind: string
          local_date: string
          logged_at: string
          mood: number | null
          note: string | null
          occurrence_key: string | null
          origin_device_id: string | null
          place: string | null
          resisted: boolean | null
          rev: number
          server_updated_at: string
          source: string
          trigger: string | null
          updated_at: string
          user_id: string
          value: number | null
        }
        Insert: {
          coping?: string | null
          created_at: string
          deleted_at?: string | null
          duration_seconds?: number | null
          field_clock?: Json
          habit_id: string
          id: string
          intensity?: number | null
          kind: string
          local_date: string
          logged_at: string
          mood?: number | null
          note?: string | null
          occurrence_key?: string | null
          origin_device_id?: string | null
          place?: string | null
          resisted?: boolean | null
          rev: number
          server_updated_at: string
          source?: string
          trigger?: string | null
          updated_at: string
          user_id: string
          value?: number | null
        }
        Update: {
          coping?: string | null
          created_at?: string
          deleted_at?: string | null
          duration_seconds?: number | null
          field_clock?: Json
          habit_id?: string
          id?: string
          intensity?: number | null
          kind?: string
          local_date?: string
          logged_at?: string
          mood?: number | null
          note?: string | null
          occurrence_key?: string | null
          origin_device_id?: string | null
          place?: string | null
          resisted?: boolean | null
          rev?: number
          server_updated_at?: string
          source?: string
          trigger?: string | null
          updated_at?: string
          user_id?: string
          value?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "habit_logs_habit_id_fkey"
            columns: ["habit_id"]
            isOneToOne: false
            referencedRelation: "habits"
            referencedColumns: ["id"]
          },
        ]
      }
      habit_pauses: {
        Row: {
          created_at: string
          deleted_at: string | null
          end_date: string | null
          field_clock: Json
          habit_id: string | null
          id: string
          origin_device_id: string | null
          reason: string | null
          rev: number
          server_updated_at: string
          start_date: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at: string
          deleted_at?: string | null
          end_date?: string | null
          field_clock?: Json
          habit_id?: string | null
          id: string
          origin_device_id?: string | null
          reason?: string | null
          rev: number
          server_updated_at: string
          start_date: string
          updated_at: string
          user_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          end_date?: string | null
          field_clock?: Json
          habit_id?: string | null
          id?: string
          origin_device_id?: string | null
          reason?: string | null
          rev?: number
          server_updated_at?: string
          start_date?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "habit_pauses_habit_id_fkey"
            columns: ["habit_id"]
            isOneToOne: false
            referencedRelation: "habits"
            referencedColumns: ["id"]
          },
        ]
      }
      habit_revisions: {
        Row: {
          baseline_per_day: number | null
          created_at: string
          daily_limit: number | null
          deleted_at: string | null
          effective_from: string
          field_clock: Json
          goal_type: string | null
          habit_id: string
          id: string
          origin_device_id: string | null
          rev: number
          schedule: Json | null
          server_updated_at: string
          target_op: string | null
          target_value: number | null
          unit: string | null
          unit_cost: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          baseline_per_day?: number | null
          created_at: string
          daily_limit?: number | null
          deleted_at?: string | null
          effective_from: string
          field_clock?: Json
          goal_type?: string | null
          habit_id: string
          id: string
          origin_device_id?: string | null
          rev: number
          schedule?: Json | null
          server_updated_at: string
          target_op?: string | null
          target_value?: number | null
          unit?: string | null
          unit_cost?: number | null
          updated_at: string
          user_id: string
        }
        Update: {
          baseline_per_day?: number | null
          created_at?: string
          daily_limit?: number | null
          deleted_at?: string | null
          effective_from?: string
          field_clock?: Json
          goal_type?: string | null
          habit_id?: string
          id?: string
          origin_device_id?: string | null
          rev?: number
          schedule?: Json | null
          server_updated_at?: string
          target_op?: string | null
          target_value?: number | null
          unit?: string | null
          unit_cost?: number | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "habit_revisions_habit_id_fkey"
            columns: ["habit_id"]
            isOneToOne: false
            referencedRelation: "habits"
            referencedColumns: ["id"]
          },
        ]
      }
      habit_sections: {
        Row: {
          archived_at: string | null
          created_at: string
          deleted_at: string | null
          end_time: string | null
          field_clock: Json
          icon: string | null
          id: string
          name: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          start_time: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          archived_at?: string | null
          created_at: string
          deleted_at?: string | null
          end_time?: string | null
          field_clock?: Json
          icon?: string | null
          id: string
          name: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          start_time?: string | null
          updated_at: string
          user_id: string
        }
        Update: {
          archived_at?: string | null
          created_at?: string
          deleted_at?: string | null
          end_time?: string | null
          field_clock?: Json
          icon?: string | null
          id?: string
          name?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          sort_key?: string
          start_time?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      habit_vocab: {
        Row: {
          archived_at: string | null
          color: number | null
          created_at: string
          deleted_at: string | null
          field_clock: Json
          icon: string | null
          id: string
          kind: string
          name: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
        }
        Insert: {
          archived_at?: string | null
          color?: number | null
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          icon?: string | null
          id: string
          kind: string
          name: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
        }
        Update: {
          archived_at?: string | null
          color?: number | null
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          icon?: string | null
          id?: string
          kind?: string
          name?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          sort_key?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      habits: {
        Row: {
          archived_at: string | null
          auto_success: boolean
          baseline_per_day: number | null
          category_id: string | null
          color: number | null
          created_at: string
          currency: string | null
          daily_limit: number | null
          deleted_at: string | null
          description: string | null
          end_date: string | null
          field_clock: Json
          freezes_per_month: number
          goal_type: string
          icon: string | null
          id: string
          kind: string
          life_minutes_per_unit: number | null
          motivation: string | null
          name: string
          notify_mode: string
          origin_device_id: string | null
          quit_mode: string | null
          quit_started_at: string | null
          quit_substance: string | null
          rev: number
          schedule: Json | null
          section_id: string | null
          server_updated_at: string
          settings: Json
          skip_policy: string
          sort_key: string
          start_date: string
          target_op: string
          target_value: number | null
          time_per_unit_minutes: number | null
          time_zone: string | null
          unit: string | null
          unit_cost: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          archived_at?: string | null
          auto_success?: boolean
          baseline_per_day?: number | null
          category_id?: string | null
          color?: number | null
          created_at: string
          currency?: string | null
          daily_limit?: number | null
          deleted_at?: string | null
          description?: string | null
          end_date?: string | null
          field_clock?: Json
          freezes_per_month?: number
          goal_type?: string
          icon?: string | null
          id: string
          kind: string
          life_minutes_per_unit?: number | null
          motivation?: string | null
          name: string
          notify_mode?: string
          origin_device_id?: string | null
          quit_mode?: string | null
          quit_started_at?: string | null
          quit_substance?: string | null
          rev: number
          schedule?: Json | null
          section_id?: string | null
          server_updated_at: string
          settings?: Json
          skip_policy?: string
          sort_key: string
          start_date: string
          target_op?: string
          target_value?: number | null
          time_per_unit_minutes?: number | null
          time_zone?: string | null
          unit?: string | null
          unit_cost?: number | null
          updated_at: string
          user_id: string
        }
        Update: {
          archived_at?: string | null
          auto_success?: boolean
          baseline_per_day?: number | null
          category_id?: string | null
          color?: number | null
          created_at?: string
          currency?: string | null
          daily_limit?: number | null
          deleted_at?: string | null
          description?: string | null
          end_date?: string | null
          field_clock?: Json
          freezes_per_month?: number
          goal_type?: string
          icon?: string | null
          id?: string
          kind?: string
          life_minutes_per_unit?: number | null
          motivation?: string | null
          name?: string
          notify_mode?: string
          origin_device_id?: string | null
          quit_mode?: string | null
          quit_started_at?: string | null
          quit_substance?: string | null
          rev?: number
          schedule?: Json | null
          section_id?: string | null
          server_updated_at?: string
          settings?: Json
          skip_policy?: string
          sort_key?: string
          start_date?: string
          target_op?: string
          target_value?: number | null
          time_per_unit_minutes?: number | null
          time_zone?: string | null
          unit?: string | null
          unit_cost?: number | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "habits_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "habits_section_id_fkey"
            columns: ["section_id"]
            isOneToOne: false
            referencedRelation: "habit_sections"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_mutes: {
        Row: {
          created_at: string
          deleted_at: string | null
          field_clock: Json
          id: string
          origin_device_id: string | null
          reason: string | null
          rev: number
          section: string | null
          server_updated_at: string
          target_id: string | null
          target_type: string
          until: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          id: string
          origin_device_id?: string | null
          reason?: string | null
          rev: number
          section?: string | null
          server_updated_at: string
          target_id?: string | null
          target_type: string
          until?: string | null
          updated_at: string
          user_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          id?: string
          origin_device_id?: string | null
          reason?: string | null
          rev?: number
          section?: string | null
          server_updated_at?: string
          target_id?: string | null
          target_type?: string
          until?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      notification_profiles: {
        Row: {
          code: string | null
          created_at: string
          deleted_at: string | null
          field_clock: Json
          id: string
          is_builtin: boolean
          name: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          spec: Json
          updated_at: string
          user_id: string
        }
        Insert: {
          code?: string | null
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          id: string
          is_builtin?: boolean
          name: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          spec: Json
          updated_at: string
          user_id: string
        }
        Update: {
          code?: string | null
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          id?: string
          is_builtin?: boolean
          name?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          sort_key?: string
          spec?: Json
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      notification_rules: {
        Row: {
          created_at: string
          deleted_at: string | null
          enabled: boolean
          field_clock: Json
          id: string
          is_default: boolean
          name: string | null
          origin_device_id: string | null
          profile_id: string | null
          rev: number
          section: string
          server_updated_at: string
          sort_key: string
          spec: Json
          target_id: string | null
          target_type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at: string
          deleted_at?: string | null
          enabled?: boolean
          field_clock?: Json
          id: string
          is_default?: boolean
          name?: string | null
          origin_device_id?: string | null
          profile_id?: string | null
          rev: number
          section: string
          server_updated_at: string
          sort_key: string
          spec: Json
          target_id?: string | null
          target_type: string
          updated_at: string
          user_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          enabled?: boolean
          field_clock?: Json
          id?: string
          is_default?: boolean
          name?: string | null
          origin_device_id?: string | null
          profile_id?: string | null
          rev?: number
          section?: string
          server_updated_at?: string
          sort_key?: string
          spec?: Json
          target_id?: string | null
          target_type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_rules_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "notification_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          acted_at: string | null
          action: string | null
          body: string | null
          category: string
          created_at: string
          dedupe_key: string
          deleted_at: string | null
          delivered_at: string | null
          delivered_via: string[] | null
          dismissed_at: string | null
          field_clock: Json
          fire_at: string
          id: string
          late: boolean
          occurrence_key: string | null
          opened_at: string | null
          origin_device_id: string | null
          payload: Json
          read_at: string | null
          rev: number
          rule_id: string | null
          section: string | null
          server_updated_at: string
          snoozed_until: string | null
          source_id: string | null
          source_type: string | null
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          acted_at?: string | null
          action?: string | null
          body?: string | null
          category: string
          created_at: string
          dedupe_key: string
          deleted_at?: string | null
          delivered_at?: string | null
          delivered_via?: string[] | null
          dismissed_at?: string | null
          field_clock?: Json
          fire_at: string
          id: string
          late?: boolean
          occurrence_key?: string | null
          opened_at?: string | null
          origin_device_id?: string | null
          payload?: Json
          read_at?: string | null
          rev: number
          rule_id?: string | null
          section?: string | null
          server_updated_at: string
          snoozed_until?: string | null
          source_id?: string | null
          source_type?: string | null
          title: string
          updated_at: string
          user_id: string
        }
        Update: {
          acted_at?: string | null
          action?: string | null
          body?: string | null
          category?: string
          created_at?: string
          dedupe_key?: string
          deleted_at?: string | null
          delivered_at?: string | null
          delivered_via?: string[] | null
          dismissed_at?: string | null
          field_clock?: Json
          fire_at?: string
          id?: string
          late?: boolean
          occurrence_key?: string | null
          opened_at?: string | null
          origin_device_id?: string | null
          payload?: Json
          read_at?: string | null
          rev?: number
          rule_id?: string | null
          section?: string | null
          server_updated_at?: string
          snoozed_until?: string | null
          source_id?: string | null
          source_type?: string | null
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          avatar_path: string | null
          created_at: string
          current_time_zone: string | null
          deleted_at: string | null
          display_name: string | null
          field_clock: Json
          home_time_zone: string
          id: string
          locale: string | null
          onboarding_completed_at: string | null
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          time_format: string
          updated_at: string
          user_id: string
          week_start: number
        }
        Insert: {
          avatar_path?: string | null
          created_at: string
          current_time_zone?: string | null
          deleted_at?: string | null
          display_name?: string | null
          field_clock?: Json
          home_time_zone?: string
          id: string
          locale?: string | null
          onboarding_completed_at?: string | null
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          time_format?: string
          updated_at: string
          user_id: string
          week_start?: number
        }
        Update: {
          avatar_path?: string | null
          created_at?: string
          current_time_zone?: string | null
          deleted_at?: string | null
          display_name?: string | null
          field_clock?: Json
          home_time_zone?: string
          id?: string
          locale?: string | null
          onboarding_completed_at?: string | null
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          time_format?: string
          updated_at?: string
          user_id?: string
          week_start?: number
        }
        Relationships: []
      }
      saved_views: {
        Row: {
          config: Json
          created_at: string
          deleted_at: string | null
          field_clock: Json
          id: string
          is_default: boolean
          name: string
          origin_device_id: string | null
          rev: number
          section: string
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
          view_type: string
        }
        Insert: {
          config: Json
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          id: string
          is_default?: boolean
          name: string
          origin_device_id?: string | null
          rev: number
          section: string
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
          view_type: string
        }
        Update: {
          config?: Json
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          id?: string
          is_default?: boolean
          name?: string
          origin_device_id?: string | null
          rev?: number
          section?: string
          server_updated_at?: string
          sort_key?: string
          updated_at?: string
          user_id?: string
          view_type?: string
        }
        Relationships: []
      }
      sync_heads: {
        Row: {
          head_rev: number
          last_origin_device_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          head_rev?: number
          last_origin_device_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          head_rev?: number
          last_origin_device_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      tags: {
        Row: {
          color: number | null
          created_at: string
          deleted_at: string | null
          field_clock: Json
          id: string
          name: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
        }
        Insert: {
          color?: number | null
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          id: string
          name: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          sort_key: string
          updated_at: string
          user_id: string
        }
        Update: {
          color?: number | null
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          id?: string
          name?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          sort_key?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      task_occurrences: {
        Row: {
          actual_end_at: string | null
          actual_start_at: string | null
          completed_at: string | null
          completion_percent: number | null
          created_at: string
          deleted_at: string | null
          field_clock: Json
          id: string
          is_cancelled: boolean
          occurrence_key: string
          origin_device_id: string | null
          outcome_note: string | null
          override_duration_minutes: number | null
          override_notes: string | null
          override_start_local: string | null
          override_title: string | null
          rating: number | null
          rev: number
          server_updated_at: string
          skip_reason: string | null
          status: string
          status_changed_at: string | null
          task_id: string
          tracked_seconds: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          actual_end_at?: string | null
          actual_start_at?: string | null
          completed_at?: string | null
          completion_percent?: number | null
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          id: string
          is_cancelled?: boolean
          occurrence_key: string
          origin_device_id?: string | null
          outcome_note?: string | null
          override_duration_minutes?: number | null
          override_notes?: string | null
          override_start_local?: string | null
          override_title?: string | null
          rating?: number | null
          rev: number
          server_updated_at: string
          skip_reason?: string | null
          status?: string
          status_changed_at?: string | null
          task_id: string
          tracked_seconds?: number | null
          updated_at: string
          user_id: string
        }
        Update: {
          actual_end_at?: string | null
          actual_start_at?: string | null
          completed_at?: string | null
          completion_percent?: number | null
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          id?: string
          is_cancelled?: boolean
          occurrence_key?: string
          origin_device_id?: string | null
          outcome_note?: string | null
          override_duration_minutes?: number | null
          override_notes?: string | null
          override_start_local?: string | null
          override_title?: string | null
          rating?: number | null
          rev?: number
          server_updated_at?: string
          skip_reason?: string | null
          status?: string
          status_changed_at?: string | null
          task_id?: string
          tracked_seconds?: number | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "task_occurrences_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
        ]
      }
      tasks: {
        Row: {
          category_id: string | null
          color: number | null
          countdown_mode: string | null
          created_at: string
          deadline_local: string | null
          deleted_at: string | null
          duration_minutes: number | null
          estimate_minutes: number | null
          field_clock: Json
          horizon_key: string | null
          icon: string | null
          id: string
          is_all_day: boolean
          is_template: boolean
          linked_checklist_id: string | null
          linked_item_id: string | null
          location: string | null
          location_lat: number | null
          location_lng: number | null
          manual_sort_key: string | null
          notes: string | null
          notify_mode: string
          origin_device_id: string | null
          priority: number
          recurrence: Json | null
          recurrence_until_local: string | null
          rev: number
          series_id: string
          server_updated_at: string
          start_local: string | null
          status: string
          time_zone: string | null
          title: string
          tracking_mode: string
          updated_at: string
          url: string | null
          user_id: string
        }
        Insert: {
          category_id?: string | null
          color?: number | null
          countdown_mode?: string | null
          created_at: string
          deadline_local?: string | null
          deleted_at?: string | null
          duration_minutes?: number | null
          estimate_minutes?: number | null
          field_clock?: Json
          horizon_key?: string | null
          icon?: string | null
          id: string
          is_all_day?: boolean
          is_template?: boolean
          linked_checklist_id?: string | null
          linked_item_id?: string | null
          location?: string | null
          location_lat?: number | null
          location_lng?: number | null
          manual_sort_key?: string | null
          notes?: string | null
          notify_mode?: string
          origin_device_id?: string | null
          priority?: number
          recurrence?: Json | null
          recurrence_until_local?: string | null
          rev: number
          series_id: string
          server_updated_at: string
          start_local?: string | null
          status?: string
          time_zone?: string | null
          title: string
          tracking_mode?: string
          updated_at: string
          url?: string | null
          user_id: string
        }
        Update: {
          category_id?: string | null
          color?: number | null
          countdown_mode?: string | null
          created_at?: string
          deadline_local?: string | null
          deleted_at?: string | null
          duration_minutes?: number | null
          estimate_minutes?: number | null
          field_clock?: Json
          horizon_key?: string | null
          icon?: string | null
          id?: string
          is_all_day?: boolean
          is_template?: boolean
          linked_checklist_id?: string | null
          linked_item_id?: string | null
          location?: string | null
          location_lat?: number | null
          location_lng?: number | null
          manual_sort_key?: string | null
          notes?: string | null
          notify_mode?: string
          origin_device_id?: string | null
          priority?: number
          recurrence?: Json | null
          recurrence_until_local?: string | null
          rev?: number
          series_id?: string
          server_updated_at?: string
          start_local?: string | null
          status?: string
          time_zone?: string | null
          title?: string
          tracking_mode?: string
          updated_at?: string
          url?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "tasks_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_linked_checklist_id_fkey"
            columns: ["linked_checklist_id"]
            isOneToOne: false
            referencedRelation: "checklists"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_linked_item_id_fkey"
            columns: ["linked_item_id"]
            isOneToOne: false
            referencedRelation: "checklist_items"
            referencedColumns: ["id"]
          },
        ]
      }
      time_entries: {
        Row: {
          created_at: string
          deleted_at: string | null
          ended_at: string | null
          field_clock: Json
          id: string
          note: string | null
          occurrence_key: string | null
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          started_at: string
          task_id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at: string
          deleted_at?: string | null
          ended_at?: string | null
          field_clock?: Json
          id: string
          note?: string | null
          occurrence_key?: string | null
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          started_at: string
          task_id: string
          updated_at: string
          user_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          ended_at?: string | null
          field_clock?: Json
          id?: string
          note?: string | null
          occurrence_key?: string | null
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          started_at?: string
          task_id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "time_entries_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
        ]
      }
      user_settings: {
        Row: {
          created_at: string
          deleted_at: string | null
          field_clock: Json
          id: string
          namespace: string
          origin_device_id: string | null
          rev: number
          server_updated_at: string
          updated_at: string
          user_id: string
          value: Json
        }
        Insert: {
          created_at: string
          deleted_at?: string | null
          field_clock?: Json
          id: string
          namespace: string
          origin_device_id?: string | null
          rev: number
          server_updated_at: string
          updated_at: string
          user_id: string
          value: Json
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          field_clock?: Json
          id?: string
          namespace?: string
          origin_device_id?: string | null
          rev?: number
          server_updated_at?: string
          updated_at?: string
          user_id?: string
          value?: Json
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      account_delete_prepare: { Args: { p_user_id: string }; Returns: Json }
      assert_client_supported: { Args: { p_build: number }; Returns: undefined }
      current_user_id: { Args: never; Returns: string }
      dispatch_claim: {
        Args: { p_lease_seconds?: number; p_limit?: number }
        Returns: Json
      }
      dispatch_complete: { Args: { p_results: Json }; Returns: Json }
      dispatch_devices: { Args: { p_user_ids: string[] }; Returns: Json }
      dispatch_guards: { Args: { p_jobs: Json }; Returns: Json }
      dispatch_upsert_inbox: { Args: { p_items: Json }; Returns: Json }
      enable_sync: { Args: { p_table: unknown }; Returns: undefined }
      everslot_ns: { Args: never; Returns: string }
      fallback_candidates: {
        Args: { p_inactive?: string; p_limit?: number }
        Returns: {
          user_id: string
        }[]
      }
      fallback_load: { Args: { p_user: string }; Returns: Json }
      fallback_replace_jobs: {
        Args: { p_jobs: Json; p_source_rev: number; p_user: string }
        Returns: Json
      }
      fcm_token_cache_get: {
        Args: { p_key: string; p_min_validity?: string }
        Returns: {
          access_token: string
          expires_at: string
        }[]
      }
      fcm_token_cache_put: {
        Args: { p_access_token: string; p_expires_at: string; p_key: string }
        Returns: undefined
      }
      fetch_rows: { Args: { p_ids: string[]; p_table: string }; Returns: Json }
      hlc_at: {
        Args: { p_at: string; p_counter?: number; p_node?: string }
        Returns: string
      }
      is_valid_time_zone: { Args: { p_zone: string }; Returns: boolean }
      ops_health: { Args: never; Returns: Json }
      ops_heartbeat: {
        Args: { p_details?: Json; p_name: string }
        Returns: undefined
      }
      purge_now: {
        Args: { p_entity_type: string; p_ids: string[] }
        Returns: Json
      }
      purge_watermark: { Args: never; Returns: number }
      raise_api_error: {
        Args: {
          p_code: string
          p_details?: Json
          p_hint?: string
          p_message: string
          p_status?: number
        }
        Returns: undefined
      }
      register_device: {
        Args: {
          p_app_build: number
          p_app_version: string
          p_device_name?: string
          p_id: string
          p_locale: string
          p_model: string
          p_os_version: string
          p_platform: string
          p_time_zone: string
        }
        Returns: Json
      }
      replace_notification_jobs: {
        Args: {
          p_device_id: string
          p_jobs: Json
          p_source_rev: number
          p_target_keys: string[]
        }
        Returns: Json
      }
      report_device_state: {
        Args: { p_id: string; p_state: Json }
        Returns: Json
      }
      request_account_deletion: { Args: never; Returns: Json }
      revoke_device: { Args: { p_id: string }; Returns: Json }
      storage_purge_claim: { Args: { p_limit?: number }; Returns: Json }
      storage_purge_done: {
        Args: { p_errors?: Json; p_ids: number[] }
        Returns: number
      }
      sync_pull: { Args: { p_limit?: number; p_since: number }; Returns: Json }
      sync_push: {
        Args: {
          p_build: number
          p_changes: Json
          p_device_id: string
          p_schema: number
        }
        Returns: Json
      }
      synced_tables: { Args: never; Returns: string[] }
      uuid_v5:
        | { Args: { p_name: string }; Returns: string }
        | { Args: { p_name: string; p_namespace: string }; Returns: string }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  private: {
    Tables: {
      account_deletion_requests: {
        Row: {
          attempts: number
          last_attempt_at: string | null
          requested_at: string
          user_id: string
        }
        Insert: {
          attempts?: number
          last_attempt_at?: string | null
          requested_at?: string
          user_id: string
        }
        Update: {
          attempts?: number
          last_attempt_at?: string | null
          requested_at?: string
          user_id?: string
        }
        Relationships: []
      }
      fcm_token_cache: {
        Row: {
          access_token: string
          cache_key: string
          expires_at: string
          updated_at: string
        }
        Insert: {
          access_token: string
          cache_key: string
          expires_at: string
          updated_at?: string
        }
        Update: {
          access_token?: string
          cache_key?: string
          expires_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      notification_jobs: {
        Row: {
          attempts: number
          claimed_at: string | null
          created_at: string
          dedupe_key: string
          expires_at: string | null
          fire_at: string
          guard: Json | null
          id: string
          importance: string | null
          last_error: string | null
          lease_until: string | null
          next_retry_at: string | null
          occurrence_key: string | null
          payload: Json
          planned_by_device: string | null
          rule_id: string | null
          sent_at: string | null
          source_rev: number
          status: string
          target_devices: string[] | null
          target_key: string
          user_id: string
        }
        Insert: {
          attempts?: number
          claimed_at?: string | null
          created_at?: string
          dedupe_key: string
          expires_at?: string | null
          fire_at: string
          guard?: Json | null
          id?: string
          importance?: string | null
          last_error?: string | null
          lease_until?: string | null
          next_retry_at?: string | null
          occurrence_key?: string | null
          payload: Json
          planned_by_device?: string | null
          rule_id?: string | null
          sent_at?: string | null
          source_rev: number
          status?: string
          target_devices?: string[] | null
          target_key: string
          user_id: string
        }
        Update: {
          attempts?: number
          claimed_at?: string | null
          created_at?: string
          dedupe_key?: string
          expires_at?: string | null
          fire_at?: string
          guard?: Json | null
          id?: string
          importance?: string | null
          last_error?: string | null
          lease_until?: string | null
          next_retry_at?: string | null
          occurrence_key?: string | null
          payload?: Json
          planned_by_device?: string | null
          rule_id?: string | null
          sent_at?: string | null
          source_rev?: number
          status?: string
          target_devices?: string[] | null
          target_key?: string
          user_id?: string
        }
        Relationships: []
      }
      ops_heartbeats: {
        Row: {
          details: Json | null
          last_run_at: string
          name: string
        }
        Insert: {
          details?: Json | null
          last_run_at: string
          name: string
        }
        Update: {
          details?: Json | null
          last_run_at?: string
          name?: string
        }
        Relationships: []
      }
      push_deliveries: {
        Row: {
          created_at: string
          device_id: string | null
          error_code: string | null
          fcm_message_id: string | null
          id: string
          job_id: string | null
          outcome: string
        }
        Insert: {
          created_at?: string
          device_id?: string | null
          error_code?: string | null
          fcm_message_id?: string | null
          id?: string
          job_id?: string | null
          outcome: string
        }
        Update: {
          created_at?: string
          device_id?: string | null
          error_code?: string | null
          fcm_message_id?: string | null
          id?: string
          job_id?: string | null
          outcome?: string
        }
        Relationships: []
      }
      storage_deletions: {
        Row: {
          attempts: number
          bucket: string
          enqueued_at: string
          id: number
          last_error: string | null
          path: string
        }
        Insert: {
          attempts?: number
          bucket: string
          enqueued_at?: string
          id?: never
          last_error?: string | null
          path: string
        }
        Update: {
          attempts?: number
          bucket?: string
          enqueued_at?: string
          id?: never
          last_error?: string | null
          path?: string
        }
        Relationships: []
      }
      sync_meta: {
        Row: {
          key: string
          value: Json
        }
        Insert: {
          key: string
          value: Json
        }
        Update: {
          key?: string
          value?: Json
        }
        Relationships: []
      }
      time_zone_names: {
        Row: {
          name: string
        }
        Insert: {
          name: string
        }
        Update: {
          name?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      bump_purge_watermarks: {
        Args: { p_watermarks: Json }
        Returns: undefined
      }
      claim_notification_jobs: {
        Args: { p_lease_seconds?: number; p_limit?: number }
        Returns: {
          attempts: number
          claimed_at: string | null
          created_at: string
          dedupe_key: string
          expires_at: string | null
          fire_at: string
          guard: Json | null
          id: string
          importance: string | null
          last_error: string | null
          lease_until: string | null
          next_retry_at: string | null
          occurrence_key: string | null
          payload: Json
          planned_by_device: string | null
          rule_id: string | null
          sent_at: string | null
          source_rev: number
          status: string
          target_devices: string[] | null
          target_key: string
          user_id: string
        }[]
        SetofOptions: {
          from: "*"
          to: "notification_jobs"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      daily_maintenance: { Args: never; Returns: Json }
      delete_stale_anonymous_users: {
        Args: { p_days?: number; p_limit?: number }
        Returns: number
      }
      enqueue_unreferenced_objects: {
        Args: { p_objects: Json }
        Returns: number
      }
      evaluate_guard: {
        Args: { p_guard: Json; p_user_id: string }
        Returns: {
          ok: boolean
          reason: string
        }[]
      }
      hard_delete_tombstones: {
        Args: { p_ids: string[]; p_table: string }
        Returns: Json
      }
      heartbeat: {
        Args: { p_details?: Json; p_name: string }
        Returns: undefined
      }
      invoke_edge: {
        Args: { p_body?: Json; p_function: string }
        Returns: number
      }
      job_muted: { Args: { p_job: Json; p_user_id: string }; Returns: boolean }
      notification_guards_ok: {
        Args: { p_jobs: Json }
        Returns: {
          job_id: string
          ok: boolean
          reason: string
        }[]
      }
      ops_health: { Args: never; Returns: Json }
      purge_order: {
        Args: never
        Returns: {
          ord: number
          table_name: string
        }[]
      }
      purge_tombstones: {
        Args: { p_batch?: number; p_days?: number }
        Returns: Json
      }
      release_expired_leases: { Args: never; Returns: number }
      requires_aal2: { Args: { p_user_id: string }; Returns: boolean }
      run_minutely: { Args: never; Returns: Json }
      stale_anonymous_users: {
        Args: { p_days?: number; p_limit?: number }
        Returns: string[]
      }
      upsert_inbox: { Args: { p_job: Json; p_late?: boolean }; Returns: string }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  app: {
    Enums: {},
  },
  private: {
    Enums: {},
  },
} as const

