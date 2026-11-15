js_restore_db() {
  psql -U gasjobber -d gasjobber -h localhost -p 5432 -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
  gunzip -c "$1" | grep -Ev "^(ALTER.*OWNER TO|REVOKE|GRANT)" | psql -q -U gasjobber -d gasjobber -h localhost -p 5432
  [ -f ./scripts/update_config_for_local.sql ] && psql -U gasjobber -d gasjobber -h localhost -p 5432 -f ./scripts/update_config_for_local.sql
}

JS_BACKUP_BUCKET_PATH="s3://gj-snapshooter-backups/snapshooter/f1c28025-jobbersoft-postgresql-all-db-backup"
JS_BACKUP_TZ="America/New_York"
JS_BACKUP_TIME_DST="07-00"
JS_BACKUP_TIME_STANDARD="08-00"
JS_BACKUP_LOOKBACK_DAYS=7

# Prints the backup URL of <tenant> on <YYYY-MM-DD>, or fails when that day has none.
_js_backup_url() {
  local tenant="$1" day="$2"
  local date_path zone primary fallback
  date_path="$(date -d "$day" +%Y/%m/%d)" || return 1

  # The backup runs on a fixed US Eastern wall-clock time, so its UTC folder shifts with DST.
  zone="$(TZ="$JS_BACKUP_TZ" date -d "$day 12:00" +%Z)"
  if [[ "$zone" == *DT ]]; then
    primary="$JS_BACKUP_TIME_DST" fallback="$JS_BACKUP_TIME_STANDARD"
  else
    primary="$JS_BACKUP_TIME_STANDARD" fallback="$JS_BACKUP_TIME_DST"
  fi

  local time src
  for time in "$primary" "$fallback"; do
    src="$JS_BACKUP_BUCKET_PATH/$date_path/$time/$tenant.sql.gz"
    if s3cmd ls "$src" 2>/dev/null | grep -q .; then
      echo "$src"
      return
    fi
    echo "Not found: $src" >&2
  done
  return 1
}

# Usage: js_fetch_db <tenant> [YYYY-MM-DD] [dest-dir]
# Without a date, fetches the latest backup of the last JS_BACKUP_LOOKBACK_DAYS days.
# Prints the downloaded path on stdout, so it chains: js_restore_db "$(js_fetch_db campbelloil)"
js_fetch_db() {
  if [[ -z "$1" ]]; then
    echo "Usage: js_fetch_db <tenant> [YYYY-MM-DD] [dest-dir]" >&2
    return 1
  fi

  local tenant="$1" day="$2"
  local dest_dir="${3:-temp}"
  local src offset

  if [[ -n "$day" ]]; then
    src="$(_js_backup_url "$tenant" "$day")"
  else
    for (( offset = 0; offset < JS_BACKUP_LOOKBACK_DAYS; offset++ )); do
      src="$(_js_backup_url "$tenant" "$(date -d "-$offset day" +%F)")" && break
    done
  fi
  [[ -n "$src" ]] || return 1

  local dest="$dest_dir/$tenant.sql.gz"
  mkdir -p "$dest_dir"
  s3cmd get --force "$src" "$dest" >&2 && echo "$dest"
}

js_gwt() {
  if [[ -z "$1" ]]; then
    echo "Usage: js_gwt <branch-name> [dir-name]" >&2
    return 1
  fi

  local branch="$1"
  # Default dir_name to $2, or to the tail of $1 if $2 isn't provided (e.g. 'feature/login' -> 'login')
  local dir_name="${2:-${1:t}}"
  local target_dir="$HOME/workspace/js-worktrees/$dir_name"

  # Ensure base worktree directory exists
  mkdir -p "$HOME/workspace/js-worktrees"

  # Add worktree and only change directory if git command succeeds
  git worktree add -b "$branch" "$target_dir" origin/main && cd "$target_dir"
}
