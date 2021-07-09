#! /bin/bash
source $SCRIPTPATH/pg_backup.config
Oldfiles_Check=$(find $BACKUP_DIR -maxdepth 1  -type d -mtime +$DAYS_TO_KEEP  -print)
oldfiles_Remove=$(find $BACKUP_DIR -maxdepth 1  -type d -mtime +$DAYS_TO_KEEP  -print)
echo $Oldfiles_Check
if [$Oldfiles_Check -eq 0]
then
        echo " there is no $DAYS_TO_KEEP old backups files "
else
        echo "there is $DAYS_TO_KEEP old back uptiles need to clean up"
fi
