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
"import json`n",
"import urllib.request`n",
"from pyspark.sql import functions as F`n",
"`n",
"WORKSPACE_ID = 'a8981880-d8c4-48dd-83b7-43f809fba42b'`n",
"LAKEHOUSE_ID = '1a1f90b7-458d-4609-93c6-c2d51a8bd970'`n",
"BRONZE_PATH = f`"abfss://{WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_ID}/Tables/bronze/scores`"`n",
"`n",
"# Supabase REST ingestion using publishable key (no DB password required)`n",
"SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://wnjnbddbguunhiubcxpg.supabase.co')`n",
"SUPABASE_TABLE = os.getenv('SUPABASE_TABLE', 'scores')`n",
"SUPABASE_PUBLISHABLE_KEY = os.getenv('SUPABASE_PUBLISHABLE_KEY', 'sb_publishable_8a42lb3cv4ilFQ91nJiSzA_uo5ij_K_')`n",
"`n",
"if not SUPABASE_PUBLISHABLE_KEY or str(SUPABASE_PUBLISHABLE_KEY).strip() == '':`n",
"    raise ValueError('Missing SUPABASE_PUBLISHABLE_KEY')`n",
"`n",
"endpoint = f`"{SUPABASE_URL}/rest/v1/{SUPABASE_TABLE}?select=*`"`n",
"headers = {`n",
"    'apikey': SUPABASE_PUBLISHABLE_KEY,`n",
"    'Authorization': f`"Bearer {SUPABASE_PUBLISHABLE_KEY}`",`n",
"    'Accept': 'application/json'`n",
"}`n",
"`n",
"req = urllib.request.Request(endpoint, headers=headers)`n",
"with urllib.request.urlopen(req, timeout=60) as response:`n",
"    payload = json.loads(response.read().decode('utf-8'))`n",
"`n",
"if not isinstance(payload, list):`n",
"    raise ValueError('Unexpected API response. Expected a list of rows.')`n",
"`n",
"if len(payload) == 0:`n",
"    raise ValueError('No rows returned from Supabase endpoint.')`n",
"`n",
"df = spark.createDataFrame(payload)`n",
"`n",
"df = df.withColumn('ingested_at_utc', F.current_timestamp())`n",
"df.write.mode('overwrite').format('delta').save(BRONZE_PATH)`n",
"`n",
"row_count = spark.read.format('delta').load(BRONZE_PATH).count()`n",
"print({'table': 'bronze.scores', 'row_count': int(row_count)})`n"
)

$silverLines = @(
"from pyspark.sql import functions as F`n",
"`n",
"WORKSPACE_ID = 'a8981880-d8c4-48dd-83b7-43f809fba42b'`n",
"LAKEHOUSE_ID = '1a1f90b7-458d-4609-93c6-c2d51a8bd970'`n",
"BRONZE_PATH = f`"abfss://{WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_ID}/Tables/bronze/scores`"`n",
"SILVER_PATH = f`"abfss://{WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_ID}/Tables/silver/scores`"`n",
"SILVER_QUARANTINE_PATH = f`"abfss://{WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_ID}/Tables/silver/scores_quarantine`"`n",
"`n",
"min_ts = F.to_timestamp(F.lit('2026-08-01T00:00:00Z'))`n",
"max_ts = F.to_timestamp(F.lit('2100-12-31T23:59:59Z'))`n",
"`n",
"df = spark.read.format('delta').load(BRONZE_PATH)`n",
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
"quarantine_df.write.mode('overwrite').format('delta').save(SILVER_QUARANTINE_PATH)`n",
"valid_df.write.mode('overwrite').format('delta').save(SILVER_PATH)`n",
"`n",
"valid_row_count = spark.read.format('delta').load(SILVER_PATH).count()`n",
"quarantine_row_count = spark.read.format('delta').load(SILVER_QUARANTINE_PATH).count()`n",
"print({'table': 'silver.scores', 'valid_row_count': int(valid_row_count), 'quarantine_row_count': int(quarantine_row_count)})`n"
)

$goldLines = @(
"from pyspark.sql import functions as F`n",
"from pyspark.sql.window import Window`n",
"`n",
"WORKSPACE_ID = 'a8981880-d8c4-48dd-83b7-43f809fba42b'`n",
"LAKEHOUSE_ID = '1a1f90b7-458d-4609-93c6-c2d51a8bd970'`n",
"SILVER_PATH = f`"abfss://{WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_ID}/Tables/silver/scores`"`n",
"GOLD_PATH = f`"abfss://{WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_ID}/Tables/gold/scores`"`n",
"`n",
"silver_df = spark.read.format('delta').load(SILVER_PATH)`n",
"`n",
"w = Window.partitionBy('player_name', 'score').orderBy(F.col('created_at').desc_nulls_last())`n",
"gold_df = silver_df.withColumn('rn', F.row_number().over(w)).filter(F.col('rn') == 1).drop('rn')`n",
"`n",
"gold_df.write.mode('overwrite').format('delta').save(GOLD_PATH)`n",
"`n",
"row_count = spark.read.format('delta').load(GOLD_PATH).count()`n",
"print({'table': 'gold.scores', 'row_count': int(row_count)})`n"
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
