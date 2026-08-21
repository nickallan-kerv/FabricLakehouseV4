$base = 'c:\GitRepos\nickallan-kerv\FabricLakehouseV4\tmp\fabric_export'

function New-NotebookJson {
  param([string[]]$SourceLines)
  return [ordered]@{
    nbformat = 4
    nbformat_minor = 5
    metadata = [ordered]@{
      dependencies = [ordered]@{ lakehouse = $null }
      language_info = [ordered]@{ name = 'python' }
      kernel_info = [ordered]@{ name = 'synapse_pyspark'; jupyter_kernel_name = $null }
      a365ComputeOptions = $null
      sessionKeepAliveTimeout = 0
    }
    cells = @(
      [ordered]@{
        cell_type = 'code'
        metadata = [ordered]@{ microsoft = [ordered]@{ language = 'python'; language_group = 'synapse_pyspark' } }
        source = $SourceLines
        outputs = @()
      }
    )
  }
}

$bronzeLines = @(
"import os`n",
"from pyspark.sql import functions as F`n",
"`n",
"# Expected environment variables for Supabase Postgres connection`n",
"SUPABASE_HOST = os.getenv('SUPABASE_HOST')`n",
"SUPABASE_DB = os.getenv('SUPABASE_DB', 'postgres')`n",
"SUPABASE_USER = os.getenv('SUPABASE_USER')`n",
"SUPABASE_PASSWORD = os.getenv('SUPABASE_PASSWORD')`n",
"SUPABASE_PORT = os.getenv('SUPABASE_PORT', '5432')`n",
"`n",
"required = [SUPABASE_HOST, SUPABASE_USER, SUPABASE_PASSWORD]`n",
"if any(v is None or str(v).strip() == '' for v in required):`n",
"    raise ValueError('Missing SUPABASE_HOST, SUPABASE_USER, or SUPABASE_PASSWORD environment variable')`n",
"`n",
"jdbc_url = f`"jdbc:postgresql://{SUPABASE_HOST}:{SUPABASE_PORT}/{SUPABASE_DB}`"`n",
"query = `"(select * from public.scores) as src`"`n",
"`n",
"df = (`n",
"    spark.read`n",
"    .format('jdbc')`n",
"    .option('url', jdbc_url)`n",
"    .option('dbtable', query)`n",
"    .option('user', SUPABASE_USER)`n",
"    .option('password', SUPABASE_PASSWORD)`n",
"    .option('driver', 'org.postgresql.Driver')`n",
"    .load()`n",
")`n",
"`n",
"df = df.withColumn('ingested_at_utc', F.current_timestamp())`n",
"df.write.mode('overwrite').format('delta').saveAsTable('bronze.scores')`n",
"`n",
"display(spark.sql('select count(*) as row_count from bronze.scores'))`n"
)

$silverLines = @(
"from pyspark.sql import functions as F`n",
"`n",
"min_ts = F.to_timestamp(F.lit('2026-08-01T00:00:00Z'))`n",
"max_ts = F.to_timestamp(F.lit('2100-12-31T23:59:59Z'))`n",
"`n",
"df = spark.table('bronze.scores')`n",
"df = df.withColumn('created_at_ts', F.to_timestamp(F.col('created_at')))`n",
"`n",
"invalid_condition = (`n",
"    (F.col('score') < F.lit(1))`n",
"    | (F.col('level') < F.lit(1))`n",
"    | (F.col('created_at_ts').isNull())`n",
"    | (F.col('created_at_ts') < min_ts)`n",
"    | (F.col('created_at_ts') > max_ts)`n",
")`n",
"`n",
"quarantine_df = (`n",
"    df.filter(invalid_condition)`n",
"      .withColumn(`n",
"          'quarantine_reason',`n",
"          F.concat_ws(';',`n",
"              F.when(F.col('score') < 1, F.lit('score_lt_1')),
",
"              F.when(F.col('level') < 1, F.lit('level_lt_1')),
",
"              F.when(F.col('created_at_ts').isNull(), F.lit('invalid_created_at')),
",
"              F.when(F.col('created_at_ts') < min_ts, F.lit('created_at_too_early')),
",
"              F.when(F.col('created_at_ts') > max_ts, F.lit('created_at_too_late'))`n",
"          )`n",
"      )`n",
")`n",
"`n",
"valid_df = df.filter(~invalid_condition).drop('created_at_ts')`n",
"`n",
"quarantine_df.write.mode('overwrite').format('delta').saveAsTable('silver.scores_quarantine')`n",
"valid_df.write.mode('overwrite').format('delta').saveAsTable('silver.scores')`n",
"`n",
"display(spark.sql('select count(*) as valid_row_count from silver.scores'))`n",
"display(spark.sql('select count(*) as quarantine_row_count from silver.scores_quarantine'))`n"
)

$goldLines = @(
"from pyspark.sql import functions as F`n",
"from pyspark.sql.window import Window`n",
"`n",
"silver_df = spark.table('silver.scores')`n",
"`n",
"w = Window.partitionBy('player_name', 'score').orderBy(F.col('created_at').desc_nulls_last())`n",
"gold_df = silver_df.withColumn('rn', F.row_number().over(w)).filter(F.col('rn') == 1).drop('rn')`n",
"`n",
"gold_df.write.mode('overwrite').format('delta').saveAsTable('gold.scores')`n",
"`n",
"display(spark.sql('select count(*) as row_count from gold.scores'))`n"
)

$bronzeNb = New-NotebookJson -SourceLines $bronzeLines
$silverNb = New-NotebookJson -SourceLines $silverLines
$goldNb = New-NotebookJson -SourceLines $goldLines

$bronzePath = Join-Path $base 'nb_scores_bronze_ingestion.Notebook\notebook-content.ipynb'
$silverPath = Join-Path $base 'nb_scores_silver_cleansing.Notebook\notebook-content.ipynb'
$goldPath = Join-Path $base 'nb_scores_gold_serving.Notebook\notebook-content.ipynb'

$bronzeNb | ConvertTo-Json -Depth 20 | Set-Content -Path $bronzePath -Encoding UTF8
$silverNb | ConvertTo-Json -Depth 20 | Set-Content -Path $silverPath -Encoding UTF8
$goldNb | ConvertTo-Json -Depth 20 | Set-Content -Path $goldPath -Encoding UTF8

Write-Output 'NOTEBOOK_DEFINITIONS_WRITTEN'
