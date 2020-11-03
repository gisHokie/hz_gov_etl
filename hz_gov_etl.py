'''
Title: Governor's ETL for Shapes to Postgis/Postgresql
Author: Scott D. McDermott
Date:   09/09/2020
Summary: Upsize the shapes from US Census to Postgis

Note: The commit to SQL may be commented out, uncomment if you need to insert into sql. the script looks like the following:
       #cur.execute(sql_insert_acs) 
        #conn.commit()     

Census api:
required 
https://api.census.gov/data/2018/acs/acs5/subject/groups/S2301.html
https://api.census.gov/data/2018/acs/acs5/subject/groups.json
"S2301_C01_001E"    "Total!!Estimate!!Population 16 years and over"
"S2301_C02_001E"    "Labor Force Participation Rate!!Estimate!!Population 16 years and over"
"S2301_C03_001E"    "Employment/Population Ratio!!Estimate!!Population 16 years and over"
"S2301_C04_001E"    "Unemployment rate!!Estimate!!Population 16 years and over"     https://api.census.gov/data/2016/acs/acs5/subject/variables/S2301_C03_001E.json
https://api.census.gov/data/2018/acs/acs5/subject
# total population B01003_001E
# total population by age B01001_001E   (identical to total population)
# employ status B23025_001E
sample url: https://api.census.gov/data/2018/acs/acs5/?get=NAME,B01003_001E,B23025_001E&for=tract:*&in=state:01&in=county:*&key=
https://api.census.gov/data/2018/acs/acs5/subject?get=NAME,S2301_C01_001E&for=tract:*&in=state:01&in=county:*&key=
'''
import shutil, os
import json
import datetime
import yaml
import sys
import requests
import subprocess

#Custom modules
import modules.shapefile_to_postgres as stp

#Paths
yaml_file = 'hz_gov_etl_config.yml'
yaml_system_path_file = os.path.join(sys.path[0], yaml_file)   # will need to have full path to file

yaml_list = ''


# Get the configs from yaml file
with open(yaml_system_path_file, 'r') as yfile:
    # The FullLoader parameter handles the conversion from YAML
    # scalar values to Python the dictionary format
    yaml_list = yaml.load(yfile, Loader=yaml.FullLoader)

# Get YAML Values
census_key = yaml_list['census_key']
version = yaml_list['version']
main_title = yaml_list['main_title']

acs_year = yaml_list['census_acs_year']

# This is not definite, but appears that the census has 
acs_max_range = yaml_list['acs_max_range']
acs_min_range = yaml_list['acs_min_range']

# Set the Postgres, there is only one so no need to loop
pg_host = yaml_list['pg']['pg_host']
pg_port = yaml_list['pg']['pg_port']
pg_database = yaml_list['pg']['pg_database']
pg_user = yaml_list['pg']['pg_user']
pg_pwd =yaml_list['pg']['pg_pwd']
pg_schema = yaml_list['pg']['pg_schema']

# Set SQL stuff, All Functions and Views are located in Postgres
sql_get_fips_abv = yaml_list['sql']['get_fips_abbv']
sql_get_all_years_acs = yaml_list['sql']['get_all_acs_years']
sql_fx_insert_pop = yaml_list['sql']['fx_insert_population']
sql_fx_insert_acs_emp = yaml_list['sql']['fx_insert_acs_emp']

# postgres connection object
dbase_conn = {
    'host': pg_host,
    'dbname': pg_database,
    'user': pg_user,
    'password': pg_pwd,
    'port': pg_port
    }
conn = stp.p_conn(dbase_conn)
cur = conn.cursor()

#Get list of current state fips and abbreviations
cur.execute("SELECT * FROM " + sql_get_fips_abv)
get_all_state_fips = cur.fetchall()

# Get the Census Code, year, and url
# ACS 5 year data is normally 1 or 2 years behind the current year
tract_api_url = ''
census_codes = yaml_list['census_codes']
str_census_codes =  ','.join(census_codes)     # convert to string for url format
acs_year = yaml_list['census_acs_year']
#now = datetime.datetime.now()

for st in get_all_state_fips:
    fip_code = st[0]        # get the fip code for each state in the loop
    if int(fip_code) >= acs_min_range and int(fip_code) <= acs_max_range:
        try:
            tract_api_url = yaml_list['full_tract_api'].format(yr=acs_year, fip_code=fip_code , acs_codes=str_census_codes, census_key=census_key)
            
            # Call the API and get data
            #r = requests.get(tract_api_url)
            #status_code = r.status_code

            #print url to know what state is being collected
            #print(tract_api_url)

            #Dump the data as JSON format
            data = r.json()
            data.pop(0)
            # https://stackoverflow.com/questions/8134602/psycopg2-insert-multiple-rows-with-one-query
            # https://api.census.gov/data/2018/acs/acs5/subject?get=NAME,S2301_C01_001E,S2301_C01_001M,S2301_C02_001E,S2301_C02_001M,S2301_C03_001E,S2301_C03_001M,S2301_C04_001E,S2301_C04_001M&for=tract:*&in=state:56&in=county:*
            # order of values:
                    #- object   
                    #- S2301_C01_001E   "Total!!Estimate!!Population 16 years and over"
                    #- S2301_C01_001M   margin of errors
                    #- S2301_C02_001E   "Labor Force Participation Rate!!Estimate!!Population 16 years and over"
                    #- S2301_C02_001M   margin of errors
                    #- S2301_C03_001E   "Employment/Population Ratio!!Estimate!!Population 16 years and over"
                    #- S2301_C03_001M   margin of errors
                    #- S2301_C04_001E   "Unemployment rate!!Estimate!!Population 16 years and over"  
                    #- S2301_C04_001M    margin of errors
                    #- state fip
                    #- county fip
                    #- tract code
                    #- year

            args_str = ''
            for x in data:
                ###Data Prep###
                # replace single apostrophes for some names
                # Need to evaluate for any Null/None data and change to 0 to insert into SQL
                i = 0                
                for y in x:
                    x[i] = str(y).replace("'", "''")
                    x[i] = str(y).replace("None", "0")
                    i += 1
                
                ###DATA QUERY STRING###
                insert_qry = ','.join('\'{}\''.format(c) for i, c in enumerate(x, 1))
                # Add the Year to the enumeration.  Year is an extra field not part of the Census
                insert_qry_year = insert_qry + ",'" + str(acs_year) + "'"
                
                ###DATA INSERT INTO SQL###
                # CALL FUNCTION to INSERT DATA
                # https://stackoverflow.com/questions/17539660/how-to-insert-data-into-table-using-stored-procedures-in-postgresql
                sql_insert_acs = 'select * from ' + sql_fx_insert_acs_emp + ' ('+ insert_qry_year + ')'

                print(sql_insert_acs)
                #cur.execute(sql_insert_acs) 
                #conn.commit()
        # Need to make sure that if the FIPS is not used by the API to ignore it (mainly for smaller territories)
        except Exception as e:
            print("fips code " + fip_code + " is not used")
            print(('Failed message: '+ str(e)))
# Get the population for the same year
try:
    pop_county_url = yaml_list['pop_county_api'].format(yr=acs_year, census_key=census_key)
    # Call the API and get data
    r = requests.get(pop_county_url)
    status_code = r.status_code

    #print url to know what state is being collected
    print(pop_county_url)

    #Dump the data as JSON format
    data = r.json()
    data.pop(0)
    for x in data:
        ###Data Prep###
        # replace single apostrophes for some names
        # Need to evaluate for any Null/None data and change to 0 to insert into SQL
        i = 0                
        for y in x:
            x[i] = str(y).replace("None", "0")
            i += 1
        
        ###DATA QUERY STRING###
        insert_qry = ','.join('\'{}\''.format(c) for i, c in enumerate(x, 1))
        # Add the Year to the enumeration.  Year is an extra field not part of the Census
        insert_qry_year = insert_qry + ",'" + str(acs_year) + "'"
        
        ###DATA INSERT INTO SQL###
        # CALL FUNCTION to INSERT DATA
        # https://stackoverflow.com/questions/17539660/how-to-insert-data-into-table-using-stored-procedures-in-postgresql
        sql_insert_acs = 'select * from ' + sql_fx_insert_pop + ' ('+ insert_qry_year + ')'

        print(sql_insert_acs)
       #cur.execute(sql_insert_acs) 
        #conn.commit()            
except Exception as e:
    print("fips code " + fip_code + " is not used")
    print(('Failed message: '+ str(e)))    
    
      
#closing database connection.  Need to close data connection
if(conn):
	conn.close()