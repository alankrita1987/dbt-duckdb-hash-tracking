# Demo DBT to perform 'Create and Replace'

This repository demonstrates how we can use DBT to full-refresh a table whilst retaining a particular column's value. 

## Usage Examples
Dimension tables are often fully refreshed to obtain the latest source of truth for a given dimension. However, whilst doing so we often miss out on what all dimensions did change. The code here showcases how we can do a full refresh of the table whilst using hash_key to identify what dimensions changed. 



This demo setup showcases

1. Import `raw_customers.xlsx`: Uses the excel plugin. See `dbt_duckdb/models/example/staging/sources.yml` for details.
2. Import `raw_orders.xlsx`: Uses DuckDB's native feature to load data from Excel via the `st_read` function. See `dbt_duckdb/models/example/staging/sources.yml` and `dbt_duckdb/models/example/staging/schema.yml`.
3. `customers_int` model in `dbt_duckdb/models/example/customers_int.sql` stores the code for creating the customer table. And `customer` model in `dbt_duckdb/models/example/customers.sql` leverages hash_key created using MD5 coding for each customer row. The customer model when executed will full-refresh the customer table whilst also retaining the previous hash_key. Comparing the prev_hash_key with hash_key, one can then identify which all customers' data was updated. 


## DBT Configurations
Ensure the following files are configured as shown below:

.env 

```.env

# DBt config variables 
DBT_TARGET_PATH=./dbt_duckdb/target/
DBT_LOG_PATH=./dbt_duckdb/logs/
DBT_PROFILES_DIR=.
DBT_ENV_TARGET=dev

```
<br>

profiles.yml

````yaml

external_data:
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 1
      plugins:
        - module: dbt_duckdb.plugins.excel
          alias: custom_excel
      target-path: "{{ env_var('DBT_TARGET_PATH') }}"
      log-path: "{{ env_var('DBT_LOG_PATH') }}"
  
  target: dev 

````

## Setup

### Virtual Environment

Create a new virtual environment called `venv`:

```bash
python3 -m venv venv
```

Activate the virtual environment:

```bash
source venv/bin/activate
```

Install the required packages:


```bash
pip install -r requirements.txt
```

### Optional: Install Spatial Extension on DuckDB

If needed, you can install the spatial extension:

```python
import duckdb
con = duckdb.connect("dev.duckdb")
con.sql("INSTALL spatial;")
```

### Ensure dbt Recognizes Custom Plugins

Make sure dbt can see the custom plugins:

```bash
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

Alternatively, edit the `bin/activate` file to include this export command.


## Run the code 

#### Running the DBT model 
```bash
dbt run --target dev
```


#### checking duckdb to verify 
```bash
duckdb dev.duckdb --- If older version or dont want to use the duckdb UI 
duckdb -ui  --- applicable for cli >v1.2.1 
```
> ❗❗ Ensure that you have duckdb cli downloaded and added to your system PATH variable. [Link to download](https://github.com/duckdb/duckdb/releases/tag/v1.2.1)

Successful execution of the above will open the duckdb console for you to query the data. 

## Output
- Initial run will have no value in the prev_hash_key column. 
- Re-running the dbt run command will populate the prev_hash_key column but with same value as hash_key 
- change the values in customer.xlsx/order.xlsx/payments.xlsx. It will change the corresponding hash_key. 
- Re-Run the dbt run command, it will now have a different/ new hash_key created for that customer/s and old hash_key will be stored in the prev_hash_key column 
