

for i in {58..10}
do
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Miseq $i"
    perl ~/dev/LIMS2-Scripts/bin/crispresso_nhej_counts_post-migration.pl --project Miseq_0$i --db_update --summary
done

for i in {9..1}
do
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Miseq $i"
    perl ~/dev/LIMS2-Scripts/bin/crispresso_nhej_counts_post-migration.pl --project Miseq_00$i --db_update --summary
done
