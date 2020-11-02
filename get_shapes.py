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
shp_ftp_url = yaml_list['census_shp_ftp_url']['shp_ftp_url']
shp_year = yaml_list['census_shp_ftp_url']['shp_year']
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

zip_lst = []

# Read the Census List from YAML File
for itm in census_list:
    typ = itm
    # Get the URL and download the zip files
    # Save the zip files to a local directory   
    if typ == 'TRACT':
        # Build/Set Tract ZIP File Name
        # Need to get the Fip codes as there is no single Tract zip file
        # All zip files are for each administrative boundaries
        pg_table = census_list[typ][1]
        shp_data_type = census_list[typ][2]
        for st in get_all_state_fips:
            full_zip_path = ''
            fip_code = st[0]        # get the fip code for each state in the loop
            if int(fip_code) >= acs_min_range and int(fip_code) <= acs_max_range:
                try:              
                    zip_full_name = census_list[typ][0].format(shp_year, fip_code)
                    full_ftp_url = shp_ftp_url.format(shp_year, typ) + zip_full_name
                    # Download the zip files
                    full_zip_path = os.path.join(sys.path[0], zip_dir + '/' + zip_full_name)
                    with urllib.request.urlopen(full_ftp_url) as response, open(full_zip_path, 'wb') as out_file:
                        print('Saving to local drive: ' + full_zip_path)
                        data = response.read() # a `bytes` object
                        out_file.write(data)
                except Exception as e:
                    print("fips code " + fip_code + " is not used")
                    print(('Failed message: '+ str(e)))
                
                # Extract and save shape files to a local directory
                try: 
                    if os.path.isfile(full_zip_path) :
                        z = zipfile.ZipFile(full_zip_path)
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
                        cmd = r'ogr2ogr -update -append -a_srs EPSG:4326 -nlt ' + shp_data_type + ' -lco SCHEMA=' + pg_schema + ' -f PostgreSQL PG:"host=' + pg_host + ' user=' + pg_user + ' dbname=' + pg_database + ' password=' + pg_pwd + '" -skipfailures -nln ' + pg_table  + ' '  + full_shp_file_path 
                        #FNULL = open(os.devnull, 'w') # prevent output of the subprocess or else lots of object data shown
                        #subprocess.call(cmd, shell=True, stdout=FNULL, stderr=subprocess.STDOUT)
                        subprocess.call(cmd, shell=True)
                except Exception as e:
                    print("fips code " + fip_code + " is not used")
                    print(('Failed message: '+ str(e)))

    # Get the URL and download the zip files
    # Save the zip files to a local directory    
    # All other shapes not tract just set year for zip files
    else:
        pg_table = census_list[typ][1] #Table name to add date in Postgres, from YAML
        shp_data_type = census_list[typ][2]
        try:
            zip_file = census_list[typ][0].format(shp_year)                   
            zip_full_name = census_list[typ][0].format(shp_year, fip_code)
            full_ftp_url = shp_ftp_url.format(shp_year, typ) + zip_full_name
            # Add to a list
            full_zip_path = os.path.join(sys.path[0], zip_dir + '/' + zip_full_name)
            with urllib.request.urlopen(full_ftp_url) as response, open(full_zip_path, 'wb') as out_file:
                print('Saving to local drive: ' + full_zip_path)
                data = response.read() # a `bytes` object
                out_file.write(data)
        except Exception as e:
            print("fips code " + fip_code + " is not used")
            print(('Failed message: '+ str(e)))


        # Extract and save shape files to a local directory
        print(full_zip_path)
        try: 
            if os.path.isfile(full_zip_path) :
                z = zipfile.ZipFile(full_zip_path)
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
                cmd = r'ogr2ogr -update -append -a_srs EPSG:4326 -nlt ' + shp_data_type + ' -lco SCHEMA=' + pg_schema + ' -f PostgreSQL PG:"host=' + pg_host + ' user=' + pg_user + ' dbname=' + pg_database + ' password=' + pg_pwd + '" -skipfailures -nln ' + pg_table  + ' '  + full_shp_file_path 
                #FNULL = open(os.devnull, 'w') # prevent output of the subprocess or else lots of object data shown
                #subprocess.call(cmd, shell=True, stdout=FNULL, stderr=subprocess.STDOUT)
                subprocess.call(cmd, shell=True)
        except Exception as e:
            print("fips code " + fip_code + " is not used")
            print(('Failed message: '+ str(e)))
            
    
# Create the FTP URL to collect the zip files containing the shape
# the loop is for Census Tract as the zip files are seperated for each admin boundaries
