# Generated by Django 5.2.3 on 2025-07-07 01:02

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('projects', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='project',
            name='case_amount',
            field=models.DecimalField(blank=True, decimal_places=2, help_text='案件涉及的金额，单位为人民币元', max_digits=15, null=True, verbose_name='涉案金额'),
        ),
    ]
