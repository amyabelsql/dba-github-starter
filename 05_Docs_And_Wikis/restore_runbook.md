# Restore Runbook

Use this with the **Restore Test** issue form.

## Before you start

- [ ] You know which backup you are restoring and when it was taken
- [ ] The target instance has room for the data and log files
- [ ] Nobody is using the target database

## Steps

1. **Find the backup chain**

   ```sql
   SELECT TOP (20)
       b.database_name,
       b.type,              -- D = full, I = differential, L = log
       b.backup_finish_date,
       f.physical_device_name
   FROM msdb.dbo.backupset AS b
   JOIN msdb.dbo.backupmediafamily AS f
       ON f.media_set_id = b.media_set_id
   WHERE b.database_name = 'Sales'
   ORDER BY b.backup_finish_date DESC;
   ```

2. **Restore the full backup**

   ```sql
   RESTORE DATABASE Sales_RestoreTest
   FROM DISK = 'X:\Backups\Sales_full.bak'
   WITH MOVE 'Sales'     TO 'X:\Data\Sales_RestoreTest.mdf',
        MOVE 'Sales_log' TO 'X:\Log\Sales_RestoreTest.ldf',
        NORECOVERY, STATS = 5;
   ```

3. **Apply the log backups in order**, all with `NORECOVERY`.

4. **Bring it online**

   ```sql
   RESTORE DATABASE Sales_RestoreTest WITH RECOVERY;
   ```

5. **Prove it worked**

   ```sql
   DBCC CHECKDB ('Sales_RestoreTest') WITH NO_INFOMSGS, ALL_ERRORMSGS;
   SELECT COUNT_BIG(*) FROM Sales_RestoreTest.dbo.Orders;
   ```

6. **Clean up**

   ```sql
   DROP DATABASE Sales_RestoreTest;
   ```

## Record the result

Close the restore-test issue with the restore time and anything that surprised you.
A backup you have never restored is not a backup.
