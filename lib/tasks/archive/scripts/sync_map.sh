GEOJSON_PATH=$1
# Extract state from path (e.g., /app/data/open-data/wa/.maps/ -> WA)
STATE=$(echo $GEOJSON_PATH | sed -E 's/.*\/open-data\/([^\/]+)\/\.maps\/.*/\1/' | tr '[:lower:]' '[:upper:]')

echo "Importing data for state: $STATE"

ogr2ogr \
  -f "PostgreSQL" \
  PG:"dbname=$POSTGRES_DB user=$POSTGRES_USER host=$POSTGRES_HOST password=$POSTGRES_PASSWORD port=5432" \
  $GEOJSON_PATH \
  -nln municipalities \
  -nlt PROMOTE_TO_MULTI \
  -lco GEOMETRY_NAME=geom \
  -lco PRECISION=NO \
  -sql "SELECT *, '$STATE' as state FROM municipalities" \
  -append

PGPASSWORD=$POSTGRES_PASSWORD psql \
  -U $POSTGRES_USER \
  -d $POSTGRES_DB \
  -h $POSTGRES_HOST \
  -c "DELETE FROM municipalities WHERE id NOT IN (SELECT MAX(id) FROM municipalities GROUP BY geoid);"
