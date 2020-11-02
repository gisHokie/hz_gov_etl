'''
author: Scott McDermott
date: 10/21/2020

url:    https://www2.census.gov/geo/tiger/TIGER2019/TRACT/
        https://www2.census.gov/geo/tiger/TIGER2019/COUNTY/
        https://www2.census.gov/geo/tiger/TIGER2019/STATE/


'''

import shutil, os
import json
import datetime
from osgeo import ogr, osr, gdal
import yaml
import sys
import requests
import subprocess
import urllib.request
import zipfile
import re

#Custom modules
import modules.shapefile_to_postgres as stp
import modules.file_scraper as fsp

scraper = fsp.Scraper()

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

# Census FTP URL
census_list = yaml_list['census_shp_info']
tract_list = yaml_list['census_shp_info']['tract']
state_list = yaml_list['census_shp_info']['state']
county_list = yaml_list['census_shp_info']['county']
uac_list = yaml_list['census_shp_info']['uac']

shp_ftp_url = yaml_list['census_shp_ftp_url']['shp_ftp_url']
shp_year = yaml_list['census_shp_ftp_url']['shp_year']
shp_admin_type = yaml_list['census_shp_ftp_url']['shp_admin_type']
zip_tract = tract_list[1]
pg_table_tract = tract_list[2]
zip_county = county_list[1]
pg_table_county = county_list[2]
zip_state = state_list[1]
pg_table_state = state_list[2]
zip_uac = uac_list[1]
pg_table_uac = uac_list[2]

zip_dir = yaml_list['census_shp_ftp_url']['zip_directory']
shp_dir = yaml_list['census_shp_ftp_url']['shp_directory']

# Set SQL stuff, All Functions and Views are located in Postgres
sql_get_fips_abv = yaml_list['sql']['get_fips_abbv']
sql_get_all_years_acs = yaml_list['sql']['get_all_acs_years']

# Create the zip and shp directories if not exit
zip_dir_path = os.path.join(sys.path[0], zip_dir)
shp_dir_path = os.path.join(sys.path[0], shp_dir)
if not os.path.exists(zip_dir_path):
	os.makedirs(zip_dir_path)
if not os.path.exists(shp_dir_path):
	os.makedirs(shp_dir_path)

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

# Create the URL for the Census FTP
full_ftp_url = ''
#yaml_system_path_file = os.path.join(sys.path[0], zip_dir)

# Build/Set State and County ZIP File Name
zip_full_state = zip_state.format(shp_year)
zip_full_county = zip_county.format(shp_year)
zip_full_uac = zip_uac.format(shp_year)
zip_tract_lst = []
zip_all_lst = []

# Build/Set Tract ZIP File Name
# Need to get the Fip codes as there is no single Tract zip file
# All zip files are for each administrative boundaries
for st in get_all_state_fips:
    fip_code = st[0]        # get the fip code for each state in the loop
    if int(fip_code) >= acs_min_range and int(fip_code) <= acs_max_range:
        try:
            zip_full_tract = zip_tract.format(shp_year, fip_code)
            # Add to a list
            zip_tract_lst.append(zip_full_tract)
          
        except Exception as e:
            print("fips code " + fip_code + " is not used")
            print(('Failed message: '+ str(e)))

# Create the FTP URL to collect the zip files containing the shape
# the loop is for Census Tract as the zip files are seperated for each admin boundaries

try:
    for typ in shp_admin_type:
        if typ == 'TRACT':
            for trc in zip_tract_lst:
                full_ftp_url = shp_ftp_url.format(shp_year, typ) + trc
                #zip_all_lst.append(full_ftp_url)
                
        if typ == 'COUNTY':
            full_ftp_url = shp_ftp_url.format(shp_year, typ) + zip_full_county
            #zip_all_lst.append(full_ftp_url) 
        
        if typ == 'STATE':
            full_ftp_url = shp_ftp_url.format(shp_year, typ) + zip_full_state
            #zip_all_lst.append(full_ftp_url)
        
        if typ == 'UAC':
            full_ftp_url = shp_ftp_url.format(shp_year, typ) + zip_full_uac
            print(full_ftp_url)
            zip_all_lst.append(full_ftp_url)

# Need to make sure that if the FIPS is not used by the API to ignore it (mainly for smaller territories)
except Exception as e:
    print("fips code " + fip_code + " is not used")
    print(('Failed message: '+ str(e)))

# Get the zip files from the sites and store in a directory 
for url in zip_all_lst:
    # Find a away to get the zip files from previous line of codes rather than doing a split
    split_url = url.split("/")
    len_split = len(split_url)
    zip_file = zip_dir_path + '/' + split_url[len_split - 1]  #save the zip files to the 'zip' directory

    full_zip_path = os.path.join(sys.path[0], zip_file)
    print(full_zip_path)
    line_list = ''
    shp_file_name = ''
    '''
    # Save the zip files to a local directory
        try: 
            with urllib.request.urlopen(url) as response, open(full_zip_path, 'wb') as out_file:
                print('Saving to local drive: ' + full_zip_path)
                data = response.read() # a `bytes` object
                out_file.write(data)
        except Exception as e:
            print(('Failed message: '+ str(e))) 
    '''
    # Extract and save shape files to a local directory
    if os.path.isfile(zip_file) :
        z = zipfile.ZipFile(zip_file)
        z.extractall(shp_dir)
        
        # Get the shape file name
        files = z.namelist()
        for i in files:
            if re.match(r'.*\.shp', i) and not re.match(r'.*\.xml', i):
                shp_file_name = i

        #Set the Full Path for the shape file
        full_shp_file_path = os.path.join(sys.path[0], shp_dir + '/' + shp_file_name) 

        #command = r'ogr2ogr -f "PostgreSQL" PG:"host=url port=5432 dbname=db1 user=username password=password" -append -update -nln schemaname.tablename "D:\path\shapefile(1,2,3...).shp" -progress -nlt MULTIPOLYGON'
        #cmd = r'D:\\OSGeo4W64\\bin\\ogr2ogr -update -append -fieldmap  '+ fieldmap + ' -a_srs EPSG:4326 -nlt GEOMETRY -lco SCHEMA=' + pg_schema + ' -f PostgreSQL PG:"host=' + pg_host + ' user=' + pg_user + ' dbname=' + pg_database + ' password=' + pg_pwd + '"  -skipfailures -nln geo_catalog.stg_geo_object_template '  + shp_full_path 
        cmd = r'ogr2ogr -update -append -a_srs EPSG:4326 -nlt GEOMETRY -lco SCHEMA=' + pg_schema + ' -f PostgreSQL PG:"host=' + pg_host + ' user=' + pg_user + ' dbname=' + pg_database + ' password=' + pg_pwd + '" -skipfailures -nln ' + public.census_urban_area  + ' '  + full_shp_file_path 
        print(cmd)
        #subprocess.call(cmd, shell=True)
          

'''
    #except Exception as e:
    #    print(('Failed message: '+ str(e))) 

# INSERT into Census Postgres table.
# Need to concatenate the YEAR and ID so that it becomes unique when newer Tracts are added in the future
#Sprint("Upsizing to Postgres: " + filename)
'''
#closing database connection.  Need to close data connection
if(conn):
	conn.close()