-- Top waits since the instance last restarted.
-- Filters out the background waits that are always at the top and never useful.
SELECT TOP (10)
    ws.wait_type,
    wait_seconds        = ws.wait_time_ms / 1000.0,
    signal_wait_seconds = ws.signal_wait_time_ms / 1000.0,
    resource_seconds    = (ws.wait_time_ms - ws.signal_wait_time_ms) / 1000.0,
    waiting_tasks       = ws.waiting_tasks_count,
    avg_wait_ms         = CASE
                              WHEN ws.waiting_tasks_count = 0 THEN 0
                              ELSE ws.wait_time_ms * 1.0 / ws.waiting_tasks_count
                          END
FROM sys.dm_os_wait_stats AS ws
WHERE ws.waiting_tasks_count > 0
  AND ws.wait_type NOT IN (
      'BROKER_TASK_STOP', 'CHECKPOINT_QUEUE', 'CLR_AUTO_EVENT',
      'CLR_MANUAL_EVENT', 'DIRTY_PAGE_POLL', 'DISPATCHER_QUEUE_SEMAPHORE',
      'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'LAZYWRITER_SLEEP',
      'LOGMGR_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'SLEEP_TASK',
      'SP_SERVER_DIAGNOSTICS_SLEEP', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
      'WAITFOR', 'XE_TIMER_EVENT'
  )
ORDER BY ws.wait_time_ms DESC;
